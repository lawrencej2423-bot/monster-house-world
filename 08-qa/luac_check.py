#!/usr/bin/env python3
"""
Monster House Highrise world — Lua syntax check that understands
Highrise Studio's TYPED Lua.

    python3 08-qa/luac_check.py [--root <dir>]

Why this exists: Highrise Studio scripts are written in a typed Lua
dialect (the official Highrise docs' own examples, e.g. CoinCollector,
use exactly this syntax):

    --!Type(ClientAndServer)
    --!Bind
    local radioSignLabel : UILabel = nil
    function self:OnTriggerEnter(other : Collider) ... end

Stock `luac -p` cannot parse the `: Type` annotations and reports them
as syntax errors — but they are NOT bugs; Studio compiles them fine.
So this checker adapts instead of the scripts:

  1. Walk <root> for *.lua, skipping dot-directories (.lua/, .git/,
     .github/, ...) and __pycache__. (The old workflow `find` picked
     up the `.lua/` install folder built by gh-actions-lua itself and
     failed with "cannot open ./.lua: Permission denied".)
  2. For each file, build a TYPE-STRIPPED temp copy (see strip_types)
     and run `luac -p` on the copy. The originals are never edited.
  3. If no luac exists on this machine, print SKIPPED and exit 0 —
     a missing checker tool is not a code failure (in the workflows,
     the separate "Lua install" step/verdict row catches a failed
     install).

Exit code: 0 = every file parsed (or check SKIPPED), 1 = a stripped
file failed luac -p (a REAL syntax error).

The stripper is deliberately conservative — it removes `: Type` spans
ONLY in the two syntactic positions where a colon can be a type
annotation in this dialect:

  * a local declarator:        local name : Type [= ...]
                               local a : T, b : U = ...
  * a function parameter list: function f(name : Type, ...) [: RetType]

plus a typed return (`): Type`) right after a function's parameter
list. Colons anywhere else — method calls `obj:Method()`, method
definitions `function self:Name()`, labels `::x::`, string contents,
comments — are never touched: the stripper works on a token stream
(strings and comments are single opaque tokens) and only deletes
spans it has positively identified as annotations.

Known limits (none occur in this repo today; each would need a new
rule, not a script edit):
  * typed `for` variables (`for i : number in ...`),
  * Luau function types with `->` returns inside an annotation,
  * annotations spanning multiple lines are handled only if the type
    itself stays a simple dotted/generic chain (the token consumer
    does not care about newlines, so in practice they work).
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

# ---------------------------------------------------------------- tokens
# Token kinds: "ident" (identifiers AND keywords), "number", "punct",
# "string" (opaque), "comment" (opaque). Whitespace is not tokenized;
# every token carries its [start, end) char span in the source so the
# stripper can delete exact spans and leave everything else — layout,
# comments, strings — byte-for-byte identical.


def _tokenize(src):
    toks = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c in " \t\r\n\f\v":
            i += 1
            continue
        if src.startswith("--", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            if m:  # block comment --[[ ]] / --[==[ ]==]
                close = "]" + m.group(1) + "]"
                j = src.find(close, i + m.end())
                j = n if j == -1 else j + len(close)
            else:  # line comment (incl. --!Type / --!Bind)
                j = src.find("\n", i)
                j = n if j == -1 else j
            toks.append(("comment", i, j))
            i = j
            continue
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            j = min(n, j + 1)
            toks.append(("string", i, j))
            i = j
            continue
        m = re.match(r"\[(=*)\[", src[i:])
        if m:  # long string [[ ]] / [==[ ]==]
            close = "]" + m.group(1) + "]"
            j = src.find(close, i + m.end())
            j = n if j == -1 else j + len(close)
            toks.append(("string", i, j))
            i = j
            continue
        if c.isalpha() or c == "_":
            j = i + 1
            while j < n and (src[j].isalnum() or src[j] == "_"):
                j += 1
            toks.append(("ident", i, j))
            i = j
            continue
        if c.isdigit():
            j = i + 1
            while j < n and (src[j].isalnum() or src[j] in "._"):
                j += 1
            toks.append(("number", i, j))
            i = j
            continue
        three, two = src[i:i + 3], src[i:i + 2]
        if three == "...":
            toks.append(("punct", i, i + 3))
            i += 3
            continue
        if two in ("..", "==", "~=", "<=", ">=", "::", "//", "<<", ">>"):
            toks.append(("punct", i, i + 2))
            i += 2
            continue
        toks.append(("punct", i, i + 1))
        i += 1
    return toks


class _Tok:
    __slots__ = ("kind", "start", "end", "text")

    def __init__(self, kind, start, end, text):
        self.kind, self.start, self.end, self.text = kind, start, end, text


def _sig_tokens(src):
    """Significant tokens (comments dropped) as _Tok objects."""
    return [_Tok(k, s, e, src[s:e]) for k, s, e in _tokenize(src)
            if k != "comment"]


# ---------------------------------------------------------------- stripper


def _consume_balanced(toks, i):
    """toks[i] is an opener (< { or (). Return index past its match."""
    pairs = {"<": ">", "{": "}", "(": ")"}
    stack = [pairs[toks[i].text]]
    i += 1
    while i < len(toks) and stack:
        t = toks[i].text
        if t in pairs:
            stack.append(pairs[t])
        elif t == stack[-1]:
            stack.pop()
        i += 1
    return i


def _consume_type(toks, i):
    """Consume one type expression starting at toks[i]; return the
    index one past its last token. A type is a chain of atoms joined
    by '|': an identifier with dotted segments (Foo.Bar), optional
    generic args (<...>), table type ({...}) or parenthesised type,
    each with an optional trailing '?'. Anything else stops the
    consumption — that is what keeps the stripper conservative."""
    while i < len(toks):
        t = toks[i]
        if t.kind == "ident":
            i += 1
            while (i + 1 < len(toks) and toks[i].text == "."
                   and toks[i + 1].kind == "ident"):
                i += 2
            if i < len(toks) and toks[i].text in ("<", "{"):
                i = _consume_balanced(toks, i)
            if i < len(toks) and toks[i].text == "?":
                i += 1
        elif t.text in ("{", "("):
            i = _consume_balanced(toks, i)
            if i < len(toks) and toks[i].text == "?":
                i += 1
        else:
            break
        if i < len(toks) and toks[i].text == "|":
            i += 1
            continue
        break
    return i


def strip_types(src):
    """Return (stripped_src, removed) where removed is a list of the
    exact annotation strings deleted (for reporting). Only `: Type`
    spans in local-declarator and function-signature positions are
    removed; all other bytes are preserved exactly."""
    toks = _sig_tokens(src)
    spans = []  # (start, end) char spans to delete

    def delete_annotation(colon_idx):
        """toks[colon_idx] is ':'; delete it plus its type. Return
        the token index one past the type. The span also absorbs
        spaces/tabs immediately before the colon (same line only),
        so `local x : T = v` strips to `local x = v`, not
        `local x  = v`."""
        end = _consume_type(toks, colon_idx + 1)
        if end > colon_idx + 1:
            start = toks[colon_idx].start
            while start > 0 and src[start - 1] in " \t":
                start -= 1
            spans.append((start, toks[end - 1].end))
        return end

    i = 0
    while i < len(toks):
        t = toks[i]
        if t.kind == "ident" and t.text == "function":
            # Find the parameter list: first '(' after the keyword
            # (name tokens incl. the method ':' sit before it and are
            # never touched).
            j = i + 1
            while j < len(toks) and toks[j].text != "(":
                j += 1
            if j >= len(toks):
                i += 1
                continue
            k = _consume_balanced(toks, j) - 1  # index of ')'
            # Parameters: a ':' whose previous significant token is a
            # parameter name (ident or '...') is an annotation.
            m = j + 1
            while m < k:
                if toks[m].text == ":" and (
                        toks[m - 1].kind == "ident"
                        or toks[m - 1].text == "..."):
                    m = delete_annotation(m)
                else:
                    m += 1
            i = k + 1
            # Typed return: ')' immediately followed by ': Type'.
            if i < len(toks) and toks[i].text == ":":
                i = delete_annotation(i)
            continue
        if t.kind == "ident" and t.text == "local":
            nxt = toks[i + 1] if i + 1 < len(toks) else None
            if nxt is not None and nxt.text == "function":
                i += 1  # the 'function' rule above handles its params
                continue
            # Declarator list: ident (':' Type)? (',' ident ...)* —
            # stop at '=' or anything else; initializers (which may
            # contain method calls) are never scanned.
            m = i + 1
            while m < len(toks) and toks[m].kind == "ident":
                if m + 1 < len(toks) and toks[m + 1].text == ":":
                    m = delete_annotation(m + 1)
                else:
                    m += 1
                if m < len(toks) and toks[m].text == ",":
                    m += 1
                    continue
                break
            i = max(i + 1, m)
            continue
        i += 1

    if not spans:
        return src, []
    spans.sort()
    out, prev, removed = [], 0, []
    for s, e in spans:
        out.append(src[prev:s])
        removed.append(src[s:e])
        prev = e
    out.append(src[prev:])
    return "".join(out), removed


# ---------------------------------------------------------------- checker

LUAC_NAMES = ("luac54.exe", "luac.exe", "luac54", "luac", "luac5.4")


def find_luac(root):
    """Resolve a Lua compiler by its real executable names (the
    official Windows zip ships luac54.exe; gh-actions-lua produces
    luac.exe). PATH first, then the gh-actions-lua .lua/bin folder
    under the root as a courtesy. None = no compiler available."""
    for name in LUAC_NAMES:
        p = shutil.which(name)
        if p:
            return p
    bindir = os.path.join(root, ".lua", "bin")
    for name in LUAC_NAMES:
        p = os.path.join(bindir, name)
        if os.path.isfile(p):
            return p
    return None


def iter_lua_files(root):
    for dirpath, dirs, files in os.walk(root):
        # Skip dot-directories (.lua install dir, .git, .github, ...)
        # and __pycache__ — they are not game source.
        dirs[:] = sorted(d for d in dirs
                         if not d.startswith(".") and d != "__pycache__")
        for fn in sorted(files):
            if fn.lower().endswith(".lua"):
                yield os.path.join(dirpath, fn)


def main():
    ap = argparse.ArgumentParser(
        description="luac -p check that understands Highrise typed Lua")
    ap.add_argument("--root", default=".",
                    help="directory to walk for *.lua (default: .)")
    args = ap.parse_args()
    root = os.path.abspath(args.root)

    files = list(iter_lua_files(root))
    if not files:
        print("No Lua files found under %s - check skipped." % root)
        return 0
    luac = find_luac(root)
    if not luac:
        print("SKIPPED: no luac found (looked for %s on PATH and in "
              "%s) - %d Lua file(s) NOT checked. A missing luac is an "
              "install problem, not a code failure."
              % (", ".join(LUAC_NAMES),
                 os.path.join(root, ".lua", "bin"), len(files)))
        return 0

    bad = 0
    stripped_count = 0
    with tempfile.TemporaryDirectory(prefix="luac-check-") as tmp:
        for path in files:
            rel = os.path.relpath(path, root)
            with open(path, "r", encoding="utf-8",
                      errors="replace") as fh:
                src = fh.read()
            stripped, removed = strip_types(src)
            if removed:
                stripped_count += 1
            tmpfile = os.path.join(
                tmp, os.path.basename(path))
            with open(tmpfile, "w", encoding="utf-8") as fh:
                fh.write(stripped)
            try:
                r = subprocess.run([luac, "-p", tmpfile],
                                   capture_output=True, text=True,
                                   timeout=30)
            except (OSError, subprocess.SubprocessError) as e:
                print("BAD   %s: could not run luac: %s" % (rel, e))
                bad += 1
                continue
            if r.returncode == 0:
                note = (" (stripped: %s)" % "; ".join(removed)) \
                    if removed else ""
                print("OK    %s%s" % (rel, note))
            else:
                bad += 1
                err = (r.stderr.strip().splitlines() or ["?"])[0]
                # Point the error at the real file, not the temp copy;
                # stripping never changes line numbers.
                err = err.replace(tmpfile, rel)
                print("BAD   %s: %s" % (rel, err))
    print("")
    print("%d Lua file(s) checked with %s; %d file(s) had Highrise "
          "type annotations stripped for the check."
          % (len(files), luac, stripped_count))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

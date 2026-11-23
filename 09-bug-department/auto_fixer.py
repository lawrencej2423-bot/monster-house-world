#!/usr/bin/env python3
"""
Bug Department — auto-fixer (safe mechanical fixes ONLY).

Runs inside GitHub Actions (see .github/workflows/bug-department.yml) and
can also be run by hand from anywhere:

    python3 09-bug-department/auto_fixer.py [--root <repo-root>] [--dry-run]

What it fixes — and NOTHING else:

  JSON files (*.json, .git/.github excluded):
    1. Trailing commas: a comma directly before a closing ] or }
       (the single most common hand-edited-JSON break). Commas are
       removed with a string-aware scanner, so commas inside string
       values are never touched.
    2. Format normalization: ONLY for a file that needed the comma fix,
       and ONLY if the file parses cleanly after the fix, the file is
       rewritten as parse-and-redump (json.dump, indent=2). A file that
       still does not parse after the comma fix is left byte-for-byte
       untouched and reported as UNFIXABLE.
    Already-valid JSON files are never rewritten.

  Lua files (*.lua, .git excluded):
    3. Trailing whitespace at end of line is stripped. Nothing else
       about the file changes (line endings are preserved; a final
       newline is neither added nor removed).

Exit code:
  0  every issue found was safely fixed (or there were no issues)
  1  at least one issue was found that this script cannot safely fix
     (e.g. JSON still invalid after trailing-comma removal). Those
     files are reported, never modified.

Every fix (or would-be fix, in --dry-run mode) is logged to stdout,
one line per change, so the Actions log is the department's paper trail.
Stdlib only. No network, no Muse, no AI — this must be able to run
on a bare GitHub runner forever.
"""

import argparse
import json
import sys
from pathlib import Path

SKIP_PARTS = {".git", ".github"}


# --------------------------------------------------------------------------
# JSON: string-aware trailing-comma removal
# --------------------------------------------------------------------------

def remove_trailing_commas(text):
    """Remove commas that directly precede ] or } outside strings.

    Returns (new_text, removed_count). A tiny scanner tracks string
    state (including backslash escapes) so a comma inside a quoted
    string is never mistaken for a trailing comma.
    """
    out = []
    removed = 0
    i, n = 0, len(text)
    in_string = False
    while i < n:
        ch = text[i]
        if in_string:
            out.append(ch)
            if ch == "\\" and i + 1 < n:      # escape: copy next char too
                out.append(text[i + 1])
                i += 2
                continue
            if ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue
        if ch == ",":
            # Look ahead past whitespace: if the next real char closes
            # an array/object, this comma is trailing -> drop it.
            j = i + 1
            while j < n and text[j] in " \t\r\n":
                j += 1
            if j < n and text[j] in "]}":
                removed += 1
                i += 1
                continue
            out.append(ch)
            i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out), removed


def fix_json_file(path, label, dry_run):
    """Returns 'ok' | 'fixed' | 'unfixable'. Prints its own log lines."""
    try:
        text = path.read_bytes().decode("utf-8")
    except UnicodeDecodeError as e:
        print(f"UNFIXABLE  {label}: not valid UTF-8 ({e})")
        return "unfixable"
    try:
        json.loads(text)
        return "ok"                                   # valid: never touch
    except json.JSONDecodeError:
        pass                                          # try the safe fix
    candidate, removed = remove_trailing_commas(text)
    if removed == 0:
        try:
            json.loads(text)
        except json.JSONDecodeError as e:
            print(f"UNFIXABLE  {label}: invalid JSON, no trailing comma "
                  f"to fix ({e.msg} at line {e.lineno} col {e.colno})")
        return "unfixable"
    try:
        data = json.loads(candidate)
    except json.JSONDecodeError as e:
        print(f"UNFIXABLE  {label}: still invalid after removing "
              f"{removed} trailing comma(s) ({e.msg} at line {e.lineno} "
              f"col {e.colno}) — file left untouched")
        return "unfixable"
    # Parse succeeded after the comma fix -> normalize via redump.
    normalized = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    if dry_run:
        print(f"WOULD-FIX  {label}: would remove {removed} trailing "
              f"comma(s) and rewrite normalized (parse-and-redump)")
    else:
        path.write_text(normalized, encoding="utf-8")
        print(f"FIXED      {label}: removed {removed} trailing comma(s), "
              f"rewrote normalized (parse-and-redump)")
    return "fixed"


# --------------------------------------------------------------------------
# Lua: trailing whitespace only
# --------------------------------------------------------------------------

def fix_lua_file(path, label, dry_run):
    """Returns 'ok' | 'fixed'. Prints its own log lines."""
    try:
        text = path.read_bytes().decode("utf-8")
    except UnicodeDecodeError:
        return "ok"            # not text we understand; leave it alone
    lines = text.splitlines(keepends=True)   # keep endings: preserve them
    changed = 0
    new_lines = []
    for line in lines:
        stripped = line.rstrip("\r\n")
        ending = line[len(stripped):]
        trimmed = stripped.rstrip(" \t")
        if trimmed != stripped:
            changed += 1
        new_lines.append(trimmed + ending)
    if changed == 0:
        return "ok"
    if dry_run:
        print(f"WOULD-FIX  {label}: would strip trailing whitespace on "
              f"{changed} line(s)")
    else:
        path.write_text("".join(new_lines), encoding="utf-8")
        print(f"FIXED      {label}: stripped trailing whitespace on "
              f"{changed} line(s)")
    return "fixed"


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

def iter_files(root, suffix):
    for p in sorted(root.rglob(f"*{suffix}")):
        if SKIP_PARTS.intersection(p.parts):
            continue
        yield p


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Bug Department auto-fixer (safe fixes only).")
    ap.add_argument("--root", default=".",
                    help="repo root (default: current directory)")
    ap.add_argument("--dry-run", action="store_true",
                    help="report what would be fixed; write nothing")
    args = ap.parse_args(argv)

    root = Path(args.root).resolve()
    mode = "DRY-RUN" if args.dry_run else "FIX"
    print(f"Bug Department auto-fixer [{mode}] — root: {root}")

    fixed = unfixable = checked = 0
    for p in iter_files(root, ".json"):
        checked += 1
        result = fix_json_file(p, str(p.relative_to(root)), args.dry_run)
        if result == "fixed":
            fixed += 1
        elif result == "unfixable":
            unfixable += 1
    for p in iter_files(root, ".lua"):
        checked += 1
        result = fix_lua_file(p, str(p.relative_to(root)), args.dry_run)
        if result == "fixed":
            fixed += 1

    print(f"\nChecked {checked} file(s): {fixed} fixable issue(s) "
          f"{'found' if args.dry_run else 'fixed'}, "
          f"{unfixable} unfixable issue(s).")
    if unfixable:
        print("RESULT: UNFIXABLE issues present — a human or agent "
              "needs to look; see UNFIXABLE lines above.")
        return 1
    print("RESULT: clean (nothing this fixer cannot handle).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

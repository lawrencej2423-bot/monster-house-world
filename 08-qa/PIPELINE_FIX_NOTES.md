# Pipeline Fix — why the first GitHub Actions runs failed, and the fixes

Scope: staged copies only (`pipeline-fix/`). `repo/` was NOT edited — these
files land via the browser upload, same as the rest of V1.
Changed: `.github/workflows/build.yml`, `.github/workflows/bug-department.yml`,
`08-qa/sweep.py`. Unchanged: `bug-sweep.yml` (it runs build.yml as a reusable
workflow, so it inherits the fix) and `finisher.yml` (checked — it has no Lua
install step).

## Root cause 1 — "Lua install" FAIL: the download URL 404s

The install step in build.yml and bug-department.yml downloaded:

```
https://downloads.sourceforge.net/project/luabinaries/5.4.2/Windows64_bin/lua-5.4.2_Win64_bin.zip
```

The folder `5.4.2/Windows64_bin/` does not exist on SourceForge (the directory
URL itself returns HTTP 404). The real location of the official LuaBinaries
5.4.2 Windows executables is the **`Tools Executables`** folder:

```
https://sourceforge.net/projects/luabinaries/files/5.4.2/Tools%20Executables/lua-5.4.2_Win64_bin.zip/download
```

(verified against SourceForge's own file listing via search, 2026-11-22).
So `Invoke-WebRequest` threw on the 404, the step failed, no Lua was ever
installed — and the next step ("Lua syntax") then failed too with "No Lua
interpreter found on PATH". Both red rows, one cause.

**Fix (both workflows, identical step):**
- Download from the corrected `Tools Executables` path, trying the
  sourceforge.net `/download` endpoint first and the downloads.sourceforge.net
  mirror second, up to 3 attempts each, following up to 10 redirects.
- Verify the payload is a real zip (first two bytes `PK`, size > 10 KB) —
  SourceForge error/interstitial pages are HTML and must not reach
  `Expand-Archive`.
- After expanding, locate `luac*.exe` recursively, add its folder to
  `GITHUB_PATH`, and smoke-test it with `luac -v` inside the install step, so
  a bad install fails HERE with a clear message instead of downstream.

## Root cause 2 — "QA tests (08-qa)" FAIL: sweep.py couldn't find DESIGN.md

`sweep.py` defaulted `--design` to **one level above the repo root**
(`<parent-of-repo>/DESIGN.md`) — true in the local working tree
(`world-building/DESIGN.md`), false in a GitHub checkout, where DESIGN.md
lives **inside** the repo at `design-docs/DESIGN.md` and the checkout's parent
is a runner temp folder. With no DESIGN.md found:

- the naming check silently degraded (no expected names to check against), and
- every DESIGN-§5 anchor that is *referenced but not placed as a manifest
  object* flipped from PENDING to FAIL — concretely `TriviaScreen`
  (referenced in the trivia Lua and START_HERE.md; a script hook, never a
  placed object).

**Reproduced locally (A/B, simulated GitHub checkout in /tmp, no DESIGN.md
above it):**
- OLD sweep: `FAIL START_HERE.md:10 — Reference to anchor 'TriviaScreen'…`
  → Totals: 1 FAIL, **exit 1**. Exactly the Actions behaviour.
- NEW sweep: finds `design-docs/DESIGN.md`, naming check actually runs
  (176 objects vs 45 DESIGN names), TriviaScreen is PENDING again →
  Totals: 0 FAIL, **exit 0**.

**Fix:** `--design` now auto-detects, in order: explicit `--design`,
`<root>/DESIGN.md`, `<root>/design-docs/DESIGN.md`, then the legacy
parent-of-repo location. Degraded mode (PENDING note) only if none exists.
All other checks unchanged and still strict.

## Root cause 3 (latent) — sweep.py's luac handling used wrong exe names

The official Windows zip ships `lua54.exe` / `luac54.exe`. The old code probed
`luac` / `luac5.4` / `lua` (no `luac54` exists as `luac5.4` — wrong name) and,
when it found an interpreter, invoked a hard-coded `luac5.4` that does not
exist, silently falling back to the balance check. It never caused a FAIL,
but the "uses luac if present" behaviour was broken on Windows.

**Fix:** new `find_lua_tool()` resolves the real names (`luac54`, `luac`,
`luac5.4`, then `lua54`, `lua`) and invokes the resolved path directly —
compiler → `-p` parse check; interpreter → `loadfile()` parse check. If no
Lua tool exists, the luac check is explicitly reported as **SKIPPED** in the
pass note (balance check still runs; absence of luac is never a failure).
Real luac syntax errors still FAIL, unchanged.

## Checked and NOT a problem

- The 4 files missing from the GitHub upload (CardStationShared.lua,
  PartyGameChatHook.lua, StationPresence.lua, PIPELINE.md): re-ran the fixed
  sweep with those 4 deleted — still 0 FAIL (one extra PENDING for the empty
  07-pipeline section, tolerated by design). They did not cause the QA
  failure, but they should still be re-uploaded for completeness.
- sweep.py path handling is `os.path`/`os.walk`-based — Windows-safe; no
  separator or line-ending issues found.
- bug-department.yml's copy of the JSON check and its verdict logic are
  unaffected; only its Lua install step changed (same fix as build.yml).

## Validation

- All 3 workflow files parse as YAML (`yaml.safe_load`).
- Fixed `sweep.py` compiles (`py_compile`) and was run against:
  - the full local repo copy → 5 pass, 2 pending, **0 FAIL**;
  - a simulated GitHub checkout (old sweep: exit 1 / new sweep: exit 0);
  - the simulated checkout minus the 4 un-uploaded files → **0 FAIL**.
- The PowerShell install step cannot be executed on this Linux VM; it is
  syntax-reviewed and built from the verified SourceForge URL. First real
  test is the next Actions run after these files are uploaded.

---

# Round 2 — Lua install: SourceForge is dead, long live lua.org

Trigger: GitHub Actions run #27. The Round 1 QA/sweep fix WORKED (QA tests
PASS in both Build Checks and Bug Department). The Lua step still failed:
the corrected SourceForge URL returned a ~137 KB NON-ZIP response on every
attempt from the runner — an HTML interstitial, not the zip. Conclusion:
SourceForge direct download from a datacenter IP is unreliable, period.
Round 2 removes SourceForge entirely. Same scope as Round 1: only the
staged copies in `pipeline-fix/` changed (`build.yml`,
`bug-department.yml`); `bug-sweep.yml` inherits via `workflow_call`;
`repo/` untouched.

## Evidence — everything below was curl-tested from this VM (2026-11-22)

SourceForge, every form, FAILS from a datacenter IP (all returned a
Cloudflare "Just a moment…" bot-wall page, HTML magic `3c 21` = `<!`):

| Attempt | HTTP | Bytes | Magic |
|---|---|---|---|
| `sourceforge.net/…/download`, browser User-Agent, `-L` | 403 | 3,285 | `<!` HTML |
| `downloads.sourceforge.net/project/…` mirror | 403 | 1,916 | `<!` HTML |
| `…/download?use_mirror=autoselect` | — (no response) | 0 | — |
| `downloads.sourceforge.net/…?use_mirror=master` | 403 | 3,285 | `<!` HTML |

(Run #27 saw the same wall from the runner side, as a ~137 KB HTML page.)

What DOES work from here:

| Source | HTTP | Bytes | Magic | Verdict |
|---|---|---|---|---|
| `lua.org/ftp/lua-5.4.8.tar.gz` | 200 | 374,332 | `1f 8b` gzip | ✅ real tarball |
| `lua.org/ftp/lua-5.4.2.tar.gz` | 200 | 353,472 | `1f 8b` gzip | ✅ real tarball |
| LuaLS 3.19.2 win32-x64 zip (GitHub Releases) | 200 | 4,455,290 | `50 4b` (`PK`) | ⚠️ real zip, but contains NO standalone `lua.exe`/`luac.exe` (Lua is embedded in `lua-language-server.exe`) — rejected |
| Chocolatey `lua` package (latest nupkg) | 200 | — | `PK` | ⚠️ latest version is **5.1.5.52 = Lua 5.1**, not 5.4 — a 5.1 `luac` would reject 5.4 syntax. `choco install lua` rejected as the method |

Marketplace actions checked (docs/README via web + GitHub API):

- **leafo/gh-actions-lua** — latest release **v13.1.0** (Oct 2026, actively
  maintained; node24). Downloads Lua SOURCE from **lua.org/ftp** (never
  SourceForge) and builds it: on Windows via a custom MSVC build producing
  `.lua/bin/lua.exe` + `luac.exe`, added to PATH. Documented Windows
  prerequisite: `step-security/msvc-dev-cmd@v1` (the transferred home of
  ilammy/msvc-dev-cmd; v1.13.1 confirmed to exist). Its own CI matrix tests
  windows-latest × Lua 5.4. Has a build cache (default on), so repeat runs
  restore `.lua` instead of recompiling. Supports exact versions —
  `luaVersion: "5.4.2"` keeps the exact Lua version Round 1 targeted.
- **xpol/setup-lua** — older, sparsely maintained by comparison, no
  advantage over leafo's action. Not chosen.
- **leafo/gh-actions-luacheck** — a linter runner, not an installer; not
  needed (the workflows already syntax-check with `luac -p`).

## The change (identical in build.yml and bug-department.yml)

The single PowerShell download step is replaced by four steps; everything
else in both workflows is byte-identical, and the verdict steps still read
`steps.lua_install.outcome` for the "Lua install" row:

1. **Set up the MSVC environment** — `step-security/msvc-dev-cmd@v1`
   (`continue-on-error: true`; if the Lua build cache hits, MSVC isn't
   even needed).
2. **Install Lua 5.4.2 (gh-actions-lua)** — `id: lua_action`,
   `leafo/gh-actions-lua@v13` with `luaVersion: "5.4.2"`,
   `continue-on-error: true`. PRIMARY method.
3. **Install Lua 5.4.2 (fallback)** — `id: lua_fallback`, runs only
   `if: steps.lua_action.outcome == 'failure'`. PowerShell: download
   `https://www.lua.org/ftp/lua-5.4.2.tar.gz`, verify gzip magic
   (`1F 8B`) + size, extract with the runner's built-in `tar`, compile
   with `cl`/`lib` (all `src/*.c` except the two mains `lua.c`/`luac.c`
   → `lua54.lib`; then link each main against it — the tarball's src
   layout was verified from here: 33 `.c` files, exactly those two
   mains), copy `lua.exe`/`luac.exe` to a bin folder on `GITHUB_PATH`,
   smoke-test `luac -v` in-step.
4. **Install Lua on the runner** — `id: lua_install` (name and id kept,
   so the summaries/verdicts are unchanged). Verification step: find
   `luac*.exe` (PATH first via `Get-Command luac`/`luac54`, then
   `.lua/` in the workspace, then the fallback folder), ensure its
   folder is on `GITHUB_PATH` for the following bash step, and
   smoke-test `luac -v`. Throws — failing the verdict honestly — only
   if BOTH install methods failed.

## Validation

- All 3 workflow files parse as YAML (`yaml.safe_load`); step lists
  confirm every pre-existing step is present, in order, unchanged
  (json → lua_install chain → lua → qa/sweep → verdict).
- No SourceForge URL remains in either workflow (only comments
  explaining why it was removed).
- The PowerShell fallback cannot be executed on this Linux VM (no
  `cl.exe`); it is syntax-reviewed and built only from pieces verified
  above (lua.org reachability, tarball layout, MSVC recipe shape).
  First real test is the next Actions run after upload — same honesty
  caveat as Round 1, but the primary path is now a maintained action
  whose own CI proves the Windows build on every release.

---

# Round 3 — the "syntax errors" were the checker's bug, not the scripts'

Trigger: GitHub Actions run #29. Round 2's Lua install WORKED
(leafo/gh-actions-lua). `luac -p` then flagged exactly 5 files, every
error a `:` at the same kind of line:

- `RadioBoothUI.lua:15`, `TriviaScreenUI.lua:16`, `RPSArenaUI.lua:15` —
  `local <name> : UILabel = nil`
- `RPSPodiumTrigger.lua:11`, `StationSpotTrigger.lua:15` —
  `function self:OnTriggerEnter(other : Collider)`

These are Highrise Studio's TYPED Lua annotations. The official
Highrise docs' own examples (e.g. CoinCollector) use exactly this
syntax; Studio compiles it, stock luac cannot parse it. The 12
untyped files passed luac cleanly. Verdict: the CHECKER adapts, the
scripts are never edited. No game script was touched in this round.

Second bug in the same step: the workflow's `find . -name "*.lua"`
also picked up the `.lua/` install directory that gh-actions-lua
builds in the workspace ("cannot open ./.lua: Permission denied",
"BAD ./.lua"). The new checker skips dot-directories entirely.

## Annotation shapes actually present (all 17 repo Lua files read)

- `--!Type(...)` header (line 1) — all 17 files. A comment; luac
  ignores it; left alone.
- `--!Bind` on its own line — the 3 UI files. Also a comment.
- Typed local `local x : UILabel = nil` — 3 instances
  (RadioBoothUI:15, RPSArenaUI:15, TriviaScreenUI:16).
- Typed parameter `(other : Collider)` — 4 instances
  (RPSPodiumTrigger + StationSpotTrigger, Enter and Exit each).
- NOT present anywhere: typed returns, typed table fields, typed
  multi-parameter lists, space-less `x: T`. (The stripper still
  handles typed returns and multi-declarator/multi-param lists —
  covered by synthetic tests — because the docs' dialect allows
  them and future scripts may use them.)

## The fix

**New: `08-qa/luac_check.py`** (stdlib only), now the single Lua
syntax checker used by both workflows:

- Walks a root for `*.lua`, pruning dot-directories (`.lua`, `.git`,
  `.github`, …) and `__pycache__`.
- Resolves luac by real executable names (`luac54.exe`, `luac.exe`,
  `luac54`, `luac`, `luac5.4`) on PATH, plus `<root>/.lua/bin` as a
  courtesy. No luac → prints SKIPPED, exit 0 (a missing compiler is
  an install failure, already caught by the workflows' separate
  "Lua install" verdict row — not a code failure).
- For each file it writes a type-stripped temp copy and runs
  `luac -p` on the copy. Stripping never changes line numbers, and
  luac error paths are rewritten back to the real file name.

**The stripper** (the heart of this round) works on a token stream —
strings and comments are single opaque tokens — and deletes a
`: Type` span ONLY where a colon can be a type annotation in this
dialect:

- a local declarator: `local name : Type [= ...]`, including
  comma-separated declarator lists;
- a function parameter list: `(name : Type, ...)`, including
  anonymous and `local function`s;
- a typed return `: Type` immediately after a signature's `)`.

Type consumption is a bounded chain (dotted names, `<...>` generics,
`{...}` table types, `?`, `|` unions) that stops at the first token
that cannot be part of a type. Method calls `obj:Method()`, method
definitions `function self:Name()` (the name colon sits before the
parameter list and is never scanned), labels `::x::` (tokenized as
`::`), string contents and comments are structurally untouchable.
The deleted span also absorbs spaces/tabs just before the colon so
stripped copies stay tidy.

**`08-qa/sweep.py`** carries a deliberate duplicate of the stripper
(`strip_type_annotations`) — sweep.py has always been self-contained
and is run standalone by the workflows and the Bug Department, so it
does not import. Its luac path now feeds luac a stripped temp copy
exactly like luac_check.py, and `find_lua_tool()` also knows the
`.exe` names. The two stripper copies are verified byte-identical in
output on all 17 files (test below); keep them in sync.

**Workflows** (`build.yml`, `bug-department.yml`): the bash
find+luac loop is replaced by one line, `python 08-qa/luac_check.py`,
under the same step id (`lua`), so the verdict rows are unchanged.
`bug-sweep.yml` inherits via `workflow_call` as before.

## Known limits of the stripper

- Typed `for` variables (`for i : number in ...`) are not stripped —
  none exist in the repo; if one appears, luac will flag it and the
  stripper needs a new rule (the scripts still won't be edited).
- Luau function types with `->` returns inside an annotation stop
  consumption at `->`; not present in the repo or the docs' examples
  used here.
- The stripper proves the stripped copy parses; it does not
  type-check (that is Studio's job, and Studio accepts the dialect).

## Validation (this VM, 2026-11-22)

- Both workflows parse as YAML; no `find . -name` loop remains in
  either; both call `python 08-qa/luac_check.py`.
- `luac_check.py` + `sweep.py` compile (`py_compile`).
- No luac exists on this VM, so `luac_check.py --root repo` prints
  SKIPPED and exits 0, as designed (17 files counted).
- Real parse proof via lupa 2.8 (bundled Lua 5.5 `load()`): all 17
  STRIPPED files parse. The 5 flagged originals FAIL `load()`
  unstripped and parse stripped — confirming the annotations were
  the only blocker. Diffs of stripped vs original show only the 7
  annotation spans removed (`: UILabel` ×3, `: Collider` ×4),
  nothing else.
- 14 synthetic trap cases pass: method-call colons, method
  definitions, labels, colons inside strings/comments untouched;
  typed locals/params/returns, multi-declarators, generics, unions,
  dotted types all stripped correctly.
- Dot-directory walk test: `.lua/`, `.git/`, `__pycache__` contents
  are excluded; real files are found.
- Updated `sweep.py` against `repo/`: 5 pass, 2 pending (the known
  honest TriviaScreen PENDINGs), **0 FAIL**, exit 0.
- First real luac test is still the next Actions run after these
  files are uploaded — same honesty caveat as Rounds 1–2 — but the
  stripped files are now proven to parse under a real Lua runtime,
  so run #29's five "syntax errors" cannot recur.

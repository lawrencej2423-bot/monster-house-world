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

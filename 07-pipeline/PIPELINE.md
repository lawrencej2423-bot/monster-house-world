# Pipeline — how the automatic checks work (plain words)

This section is the repo's safety net. Its whole job: **catch mistakes
automatically, every time, without anybody having to remember to check.**

There are two workflow files. On GitHub they live in `.github/workflows/`
(GitHub only reads workflows from that one folder — that's why they aren't
in this folder with the rest of section 07):

| File | What it is |
|---|---|
| `.github/workflows/build.yml` | **Build Checks** — the actual checks |
| `.github/workflows/bug-sweep.yml` | **Bug Sweep** — runs Build Checks automatically, on a timer |

---

## What runs, and when

**Build Checks (`build.yml`) runs when:**

- code is pushed to the repo,
- a pull request is opened or updated,
- someone presses "Run workflow" by hand on GitHub's Actions tab.

**Bug Sweep (`bug-sweep.yml`) runs when:**

- code is pushed (same checks, via Build Checks — it borrows them instead
  of copying them, so a sweep can never drift out of date), and
- **every Monday at 14:00 UTC** (about 6–7am Los Angeles), even if nothing
  changed since the last run. That's the "automatic" part: if something
  quietly breaks, the sweep finds it within a week on its own.
- It can also be fired by hand from the Actions tab.

If a **scheduled** sweep fails, Bug Sweep automatically opens a GitHub
issue called "🐛 Automatic bug sweep failed" (or adds a comment if that
issue is already open), with a link straight to the failed run. Push
failures don't get an issue — they already show as a red X on the commit.

Everything runs on **`windows-latest`** — a free Windows machine GitHub
lends the repo for a few minutes. Windows matters because Highrise Studio
is a Windows/Mac tool; checking on the same kind of machine the world will
be finished on keeps surprises down. This repo is on the GitHub Free plan;
standard runners for a public repo don't need a card or a paid plan.

---

## What gets checked

Each run does all three checks **even if an earlier one fails**, then
prints one summary table at the bottom of the run page and only then
passes or fails as a whole.

1. **JSON manifests parse.**
   Every `.json` file in the repo (the layout in `01-layout`, the house
   facade in `02-house-facade`, asset lists in `06-assets`, and any other
   section that adds one) is loaded by a real JSON parser. One typo'd
   comma fails the run and names the file and the error.

2. **Lua syntax is real.**
   The runner downloads and installs an actual Lua interpreter (the
   official LuaBinaries 5.4 Windows build), then runs `luac -p` — parse
   only, nothing executes — over every `.lua` file (sections `03`, `04`,
   `05`). A file that wouldn't even load in the world fails here first,
   for free, instead of inside Highrise Studio later.

3. **QA tests run, if they're there yet.**
   If section `08-qa` exists, the pipeline runs the first entry point it
   finds, in this order:
   - `08-qa/run_tests.py` → run with Python,
   - `08-qa/test_*.py` (or `*_test.py`) → run with pytest,
   - `08-qa/run_tests.sh` → run with bash,
   - `08-qa/sweep.py` → run with Python.

   If `08-qa` hasn't landed yet, or has no entry point, this check is
   reported as **SKIPPED**, not failed — the pipeline is built to work
   while the other sections are still being written, and to pick the QA
   suite up automatically the moment it appears. **That is the contract
   for the QA crew: put tests in `08-qa` behind one of those entry
   points and they run on every push and every sweep, no wiring needed.**

### How to read a result

- **Green check** on the commit / Actions tab = everything passed (or was
  legitimately skipped, which the summary says out loud).
- **Red X** = something failed. Open the run and scroll to the bottom:
  the **summary table** says which of the three checks failed, and the
  failed step's log names the exact file and error.
- Nothing here is silent: a check that finds no files says so
  ("check skipped — nothing to validate") instead of pretending to pass.

---

## The honest open item — what this pipeline does NOT do

**The final step of shipping the world is not automated, and is not yet
proven:**

> Open the project in **Highrise Studio** (Unity), press **Play** to test
> it, then **Upload** it to Highrise under the owner's account.

These workflows only validate the world's **text files** — manifests and
Lua. They never open Unity or Studio, never sign in to Highrise, and
never press Play or Upload. There is currently no proven way to do that
step from GitHub Actions: Studio needs an interactive, signed-in session,
and the upload step has not been tested end-to-end from a cloud runner.

So the pipeline's promise is deliberately narrower and fully kept:

- **Before** the Studio step: every file that goes into the world is
  machine-checked on every push and every week, automatically.
- **The Studio step itself** (Play → Upload) is still a finisher step done
  in a signed-in Studio session, following the PUBLISH.md checklist kept
  with the world-building design docs, until someone proves an automated
  route for it.

If that route ever gets proven, it belongs here as a third workflow —
and this file should be updated the same day, so this section never
claims more than it does.

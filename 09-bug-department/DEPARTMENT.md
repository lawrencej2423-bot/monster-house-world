# 🐛 The Bug Department

**This department's whole job is errors and bugs. Nothing else.**

## The most important thing to know

**This department does not live on Muse. It lives on GitHub.**

It runs on GitHub's own computers (called "runners"), on GitHub's own
schedule, using GitHub's own systems. It does not need a Muse session
open. It does not use any of your Muse usage. If you run out of Muse
usage, if no agent is awake, if nobody looks at this project for a
month — the Bug Department still clocks in and does its rounds, exactly
the same. Its instructions are files in this repo
(`.github/workflows/bug-department.yml` and `auto_fixer.py` in this
folder), and GitHub reads them by itself.

Nothing in this department is an AI. It is plain, fixed machinery —
which is exactly why it can be trusted to keep running unattended.

## When it runs

- **Every time anything is pushed** to the repo (new files, edits,
  anything).
- **Every 6 hours on its own schedule**, even if nothing changed —
  so a problem that sneaks in gets caught the same day.
- **Any time a human presses the button** (Actions tab → "Bug
  Department" → "Run workflow").

## What it does, in order

1. **Auto-fix lane.** A small script (`auto_fixer.py`) walks every
   file and fixes the few problems that are *provably* safe to fix
   mechanically — no judgement calls:
   - a trailing comma in a JSON file (a comma right before a `]` or
     `}` — the classic break that makes a whole manifest unreadable),
     then tidies that file's formatting;
   - trailing spaces at the ends of lines in Lua files.
   If it fixed anything, it commits the fixes straight back to the
   repo itself, as **github-actions[bot]**, with the message
   **"bug-department: auto-fix"**. You can always see exactly what it
   touched in the commit history.
2. **Check lane.** It then runs the full set of checks on the (fixed)
   files — the same ones as a normal build:
   - every JSON manifest opens correctly,
   - every Lua script passes a real syntax check,
   - the QA bug sweep (`08-qa/sweep.py`) passes.
3. **Report lane.** If things are *still* broken after the auto-fixes:
   - it opens **one** GitHub issue titled **"🐛 Bug Department: sweep
     failing"** with the label **bug-department**, listing what failed,
     file by file;
   - if that issue is already open, it adds a comment instead — it
     never spams duplicate issues;
   - when a later run passes everything, it comments **"✅ Sweep green
     again"** on the issue and closes it.

## Where to see its work

- **Actions tab** of this repo → "Bug Department": every run, green
  (all good) or red (something needs a real fix), with a plain summary
  table at the bottom of each run.
- **Issues tab**, label **bug-department**: the department's open
  case file, when something is broken that it can't fix itself.
- **Commit history**: any commit by github-actions[bot] named
  "bug-department: auto-fix" is the department tidying up after a
  small mechanical slip.

## What it can NOT do (its honest limits)

- **It only auto-fixes punctuation-level problems.** A comma, a stray
  space. It will never rewrite game logic, move a table, change a
  design, or guess what you meant. Anything smarter than punctuation
  gets *reported*, not "fixed".
- **It cannot fix design or logic bugs.** If a script does the wrong
  thing but is spelled correctly, the department can only flag it in
  its issue. Fixing those takes an agent or a human — when one is
  available, the open bug-department issue is the first thing to read.
- **It cannot build or upload the world.** Opening Highrise Studio,
  pressing Play, and uploading to Highrise needs a signed-in Studio
  session; no GitHub machinery does that (see
  `07-pipeline/PIPELINE.md`). The department guards the *files*; the
  Studio step is still a separate finisher.
- **Free-tier minutes.** This repo is public, and GitHub Actions is
  free for public repos, so in practice the schedule costs nothing.
  If the repo ever goes private, the free plan includes a monthly
  pool of runner minutes and the 6-hour schedule would draw from it —
  if minutes ever run out, runs pause until the month resets; nothing
  breaks, the department just waits.
- **GitHub itself has to be up.** If GitHub Actions is down, the
  department waits and catches up on the next scheduled run.

## The files

| File | What it is |
|---|---|
| `.github/workflows/bug-department.yml` | The department itself: schedule, auto-fix lane, checks, issue reporting. GitHub runs this on its own. |
| `09-bug-department/auto_fixer.py` | The only hands the department has. Fixes trailing commas + trailing whitespace, logs everything, and refuses (loudly) to touch anything it can't fix safely. Has a `--dry-run` mode that only reports. |
| `09-bug-department/DEPARTMENT.md` | This charter. |

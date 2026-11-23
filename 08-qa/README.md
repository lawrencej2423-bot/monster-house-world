# 08-qa — Automatic Bug Sweeps

**What this is:** the QA section of the Monster House world repo. One
script — `sweep.py` — checks the whole repo against the design rules in
`../../DESIGN.md` (§1, §3, §5) so mistakes get caught by a machine, not
by a human doing bug sweeps by hand.

## Run it

```bash
python3 08-qa/sweep.py            # from the repo root (works from anywhere)
python3 08-qa/sweep.py --json     # + machine-readable summary
```

Exit code **0** = no failures (PENDING sections are fine). Exit code
**1** = at least one FAIL — the output names the file, line, and problem.

## What it checks

1. **JSON validity** — every `.json` file in the repo must parse.
2. **Layout geometry** — manifest objects stay inside the 40×30
   footprint, don't overlap each other, stay out of the central aisle
   (X 18–22, Z 2–22), and keep the 1.5-unit clear ring around game
   tables (DESIGN §1).
3. **Lua sanity** — delimiter balance and block (`function`/`if`/`for`/
   `while`/`do` vs `end`, `repeat` vs `until`) balance for every `.lua`
   file; uses a real `luac -p` when one is installed.
4. **Naming** — every placed object's name must be an exact DESIGN.md
   §3/§5 name (§1 naming rule).
5. **Anchors** — no file may reference a bot-station anchor
   (`BotStation_*`, `BotGreeterAnchor_*`, `HostSpot`, `TriviaScreen`)
   that doesn't exist. DESIGN-defined anchors not yet placed in a
   manifest are PENDING, not failures.

Sections still being built by other crews report as **PENDING**, never
as failures.

## Automatic runs

`.github/workflows/build.yml` (Check 3) runs this sweep on every push,
and `.github/workflows/bug-sweep.yml` re-runs it weekly and opens a
GitHub issue if a scheduled sweep fails. Results of manual runs are
recorded in `SWEEP_REPORT.md`.

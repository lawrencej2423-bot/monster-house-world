# Sweep Report — First Run

- **When:** 2026-11-22 ~16:42 PST (2026-11-23 00:42 UTC)
- **Command:** `python3 08-qa/sweep.py` (repo root:
  `~/workspace/highrise-bot/world-building/repo/`)
- **Result:** **1 FAIL · 10 PENDING · exit code 1**
- **Checks run against:** `../../DESIGN.md` §1 (global rules), §3
  (zone layout/names), §5 (bot-station anchors) — 45 expected object
  names extracted from DESIGN.

## Totals by check

| Check | Result |
|---|---|
| JSON files parse | 2 checked, 1 OK, **1 FAIL** (see §06-assets) |
| Lua sanity (15 files) | All pass (balance check — no `luac` on this machine) |
| Layout geometry (bounds / overlap / aisle / clear rings) | Nothing to check yet — no layout manifest exists (PENDING, §01-layout) |
| Object naming vs DESIGN §3/§5 | No placed objects yet (PENDING) |
| Anchor references (8 distinct) | All resolve to DESIGN §5; none placed in a manifest yet (PENDING) |

## FAILURES — per section

### 06-assets — 1 failure (for Crew 6; QA did not edit their folder)

- **`06-assets/assets_manifest.json:305` — JSON parse error:
  "Expecting property name enclosed in double quotes" (col 1).**
  The file is 304 lines / 17,630 bytes and ends abruptly at line 304
  with `],` — the enclosing array/object is never closed, so the
  parser hits end-of-file at line 305 expecting another property.
  Last modified 00:41:58 UTC, about a minute before this sweep, so
  Crew 6 may still have been writing it — but as it stands the file
  is invalid JSON and will fail the GitHub Actions sweep on push.
  **Fix:** finish/close the manifest structure (the root object and
  its arrays need their closing `]` / `}`), then re-run the sweep.

### All other sections — no failures

- **03-scripts-card-games:** all Lua files pass the balance/syntax
  sanity check. (An earlier sweep draft flagged `PokerStation.lua`
  for a block imbalance — that was a bug in QA's own checker: it
  miscounted `for seat = 1, N do` headers. Fixed in `sweep.py` and
  re-verified; the file is clean. Same for
  `04-scripts-party-games/shared/StationPresence.lua`.)
- **04-scripts-party-games:** all Lua files pass.
- **07-pipeline:** `build.yml` Check 3 already invokes
  `08-qa/sweep.py` per the PIPELINE.md contract — automatic sweeps
  on every push are wired correctly. No action needed.

## PENDING — sections still building (not failures)

- **01-layout:** folder does not exist yet. All 45 DESIGN §3/§5 names
  are unplaced: BarCounter, BlackjackSign, BlackjackTable_Main,
  BotGreeterAnchor_A, BotStation_Blackjack, BotStation_Poker,
  BotStation_RPS, BotStation_Radio, BotStation_TriviaHost,
  ChipDecor_Poker, CornerStool, DJBooth, DanceFloor, EntryArch,
  EntryBench, EntryPlanter, HostSpot, LoungePlant, LoungeRug,
  LoungeSofa_1, LoungeSofa_2, MarqueeSign, PokerSign, PokerTable_Main,
  PokerTable_Overflow, PvPBlackjackTable, RPSCircle, RPSPodium_A,
  RPSPodium_B, RPSSign, RadioInfoSign, RadioSign, SpawnPoint,
  StageScreen, StageSpeaker, Stage_Platform, TriviaScreen,
  TriviaSign, VIPBarShelf, VIPGateSign, VIPLoungeSet, VIPStairs,
  VIPTable, VIP_Platform, WelcomeSign.
- **Anchors referenced but not yet placed** (all defined in DESIGN
  §5, so these clear automatically once 01-layout lands):
  `BotGreeterAnchor_A` (06-assets/assets_manifest.json:59),
  `BotStation_Blackjack` (03-scripts-card-games/BlackjackStation.lua:22),
  `BotStation_Poker` (03-scripts-card-games/CardStationShared.lua:48),
  `BotStation_RPS`, `BotStation_Radio`, `BotStation_TriviaHost`,
  `HostSpot` (04-scripts-party-games/shared/PartyGameCommon.lua:23–25),
  `TriviaScreen` (04-scripts-party-games/shared/PartyGameCommon.lua:37).

## Watch item for the design/layout crews (not a current failure)

DESIGN §1 says the central aisle (X 18–22, Z 2–22) must stay
**completely clear of furniture**, but §3 B2 places
`BlackjackTable_Main` at center (19, 0, 18) and `PvPBlackjackTable`
at (19, 0, 11) — both inside the aisle's X-range. When the layout
manifest lands with those positions, this sweep **will** flag both
tables as aisle intrusions. §1 and §3 need one reconciled reading
before then (QA's recommendation: exempt the two blackjack tables
explicitly in §1, since §3 deliberately puts the blackjack pit
"directly ahead of the aisle" — but that's a design call, not QA's).

## QA self-verification

`sweep.py` was validated against a planted-bug fixture (in /tmp, not
in the repo) before the real run: broken JSON, an unknown object
name, an aisle intrusion, an object overlap, a clear-ring violation,
an unbalanced Lua file, and a reference to a non-existent anchor
(`BotStation_Nope`) were **all caught** with correct file/line, and
exit code 1. Two checker bugs found during validation were fixed in
08-qa's own scope: (1) DESIGN name extraction broke on the §3
plan-view code fence (found 11 names instead of 45); (2) the Lua
block counter miscounted `for`/`while` header `do`s.

## How this runs automatically

- Every push: `.github/workflows/build.yml` → Check 3 runs
  `08-qa/sweep.py`; a FAIL turns the run red.
- Weekly + on demand: `.github/workflows/bug-sweep.yml` re-runs the
  same checks and opens a GitHub issue if a scheduled sweep fails.

---

# Sweep Report — Re-run after Sweep Fix Crew

- **When:** 2026-11-22 ~16:52 PST (2026-11-23 00:52 UTC)
- **Command:** `python3 08-qa/sweep.py` (same repo root)
- **Result:** **47 FAIL · 2 PENDING · exit code 1** — down from
  **196 FAIL** at the start of this fix pass. **All 47 remaining
  FAILs are in `10-interior/interior_manifest.json` (naming only)** —
  a section outside the Sweep Fix Crew's permitted edit scope; see
  "Remaining" below. Everywhere the crew was allowed to edit is green.

## What was fixed

### 01-layout naming (60 entries reconciled in `layout_manifest.json`)

- **17 DESIGN instances** gained a `"design_name"` field with the
  exact DESIGN name (instance names stay unique — the builder skips
  in-manifest duplicates): EntryPlanter_A/B, EntryBench_A/B,
  LoungeRug_1/2, StageSpeaker_L/R, CornerStool_1–4, VIPTable_1/2,
  LoungePlant_1–3.
- **43 extra props** DESIGN never names gained `"extra_prop": true`
  + `"design_name": null` (walkway pieces, film lawn signs, rails,
  armchairs, coffee tables, bar stools, trees, fences, facade
  placeholder footprints, PvPSign, spectator stools, …).
- `sweep.py` naming check now passes a name only if it is a DESIGN
  name, maps to one via `design_name`, or is explicitly marked
  `extra_prop`. Unmarked unknown names still FAIL — no other check
  was weakened. Side effect: the 7 DESIGN names previously PENDING
  as unplaced (EntryPlanter, EntryBench, LoungeRug, StageSpeaker,
  CornerStool, VIPTable, LoungePlant) now count as placed.

### Aisle exemption (DESIGN ruling, encoded in `sweep.py`)

Per the design ruling (Jett, 2026-11-22 — §3's specific placements
win over §1's general rule): `BlackjackTable_Main` and
`PvPBlackjackTable` are exempt from the central-aisle check, as are
their clear rings where they overlap the aisle. Their own signage
travels with the exemption (`BlackjackSign` hangs at Y=4;
`PvPSign` is dressing mounted on the PvP table). Everything else in
the aisle still FAILs. This cleared the 4 aisle FAILs
(2 tables + 2 signs).

### Clear-ring corrections (encoded in `sweep.py`)

- A table's own sign is dressing for that table, not a ring
  intrusion (PokerSign, BlackjackSign, PvPSign mappings).
- Non-ground objects (`level: hanging` / `ceiling`) no longer count
  as floor-ring or aisle intrusions — cleared the hanging signs in
  both areas and `InteriorRibBeam_1` (ceiling, Y=7.4).

### Footprint: declared-area bounds (encoded in `sweep.py`)

A manifest that declares its own area (`world.grid.footprint_x/z`)
is bounds-checked against its declared 40×30 area. This cleared all
~79 interior footprint FAILs: the interior legitimately sits at the
+200 X offset its manifest declares ("two rooms but one"). Yard
manifests without a declaration are still checked against the
global 40×30.

## Remaining — 47 FAILs, all `10-interior` naming (not this crew's files)

The interior crew's shell/dressing names are not DESIGN §3/§5 names
and their manifest entries carry no `design_name` / `extra_prop`
marks yet: BarStool_1–5, ChipDecor_Poker_Overflow, CornerStool_1–4,
InteriorBarSign, InteriorCeiling_Main, InteriorChandelier,
InteriorEntryBench_East/West, InteriorEntryPoint, InteriorFloor_Main,
InteriorFurnace, InteriorMarqueeSign, InteriorPortrait_East/West,
InteriorRibBeam_1–3, InteriorTongueCarpet, InteriorWall_East/North/
South/West, InteriorWelcomeSign, LoungeCoffeeTable_1/2,
LoungePlant_1–3, LoungeRug_1/2, PvPBlackjackSign, RPSStool_1–4,
StageSpeaker_East/West, TeleportDoor_InteriorExit, VIPTable_1/2.

**Remedy (interior crew, in their own manifest):** apply the same
marking the layout now uses — `"design_name"` for DESIGN instances
(CornerStool_1–4, VIPTable_1/2, LoungePlant_1–3, LoungeRug_1/2,
StageSpeaker_East/West), `"extra_prop": true` for the interior
shell/dressing names. No sweep change is needed; the mechanism is
already in `sweep.py`. Until then the sweep stays honestly red on
that one section.

## PENDING (honest, not failures)

- `TriviaScreen` — defined in DESIGN §5 and referenced by scripts,
  but not placed as an object in any manifest (it is the script hook
  name for `StageScreen`, per the assets section). Clears when a
  manifest places it or the hook relationship is encoded.

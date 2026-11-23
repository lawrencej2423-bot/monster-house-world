# Layout — Monster House Front Yard

**File pair:** `layout_manifest.json` (the exact placements the builder uses) + this doc (the same thing in plain words).
**Plot:** 40 units wide (X, east) × 30 units deep (Z, north), origin at the south-west corner. 1 unit = 1 floor tile. Y is up.
**Spawn:** `(20, 0, 3)`, facing north — you land on the street side, looking straight up the front walkway at the house.

## How to read the manifest

Every object has: `name` (exact, matches DESIGN.md §3/§5 — scripts and bot stations reference these), `zone`, `type`, `level` (which surface it sits on: `ground`, `steps`, `porch`, `deck`, `facade`, `hanging`, `decal`, `dressing`, `roof`), `position` (x/y/z of its center), `rotation_y_deg` (0 = facing north, 90 = east, 180 = south, 270 = west), `footprint` (width × depth on the ground), and `notes`.

**97 objects, 8 zones.**

## The yard, zone by zone

- **Zone A — Entry / Street (Z 0–6, full width).** Crooked picket gate arch in the south fence, marquee sign above it, welcome/rules sign, two entry planters (dead, film-style), two benches, and LJAAYY2's greeter anchor near spawn. The floor turns from street sidewalk to walkway here.
- **The front walkway (the aisle).** One straight walk from the street to the porch: sidewalk at Z 0–2, then the 4-wide walkway **X 18–22, Z 2–22**, ending at the porch steps. This is DESIGN §1's central aisle dressed as the film house's front walk — same clear-corridor rule, nothing placed on it (one exemption, see Conflicts #1).
- **Zone B — Casino floor, yard pits (X 2–24, Z 8–22).** Poker pit NW (`PokerTable_Main` at 7.5, 18 with LJAAYY2's dealer anchor on its north side, plus the overflow table porch-side at 13.5, 20.3), blackjack pit center-north (`BlackjackTable_Main` at 19, 18 with LJAAYYBot's dealer anchor; `PvPBlackjackTable` at 19, 11), and the RPS dueling circle SW (7.5, 10) with two podiums, four spectator stools, and LJAAYY2's referee anchor just north of the circle. Low gold railings edge the pits.
- **Zone C — Chill hangout, east yard (X 26–38, Z 8–22).** Two sofa sets with armchairs, coffee tables and rugs, a bar counter with 5 stools along the east fence, three dead shrubs as dividers. No game tables here, on purpose.
- **Zone D — Trivia at the porch (X 12–28, Z 22–25).** The host stands on the porch steps (`Stage_Platform`, top Y 0.6; `HostSpot` = `BotStation_TriviaHost`, same marker). The big trivia screen (`StageScreen`, scripting hook `TriviaScreen`) and the TRIVIA NIGHT sign are mounted on the house facade above the porch; speaker stacks sit on the porch ends. The audience stands in the yard facing the house.
- **Zone E — Radio corner, NE yard (X 30–38, Z 17–23).** `DJBooth` corner booth facing south, bot radio anchor hidden behind it, LJAAYY RADIO sign above, info panel, checker dance floor in front with four corner stools.
- **Zone F — VIP overlook, west side yard.** A raised deck at Y 3.2 (X 1.5–7.5, Z 24–29) beside the house: stairs up from the yard, VIP gate sign, two small 4-seat tables, lounge set, bar shelf, south railing. Social only — no bot games up there in v1.
- **Zone H — The house (X 8–32, Z 23–30). Background only, not enterable.** Facade body, steep crooked roof, the monster-mouth porch (X 12–28, Z 23–25), two glowing orange eye windows, the open door-mouth with yellow light, porch lanterns. The facade crew owns the film-accurate detail against `repo/00-reference/REFERENCE.md`; this manifest fixes the footprint so nothing else gets placed inside it.
- **Perimeter.** Crooked picket fence all the way around, with the gate opening at the walkway (X 17–23, Z 0).

## Film-accurate yard additions (user correction, 2026-11-22)

1. **Straight front walkway** from the street/spawn side to the porch — `StreetSidewalk` → `AisleWalkway` → `FrontWalkway_NorthLink` → `Stage_Platform` steps, one straight line at X 18–22.
2. **Two hand-painted lawn signs flanking the walkway** at Z 9, facing the street: `LawnSign_KeepAway` (west, X 15.2) and `LawnSign_Beware` (east, X 23.4). Both sit outside the walkway and outside every game table's clear ring.
3. **Bare gnarled trees framing the yard on both sides of the house:** `GnarledTree_West` (6.5, 22.8) and `TwistedTree` (3.5, 21.5) on the west, `GnarledTree_East` (36.5, 22.5) on the east — all clear of table rings, stairs, and the walkway.

## Conflicts resolved (read this before re-running any sweep)

1. **Aisle vs. blackjack tables — EXEMPTION (QA ruling by Jett, 2026-11-22).** DESIGN §1 says the aisle (X 18–22, Z 2–22) must be completely clear, but §3 places `BlackjackTable_Main` (19, 0, 18) and `PvPBlackjackTable` (19, 0, 11) inside that X-range. **Ruling: the §3 placements win.** The aisle rule carries an explicit exemption for **those two tables only, including their 1.5-unit clear rings where the rings overlap the aisle** (the walkway leads into the blackjack pit; the tables are its terminus). Everything else — every other object and every other table's ring — is kept out of the aisle, and the validator enforces exactly that. Sweeps should encode the exemption for `BlackjackTable_Main` + `PvPBlackjackTable` rather than flagging them. (`BotStation_Blackjack` and `SpawnPoint` also sit in the corridor by §5/§1 design — a dealer anchor and the spawn marker, not furniture.)
2. **`PokerTable_Overflow` was on top of the RPS circle.** §3 puts the overflow table at (7.5, 0, 11) and `RPSCircle` at (7.5, 0, 10) with radius 2.5 — they occupy the same ground, and each breaks the other's clear space. Per §2 ("poker on porch-side pits in front of the house"), the overflow table moved to **(13.5, 0, 20.3)**, verified clear of all four tables' rings, the walkway, and the porch.
3. **The north RPS spectator stool was the referee's spot.** §3 rings four stools at radius 3.5 N/E/S/W of the circle; the north spot is exactly `BotStation_RPS` (7.5, 0, 13.5). The four stools now sit on the diagonals (NE/NW/SE/SW, same radius), so the referee anchor stands alone.
4. **§3's north-end rooms vs. §2's facade backdrop.** §3 zones D/E/F (stage, radio, VIP mezzanine) fill Z 23–29 as interior rooms, but §2 (the later user refinement) makes Z 23–30 the house facade backdrop — not enterable. Resolution, keeping every §5 bot station and clearance: trivia moved to the porch steps + facade screen (Zone D), radio to a corner booth in the NE yard (Zone E, `BotStation_Radio` moved with the booth, same booth-relative spot), VIP became a raised yard overlook deck in the west side yard, slimmed to X 1.5–7.5 so it never overlaps the facade footprint (X 8–32). `HostSpot` kept its Y (0.6) and center X (20.5) on the porch front.
5. **`BotStation_TriviaHost` and `HostSpot` are one marker.** §5 says the trivia anchor IS the HostSpot floor marker, so the manifest carries `HostSpot` plus a `BotStation_TriviaHost` entry flagged `co_located_with: HostSpot` — an alias for the name check, not a second placed object.
6. **The PvP sign post had nowhere legal to stand.** §3 wants a "PvP" sign post beside `PvPBlackjackTable`, but every beside-spot is inside that table's own clear ring (or in the walkway). `PvPSign` is therefore mounted on the table's south edge as table dressing.
7. **Fence corners (caught by this crew's own validator).** The first pass double-covered the four corner squares where fence segments met. Side fences were trimmed to butt against the end fences; re-validation is clean.

## Validation (self-run, 2026-11-22)

- `python3 -m json.tool layout_manifest.json` — **valid JSON**.
- Custom geometry sweep (same rules QA runs): required-field and unique-name check, DESIGN §3/§5 name coverage (all singletons exact; multiples as suffixed instances), spawn point exact, pairwise footprint overlap per surface level, aisle intrusion (with Conflicts #1 exemption), 1.5-unit clear rings around all four game tables, facade-band exclusivity (X 8–32, Z 23–30).
- **Result: ALL CHECKS PASSED** — 97 objects, 0 overlaps, 0 aisle intrusions beyond the ruled exemption, 0 ring intrusions, facade band clean. First run caught the fence corners (Conflicts #7); fixed and re-run clean.

## Scope notes

- Facade *detail* (teeth, brow roofline, chimney, siding) belongs to the facade crew against `repo/00-reference/REFERENCE.md` — this manifest only fixes facade/porch footprints and the mounted pieces' positions (eyes, door, screen, signs, lanterns).
- The later design change moving the games *inside* the house via the teleport door (interior crew) does not change this yard: the yard, walkway, signs, trees, porch, and facade placements stand as the world's exterior either way.

## Naming reconciliation (Sweep Fix Crew, 2026-11-22)

The QA sweep requires every placed object to carry an exact DESIGN.md
§3/§5 name. This manifest's entries now declare their relationship to
DESIGN explicitly, in two ways:

- **DESIGN instances** — the entry IS a DESIGN object, placed more
  than once. The entry keeps a unique instance name (the builder
  skips in-manifest duplicate names, so two entries both named
  `EntryPlanter` would lose one planter) and gains a `"design_name"`
  field holding the exact DESIGN name:
  `EntryPlanter_A/B → EntryPlanter`, `EntryBench_A/B → EntryBench`,
  `LoungeRug_1/2 → LoungeRug`, `StageSpeaker_L/R → StageSpeaker`,
  `CornerStool_1–4 → CornerStool`, `VIPTable_1/2 → VIPTable`,
  `LoungePlant_1–3 → LoungePlant`.
- **Extra props** — legitimate dressing DESIGN never names. These
  entries are marked `"extra_prop": true` with `"design_name": null`:
  the walkway/sidewalk pieces, the film-accurate `LawnSign_KeepAway` /
  `LawnSign_Beware`, pit rails, lounge armchairs/coffee tables, bar
  stools and sign, spectator stools, `PvPSign`, VIP rail, the gnarled
  trees, the fence run, and the facade placeholder footprints
  (`MonsterHouse_Facade`, `MonsterHouse_Roof`, `HousePorch`,
  `EyeWindow_L/R`, `DoorMouth`, `PorchLantern_L/R`) whose detail
  belongs to the facade crew.

The sweep (`08-qa/sweep.py`) accepts a name only if it is a DESIGN
name, maps to one via `design_name`, or is explicitly marked
`extra_prop` — unmarked unknown names still fail.

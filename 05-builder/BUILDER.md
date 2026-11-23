# WorldBuilder — `builder.lua` in plain words

**What this is:** one Lua script that builds the Monster House world for us.
Instead of a person dragging hundreds of objects around in Highrise Studio
by hand, the layout crew and the house-facade crew each write a *manifest* —
a list that says "put this thing, with this exact name, at this exact spot."
The builder reads the combined list and places everything, the same way,
every time. If a name or a spot changes, we change the list and re-run —
nobody re-does hand placement.

**Why the names matter:** the design (DESIGN.md §1) gives every object an
exact name like `PokerTable_Main` or `BotStation_Poker`. The bots and the
other world scripts find objects *by those names*. The builder never renames
anything — the placed object gets the manifest name, character for character.

**Safe to re-run (idempotent):** before placing anything, the builder checks
whether an object with that name is already in the world. If it is, it skips
it and says so in the log. Running the builder twice does **not** create
doubles. It also catches the same name appearing twice inside one manifest
(first one wins, the rest are logged as duplicates). There is a
`FORCE_REBUILD` switch in the script (default **off**) that destroys and
re-places same-named objects — only turn it on deliberately.

**Grouped by zone:** the builder works zone by zone (entry, casino floor,
facade, …) and logs a header, one line per object (placed / skipped /
missing-template), and a per-zone and grand-total summary, all prefixed
`[Builder]`. If the summary says `0 errors`, the build is clean.

---

## How the finisher runs it (Highrise Studio)

1. Create an empty object in the scene named **`WorldBuilder`**, attach
   `builder.lua` to it.
2. Create an empty object named **`BuilderTemplates`**, keep it **inactive**,
   and put one child object per *asset key* the manifests use (see
   "Templates" below). These are the stock objects the builder clones.
3. Add the **`Placements`** Module script (see "What the builder loads").
4. Press **Play**. The build runs once, on start. Read the `[Builder]` log.
5. Stop, save the scene, and Upload (per PUBLISH.md). To re-run after a fix,
   call the global `BuildWorld()` again, or just press Play again — re-runs
   skip what's already placed.

---

## What the builder loads

Highrise Lua scripts can't read files off a disk, so the JSON manifests are
turned into one **Module script named `Placements`** by the repo pipeline
before the project is opened in Studio. That module returns the *combined*
placements list from both section manifests:

- `repo/01-layout/layout_manifest.json`
- `repo/02-house-facade/facade_manifest.json`

Either module shape works — a table with a `placements` array, or the array
itself:

```lua
--!Type(Module)
-- Placements.lua (generated from the two JSON manifests -- do not hand-edit)
return {
    placements = {
        { name = "PokerTable_Main", asset = "PokerTable", x = 7.5, y = 0, z = 18,
          rotation = 0, zone = "B_CasinoFloor", part = "layout" },
        -- ...every entry from both manifests...
    },
}
```

If no usable `Placements` module is in the project, the builder falls back
to a tiny built-in smoke-test list (4 entries with coordinates copied from
DESIGN.md §3/§5: `SpawnPoint`, `WelcomeSign`, `PokerTable_Main`,
`BotStation_Poker`) and logs that it used the fallback. That fallback is
only for proving the builder works — the real build always comes from the
manifests.

> **Status when this was written:** the two JSON manifests did not exist
> yet (crews 01 and 02 were still writing them in parallel). The builder was
> written and tested against the schema below, and it tolerates the spelling
> variants listed there, so the manifests can land as-is.

---

## The manifest schema (exact)

Each section manifest is a JSON object with a `placements` array. Each entry
in the array is one object to place:

```json
{
  "version": 1,
  "placements": [
    {
      "name": "PokerTable_Main",
      "asset": "PokerTable",
      "x": 7.5,
      "y": 0,
      "z": 18,
      "rotation": 0,
      "zone": "B_CasinoFloor",
      "part": "layout"
    },
    {
      "name": "Facade_EyeWindow_L",
      "asset": "EyeWindow",
      "x": 14,
      "y": 6,
      "z": 30,
      "rotation": 180,
      "zone": "Facade",
      "part": "facade",
      "scale": { "x": 2, "y": 2, "z": 1 },
      "notes": "left eye of the angry facade -- glows amber"
    }
  ]
}
```

### Fields

| Field | Required | Type | Meaning / rules |
|---|---|---|---|
| `name` | **Yes** | string | The exact in-world object name, copied character-for-character from DESIGN.md §3/§5. Must be unique across **both** manifests combined. Missing/empty → entry is INVALID (logged, skipped). |
| `x`, `z` | **Yes** | number | Ground-plane position on the DESIGN grid (1 unit = 1 tile, X east, Z north, origin at the south-west corner). Missing/non-numeric → INVALID. |
| `y` | No | number | Height. Default `0` (floor top surface is Y=0). |
| `asset` | No | string | Which template to clone (see "Templates"). Default: the entry's own `name`. Aliases the builder also accepts: `prefab`, `template`, `model`. |
| `rotation` | No | number or object | Facing, in degrees. A plain number means yaw (turn around the up axis; `0` = facing +Z/north, `180` = facing −Z/south). An object `{ "x":…, "y":…, "z":… }` (or `{ "yaw":… }`) gives full Euler angles. Separate `rotationY` or `yaw` fields also work. Default `0`. |
| `zone` | No | string | Grouping label used for the log sections and summaries (e.g. `"A_Entry"`, `"B_CasinoFloor"`, `"Facade"`). Zones are built in the order they first appear in the combined list. Default `"Unzoned"`. |
| `part` | No | string | Which section/manifest the entry came from (`"layout"`, `"facade"`, …). Shown in the placement log line. Alias: `section`. |
| `scale` | No | number or object | A number scales uniformly; `{ "x":…, "y":…, "z":… }` scales per axis. Absent → the clone keeps the template's own scale. |
| `active` | No | boolean | Whether the placed object starts switched on. Absent → the builder activates it (templates are stocked inactive, so clones need this). |
| `position` | No | object | Alternative to flat `x`/`y`/`z`: `{ "x":…, "y":…, "z":… }`. Flat fields win if both are given. |
| `notes` | No | string | Free text for humans. The builder ignores it. |

Any other fields are ignored by the builder, so manifests may carry extra
data (materials, colors, asset-catalog IDs) for other tools without breaking
the build.

### Coordinates reminder (from DESIGN.md §1)

- Footprint 40 (X) × 30 (Z); the north end (Z 23–30) is the Monster House
  facade backdrop — the playable space is the front yard in front of it.
- Central aisle X 18–22, Z 2→22 stays completely clear; every game table
  keeps a 1.5-unit clear ring. The builder places what the manifest says —
  keeping the manifest inside these rules is the layout crew's job, and the
  QA crew's checks enforce it.

---

## Templates (the stock shelf)

- One scene object named **`BuilderTemplates`**, kept inactive, with one
  child per `asset` key used anywhere in the manifests. The child object's
  name **is** the asset key (e.g. a child named `PokerTable`).
- The builder clones the template, renames the clone to the entry's exact
  `name`, moves/rotates/scales it, parents it under **`BuiltWorld`** (created
  automatically if missing), and activates it.
- Template names must never collide with placement `name`s — keep the two
  sets distinct (e.g. asset `PokerTable` → placements `PokerTable_Main`,
  `PokerTable_Overflow`).
- If a template is missing, the builder logs
  `MISSING TEMPLATE '<asset>' for '<name>' -- skipped` and moves on. It only
  substitutes a plain cube placeholder if the engine exposes a
  create-primitive call; either way the log tells you exactly which asset
  keys still need stocking.

---

## Reading the log

```
[Builder] === WorldBuilder starting ===
[Builder] placements source: Placements module (.placements table) (128 entries)
[Builder] --- Zone: A_Entry (9 objects) ---
[Builder] PLACED WelcomeSign (WelcomeSign) @ (16.5, 1.6, 5.8) rotY=180 [layout]
[Builder] SKIP MarqueeSign (already in world)
[Builder] WARNING: MISSING TEMPLATE 'EyeWindow' for 'Facade_EyeWindow_L' -- skipped
[Builder] ERROR: INVALID placement: 'BrokenEntry' is missing a numeric x/z position
[Builder] Zone A_Entry done: 7 placed, 1 skipped, 1 missing-template, 0 errors
[Builder] === WorldBuilder done: 120 placed, 5 skipped, 2 missing-template, 1 invalid, 0 errors ===
```

- `PLACED` — cloned and positioned this run.
- `SKIP … (already in world)` — idempotency working; not an error.
- `DUPLICATE name … in manifest` — the combined list has that name twice;
  fix the manifests, not the builder.
- `MISSING TEMPLATE` — stock that asset key under `BuilderTemplates`.
- `INVALID placement` — the manifest entry is broken (see the reason given).
- `ERROR` / `exception placing` — an engine call failed for that one entry;
  the build continued with the rest.

---

## Honesty register (API verification)

Following the project convention from SCRIPTS.md §0/§6:

- **Verified in the official docs:** the `--!Type(Server)` header,
  `self:ServerStart()` lifecycle, `GameObject.Find(name)`, `Vector3`,
  and `require("ModuleName")` for Module scripts.
- **Standard Unity-pattern calls the checked docs did not explicitly show:**
  `GameObject.Instantiate`, `GameObject.Destroy`, `GameObject.new`,
  `Transform:Find`, `Quaternion.Euler`, `SetActive`,
  `GameObject.CreatePrimitive`. Every one of them is wrapped so that if it
  fails in the real engine, that entry logs an `ERROR` and the build
  continues — but they still need confirming in the first Play-mode run in
  Studio before anyone trusts a full build.

## Checks run on this script (2026-11-22, by the builder crew)

No `luac` exists on this machine, so the script was checked two ways:

1. **Balance/syntax sanity (Python):** strings and comments stripped, then
   bracket balance and block-keyword balance (`function/if/for/while/do/
   repeat` vs `end/until`) verified — **PASS** (472 lines).
2. **Real execution under a stubbed Highrise/Unity API** (Lua via `lupa`,
   with a fake scene, template shelf, and a test `Placements` module
   exercising flat + nested positions, numeric + table rotations, scale,
   a duplicate name, an invalid entry, and a missing template):
   - Run 1: **4 placed, 1 skipped (duplicate), 1 missing-template,
     1 invalid, 0 errors** — as expected.
   - Run 2 (idempotency): **0 placed, 5 skipped**, scene size unchanged —
     **PASS** after one fix (below).
   - Fallback path (no `Placements` module): built-in list placed 4,
     re-run skipped all 4 — **PASS**.

**Bug found by the execution test and fixed:** the first version checked
"already placed?" with `GameObject.Find(name)` only. When a placement's name
equals its template's name (e.g. `WelcomeSign`), Find returns the *template*
first, the placed clone hides behind it, and a re-run would have placed a
double. The builder now looks under its own `BuiltWorld` root first (where
everything it places lives) before falling back to a scene-wide Find. The
re-run of the test after the fix is the PASS above.

# 10 — Interior: the games inside the house

**The design change (user, 2026-11-22):** the games move **inside** the
Monster House. Players walk up to the front door in the yard — or tap it —
and are teleported into a full game floor inside the house. An exit door
inside teleports them back out to the yard. The user's words: *"like two
rooms but one."*

So this world is now **one world, two areas**:

| Area | What it is | Built by |
|---|---|---|
| **A — The yard** | Spawn, street, walkway, lawn signs, gnarled trees, and the ~95% replica Monster House facade standing at the north end, mouth open, looking mad. No game tables out here anymore. | 01-layout, 02-house-facade, 00-reference |
| **B — The interior** (this section) | A complete enclosed game floor — entry, poker pit, blackjack pit, RPS pit, lounge, trivia stage, radio corner, VIP mezzanine — dressed as the inside of the creature: warped floorboards, a red hall carpet that is the house's tongue, rib-like ceiling beams, a furnace for a heart, amber light. | 10-interior (`interior_manifest.json`) |

The stations inside are the **same stations** from DESIGN.md §3/§5 — same
exact object and anchor names (`PokerTable_Main`, `BotStation_Blackjack`,
…), same bots dealing (LJAAYYBot on blackjack, LJAAYY2 on poker). Only
their coordinates changed. Game logic still lives in the bots, exactly as
SCRIPTS.md §4 says; this section is furniture, anchors, and the doors.

---

## Where the interior sits, and why you can't see it

The interior is built in the **same scene**, on the **same ground plane**
(floor top at Y=0), shifted **200 units east**:

> **Every interior coordinate = the DESIGN.md coordinate with X + 200.
> Z and Y do not change.**

The interior hall occupies X 200–240, Z 0–30 — the DESIGN 40×30 grid,
picked up and set down 200 units east, then wrapped in a sealed shell
(floor, four walls, ceiling at Y=8, no windows).

Why this offset and not somewhere else:

- **Same Y=0 plane** — gravity, floor collision, sitting, triggers and
  spawn behaviour all work exactly as they do in the yard. Nothing about
  the proven yard setup changes.
- **Invisible from the yard** — there are 160 units of empty space
  between the yard's east edge (X=40) and the interior's west wall
  (X=200), far beyond any sightline from the yard (the facade is ~11
  units tall; players look at the house, not 200 units sideways into
  nothing). The sealed shell also means no light leaks in either
  direction: the yard's night sky is never visible from inside, and the
  interior's amber glow never shows in the yard.
- **Why not underneath the yard** — a negative-Y box risks fall/respawn
  weirdness (a physics slip in the yard could drop a player *into* the
  casino), shadow/lighting oddities, and confusing height reads. The
  flat east offset has none of those failure modes.
- **The +200 rule makes integration mechanical** — every hardcoded centre
  in the already-built scripts changes by exactly `x + 200` (full list
  below). No re-layout, no new proportions to argue about.

One scene also means one player list and one chat: the bots' chat
commands (`!poker`, `!blackjack`, …) are heard the same inside and out,
which is what we want — the door changes where you *stand*, not which
world you're in. (Assumption to confirm in the first Play test — see
Unverified, item 6.)

---

## The door flow

**Going in (yard → interior):**

1. Player walks up the walkway to the porch — into the mouth — and
   either **walks into the front-door trigger** or **taps the door**.
2. Their client sends one request naming the door. It claims nothing
   else.
3. The **server** checks: the avatar really is at the door (within
   3 units of the trigger centre at (20, 0, 22.6)) and the player isn't
   on teleport cooldown.
4. Server moves the avatar to the **interior entry landing
   (220, 0, 3)**, facing north — down the tongue carpet, tables and
   stage ahead, welcome sign on the left. Same first-glance read as
   spawning in the yard, on purpose.

**Coming out (interior → yard):**

1. Player walks to the door in the interior's south wall
   (`TeleportDoor_InteriorExit`) and taps it or walks into it.
2. Same server validation (trigger centre (220, 0, 0.9)).
3. Server moves them to **(20, 0, 21.5)** — on the walkway in front of
   the porch, facing south, looking back across the yard.

**Anti-bounce:** both landing points sit *outside* the opposite door's
trigger volume (interior landing Z=3 vs exit volume ending at Z=1.6;
yard landing Z=21.5 vs yard volume starting at Z=22.0), and the script
adds a **4-second per-player cooldown** after every teleport. Nobody
ping-pongs.

Script: [`TeleportDoor.lua`](TeleportDoor.lua) — one copy attached to
each door object; each copy self-identifies by its object name, the
same pattern the card-station scripts use.

---

## What must change in the already-built scripts (integration pass)

The 03/04 crews hardcoded yard-grid centres. The rule is **x + 200,
z and y unchanged**. Everything below is the complete list — grep for
the old numbers to double-check nothing is missed.

### A. `03-scripts-card-games/CardStationShared.lua` — FUNCTIONAL (config values)

This module is the card stations' source of truth for centres and
anchor positions (used for sign/prompt reference and builder checks;
live seat distance checks use the real object transforms, but stale
values here would mislead signs, warnings, and builders).

| Entry | Field | Old (yard) | New (interior) |
|---|---|---|---|
| `PokerTable_Main` | `center` | (7.5, 0, 18) | **(207.5, 0, 18)** |
| `PokerTable_Main` | `anchorPos` (`BotStation_Poker`) | (7.5, 0, 20.2) | **(207.5, 0, 20.2)** |
| `PokerTable_Overflow` | `center` | (7.5, 0, 11) | **(207.5, 0, 11)** |
| `PokerTable_Overflow` | `anchorPos` | (7.5, 0, 20.2) | **(207.5, 0, 20.2)** |
| `BlackjackTable_Main` | `center` | (19, 0, 18) | **(219, 0, 18)** |
| `BlackjackTable_Main` | `anchorPos` (`BotStation_Blackjack`) | (19, 0, 19.8) | **(219, 0, 19.8)** |
| `PvPBlackjackTable` | `center` | (19, 0, 11) | **(219, 0, 11)** |
| `PvPBlackjackTable` | `anchorPos` | (19, 0, 19.8) | **(219, 0, 19.8)** |

### B. `03-scripts-card-games/PokerStation.lua` / `BlackjackStation.lua` — comments only

Header comments quote the old centres (PokerStation lines 5–6 and the
`BotStation_Poker` note ~line 21; BlackjackStation lines 6–7 and the
`BotStation_Blackjack` note ~line 22). No behaviour change — update the
numbers so the next reader isn't misled:
`7.5 → 207.5` (poker), `19 → 219` (blackjack), z values unchanged.

### C. `04-scripts-party-games/shared/PartyGameCommon.lua` — FUNCTIONAL (validation values)

`ANCHOR_POS` and `PODIUM_POS` are used by the **server** to
distance-validate station-occupation claims. If these stay on yard
coordinates, every interior presence claim fails validation. These are
the most important changes in this list.

| Constant | Key | Old (yard) | New (interior) |
|---|---|---|---|
| `ANCHOR_POS` | `BotStation_TriviaHost` | { x = 20.5, z = 26.5 } | **{ x = 220.5, z = 26.5 }** |
| `ANCHOR_POS` | `BotStation_RPS` | { x = 7.5, z = 13.5 } | **{ x = 207.5, z = 13.5 }** |
| `ANCHOR_POS` | `BotStation_Radio` | { x = 34, z = 27.8 } | **{ x = 234, z = 27.8 }** |
| `PODIUM_POS` | `RPSPodium_A` | { x = 5.5, z = 10 } | **{ x = 205.5, z = 10 }** |
| `PODIUM_POS` | `RPSPodium_B` | { x = 9.5, z = 10 } | **{ x = 209.5, z = 10 }** |

Also update the position comments beside `ANCHOR_TRIVIA_HOST` /
`ANCHOR_RPS_REFEREE` / `ANCHOR_RADIO` (lines ~23–25) and the podium
comments (~lines 47–48) to the new numbers.

### D. `04-scripts-party-games` station scripts — comments only

- `radio/RadioBooth.lua` header (~lines 3, 9): `DJBooth` centre
  (34, 0, 27) → **(234, 0, 27)**; `BotStation_Radio` (34, 0, 27.8) →
  **(234, 0, 27.8)**.
- `rps/RPSArena.lua` header (~lines 3, 8): `RPSCircle` centre
  (7.5, 0, 10) → **(207.5, 0, 10)**; `BotStation_RPS` (7.5, 0, 13.5) →
  **(207.5, 0, 13.5)**.
- `rps/RPSArenaUI.lua` header (~line 3): `RPSSign` post
  (7.5, 1.8, 7.8) → **(207.5, 1.8, 7.8)**.
- `trivia/TriviaStage.lua`: no hardcoded centre found — nothing to
  change (it keys off object names).

### E. `01-layout/layout_manifest.json` — REMOVE the yard station copies

Scene object names must be unique: `GameObject.Find("PokerTable_Main")`
cannot be allowed to find two tables. The interior manifest is now the
single home of every station object. Remove these from the yard layout
(yard positions as currently placed there in brackets — several differ
from DESIGN, which is exactly why they must not survive as duplicates):

`PokerTable_Main` (7.5,0,18) · `PokerTable_Overflow` (13.5,0,20.3) ·
`BotStation_Poker` (7.5,0,20.2) · `BlackjackTable_Main` (19,0,18) ·
`PvPBlackjackTable` (19,0,11) · `BotStation_Blackjack` (19,0,19.8) ·
`RPSCircle` (7.5,0,10) · `RPSPodium_A` (5.5,0,10) · `RPSPodium_B`
(9.5,0,10) · `RPSSign` (7.5,1.8,7.8) · `BotStation_RPS` (7.5,0,13.5) ·
`Stage_Platform` (20.5,0,22.6) · `StageScreen` (20.5,4.6,24.9) ·
`HostSpot` (20.5,0.6,22.6) · `BotStation_TriviaHost` (20.5,0.6,22.6) ·
`TriviaSign` (20.5,6.5,24.9) · `DJBooth` (34,0,21.3) · `BotStation_Radio`
(34,0,22.3) · `RadioSign` (34,4.5,21.3) · `RadioInfoSign` (31.5,1.6,20.8) ·
`DanceFloor` (34,0,19.3) — and any `CornerStool` / stage-speaker /
lounge / VIP copies the yard layout placed from the same §3 list.

The yard keeps: spawn, street/gate, walkway, KEEP AWAY / BEWARE signs,
trees, facade, and yard dressing.

**ADD to the yard:** one new object — `TeleportDoor_Yard`, an invisible
trigger box (~3 wide × 2 high × 1.2 deep) centred at **(20, 0, 22.6)**
in front of the facade's front door (door is centred on the facade per
REFERENCE.md), with a trigger Collider, a TapHandler on the door itself,
and a copy of `TeleportDoor.lua` attached. (Full linkage spec in
`interior_manifest.json` → `door_linkage`.)

### F. `02-house-facade` — make the front door functional

The replica facade itself doesn't move. Its front door gains: the
trigger volume above, a TapHandler, and the `TeleportDoor.lua` copy.
The door stays centred and keeps pouring its #FFD76A light (REFERENCE
checklist) — walking into that light is now literally how you enter.

### G. `05-builder/builder.lua` — fallback list + manifest loading

- The built-in smoke-test fallback list (~lines 73–74) hardcodes
  `PokerTable_Main` (7.5, 0, 18) and `BotStation_Poker` (7.5, 0, 20.2).
  Change to **(207.5, 0, 18)** and **(207.5, 0, 20.2)**.
- The builder's combined placements list must now also include
  `10-interior/interior_manifest.json`'s `objects` alongside the layout
  and facade manifests (same schema — `name`, `position{x,y,z}`,
  `rotation_y_deg`, `zone`).

### H. `08-qa/sweep.py` — teach the sweep about the second area

The sweep's geometry checks assume the single 40×30 yard footprint and
the X 18–22 aisle. Interior objects at X 200–240 will false-fail both.
The sweep needs: a second legal footprint (X 200–240, Z 0–30), the
interior aisle (X 218–222, Z 2–22) with the **same blackjack exemption**
(`BlackjackTable_Main`, `PvPBlackjackTable`, `BotStation_Blackjack`),
and a duplicate-name check across the layout + interior manifests
(catches §E regressions automatically). Flagged for the QA / Bug
Department crews — not changed here (not this section's folder).

### I. `DESIGN.md` — spec note for the design lead

DESIGN.md §2's refinement ("the playable world is the front yard, not
the interior… the north end is the house facade backdrop, not enterable
interior rooms in v1") is **superseded** by the user's 2026-11-22 design
change. §3/§5 coordinates now describe the interior's local grid
(world X = §3 X + 200). DESIGN.md itself is outside this section's
folder — flagged here for the parent/design lead to amend.

---

## Files in this section

| File | What it is |
|---|---|
| `interior_manifest.json` | Every interior placement (same schema as 01-layout): shell, entry + exit door, all game stations at interior coordinates with exact §3/§5 names, lounge/stage/radio/VIP, and the alive-inside dressing. Plus the `door_linkage` block specifying the yard-side door object. |
| `TeleportDoor.lua` | ClientAndServer script for both doors: tap + walk-in on the client, server-validated move with cooldown. Attach one copy to `TeleportDoor_Yard`, one to `TeleportDoor_InteriorExit`. |
| `INTERIOR.md` | This file. |

**Studio setup checklist (doors):**

- [ ] `TeleportDoor_InteriorExit` placed per the manifest, trigger
      Collider (volume Z 0.2–1.6) + TapHandler + `TeleportDoor.lua`.
- [ ] `TeleportDoor_Yard` placed per §E, trigger Collider + TapHandler
      on the facade door + `TeleportDoor.lua`.
- [ ] Interior shell built with NO gaps (check from the yard at night:
      no amber light leaks; from inside: no sky visible).
- [ ] All station objects present **once** — search the scene for each
      §5 anchor name and confirm exactly one hit, inside the interior.

**Play-test checklist (doors):**

- [ ] Walk into the yard front door → land at (220, 0, 3) facing north.
- [ ] Tap the yard front door from the walkway → same result.
- [ ] Walk into / tap the interior exit door → land at (20, 0, 21.5)
      facing south, in front of the porch.
- [ ] Stand at a table and fire a door request (modified client) →
      server rejects it (distance check log line).
- [ ] Use a door twice quickly → second use inside 4 s does nothing
      (cooldown); after 4 s it works.
- [ ] Land from a teleport and stand still 10 s → no bounce back
      (landing points are outside the trigger volumes).
- [ ] **The move itself** — if the avatar does NOT move on any of the
      above, the position-write call is the unverified piece (see
      below); everything else (triggers, validation, cooldown) should
      still log correctly.
- [ ] Sit at a poker table, then (after standing) use the door — and
      separately: note what happens to a seat if a seated player could
      somehow teleport (expected: blocked by distance — confirm).

---

## What is unverified (honest register, SCRIPTS.md §6 style)

1. **The position-write move call.** The checked docs verify *reading*
   `player.character.transform.position` (distance checks) — they show
   no example of *setting* it to teleport a player.
   `TeleportDoor.lua` writes `transform.position = Vector3(x, y, z)`
   inside `pcall`: if it fails in Play mode, the error prints, the
   player stays put, nothing else breaks. **This is the #1 Play-test
   item.** If the write doesn't move avatars, the follow-up is a
   Studio-API research task (character teleport/respawn call) — the
   door system around it doesn't change.
2. **Facing write.** `transform.rotation = Quaternion.Euler(0, yaw, 0)`
   is a second, independent `pcall`. Quaternion was not in the checked
   docs. If it fails, teleports still work; players keep their old
   facing. Cosmetic only.
3. **Cooldown clock.** `os.time()` is standard Lua and the docs' Wallet
   example uses `os.date`, so the `os` library exists — but `os.time`
   specifically is not in a checked example. Worst case the cooldown
   misbehaves and gets swapped for a frame/tick counter in Play test.
4. **Seat state across a teleport.** Station scripts free seats on
   tap-stand and on disconnect. A teleported player is still connected,
   and the door's distance check means a *seated* player can't reach a
   door — so the case should be impossible. Confirm in Play test; if a
   seat can be stranded, the v1.1 fix is a teleport event the station
   scripts can listen for (not built here).
5. **Bots inside a World** — unchanged from SCRIPTS.md §6 item 5. The
   anchors are named, positioned objects; whether the Python bots can
   stand at them inside a Studio World is still unverified. The games
   run on chat either way.
6. **One-scene assumptions.** One scene = one player list / one chat is
   the standard reading of the checked docs (`scene.PlayerJoined` is
   per-scene), but nobody has run this two-area layout yet. Confirm in
   Play test that a player inside the interior hears yard chat and vice
   versa, and that `scene.PlayerJoined` fires once per player, not per
   area.
7. **Trigger-on-landing.** Landing points are placed outside the door
   volumes by geometry, but whether `OnTriggerEnter` can fire from a
   teleport landing *near* a volume edge is a Play-mode behaviour —
   covered by the 10-second stand-still checklist item above, with the
   cooldown as backstop.

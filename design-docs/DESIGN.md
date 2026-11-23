# Highrise World Design Spec — Faceless / LJAAYY

**Owner:** LJAAYY (owner user ID `62606c8bd2268ffe576634c1`)
**Purpose:** A permanent home world for LJAAYY's two game bots — LJAAYYBot (bot #1) and LJAAYY2 (bot #2) — which run poker, blackjack, RPS, and trivia. Today those games live in borrowed rooms ("Real Gamblers", "DEAL OR NO DEAL", "DIE MAD"). This world gives the bots a floor that is designed around the games, so players spawn, find a table, and play without the bots or players crowding each other.
**Build target:** Highrise Studio project (Unity scene + Lua), executable by a builder agent via the `Library/Highrise/hr` launcher path. All coordinates below use a single ground-plane grid so the builder can place objects without guessing.

---

## 1. Coordinate system & global rules (builder: read first)

- **Units / axes:** 1 unit = 1 floor tile. X = east (+ right on plan), Z = north (+ up on plan), Y = up. Floor top surface at Y = 0.
- **Footprint:** Main hall **40 (X) × 30 (Z)** units, origin (0,0) at the **south-west corner** of the hall floor. Ceiling height 8 units (open-beam, no second floor except the VIP mezzanine, §3.6).
- **Walls:** Perimeter walls on all four sides, height 8, except: south wall has the entry arch (see Zone A); north wall behind the stage is a full accent wall.
- **Spawn point:** `(20, 0, 3)`, facing north (+Z) — players land inside the entry, looking straight down the central carpet to the casino floor and stage.
- **Central aisle:** A 4-wide carpet runner from (18–22, Z 2→22) — keep **completely clear of furniture** at all times. This is the player highway; no table, seat, or decor may intrude.
- **Clearance rule:** Every game table keeps a **1.5-unit clear ring** around it (players stand/sit there to play). No decor inside the ring.
- **Lighting plan (global):** Warm ambient overall; each zone gets its own accent color (§3). Use emissive trim + point lights, not more geometry, to separate zones — cheaper to build and reads clearly in-world.
- **Naming rule:** Every placed gameplay object gets the exact `name` given in §3 (e.g. `PokerTable_Main`). Bot station anchors (§5) must use the exact anchor names — bot code and future scripts will reference them.
- **Asset rule:** Prefer stock Highrise Studio catalog items matching the descriptions. Where a custom item is named (e.g. the marquee sign), build it from primitives + a text/emoji sign panel; do not block the build waiting on a custom asset.

---

## 2. Theme & name

### Style direction — USER PICK 2026-11-22, UPDATED: "the house off Monster House"

Supersedes the earlier picks the same day (first *The Boondocks* house, then a Chum Bucket image the user sent) — the user explicitly changed it: "Change it from the chum bucket to Monster House" / "The house off Monster House."

The 3D space must look like a cartoon haunted house, specifically inspired by the house in *Monster House* (the user described it as "the Cartoon Network original movie"): a crooked, looming suburban house that feels alive — warped / leaning wood siding, a steep shingled roof, windows placed and lit like watchful eyes, the front door and porch like a mouth, creaky front porch, bare twisted tree and dead lawn out front, autumn / Halloween mood, dim amber light from inside, bold cartoon outlines, exaggerated tilts and proportions. NOT a literal replica of the copyrighted house — an original house in that style/mood.

**Setting refinement — USER 2026-11-22:** The playable world is the **front yard** of that house, not the interior. The Monster House itself sits in the **background, looking mad** — angry face in the facade (eyes = upper windows, mouth = door/porch), looming over the yard. Players spawn and play in the yard in front of it. The casino/bot functions (§3, §5) get dressed INTO the front yard: poker/blackjack on yard tables / porch-side pits in front of the house, trivia facing the house / on a yard stage corner, radio in a corner booth, VIP as a raised porch / yard overlook. The §3 grid becomes the yard layout — the north end (Z 23–30) is the house facade backdrop, not enterable interior rooms in v1. If the yard dressing and the §3 casino grid conflict, keep the §3 bot stations and clearances, and change materials/props to the Monster House front-yard style.

### Lead concept — Gamblers' Casino Lounge (RECOMMENDED)

A neon-and-velvet casino lounge built *for* the bots' games: a real casino floor where poker, blackjack, and RPS each have a dedicated pit, a stage for trivia nights, a radio corner running LJAAYY Radio, and a VIP mezzanine for high rollers. It extends the rooms that already work for him ("Real Gamblers", "DEAL OR NO DEAL") into a world he owns.

**Name options (lead first):**
1. **REAL GAMBLERS** — matches his existing room name; players who know the bot already know the brand. *(Recommended)*
2. **LJAAYY'S HOUSE** — "the house always wins" framing; personal brand.
3. **DEAL OR NO DEAL CASINO** — carries over his bot #1's home-room name.

**Palette:** Deep green felt + black + gold trim, neon magenta/cyan accent signage. Floor: dark wood border, green carpet field, gold-trim red central runner.

### Alternate A — Neon Arcade / Game Show Studio

Bright TV-studio take on the same layout: the trivia stage becomes the hero (big screen, buzzers), game pits become "show floors." Names: **DEAL OR NO DEAL LIVE**, **LJAAYY GAME NIGHT**. Palette swaps green felt for glossy black floors, white light strips, saturated primary signage. Layout in §3 is unchanged — only materials, signage text, and stage dressing change.

### Alternate B — Chill Rooftop Lounge

Low-key social hangout first, games second: open-air rooftop at night, string lights, skyline backdrop; tables shrink to a corner "games deck," stage becomes an acoustic corner. Names: **THE ROOFTOP**, **LJAAYY LOUNGE**. Palette: navy/indigo night, warm string-light amber, pale wood. Use only if he wants hangout-first; the casino layout below is written for the lead concept.

> Builder: build the **lead concept** unless the parent agent confirms a different pick. Materials/signage are parameterized so Alternate A is a re-skin, not a re-layout.

---

## 3. Zone-by-zone layout

Plan view (north = top). Not to scale — coordinates in each zone are authoritative.

```
Z=30 ┌──────────────┬───────────────┬──────────────┐
     │  F. VIP      │  D. STAGE /   │  E. RADIO /  │
     │  MEZZANINE   │  TRIVIA       │  MUSIC       │
Z=22 ├──────────────┴───┬───────────┴──────────────┤
     │                  │                          │
     │  B. CASINO FLOOR │      C. CHILL HANGOUT    │
     │  poker / BJ / RPS│      (east lounge)       │
Z=6  ├──────────────────┴──────────────────────────┤
     │  A. ENTRY / SPAWN  (full width, Z 0–6)      │
Z=0  └──────────────────[ ENTRY ARCH ]─────────────┘
     X=0              X=20                       X=40
```

### Zone A — Spawn / Entry (X 0–40, Z 0–6)

The first impression and the traffic splitter. Players spawn here, read one sign, and walk north.

| Object (`name`) | Position | Notes |
|---|---|---|
| `SpawnPoint` | (20, 0, 3), facing +Z | The world spawn. |
| `EntryArch` | South wall, X 17–23, Z 0 | 6-wide, 5-high arch opening; gold trim. |
| `MarqueeSign` | Above arch, inside face, Y 5.5 | Text panel: world name (§2 pick) + "POKER • BLACKJACK • RPS • TRIVIA" under it. Neon emissive. |
| `WelcomeSign` | (16.5, 1.6, 5.8), facing south (-Z toward spawn) | Rules/how-to panel, exact text: "Welcome! Whisper a bot or say !help in chat. !poker / !blackjack / !rps / !trivia to play. Cashouts are whispered — check your DMs." |
| `BotGreeterAnchor_A` | (23.5, 0, 4) | See §5 — LJAAYY2's off-peak station is near here. |
| 2× `EntryPlanter` | (14, 0, 4) and (26, 0, 4) | Low planter + palm; keeps spawn area feeling dressed without blocking flow. |
| 2× `EntryBench` | (10, 0, 5) and (30, 0, 5), facing north | Sittable. Overflow waiting space. |
| Floor change | Z 0–6 strip | Red carpet material (vs. green field north of Z=6) — the color change itself teaches players they've entered. |

**Do not place:** any game table, any standing decor within X 17–23 / Z 0–8 (spawn + aisle corridor).

### Zone B — Casino Floor (X 2–24, Z 8–22) — the core

Three game pits, each visually distinct so a player can find their game from the spawn in one glance. Pits are separated by low gold railings (height 0.9, walk-through gaps on the aisle side) — definition without walls.

**B1. Poker Pit (X 3–12, Z 14–22, north-west of the floor)**

| Object (`name`) | Position | Notes |
|---|---|---|
| `PokerTable_Main` | Center (7.5, 0, 18) | Oval/round poker table, green felt, **8 seats** evenly spaced, all sittable. This is the primary poker game surface. |
| `PokerTable_Overflow` | Center (7.5, 0, 11)* | Second 8-seat table, same style. *Z=11 puts it in the pit's south half; keep 1.5 ring clear — it doubles as the tournament/overflow table. |
| `PokerSign` | Hanging above main table, Y 4 | Double-sided neon sign: "POKER". |
| `ChipDecor_Poker` | On both tables | Static chip stacks + card props, non-interactive dressing. |
| Accent light | Above main table | Warm white spotlight pool over the felt. |

**B2. Blackjack Pit (X 14–24, Z 14–22, north-center, directly ahead of the aisle)**

Blackjack gets the most central pit — it's the fastest game and historically his bots' busiest.

| Object (`name`) | Position | Notes |
|---|---|---|
| `BlackjackTable_Main` | Center (19, 0, 18) | Classic half-moon blackjack table, **7 player seats** on the curved side (facing north), dealer position on the flat (north) side. |
| `BlackjackSign` | Hanging above, Y 4 | Double-sided neon sign: "BLACKJACK". |
| `PvPBlackjackTable` | Center (19, 0, 11) | Second half-moon table, mirrored (dealer side south), reserved for PvP blackjack mode so house and PvP games never share a table visually. Sign post beside it: "PvP". |
| Accent light | Above main table | Cool white spotlight pool. |

**Bot note:** the dealer-side standing spots at both blackjack tables are bot-relevant — see §5 (`BotStation_Blackjack`).

**B3. RPS Pit (X 3–12, Z 8–12, south-west of the floor)**

RPS is fast and standing — no big table. Build it as a dueling circle.

| Object (`name`) | Position | Notes |
|---|---|---|
| `RPSCircle` | Center (7.5, 0, 10) | Flat circular floor decal/arena, radius 2.5, gold ring, three icons (rock / paper / scissors) equally spaced on the ring. |
| `RPSPodium_A` / `RPSPodium_B` | (5.5, 0, 10) and (9.5, 0, 10), facing each other | Two low standing podiums — the duelists' spots. |
| `RPSSign` | Post sign at (7.5, 1.8, 7.8), facing south | "ROCK PAPER SCISSORS — tournaments in chat: !rps" |
| Spectator stools ×4 | Ring at radius 3.5, N/E/S/W of circle | Sittable, outside the duel ring. |

### Zone C — Chill Hangout (X 26–38, Z 8–22, east lounge)

The decompression side — deliberately **no game tables**. Players between games, listeners, and people who just want to sit.

| Object (`name`) | Position | Notes |
|---|---|---|
| 2× sofa set (`LoungeSofa_1/2`) | (29, 0, 18) facing west; (35, 0, 12) facing north | L-shaped sofa + 2 armchairs each, around a low coffee table. All sittable. |
| `LoungeRug` ×2 | Under each sofa set | Muted pattern, visually quiets the zone. |
| `BarCounter` | Along east wall, X 38–39.5, Z 13–19 | Non-functional bar counter + 5 bar stools (sittable). Back shelf with bottle dressing. Sign above: "THE LOUNGE". |
| 3× `LoungePlant` | Corners (27, 0, 21), (38, 0, 9), (27, 0, 9) | Tall plants; soft zone dividers vs. the casino floor. |
| Lighting | Whole zone | Dim warm (lowest light level in the hall). No neon here except the small bar sign. |

### Zone D — Stage / Trivia (X 14–27, Z 23–29, north-center, raised)

Trivia is a show — it gets a stage everyone on the floor can see from their table.

| Object (`name`) | Position | Notes |
|---|---|---|
| `Stage_Platform` | X 15–26, Z 24–29, height 0.6 (Y top = 0.6) | Steps on both ends (west end X 15, east end X 26), 3 steps each. |
| `StageScreen` | North wall, center (20.5, 3.2, 29.5) | Large screen panel (min 8 × 3.5). Reserved surface for trivia question display / winner names — a plain emissive panel is fine for v1; scripting hook name: `TriviaScreen`. |
| `HostSpot` | (20.5, 0.6, 26.5) floor marker | Where the trivia host (bot or player) stands — center stage. See §5. |
| 2× `StageSpeaker` | (15.5, 0.6, 28.5) and (25.5, 0.6, 28.5) | Speaker stacks flanking the screen. |
| `TriviaSign` | Above screen, Y 6 | Neon sign: "TRIVIA NIGHT". |
| Audience floor | X 14–27, Z 20–23 (in front of stage, overlaps casino floor north edge) | Keep **empty** — standing audience space. The blackjack pit's north edge stops at Z=22; do not push tables into Z 20–23 in X 14–27. |
| Stage lighting | 2 spotlights from ceiling Y 8 aimed at `HostSpot` + screen wash | Magenta accent. |

### Zone E — Radio / Music Corner (X 29–39, Z 23–29, north-east)

Home of **LJAAYY Radio**. Small, loud-looking, separate from the trivia stage so music and trivia never fight over the same corner.

| Object (`name`) | Position | Notes |
|---|---|---|
| `DJBooth` | Center (34, 0, 27), facing south | DJ desk + turntable/mixer props, one standing spot behind it. |
| `RadioSign` | Above booth, Y 4.5 | Neon sign: "LJAAYY RADIO". |
| `RadioInfoSign` | (31, 1.6, 24), facing south-west | Panel: "Now playing: LJAAYY Radio — song requests in chat: !song" (confirm exact command text with bot config at build time; placeholder wording is acceptable for v1). |
| Dance floor (`DanceFloor`) | X 30–38, Z 23–25.5 | Flat checker/light-tile floor panel, no furniture on it. |
| 4× `CornerStool` | Around dance floor edges | Sittable. |
| Lighting | Booth + dance floor | Cyan/magenta alternating accent — the "music" color code, distinct from stage magenta-only. |

### Zone F — VIP Mezzanine (X 2–12, Z 23–29, north-west, raised Y = 3.2)

High-roller overlook above the poker pit — status space, and the quietest seats in the house with the best view (stage + whole floor).

| Object (`name`) | Position | Notes |
|---|---|---|
| `VIP_Platform` | X 2–12, Z 23–29 at Y 3.2 | Floor slab; railing (height 1.0) on its south edge (Z=23) and east edge (X=12) with a glass or open-rail finish. |
| `VIPStairs` | Along west wall, X 2–4, from (3, 0, 22) up to (3, 3.2, 24) | Single straight stair run; entry from the casino floor's NW corner. |
| `VIPGateSign` | At stair base (3.5, 1.8, 22.5) | Small gold sign: "VIP". (v1: open access — gating by gold/role is a later scripting task, noted in §6.) |
| 2× `VIPTable` | (5, 3.2, 26) and (9.5, 3.2, 26) | Small round 4-seat tables, premium finish (black + gold). Social only — **no bot games run up here in v1**. |
| `VIPLoungeSet` | (7, 3.2, 28) against north wall | Plush sofa + chairs facing south over the railing (the view seats). |
| `VIPBarShelf` | North wall (10.5, 3.2, 28.8) | Small shelf + bottle dressing. |
| Lighting | Whole mezzanine | Gold warm, low. One spotlight per VIP table. |

---

## 4. Player flow

1. **Spawn (Zone A, (20,0,3))** → player faces north: marquee overhead, welcome sign directly ahead-left, central carpet leads north. First decision takes <5 seconds.
2. **Split at Z≈7:** west = casino floor pits (poker SW/NW, RPS SW, blackjack center-north); east = lounge/bar (Zone C); straight ahead past the tables = stage audience area (Zone D).
3. **Play loop:** player walks to a pit → stands/sits in the table's clear ring → plays via chat commands with the bot stationed at that pit (§5) → winnings/cashout handled by whisper/DM (per the bots' existing whispered-cashout rule), so the floor never fills with payout spam.
4. **Between games:** lounge (east), radio/dance corner (NE), or VIP mezzanine (NW stairs) — all reachable without crossing a game pit.
5. **Trivia events:** host calls it in chat → players gather in the audience floor (Z 20–23) or watch from their tables — stage and screen are visible from every pit (sightline rule: nothing taller than 1.2 units between Z 8–20 in X 14–27 except the hanging pit signs at Y≥4).
6. **Exit/re-entry:** spawn is also the re-entry point after any reconnect; the welcome sign re-orients returning players.

---

## 5. Bot stations (critical — builders must place these anchors exactly)

Bots join as avatars and stand at fixed anchors so players always know where "the dealer" is. Place an invisible (or subtly marked) anchor object with each exact name; also add the listed physical marker so the spot reads correctly even when a bot is offline.

| Anchor (`name`) | Bot | Position | Facing | Physical marker |
|---|---|---|---|---|
| `BotStation_Blackjack` | **LJAAYYBot (bot #1)** | (19, 0, 19.8) — dealer side of `BlackjackTable_Main` | South (-Z, toward player seats) | Gold floor disc, radius 0.5, under the spot. |
| `BotStation_TriviaHost` | **LJAAYYBot (bot #1)** — event mode only | = `HostSpot` (20.5, 0.6, 26.5) on stage | South (-Z, toward audience) | The stage floor marker itself. |
| `BotStation_Poker` | **LJAAYY2 (bot #2)** | (7.5, 0, 20.2) — north side of `PokerTable_Main` (dealer/host side) | South (-Z, toward table) | Gold floor disc, radius 0.5. |
| `BotStation_RPS` | **LJAAYY2 (bot #2)** — event mode only | (7.5, 0, 13.5) — just north of `RPSCircle`, referee spot | South (-Z, toward the circle) | Small gold disc. |
| `BotStation_Radio` | Either bot — idle/default | Behind `DJBooth` (34, 0, 27.8) | South | None (booth hides the spot). |

**Stationing logic (for the parent agent / bot config, not the scene builder):**
- **Default (always-on):** LJAAYYBot at `BotStation_Blackjack`, LJAAYY2 at `BotStation_Poker`. These are the two highest-traffic games; both bots are visible from spawn down the aisle/pit sightlines.
- **Trivia event:** LJAAYYBot moves to `BotStation_TriviaHost`; LJAAYY2 stays on poker (blackjack pauses or runs unattended-by-avatar — the bot answers chat from wherever it stands, the station is presentational).
- **RPS tournament:** LJAAYY2 moves to `BotStation_RPS` as referee; LJAAYYBot stays on blackjack.
- **Off-peak / idle:** LJAAYY2 may move to `BotGreeterAnchor_A` near spawn to greet joiners; LJAAYYBot never leaves blackjack in v1 (it's the gold-holding bot and the anchor of the room).
- Movement between stations uses the bots' existing room-move/whisper-verified presence behavior — no new scene scripting is required for v1. Station changes are presentational only; game state lives in the bots, never in the scene.

---

## 6. Build order & v1 scope

**Build in this order** (each step is independently checkable in Studio):

1. Shell: floor slab 40×30, perimeter walls, entry arch, ceiling beams at Y=8, mezzanine slab + stairs (Zone F structure only).
2. Floor materials & central carpet runner; zone floor accents (entry red strip, dance floor panel, RPS circle decal).
3. Zone A complete (spawn, signs) — set the world spawn to `SpawnPoint`.
4. Casino floor: railings, then tables in pit order B2 (blackjack) → B1 (poker) → B3 (RPS), with hanging signs and table spotlights.
5. Stage (Zone D platform, screen panel named `TriviaScreen`, speakers, lights).
6. Radio corner (Zone E) and lounge (Zone C) furniture.
7. VIP mezzanine furnishing (Zone F).
8. Bot station anchors + gold discs (§5) — verify names character-for-character.
9. Global lighting pass + sightline check (§4, step 5).
10. Play-test: spawn → walk every zone → confirm no furniture intrudes on the aisle (X 18–22, Z 2–22) or any table's 1.5-unit ring.

**Explicitly out of v1 scope** (note for later, do not build): scripted trivia screen content, VIP access gating, in-world gold displays, custom furniture assets, a second scene/room. The bots bring all game logic with them.

**Open decisions for Faceless (do not block the build):** world name pick (§2 — default REAL GAMBLERS), theme pick (default lead casino concept), radio request-command wording on `RadioInfoSign`.

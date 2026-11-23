# Assets Guide — Monster House World (plain words)

**What this is:** the shopping-and-building list for the Monster House Highrise world. The machine-readable version is `assets_manifest.json` right next to this file — same list, same names. This guide is the human version.

**The world in one sentence:** players play in the **front yard** of a haunted cartoon house; the house itself stands behind the yard, **looking mad** — glowing orange windows for eyes, the porch and door for a mouth — while the poker, blackjack, RPS, and trivia games are dressed into the yard in front of it.

---

## ⚠️ Change note — the house now matches the real film house

The user corrected the design on 2026-11-22: the generic "haunted house in that style" facade was **not accurate enough**. The house must now match the **actual house from the Monster House film (~95% replica)**. The reference crew's file — `repo/00-reference/REFERENCE.md` — is the authority for how the facade and yard should look.

The facade/yard entries in the manifest were updated for this:

- **Two glowing ORANGE eye windows** (they were "dim amber" before — fixed to orange, and `Facade_AmberGlow` was renamed `Facade_OrangeGlow`)
- **Furrowed brow roofline** above the eye windows (new entry: `Facade_BrowRoofline`)
- **Jagged splintered tooth planks** hanging in the porch/door opening — the monster's teeth (new entry: `Facade_ToothPlanks`)
- **Sagging porch boards**, crooked posts, sagging porch roof
- **Weathered gray-brown wood siding**, steep shingled roof, **crooked smoking chimney**
- **Bare gnarled trees** in the yard (now 2, not 1)
- **Two lawn signs:** **"KEEP AWAY"** and **"BEWARE"** (new entries: `Yard_SignKeepAway`, `Yard_SignBeware`)

Everything else (game pits, bot stations, names, positions) did not change.

---

## How to use this list in Highrise Studio

1. **Search first.** Every entry has *catalog search terms*. Open the Asset Catalog inside Studio (Highrise → Studio → Asset Catalog), type the terms, and pick the closest free low-poly item. Most of this list is ordinary stuff — tables, chairs, stools, benches, plants, signs.
2. **Check the price before you commit.** Much of the catalog is free, but some items cost Gold. **Never buy anything without the user's OK.** If the good-looking item costs Gold, use a free one or the fallback.
3. **Use the fallback without guilt.** Every entry also has a *primitives fallback* — how to build the same thing from plain boxes, cylinders, and materials in Unity. The fallback is not a failure; for signs, discs, the stage, and the whole house facade, primitives are actually the main plan.
4. **Chairs are not done until they have an Anchor Point.** A chair placed in the scene is just decoration until you add an **Anchor Point** — that's the spot that lets an avatar actually sit. Every entry that needs one says `sit_anchor_required` in the JSON. Skip this and players will stand on the furniture.
5. **Names are exact.** If the JSON gives a `design_name`, the object in the scene must have that name **character-for-character** (example: `PokerTable_Main`). The bots and scripts look these names up. If `proposed_name` is true, the name came from this manifest (the design doc never named the item) — still use it exactly as written so everyone is talking about the same thing.

---

## The zones, in plain words

### Front yard (`front_yard`)
Where players land and hang out. The spawn point, the entry arch with the big marquee sign, the welcome/rules sign, two benches and planters at the entry, the dead lawn, a cracked walkway up the middle, crooked picket fences, leaf piles, a streetlamp, the gnarled trees, the **KEEP AWAY** and **BEWARE** lawn signs, and — along the east side — the chill corner: two sofa sets with rugs, a bar counter with stools, and tall dead plants as dividers. The middle path (the walkway) stays **clear** — it's the player highway.

### The facade (`facade`)
The house itself. It is a **backdrop, not a building you enter** (not in v1). One crooked house shell with warped gray-brown siding, a steep shingled roof with a furrowed-brow edge, a crooked smoking chimney, two **glowing orange eye windows**, the door/porch **mouth** with **jagged tooth planks**, a sagging porch and steps, dead vines, and the orange glow that makes it feel alive. Build it from primitives against `00-reference/REFERENCE.md`.

### Poker (`poker`)
Two 8-seat poker tables (main + overflow) with 16 anchored chairs, chip-and-card dressing on the tables, a hanging "POKER" sign, a low pit railing, a warm spotlight, and LJAAYY2's station anchor + gold floor disc on the dealer side of the main table.

### Blackjack (`blackjack`)
The half-moon main table with **7 seats**, a mirrored second half-moon table for PvP blackjack with its own "PvP" sign post, card-shoe/chip-tray props, a "BLACKJACK" sign, railing, cool spotlight, and LJAAYYBot's station anchor + gold disc on the dealer side. Bot #1 lives at this station — it's the gold-holding bot and never leaves it in v1.

### Trivia (`trivia`)
A raised yard stage (0.6 high, steps at both ends), the big screen, the host spot in the middle, two speaker stacks, a "TRIVIA NIGHT" sign, and magenta stage lights. **The audience area in front of the stage stays empty on purpose** — it's standing room. Do not put benches there (see fixes below). The screen's scene name is `StageScreen`; `TriviaScreen` is only the name scripts use to talk to it — it's the same object, not two objects.

### Radio (`radio`)
The LJAAYY Radio corner: DJ booth with turntable props, "LJAAYY RADIO" neon sign, the info sign with the song-request wording, a checker dance floor (nothing on it), 4 stools around it, cyan/magenta lights, a mic stand, and the invisible piece that actually makes sound — the built-in **PlayMusic** component, which can play the radio stream URL. Either bot idles behind this booth when nothing else is on.

### RPS (`rps`)
Rock-paper-scissors is a standing game: a gold-ringed circle decal on the ground with the three icons on the ring, two low podiums facing each other, a sign post explaining it, 4 spectator stools **outside** the ring, and LJAAYY2's referee anchor + gold disc just north of the circle for tournaments.

### VIP porch (`vip_porch`)
The raised porch overlook (up at Y 3.2, stairs at the west side, "VIP" sign at the bottom): two small black-and-gold 4-seat tables with chairs, a plush lounge set facing out over the railing — the best view in the yard — a little bar shelf, and warm gold spotlights. Social only: **no bot games run up here in v1**, and there's no gate/lock in v1 either.

---

## Fixes made while building this list (cross-check vs DESIGN.md §3/§5 and ASSETS.md)

1. **Blackjack seats: 5 → 7.** The old assets doc said 5 stools per blackjack table. The design spec says the main table has **7 player seats**. The manifest uses 7. The PvP table has no seat count in the design, so it mirrors 7 — flagged in the JSON as an assumption.
2. **Trivia audience benches: removed.** The old assets doc suggested 10–15 benches/chairs facing the stage. The design spec says the audience floor stays **empty**. No audience seating is listed; a marker entry (`AudienceFloor_Clear`) is in the JSON only to stop anyone furnishing it by accident.
3. **Screen name untangled.** The scene object is `StageScreen`; `TriviaScreen` is only its scripting hook name. Both are recorded on one manifest entry so nobody builds two screens or names the object wrong.
4. **Palms → dead plants.** The entry planters were described with palms, which clashes with the Monster House look (dead, autumn, haunted). They now call for dead shrubs and bare branches.
5. **Indoor lounge → front yard.** The old assets doc was written for an indoor casino. Per the design update, the playable space is the **front yard** and the house is a background facade. Lounge furniture moved into the front-yard group as yard seating, and the VIP mezzanine became the raised **VIP porch**. Every design name, position, and clearance stayed exactly the same.
6. **Unnamed things got proposed names.** The design describes but never names: table chairs/stools, RPS spectator stools, pit railings, the pit/stage/VIP lights, the gold discs under bot stations, the "PvP" sign post, the stage steps, the VIP railing, and all the facade/yard backdrop pieces. Each one has a manifest name marked `proposed_name: true` in the JSON, so it's always clear which names come from the design and which ones we invented for bookkeeping.
7. **Film-reference update (2026-11-22).** Facade/yard entries reworked to the actual film house — see the change note at the top of this guide.

---

## Rough build order for assets

1. Yard ground, walkway, facade shell + roof + porch (the backdrop sells the whole world).
2. Facade face: eye windows + orange glow, brow roofline, tooth-plank mouth, chimney, vines.
3. Entry: arch, marquee, welcome sign, benches, planters, lawn signs, trees, fences.
4. Game pits: blackjack → poker → RPS (tables, seats **with anchors**, signs, railings, discs, bot station anchors — check names twice).
5. Trivia stage + screen + speakers; radio booth + dance floor + PlayMusic.
6. VIP porch furniture; lounge seating; leaf piles and final dressing last.

**Counts:** 86 manifest entries across the 8 zones (44 carry exact DESIGN names, 42 are proposed names for items the design never named), and about 147 placed objects once quantities (16 poker chairs, 14 blackjack stools, etc.) are counted — most are duplicates of a small set of unique items.

**Money rule, again:** the plan assumes **0 Gold**. If Studio shows a price on something, stop and use the free item or the primitives fallback. Nothing gets bought without the user's OK.

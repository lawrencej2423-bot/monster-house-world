# 04 — Scripts: Party Games (Trivia · Radio · RPS)

World-side Lua for the three party-game stations of the Monster House
world. **Presentation only** — the bots run all game logic (SCRIPTS.md §4):

| Station | World piece (this folder) | Bot that owns the game | Bot anchor (DESIGN.md §5, exact) |
|---|---|---|---|
| Trivia stage | Screen + host presence | **LJAAYYBot** (bot #1) | `BotStation_TriviaHost` = `HostSpot` (20.5, 0.6, 26.5) |
| Radio booth | Now-playing sign + booth presence | Either bot (stream/queue bot-side) | `BotStation_Radio` behind `DJBooth` (34, 0, 27.8) |
| RPS arena | Banner + podium occupancy + referee presence | **LJAAYY2** (bot #2) | `BotStation_RPS` (7.5, 0, 13.5) |

Yard dressing (DESIGN.md §2): the stage is the yard stage corner with the
audience facing the house facade; the RPS circle is ringed on the front
lawn (`RPSCircle` (7.5, 0, 10), podiums `RPSPodium_A` (5.5, 0, 10) /
`RPSPodium_B` (9.5, 0, 10)); the radio booth is the yard's NE corner booth
(`DJBooth` (34, 0, 27), sign `RadioSign`). Grid coordinates and anchor
names are unchanged from DESIGN.md §3/§5.

## How the pieces talk — the display bridge

Bots and World Lua are separate systems with no verified direct bridge
(SCRIPTS.md §4b). The v1 hook is deliberately simple and uses only
verified pieces on both sides:

1. The owning bot posts **one ordinary chat line** (verified bot pattern:
   `self.highrise.chat(...)`) in a fixed format, e.g.
   `[TRIVIA] QUESTION: Which planet is known as the Red Planet?`
2. `shared/PartyGameChatHook.lua` — the **only** chat hook in this
   section — passes every message through with
   `Chat:DisplayTextMessage` (so chat is never swallowed or duplicated),
   recognises display lines, checks the sender is the owning bot by
   `player.name`, and re-fires them as internal events.
3. Each station script renders the event: UI label on the screen / sign
   / banner surface, plus a `print()` fallback, plus a server-side cache
   so late joiners get the current card.

Protocol (full table in `shared/PartyGameCommon.lua`):
`[TRIVIA] QUESTION:|ANSWER:|WINNER:|IDLE` ·
`[RADIO] NOW:|OFF` ·
`[RPS] STATE:|WINNER:|IDLE`

Bot-side to-do (parent agent / bot package, **not** in this folder):
emit those lines at the moments the bot already announces results in
chat. Until then, every station sits at its idle card and still works
(tap re-display, presence, podium tracking).

## Files

**shared/**
- `PartyGameCommon.lua` — Module: exact anchor/object names + positions
  from DESIGN.md §3/§5, bot names, ground-distance helper, display-line
  parser. Loaded via `require("PartyGameCommon")`.
- `PartyGameChatHook.lua` — ClientAndServer, one empty scene object:
  the single chat hook + display bridge described above.
- `StationPresence.lua` — ClientAndServer, one empty scene object:
  server-validated occupancy of the three bot anchors (client claims,
  server distance-checks — the docs' ScoreSystem rule).
- `StationSpotTrigger.lua` — Client: attach to each anchor object
  (`BotStation_TriviaHost`, `BotStation_RPS`, `BotStation_Radio`), each
  with a trigger Collider. The object name is the spot name.

**trivia/** (Zone D — stage X 14–27, Z 23–29)
- `TriviaStage.lua` — ClientAndServer on `StageScreen` (hook name
  `TriviaScreen`): renders bridge updates, tap-to-redisplay (TapHandler),
  host-presence notices, server catch-up cache.
- `TriviaScreenUI.lua` + `TriviaScreen.uxml` — world-space UI on the
  screen surface; label bind `triviaScreenLabel`.

**radio/** (Zone E — X 29–39, Z 23–29)
- `RadioBooth.lua` — ClientAndServer on `DJBooth`: now-playing rendering,
  tap re-display, booth-presence notices, server catch-up cache.
- `RadioBoothUI.lua` + `RadioBooth.uxml` — world-space UI on `RadioSign`;
  label bind `radioSignLabel`. No audio is controlled (no verified
  world audio API — SCRIPTS.md).

**rps/** (Zone B3 — X 3–12, Z 8–12)
- `RPSArena.lua` — ClientAndServer on `RPSCircle`: banner rendering,
  server-validated podium occupancy, referee-presence notices. Never
  reads throws and never picks a winner.
- `RPSPodiumTrigger.lua` — Client: attach to `RPSPodium_A` and
  `RPSPodium_B` (trigger Colliders).
- `RPSArenaUI.lua` + `RPSArena.uxml` — world-space banner UI on the
  `RPSSign` post; label bind `rpsBannerLabel`.

## Studio setup checklist

1. Module script `PartyGameCommon` present in the project (name must
   match the `require` calls).
2. Empty objects `PartyGameBridge` (ChatHook) and `PartyGameStations`
   (StationPresence) in the scene.
3. Trigger Colliders on the three anchor objects + both RPS podiums;
   TapHandlers on `StageScreen`, `DJBooth`, `RPSCircle`.
4. UI documents for the three `.uxml` files, output set to world-space
   on their surfaces; bind names exactly as in the UI scripts.

## Play-test checklist

- [ ] Bot posts `[TRIVIA] QUESTION: …` → screen label + console show it;
      a player typing the same line changes nothing (sender check).
- [ ] Normal chat still displays exactly once with the hook active.
- [ ] Joining mid-question: screen catches up to the current card
      (exercises the server-cache assumption noted in TriviaStage.lua).
- [ ] Standing on `BotStation_TriviaHost` / `BotStation_RPS` /
      `BotStation_Radio` prints presence; stepping off clears it;
      firing a claim from across the yard is rejected (distance check).
- [ ] Both podiums can be held at once, by different players; a third
      player stepping on a held podium does not steal it silently
      (occupant name only changes on a fresh validated claim — check
      the announced name matches expectations).
- [ ] `[RADIO] NOW: …` updates the booth sign; `[RADIO] OFF` idles it.
- [ ] `[RPS] STATE:` / `[RPS] WINNER:` update the banner; the arena
      never declares a winner on its own.

## Known unverified items (inherited from SCRIPTS.md §6)

- Bots speaking inside a Studio World at all (§6.5) — if they can't,
  the bridge never fires and stations stay at idle cards; nothing breaks.
- Gameplay-event → UI-script label wiring (§6.1) — `print()` fallbacks
  cover every surface.
- Chat handler execution context (§6.9) — the hook is ClientAndServer,
  matching the Chat service page.
- Server-side `Connect` receiving a `FireAllClients` event (late-joiner
  catch-up) — new starter-pattern assumption, flagged inline in each
  station script; live rendering does not depend on it.

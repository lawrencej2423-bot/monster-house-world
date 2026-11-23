# 03 — Card-game station scripts (poker + blackjack)

World-side Lua for the poker and blackjack stations of the Monster House
front-yard world. These scripts are the **furniture layer**: table anchors,
seat/stand prompts, seat assignment, and signage state.

**The games themselves are not here.** Poker and blackjack logic, cards,
gold and payouts live in the Python bots — LJAAYY2 deals poker, LJAAYYBot
deals blackjack — exactly as they work in the rooms today (SCRIPTS.md §4).
Sitting at a table in-world is presentational: it puts the player at the
table the bot is dealing. Nothing in this folder touches gold.

## Files

| File | Type | Attach to | What it does |
|---|---|---|---|
| `CardStationShared.lua` | Module | (referenced by `require`, not attached) | Single source of truth: per-table config (seats, centre, sign text, play command), the exact bot-anchor names/positions, signage modes (`OPEN` / `SEATING` / `FULL`), sign-line and prompt formatters. |
| `PokerStation.lua` | ClientAndServer | `PokerTable_Main` **and** `PokerTable_Overflow` | Walk-up prompt, tap-to-sit / tap-to-stand, server-authoritative seat assignment (proximity-checked), occupancy signage broadcasts for the poker tables. |
| `BlackjackStation.lua` | ClientAndServer | `BlackjackTable_Main` **and** `PvPBlackjackTable` | Same station behaviour for blackjack. Hands out **player seats only** — the dealer spot is the bot anchor, never a seat. |

One script serves both tables of its game: each copy identifies its table
by its own object name, looks the config up in `CardStationShared`, and
ignores events naming the other table.

## Bot station anchors (DESIGN.md §5 — EXACT names, do not rename)

| Anchor | Bot | Position | Serves |
|---|---|---|---|
| `BotStation_Poker` | LJAAYY2 (bot #2) | (7.5, 0, 20.2) — north side of `PokerTable_Main`, facing south | Both poker tables |
| `BotStation_Blackjack` | LJAAYYBot (bot #1) | (19, 0, 19.8) — dealer side of `BlackjackTable_Main`, facing south | Both blackjack tables |

On server start, each station script checks its anchor exists with
`GameObject.Find` and prints a warning naming the missing anchor if the
builder forgot it or misspelled it.

## Tables (DESIGN.md §3)

| Object | Centre | Player seats | Sign |
|---|---|---|---|
| `PokerTable_Main` | (7.5, 0, 18) | 8 | `PokerSign` — "POKER" |
| `PokerTable_Overflow` | (7.5, 0, 11) | 8 | shares `PokerSign` |
| `BlackjackTable_Main` | (19, 0, 18) | 7 | `BlackjackSign` — "BLACKJACK" |
| `PvPBlackjackTable` | (19, 0, 11) | 7 | "PvP" sign post beside the table |

## How a seat works

1. Player walks into a table's ring → client prints the prompt
   (game, dealer bot + anchor, chat command) — trigger pattern from
   SCRIPTS.md §2.
2. Player taps the table → client fires a seat request naming the table.
3. **Server** validates: player not already seated here, avatar exists,
   and avatar is within `SEAT_MAX_DISTANCE` (4 units) of the table —
   the same never-trust-the-client distance check as the coin system.
4. Server assigns the lowest free seat, replies to that player only, and
   broadcasts the new signage state to everyone.
5. Tap again to stand; disconnecting also frees the seat.

## Signage state

Derived on the server from occupancy only — never from game state:

- `OPEN` — 0 seated · `SEATING` — some seats free · `FULL` — no seats free
- Sign line format: `POKER · SEATING · 3/8 seats · dealer: LJAAYY2`

Today the line is delivered by client `print` (the verified fallback used
throughout SCRIPTS.md). Forwarding it onto the physical hanging signs'
UILabels uses the UI-script `--!Bind` pattern — the pieces are documented
but that exact cross-script wiring is **UNVERIFIED** (SCRIPTS.md §6 item 1),
so it is a marked TODO in both station scripts, to be confirmed in Play
mode before publishing.

## Studio setup checklist (per table object)

- [ ] Object named **exactly** as in the tables list above.
- [ ] `PokerStation.lua` / `BlackjackStation.lua` attached (matching game).
- [ ] Collider + `TapHandler` on the table (tap = sit/stand).
- [ ] Trigger Collider covering the seat ring (walk-up prompt).
- [ ] `CardStationShared` module script present in the project.
- [ ] Bot anchor placed with its exact §5 name; gold floor disc under it.
- [ ] Play-test: tap from far away → refused; tap at the table → seated;
      fill the table → sign state `FULL`; disconnect seated → seat frees.

## Known limits / unverified (inherited from SCRIPTS.md §6)

- A player can hold a seat at a poker table and a blackjack table at the
  same time (seat maps are per-table; a cross-station registry is a later
  refinement, not a v1 requirement).
- Whether the Python bots can be present *inside* a Studio World the way
  they join rooms is UNVERIFIED (SCRIPTS.md §4b). These scripts assume
  nothing about it — anchors are just named, positioned objects.
- There is no Lua↔Python bridge in v1. If the bots ever need to drive the
  signs (e.g. "GAME RUNNING" during a hand), that is the ChannelRequest /
  Persistence-API research task in SCRIPTS.md §4c.4 — not built here.

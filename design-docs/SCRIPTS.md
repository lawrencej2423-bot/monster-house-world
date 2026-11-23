# Highrise World — Starter Gameplay Scripts (Lua)

**For:** Faceless's Highrise World (companion to `FEASIBILITY.md` in this folder)
**Written:** 2026-11-22
**Status:** Starter plans + skeleton code. Nothing here has been run in Unity yet — every skeleton needs a Play-mode test in Highrise Studio before publishing. Skeletons follow the official docs' own examples as closely as possible; anything the docs did not confirm is marked **UNVERIFIED** inline and collected in §6.

---

## 0. Verified API basis (official docs, create.highrise.game)

Only these claims are treated as fact in the skeletons below:

| API | What was verified | Source |
|---|---|---|
| Script types | First line declares the type: `--!Type(Server)`, `--!Type(Client)`, `--!Type(ClientAndServer)`, `--!Type(Module)`, `--!Type(UI)` | Studio API / Lua attributes & script-type pages |
| Lifecycle | Server scripts use `self:ServerAwake()` / `self:ServerStart()`; client scripts use `self:ClientAwake()` / `self:ClientStart()`; `self` exposes `self.gameObject`, `self.transform` | Studio API classes `Self`, `GameServer`, `GameClient` |
| Player connect (server) | `server.PlayerConnected:Connect(function(player) ... end)` and `server.PlayerDisconnected` — authoritative, fires on connect, **not** on avatar spawn | Studio API class `GameServer` |
| Player joined scene | `scene.PlayerJoined:Connect(function(scene, player) ... end)` and `scene.PlayerLeft` — fires when a player joins/leaves a scene | "Player and Character Events" guide; Client–Server Communication guide |
| Player identity | `player.name`; persistent ID is `player.user.id` (use for storage/leaderboards — `player.id` is a per-session ID, do **not** use it for storage); `player.character` is the avatar GameObject; `player.CharacterChanged` fires on spawn/respawn | Studio API classes `Player`, `User`; Storage service page |
| Custom events | `Event.new("Name")`, `:Connect(fn)`, `:FireServer(...)` (server handler receives the sending player first), `:FireClient(player, ...)`, `:FireAllClients(...)`. Events accept strings, numbers, tables | "Client Server Communication" guide |
| Module scripts | A `--!Type(Module)` script can export functions other scripts call via `require("ModuleName")` (docs' ScoreSystem example) | "Client Server Communication" guide |
| Storage (server only) | Persistent across restarts/sessions. `Storage.GetPlayerValue(player, key, function(value) ... end)`, `Storage.SetPlayerValue(player, key, value)`, `Storage.IncrementPlayerValue(player, key, amount, callback)`, plus global `Storage.GetValue/SetValue(key, ...)`. Server scripts only | Studio API service `Storage` |
| Leaderboard (server only) | `Leaderboard.IncrementScoreForPlayer(id, player, amount, function(entry, error) ... end)`, `Leaderboard.GetEntries(id, fromRank, limit, function(entries, error) ... end)`, `Leaderboard.GetEntryForPlayer(id, player, cb)`, `Leaderboard.Reset(id, cb)`. Multiple boards via different `leaderboardId`s; rate-limited (`LeaderboardError.RequestThrottled`). `LeaderboardEntry` has `score` and `rank` | Studio API class `Leaderboard`; "Leaderboard API Documentation" guide |
| Coin touch (client) | Client script `self:OnTriggerEnter(other : Collider)`; `other.gameObject:GetComponent(Character)` gives the character, whose `.player` is the Player; compare with `client.localPlayer` | "Client Server Communication" guide (CoinCollector example, verbatim pattern) |
| Coin validation (server) | Server re-checks before awarding: coin exists via `GameObject.Find(coinName)`, player hasn't collected it, and `Vector3.Distance(player.character.transform.position, coin.transform.position)` is within a max distance. **Never trust the client's claimed points** | Same guide (ScoreSystem example) |
| Tap interaction | Object with a Collider + `TapHandler` component; `self.gameObject:GetComponent(TapHandler).Tapped:Connect(fn)` | "Tap Handlers" guide; Studio API class `TapHandler` |
| UI text | UI script (`--!Type(UI)`) + UXML with `<hr:UILabel name="myLabel">`; Lua binds it with `--!Bind local myLabel : UILabel = nil` (variable name must match the UXML name) and sets text with `myLabel:SetPrelocalizedText("...")`. UI Output can be HUD, Above Chat, or World-space | "UI Scripts" (script-types/ui); "Bind" attribute page |
| In-world chat service | `Chat:CreateChannel(name, allowsText, allowsVoice)` returns a channel; `Chat:AddPlayerToChannel(channel, player)`; `Chat.TextMessageReceivedHandler:Connect(function(channel, player, message, language, originalMessage) ... end)`; pass the final text through with `Chat:DisplayTextMessage(channel, player, message, language, originalMessage)` when you hook the handler | Studio API service `Chat` |
| Room bots (separate system) | Python SDK: `class Bot(BaseBot)` with `async def on_chat(self, user, message)`, `on_whisper`, `on_message`; replies via `await self.highrise.chat(text)`, `await self.highrise.send_whisper(user_id, text)`, `await self.highrise.send_message(conversation_id, text)` | Bots guides (Tipping Bot / Statistics Bot / Earn Gold examples) |
| Hidden bot channel | Bot API `ChannelRequest`: "Send a hidden channel message to the room. This message will not be displayed in the chat, so it can be used to communicate between bots or client-side scripts." | Bots API endpoint `ChannelRequest` |

**Key architecture rule from the docs:** the server is authoritative. Clients only *request* (e.g. "I touched coin X"); the server validates and awards. All skeletons below follow that.

---

## 1. Welcome / Spawn script — `WelcomeGreeter.lua`

### Plan
- **Goal:** every player who enters the spawn scene gets a personal greeting showing their name, their all-time coin score, and one line on what to do first. Returning players get a shorter "welcome back."
- **Why two hooks:** `server.PlayerConnected` fires when the connection happens, *before* the avatar exists (docs are explicit). The greeting itself is keyed to `scene.PlayerJoined`, which is when the player is actually in the scene. First-visit detection uses Storage (`hasVisited`), which is server-only — so the greeting text is assembled on the server and pushed to that one player's client with `FireClient` (verified pattern from the Client–Server Communication guide's `Example.lua`).
- **Display:** the client side prints the message (verified) and, if the HUD from §3 is present, also shows it on a label (the label call is verified; wiring this specific event into the UI script is a starter pattern — see UNVERIFIED note in §6).

### Studio setup
1. Create an empty GameObject in the spawn scene, name it `WelcomeGreeter`.
2. Create a Lua script, type **ClientAndServer**, name it `WelcomeGreeter`, drag it onto that object.

### Skeleton
```lua
--!Type(ClientAndServer)
-- WelcomeGreeter.lua — attach to an empty object in the spawn scene.

local WelcomeEvent = Event.new("WelcomeEvent")  -- server -> one client

local WORLD_NAME = "LJAAYY's World"             -- TODO: set the real world name
local FIRST_TASK = "Grab the glowing coins scattered around spawn — each one is worth 10 points."

-- CLIENT SIDE: receive the greeting and show it.
function self:ClientAwake()
    WelcomeEvent:Connect(function(message)
        -- Verified display path: console/chat-log print.
        print(message)
        -- TODO (Play-test): if a HUD UI script exists, forward `message`
        -- to its UILabel via SetPrelocalizedText (see section 3).
    end)
end

-- SERVER SIDE: greet when the player actually joins the scene.
function self:ServerAwake()
    scene.PlayerJoined:Connect(function(scene, player)
        Storage.GetPlayerValue(player, "hasVisited", function(visited)
            Storage.GetPlayerValue(player, "score", function(score)
                local msg
                if visited then
                    msg = "Welcome back, " .. player.name .. "! Score so far: " .. (score or 0) .. "."
                else
                    msg = "Welcome to " .. WORLD_NAME .. ", " .. player.name .. "! " .. FIRST_TASK
                    Storage.SetPlayerValue(player, "hasVisited", true)
                end
                WelcomeEvent:FireClient(player, msg)
            end)
        end)
    end)
end
```

### Tuning knobs
- `WORLD_NAME`, `FIRST_TASK`: the only text a non-coder ever needs to touch.
- Swap the `hasVisited` check for a daily-return greeting later using a stored date string (docs' Wallet example uses `os.date("%Y-%m-%d")` with Storage — that pattern is verified in the `Wallet` class page).

### Test checklist (Play mode, Virtual Player + a second client if possible)
- [ ] First join prints the long greeting once; rejoin prints the short one.
- [ ] Greeting shows the joining player's own name/score only (not other players').
- [ ] No greeting before the avatar is in the scene.

---

## 2. Coin / points system — `ScoreSystem.lua` (Module) + `CoinCollector.lua` (Client)

### Plan
- **Goal:** coins placed around the world; walking through one = **+10 points**, saved permanently, mirrored onto the leaderboard (§3).
- This is the docs' own ScoreSystem example, adapted — same event names, same server-side distance/uniqueness checks, same Storage calls. Two additions, both built only from verified calls: (1) each award also calls `Leaderboard.IncrementScoreForPlayer`, (2) coins are per-session collectible (a coin a player already grabbed this session is ignored — exactly the docs' behaviour; making coins respawn for everyone is a design change, see knob below).
- **Anti-cheat (from the docs, keep it):** the client sends only the coin's *name*. Points value, distance check (max 3 units), and already-collected check all live on the server.

### Studio setup
1. Create a Lua **Module** script named `ScoreSystem` (name must match the `require("ScoreSystem")` in CoinCollector).
2. For each coin: a GameObject with a **Collider set as a trigger**, a unique name (`Coin_01`, `Coin_02`, … — the server finds coins by name, so duplicates break it), and the `CoinCollector` client script attached.
3. Attach `ScoreSystem`'s module per the docs' module setup (Module scripts are referenced by `require`, not dragged onto objects — follow the Client–Server Communication guide).

### Skeleton — ScoreSystem.lua
```lua
--!Type(Module)
-- ScoreSystem.lua — authoritative score + coin awards. Adapted from the
-- official Client-Server Communication guide's ScoreSystem example.

local GetMyScoreRequest = Event.new("GetMyScoreRequest")
local CollectCoinRequest = Event.new("CollectCoinRequest")
local ScoreChanged       = Event.new("ScoreChanged")

local COIN_POINTS = 10          -- what a coin is worth; server only
local MAX_COLLECT_DISTANCE = 3  -- how close the character must be
local LEADERBOARD_ID = "coins_all_time"

local collectedCoins = {}       -- server: player name -> { coinName = true }

-- Called by CoinCollector (client) when the local player touches a coin.
CollectCoin = function(coin : GameObject)
    CollectCoinRequest:FireServer(coin.name)
end

local function SendScore(player)
    Storage.GetPlayerValue(player, "score", function(score)
        ScoreChanged:FireClient(player, score or 0)
    end)
end

function self:ClientAwake()
    ScoreChanged:Connect(function(score)
        print("My score is: " .. score)
        -- TODO (Play-test): forward to HUD label (section 3).
    end)
    GetMyScoreRequest:FireServer()
end

function self:ServerAwake()
    server.PlayerConnected:Connect(function(player)
        collectedCoins[player.name] = {}
    end)
    server.PlayerDisconnected:Connect(function(player)
        collectedCoins[player.name] = nil
    end)

    GetMyScoreRequest:Connect(SendScore)

    CollectCoinRequest:Connect(function(player, coinName)
        local collected = collectedCoins[player.name]
        if type(coinName) ~= "string" or collected == nil or collected[coinName] then return end

        local coin = GameObject.Find(coinName)
        if coin == nil or player.character == nil then return end
        if Vector3.Distance(player.character.transform.position, coin.transform.position) > MAX_COLLECT_DISTANCE then return end

        collected[coinName] = true

        Storage.IncrementPlayerValue(player, "score", COIN_POINTS, function()
            SendScore(player)
        end)
        -- Keep the all-time leaderboard in step with the stored score.
        Leaderboard.IncrementScoreForPlayer(LEADERBOARD_ID, player, COIN_POINTS, function(entry, error)
            if error ~= LeaderboardError.None then
                print("Leaderboard update failed: " .. tostring(error))
            end
        end)

        print(player.name .. " collected " .. coinName)
    end)
end
```

### Skeleton — CoinCollector.lua (one per coin)
```lua
--!Type(Client)
-- CoinCollector.lua — attach to each coin (Collider must be a trigger).

local ScoreSystem = require("ScoreSystem")

function self:OnTriggerEnter(other : Collider)
    local playerCharacter = other.gameObject:GetComponent(Character)
    if playerCharacter == nil then return end
    if client.localPlayer == playerCharacter.player then
        ScoreSystem.CollectCoin(self.gameObject)
    end
end
```

### Tuning knobs
- `COIN_POINTS`, `MAX_COLLECT_DISTANCE`, coin names/placement.
- **Respawning coins:** the docs' design is one-grab-per-player-per-session. A respawn timer (hide the coin, clear its entry in `collectedCoins` after N seconds) is a **design extension — UNVERIFIED pattern**, test carefully in Play mode before using.
- **Gold instead of points:** a verified `Wallet.TransferGoldToPlayer(player, amount, cb)` exists (Studio API class `Wallet`, server-only, spends the *world's* wallet). Swapping points for real gold is possible but is a money decision for Faceless — not in this starter.

### Test checklist
- [ ] Walking through a coin: +10 once; walking through it again: no change.
- [ ] Score survives leaving and rejoining (Storage persistence).
- [ ] Two players can each collect the same coin once.
- [ ] Firing `CollectCoinRequest` from a modified client for a far-away coin awards nothing (distance check).

---

## 3. Leaderboard — `LeaderboardBoard.lua` + HUD label

### Plan
- **Goal:** a Top-10 board for the coin score that any player can view, plus a personal "My score" HUD line.
- **Data:** the native `Leaderboard` service (§2 already writes to `coins_all_time` on every coin). Do **not** build rankings out of Storage by hand — the docs warn Storage reads/writes for leaderboard-style data race, and a purpose-built Leaderboard API exists.
- **Display paths, in order of confidence:**
  1. **Chat-log print (verified pieces):** server fetches `Leaderboard.GetEntries`, formats lines, `FireAllClients` sends them (events accept strings/tables — verified); clients print. Ugly but works with zero UI setup.
  2. **HUD label (verified pieces, starter wiring):** a UI script with a bound `UILabel` shows the text via `SetPrelocalizedText`. Feeding the fetched entries into that label uses the same event + bind patterns, but the exact hookup (gameplay event → UI script) must be confirmed in Play mode — marked UNVERIFIED wiring in §6.
- **Refresh discipline:** Leaderboard calls are rate-limited. Fetch on request (player taps the board) and at most on a slow timer — never per-frame, never per-coin for the *display* (the per-coin `IncrementScoreForPlayer` write in §2 is one call per coin, which is the intended use).

### Studio setup
1. A physical board object in the world with a Collider + `TapHandler` (for the tap-to-view path).
2. `LeaderboardBoard.lua` as **ClientAndServer** on that board object.
3. Optional HUD: UXML with `<hr:UILabel name="boardLabel">` + a `--!Type(UI)` script binding `boardLabel` (per the UI Scripts page).

### Skeleton — LeaderboardBoard.lua
```lua
--!Type(ClientAndServer)
-- LeaderboardBoard.lua — tap the board to see the Top 10 coin scores.

local ShowBoardRequest = Event.new("ShowBoardRequest")
local ShowBoardEvent   = Event.new("ShowBoardEvent")

local LEADERBOARD_ID = "coins_all_time"
local TOP_N = 10

-- CLIENT: tapping the board asks the server for the standings.
function self:ClientAwake()
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        ShowBoardRequest:FireServer()
    end)
    ShowBoardEvent:Connect(function(text)
        print(text)
        -- TODO (Play-test): forward `text` to the HUD/board UILabel
        -- via SetPrelocalizedText (see UI note above).
    end)
end

-- SERVER: fetch and format. Only rank + score fields are used —
-- both are documented LeaderboardEntry properties.
function self:ServerAwake()
    ShowBoardRequest:Connect(function(player)
        Leaderboard.GetEntries(LEADERBOARD_ID, 1, TOP_N, function(entries, error)
            if error ~= LeaderboardError.None then
                ShowBoardEvent:FireClient(player, "Leaderboard unavailable right now.")
                return
            end
            local lines = { "— Top " .. TOP_N .. " Coin Scores —" }
            for i, entry in ipairs(entries) do
                lines[#lines + 1] = entry.rank .. ".  " .. entry.score .. " pts"
                -- NOTE: an entry display-name field is UNVERIFIED (see section 6).
                -- The docs' SetScore examples pass player.name when writing an
                -- entry, but the LeaderboardEntry property list checked for this
                -- plan documents only rank and score. Add names only after
                -- confirming the field in Play mode.
            end
            if #entries == 0 then
                lines[#lines + 1] = "No scores yet — be the first!"
            end
            ShowBoardEvent:FireClient(player, table.concat(lines, "\n"))
        end)
    end)
end
```

### Variants (same API, different `leaderboardId`)
- `coins_daily` / `coins_weekly`: write to these in §2 alongside the all-time board (two extra `IncrementScoreForPlayer` calls per coin), and clear them with `Leaderboard.Reset(id, cb)` on a schedule — **who runs the reset and when is a manual/ops step; an automatic timed reset is UNVERIFIED** (no scheduler API was confirmed for this plan).
- Personal best line: `Leaderboard.GetEntryForPlayer(LEADERBOARD_ID, player, cb)` returns the player's own entry — good for the welcome greeting in §1 instead of the raw Storage score.

### Test checklist
- [ ] After collecting coins on two clients, tap board → both scores listed, correctly ordered.
- [ ] Empty board shows the "No scores yet" line, not an error.
- [ ] Rapid repeated taps don't produce throttling errors in the console (if they do, add a client-side cooldown before `FireServer`).

---

## 4. Hooks for the existing bots (poker / blackjack / trivia)

Faceless already has two Highrise **room bots** — LJAAYYBot and LJAAYY2 (Python SDK) — running poker, blackjack, and trivia in room chat, with gold payouts funnelled through the bot code. The World (Studio/Lua) and the bots (Bot API/Python) are **two different Highrise systems**. This section is deliberately split into what is verified, what is a plan, and what is unverified — do not promise Faceless a seamless merge.

### 4a. Verified pieces
- Bots hear and speak in a **room**: `on_chat(user, message)` in, `self.highrise.chat(...)` / `send_whisper(...)` out (Bots guides). All existing game commands (`!poker`, `!blackjack`, `!trivia`, etc.) live there today.
- The Studio **Chat service** exists inside Worlds: channels via `Chat:CreateChannel`, membership via `Chat:AddPlayerToChannel`, and a message hook `Chat.TextMessageReceivedHandler` (Studio API service `Chat`). So *inside the World*, Lua can see player chat text and run its own command parsing — that part is a native World feature, independent of the bots.
- The Bot API has a hidden **ChannelRequest** ("communicate between bots or client-side scripts") — a documented bridge *concept* on the room side.

### 4b. UNVERIFIED — read before building anything here
- **Whether a Bot API bot can join / speak inside a Studio World instance the way it joins a room is UNVERIFIED.** Every bot guide checked documents rooms. Confirm in a live test (bot token + world/room ID) before designing around bots being present in the World.
- **The Python SDK method name for sending a ChannelRequest is UNVERIFIED** (only the REST endpoint description was checked).
- **No direct Lua↔Python bridge is documented in the pages checked.** World Lua Storage/Leaderboard and the bots' own data files are separate stores; nothing verified syncs them automatically.

### 4c. Recommended hook plan (works even if 4b stays unverified)
1. **World side (Lua, native): trivia + score tie-in.**
   Use `Chat.TextMessageReceivedHandler` to watch world chat for a small set of World-native commands — e.g. `!score` (reply via the §2/§3 events: tell the player their coin score and rank) and `!top` (show the board). Skeleton hook (server context; if you connect the handler, the docs say to pass the message through with `DisplayTextMessage` so chat still displays normally):
   ```lua
   --!Type(Server)
   -- WorldChatCommands.lua — PLAN skeleton; test the handler context in Play mode.
   function self:ServerStart()
       Chat.TextMessageReceivedHandler:Connect(function(channel, player, message, language, originalMessage)
           Chat:DisplayTextMessage(channel, player, message, language, originalMessage)
           if message == "!score" then
               -- Reuse section 2/3: fetch the player's score + leaderboard
               -- entry on the server and FireClient the reply to a client
               -- script that prints it. (Event plumbing as in sections 1-3.)
               print(player.name .. " asked for their score")
           end
       end)
   end
   ```
   *Caveat:* the Chat page shows the handler as ClientAndServer; which side(s) your script must run on for command parsing is a **Play-mode confirmation item**.
2. **Room side (bots, unchanged): poker/blackjack/trivia stay in the room.**
   The bots' games are gold/chat games already built and tested in the room environment. The World complements them rather than replacing them: the World is the coin/exploration game; the room (linked from the World — **link/portal mechanics UNVERIFIED**, at minimum a sign with the room name) is the casino/trivia lounge where LJAAYYBot and LJAAYY2 run the tables.
3. **Cross-promotion hooks that need no bridge:**
   - World → room: the welcome greeting (§1) names the bot games ("Poker and trivia run in LJAAYY's room — ask LJAAYYBot for `!poker`").
   - Room → World: add a bot chat command (e.g. `!world`) in the existing Python bot code that replies with the World's name/how to find it. This is ordinary `on_chat` + `self.highrise.chat` — verified bot pattern, small change to existing code, no new API.
   - Shared *display* (not shared data): the bot can announce the room's poker leaderboard in chat (it already tracks its own data), and the World board (§3) shows coin scores. Two boards, two games — no sync risk.
4. **If a real data bridge is ever wanted:** the World Persistence **Web API** exists (Creator Portal → your World → Management → API Key → Issue Token; "Highrise World Persistence API" guide). Whether its endpoints let an external Python process read the same values the Lua `Storage`/`Leaderboard` services write is **UNVERIFIED** — that is a research task of its own before anyone builds a sync. (Token handling rule stands: any such token goes through the secure vault only, never in code or chat.)

### Division of labour, in one line
**World/Lua owns:** coins, points, world leaderboard, welcome, in-world `!score`/`!top`.
**Bots/Python own:** poker, blackjack, trivia, gold bank/cashout — in the room, exactly as they work today.

---

## 5. Suggested build order

1. §1 WelcomeGreeter (smallest; proves events + Storage in the real project).
2. §2 ScoreSystem + 3–5 test coins (proves triggers, server validation, persistence).
3. §3 Leaderboard board (proves Leaderboard service + TapHandler + HUD wiring question).
4. §4c.1 in-world `!score`/`!top` chat hook.
5. §4c.3 bot-side `!world` command (existing Python code, next bot relaunch).
6. Only then: investigate §4b/§4c.4 (bots inside Worlds, Persistence Web API sync) as its own research task.

Every step: Play-test with the Virtual Player plus one real second account before moving on, per the checklists.

---

## 6. UNVERIFIED register (everything in one place)

1. Forwarding a gameplay event's text into a `--!Type(UI)` script's `UILabel` from a ClientAndServer script — the pieces (events, `--!Bind`, `SetPrelocalizedText`) are each documented, but this exact cross-script wiring was not shown in a checked example. Confirm in Play mode; the print fallback in every skeleton works regardless.
2. `LeaderboardEntry` display-name field — write-side examples pass `player.name`, but the entry property list checked documents only `rank` and `score`. Skeletons use only those two.
3. Coin respawn timers / clearing `collectedCoins` entries mid-session — design extension, not a documented pattern.
4. Automatic scheduled reset of daily/weekly leaderboards — no scheduler API confirmed; `Leaderboard.Reset` itself is verified, its trigger is manual until proven otherwise.
5. Bot API bots joining/speaking inside a Studio World instance (vs. a room) — not documented in the bot guides checked.
6. Python SDK method for the Bot API `ChannelRequest` endpoint — endpoint description verified, SDK call not checked.
7. World Persistence Web API as a Lua Storage/Leaderboard sync bridge for the Python bots — API and token issuance exist; equivalence with in-world Storage data unverified.
8. World→room links/portals for sending players from the World to the bots' room — not checked; signage text is the fallback.
9. `Chat.TextMessageReceivedHandler` execution context (client vs server) for command parsing — page marks it ClientAndServer; confirm where the connection must live in Play mode.
10. A server-Lua "send world chat message" call — not confirmed in the pages checked; skeletons therefore deliver text via `FireClient` + client print/UI instead of inventing a chat-send function. (The Chat service page mentions spawning a chat bubble at a position, but the method name was not captured — do not guess it.)

## Sources (all create.highrise.game, checked 2026-11-22)
- Client Server Communication — https://create.highrise.game/learn/studio/create/scripting/advanced/client-server-communication
- GameServer / GameClient / Player / User / Self classes — https://create.highrise.game/learn/studio-api/classes/GameServer (and sibling class pages)
- Storage service — https://create.highrise.game/learn/studio-api/services/Storage
- Leaderboard class — https://create.highrise.game/learn/studio-api/classes/Leaderboard ; Leaderboard API guide — https://create.highrise.game/learn/studio/create/scripting/advanced/leaderboard-api
- Tap Handlers — https://create.highrise.game/learn/studio/create/scripting/advanced/taphandlers
- UI Scripts — https://create.highrise.game/learn/studio/create/scripting/script-types/ui ; Bind — https://create.highrise.game/learn/studio/create/scripting/lua/attributes/bind
- Chat service — https://create.highrise.game/learn/studio-api/services/Chat
- Player and Character Events — https://create.highrise.game/learn/studio/create/scripting/advanced/player-character-events
- Bots: Tipping Bot / Statistics Bot guides; ChannelRequest — https://create.highrise.game/learn/bots/api/endpoints/channelrequest
- World Persistence API — https://create.highrise.game/learn/studio/create/scripting/advanced/world-persistence-api

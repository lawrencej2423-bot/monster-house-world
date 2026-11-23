--!Type(ClientAndServer)
-- BlackjackStation.lua — world-side station script for the blackjack
-- tables.
--
-- Attach this ONE script to BOTH blackjack table objects:
--   BlackjackTable_Main (centre 19, 0, 18 — 7 player seats, curved side)
--   PvPBlackjackTable   (centre 19, 0, 11 — 7 player seats, mirrored)
-- Each copy tells the tables apart by its own object name and looks its
-- config up in CardStationShared. Event handlers ignore requests that
-- name a different table, so the two copies never fight.
--
-- WHAT THIS SCRIPT DOES (world side only):
--   * Walk-up prompt when a player enters the table's ring.
--   * Tap the table = take a seat / tap again = stand up. The SERVER
--     assigns seats (authoritative, SCRIPTS.md section 0): it checks the
--     player is really standing at this table before seating them.
--   * Signage state: OPEN / SEATING / FULL + seat count, broadcast to all
--     clients on every change (see CardStationShared.FormatSignLine).
--
-- DEALER RULE: the seat map hands out PLAYER seats only (7 per table,
-- DESIGN.md section 3). The dealer position is never a seat — it is the
-- bot anchor BotStation_Blackjack (19, 0, 19.8, flat/north side of
-- BlackjackTable_Main, facing the player seats — DESIGN.md section 5),
-- where LJAAYYBot stands.
--
-- WHAT IT NEVER DOES: cards, hands, bets, gold. Blackjack itself (house
-- and PvP) is run by the dealer bot LJAAYYBot in chat (!blackjack). The
-- two tables exist so house and PvP games never share a table visually
-- (DESIGN.md section 3, B2); which mode is live is the bot's business —
-- this script only mirrors seats and signage.
--
-- Studio setup per table object:
--   1. A Collider (the table / its clear ring) with TapHandler on it.
--   2. A trigger Collider covering the seat ring, for the walk-up prompt
--      (OnTriggerEnter pattern, SCRIPTS.md section 2).

local Shared = require("CardStationShared")

local SeatRequest  = Event.new("BlackjackSeatRequest")   -- client -> server
local LeaveRequest = Event.new("BlackjackLeaveRequest")  -- client -> server
local SeatReply    = Event.new("BlackjackSeatReply")     -- server -> one client
local StateChanged = Event.new("BlackjackStationState")  -- server -> all clients

-- This copy's identity, set in ClientAwake / ServerAwake from the object
-- the script is attached to.
local myStationName = nil
local myConfig = nil

-- Client-only: am I seated at this table, and in which seat?
local mySeat = nil

-- Server-only seat map for THIS table: seatNumber -> player name, plus
-- the reverse lookup. (In a ClientAndServer script these locals exist on
-- both sides; only the server copies are ever written — same pattern as
-- ScoreSystem's collectedCoins in SCRIPTS.md section 2.)
local seats = {}
local seatByPlayer = {}
local seatedCount = 0

local function LoadMyConfig()
    myStationName = self.gameObject.name
    myConfig = Shared.CardStations_GetConfig(myStationName)
    if myConfig == nil then
        print("[BlackjackStation] WARNING: attached to '" .. myStationName
            .. "', which is not a known blackjack table. "
            .. "Attach only to BlackjackTable_Main / PvPBlackjackTable.")
    end
    return myConfig ~= nil
end

-- SERVER: push the current signage state to every client.
local function BroadcastState()
    local mode = Shared.CardStations_DeriveMode(seatedCount, myConfig.seats)
    StateChanged:FireAllClients(myStationName, mode, seatedCount, myConfig.seats)
end

-- SERVER: lowest free PLAYER seat number, or nil when the table is full.
-- (The dealer spot is BotStation_Blackjack — never in this map.)
local function LowestFreeSeat()
    for seat = 1, myConfig.seats do
        if seats[seat] == nil then return seat end
    end
    return nil
end

-- SERVER: free a player's seat (leave request or disconnect).
local function ClearSeat(player)
    local seat = seatByPlayer[player.name]
    if seat == nil then return end
    seats[seat] = nil
    seatByPlayer[player.name] = nil
    seatedCount = seatedCount - 1
    BroadcastState()
end

-- CLIENT: walk-up prompt (verified trigger pattern, SCRIPTS.md section 2).
function self:OnTriggerEnter(other)
    if client == nil or myConfig == nil then return end
    local character = other.gameObject:GetComponent(Character)
    if character == nil then return end
    if client.localPlayer == character.player then
        print(Shared.CardStations_FormatPrompt(myConfig))
    end
end

function self:ClientAwake()
    if not LoadMyConfig() then return end

    -- Tap the table: seat me if I'm standing, stand me up if I'm seated.
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        if mySeat ~= nil then
            LeaveRequest:FireServer(myStationName)
        else
            SeatRequest:FireServer(myStationName)
        end
    end)

    -- Personal reply to my seat/leave requests.
    SeatReply:Connect(function(stationName, seated, seatNumber, message)
        if stationName ~= myStationName then return end
        if seated then mySeat = seatNumber else mySeat = nil end
        print(message)
    end)

    -- Signage state for this table.
    StateChanged:Connect(function(stationName, mode, count, total)
        if stationName ~= myStationName then return end
        local line = Shared.CardStations_FormatSignLine(myConfig, mode, count)
        print("[SIGN] " .. line)
        -- TODO (Play-test): forward `line` to this station's sign
        -- (BlackjackSign for the main table; the "PvP" sign post for the
        -- PvP table) via the UI-script bind pattern (SCRIPTS.md sections
        -- 3 + 6, item 1 — cross-script UI wiring is UNVERIFIED until
        -- confirmed in Play mode; the print above always works).
    end)
end

function self:ServerAwake()
    if not LoadMyConfig() then return end

    -- Builder self-check: the dealer anchor must exist under its EXACT
    -- DESIGN.md section 5 name, or the bot has nowhere defined to stand.
    if GameObject.Find(myConfig.botAnchor) == nil then
        print("[BlackjackStation] WARNING: bot anchor '" .. myConfig.botAnchor
            .. "' not found in scene — place it exactly as named "
            .. "(DESIGN.md section 5).")
    end

    SeatRequest:Connect(function(player, stationName)
        if stationName ~= myStationName then return end

        if seatByPlayer[player.name] ~= nil then
            SeatReply:FireClient(player, myStationName, true,
                seatByPlayer[player.name],
                "You are already seated at " .. myConfig.displayName .. ".")
            return
        end
        if player.character == nil then return end

        -- Server-side proximity check: never trust the client's word
        -- that it is at the table (SCRIPTS.md section 2 anti-cheat).
        local distance = Vector3.Distance(
            player.character.transform.position,
            self.gameObject.transform.position)
        if distance > Shared.SEAT_MAX_DISTANCE then
            SeatReply:FireClient(player, myStationName, false, 0,
                "Come closer to the table to take a seat.")
            return
        end

        local seat = LowestFreeSeat()
        if seat == nil then
            SeatReply:FireClient(player, myStationName, false, 0,
                myConfig.displayName .. " is full — try the other table.")
            return
        end

        seats[seat] = player.name
        seatByPlayer[player.name] = seat
        seatedCount = seatedCount + 1
        SeatReply:FireClient(player, myStationName, true, seat,
            "Seat " .. seat .. " at " .. myConfig.displayName
            .. ". " .. myConfig.botName .. " deals — play in chat: "
            .. myConfig.playCommand)
        BroadcastState()
    end)

    LeaveRequest:Connect(function(player, stationName)
        if stationName ~= myStationName then return end
        if seatByPlayer[player.name] == nil then return end
        ClearSeat(player)
        SeatReply:FireClient(player, myStationName, false, 0,
            "You stood up from " .. myConfig.displayName .. ".")
    end)

    -- A player who disconnects while seated frees the seat.
    server.PlayerDisconnected:Connect(function(player)
        ClearSeat(player)
    end)
end

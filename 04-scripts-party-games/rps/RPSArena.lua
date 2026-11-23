--!Type(ClientAndServer)
-- RPSArena.lua — attach to the RPSCircle object (DESIGN.md Zone B3,
-- center (7.5, 0, 10), radius 2.5, gold ring). Yard dressing: a dueling
-- circle ringed on the front lawn, podiums facing each other.
--
-- PRESENTATION ONLY. Throws, winners, tournament brackets and gold
-- live in LJAAYY2 (bot #2), who referees from BotStation_RPS
-- ((7.5, 0, 13.5), just north of the circle — DESIGN.md section 5).
-- This script tracks who is standing on RPSPodium_A / RPSPodium_B
-- (server-validated, like StationPresence) and renders what the bot
-- announces through the display bridge (PartyGameChatHook.lua):
--   [RPS] STATE: <text>    -> arena banner (countdowns, "SHOOT!", …)
--   [RPS] WINNER: <name>   -> arena banner celebrates the winner
--   [RPS] IDLE             -> banner returns to the how-to card
-- It NEVER decides a winner itself: no throws are read here, by design.

local Common = require("PartyGameCommon")

local RPSDisplayEvent  = Event.new("RPSDisplayEvent")    -- bridge -> all clients (+ server cache)
local BannerTextEvent  = Event.new("RPSBannerText")      -- server -> one client (catch-up only)
local StateRequest     = Event.new("RPSStateRequest")    -- client -> server
local ClaimPodiumReq   = Event.new("RPSClaimPodium")     -- client -> server
local ReleasePodiumEvt = Event.new("RPSReleasePodium")   -- client -> server
local PodiumEvent      = Event.new("RPSPodiumEvent")     -- server -> all clients / one client
local PresenceEvent    = Event.new("StationPresenceEvent")

local IDLE_TEXT = "ROCK PAPER SCISSORS — tournaments in chat: !rps"

local function Render(kind, payload)
    if kind == "STATE" then
        return "✊✋✌️ " .. payload
    elseif kind == "WINNER" then
        return "🏆 " .. payload .. " takes the circle!"
    else -- IDLE and anything unrecognised
        return IDLE_TEXT
    end
end

-- CLIENT: print bridge updates and podium changes, cache the banner
-- for tap re-display, and catch up from the server on join. Podium
-- claims originate in RPSPodiumTrigger.lua (the docs' CoinCollector
-- pattern) and are validated on the server below.
function self:ClientAwake()
    local lastKind, lastPayload = "IDLE", ""

    RPSDisplayEvent:Connect(function(kind, payload)
        lastKind, lastPayload = kind, payload
        print("[RPS arena] " .. Render(kind, payload))
    end)

    PodiumEvent:Connect(function(podiumName, playerName)
        if playerName == "" then
            print(podiumName .. " is open.")
        else
            print(playerName .. " steps up on " .. podiumName .. ".")
        end
    end)

    PresenceEvent:Connect(function(anchorName, playerName)
        if anchorName == "BotStation_RPS" and playerName ~= "" then
            print("Referee on station: " .. playerName)
        end
    end)

    -- Tapping the circle re-shows the current banner / how-to card.
    local tap = self.gameObject:GetComponent(TapHandler)
    if tap ~= nil then
        tap.Tapped:Connect(function()
            print("[RPS arena] " .. Render(lastKind, lastPayload))
        end)
    end

    StateRequest:FireServer()
end

-- SERVER: validate podium claims by distance (never trust the client),
-- track occupants, cache the banner for late joiners.
function self:ServerAwake()
    local lastKind, lastPayload = "IDLE", ""
    local podiumOccupants = {} -- podium name -> player name

    RPSDisplayEvent:Connect(function(kind, payload)
        lastKind, lastPayload = kind, payload
    end)

    ClaimPodiumReq:Connect(function(player, podiumName)
        local point = Common.PODIUM_POS[podiumName]
        if point == nil or player.character == nil then return end
        if Common.GroundDistance(player.character.transform.position, point) > Common.MAX_SPOT_DISTANCE then
            return
        end
        if podiumOccupants[podiumName] ~= player.name then
            podiumOccupants[podiumName] = player.name
            PodiumEvent:FireAllClients(podiumName, player.name)
        end
    end)

    ReleasePodiumEvt:Connect(function(player, podiumName)
        if podiumOccupants[podiumName] == player.name then
            podiumOccupants[podiumName] = nil
            PodiumEvent:FireAllClients(podiumName, "")
        end
    end)

    server.PlayerDisconnected:Connect(function(player)
        for podiumName, name in pairs(podiumOccupants) do
            if name == player.name then
                podiumOccupants[podiumName] = nil
                PodiumEvent:FireAllClients(podiumName, "")
            end
        end
    end)

    StateRequest:Connect(function(player)
        BannerTextEvent:FireClient(player, Render(lastKind, lastPayload))
        for podiumName, name in pairs(podiumOccupants) do
            PodiumEvent:FireClient(player, podiumName, name)
        end
    end)
end

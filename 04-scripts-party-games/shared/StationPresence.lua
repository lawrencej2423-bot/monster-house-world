--!Type(ClientAndServer)
-- StationPresence.lua — attach to ONE empty object in the scene
-- (suggested name: PartyGameStations). Tracks which player (usually a
-- bot avatar) is standing at this section's DESIGN.md section 5 anchors:
--   BotStation_TriviaHost, BotStation_RPS, BotStation_Radio
--
-- Pattern is the docs' ScoreSystem one, reused: a client trigger script
-- (StationSpotTrigger.lua) CLAIMS occupation; this server side VALIDATES
-- the claim with a distance check before believing it. Presence is
-- presentational only — signs and stage dressing react to it; game
-- state never lives here (DESIGN.md section 5: "game state lives in
-- the bots, never in the scene").

local Common = require("PartyGameCommon")

local ClaimSpotRequest  = Event.new("StationClaimRequest")   -- client -> server
local ReleaseSpotEvent  = Event.new("StationReleaseEvent")   -- client -> server
local PresenceEvent     = Event.new("StationPresenceEvent")  -- server -> all clients

-- Server: anchor name -> player name standing there (or nil).
local occupants = {}

local function BroadcastPresence(anchorName)
    PresenceEvent:FireAllClients(anchorName, occupants[anchorName] or "")
end

-- CLIENT: print presence changes. (Claims originate in
-- StationSpotTrigger.lua, which fires ClaimSpotRequest itself;
-- consumers like TriviaStage also listen to PresenceEvent directly.)
function self:ClientAwake()
    PresenceEvent:Connect(function(anchorName, playerName)
        if playerName == "" then
            print(anchorName .. " is now empty.")
        else
            print(playerName .. " is on station at " .. anchorName .. ".")
        end
    end)
end

-- SERVER: validate claims, track occupants, notice departures.
function self:ServerAwake()
    ClaimSpotRequest:Connect(function(player, anchorName)
        local point = Common.ANCHOR_POS[anchorName]
        if point == nil or player.character == nil then return end
        if Common.GroundDistance(player.character.transform.position, point) > Common.MAX_SPOT_DISTANCE then
            return -- claimed a spot they are not standing on: ignore
        end
        if occupants[anchorName] ~= player.name then
            occupants[anchorName] = player.name
            BroadcastPresence(anchorName)
        end
    end)

    ReleaseSpotEvent:Connect(function(player, anchorName)
        if occupants[anchorName] == player.name then
            occupants[anchorName] = nil
            BroadcastPresence(anchorName)
        end
    end)

    server.PlayerDisconnected:Connect(function(player)
        for anchorName, name in pairs(occupants) do
            if name == player.name then
                occupants[anchorName] = nil
                BroadcastPresence(anchorName)
            end
        end
    end)
end

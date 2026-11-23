--!Type(ClientAndServer)
-- RadioBooth.lua — attach to the DJBooth object (DESIGN.md Zone E,
-- center (34, 0, 27), facing south). Home of LJAAYY Radio.
--
-- PRESENTATION ONLY. The actual stream, song queue and !song requests
-- live with the bots / the radio service — this script runs the booth's
-- in-world face: the now-playing sign (RadioBoothUI.lua), booth tap
-- re-display, and presence at BotStation_Radio (behind the booth,
-- (34, 0, 27.8), DESIGN.md section 5 — either bot may idle there).
--
-- Display bridge (PartyGameChatHook.lua), from either bot:
--   [RADIO] NOW: <song / show text>  -> sign shows what's playing
--   [RADIO] OFF                      -> sign returns to the idle card
-- No audio is controlled by this script — no world audio API was
-- verified in SCRIPTS.md.

local RadioDisplayEvent = Event.new("RadioDisplayEvent")  -- bridge -> all clients (+ server cache)
local SignTextEvent     = Event.new("RadioSignText")      -- server -> one client (catch-up only)
local StateRequest      = Event.new("RadioStateRequest")  -- client -> server (late joiners)
local PresenceEvent     = Event.new("StationPresenceEvent")

local IDLE_TEXT = "LJAAYY RADIO — requests in chat: !song"

local function Render(kind, payload)
    if kind == "NOW" then
        return "🎵 Now playing: " .. payload
    else -- OFF and anything unrecognised
        return IDLE_TEXT
    end
end

-- CLIENT: print bridge updates, cache the latest card for tap
-- re-display, and catch up from the server on join.
function self:ClientAwake()
    local lastKind, lastPayload = "OFF", ""

    RadioDisplayEvent:Connect(function(kind, payload)
        lastKind, lastPayload = kind, payload
        print("[Radio booth] " .. Render(kind, payload))
    end)

    PresenceEvent:Connect(function(anchorName, playerName)
        if anchorName == "BotStation_Radio" and playerName ~= "" then
            print(playerName .. " is behind the DJ booth.")
        end
    end)

    local tap = self.gameObject:GetComponent(TapHandler)
    if tap ~= nil then
        tap.Tapped:Connect(function()
            print("[Radio booth] " .. Render(lastKind, lastPayload))
        end)
    end

    StateRequest:FireServer()
end

-- SERVER: cache the latest card for late joiners. Same Play-test note
-- as TriviaStage: if a server-side Connect does not receive the
-- bridge's FireAllClients, only catch-up is lost, not live rendering.
function self:ServerAwake()
    local lastKind, lastPayload = "OFF", ""

    RadioDisplayEvent:Connect(function(kind, payload)
        lastKind, lastPayload = kind, payload
    end)

    StateRequest:Connect(function(player)
        SignTextEvent:FireClient(player, Render(lastKind, lastPayload))
    end)
end

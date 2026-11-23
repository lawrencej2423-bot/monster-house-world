--!Type(ClientAndServer)
-- TriviaStage.lua — attach to the StageScreen object (DESIGN.md Zone D;
-- its scripting hook name is "TriviaScreen"). In the Monster House yard
-- dressing, the stage sits in the yard's stage corner and the audience
-- faces the house facade behind it.
--
-- PRESENTATION ONLY. Trivia questions, answers, scoring and gold live
-- in LJAAYYBot (bot #1) — see SCRIPTS.md section 4. This script renders
-- what the bot announces through the display bridge
-- (PartyGameChatHook.lua):
--   [TRIVIA] QUESTION: <text>   -> screen shows the question
--   [TRIVIA] ANSWER: <text>     -> screen reveals the answer
--   [TRIVIA] WINNER: <name>     -> screen celebrates the winner
--   [TRIVIA] IDLE               -> screen returns to the idle card
-- Rendering paths: TriviaScreenUI.lua draws the same updates on the
-- screen surface; this script prints them (verified fallback) and the
-- server caches the latest card for late joiners.
-- The host bot avatar stands at BotStation_TriviaHost (= HostSpot,
-- DESIGN.md section 5); StationPresence reports when it is occupied.

local TriviaDisplayEvent = Event.new("TriviaDisplayEvent")  -- bridge -> all clients (+ server cache)
local ScreenTextEvent    = Event.new("TriviaScreenText")    -- server -> one client (catch-up only)
local StateRequest       = Event.new("TriviaStateRequest")  -- client -> server (late joiners)
local PresenceEvent      = Event.new("StationPresenceEvent")

local IDLE_TEXT = "TRIVIA NIGHT — questions run in chat with LJAAYYBot"

-- Render one display update into screen text. Pure function of the
-- bridge payload, shared by the live path and the late-joiner path.
-- (TriviaScreenUI.lua keeps its own copy — UI scripts cannot be
-- assumed to require() this gameplay script.)
local function Render(kind, payload)
    if kind == "QUESTION" then
        return "❓ " .. payload
    elseif kind == "ANSWER" then
        return "✅ Answer: " .. payload
    elseif kind == "WINNER" then
        return "🏆 " .. payload .. " got it!"
    else -- IDLE and anything unrecognised
        return IDLE_TEXT
    end
end

-- CLIENT: print bridge updates and remember the latest card so tapping
-- the screen re-shows it; ask the server for catch-up on join.
function self:ClientAwake()
    local lastKind, lastPayload = "IDLE", ""

    TriviaDisplayEvent:Connect(function(kind, payload)
        lastKind, lastPayload = kind, payload
        print("[Trivia screen] " .. Render(kind, payload))
    end)

    PresenceEvent:Connect(function(anchorName, playerName)
        if anchorName == "BotStation_TriviaHost" and playerName ~= "" then
            print("Trivia host on stage: " .. playerName)
        end
    end)

    -- Tap the screen to re-show the current card (e.g. you walked up
    -- mid-question). Requires a TapHandler on the screen object.
    local tap = self.gameObject:GetComponent(TapHandler)
    if tap ~= nil then
        tap.Tapped:Connect(function()
            print("[Trivia screen] " .. Render(lastKind, lastPayload))
        end)
    end

    StateRequest:FireServer()
end

-- SERVER: cache the latest display so a player who joins mid-round can
-- be caught up on the screen surface. NOTE (Play-test item, in the
-- spirit of SCRIPTS.md section 6): this assumes a server-side Connect
-- on TriviaDisplayEvent receives the bridge's FireAllClients. If it
-- does not, only the catch-up is lost — live rendering on connected
-- clients is unaffected.
function self:ServerAwake()
    local lastKind, lastPayload = "IDLE", ""

    TriviaDisplayEvent:Connect(function(kind, payload)
        lastKind, lastPayload = kind, payload
    end)

    StateRequest:Connect(function(player)
        ScreenTextEvent:FireClient(player, Render(lastKind, lastPayload))
    end)
end

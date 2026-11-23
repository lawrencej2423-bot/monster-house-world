--!Type(Module)
-- PartyGameCommon.lua — shared constants + helpers for the party-game
-- scripts (trivia stage, radio booth, RPS arena). Other scripts in this
-- section load it with:  local Common = require("PartyGameCommon")
--
-- Everything here mirrors DESIGN.md exactly:
--   * Bot station anchor names are DESIGN.md section 5, character-for-
--     character. Bot code references these names — never rename them.
--   * Object names and positions are DESIGN.md section 3 (Zones B3/D/E).
--   * The bots (LJAAYYBot / LJAAYY2, Python) own ALL game logic: trivia
--     questions and scoring, RPS throws and winners, radio playback.
--     These Lua scripts are presentation only: screens, signs, podium
--     and station presence. They never decide a winner or move gold.

local M = {}

-- Bot display names (chat sender names the display bridge trusts).
M.BOT_TRIVIA = "LJAAYYBot"   -- bot #1: blackjack default, trivia host in event mode
M.BOT_RPS    = "LJAAYY2"     -- bot #2: poker default, RPS referee in event mode
M.BOT_RADIO  = nil           -- radio may be announced by either bot (see RadioBooth)

-- DESIGN.md section 5 anchors used by THIS section (exact names).
M.ANCHOR_TRIVIA_HOST = "BotStation_TriviaHost"  -- = HostSpot (20.5, 0.6, 26.5), on stage
M.ANCHOR_RPS_REFEREE = "BotStation_RPS"         -- (7.5, 0, 13.5), north of RPSCircle
M.ANCHOR_RADIO       = "BotStation_Radio"       -- behind DJBooth (34, 0, 27.8)

-- Anchor ground positions { x, z } from DESIGN.md section 5, used by the
-- server to distance-validate station-occupation claims (the docs'
-- ScoreSystem rule: never trust the client, re-check on the server).
M.ANCHOR_POS = {
    BotStation_TriviaHost = { x = 20.5, z = 26.5 },
    BotStation_RPS        = { x = 7.5,  z = 13.5 },
    BotStation_Radio      = { x = 34.0, z = 27.8 },
}

-- DESIGN.md section 3 objects used by THIS section (exact names).
M.OBJ_TRIVIA_SCREEN = "TriviaScreen"    -- scripting hook name for StageScreen
M.OBJ_HOST_SPOT     = "HostSpot"
M.OBJ_DJ_BOOTH      = "DJBooth"
M.OBJ_RADIO_SIGN    = "RadioSign"
M.OBJ_RPS_CIRCLE    = "RPSCircle"
M.OBJ_RPS_PODIUM_A  = "RPSPodium_A"     -- (5.5, 0, 10)
M.OBJ_RPS_PODIUM_B  = "RPSPodium_B"     -- (9.5, 0, 10)
M.OBJ_RPS_SIGN      = "RPSSign"

M.PODIUM_POS = {
    RPSPodium_A = { x = 5.5, z = 10.0 },
    RPSPodium_B = { x = 9.5, z = 10.0 },
}

-- How close (ground-plane units) a character must be to a spot for the
-- server to accept "I am standing there". Matches the docs' coin rule
-- scale (max collect distance 3); spots are small, so 1.5 is generous.
M.MAX_SPOT_DISTANCE = 1.5

-- Ground-plane distance between a character position and an {x, z} point.
-- Manual math on position components — deliberately avoids assuming a
-- Vector3 constructor the checked docs did not show.
function M.GroundDistance(pos, point)
    local dx = pos.x - point.x
    local dz = pos.z - point.z
    return math.sqrt(dx * dx + dz * dz)
end

-- Display-bridge protocol (see PartyGameChatHook.lua): the owning bot
-- posts ONE ordinary chat line and the world mirrors it onto the
-- screen / sign / arena state. Lines look like:
--   [TRIVIA] QUESTION: Which planet is known as the Red Planet?
--   [TRIVIA] ANSWER: Mars
--   [TRIVIA] WINNER: SomePlayer
--   [TRIVIA] IDLE
--   [RADIO] NOW: Song Title — Artist
--   [RADIO] OFF
--   [RPS] STATE: Rock… Paper… Scissors…
--   [RPS] WINNER: SomePlayer
--   [RPS] IDLE
-- Returns tag, kind, payload — or nil if the line is not a display line.
function M.ParseDisplayLine(message)
    if type(message) ~= "string" then return nil end
    local tag, rest = message:match("^%[(%u+)%]%s*(.+)$")
    if tag == nil then return nil end
    local kind, payload = rest:match("^(%u+):%s*(.+)$")
    if kind ~= nil then return tag, kind, payload end
    -- Bare form, e.g. "[TRIVIA] IDLE" / "[RADIO] OFF"
    local bare = rest:match("^(%u+)$")
    if bare ~= nil then return tag, bare, "" end
    return nil
end

return M

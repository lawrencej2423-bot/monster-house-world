--!Type(ClientAndServer)
-- PartyGameChatHook.lua — attach to ONE empty object in the scene
-- (suggested name: PartyGameBridge). This is the ONLY chat hook in this
-- section: exactly one script may pass messages through with
-- Chat:DisplayTextMessage, or chat lines would display multiple times.
--
-- What it does: watches world chat for display-bridge lines posted by
-- the game bots (protocol in PartyGameCommon.lua) and re-fires them as
-- internal events the trivia / radio / RPS scripts render:
--   TriviaDisplayEvent(kind, payload)   from LJAAYYBot  (bot #1)
--   RadioDisplayEvent(kind, payload)    from either bot
--   RPSDisplayEvent(kind, payload)      from LJAAYY2    (bot #2)
-- Sender is checked by player.name, so a random player typing
-- "[TRIVIA] WINNER: me" changes nothing.
--
-- HONEST LIMITS (from SCRIPTS.md section 4b/6): whether Bot API bots can
-- speak inside a Studio World at all is UNVERIFIED, and the Chat
-- handler's execution context is a Play-mode confirmation item. If bots
-- never appear in world chat, this hook simply never fires and every
-- script still works in its idle/manual states. The bot-side change to
-- emit these lines is one ordinary chat() call per announcement —
-- a bot-package change for the parent agent, NOT made here.

local Common = require("PartyGameCommon")

local TriviaDisplayEvent = Event.new("TriviaDisplayEvent")
local RadioDisplayEvent  = Event.new("RadioDisplayEvent")
local RPSDisplayEvent    = Event.new("RPSDisplayEvent")

local EVENT_FOR_TAG = {
    TRIVIA = TriviaDisplayEvent,
    RADIO  = RadioDisplayEvent,
    RPS    = RPSDisplayEvent,
}

local function SenderAllowed(tag, playerName)
    if tag == "TRIVIA" then return playerName == Common.BOT_TRIVIA end
    if tag == "RPS" then return playerName == Common.BOT_RPS end
    if tag == "RADIO" then
        return playerName == Common.BOT_TRIVIA or playerName == Common.BOT_RPS
    end
    return false
end

function self:ServerStart()
    Chat.TextMessageReceivedHandler:Connect(function(channel, player, message, language, originalMessage)
        -- Always pass the message through first, so normal chat is
        -- never swallowed (per the Chat service docs).
        Chat:DisplayTextMessage(channel, player, message, language, originalMessage)

        local tag, kind, payload = Common.ParseDisplayLine(message)
        if tag == nil then return end
        if not SenderAllowed(tag, player.name) then return end

        local event = EVENT_FOR_TAG[tag]
        if event ~= nil then
            event:FireAllClients(kind, payload)
        end
    end)
end

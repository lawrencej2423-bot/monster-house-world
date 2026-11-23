--!Type(UI)
-- TriviaScreenUI.lua — world-space UI for the trivia stage screen.
-- Pair with TriviaScreen.uxml (a single UILabel named triviaScreenLabel,
-- UI Output set to world-space and placed on the StageScreen surface).
--
-- It renders two feeds:
--   * TriviaDisplayEvent — live bridge updates (questions/answers).
--   * TriviaScreenText   — the server's catch-up card for late joiners.
--
-- UNVERIFIED WIRING (SCRIPTS.md section 6, item 1): the pieces — Events,
-- --!Bind, SetPrelocalizedText — are each documented, but feeding a
-- gameplay event into a UI script was not shown in a checked example.
-- Confirm in Play mode; TriviaStage's print() fallback works regardless.

--!Bind
local triviaScreenLabel : UILabel = nil

local TriviaDisplayEvent = Event.new("TriviaDisplayEvent")
local ScreenTextEvent    = Event.new("TriviaScreenText")

local IDLE_TEXT = "TRIVIA NIGHT — questions run in chat with LJAAYYBot"

-- Own copy of TriviaStage's Render (UI scripts cannot be assumed to
-- require() gameplay scripts). Keep the two in step.
local function Render(kind, payload)
    if kind == "QUESTION" then
        return "❓ " .. payload
    elseif kind == "ANSWER" then
        return "✅ Answer: " .. payload
    elseif kind == "WINNER" then
        return "🏆 " .. payload .. " got it!"
    else
        return IDLE_TEXT
    end
end

function self:ClientStart()
    triviaScreenLabel:SetPrelocalizedText(IDLE_TEXT)
    TriviaDisplayEvent:Connect(function(kind, payload)
        triviaScreenLabel:SetPrelocalizedText(Render(kind, payload))
    end)
    ScreenTextEvent:Connect(function(text)
        triviaScreenLabel:SetPrelocalizedText(text)
    end)
end

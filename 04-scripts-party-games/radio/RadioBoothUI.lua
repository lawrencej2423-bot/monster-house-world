--!Type(UI)
-- RadioBoothUI.lua — world-space UI for the RadioSign surface above the
-- DJ booth (DESIGN.md Zone E: RadioSign, Y 4.5, "LJAAYY RADIO").
-- Pair with RadioBooth.uxml (UILabel named radioSignLabel).
--
-- It renders two feeds:
--   * RadioDisplayEvent — live bridge updates (now-playing lines).
--   * RadioSignText     — the server's catch-up card for late joiners.
--
-- UNVERIFIED WIRING (SCRIPTS.md section 6, item 1): same note as
-- TriviaScreenUI — pieces documented, cross-script feed is a Play-mode
-- confirmation item. RadioBooth's print() fallback works regardless.

--!Bind
local radioSignLabel : UILabel = nil

local RadioDisplayEvent = Event.new("RadioDisplayEvent")
local SignTextEvent     = Event.new("RadioSignText")

local IDLE_TEXT = "LJAAYY RADIO — requests in chat: !song"

-- Own copy of RadioBooth's Render (UI scripts cannot be assumed to
-- require() gameplay scripts). Keep the two in step.
local function Render(kind, payload)
    if kind == "NOW" then
        return "🎵 Now playing: " .. payload
    else
        return IDLE_TEXT
    end
end

function self:ClientStart()
    radioSignLabel:SetPrelocalizedText(IDLE_TEXT)
    RadioDisplayEvent:Connect(function(kind, payload)
        radioSignLabel:SetPrelocalizedText(Render(kind, payload))
    end)
    SignTextEvent:Connect(function(text)
        radioSignLabel:SetPrelocalizedText(text)
    end)
end

--!Type(UI)
-- RPSArenaUI.lua — world-space banner UI for the RPS arena, placed by
-- the RPSSign post (DESIGN.md Zone B3: post sign at (7.5, 1.8, 7.8),
-- facing south). Pair with RPSArena.uxml (UILabel named rpsBannerLabel).
--
-- It renders two feeds:
--   * RPSDisplayEvent — live bridge updates (state / winner lines).
--   * RPSBannerText   — the server's catch-up card for late joiners.
--
-- UNVERIFIED WIRING (SCRIPTS.md section 6, item 1): same note as the
-- other UI scripts in this section — confirm in Play mode;
-- RPSArena's print() fallback works regardless.

--!Bind
local rpsBannerLabel : UILabel = nil

local RPSDisplayEvent = Event.new("RPSDisplayEvent")
local BannerTextEvent = Event.new("RPSBannerText")

local IDLE_TEXT = "ROCK PAPER SCISSORS — tournaments in chat: !rps"

-- Own copy of RPSArena's Render (UI scripts cannot be assumed to
-- require() gameplay scripts). Keep the two in step.
local function Render(kind, payload)
    if kind == "STATE" then
        return "✊✋✌️ " .. payload
    elseif kind == "WINNER" then
        return "🏆 " .. payload .. " takes the circle!"
    else
        return IDLE_TEXT
    end
end

function self:ClientStart()
    rpsBannerLabel:SetPrelocalizedText(IDLE_TEXT)
    RPSDisplayEvent:Connect(function(kind, payload)
        rpsBannerLabel:SetPrelocalizedText(Render(kind, payload))
    end)
    BannerTextEvent:Connect(function(text)
        rpsBannerLabel:SetPrelocalizedText(text)
    end)
end

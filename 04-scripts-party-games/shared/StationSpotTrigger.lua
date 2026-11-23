--!Type(Client)
-- StationSpotTrigger.lua — attach to EACH station anchor object that
-- has a Collider set as a trigger:
--   BotStation_TriviaHost, BotStation_RPS, BotStation_Radio
-- (DESIGN.md section 5 — the anchor object names ARE the spot names,
-- so this one script serves all three with no per-object config.)
--
-- Same shape as the docs' CoinCollector: the client notices the local
-- player stepping on/off the spot and CLAIMS it; StationPresence.lua
-- re-validates the claim on the server before believing it.

local ClaimSpotRequest = Event.new("StationClaimRequest")
local ReleaseSpotEvent = Event.new("StationReleaseEvent")

function self:OnTriggerEnter(other : Collider)
    local playerCharacter = other.gameObject:GetComponent(Character)
    if playerCharacter == nil then return end
    if client.localPlayer == playerCharacter.player then
        ClaimSpotRequest:FireServer(self.gameObject.name)
    end
end

function self:OnTriggerExit(other : Collider)
    local playerCharacter = other.gameObject:GetComponent(Character)
    if playerCharacter == nil then return end
    if client.localPlayer == playerCharacter.player then
        ReleaseSpotEvent:FireServer(self.gameObject.name)
    end
end

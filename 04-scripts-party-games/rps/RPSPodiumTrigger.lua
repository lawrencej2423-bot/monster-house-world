--!Type(Client)
-- RPSPodiumTrigger.lua — attach to BOTH podium objects, RPSPodium_A and
-- RPSPodium_B (DESIGN.md Zone B3), each with a Collider set as a
-- trigger. The object name IS the podium name, so one script serves
-- both. Claims are validated by RPSArena.lua on the server (distance
-- check) before anyone is shown as standing on a podium.

local ClaimPodiumReq   = Event.new("RPSClaimPodium")
local ReleasePodiumEvt = Event.new("RPSReleasePodium")

function self:OnTriggerEnter(other : Collider)
    local playerCharacter = other.gameObject:GetComponent(Character)
    if playerCharacter == nil then return end
    if client.localPlayer == playerCharacter.player then
        ClaimPodiumReq:FireServer(self.gameObject.name)
    end
end

function self:OnTriggerExit(other : Collider)
    local playerCharacter = other.gameObject:GetComponent(Character)
    if playerCharacter == nil then return end
    if client.localPlayer == playerCharacter.player then
        ReleasePodiumEvt:FireServer(self.gameObject.name)
    end
end

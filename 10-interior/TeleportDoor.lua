--!Type(ClientAndServer)
-- TeleportDoor.lua — the front-door teleport system for the Monster House
-- world. One world, two areas ("like two rooms but one"):
--
--   TeleportDoor_Yard          the house's front door, on the porch in the
--                              front yard (facade, 02-house-facade). Tap it
--                              or walk into its trigger -> the player is
--                              moved to the interior entry landing.
--   ExitDoor_Trigger           the inside face of that same door, in the
--                              interior game floor (10-interior). A fresh
--                              scene-root trigger object (the placed clone
--                              named TeleportDoor_InteriorExit is visual
--                              only — a script on the clone never fired;
--                              scene-root objects fire, proven 2026-11-23).
--                              Tap or walk in -> back outside, landing on
--                              the yard in front of the porch.
--
-- SETUP: attach ONE copy of this script to EACH door object. Each copy
-- identifies its door by its own GameObject name (same pattern as the
-- 03-scripts card stations) and ignores requests naming the other door.
-- Each door object needs:
--   * a Collider set as a trigger, sized to the volumes in DOORS below
--   * a TapHandler component (tap path)
-- The interior copy's object + placement are in interior_manifest.json;
-- the yard copy's object is placed by the facade/layout integration pass
-- at the trigger centre below (see INTERIOR.md, door linkage).
--
-- VERIFIED BASIS (SCRIPTS.md section 0 — only these are treated as fact):
--   * Client trigger pattern: self:OnTriggerEnter(other), other.gameObject
--     :GetComponent(Character), character.player, client.localPlayer
--     (docs' CoinCollector example).
--   * Tap: GetComponent(TapHandler).Tapped:Connect(fn) (Tap Handlers guide).
--   * Events: Event.new / :Connect / :FireServer — server handler receives
--     the sending player first (Client-Server Communication guide).
--   * Server-side distance validation with Vector3.Distance between
--     player.character.transform.position and a known point — the docs'
--     ScoreSystem rule: never trust the client's claim, re-check on the
--     server before doing anything.
--   * Reading player.character.transform.position (used by the distance
--     check above).
--
-- *** PLAY-TEST VERIFY — the actual MOVE (SCRIPTS.md section 6 style) ***
-- The docs checked for this project verify READING a character's position
-- (distance checks). They do NOT show an example of SETTING a character's
-- position to move/teleport a player. The move below therefore:
--   * writes player.character.transform.position = Vector3(x, y, z)
--     (Vector3.Distance is verified, so the Vector3 type exists; the
--     3-argument constructor is the standard Unity form), and
--   * is wrapped in pcall: if the write fails in Play mode, the error is
--     printed, the player simply stays where they are, and NOTHING else
--     breaks. Confirm this call in the first Play-mode test (checklist in
--     INTERIOR.md) before treating the doors as working. If the position
--     write does not move the avatar, the fix is a Studio-API research
--     item (character teleport/respawn API), NOT a redesign — the door,
--     trigger, validation and cooldown logic here stays as-is.
-- The facing write (transform.rotation via Quaternion.Euler) is a second,
-- independent pcall: if it fails, the teleport still happens, the player
-- just keeps their old facing. Quaternion was not in the checked docs —
-- same verify status as the move.
-- os.time() (cooldown clock) is standard Lua; the docs' Wallet example
-- uses os.date, so the os library is present. Low risk, noted for honesty.

local TeleportRequest = Event.new("TeleportDoorRequest")

-- Door configs, keyed by the door GameObject's EXACT name.
--   triggerCenter : centre of the door's trigger volume; the server
--                   requires the requesting avatar to be within
--                   MAX_DOOR_DISTANCE of this point.
--   destination   : where the player lands (position of the landing
--                   anchor on the other side).
--   facingYawDeg  : facing after the move (0 = north/+Z, 180 = south/-Z),
--                   applied via the optional pcall'd rotation write.
--   arriveName    : human label used in log lines.
local DOORS = {
    TeleportDoor_Yard = {
        triggerCenter = { x = 20, y = 0, z = 22.6 },
        destination   = { x = 220, y = 0, z = 3 },
        facingYawDeg  = 0,
        arriveName    = "inside the house (interior entry)",
    },
    ExitDoor_Trigger = {
        triggerCenter = { x = 220, y = 0, z = 0.9 },
        destination   = { x = 20, y = 0, z = 21.5 },
        facingYawDeg  = 180,
        arriveName    = "back outside (front yard)",
    },
}

-- How close (units) the avatar must be to the door's trigger centre for
-- the server to accept the teleport. The trigger volumes are ~1.2-1.4
-- deep; 3 covers standing anywhere in the volume plus a step, and is
-- the same scale as the docs' coin collect distance (3).
local MAX_DOOR_DISTANCE = 3

-- Per-player cooldown (seconds) after a successful teleport. Two jobs:
-- 1. Anti-bounce: the landing points are deliberately OUTSIDE the other
--    door's trigger volume (interior landing Z=3 vs exit volume ending
--    Z=1.6; yard landing Z=21.5 vs yard volume starting Z=22.0), and the
--    cooldown covers any residual trigger overlap while the player
--    settles, so nobody ping-pongs yard <-> interior.
-- 2. Spam control: one player cannot fire teleports faster than this.
local TELEPORT_COOLDOWN_SECONDS = 4

-- This copy's door config, resolved in Awake from the object name.
local myDoorName = nil
local myConfig = nil

local function ResolveDoor()
    if myConfig ~= nil then return myConfig end
    myDoorName = self.gameObject.name
    myConfig = DOORS[myDoorName]
    if myConfig == nil then
        print("[TeleportDoor] WARNING: object '" .. tostring(myDoorName)
            .. "' is not a known door name. Attach this script only to "
            .. "TeleportDoor_Yard or ExitDoor_Trigger. "
            .. "This copy will do nothing.")
    end
    return myConfig
end

-- CLIENT SIDE ------------------------------------------------------------
-- Both entry paths (walk-in trigger and tap) do the same thing: tell the
-- server "the local player used door X". The client claims nothing else —
-- no position, no destination. The server re-validates everything.

local function RequestTeleport()
    if ResolveDoor() == nil then return end
    TeleportRequest:FireServer(myDoorName)
end

function self:ClientAwake()
    if ResolveDoor() == nil then return end

    -- Tap path (Tap Handlers guide pattern).
    local tapHandler = self.gameObject:GetComponent(TapHandler)
    if tapHandler ~= nil then
        tapHandler.Tapped:Connect(function()
            RequestTeleport()
        end)
    else
        print("[TeleportDoor] WARNING: no TapHandler on '" .. myDoorName
            .. "' — tap-to-teleport is off for this door (walk-in still works).")
    end
end

-- Walk-in path (docs' CoinCollector pattern, verbatim shape).
function self:OnTriggerEnter(other)
    if ResolveDoor() == nil then return end
    local playerCharacter = other.gameObject:GetComponent(Character)
    if playerCharacter == nil then return end
    if client.localPlayer == playerCharacter.player then
        RequestTeleport()
    end
end

-- SERVER SIDE ------------------------------------------------------------
-- Authoritative: validates the request (known door, avatar exists, avatar
-- actually at that door, cooldown elapsed), then performs the move.

local lastTeleportAt = {} -- player.name -> os.time() of last teleport

function self:ServerAwake()
    if ResolveDoor() == nil then return end

    server.PlayerDisconnected:Connect(function(player)
        lastTeleportAt[player.name] = nil
    end)

    TeleportRequest:Connect(function(player, doorName)
        -- Only handle requests for THIS door (the other door's copy of
        -- this script receives the same broadcast and ignores it).
        if doorName ~= myDoorName then return end
        local config = myConfig
        if config == nil or player == nil then return end
        if player.character == nil then return end

        -- Distance validation (docs' ScoreSystem rule): the avatar must
        -- really be standing at this door, not claiming it from afar.
        local charPos = player.character.transform.position
        local dx = charPos.x - config.triggerCenter.x
        local dz = charPos.z - config.triggerCenter.z
        local dist = math.sqrt(dx * dx + dz * dz)
        if dist > MAX_DOOR_DISTANCE then
            print("[TeleportDoor] Rejected teleport for " .. player.name
                .. " at '" .. doorName .. "': avatar is " .. dist
                .. " units from the door (max " .. MAX_DOOR_DISTANCE .. ").")
            return
        end

        -- Cooldown / anti-bounce.
        local now = os.time()
        local last = lastTeleportAt[player.name]
        if last ~= nil and (now - last) < TELEPORT_COOLDOWN_SECONDS then
            return
        end

        -- THE MOVE — PLAY-TEST VERIFY (see header). pcall-wrapped: on
        -- failure the player stays put and the error is logged, nothing
        -- else breaks.
        local dest = config.destination
        local ok, err = pcall(function()
            player.character.transform.position = Vector3(dest.x, dest.y, dest.z)
        end)
        if not ok then
            print("[TeleportDoor] MOVE FAILED for " .. player.name
                .. " at '" .. doorName .. "': " .. tostring(err)
                .. " — the position-write call is unverified; see the "
                .. "PLAY-TEST VERIFY note at the top of TeleportDoor.lua.")
            return
        end

        -- Facing (optional, independent pcall — failure here never blocks
        -- or undoes the teleport).
        pcall(function()
            player.character.transform.rotation =
                Quaternion.Euler(0, config.facingYawDeg, 0)
        end)

        lastTeleportAt[player.name] = now
        print("[TeleportDoor] " .. player.name .. " used '" .. doorName
            .. "' -> " .. config.arriveName .. ".")
    end)
end

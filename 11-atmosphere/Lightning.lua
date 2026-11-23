--!Type(ClientAndServer)
-- ============================================================================
-- Lightning.lua -- storm lightning for the Monster House world (11-atmosphere)
--
-- Attach to the empty scene object named exactly "LightningController"
-- (see atmosphere_manifest.json).
--
-- WHAT IT DOES
--   Every so often (random 7-18 seconds) the storm flashes: a quick double
--   flash -- strike, short dark gap, brighter strike with a decay tail --
--   that lights up the sky behind the house and briefly lifts the whole
--   yard. Then darkness again. Under ~5% of the time is lit: this is
--   weather, not a strobe.
--
-- HOW IT STAYS IN SYNC
--   The SERVER picks each strike time and fires the verified event
--   (Event.new + :FireAllClients(...), per SCRIPTS.md section 0) carrying a
--   single number: the strike strength. Every CLIENT then renders the same
--   flash curve locally, so all players see the same flash at (nearly) the
--   same moment. Clients never decide timing.
--
-- WHAT IT DRIVES (found by exact name -- GameObject.Find is verified):
--   "LightningSkyFlash"  -- big soft white-blue panel/dome patch behind the
--                           house; its material opacity/emissive is pulsed.
--   "LightningFlashLight"-- cold light source, intensity 0 at rest, pulsed.
--   Both are defined in atmosphere_manifest.json. If either is missing, the
--   script logs a warning once and keeps running (the other still flashes).
--
-- HONESTY / PLAY-TEST REGISTER (SCRIPTS.md section 6 style)
--   VERIFIED by our docs: --!Type header, ServerStart/ClientStart
--   lifecycle, Event.new/:Connect/:FireAllClients, GameObject.Find.
--   PLAY-TEST VERIFY (docs do NOT confirm these; each is pcall-wrapped so a
--   failure logs once and degrades gracefully instead of erroring):
--     * The wait/timer mechanism (WaitForSeconds inside a coroutine). Our
--       docs confirm NO scheduler API (SCRIPTS.md section 6: automatic
--       timed resets are UNVERIFIED). If waits fail, the server loop stops
--       after logging -- the world still works, just without lightning.
--     * Setting a Light component's .intensity from Lua.
--     * Setting a material's opacity/emissive (via Renderer material color
--       alpha and/or emissive intensity -- whichever the scene object uses).
--   If Play-test shows a different timer or property API, only the small
--   helper functions at the bottom need to change.
-- ============================================================================

local LightningStrikeEvent = Event.new("LightningStrike") -- server -> all clients, arg: strength (number)

-- Tuning (mirrors atmosphere_manifest.json -> LightningController settings)
local IDLE_MIN_SECONDS = 7
local IDLE_MAX_SECONDS = 18
local STRIKE2_BOOST = 1.55 -- second flash is ~55% brighter than the first

-- ============================================================================
-- SERVER SIDE: the clock. Picks strike times, fires the event, sleeps again.
-- ============================================================================

local serverWarned = false
local function serverLogOnce(message)
    if serverWarned then return end
    serverWarned = true
    print("[Lightning] " .. message)
end

function self:ServerStart()
    -- Coroutine so the (unverified) wait can yield without blocking start-up.
    local ok, err = pcall(function()
        local co = coroutine.create(function()
            while true do
                local idle = IDLE_MIN_SECONDS + math.random() * (IDLE_MAX_SECONDS - IDLE_MIN_SECONDS)
                local waited = waitSeconds(idle) -- PLAY-TEST VERIFY helper, bottom of file
                if not waited then
                    serverLogOnce("wait mechanism unavailable -- lightning timing disabled (see PLAY-TEST notes).")
                    return
                end
                local strength = 0.8 + math.random() * 0.4 -- 0.8 .. 1.2
                LightningStrikeEvent:FireAllClients(strength)
            end
        end)
        local resumed, coErr = coroutine.resume(co)
        if not resumed then
            serverLogOnce("timing coroutine failed to start: " .. tostring(coErr))
        end
    end)
    if not ok then
        serverLogOnce("ServerStart failed: " .. tostring(err))
    end
end

-- ============================================================================
-- CLIENT SIDE: render the flash curve when the server fires a strike.
-- ============================================================================

local skyFlashObject = nil
local flashLightObject = nil
local clientWarned = false

local function clientLogOnce(message)
    if clientWarned then return end
    clientWarned = true
    print("[Lightning] " .. message)
end

-- The flash curve, as {timeSecondsFromStrikeStart, level 0..1} keyframes.
-- Double flash: strike 1, dark gap, brighter strike 2, decay tail.
local FLASH_CURVE = {
    { 0.00, 0.00 },
    { 0.06, 0.70 }, -- strike 1 rise
    { 0.10, 0.55 },
    { 0.15, 0.05 }, -- dark gap
    { 0.23, 1.00 }, -- strike 2 peak (multiplied by STRIKE2_BOOST at render)
    { 0.32, 0.75 },
    { 0.68, 0.00 }, -- decay tail end (~0.45s of visible falloff)
}

local function curveLevelAt(t)
    if t <= FLASH_CURVE[1][1] then return FLASH_CURVE[1][2] end
    for i = 2, #FLASH_CURVE do
        local t1, l1 = FLASH_CURVE[i][1], FLASH_CURVE[i][2]
        local t0, l0 = FLASH_CURVE[i - 1][1], FLASH_CURVE[i - 1][2]
        if t <= t1 then
            local span = t1 - t0
            if span <= 0 then return l1 end
            local f = (t - t0) / span
            return l0 + (l1 - l0) * f
        end
    end
    return 0
end

local function applyFlash(level)
    -- level 0..~1.55 (strike-2 boost included by caller)
    if skyFlashObject ~= nil then setObjectGlow(skyFlashObject, level) end
    if flashLightObject ~= nil then setLightLevel(flashLightObject, level) end
end

local function playStrike(strength)
    local totalTime = FLASH_CURVE[#FLASH_CURVE][1]
    local elapsed = 0
    local step = 0.03 -- ~33 fps sampling of the curve; cheap and smooth enough
    while elapsed <= totalTime do
        local level = curveLevelAt(elapsed) * strength
        if elapsed > 0.15 then level = level * STRIKE2_BOOST end -- boost applies to strike 2 + tail
        applyFlash(level)
        if not waitSeconds(step) then
            applyFlash(0) -- never leave the sky lit if the wait mechanism dies mid-flash
            clientLogOnce("wait mechanism failed mid-flash -- flash cut short (see PLAY-TEST notes).")
            return
        end
        elapsed = elapsed + step
    end
    applyFlash(0)
end

function self:ClientStart()
    local okFind, errFind = pcall(function()
        skyFlashObject = GameObject.Find("LightningSkyFlash")
        flashLightObject = GameObject.Find("LightningFlashLight")
    end)
    if not okFind then
        clientLogOnce("GameObject.Find failed: " .. tostring(errFind))
    end
    if skyFlashObject == nil then
        clientLogOnce("object 'LightningSkyFlash' not found -- sky panel will not flash (check atmosphere manifest placement).")
    end
    if flashLightObject == nil then
        clientLogOnce("object 'LightningFlashLight' not found -- flash light will not pulse (check atmosphere manifest placement).")
    end
    applyFlash(0) -- guarantee the rest state: dark sky, light off

    LightningStrikeEvent:Connect(function(strength)
        local ok, err = pcall(function()
            playStrike(tonumber(strength) or 1.0)
        end)
        if not ok then
            applyFlash(0)
            clientLogOnce("strike render failed: " .. tostring(err))
        end
    end)
end

-- ============================================================================
-- PLAY-TEST VERIFY HELPERS
-- Everything our docs do NOT confirm lives down here, each wrapped in pcall,
-- each returning true/false instead of throwing. If Play-test in Studio
-- shows the real API differs, fix ONLY these three functions.
-- ============================================================================

-- Waits `seconds` and returns true; returns false if no wait mechanism works.
-- PLAY-TEST VERIFY: no scheduler/timer API is confirmed in SCRIPTS.md.
function waitSeconds(seconds)
    local ok = pcall(function()
        if WaitForSeconds ~= nil then
            coroutine.yield(WaitForSeconds(seconds))
        elseif wait ~= nil then
            wait(seconds)
        else
            error("no wait function available")
        end
    end)
    return ok
end

-- Sets a light object's intensity as a fraction of its manifest peak.
-- PLAY-TEST VERIFY: Light component access from Lua is not doc-confirmed.
local LIGHT_PEAK = 2.2 -- matches manifest: peak ~2.2x moonlight feel
function setLightLevel(lightObject, level)
    pcall(function()
        local light = lightObject:GetComponent("Light")
        if light == nil then light = lightObject:GetComponent(Light) end
        if light ~= nil then
            light.intensity = LIGHT_PEAK * level
        end
    end)
end

-- Sets the sky flash panel's glow: material colour alpha and/or emissive.
-- PLAY-TEST VERIFY: material property access from Lua is not doc-confirmed.
function setObjectGlow(glowObject, level)
    pcall(function()
        local renderer = glowObject:GetComponent("Renderer")
        if renderer == nil then renderer = glowObject:GetComponent(MeshRenderer) end
        if renderer ~= nil and renderer.material ~= nil then
            local mat = renderer.material
            if mat.color ~= nil then
                local c = mat.color
                c.a = math.min(1, 0.85 * level)
                mat.color = c
            end
            pcall(function()
                if mat.emissiveIntensity ~= nil then
                    mat.emissiveIntensity = 1.6 * level
                end
            end)
        end
    end)
end

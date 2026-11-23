--!Type(Server)
-- ============================================================================
-- builder.lua -- WorldBuilder for the Monster House Highrise world (LJAAYY)
--
-- WHAT IT DOES
--   Reads a combined placements list (from the "Placements" Module script,
--   which the repo pipeline generates out of the section manifests:
--   01-layout/layout_manifest.json + 02-house-facade/facade_manifest.json)
--   and places every entry into the scene at its exact manifest position,
--   with its exact manifest name (DESIGN.md section 1 naming rule: bot code
--   and other scripts reference objects by these names, never rename them).
--
-- IDEMPOTENT
--   Running it twice must NOT double-place. Before placing an entry, the
--   builder looks for an object already in the scene with that exact name
--   (GameObject.Find). If one exists, the entry is SKIPPED and logged.
--   Duplicate names inside the manifest itself are also caught: only the
--   first one is placed, the rest are logged as duplicates and skipped.
--   Set CONFIG.FORCE_REBUILD = true only if you deliberately want existing
--   same-named objects destroyed and re-placed.
--
-- HOW IT PLACES
--   Each manifest entry names a template via its "asset" field. Templates
--   are ordinary scene objects kept as children of an object named
--   "BuilderTemplates" (kept inactive so they stay invisible). The builder
--   clones the template, renames the clone to the entry's exact name, moves
--   it to the entry's position/rotation/scale, parents it under
--   "BuiltWorld", and activates it. If a template is missing, the entry is
--   logged as MISSING TEMPLATE and skipped (a plain cube placeholder is
--   used only if the engine exposes CreatePrimitive -- see BUILDER.md).
--
-- HOW TO RUN IT (finisher step in Highrise Studio)
--   1. Put an empty object named "WorldBuilder" in the scene, attach this
--      script to it.
--   2. Put the combined "Placements" Module script in the project.
--   3. Stock "BuilderTemplates" with one child per asset key used by the
--      manifests.
--   4. Press Play. The build runs once on ServerStart and logs everything
--      it placed / skipped / missed, grouped by zone, plus a summary.
--   5. Read the log, then save the scene and Upload (see PUBLISH.md).
--   BuildWorld() is a global function, so it can also be re-run manually
--   from another script after fixing a template or a manifest.
--
-- API NOTES (honesty register -- same convention as SCRIPTS.md)
--   Verified in the official docs (see SCRIPTS.md section 0): script-type
--   header, self:ServerStart() lifecycle, GameObject.Find(name),
--   Vector3, require("ModuleName") for Module scripts.
--   Standard Unity-pattern calls that the checked docs did NOT explicitly
--   show, so they are wrapped in pcall and must be confirmed in the first
--   Play-mode run: GameObject.Instantiate, GameObject.Destroy,
--   GameObject.new, Transform:Find, Quaternion.Euler, SetActive,
--   GameObject.CreatePrimitive. If one of them fails, the builder logs an
--   ERROR for that entry and keeps going -- it never dies mid-build.
-- ============================================================================

local CONFIG = {
    RUN_ON_START   = true,           -- build automatically on ServerStart
    FORCE_REBUILD  = false,          -- true = destroy + re-place same names
    ROOT_NAME      = "BuiltWorld",   -- placed objects are parented under this
    TEMPLATES_NAME = "BuilderTemplates", -- scene object holding the templates
    LOG_PREFIX     = "[Builder]",
}

-- ----------------------------------------------------------------------------
-- Embedded fallback placements -- SMOKE TEST ONLY.
-- Used only when the "Placements" Module script is not in the project yet.
-- Coordinates/names copied from DESIGN.md section 3 (Zone A table) and
-- section 5 (bot stations). The real build always comes from the manifests.
-- ----------------------------------------------------------------------------
local EMBEDDED_PLACEMENTS = {
    { name = "SpawnPoint",       asset = "SpawnPoint",    x = 20,   y = 0,   z = 3,    rotation = 0,   zone = "A_Entry",       part = "layout" },
    { name = "WelcomeSign",      asset = "WelcomeSign",   x = 16.5, y = 1.6, z = 5.8,  rotation = 180, zone = "A_Entry",       part = "layout" },
    { name = "PokerTable_Main",  asset = "PokerTable",    x = 7.5,  y = 0,   z = 18,   rotation = 0,   zone = "B_CasinoFloor", part = "layout" },
    { name = "BotStation_Poker", asset = "BotStationDisc", x = 7.5, y = 0,   z = 20.2, rotation = 180, zone = "B_CasinoFloor", part = "layout" },
}

-- ----------------------------------------------------------------------------
-- Logging
-- ----------------------------------------------------------------------------
local function log(msg)
    print(CONFIG.LOG_PREFIX .. " " .. msg)
end

local function logWarn(msg)
    print(CONFIG.LOG_PREFIX .. " WARNING: " .. msg)
end

local function logError(msg)
    print(CONFIG.LOG_PREFIX .. " ERROR: " .. msg)
end

-- ----------------------------------------------------------------------------
-- Placement loading: combined list from the "Placements" Module script.
-- Accepts either a module returning { placements = { ... } } or a module
-- returning the array directly. Falls back to the embedded smoke-test list.
-- ----------------------------------------------------------------------------
local function loadPlacements()
    local ok, mod = pcall(require, "Placements")
    if ok and type(mod) == "table" then
        if type(mod.placements) == "table" then
            return mod.placements, "Placements module (.placements table)"
        end
        if mod[1] ~= nil then
            return mod, "Placements module (array)"
        end
        logWarn("Placements module loaded but holds no placements list")
    end
    return EMBEDDED_PLACEMENTS, "embedded fallback (no usable Placements module)"
end

-- ----------------------------------------------------------------------------
-- Normalization: turn one raw manifest entry into a strict internal entry,
-- or return nil + a reason. Tolerant about the exact manifest spelling:
--   position : flat x/y/z fields, or a nested position = {x=, y=, z=} table
--   rotation : a number (yaw degrees), or {x=, y=, z=}, or {yaw=},
--              or separate rotationY / yaw fields
--   asset    : "asset", or "prefab", or "template", or "model";
--              defaults to the entry's own name
--   zone     : "zone"; defaults to "Unzoned"
--   part     : "part" or "section" (which manifest/section it came from)
--   scale    : a number (uniform) or {x=, y=, z=}; absent = keep template's
--   active   : true/false; absent = activate the placed object
-- ----------------------------------------------------------------------------
local function numOr(value, fallback)
    local n = tonumber(value)
    if n == nil then
        return fallback
    end
    return n
end

local function normalizeRotation(entry)
    local r = entry.rotation
    if r == nil then
        r = entry.rotationY
    end
    if r == nil then
        r = entry.yaw
    end
    if type(r) == "number" then
        return 0, r, 0
    end
    if type(r) == "table" then
        return numOr(r.x, 0), numOr(r.y or r.yaw, 0), numOr(r.z, 0)
    end
    return 0, 0, 0
end

local function normalizeScale(entry)
    local s = entry.scale
    if type(s) == "number" then
        return { x = s, y = s, z = s }
    end
    if type(s) == "table" then
        return {
            x = numOr(s.x, 1),
            y = numOr(s.y, 1),
            z = numOr(s.z, 1),
        }
    end
    return nil
end

local function normalize(entry, index)
    if type(entry) ~= "table" then
        return nil, "entry #" .. index .. " is not a table/object"
    end

    local name = entry.name
    if type(name) ~= "string" or name == "" then
        return nil, "entry #" .. index .. " has no valid 'name'"
    end

    local pos = entry.position
    if type(pos) ~= "table" then
        pos = {}
    end
    local x = numOr(entry.x, numOr(pos.x, nil))
    local z = numOr(entry.z, numOr(pos.z, nil))
    if x == nil or z == nil then
        return nil, "'" .. name .. "' is missing a numeric x/z position"
    end
    local y = numOr(entry.y, numOr(pos.y, 0))

    local rx, ry, rz = normalizeRotation(entry)

    local asset = entry.asset or entry.prefab or entry.template or entry.model
    if type(asset) ~= "string" or asset == "" then
        asset = name
    end

    local zone = entry.zone
    if type(zone) ~= "string" or zone == "" then
        zone = "Unzoned"
    end

    local part = entry.part or entry.section
    if type(part) ~= "string" then
        part = ""
    end

    local active = entry.active
    if type(active) ~= "boolean" then
        active = nil
    end

    return {
        name = name,
        asset = asset,
        x = x,
        y = y,
        z = z,
        rx = rx,
        ry = ry,
        rz = rz,
        scale = normalizeScale(entry),
        zone = zone,
        part = part,
        active = active,
    }
end

-- ----------------------------------------------------------------------------
-- Scene helpers (engine calls wrapped so a failure logs instead of dying)
-- ----------------------------------------------------------------------------
local function isUnderTemplates(obj, templatesRoot)
    if obj == nil or templatesRoot == nil then
        return false
    end
    local t = obj.transform
    local rootTransform = templatesRoot.transform
    local guard = 0
    while t ~= nil and guard < 32 do
        if t == rootTransform then
            return true
        end
        t = t.parent
        guard = guard + 1
    end
    return false
end

local function findTemplate(assetName, templatesRoot)
    if templatesRoot ~= nil then
        local ok, child = pcall(function()
            return templatesRoot.transform:Find(assetName)
        end)
        if ok and child ~= nil then
            return child.gameObject
        end
    end
    -- Fallback: a scene object named exactly like the asset key.
    -- Convention: template names must never collide with placement names.
    return GameObject.Find(assetName)
end

local function findExisting(name, templateObj, templatesRoot, root)
    -- First look under our own root: everything this builder places lives
    -- there, and Transform:Find sees it even when a template shares the
    -- same name (GameObject.Find returns only the FIRST match in the
    -- scene, which can be the template and would hide the placed object
    -- behind it -- that is exactly the double-place bug this prevents).
    if root ~= nil then
        local ok, child = pcall(function()
            return root.transform:Find(name)
        end)
        if ok and child ~= nil then
            return child.gameObject
        end
    end
    -- Then anywhere else in the scene (e.g. an object placed by hand in
    -- Studio with a design name) -- except the template stock itself.
    local found = GameObject.Find(name)
    if found == nil then
        return nil
    end
    if templateObj ~= nil and found == templateObj then
        return nil -- the template itself is not a placed object
    end
    if isUnderTemplates(found, templatesRoot) then
        return nil -- still sitting in the template stock, not placed
    end
    return found
end

local function getOrCreateRoot()
    local root = GameObject.Find(CONFIG.ROOT_NAME)
    if root ~= nil then
        return root
    end
    local ok, created = pcall(function()
        return GameObject.new(CONFIG.ROOT_NAME)
    end)
    if ok and created ~= nil then
        return created
    end
    return nil -- parenting is cosmetic; the build continues unparented
end

local function instantiate(templateObj)
    local ok, obj = pcall(function()
        return GameObject.Instantiate(templateObj)
    end)
    if ok and obj ~= nil then
        return obj
    end
    return nil
end

local function createPrimitiveFallback(entry)
    if GameObject.CreatePrimitive == nil then
        return nil
    end
    if PrimitiveType == nil or PrimitiveType.Cube == nil then
        return nil
    end
    local ok, obj = pcall(function()
        return GameObject.CreatePrimitive(PrimitiveType.Cube)
    end)
    if ok and obj ~= nil then
        return obj
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- Place one normalized entry. Returns a status string:
--   "placed" | "skipped" | "missing" | "error"
-- ----------------------------------------------------------------------------
local function placeOne(e, ctx)
    if ctx.seen[e.name] then
        logWarn("DUPLICATE name '" .. e.name .. "' in manifest -- skipped (first one wins)")
        return "skipped"
    end
    ctx.seen[e.name] = true

    local templateObj = findTemplate(e.asset, ctx.templatesRoot)
    local existing = findExisting(e.name, templateObj, ctx.templatesRoot, ctx.root)
    if existing ~= nil then
        if CONFIG.FORCE_REBUILD then
            local okDestroy = pcall(function()
                GameObject.Destroy(existing)
            end)
            if not okDestroy then
                logError("FORCE_REBUILD: could not destroy existing '" .. e.name .. "' -- skipped")
                return "error"
            end
            log("FORCE_REBUILD: destroyed existing '" .. e.name .. "'")
        else
            log("SKIP " .. e.name .. " (already in world)")
            return "skipped"
        end
    end

    local obj = nil
    if templateObj ~= nil then
        obj = instantiate(templateObj)
        if obj == nil then
            logError("could not clone template '" .. e.asset .. "' for '" .. e.name .. "'")
            return "error"
        end
    else
        obj = createPrimitiveFallback(e)
        if obj == nil then
            logWarn("MISSING TEMPLATE '" .. e.asset .. "' for '" .. e.name .. "' -- skipped")
            return "missing"
        end
        logWarn("no template '" .. e.asset .. "' -- plain cube placeholder placed for '" .. e.name .. "'")
    end

    obj.name = e.name
    obj.transform.position = Vector3.new(e.x, e.y, e.z)
    obj.transform.rotation = Quaternion.Euler(e.rx, e.ry, e.rz)
    if e.scale ~= nil then
        obj.transform.localScale = Vector3.new(e.scale.x, e.scale.y, e.scale.z)
    end
    if ctx.root ~= nil then
        obj.transform.parent = ctx.root.transform
    end
    if e.active ~= nil then
        obj:SetActive(e.active)
    else
        obj:SetActive(true)
    end

    log("PLACED " .. e.name .. " (" .. e.asset .. ") @ (" .. tostring(e.x) .. ", "
        .. tostring(e.y) .. ", " .. tostring(e.z) .. ") rotY=" .. tostring(e.ry)
        .. (e.part ~= "" and (" [" .. e.part .. "]") or ""))
    return "placed"
end

-- ----------------------------------------------------------------------------
-- The build. Global on purpose: the finisher (or another script) can call
-- BuildWorld() again after fixing a template or a manifest.
-- Returns a totals table { placed=, skipped=, missing=, invalid=, error= }.
-- ----------------------------------------------------------------------------
function BuildWorld()
    log("=== WorldBuilder starting ===")

    local rawList, sourceName = loadPlacements()
    log("placements source: " .. sourceName .. " (" .. #rawList .. " entries)")

    -- Normalize everything first, grouped by zone, manifest order kept
    -- inside each zone, zones in first-appearance order.
    local zoneOrder = {}
    local zones = {}
    local invalidCount = 0
    for i, raw in ipairs(rawList) do
        local e, err = normalize(raw, i)
        if e == nil then
            invalidCount = invalidCount + 1
            logError("INVALID placement: " .. err)
        else
            if zones[e.zone] == nil then
                zones[e.zone] = { entries = {} }
                zoneOrder[#zoneOrder + 1] = e.zone
            end
            local group = zones[e.zone]
            group.entries[#group.entries + 1] = e
        end
    end

    local ctx = {
        seen = {},
        templatesRoot = GameObject.Find(CONFIG.TEMPLATES_NAME),
        root = getOrCreateRoot(),
    }
    if ctx.templatesRoot == nil then
        logWarn("no '" .. CONFIG.TEMPLATES_NAME .. "' object in scene -- "
            .. "templates will be looked up by name, then primitive fallback")
    end
    if ctx.root == nil then
        logWarn("could not find or create '" .. CONFIG.ROOT_NAME .. "' -- "
            .. "objects will be placed unparented (positions are unaffected)")
    end

    local totals = { placed = 0, skipped = 0, missing = 0, invalid = invalidCount, error = 0 }

    for _, zoneName in ipairs(zoneOrder) do
        local group = zones[zoneName]
        log("--- Zone: " .. zoneName .. " (" .. #group.entries .. " objects) ---")
        local counts = { placed = 0, skipped = 0, missing = 0, error = 0 }
        for _, e in ipairs(group.entries) do
            local ok, status = pcall(placeOne, e, ctx)
            if not ok then
                logError("exception placing '" .. e.name .. "': " .. tostring(status))
                status = "error"
            end
            counts[status] = counts[status] + 1
            totals[status] = totals[status] + 1
        end
        log("Zone " .. zoneName .. " done: " .. counts.placed .. " placed, "
            .. counts.skipped .. " skipped, " .. counts.missing .. " missing-template, "
            .. counts.error .. " errors")
    end

    log("=== WorldBuilder done: " .. totals.placed .. " placed, "
        .. totals.skipped .. " skipped, " .. totals.missing .. " missing-template, "
        .. totals.invalid .. " invalid, " .. totals.error .. " errors ===")
    return totals
end

-- ----------------------------------------------------------------------------
-- Lifecycle: build once when the world starts (in Studio: on Play).
-- ----------------------------------------------------------------------------
function self:ServerStart()
    if CONFIG.RUN_ON_START then
        BuildWorld()
    else
        log("RUN_ON_START is off -- call BuildWorld() manually to build")
    end
end

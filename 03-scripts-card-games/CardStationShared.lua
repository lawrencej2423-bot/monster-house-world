--!Type(Module)
-- CardStationShared.lua — shared config + helpers for the card-game
-- stations (poker + blackjack) in the Monster House front-yard world.
--
-- Other scripts use this via:  local Shared = require("CardStationShared")
-- (Module pattern follows SCRIPTS.md section 2, ScoreSystem.)
--
-- SOURCE OF TRUTH for every name/position below:
--   DESIGN.md section 3 (tables, seats, signs) and section 5 (bot anchors).
-- Anchor and object names are EXACT — bot code and builders reference them
-- character-for-character. Do not rename anything here without updating
-- DESIGN.md section 5 first.
--
-- DIVISION OF LABOUR (SCRIPTS.md section 4): the Python bots (LJAAYYBot,
-- LJAAYY2) own ALL game logic, cards, gold and payouts. This module only
-- describes the world-side furniture: where the tables are, where the bot
-- dealer stands, how many seats exist, and what the signs should say.

-- How close (in units) a player's avatar must be to a table centre before
-- the server accepts a seat request. DESIGN.md section 1 keeps a 1.5-unit
-- clear ring around every table; 4 units covers ring + table radius and
-- matches the server-side distance-check style of SCRIPTS.md section 2.
SEAT_MAX_DISTANCE = 4

-- Signage modes. Derived on the server from occupancy only — the world
-- scripts never invent game state (hands, pots, winners); that is bot data.
MODE_OPEN    = "OPEN"     -- nobody seated yet
MODE_SEATING = "SEATING"  -- some seats taken, some free
MODE_FULL    = "FULL"     -- every seat taken

-- Station configs, keyed by the table GameObject's exact name.
--   center     : table centre (DESIGN.md section 3), used for sign text /
--                builder reference; live distance checks use the actual
--                object transform, not this copy.
--   botAnchor  : exact DESIGN.md section 5 anchor the dealer bot stands at.
--   anchorPos  : that anchor's position, for builder double-checks.
--   seats      : PLAYER seats only. The dealer spot is the bot anchor and
--                is never handed out as a seat.
--   signName   : hanging sign object for this station, or nil if the
--                station has no hanging sign (PvP table has a sign post).
CardStations = {
    PokerTable_Main = {
        game = "poker",
        displayName = "Poker",
        seats = 8,
        center = { x = 7.5, y = 0, z = 18 },
        botName = "LJAAYY2",
        botAnchor = "BotStation_Poker",
        anchorPos = { x = 7.5, y = 0, z = 20.2 },
        signName = "PokerSign",
        signText = "POKER",
        playCommand = "!poker",
    },
    PokerTable_Overflow = {
        game = "poker",
        displayName = "Poker (Overflow)",
        seats = 8,
        center = { x = 7.5, y = 0, z = 11 },
        botName = "LJAAYY2",
        botAnchor = "BotStation_Poker",
        anchorPos = { x = 7.5, y = 0, z = 20.2 },
        signName = "PokerSign", -- shares the main table's hanging sign
        signText = "POKER",
        playCommand = "!poker",
    },
    BlackjackTable_Main = {
        game = "blackjack",
        displayName = "Blackjack",
        seats = 7,
        center = { x = 19, y = 0, z = 18 },
        botName = "LJAAYYBot",
        botAnchor = "BotStation_Blackjack",
        anchorPos = { x = 19, y = 0, z = 19.8 },
        signName = "BlackjackSign",
        signText = "BLACKJACK",
        playCommand = "!blackjack",
    },
    PvPBlackjackTable = {
        game = "blackjack",
        displayName = "PvP Blackjack",
        seats = 7,
        center = { x = 19, y = 0, z = 11 },
        botName = "LJAAYYBot",
        botAnchor = "BotStation_Blackjack",
        anchorPos = { x = 19, y = 0, z = 19.8 },
        signName = nil, -- DESIGN.md: a "PvP" sign post beside the table
        signText = "PvP",
        playCommand = "!blackjack",
    },
}

-- Look up a station config by the table object's exact name.
-- Returns nil for unknown names (callers print a builder warning).
CardStations_GetConfig = function(stationName)
    if type(stationName) ~= "string" then return nil end
    return CardStations[stationName]
end

-- Derive the signage mode from occupancy. Pure function — no game state.
CardStations_DeriveMode = function(seatedCount, seatCount)
    if seatedCount <= 0 then
        return MODE_OPEN
    elseif seatedCount >= seatCount then
        return MODE_FULL
    else
        return MODE_SEATING
    end
end

-- The one line a station's sign shows under its big game name, e.g.
-- "POKER · SEATING · 3/8 seats · dealer: LJAAYY2"
CardStations_FormatSignLine = function(config, mode, seatedCount)
    return config.signText .. " · " .. mode .. " · "
        .. seatedCount .. "/" .. config.seats .. " seats"
        .. " · dealer: " .. config.botName
end

-- The prompt a player sees when they walk into a table's ring, e.g.
-- "Blackjack — tap the table to take a seat. LJAAYYBot deals here
--  (BotStation_Blackjack). Play in chat: !blackjack"
CardStations_FormatPrompt = function(config)
    return config.displayName .. " — tap the table to take a seat. "
        .. config.botName .. " deals here (" .. config.botAnchor .. "). "
        .. "Play in chat: " .. config.playCommand
end

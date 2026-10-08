-- LizzaricksUnitFrames / Core / Tags
--
-- Luna-style text tags: "[name] [smarthealth]" on a font string.
--
-- Secret-safe by construction: a tag returns a FORMAT PIECE (a plain string
-- we build ourselves) plus the VALUES for it, which may be secret. A tag line
-- is rendered with one FontString:SetFormattedText(format, values...) call,
-- which the client allows with secret arguments. No tag ever compares or
-- computes with a value it may not read.
local _, ns = ...

local Tags = {}
ns.Tags = Tags

local EMPTY = ""
local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana or 0

local function readable(v)
    return ns.CanRead(v)
end

-- Status text for dead/ghost/offline units; nil when the unit is alive.
local function statusText(u)
    local connected = UnitIsConnected(u)
    if readable(connected) and not connected then return PLAYER_OFFLINE or "Offline" end
    local ghost = UnitIsGhost(u)
    if readable(ghost) and ghost then return "Ghost" end
    local dead = UnitIsDead(u)
    if readable(dead) and dead then return DEAD or "Dead" end
end

local SHORT_CLASSIFICATION = { elite = "+", rare = "R", rareelite = "R+", worldboss = "B" }
local LONG_CLASSIFICATION = {
    elite = ELITE or "Elite",
    rare = "Rare",
    rareelite = "Rare Elite",
    worldboss = BOSS or "Boss",
}

local function classification(u)
    local c = UnitClassification(u)
    if readable(c) then return c end
end

local function percent(fn, u)
    if not ns.ScaleTo100 then return EMPTY end
    return "%.0f%%", fn(u, true, ns.ScaleTo100)
end

local function full(v)
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(v) end
    return AbbreviateNumbers(v)
end

local function short(v)
    return AbbreviateNumbers(v)
end

-- health/max (and percent), or the status text for dead and offline units
local function smartHealth(u, fmt, withPercent)
    local s = statusText(u)
    if s then return lit(s) end
    if withPercent and ns.ScaleTo100 then
        return "%s/%s %.0f%%", fmt(UnitHealth(u)), fmt(UnitHealthMax(u)), UnitHealthPercent(u, true, ns.ScaleTo100)
    end
    return "%s/%s", fmt(UnitHealth(u)), fmt(UnitHealthMax(u))
end

-- ---------------------------------------------------------- the tags --
--
-- Each entry: function(unit) -> formatPiece, values...
-- A tag without values returns only its literal piece (with % escaped).

local function lit(s)
    return (s:gsub("%%", "%%%%"))
end

Tags.methods = {
    -- identity
    name = function(u)
        local n = UnitName(u)
        if readable(n) and not n then return EMPTY end
        return "%s", n
    end,
    level = function(u)
        local l = UnitLevel(u)
        if not readable(l) then return "%s", l end
        if l <= 0 then return "??" end
        return "%d", l
    end,
    classification = function(u)
        return lit(LONG_CLASSIFICATION[classification(u) or ""] or EMPTY)
    end,
    shortclassification = function(u)
        return lit(SHORT_CLASSIFICATION[classification(u) or ""] or EMPTY)
    end,
    class = function(u)
        local name = UnitClass(u)
        if readable(name) and not name then return EMPTY end
        return "%s", name
    end,
    creature = function(u)
        local t = UnitCreatureType(u)
        if readable(t) and not t then return EMPTY end
        return "%s", t
    end,
    smartclass = function(u)
        local isPlayer = UnitIsPlayer(u)
        if readable(isPlayer) and isPlayer then return Tags.methods.class(u) end
        return Tags.methods.creature(u)
    end,

    -- colours: they only open a colour, [nocolor] closes it
    classcolor = function(u)
        local c = ns.ClassColor(u)
        return c and ns.Hex(c) or "|cffffffff"
    end,
    reactcolor = function(u)
        local c = ns.ReactionColor(u)
        return c and ns.Hex(c) or "|cffffffff"
    end,
    levelcolor = function(u)
        local l = UnitLevel(u)
        if not readable(l) then return EMPTY end
        if l <= 0 then return "|cffff0000" end
        if GetCreatureDifficultyColor then
            local c = GetCreatureDifficultyColor(l)
            return ns.Hex({ c.r, c.g, c.b })
        end
        return EMPTY
    end,
    nocolor = function() return "|r" end,

    -- health
    -- Full numbers with thousands separators, as in Luna; the s-variants
    -- are short (1.2K). Both formatters take secrets.
    hp = function(u) return "%s", full(UnitHealth(u)) end,
    maxhp = function(u) return "%s", full(UnitHealthMax(u)) end,
    shp = function(u) return "%s", short(UnitHealth(u)) end,
    smaxhp = function(u) return "%s", short(UnitHealthMax(u)) end,
    missinghp = function(u) return "%s", full(UnitHealthMissing(u, true)) end,
    perhp = function(u) return percent(UnitHealthPercent, u) end,
    status = function(u) return lit(statusText(u) or EMPTY) end,
    smarthealth = function(u) return smartHealth(u, full, false) end,
    smarthealthp = function(u) return smartHealth(u, full, true) end,
    ssmarthealth = function(u) return smartHealth(u, short, false) end,
    ssmarthealthp = function(u) return smartHealth(u, short, true) end,

    -- power
    pp = function(u) return "%s", full(UnitPower(u)) end,
    maxpp = function(u) return "%s", full(UnitPowerMax(u)) end,
    spp = function(u) return "%s", short(UnitPower(u)) end,
    smaxpp = function(u) return "%s", short(UnitPowerMax(u)) end,
    missingpp = function(u) return "%s", full(UnitPowerMissing(u)) end,
    -- mana whatever the shown power is (druids in forms)
    mana = function(u) return "%s", full(UnitPower(u, MANA)) end,
    maxmana = function(u) return "%s", full(UnitPowerMax(u, MANA)) end,
    perpp = function(u)
        if not ns.ScaleTo100 then return EMPTY end
        return "%.0f%%", UnitPowerPercent(u, nil, false, ns.ScaleTo100)
    end,

    -- state
    afk = function(u)
        local afk = UnitIsAFK(u)
        if readable(afk) and afk then return "(AFK)" end
        return EMPTY
    end,
    nameafk = function(u)
        local afk = UnitIsAFK(u)
        if readable(afk) and afk then return "(AFK)" end
        return Tags.methods.name(u)
    end,
    combat = function(u)
        local c = UnitAffectingCombat(u)
        if readable(c) and c then return "(Combat)" end
        return EMPTY
    end,
    -- the player only: inns and capitals (IsResting is plain, not secret)
    resting = function(u)
        if u ~= "player" then
            local ok, same = pcall(UnitIsUnit, u, "player")
            if not (ok and readable(same) and same) then return EMPTY end
        end
        if IsResting and IsResting() then return "(Resting)" end
        return EMPTY
    end,
    smartlevel = function(u)
        local c = classification(u)
        if c == "worldboss" then return "Boss" end
        local l = UnitLevel(u)
        if not readable(l) then return "%s", l end
        if l <= 0 then return "??" end
        if c == "elite" or c == "rareelite" then return "%d+", l end
        return "%d", l
    end,
    guild = function(u)
        local g = GetGuildInfo(u)
        if readable(g) and not g then return EMPTY end
        return "%s", g
    end,
    -- red in combat, green while resting (player), nothing otherwise
    statuscolor = function(u)
        local c = UnitAffectingCombat(u)
        if (readable(c) and c) or (u == "player" and (InCombatLockdown() or ns.inCombat)) then
            return "|cffff2020"
        end
        if u == "player" and IsResting and IsResting() then return "|cff33dd33" end
        return EMPTY
    end,
    combatcolor = function(u)
        local c = UnitAffectingCombat(u)
        if readable(c) and c then return "|cffff0000" end
        return EMPTY
    end,

    -- pet (player's hunter pet only)
    happiness = function(u)
        local h = ns.PetHappiness(u)
        if not h then return EMPTY end
        local names = { "Unhappy", "Content", "Happy" }
        return ns.Hex(ns.colors.happiness[h]) .. names[h] .. "|r"
    end,
    loyalty = function(u)
        if u ~= "pet" or not (C_PetInfo and C_PetInfo.GetPetLoyalty) then return EMPTY end
        local ok, name = pcall(C_PetInfo.GetPetLoyalty)
        if not ok or not ns.CanRead(name) or not name then return EMPTY end
        return "%s", name
    end,

    -- experience of the player (the frame's unit does not matter)
    xp = function()
        local cur, max = UnitXP("player"), UnitXPMax("player")
        return "%s/%s", AbbreviateNumbers(cur), AbbreviateNumbers(max)
    end,
    xppet = function()
        if not GetPetExperience then return EMPTY end
        local cur, max = GetPetExperience()
        if not (readable(cur) and readable(max)) or not max or max == 0 then return EMPTY end
        return "%s/%s", full(cur), full(max)
    end,
    percxppet = function()
        if not GetPetExperience then return EMPTY end
        local cur, max = GetPetExperience()
        if not (readable(cur) and readable(max)) or not max or max == 0 then return EMPTY end
        return "%.0f%%", cur / max * 100
    end,
    percxp = function()
        local cur, max = UnitXP("player"), UnitXPMax("player")
        if not (readable(cur) and readable(max)) or max == 0 then return EMPTY end
        return "%.0f%%", cur / max * 100
    end,
}

-- Tags with an argument after a colon: [shortname:5], [color:ff8000].
Tags.argMethods = {
    shortname = function(arg)
        local n = tonumber(arg) or 12
        return function(u)
            local name = UnitName(u)
            if not readable(name) then return "%s", name end
            if not name then return EMPTY end
            return "%s", name:sub(1, n)
        end
    end,
    color = function(arg)
        local hex = arg:match("^%x%x%x%x%x%x$")
        return function() return hex and ("|cff" .. hex) or EMPTY end
    end,
}

-- For the tag help in the options window.
Tags.help = {
    { "name", "Name" },
    { "shortname:x", "First x letters of the name" },
    { "nameafk", "Name, or (AFK)" },
    { "afk", "(AFK) when away" },
    { "level", "Level (?? for bosses)" },
    { "smartlevel", "Level with + for elites, Boss for bosses" },
    { "class", "Class" },
    { "smartclass", "Class for players, creature type for NPCs" },
    { "creature", "Creature type" },
    { "classification", "Elite / Rare / Rare Elite / Boss" },
    { "shortclassification", "+ / R / R+ / B" },
    { "guild", "Guild name" },
    { "status", "Dead / Ghost / Offline" },
    { "combat", "(Combat) while in combat" },
    { "resting", "(Resting) in an inn or a capital (player only)" },
    { "hp", "Current health (1,234)" },
    { "maxhp", "Maximum health" },
    { "shp", "Current health, short (1.2K)" },
    { "smaxhp", "Maximum health, short" },
    { "missinghp", "Missing health" },
    { "perhp", "Health in percent" },
    { "smarthealth", "Health/max, or Dead/Offline" },
    { "smarthealthp", "Health/max and percent" },
    { "ssmarthealth", "Like smarthealth, short numbers" },
    { "ssmarthealthp", "Like smarthealthp, short numbers" },
    { "pp", "Current power" },
    { "maxpp", "Maximum power" },
    { "spp", "Current power, short" },
    { "smaxpp", "Maximum power, short" },
    { "missingpp", "Missing power" },
    { "mana", "Current mana, also in a druid form" },
    { "maxmana", "Maximum mana, also in a druid form" },
    { "perpp", "Power in percent" },
    { "happiness", "Pet happiness (Happy / Content / Unhappy, coloured)" },
    { "loyalty", "Pet loyalty level" },
    { "xp", "Experience/needed (player)" },
    { "percxp", "Experience in percent (player)" },
    { "xppet", "Pet experience/needed" },
    { "percxppet", "Pet experience in percent" },
    { "classcolor", "Starts the class colour" },
    { "reactcolor", "Starts the reaction colour" },
    { "levelcolor", "Starts the level difficulty colour" },
    { "combatcolor", "Starts red while in combat" },
    { "statuscolor", "Starts red in combat, green while resting (player)" },
    { "color:rrggbb", "Starts your own colour, e.g. [color:ff8000]" },
    { "nocolor", "Ends a colour" },
}

-- ------------------------------------------------------------ compile --

-- "[a] text [b]" -> { "a", " text ", "b" } with tags marked as { tag = fn }.
local cache = {}

function Tags.Compile(line)
    if cache[line] then return cache[line] end
    local parts = {}
    local pos = 1
    while pos <= #line do
        local s, e, tag = line:find("%[([%w:]+)%]", pos)
        if not s then
            table.insert(parts, lit(line:sub(pos)))
            break
        end
        if s > pos then table.insert(parts, lit(line:sub(pos, s - 1))) end
        local fn = Tags.methods[tag]
        if not fn then
            local base, arg = tag:match("^(%w+):(.+)$")
            if base and Tags.argMethods[base] then fn = Tags.argMethods[base](arg) end
        end
        if fn then
            table.insert(parts, { fn = fn })
        else
            table.insert(parts, lit(line:sub(s, e))) -- unknown tag stays visible
        end
        pos = e + 1
    end
    cache[line] = parts
    return parts
end

-- Tags whose value follows the power (the fast power ticker redraws only
-- texts that use one of them).
local POWER_TAGS = { pp = true, maxpp = true, spp = true, smaxpp = true, missingpp = true,
    mana = true, maxmana = true, perpp = true }
local usesPower = {}

function Tags.UsesPower(line)
    local v = usesPower[line]
    if v == nil then
        v = false
        for tag in line:gmatch("%[([%w:]+)%]") do
            if POWER_TAGS[tag] then v = true break end
        end
        usesPower[line] = v
    end
    return v
end

-- ------------------------------------------------------------- render --

local fmtBuf, args = {}, {}

-- Takes pcall's results for one tag: stores its values after position n
-- and returns the new count and the tag's format piece. The piece is always
-- our own plain string, so testing it is safe; the values are never tested.
local function append(n, ok, piece, ...)
    if not ok then
        if ns.LogError then ns.LogError("tag", piece) end
        return n, EMPTY
    end
    if not piece then return n, EMPTY end
    local count = select("#", ...)
    for i = 1, count do
        args[n + i] = (select(i, ...))
    end
    return n + count, piece
end

function Tags.Render(fs, line, unit)
    local parts = Tags.Compile(line)
    local n = 0
    for i = 1, #parts do
        local p = parts[i]
        if type(p) == "string" then
            fmtBuf[i] = p
        else
            n, fmtBuf[i] = append(n, pcall(p.fn, unit))
        end
    end
    local fmt = table.concat(fmtBuf, "", 1, #parts)
    fs:SetFormattedText(fmt, unpack(args, 1, n))
    for i = 1, n do args[i] = nil end
end

function Tags.List()
    local list = {}
    for k in pairs(Tags.methods) do table.insert(list, k) end
    table.sort(list)
    return list
end

-- FUF / Core / Tags
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
    hp = function(u) return "%s", AbbreviateNumbers(UnitHealth(u)) end,
    maxhp = function(u) return "%s", AbbreviateNumbers(UnitHealthMax(u)) end,
    missinghp = function(u) return "%s", AbbreviateNumbers(UnitHealthMissing(u, true)) end,
    perhp = function(u) return percent(UnitHealthPercent, u) end,
    status = function(u) return lit(statusText(u) or EMPTY) end,
    smarthealth = function(u)
        local s = statusText(u)
        if s then return lit(s) end
        return "%s/%s", AbbreviateNumbers(UnitHealth(u)), AbbreviateNumbers(UnitHealthMax(u))
    end,
    smarthealthp = function(u)
        local s = statusText(u)
        if s then return lit(s) end
        if not ns.ScaleTo100 then return Tags.methods.smarthealth(u) end
        return "%s/%s %.0f%%", AbbreviateNumbers(UnitHealth(u)), AbbreviateNumbers(UnitHealthMax(u)),
            UnitHealthPercent(u, true, ns.ScaleTo100)
    end,

    -- power
    pp = function(u) return "%s", AbbreviateNumbers(UnitPower(u)) end,
    maxpp = function(u) return "%s", AbbreviateNumbers(UnitPowerMax(u)) end,
    missingpp = function(u) return "%s", AbbreviateNumbers(UnitPowerMissing(u)) end,
    perpp = function(u)
        if not ns.ScaleTo100 then return EMPTY end
        return "%.0f%%", UnitPowerPercent(u, nil, false, ns.ScaleTo100)
    end,
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

-- ------------------------------------------------------------- render --

local fmtBuf, args = {}, {}

-- Takes pcall's results for one tag: stores its values after position n
-- and returns the new count and the tag's format piece. The piece is always
-- our own plain string, so testing it is safe; the values are never tested.
local function append(n, ok, piece, ...)
    if not ok or not piece then return n, EMPTY end
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

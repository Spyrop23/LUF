-- LizzaricksUnitFrames / Frames / Range
--
-- Out-of-range fading for group members and pets (Luna: alpha 0.4).
--
-- UnitInRange returns SECRET booleans in Forever. We never test them:
-- Frame:SetAlphaFromBoolean lets the client pick the alpha from the secret.
-- Only where the answer is readable (and "not checked", e.g. the player
-- itself) do we decide in Lua.
local _, ns = ...

local RG = {}
ns.Range = RG

-- Settings keys that fade. UnitInRange answers for group members (and their
-- pets); for the player's own pet it reports "out of range" even next to
-- you, as a secret we cannot catch, so the pet frame never fades.
-- Targets (yours, your party's and raid's, focus) can be anyone, also enemies:
-- they are measured with one of your own spells (C_Spell.IsSpellInRange) or
-- the follow distance (CheckInteractDistance, about 28 yards); range.measure
-- picks: "auto" (spell, else 28 yards), "spell" or "28".
RG.supported = { party = true, partypet = true, raid = true, raidpet = true,
    target = true, targettarget = true, focus = true, focustarget = true, partytarget = true, raidtarget = true }
local BY_SPELL = { target = true, targettarget = true, focus = true, focustarget = true, partytarget = true,
    raidtarget = true }
RG.BY_SPELL = BY_SPELL

-- Rank 1 spell IDs with about 30-40 yards range, per class: one list for
-- enemies (harm), one for friends (help). Every one you know is asked (by
-- name, so the highest rank counts), in this order: a spell the client
-- cannot check right now (e.g. Charge outside Battle Stance) answers
-- nothing, so the next one (Intercept) speaks.
-- A spell with a minimum range (Charge 8-25, Auto Shot 8-35) says "out of
-- range" up close, so a melee spell (near) counts as well: in range is
-- "the spell reaches or melee does". Only the few yards between melee and
-- the minimum range fade (there neither one can be used).
local SPELLS = {
    harm = {
        MAGE = { 133, 116 }, PRIEST = { 585, 589 }, WARLOCK = { 686, 348 }, DRUID = { 5176 },
        SHAMAN = { 403 }, PALADIN = { 24275 }, WARRIOR = { 100, 20252 }, HUNTER = { 75 },
    },
    -- Heroic Strike, Pummel, Slam / Raptor Strike (Forever, Retail)
    near = { WARRIOR = { 78, 6552, 1464 }, HUNTER = { 2973, 186270 } },
    help = {
        MAGE = { 1459 }, PRIEST = { 2050, 1243 }, WARLOCK = { 5697 }, DRUID = { 5185, 1126 },
        SHAMAN = { 331 }, PALADIN = { 635, 19740 },
    },
}

-- The spells of a list you know, by name; nil when none.
local spellCache = {}
local function rangeSpells(kind)
    local cached = spellCache[kind]
    if cached ~= nil then return cached or nil end
    local _, class = UnitClass("player")
    local found = {}
    for _, id in ipairs(ns.CanRead(class) and SPELLS[kind][class] or {}) do
        local known = IsPlayerSpell and IsPlayerSpell(id)
        if known or (IsSpellKnown and IsSpellKnown(id)) then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
            table.insert(found, (info and info.name) or (GetSpellInfo and GetSpellInfo(id)) or id)
        end
    end
    spellCache[kind] = #found > 0 and found or false
    return spellCache[kind] or nil
end
-- new spells, new ranks
ns:RegisterEvent("SPELLS_CHANGED", function() spellCache = {} end)
ns:RegisterEvent("LEARNED_SPELL_IN_TAB", function() spellCache = {} end)

-- CheckInteractDistance (index: 2 trade, about 8-11 yards; 4 follow, about
-- 28 yards), or nil when unknown. Out of combat only: in combat the client
-- answers "too far" for everyone, friends next to you too.
local TRADE, FOLLOW = 2, 4
local function interactRange(unit, hostile, index)
    if not CheckInteractDistance then return nil end
    if InCombatLockdown() then return nil end
    local ok, inRange = pcall(CheckInteractDistance, unit, index)
    if ok and ns.CanRead(inRange) then return inRange end
    return nil
end

local function isIn(spell, unit)
    local ok, inRange = pcall(C_Spell.IsSpellInRange, spell, unit)
    if ok then return inRange end
end

-- Any of the spells in range: true / false / secret, nil when none can tell.
local function anyIn(spells, unit)
    local sawFalse = false
    for _, spell in ipairs(spells) do
        local inRange = isIn(spell, unit)
        if type(inRange) ~= "nil" then
            if not ns.CanRead(inRange) then return inRange end
            if inRange then return true end
            sawFalse = true
        end
    end
    if sawFalse then return false end
    return nil
end

-- Group members also answer in combat: UnitInRange (secret, about 40 yards).
local function groupRange(unit)
    local okP, party = pcall(UnitInParty, unit)
    local okR, raid = pcall(UnitInRaid, unit)
    local member = (okP and ns.CanRead(party) and party) or (okR and ns.CanRead(raid) and raid)
    if not member then return nil end
    local ok, inRange = pcall(UnitInRange, unit)
    if ok then return inRange end
end

-- A spell with a minimum range (Charge) plus melee: in range when either
-- reaches. Between the two (about 5-8 yards) neither does, yet the unit is
-- close: out of combat the trade distance tells; in combat the frame
-- remembers that the unit was in melee last (walking out of melee passes
-- that gap before Charge range starts). f.rangeZone: "melee" / "far".
local function nearOrFar(f, unit, hostile, spells, near)
    local inMelee = anyIn(near, unit)
    if ns.CanRead(inMelee) and inMelee then f.rangeZone = "melee" return true end
    local inSpell = anyIn(spells, unit)
    if ns.CanRead(inSpell) and inSpell then f.rangeZone = "far" return true end
    local close = interactRange(unit, hostile, TRADE)
    if close ~= nil then
        f.rangeZone = close and "melee" or nil
        return close
    end
    if f.rangeZone == "melee" then return true end
    if type(inSpell) == "nil" and type(inMelee) == "nil" then return nil end
    return false
end

-- In range of one of your spells (true/false/secret), or nil when no spell fits.
local function spellRange(f, unit, hostile)
    if not (C_Spell and C_Spell.IsSpellInRange) then return nil end
    local kinds
    if hostile ~= nil then kinds = { hostile and "harm" or "help" } else kinds = { "harm", "help" } end
    for _, kind in ipairs(kinds) do
        local spells = rangeSpells(kind)
        local near = spells and kind == "harm" and rangeSpells("near")
        if near then
            local inRange = nearOrFar(f, unit, hostile, spells, near)
            if type(inRange) ~= "nil" then return inRange end
        elseif spells then
            local inRange = anyIn(spells, unit)
            if type(inRange) ~= "nil" then return inRange end
        end
    end
    return nil
end

local function targetRange(f, unit, measure)
    local ok, canAttack = pcall(UnitCanAttack, "player", unit)
    local hostile   -- nil: unknown (secret)
    if ok and ns.CanRead(canAttack) then hostile = canAttack and true or false end
    if measure ~= "28" then
        local inRange = spellRange(f, unit, hostile)
        if type(inRange) ~= "nil" or measure == "spell" then return inRange end
    end
    if InCombatLockdown() then
        -- no follow distance in combat: group members still answer
        -- (no "x and y or z": the answer may be false, or a secret)
        if hostile == false then return groupRange(unit) end
        return nil
    end
    return interactRange(unit, hostile, FOLLOW)
end

-- A new unit behind a frame: forget where the last one stood.
local function forgetZones()
    if not ns.UF then return end
    for key in pairs(BY_SPELL) do
        for _, f in ipairs(ns.UF.byKey[key] or {}) do f.rangeZone = nil end
    end
end
for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UNIT_TARGET" }) do
    ns:RegisterEvent(event, forgetZones)
end

local POLL_EVERY = 0.25

local function isPlayer(unit)
    if unit == "player" then return true end
    local ok, same = pcall(UnitIsUnit, unit, "player")
    return ok and ns.CanRead(same) and same or false
end

function RG.Update(f)
    local db = f.db.range
    if not (RG.supported[f.key] and db and db.enabled) or ns.unlocked then
        f:SetAlpha(1)
        return
    end
    local unit = f.unit
    if isPlayer(unit) or not UnitExists(unit) then
        f:SetAlpha(1)
        return
    end
    local inRange, checked
    if BY_SPELL[f.key] then
        -- not UnitInRange: it says "out of range" for anyone outside the group
        inRange = targetRange(f, unit, db.measure or "auto")
    else
        inRange, checked = UnitInRange(unit)
    end
    -- a readable "not checked" means: no range information, stay opaque
    if ns.CanRead(checked) and checked == false then
        f:SetAlpha(1)
        return
    end
    if type(inRange) == "nil" then
        f:SetAlpha(1)
        return
    end
    if ns.CanRead(inRange) then
        f:SetAlpha(inRange and 1 or db.alpha)
    elseif f.SetAlphaFromBoolean then
        f:SetAlphaFromBoolean(inRange, 1, db.alpha)
    end
end

-- One shared poll for all fading frames; plus the client's range event.
local ticker = CreateFrame("Frame")
local wait = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    wait = wait + elapsed
    if wait < POLL_EVERY then return end
    wait = 0
    if not ns.UF then return end
    for key in pairs(RG.supported) do
        for _, f in ipairs(ns.UF.byKey[key] or {}) do
            if f:IsVisible() then RG.Update(f) end
        end
    end
end)

ns:RegisterEvent("UNIT_IN_RANGE_UPDATE", function(_, unit)
    local f = ns.UF and unit and ns.UF.frames[unit]
    if f and f:IsVisible() then RG.Update(f) end
end)

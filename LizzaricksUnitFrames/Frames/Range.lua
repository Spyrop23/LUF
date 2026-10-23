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
-- enemies (harm), one for friends (help). The first one you know is used
-- (by name, so the highest rank counts). No spells with a minimum range
-- (Throw, Shoot, Auto Shot, Charge): they report "out of range" up close.
local SPELLS = {
    harm = {
        MAGE = { 133, 116 }, PRIEST = { 585, 589 }, WARLOCK = { 686, 348 }, DRUID = { 5176 },
        SHAMAN = { 403 }, PALADIN = { 24275 },
    },
    help = {
        MAGE = { 1459 }, PRIEST = { 2050, 1243 }, WARLOCK = { 5697 }, DRUID = { 5185, 1126 },
        SHAMAN = { 331 }, PALADIN = { 635, 19740 },
    },
}

local spellCache = {}
local function rangeSpell(kind)
    local cached = spellCache[kind]
    if cached ~= nil then return cached or nil end
    local _, class = UnitClass("player")
    local found = false
    for _, id in ipairs(ns.CanRead(class) and SPELLS[kind][class] or {}) do
        local known = IsPlayerSpell and IsPlayerSpell(id)
        if known or (IsSpellKnown and IsSpellKnown(id)) then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
            found = (info and info.name) or (GetSpellInfo and GetSpellInfo(id)) or id
            break
        end
    end
    spellCache[kind] = found
    return found or nil
end
-- new spells, new ranks
ns:RegisterEvent("SPELLS_CHANGED", function() spellCache = {} end)
ns:RegisterEvent("LEARNED_SPELL_IN_TAB", function() spellCache = {} end)

-- In range of one of your spells (true/false/secret), or nil when no spell fits.
local function spellRange(unit)
    if not (C_Spell and C_Spell.IsSpellInRange) then return nil end
    local ok, hostile = pcall(UnitCanAttack, "player", unit)
    local kinds
    if ok and ns.CanRead(hostile) then kinds = { hostile and "harm" or "help" } else kinds = { "harm", "help" } end
    for _, kind in ipairs(kinds) do
        local spell = rangeSpell(kind)
        if spell then
            local okR, inRange = pcall(C_Spell.IsSpellInRange, spell, unit)
            if okR and type(inRange) ~= "nil" then return inRange end
        end
    end
    return nil
end

-- Within follow distance (about 28 yards), or nil when unknown. In combat
-- the client allows it on friends only, so enemies are not asked then.
local FOLLOW = 4
local function followRange(unit, hostile)
    if not CheckInteractDistance then return nil end
    if InCombatLockdown() and hostile ~= false then return nil end
    local ok, inRange = pcall(CheckInteractDistance, unit, FOLLOW)
    if ok then return inRange end
    return nil
end

local function targetRange(unit, measure)
    local ok, canAttack = pcall(UnitCanAttack, "player", unit)
    local hostile   -- nil: unknown (secret)
    if ok and ns.CanRead(canAttack) then hostile = canAttack and true or false end
    if measure ~= "28" then
        local inRange = spellRange(unit)
        if type(inRange) ~= "nil" or measure == "spell" then return inRange end
    end
    return followRange(unit, hostile)
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
        inRange = targetRange(unit, db.measure or "auto")
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

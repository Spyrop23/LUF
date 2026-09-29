-- FUF / Core / Media
--
-- Textures, fonts and the colour tables (values as in Luna Unit Frames).
local _, ns = ...

ns.media = {
    font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    background = "Interface\\Buttons\\WHITE8X8",
}

-- Bar textures. The first fifteen ship with FUF (smooth 8-bit gradients, no
-- banding at any bar height); the others come with the client (paths
-- checked in the 1.60.1 UI source). Blizzard's UI-StatusBar is made for
-- thin bars and shows bands when stretched.
local MEDIA = "Interface\\AddOns\\FUF\\Media\\"
ns.textures = {
    { "Smooth", MEDIA .. "Smooth" },
    { "Soft", MEDIA .. "Soft" },
    { "Dark", MEDIA .. "Dark" },
    { "Charcoal", MEDIA .. "Charcoal" },
    { "Matte", MEDIA .. "Matte" },
    { "Minimalist", MEDIA .. "Minimalist" },
    { "Gloss", MEDIA .. "Gloss" },
    { "Glass", MEDIA .. "Glass" },
    { "Split", MEDIA .. "Split" },
    { "Tube", MEDIA .. "Tube" },
    { "Inset", MEDIA .. "Inset" },
    { "Bevel", MEDIA .. "Bevel" },
    { "Lines", MEDIA .. "Lines" },
    { "Grain", MEDIA .. "Grain" },
    { "Brushed", MEDIA .. "Brushed" },
    { "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar" },
    { "Raid", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
    { "Flat", "Interface\\Buttons\\WHITE8X8" },
}

function ns.Texture()
    local want = ns.db and ns.db.texture
    for _, t in ipairs(ns.textures) do
        if t[1] == want then return t[2] end
    end
    return ns.textures[1][2]
end

ns.colors = {
    class = {
        HUNTER  = { 0.67, 0.83, 0.45 },
        WARLOCK = { 0.58, 0.51, 0.79 },
        PRIEST  = { 1.00, 1.00, 1.00 },
        PALADIN = { 0.96, 0.55, 0.73 },
        MAGE    = { 0.41, 0.80, 0.94 },
        ROGUE   = { 1.00, 0.96, 0.41 },
        DRUID   = { 1.00, 0.49, 0.04 },
        SHAMAN  = { 0.14, 0.35, 1.00 },
        WARRIOR = { 0.78, 0.61, 0.43 },
    },
    power = {
        MANA   = { 0.30, 0.50, 0.85 },
        RAGE   = { 0.90, 0.20, 0.30 },
        FOCUS  = { 1.00, 0.50, 0.25 },
        ENERGY = { 1.00, 0.85, 0.10 },
    },
    -- Indexed by UnitReaction (1 hated .. 8 exalted).
    reaction = {
        { 0.80, 0.30, 0.22 },
        { 0.80, 0.30, 0.22 },
        { 0.75, 0.27, 0.00 },
        { 0.90, 0.70, 0.00 },
        { 0.00, 0.60, 0.10 },
        { 0.00, 0.60, 0.10 },
        { 0.00, 0.60, 0.10 },
        { 0.00, 0.60, 0.10 },
    },
    static  = { 0.20, 0.90, 0.20 },
    cast    = { 1.00, 0.70, 0.30 },
    channel = { 0.25, 0.25, 1.00 },
    tapped  = { 0.50, 0.50, 0.50 },
    offline = { 0.50, 0.50, 0.50 },
    unknownPower = { 0.60, 0.60, 0.60 },
    -- pet happiness as returned by C_PetInfo.GetPetHappiness (Luna colours)
    happiness = {
        { 0.90, 0.00, 0.00 },   -- 1 unhappy
        { 0.93, 0.93, 0.00 },   -- 2 content
        { 0.20, 0.90, 0.20 },   -- 3 happy
    },
}

-- The player's pet happiness (1 unhappy, 2 content, 3 happy), or nil when
-- the unit is not the player's pet or the pet has none (non-hunter pets).
function ns.PetHappiness(unit)
    if unit ~= "pet" or not (C_PetInfo and C_PetInfo.GetPetHappiness) then return end
    local ok, h = pcall(C_PetInfo.GetPetHappiness)
    if ok and ns.CanRead(h) and h and ns.colors.happiness[h] then return h end
end

-- Class token of a unit, or nil when it is secret (identity restricted).
function ns.UnitClassToken(unit)
    local _, token = UnitClass(unit)
    if ns.CanRead(token) and token then return token end
end

function ns.ClassColor(unit)
    local token = ns.UnitClassToken(unit)
    return token and ns.colors.class[token]
end

function ns.ReactionColor(unit)
    local r = UnitReaction(unit, "player")
    if ns.CanRead(r) and r then return ns.colors.reaction[r] end
end

function ns.PowerColor(unit)
    local _, token = UnitPowerType(unit)
    if ns.CanRead(token) and token and ns.colors.power[token] then
        return ns.colors.power[token]
    end
    return ns.colors.unknownPower
end

function ns.Hex(c)
    return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

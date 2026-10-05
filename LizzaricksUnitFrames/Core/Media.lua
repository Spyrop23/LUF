-- LizzaricksUnitFrames / Core / Media
--
-- Textures, fonts and the colour tables (values as in Luna Unit Frames).
local _, ns = ...

ns.media = {
    font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    background = "Interface\\Buttons\\WHITE8X8",
}

-- Bar textures. The first fifteen ship with the addon (smooth 8-bit gradients, no
-- banding at any bar height); the others come with the client (paths
-- checked in the 1.60.1 UI source). Blizzard's UI-StatusBar is made for
-- thin bars and shows bands when stretched.
local MEDIA = "Interface\\AddOns\\LizzaricksUnitFrames\\Media\\"
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

-- Fonts, as in Luna: the client's own, the free ones that ship with the
-- addon (licences in Media\Fonts\LICENSE.txt), and any font another addon
-- registered with LibSharedMedia (not needed, only used when present).
local FONTS = MEDIA .. "Fonts\\"
local DEFAULT_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
ns.fonts = {
    { "Default", DEFAULT_FONT },
    { "Friz Quadrata", "Fonts\\FRIZQT__.TTF" },
    { "Arial Narrow", "Fonts\\ARIALN.TTF" },
    { "Skurri", "Fonts\\SKURRI.TTF" },
    { "Morpheus", "Fonts\\MORPHEUS.TTF" },
    { "Aldrich", FONTS .. "Aldrich.ttf" },
    { "Bangers", FONTS .. "Bangers.ttf" },
    { "Faster One", FONTS .. "FasterOne.ttf" },
    { "Iceland", FONTS .. "Iceland.ttf" },
    { "Inconsolata", FONTS .. "Inconsolata.ttf" },
    { "Trade Winds", FONTS .. "TradeWinds.ttf" },
    { "Vera Serif", FONTS .. "VeraSerif.ttf" },
}

local function sharedMedia()
    local stub = _G.LibStub
    return stub and stub("LibSharedMedia-3.0", true)
end

-- Every font to choose from: { name, path }.
function ns.FontList()
    local list, seen = {}, {}
    for _, f in ipairs(ns.fonts) do
        table.insert(list, f)
        seen[f[1]] = true
    end
    local lsm = sharedMedia()
    if lsm then
        local ok, names = pcall(lsm.List, lsm, "font")
        for _, name in ipairs(ok and names or {}) do
            if not seen[name] then
                local path = lsm:Fetch("font", name, true)
                if path then table.insert(list, { name, path }) seen[name] = true end
            end
        end
    end
    return list
end

function ns.Font()
    local want = ns.db and ns.db.font
    if want and want ~= "Default" then
        for _, f in ipairs(ns.FontList()) do
            if f[1] == want then return f[2] end
        end
    end
    return DEFAULT_FONT
end

-- Outline for the frame texts (tags, cast bar), as chosen on the General page.
function ns.FontFlags()
    return ns.db and ns.db.fontOutline and "OUTLINE" or ""
end

-- Sets the chosen font; falls back to the client's font if the file does
-- not load (a missing shared-media font, a client without that file).
-- Every font string we gave a font, to set it again later (weak keys).
local fontStrings = setmetatable({}, { __mode = "k" })

local function apply(fs, size, flags)
    local ok, set = pcall(fs.SetFont, fs, ns.Font(), size, flags)
    if not (ok and set) then
        fs:SetFont(DEFAULT_FONT, size, flags)
    end
end

function ns.SetFont(fs, size, flags)
    flags = flags or ""
    fontStrings[fs] = { size, flags }
    apply(fs, size, flags)
end

-- A font file the client has not loaded yet can leave a font string empty
-- although the font was set (seen with shared-media fonts: the text came
-- back only once the outline was toggled). Setting the same font again is
-- ignored, so every string gets a different font first, then its own.
function ns.RefreshFonts()
    for fs, s in pairs(fontStrings) do
        pcall(fs.SetFont, fs, DEFAULT_FONT, s[1], s[2])
        apply(fs, s[1], s[2])
    end
end

-- Loads every font file once into a hidden string, so it is ready before
-- the frames use it.
local preload
function ns.PreloadFonts()
    preload = preload or UIParent:CreateFontString(nil, "BACKGROUND")
    preload:Hide()
    for _, f in ipairs(ns.FontList()) do
        if pcall(preload.SetFont, preload, f[2], 12, "") then preload:SetText("Lizzarick") end
    end
end

-- Right after login and after a font change: once more a little later,
-- when the files have loaded.
function ns.RefreshFontsSoon()
    if not C_Timer then return end
    C_Timer.After(0.5, ns.RefreshFonts)
    C_Timer.After(2, ns.RefreshFonts)
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
        -- Retail classes (Blizzard's class colours)
        DEATHKNIGHT = { 0.77, 0.12, 0.23 },
        DEMONHUNTER = { 0.64, 0.19, 0.79 },
        MONK        = { 0.00, 1.00, 0.60 },
        EVOKER      = { 0.20, 0.58, 0.50 },
    },
    power = {
        MANA   = { 0.30, 0.50, 0.85 },
        RAGE   = { 0.90, 0.20, 0.30 },
        FOCUS  = { 1.00, 0.50, 0.25 },
        ENERGY = { 1.00, 0.85, 0.10 },
        -- Retail power types (Blizzard's PowerBarColor)
        RUNIC_POWER  = { 0.00, 0.82, 1.00 },
        LUNAR_POWER  = { 0.30, 0.52, 0.90 },
        MAELSTROM    = { 0.00, 0.50, 1.00 },
        INSANITY     = { 0.40, 0.00, 0.80 },
        FURY         = { 0.79, 0.26, 0.99 },
        PAIN         = { 1.00, 0.61, 0.00 },
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

-- Luna's Colors page: a profile may override any colour above
-- (ns.db.colors["class.WARRIOR"] = { r, g, b }). The tables are changed in
-- place, so code holding a reference sees the new values.
local function copy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = type(v) == "table" and copy(v) or v end
    return c
end
local defaultColors = copy(ns.colors)

-- "class.WARRIOR" -> the colour table in `root` (nil if there is none).
local function colorAt(root, path)
    local t = root
    for part in path:gmatch("[^%.]+") do
        if type(t) ~= "table" then return nil end
        t = t[tonumber(part) or part]
    end
    return type(t) == "table" and type(t[1]) == "number" and t or nil
end

function ns.DefaultColor(path) return colorAt(defaultColors, path) end
function ns.Color(path) return colorAt(ns.colors, path) end

function ns.ApplyColors()
    local over = ns.db and ns.db.colors or {}
    local function walk(dst, def, prefix)
        for k, v in pairs(def) do
            local path = prefix .. k
            if type(v[1]) == "number" then
                local o = over[path]
                local src = type(o) == "table" and o or v
                dst[k][1], dst[k][2], dst[k][3] = src[1], src[2], src[3]
            else
                walk(dst[k], v, path .. ".")
            end
        end
    end
    walk(ns.colors, defaultColors, "")
end

function ns.SetColor(path, r, g, b)
    ns.db.colors = ns.db.colors or {}
    ns.db.colors[path] = { r, g, b }
    ns.ApplyColors()
    ns:ApplyAll()
end

function ns.ResetColors()
    ns.db.colors = {}
    ns.ApplyColors()
    ns:ApplyAll()
end

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
    -- other Retail power types: Blizzard's own colour table
    local pbc = ns.CanRead(token) and token and _G.PowerBarColor and _G.PowerBarColor[token]
    if type(pbc) == "table" and pbc.r then return { pbc.r, pbc.g, pbc.b } end
    return ns.colors.unknownPower
end

function ns.Hex(c)
    return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

ns:OnLogin(ns.PreloadFonts)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function() ns.RefreshFontsSoon() end)

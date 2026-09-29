-- FUF / Core / Profile
--
-- Saved variables with named profiles, without a library.
--
-- FUFDB = {
--     profiles = { [name] = <settings> },
--     chars    = { [player GUID] = profileName },
--     minimap  = { angle = 220, hide = false },   -- account-wide, not per profile
-- }
--
-- ns.db is the active profile. Missing keys are filled from ns.defaults
-- on load, so a new setting never needs a migration.
local _, ns = ...

-- Layout units are pixels at scale 1. x/y are the frame's top-left corner
-- relative to UIParent's top-left (Luna's default layout); party frames
-- stack below the first one, party pets sit relative to their owner's frame.
-- Tag lines use the Luna syntax, see Core/Tags.lua.
local function merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            merge(dst[k], v)
        else
            dst[k] = v
        end
    end
    return dst
end

local function unitDefaults(o)
    local d = {
        enabled = true,
        x = 10, y = -15,
        width = 240, height = 40,
        scale = 1,
        hideBlizzard = true,
        healthBar = { weight = 6, colorType = "class", background = true, backgroundAlpha = 0.2 },
        powerBar  = { enabled = true, weight = 4.5, background = true, backgroundAlpha = 0.2 },
        portrait  = { enabled = true, type = "3D", side = "LEFT", width = 0.22 },
        castBar   = { enabled = false, height = 10, position = "BELOW", icon = true, hideBlizzard = true },
        tags = {
            healthBar = { size = 10, left = "[name]", center = "", right = "[smarthealth]" },
            powerBar  = { size = 10, left = "[levelcolor][level][shortclassification] [classcolor][smartclass]", center = "", right = "[pp]/[maxpp]" },
        },
    }
    return merge(d, o or {})
end

local function small(o)
    return merge({
        width = 100, height = 30,
        portrait = { enabled = false },
        powerBar = { enabled = false },
        tags = {
            healthBar = { size = 9, left = "[name]", center = "", right = "[perhp]" },
            powerBar  = { size = 9, left = "", center = "", right = "" },
        },
    }, o)
end

local noPortrait = { portrait = { enabled = false } }

ns.defaults = {
    locked = true,
    texture = "Blizzard",
    backgroundAlpha = 0.8,
    units = {
        player = unitDefaults({ castBar = { enabled = true } }),
        pet = unitDefaults({ y = -72, height = 30 }),
        pettarget = unitDefaults(small({ x = 260, y = -72, enabled = false })),
        target = unitDefaults({
            x = 260,
            castBar = { enabled = true },
            tags = { healthBar = { right = "[smarthealthp]" } },
        }),
        targettarget = unitDefaults(merge({ x = 510, width = 150 }, noPortrait)),
        targettargettarget = unitDefaults(merge({ x = 670, width = 150 }, noPortrait)),
        party = unitDefaults({ y = -115, spacing = 20 }),
        partypet = unitDefaults(small({
            x = 5, y = -20, height = 20,
            tags = { healthBar = { left = "", center = "[smarthealth]", right = "" } },
        })),
    },
}

local function copyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            copyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local function deepCopy(t)
    local c = {}
    for k, v in pairs(t) do
        c[k] = type(v) == "table" and deepCopy(v) or v
    end
    return c
end

-- Forever has no realms in the classic sense and names may come back in
-- two parts; the GUID is the stable key when it is readable.
local function charKey()
    local guid = ns.Readable(UnitGUID("player"), nil)
    if guid then return guid end
    local name = ns.Readable(UnitName("player"), nil) or "?"
    return name .. " - " .. (ns.Readable(GetRealmName(), nil) or "?")
end

function ns:InitDB()
    FUFDB = FUFDB or {}
    FUFDB.profiles = FUFDB.profiles or {}
    FUFDB.chars = FUFDB.chars or {}
    FUFDB.minimap = FUFDB.minimap or { angle = 220, hide = false }
    local name = FUFDB.chars[charKey()] or "Default"
    FUFDB.chars[charKey()] = name
    self:SetProfile(name)
end

function ns:CurrentProfile()
    return FUFDB.chars[charKey()]
end

-- Switching the profile rebuilds the layout (deferred until out of combat).
function ns:SetProfile(name)
    FUFDB.profiles[name] = copyDefaults(FUFDB.profiles[name] or {}, self.defaults)
    FUFDB.chars[charKey()] = name
    self.db = FUFDB.profiles[name]
    if self.OnProfileChanged then self:OnProfileChanged() end
end

function ns:ResetProfile()
    FUFDB.profiles[self:CurrentProfile()] = nil
    self:SetProfile(self:CurrentProfile())
end

-- Copies another profile's settings into the current one.
function ns:CopyProfile(from)
    local src = FUFDB.profiles[from]
    if not src or from == self:CurrentProfile() then return end
    FUFDB.profiles[self:CurrentProfile()] = deepCopy(src)
    self:SetProfile(self:CurrentProfile())
end

-- Deletes a profile that no character uses at the moment of the call
-- except possibly others; the current one cannot be deleted.
function ns:DeleteProfile(name)
    if name == self:CurrentProfile() then return false end
    FUFDB.profiles[name] = nil
    for char, p in pairs(FUFDB.chars) do
        if p == name then FUFDB.chars[char] = "Default" end
    end
    return true
end

function ns:ProfileNames()
    local list = {}
    for n in pairs(FUFDB.profiles) do table.insert(list, n) end
    table.sort(list)
    return list
end

-- FUF / Core / Profile
--
-- Saved variables with named profiles, without a library.
--
-- FUFDB = {
--     profiles = { [name] = <settings> },
--     chars    = { [player GUID] = profileName },
-- }
--
-- ns.db is the active profile. Missing keys are filled from ns.defaults
-- on load, so a new setting never needs a migration.
local _, ns = ...

-- Layout units are pixels at scale 1. x/y are the frame's top-left corner
-- relative to UIParent's top-left (Luna's default layout). Tag lines use
-- the Luna syntax, see Core/Tags.lua.
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
        tags = {
            healthBar = { size = 10, left = "[name]", center = "", right = "[smarthealth]" },
            powerBar  = { size = 10, left = "[levelcolor][level][shortclassification] [classcolor][smartclass]", center = "", right = "[pp]/[maxpp]" },
        },
    }
    return merge(d, o or {})
end

local noPortrait = { portrait = { enabled = false } }

ns.defaults = {
    locked = true,
    units = {
        player = unitDefaults(),
        target = unitDefaults({
            x = 260,
            tags = { healthBar = { right = "[smarthealthp]" } },
        }),
        targettarget = unitDefaults(merge({ x = 510, width = 150 }, noPortrait)),
        targettargettarget = unitDefaults(merge({ x = 670, width = 150 }, noPortrait)),
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
    local name = FUFDB.chars[charKey()] or "Default"
    FUFDB.chars[charKey()] = name
    self:SetProfile(name)
end

function ns:CurrentProfile()
    return FUFDB.chars[charKey()]
end

-- Switching the profile rebuilds the layout; call out of combat only.
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

function ns:ProfileNames()
    local list = {}
    for n in pairs(FUFDB.profiles) do table.insert(list, n) end
    table.sort(list)
    return list
end

-- LizzaricksUnitFrames / Core / Profile
--
-- Saved variables with named profiles, without a library.
--
-- LizzaricksUFDB = {
--     profiles = { [name] = <settings> },
--     chars    = { [player GUID] = profileName },
--     minimap  = { angle = 220, hide = false },   -- account-wide, not per profile
--     filterLists = { [name] = { [spellID] = true } },   -- account-wide
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

-- Luna's nine squares, all off: corners 10 px, edges and centre 15 px.
local function squareDefaults()
    local s = {}
    for _, p in ipairs({ "topleft", "top", "topright", "bottomleft", "bottom", "bottomright" }) do
        s[p] = { enabled = false, type = "aggro", size = 10, x = 0, y = 0, spells = "", list = "", texture = false, timer = false, count = 1, grow = "RIGHT" }
    end
    s.leftcenter = { enabled = false, type = "aggro", size = 15, x = -1, y = 0, spells = "", list = "", texture = false, timer = false, count = 1, grow = "RIGHT" }
    s.center = { enabled = false, type = "aggro", size = 15, x = 0, y = 0, spells = "", list = "", texture = false, timer = false, count = 1, grow = "RIGHT" }
    s.rightcenter = { enabled = false, type = "aggro", size = 15, x = 1, y = 0, spells = "", texture = false, timer = false }
    return s
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
        healPrediction = { enabled = true, overflow = 1.05, alpha = 0.8, absorbs = true },
        xpBar     = { enabled = false, weight = 2, background = true, backgroundAlpha = 0.2 },
        emptyBar  = { enabled = false, weight = 3, background = true, backgroundAlpha = 0.5, color = { 0, 0, 0 } },
        range     = { enabled = true, alpha = 0.4 },
        squares   = squareDefaults(),
        borders   = { mouseover = true, aggro = false, debuff = "own", size = 2, onTop = false },   -- Luna's defaults
        highlight = { mouseover = false, target = false, debuff = "off", alpha = 0.25 },
        combatText = { enabled = false, size = 20 },
        indicators = {
            raidTarget   = { enabled = true, size = 20, point = "TOP", x = 0, y = 0 },
            class        = { enabled = false, size = 16, point = "BOTTOMRIGHT", x = -1, y = 1 },
            masterLooter = { enabled = true, size = 12, point = "TOPRIGHT", x = -16, y = -1 },
            leader       = { enabled = true, size = 14, point = "TOPRIGHT", x = -4, y = -1 },
            assistant    = { enabled = true, size = 14, point = "TOPRIGHT", x = -4, y = -1 },   -- where the leader's crown would be
            mainTank     = { enabled = true, size = 14, point = "TOPLEFT", x = 18, y = -1 },     -- next to the role icon
            mainAssist   = { enabled = true, size = 14, point = "TOPLEFT", x = 18, y = -1 },
            pvp          = { enabled = false, size = 24, point = "RIGHT", x = 0, y = 0 },
            resurrect    = { enabled = true, size = 20, point = "CENTER", x = 0, y = 0 },
            role         = { enabled = true, size = 14, point = "TOPLEFT", x = 4, y = -1 },
            elite        = { enabled = false, side = "RIGHT", scale = 1.6 },
        },
        auras     = {
            buffs = false, debuffs = false,
            buffFilter = "all", debuffFilter = "all",
            buffList = "", buffListMode = "exclude", debuffList = "", debuffListMode = "exclude",
            size = 18, debuffSize = 22, spacing = 2, groupGap = 4, perRow = 8,
            maxBuffs = 16, maxDebuffs = 16,
            position = "BOTTOM",
            debuffPosition = "SAME",   -- "SAME" = with the buffs, else a place of their own
            -- Luna's horizontal limit side / limit (% of the frame width) and
            -- bigger buffs (extra pixels for your own auras)
            buffGrow = "RIGHT", debuffGrow = "RIGHT", buffLimit = 100, debuffLimit = 100,
            biggerBuffs = 0, biggerDebuffs = 0,
            buffX = 0, buffY = 0, debuffX = 0, debuffY = 0,   -- offsets of the blocks
            durationPosition = "BELOW",   -- time left: BELOW / INSIDE / ABOVE the icon
            duration = true, swipe = true, dispelColors = true,
        },
        tags = {
            healthBar = { size = 10, left = "[name]", center = "", right = "[smarthealth]" },
            powerBar  = { size = 10, left = "[levelcolor][level][shortclassification] [classcolor][smartclass]", center = "", right = "[pp]/[maxpp]" },
            xpBar     = { size = 8, left = "", center = "[xp] [percxp]", right = "" },
            emptyBar  = { size = 10, left = "", center = "[name]", right = "" },
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
    texture = "Smooth",
    backgroundAlpha = 0.8,
    units = {
        player = unitDefaults({
            castBar = { enabled = true },
            status = { enabled = true, size = 16, point = "BOTTOMLEFT" },   -- Luna's default
            combatText = { enabled = true },
            -- combo points, holy power, soul shards ... as a row of points
            classPower = { enabled = true, height = 7, spacing = 2, position = "ABOVE" },
        }),
        pet = unitDefaults({
            y = -72, height = 30,
            healthBar = { colorType = "happiness" },
            happiness = { enabled = false, size = 14 },   -- the colour says enough
            auras = { buffs = true, debuffs = true, size = 16, debuffSize = 20 },
            xpBar = { enabled = true },
            combatText = { enabled = true },
            tags = { xpBar = { center = "[xppet] [percxppet]" } },
        }),
        pettarget = unitDefaults(small({ x = 260, y = -72, enabled = false })),
        target = unitDefaults({
            x = 260,
            indicators = { elite = { enabled = true } },
            combatText = { enabled = true },
            castBar = { enabled = true },
            auras = { buffs = true, debuffs = true },
            tags = { healthBar = { right = "[smarthealthp]" } },
        }),
        targettarget = unitDefaults(merge({ x = 510, width = 150 }, noPortrait)),
        targettargettarget = unitDefaults(merge({ x = 670, width = 150 }, noPortrait)),
        -- focus below target of target, its target (off by default) next to it
        focus = unitDefaults(merge({
            x = 510, y = -65, width = 200, height = 34,
            castBar = { enabled = true },
            auras = { debuffs = true, position = "BOTTOM" },
        }, noPortrait)),
        focustarget = unitDefaults(small({ x = 720, y = -65, width = 120, enabled = false })),
        party = unitDefaults({ y = -140, spacing = 20, hideInRaid = true,
            auras = { debuffs = true, position = "RIGHT", perRow = 4 } }),
        partypet = unitDefaults(small({
            x = 5, y = -20, height = 20,
            tags = { healthBar = { left = "", center = "[smarthealth]", right = "" } },
        })),
        -- Luna's main tank / main assist frames (raid roles), with their targets
        maintank = unitDefaults(small({
            x = 450, y = -200, width = 120, height = 30, spacing = 4,
            tags = { healthBar = { left = "[name]", center = "", right = "[perhp]" } },
        })),
        maintanktarget = unitDefaults(small({
            x = 4, y = 0, width = 100, height = 30,
            tags = { healthBar = { left = "[name]", center = "", right = "[perhp]" } },
        })),
        mainassist = unitDefaults(small({
            x = 450, y = -350, width = 120, height = 30, spacing = 4,
            tags = { healthBar = { left = "[name]", center = "", right = "[perhp]" } },
        })),
        mainassisttarget = unitDefaults(small({
            x = 4, y = 0, width = 100, height = 30,
            tags = { healthBar = { left = "[name]", center = "", right = "[perhp]" } },
        })),
        -- a party member's target: upper half next to the member, the pet below
        partytarget = unitDefaults(small({
            enabled = false, x = 5, y = 0, height = 20,
            tags = { healthBar = { left = "[name]", center = "", right = "[perhp]" } },
        })),
        raid = unitDefaults(small({
            x = 10, y = -420, width = 60, height = 30, spacing = 2, groupSpacing = 4,
            groupDirection = "DOWN", groupsPerRow = 8, separateGroups = false,
            showInParty = false, hidePartyFrames = true,   -- Luna: raid frames in a party
            healthBar = { weight = 8 },
            powerBar = { enabled = true, weight = 1.5 },
            tags = {
                healthBar = { size = 8, left = "", center = "[name]", right = "" },
                powerBar  = { size = 7, left = "", center = "", right = "" },
            },
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
    LizzaricksUFDB = LizzaricksUFDB or {}
    LizzaricksUFDB.profiles = LizzaricksUFDB.profiles or {}
    LizzaricksUFDB.chars = LizzaricksUFDB.chars or {}
    LizzaricksUFDB.minimap = LizzaricksUFDB.minimap or { angle = 220, hide = false }
    LizzaricksUFDB.filterLists = LizzaricksUFDB.filterLists or {}   -- account-wide
    local name = LizzaricksUFDB.chars[charKey()] or "Default"
    LizzaricksUFDB.chars[charKey()] = name
    self:SetProfile(name)
end

function ns:CurrentProfile()
    return LizzaricksUFDB.chars[charKey()]
end

-- Switching the profile rebuilds the layout (deferred until out of combat).
function ns:SetProfile(name)
    LizzaricksUFDB.profiles[name] = copyDefaults(LizzaricksUFDB.profiles[name] or {}, self.defaults)
    LizzaricksUFDB.chars[charKey()] = name
    self.db = LizzaricksUFDB.profiles[name]
    -- 0.3.0: pets are coloured by happiness, as in Luna
    if not self.db.migrated030 then
        self.db.migrated030 = true
        if self.db.units.pet.healthBar.colorType == "class" then
            self.db.units.pet.healthBar.colorType = "happiness"
        end
    end
    -- 0.3.1: our own smooth texture replaces Blizzard's banded one
    if not self.db.migrated031 then
        self.db.migrated031 = true
        if self.db.texture == "Blizzard" then self.db.texture = "Smooth" end
    end
    -- 0.6.2: debuffs larger than buffs (Luna's "bigger debuffs")
    if not self.db.migrated062 then
        self.db.migrated062 = true
        for _, u in pairs(self.db.units) do
            if u.auras then u.auras.debuffSize = (u.auras.size or 18) + 4 end
        end
    end
    -- 0.3.3: the happiness face is off by default (the bar colour shows it)
    if not self.db.migrated033 then
        self.db.migrated033 = true
        self.db.units.pet.happiness.enabled = false
    end
    -- Retail: no pet happiness, pets coloured like other frames
    if ns.isRetail and self.db.units.pet.healthBar.colorType == "happiness" then
        self.db.units.pet.healthBar.colorType = "class"
    end
    self.db.colors = self.db.colors or {}   -- Colors page overrides
    ns.ApplyColors()
    if self.OnProfileChanged then self:OnProfileChanged() end
end

function ns:ResetProfile()
    LizzaricksUFDB.profiles[self:CurrentProfile()] = nil
    self:SetProfile(self:CurrentProfile())
end

-- Copies another profile's settings into the current one.
function ns:CopyProfile(from)
    local src = LizzaricksUFDB.profiles[from]
    if not src or from == self:CurrentProfile() then return end
    LizzaricksUFDB.profiles[self:CurrentProfile()] = deepCopy(src)
    self:SetProfile(self:CurrentProfile())
end

-- Deletes a profile that no character uses at the moment of the call
-- except possibly others; the current one cannot be deleted.
function ns:DeleteProfile(name)
    if name == self:CurrentProfile() then return false end
    LizzaricksUFDB.profiles[name] = nil
    for char, p in pairs(LizzaricksUFDB.chars) do
        if p == name then LizzaricksUFDB.chars[char] = "Default" end
    end
    return true
end

function ns:ProfileNames()
    local list = {}
    for n in pairs(LizzaricksUFDB.profiles) do table.insert(list, n) end
    table.sort(list)
    return list
end

-- LizzaricksUnitFrames / Frames / ClassPower
--
-- The class resource as a row of points on the player frame: combo points
-- (rogue, druid in cat form), holy power, soul shards, chi, arcane charges,
-- essence.
--
-- The current value may be secret (power types are secret unless the game
-- flags them otherwise). It is never compared: every point is a tiny status
-- bar spanning "point n-1 .. n", and the value goes into SetValue, so the
-- client fills exactly the points that are reached. The number of points
-- (UnitPowerMax for the player) is readable: the player is player-controlled.
--
-- Forever keeps Classic's combo points on the target (Blizzard's own combo
-- frame reads GetComboPoints("player", "target") there); everything else
-- reads UnitPower("player", type).
local _, ns = ...

local CP = {}
ns.ClassPower = CP

CP.supported = { player = true }
CP.POSITIONS = { { "ABOVE", "Above the frame" }, { "BELOW", "Below the frame" } }

local MAX_POINTS = 10
local PT = Enum and Enum.PowerType or {}

-- Point colours by power type.
local COLORS = {
    [PT.ComboPoints or 4]   = { 1.00, 0.82, 0.10 },
    [PT.HolyPower or 9]     = { 0.95, 0.90, 0.60 },
    [PT.SoulShards or 7]    = { 0.58, 0.51, 0.79 },
    [PT.Chi or 12]          = { 0.71, 1.00, 0.92 },
    [PT.ArcaneCharges or 16] = { 0.41, 0.80, 0.94 },
    [PT.Essence or 19]      = { 0.40, 0.80, 1.00 },
}

local function call(fn, ...)
    if not fn then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
end

local function readable(v) return ns.CanRead(v) and v end

-- The power type the player's class shows as points right now, or nil.
local function powerType()
    local _, class = call(UnitClass, "player")
    class = readable(class)
    if class == "ROGUE" then return PT.ComboPoints or 4 end
    if class == "DRUID" then
        -- combo points only in cat form (energy is the shown power then)
        local _, token = call(UnitPowerType, "player")
        if readable(token) == "ENERGY" then return PT.ComboPoints or 4 end
        return nil
    end
    if class == "PALADIN" then return PT.HolyPower or 9 end
    if class == "WARLOCK" then return PT.SoulShards or 7 end
    if class == "EVOKER" then return PT.Essence or 19 end
    local spec = readable(call(GetSpecialization))
    if class == "MONK" and spec == 3 then return PT.Chi or 12 end            -- Windwalker
    if class == "MAGE" and spec == 1 then return PT.ArcaneCharges or 16 end   -- Arcane
end

-- Classes that can have points at all (druids: in cat form); in Forever
-- only combo points exist.
local CLASSES = ns.isRetail
    and { ROGUE = true, DRUID = true, PALADIN = true, WARLOCK = true, MONK = true, MAGE = true, EVOKER = true }
    or { ROGUE = true, DRUID = true }

-- Space the row takes next to the frame on `side` ("ABOVE"/"BELOW"), so the
-- cast bar and the auras can make room. Kept for the class even while a
-- form or spec shows no points, so nothing jumps around in combat.
function CP.Reserved(f, side)
    if not f.classPower then return 0 end
    local db = f.db.classPower
    if not (db and db.enabled) or (db.position or "ABOVE") ~= side then return 0 end
    local _, class = call(UnitClass, "player")
    if not (ns.unlocked or CLASSES[readable(class)]) then return 0 end
    return db.height + 1
end

local function maxPoints(ptype)
    local max = readable(call(UnitPowerMax, "player", ptype))
    if type(max) ~= "number" or max <= 0 then return 0 end
    return math.min(max, MAX_POINTS)
end

-- The (possibly secret) current value; never compared, only handed to bars.
local function currentValue(ptype)
    if ns.isForever and ptype == (PT.ComboPoints or 4) and GetComboPoints then
        return call(GetComboPoints, "player", "target")
    end
    return call(UnitPower, "player", ptype)
end

local frames = {}

function CP.Create(f)
    if not CP.supported[f.key] then return end
    local holder = CreateFrame("Frame", nil, f)
    holder:SetFrameLevel(f:GetFrameLevel() + 2)
    holder.points = {}
    for i = 1, MAX_POINTS do
        local bar = CreateFrame("StatusBar", nil, holder)
        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints()
        bar:SetMinMaxValues(i - 1, i)
        bar:SetValue(0)
        bar:Hide()
        holder.points[i] = bar
    end
    holder:Hide()
    f.classPower = holder
    frames[f] = true
end

-- Places the row and its points for `count` points.
local function arrange(f, count)
    local holder, db = f.classPower, f.db.classPower
    local width = f.db.width
    local gap = db.spacing or 2
    local pointW = (width - (count - 1) * gap) / count
    local texture = ns.Texture()
    for i, bar in ipairs(holder.points) do
        bar:ClearAllPoints()
        if i <= count then
            bar:SetPoint("TOPLEFT", holder, "TOPLEFT", (i - 1) * (pointW + gap), 0)
            bar:SetSize(pointW, db.height)
            bar:SetStatusBarTexture(texture)
            bar.bg:SetTexture(texture)
            bar:Show()
        else
            bar:Hide()
        end
    end
    holder.count = count
end

-- Where the row sits (protected context: called from UF.Layout).
function CP.Layout(f)
    local holder = f.classPower
    if not holder then return end
    local db = f.db.classPower
    holder:ClearAllPoints()
    holder:SetSize(f.db.width, db.height)
    -- directly on the frame; the cast bar makes room (CP.Reserved)
    if db.position == "BELOW" then
        holder:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -1)
    else
        holder:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 1)
    end
    holder.count = nil   -- re-arrange on the next update
    CP.Update(f)
end

function CP.Update(f)
    local holder = f.classPower
    if not holder then return end
    local db = f.db.classPower
    local ptype = db.enabled and powerType()
    local count = ptype and maxPoints(ptype) or 0
    if ns.unlocked and db.enabled and count == 0 then
        count, ptype = 5, PT.ComboPoints or 4   -- config mode: show where it goes
    end
    if count == 0 then
        holder:Hide()
        return
    end
    if holder.count ~= count then arrange(f, count) end
    local c = COLORS[ptype] or COLORS[PT.ComboPoints or 4]
    local value = ns.unlocked and 3 or currentValue(ptype)
    for i = 1, count do
        local bar = holder.points[i]
        bar:SetStatusBarColor(c[1], c[2], c[3])
        bar.bg:SetVertexColor(c[1] * 0.25, c[2] * 0.25, c[3] * 0.25, 0.8)
        -- each point fills itself once the (secret) value reaches it
        if type(value) == "nil" or not pcall(bar.SetValue, bar, value) then bar:SetValue(0) end
    end
    holder:Show()
end

CP.Refresh = CP.Update

local function updateAll()
    for f in pairs(frames) do
        if f:IsVisible() then CP.Update(f) end
    end
end

local function onPower(_, unit)
    if unit == "player" then updateAll() end
end

for _, event in ipairs({ "UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER" }) do
    ns:RegisterEvent(event, onPower)
end
for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED",
    "UPDATE_SHAPESHIFT_FORM" }) do
    ns:RegisterEvent(event, updateAll)
end

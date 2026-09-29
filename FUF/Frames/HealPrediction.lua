-- FUF / Frames / HealPrediction
--
-- Incoming heals and absorb shields on the health bar, as in Luna: own heals
-- dark green, heals from others light green, absorbs white, each starting
-- where the previous one ends.
--
-- All amounts are secret. The client's own heal prediction calculator
-- (CreateUnitHealPredictionCalculator + UnitGetDetailedHealPrediction) splits
-- them into "from me" and "from others" and clamps them to the missing health
-- plus the allowed overflow, so our code never adds or compares anything.
-- Each amount goes into its own StatusBar (0 .. max health, the width of the
-- health bar), anchored to the right edge of the previous bar's fill.
local _, ns = ...

local HP = {}
ns.HealPrediction = HP

local COLORS = {
    own    = { 0.10, 0.45, 0.10 },
    others = { 0.20, 0.90, 0.20 },
    absorb = { 0.85, 0.95, 1.00 },
}

local function newBar(parent)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetMinMaxValues(0, 1)
    b:SetValue(0)
    return b
end

function HP.Create(f)
    if not CreateUnitHealPredictionCalculator or not UnitGetDetailedHealPrediction then return end
    local ok, calc = pcall(CreateUnitHealPredictionCalculator)
    if not ok or not calc then return end

    -- The holder clips: prediction may reach past the bar only as far as the
    -- overflow setting allows.
    local holder = CreateFrame("Frame", nil, f.healthBar)
    holder:SetClipsChildren(true)
    holder:SetFrameLevel(f.healthBar:GetFrameLevel() + 1)

    f.heal = {
        calc = calc,
        holder = holder,
        own = newBar(holder),
        others = newBar(holder),
        absorb = newBar(holder),
    }
end

-- Geometry and look (protected context: called from UF.Layout).
function HP.Layout(f, barWidth)
    local h = f.heal
    if not h then return end
    local db = f.db.healPrediction
    local bar = f.healthBar
    if not db or not db.enabled or not bar:IsShown() then
        h.holder:Hide()
        return
    end

    local overflow = math.max(1, db.overflow or 1)
    pcall(h.calc.SetIncomingHealOverflowPercent, h.calc, overflow)
    if Enum.UnitIncomingHealClampMode then
        pcall(h.calc.SetIncomingHealClampMode, h.calc, Enum.UnitIncomingHealClampMode.MissingHealth)
    end

    h.holder:ClearAllPoints()
    h.holder:SetPoint("TOPLEFT", bar, "TOPLEFT")
    h.holder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", barWidth * (overflow - 1), 0)
    h.holder:Show()

    local texture = ns.Texture()
    local previous = bar:GetStatusBarTexture()
    for _, key in ipairs({ "own", "others", "absorb" }) do
        local b = h[key]
        b:SetStatusBarTexture(texture)
        local c = COLORS[key]
        b:SetStatusBarColor(c[1], c[2], c[3], db.alpha)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", previous, "TOPRIGHT")
        b:SetPoint("BOTTOMLEFT", previous, "BOTTOMRIGHT")
        b:SetWidth(barWidth)
        b:SetShown(key ~= "absorb" or db.absorbs)
        previous = b:GetStatusBarTexture()
    end
end

-- New values: every amount straight from the calculator into its bar.
function HP.Update(f)
    local h = f.heal
    if not h or not h.holder:IsShown() then return end
    local unit = f.unit
    local ok = pcall(UnitGetDetailedHealPrediction, unit, "player", h.calc)
    if not ok then return end

    local maxHealth = UnitHealthMax(unit)
    local okHeals, _, fromMe, fromOthers = pcall(h.calc.GetIncomingHeals, h.calc)
    if not okHeals then fromMe, fromOthers = nil, nil end
    local absorbs
    if f.db.healPrediction.absorbs then
        local okAbsorb, amount = pcall(h.calc.GetDamageAbsorbs, h.calc)
        if okAbsorb then absorbs = amount end
    end

    -- type() is the one test that is allowed on a secret
    local function show(b, value)
        b:SetMinMaxValues(0, maxHealth)
        if type(value) == "nil" then b:SetValue(0) else b:SetValue(value) end
    end
    show(h.own, fromMe)
    show(h.others, fromOthers)
    show(h.absorb, absorbs)
end

-- LizzaricksUnitFrames / Frames / ManaTimer
--
-- The "five second rule" on the player's mana bar (Forever/Classic): after
-- you spend mana, spirit regeneration pauses for 5 seconds. A spark runs
-- along the mana bar during that time; when it reaches the end, mana
-- regenerates again.
--
-- The player's mana can be secret (it may not be compared), so spending is
-- seen from the spell: a successful cast whose cost (C_Spell.GetSpellPowerCost)
-- includes mana. A readable drop of mana counts too (e.g. a mana cost the
-- spell data does not list). Retail has no five second rule, so nothing
-- happens there.
local _, ns = ...

local MT = {}
ns.ManaTimer = MT

local DURATION = 5
local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana or 0

local lastMana, started
local ticker = CreateFrame("Frame")

local function call(fn, ...)
    if not fn then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
end

local function playerFrames()
    return ns.UF and ns.UF.byKey.player or {}
end

-- The bar shows mana right now (druids in forms show rage/energy).
local function showsMana()
    local ptype = call(UnitPowerType, "player")
    return ns.CanRead(ptype) and ptype == MANA
end

local function spark(f)
    local bar = f.powerBar
    if not bar then return nil end
    if not bar.fiveSecond then
        local s = bar:CreateTexture(nil, "OVERLAY")
        s:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        s:SetBlendMode("ADD")
        s:Hide()
        bar.fiveSecond = s
    end
    return bar.fiveSecond
end

local function wanted(f)
    local db = f.db.powerBar
    return db.enabled ~= false and db.fiveSecond ~= false and f.unit == "player"
        and f:IsVisible() and f.powerBar:IsShown()
end

local function hideAll()
    for _, f in ipairs(playerFrames()) do
        if f.powerBar and f.powerBar.fiveSecond then f.powerBar.fiveSecond:Hide() end
    end
end

local function onUpdate()
    local left = started and (DURATION - (GetTime() - started)) or 0
    if left <= 0 or not showsMana() then
        started = nil
        ticker:SetScript("OnUpdate", nil)
        hideAll()
        return
    end
    local progress = 1 - left / DURATION
    for _, f in ipairs(playerFrames()) do
        local s = spark(f)
        if s and wanted(f) then
            local bar = f.powerBar
            local h = bar:GetHeight()
            s:SetSize(math.max(12, h * 1.2), h * 2.5)
            s:ClearAllPoints()
            s:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * progress, 0)
            s:Show()
        elseif s then
            s:Hide()
        end
    end
end

local function start()
    if not showsMana() then return end
    started = GetTime()
    ticker:SetScript("OnUpdate", onUpdate)
end

local function readable(v) return ns.CanRead(v) and v or nil end

-- Does the spell cost mana?
local function costsMana(spellID)
    local getCost = C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost
    local costs = call(getCost, spellID)
    if type(costs) ~= "table" then return false end
    for _, c in ipairs(costs) do
        if readable(c.type) == MANA then
            local cost, percent = readable(c.cost) or 0, readable(c.costPercent) or 0
            if cost > 0 or percent > 0 then return true end
        end
    end
    return false
end

local function onCast(_, unit, _, spellID)
    if unit ~= "player" or ns.isRetail then return end
    spellID = readable(spellID)
    if spellID and costsMana(spellID) then start() end
end

local function onPower(_, unit)
    if unit ~= "player" or ns.isRetail then return end
    local mana = call(UnitPower, "player", MANA)
    if not ns.CanRead(mana) then lastMana = nil return end
    if lastMana and mana < lastMana then start() end
    lastMana = mana
end

ns:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", onCast)
for _, event in ipairs({ "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT" }) do
    ns:RegisterEvent(event, onPower)
end

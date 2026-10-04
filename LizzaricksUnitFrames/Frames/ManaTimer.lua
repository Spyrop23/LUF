-- LizzaricksUnitFrames / Frames / ManaTimer
--
-- The "five second rule" on the player's mana bar (Forever/Classic): after
-- you spend mana, spirit regeneration pauses for 5 seconds. A spark runs
-- along the mana bar during that time; when it reaches the end, mana
-- regenerates again.
--
-- Spending is seen as a drop of the player's mana (readable in Forever).
-- Retail has no five second rule, so nothing happens there.
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
            s:SetSize(math.max(8, h * 0.6), h * 2)
            s:ClearAllPoints()
            s:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * progress, 0)
            s:Show()
        elseif s then
            s:Hide()
        end
    end
end

local function onPower(_, unit)
    if unit ~= "player" or ns.isRetail then return end
    local mana = call(UnitPower, "player", MANA)
    if not ns.CanRead(mana) then lastMana = nil return end
    if lastMana and mana < lastMana and showsMana() then
        started = GetTime()
        ticker:SetScript("OnUpdate", onUpdate)
    end
    lastMana = mana
end

for _, event in ipairs({ "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT" }) do
    ns:RegisterEvent(event, onPower)
end

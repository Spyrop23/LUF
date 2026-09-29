-- FUF / Core / Mover
--
-- Config mode (Luna's "unlock"): every frame is shown, drawn with the
-- player as a stand-in when its own unit does not exist, and can be dragged.
-- Protected changes (show, move, unit watch) happen out of combat only;
-- entering combat locks the frames again.
local _, ns = ...

local UF = ns.UF
ns.unlocked = false

local function overlay(f)
    if f.moverOverlay then return f.moverOverlay end
    local o = f:CreateTexture(nil, "OVERLAY")
    o:SetAllPoints()
    o:SetColorTexture(0.2, 0.6, 1, 0.25)
    local label = f:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.media.font, 10, "OUTLINE")
    label:SetPoint("BOTTOM", f, "TOP", 0, 2)
    f.moverOverlay, f.moverLabel = o, label
    return o
end

-- Top-left corner of f relative to UIParent's top-left, in f's own scale.
local function topLeftOffset(f)
    local s = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local x = f:GetLeft()
    local y = f:GetTop() - UIParent:GetTop() / s
    return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function onDragStart(f)
    if InCombatLockdown() then return end
    f:StartMoving()
end

local function onDragStop(f)
    f:StopMovingOrSizing()
    -- Our profile stores the position, not the client's layout cache.
    pcall(f.SetUserPlaced, f, false)
    if InCombatLockdown() then return end
    f.db.x, f.db.y = topLeftOffset(f)
    UF.Layout(f)
end

-- While unlocked a frame without its unit shows the player instead, so
-- there is something to see and place. Its real unit comes back on lock.
local function standIn(f, on)
    local unit = f.realUnit or f.unit
    if on and not UnitExists(unit) then
        f.realUnit = f.realUnit or f.unit
        f.unit = "player"
    elseif not on and f.realUnit then
        f.unit = f.realUnit
        f.realUnit = nil
    end
end

local function unlockFrame(f)
    UnregisterUnitWatch(f)
    standIn(f, true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", onDragStart)
    f:SetScript("OnDragStop", onDragStop)
    overlay(f):Show()
    f.moverLabel:SetText(ns.unitLabels[f.realUnit or f.unit] or f.unit)
    f.moverLabel:Show()
    f:Show()
    UF.Update(f)
end

local function lockFrame(f)
    f:StopMovingOrSizing()
    f:RegisterForDrag()
    f:SetScript("OnDragStart", nil)
    f:SetScript("OnDragStop", nil)
    if f.moverOverlay then
        f.moverOverlay:Hide()
        f.moverLabel:Hide()
    end
    standIn(f, false)
    if f.db.enabled then
        RegisterUnitWatch(f)
        UF.Update(f)
    else
        f:Hide()
    end
end

function ns:SetLocked(locked)
    if InCombatLockdown() then
        ns:Print("Not in combat.")
        return
    end
    ns.unlocked = not locked
    ns.db.locked = locked
    for _, f in pairs(UF.frames) do
        if locked then lockFrame(f) else unlockFrame(f) end
    end
    if not locked then
        ns:Print("Frames unlocked: drag them with the left mouse button. |cffffff00/fuf lock|r when done.")
    end
end

-- Combat ends config mode. PLAYER_REGEN_DISABLED arrives just before the
-- lockdown starts, so the protected calls usually still go through; if not,
-- they run when combat ends.
ns:RegisterEvent("PLAYER_REGEN_DISABLED", function()
    if not ns.unlocked then return end
    ns.unlocked = false
    ns.db.locked = true
    ns:RunOutOfCombat(function()
        for _, f in pairs(UF.frames) do lockFrame(f) end
    end)
    ns:Print("Combat: frames locked.")
end)

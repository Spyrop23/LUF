-- FUF / Core / Mover
--
-- Config mode (Luna's "unlock"): every enabled frame is shown, drawn with
-- the player as a stand-in when its own unit does not exist, and can be
-- dragged. Dragging any party frame moves the whole party; party pets keep
-- their offset to their owner. Protected changes (show, move, unit watch)
-- happen out of combat only; entering combat locks the frames again.
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

-- Offsets for db.x/db.y from where the frame was dropped, in the frame's
-- own scale (that is how SetPoint reads them).
local function dropOffsets(f)
    local s = f:GetEffectiveScale()
    if f.anchorFrame then
        local a = f.anchorFrame
        local as = a:GetEffectiveScale()
        return (f:GetLeft() * s - a:GetRight() * as) / s, (f:GetTop() * s - a:GetTop() * as) / s
    end
    local us = UIParent:GetEffectiveScale()
    local x = f:GetLeft()
    local y = f:GetTop() - UIParent:GetTop() * us / s
    if f.key == "raid" then
        -- back from this member to its group's origin, then to the raid's
        local mx, my = UF.RaidMemberOffset(f.raidSlot or 1)
        x, y = x - mx, y - my
        if f.db.separateGroups then return x, y end
        local gx, gy = UF.RaidGridOrigin(f.raidGroup or 1)
        return x - (gx - f.db.x), y - (gy - f.db.y)
    end
    if f.index and f.index > 1 then
        y = y + (f.index - 1) * (f.db.height + (f.db.spacing or 0))
    end
    return x, y
end

-- Frames that move together with f: the whole party, the whole raid, or
-- f's raid group when groups are moved separately.
local function siblings(f)
    local list = {}
    if f.key ~= "party" and f.key ~= "raid" then return list end
    for _, s in ipairs(UF.byKey[f.key] or {}) do
        if s ~= f and s:IsShown() then
            if f.key ~= "raid" or not f.db.separateGroups or s.raidGroup == f.raidGroup then
                table.insert(list, s)
            end
        end
    end
    return list
end

local function onDragStart(f)
    if InCombatLockdown() then return end
    -- Hang the others on the dragged frame, keeping their distance, so the
    -- whole block moves while dragging. Layout puts them back on UIParent.
    for _, s in ipairs(siblings(f)) do
        local dx, dy = s:GetLeft() - f:GetLeft(), s:GetTop() - f:GetTop()
        s:ClearAllPoints()
        s:SetPoint("TOPLEFT", f, "TOPLEFT", dx, dy)
    end
    f:StartMoving()
end

local function onDragStop(f)
    f:StopMovingOrSizing()
    -- Our profile stores the position, not the client's layout cache.
    pcall(f.SetUserPlaced, f, false)
    if InCombatLockdown() then return end
    local x, y = dropOffsets(f)
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    if f.key == "raid" and f.db.separateGroups then
        f.db.groupPos = f.db.groupPos or {}
        f.db.groupPos[f.raidGroup or 1] = { x = x, y = y }
    else
        f.db.x, f.db.y = x, y
    end
    ns:ApplyKey(f.key)
    if ns.Options then ns.Options:Refresh() end
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

-- Also called by UF.Apply while config mode is on.
function ns.UnlockFrame(f)
    UF.Unwatch(f)
    if not f.db.enabled then
        f:Hide()
        return
    end
    standIn(f, true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", onDragStart)
    f:SetScript("OnDragStop", onDragStop)
    overlay(f):Show()
    local label = ns.unitLabels[f.key] or f.key
    if f.key == "raid" then
        -- one label per group, on its first member
        label = (f.raidSlot == 1) and ("Grp " .. (f.raidGroup or 1)) or nil
    elseif f.index then
        label = label .. " " .. f.index
    end
    f.moverLabel:SetText(label or "")
    f.moverLabel:SetShown(label ~= nil)
    f:Show()
    f:SetAlpha(1)
    UF.Update(f)
    if ns.CastBar then ns.CastBar.Preview(f, true) end
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
    if ns.CastBar then ns.CastBar.Preview(f, false) end
    UF.Watch(f)
    if f.db.enabled then UF.UnitChanged(f) end
end

function ns:SetLocked(locked)
    if InCombatLockdown() then
        ns:Print("Not in combat.")
        return
    end
    ns.unlocked = not locked
    ns.db.locked = locked
    for _, f in pairs(UF.frames) do
        if locked then lockFrame(f) else ns.UnlockFrame(f) end
    end
    if locked then
        ns:Print("Frames locked.")
    else
        ns:Print("Frames unlocked: drag them with the left mouse button. |cffffff00/fuf lock|r when done.")
    end
    if ns.Options then ns.Options:Refresh() end
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

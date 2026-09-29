-- FUF / Frames / Blizzard
--
-- Silences Blizzard's own unit frames when ours replace them.
--
-- Hide() is not enough: Edit Mode and Blizzard's update code show them
-- again. The frame goes to a hidden parent with its events off. Frames that
-- Blizzard loads into the secure environment refuse UnregisterAllEvents from
-- addon code ("forbidden aspect 'EventRegistrations'"), so every call is
-- wrapped in pcall; hidden with their parent they stay silent anyway.
--
-- PlayerFrame keeps its parent because PetFrame is its child: only its
-- content containers are hidden. Showing Blizzard's frames again needs a
-- /reload (as in Luna).
local _, ns = ...

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local silenced = {}

local function unregisterTree(frame, skip)
    if not frame or frame == skip then return end
    if frame.UnregisterAllEvents then pcall(frame.UnregisterAllEvents, frame) end
    local kids = { frame:GetChildren() }
    for i = 1, #kids do unregisterTree(kids[i], skip) end
end

local function keepHidden(region)
    if silenced[region] then return end
    silenced[region] = true
    hooksecurefunc(region, "Show", function(self)
        C_Timer.After(0, function()
            if not InCombatLockdown() then self:Hide() end
        end)
    end)
end

local function silencePlayer()
    local pf = _G.PlayerFrame
    if not pf then return end
    unregisterTree(pf, _G.PetFrame)
    pf:EnableMouse(false)
    for _, key in ipairs({ "PlayerFrameContainer", "PlayerFrameContent" }) do
        local c = pf[key]
        if c then
            c:Hide()
            keepHidden(c)
        end
    end
end

local function silenceWhole(frame)
    if not frame then return end
    unregisterTree(frame)
    frame:Hide()
    frame:SetParent(hiddenParent)
    if not silenced[frame] then
        silenced[frame] = true
        -- Something (Edit Mode) may re-parent it; put it back.
        hooksecurefunc(frame, "SetParent", function(self, parent)
            if parent ~= hiddenParent then
                ns:RunOutOfCombat(function() self:SetParent(hiddenParent) end)
            end
        end)
    end
end

local SILENCER = {
    player = silencePlayer,
    target = function() silenceWhole(_G.TargetFrame) end,
    -- Blizzard's target-of-target frame is a child of TargetFrame.
    targettarget = function() silenceWhole(_G.TargetFrame and _G.TargetFrame.totFrame) end,
}

local done = {}

function ns:HideBlizzard(unit)
    local fn = SILENCER[unit]
    if not fn or done[unit] then return end
    ns:RunOutOfCombat(function()
        if done[unit] then return end
        done[unit] = true
        local ok, err = pcall(fn)
        if not ok then
            ns:Print("Could not hide Blizzard's %s frame: %s", unit, tostring(err))
        end
    end)
end

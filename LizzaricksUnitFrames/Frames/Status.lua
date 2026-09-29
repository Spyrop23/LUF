-- LizzaricksUnitFrames / Frames / Status
--
-- Luna's status indicator on the player frame: crossed swords in combat,
-- the animated "Zzz" while resting. Combat wins over resting.
--
-- Both come from readable sources: InCombatLockdown / PLAYER_REGEN_* and
-- IsResting / PLAYER_UPDATE_RESTING. The art is Blizzard's own (Forever's
-- PlayerFrame uses the same atlases, PlayerFrame.xml:344 and :401).
local _, ns = ...

local ST = {}
ns.Status = ST

ST.supported = { player = true }

ST.POINTS = {
    { "TOPLEFT", "Top left" }, { "TOP", "Top" }, { "TOPRIGHT", "Top right" },
    { "LEFT", "Left" }, { "CENTER", "Center" }, { "RIGHT", "Right" },
    { "BOTTOMLEFT", "Bottom left" }, { "BOTTOM", "Bottom" }, { "BOTTOMRIGHT", "Bottom right" },
}

local frames = {}

function ST.Create(f)
    if not ST.supported[f.key] then return end
    local holder = CreateFrame("Frame", nil, f)
    holder:SetFrameLevel(f:GetFrameLevel() + 12)

    local combat = holder:CreateTexture(nil, "OVERLAY")
    combat:SetAtlas("UI-HUD-UnitFrame-Player-CombatIcon")
    combat:SetAllPoints(holder)
    combat:Hide()

    local rest = holder:CreateTexture(nil, "OVERLAY")
    rest:SetAtlas("UI-HUD-UnitFrame-Player-Rest-Flipbook")
    rest:SetPoint("CENTER", holder, "CENTER")
    rest:Hide()
    local anim = rest:CreateAnimationGroup()
    anim:SetLooping("REPEAT")
    local flip = anim:CreateAnimation("FlipBook")
    flip:SetDuration(1.5)
    flip:SetFlipBookRows(7)
    flip:SetFlipBookColumns(6)
    flip:SetFlipBookFrames(42)

    f.status = { holder = holder, combat = combat, rest = rest, anim = anim }
    frames[f] = true
end

-- Size and anchor (protected context: called from UF.Layout).
function ST.Layout(f)
    local s = f.status
    if not s then return end
    local db = f.db.status
    if not db or not db.enabled then
        s.holder:Hide()
        return
    end
    s.holder:ClearAllPoints()
    s.holder:SetPoint("CENTER", f, db.point or "BOTTOMLEFT", 0, 0)
    s.holder:SetSize(db.size, db.size)
    s.rest:SetSize(db.size * 1.5, db.size * 1.5)   -- the Zzz art has air around it
    s.holder:Show()
    ST.Update(f)
end

function ST.Update(f)
    local s = f.status
    if not s or not s.holder:IsShown() then return end
    local inCombat = InCombatLockdown() or ns.inCombat
    local resting = not inCombat and IsResting and IsResting()
    s.combat:SetShown(inCombat and true or false)
    s.rest:SetShown(resting and true or false)
    if resting then
        if not s.anim:IsPlaying() then s.anim:Play() end
    else
        s.anim:Stop()
    end
end

local function updateAll()
    for f in pairs(frames) do ST.Update(f) end
end

-- REGEN_DISABLED arrives just before the lockdown starts, so remember it.
ns:RegisterEvent("PLAYER_REGEN_DISABLED", function() ns.inCombat = true; updateAll() end)
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function() ns.inCombat = false; updateAll() end)
ns:RegisterEvent("PLAYER_UPDATE_RESTING", updateAll)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", updateAll)

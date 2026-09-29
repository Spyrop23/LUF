-- FUF / Frames / Units
--
-- Spawns the single-unit frames from the profile.
local _, ns = ...

ns.unitOrder = { "player", "target", "targettarget", "targettargettarget" }

ns.unitLabels = {
    player = "Player",
    target = "Target",
    targettarget = "Target of Target",
    targettargettarget = "Target of Target of Target",
}

local function spawnAll()
    for _, unit in ipairs(ns.unitOrder) do
        local db = ns.db.units[unit]
        local f = ns.UF.frames[unit]
        if f then
            ns.UF.Apply(f, db)
        else
            ns.UF.Create(unit, db)
        end
        if db.enabled and db.hideBlizzard then
            ns:HideBlizzard(unit)
        end
    end
end

ns:OnLogin(function()
    ns:RunOutOfCombat(spawnAll)
end)

-- A profile switch re-applies every frame, once we may touch them.
function ns:OnProfileChanged()
    if not ns.UF.frames.player then return end -- first load: spawnAll follows
    ns:RunOutOfCombat(spawnAll)
end

-- The client re-applies saved positions late after a reload (at login,
-- entering the world and again ~2 s later); lay ours out once more after.
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(2.5, function()
        ns:RunOutOfCombat(function()
            for _, f in pairs(ns.UF.frames) do ns.UF.Layout(f) end
        end)
    end)
end)

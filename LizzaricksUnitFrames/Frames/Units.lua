-- LizzaricksUnitFrames / Frames / Units
--
-- Which frames exist and in what order they are built. Party frames are
-- four fixed SecureUnitButtons (party1..4) instead of a group header: the
-- header's snippets need loadstring_untainted, which the Forever beta lacks.
-- The raid works the same way: raid1..40, sorted into subgroup columns out
-- of combat (UF.ArrangeRaid).
local _, ns = ...

-- Settings keys in menu order, with their labels.
ns.unitKeys = {
    "player", "pet", "pettarget", "target", "targettarget", "targettargettarget",
    "party", "partypet", "raid",
}

ns.unitLabels = {
    player = "Player",
    pet = "Pet",
    pettarget = "Pet Target",
    target = "Target",
    targettarget = "Target of Target",
    targettargettarget = "Target of Target of Target",
    party = "Party",
    partypet = "Party Pets",
    raid = "Raid",
}

local function spawnAll()
    local UF = ns.UF
    for _, unit in ipairs({ "player", "pet", "pettarget", "target", "targettarget", "targettargettarget" }) do
        if UF.frames[unit] then UF.Apply(UF.frames[unit]) else UF.Create(unit) end
    end
    for i = 1, 4 do
        local unit = "party" .. i
        local f = UF.frames[unit]
        if f then UF.Apply(f) else f = UF.Create(unit, { key = "party", index = i }) end
        local petUnit = "partypet" .. i
        if UF.frames[petUnit] then
            UF.Apply(UF.frames[petUnit])
        else
            UF.Create(petUnit, { key = "partypet", index = i, anchorFrame = f })
        end
    end
    for i = 1, 40 do
        local unit = "raid" .. i
        if UF.frames[unit] then UF.Apply(UF.frames[unit]) else UF.Create(unit, { key = "raid", index = i }) end
    end
    UF.ArrangeRaid()
    for _, key in ipairs(ns.unitKeys) do
        ns:HideBlizzard(key)
    end
end

-- Who is in which subgroup changes with the roster; frames move out of combat.
ns:RegisterEvent("GROUP_ROSTER_UPDATE", function()
    if ns.UF.byKey.raid then ns:RunOutOfCombat(ns.UF.ArrangeRaid) end
end)

ns:OnLogin(function()
    ns:RunOutOfCombat(spawnAll)
end)

-- A profile switch re-applies every frame, once we may touch them.
function ns:OnProfileChanged()
    if not ns.UF.frames.player then return end -- first load: spawnAll follows
    ns:RunOutOfCombat(spawnAll)
    if ns.Options then ns.Options:Refresh() end
end

-- The client re-applies saved positions late after a reload (at login,
-- entering the world and again ~2 s later); lay ours out once more after.
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(2.5, function()
        ns:RunOutOfCombat(function()
            for _, f in pairs(ns.UF.frames) do ns.UF.Layout(f) end
            ns.UF.ArrangeRaid()
        end)
    end)
end)

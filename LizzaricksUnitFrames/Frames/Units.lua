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
    "party", "partypet", "partytarget", "raid",
    "maintank", "maintanktarget", "mainassist", "mainassisttarget",
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
    partytarget = "Party Targets",
    raid = "Raid",
    maintank = "Main Tank",
    maintanktarget = "Main Tank Target",
    mainassist = "Main Assist",
    mainassisttarget = "Main Assist Target",
}

-- Main tank / main assist frames: how many, and their raid role.
local ROLE_FRAMES = {
    { key = "maintank", role = "MAINTANK", count = 4 },
    { key = "mainassist", role = "MAINASSIST", count = 2 },
}

-- raidN units with the role, in raid order (only in a raid; the role is
-- the 10th value of GetRaidRosterInfo).
local function raidMembersWithRole(role)
    local list = {}
    if not (IsInRaid and IsInRaid()) or not GetRaidRosterInfo then return list end
    for i = 1, 40 do
        local ok, r = pcall(function() return (select(10, GetRaidRosterInfo(i))) end)
        if ok and ns.CanRead(r) and r == role then table.insert(list, "raid" .. i) end
    end
    return list
end

-- Points the main tank / assist frames (and their targets) at the members
-- that have the role right now. Out of combat.
function ns.AssignRaidRoles()
    local UF = ns.UF
    for _, rf in ipairs(ROLE_FRAMES) do
        local members = raidMembersWithRole(rf.role)
        for i, f in ipairs(UF.byKey[rf.key] or {}) do
            UF.SetUnit(f, members[i] or "none")
        end
        for i, f in ipairs(UF.byKey[rf.key .. "target"] or {}) do
            UF.SetUnit(f, members[i] and (members[i] .. "target") or "none")
        end
    end
end

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
        local targetUnit = "party" .. i .. "target"
        if UF.frames[targetUnit] then
            UF.Apply(UF.frames[targetUnit])
        else
            UF.Create(targetUnit, { key = "partytarget", index = i, anchorFrame = f })
        end
    end
    for i = 1, 40 do
        local unit = "raid" .. i
        if UF.frames[unit] then UF.Apply(UF.frames[unit]) else UF.Create(unit, { key = "raid", index = i }) end
    end
    UF.ArrangeRaid()
    -- main tanks / assists: fixed frames that follow the raid roles
    for _, rf in ipairs(ROLE_FRAMES) do
        for i = 1, rf.count do
            local id = rf.key .. i
            local f = UF.frames[id]
            if f then UF.Apply(f) else f = UF.Create(id, { key = rf.key, index = i }) end
            local tid = rf.key .. "target" .. i
            if UF.frames[tid] then
                UF.Apply(UF.frames[tid])
            else
                UF.Create(tid, { key = rf.key .. "target", index = i, anchorFrame = f })
            end
        end
    end
    ns.AssignRaidRoles()
    for _, key in ipairs(ns.unitKeys) do
        ns:HideBlizzard(key)
    end
end

-- Who is in which subgroup changes with the roster; frames move out of combat.
ns:RegisterEvent("GROUP_ROSTER_UPDATE", function()
    if ns.UF.byKey.raid then ns:RunOutOfCombat(ns.UF.ArrangeRaid) end
    if ns.UF.byKey.maintank then ns:RunOutOfCombat(ns.AssignRaidRoles) end
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

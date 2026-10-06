-- LizzaricksUnitFrames / Frames / Indicators
--
-- Luna's small icons on a unit frame: raid target mark, class, group
-- leader, raid assistant, master looter, PvP flag, incoming resurrection, group role and
-- the elite dragon. Each has on/off, size, anchor point and offset; the elite dragon
-- sits on one side of the frame.
--
-- Secrets: the raid mark index is secret, so it goes straight into the
-- texture (SetSpriteSheetCell) and only its existence is tested. Yes/no
-- values that may be secret (leader, resurrection, master looter) drive the
-- icon's alpha through SetAlphaFromBoolean. Class and faction are used only
-- when readable; otherwise the icon stays hidden.
local _, ns = ...

local IN = {}
ns.Indicators = IN

IN.POINTS = {
    { "TOPLEFT", "Top left" }, { "TOP", "Top" }, { "TOPRIGHT", "Top right" },
    { "LEFT", "Left" }, { "CENTER", "Center" }, { "RIGHT", "Right" },
    { "BOTTOMLEFT", "Bottom left" }, { "BOTTOM", "Bottom" }, { "BOTTOMRIGHT", "Bottom right" },
}
IN.SIDES = { { "LEFT", "Left" }, { "RIGHT", "Right" } }

-- key, label (order of the options page)
IN.KINDS = {
    { "raidTarget", "Raid target icon" },
    { "class", "Class" },
    { "masterLooter", "Master looter" },
    { "leader", "Leader" },
    { "assistant", "Raid assistant" },
    { "mainTank", "Main tank" },
    { "mainAssist", "Main assist" },
    { "pvp", "Player vs. Player" },
    { "resurrect", "Resurrections" },
    { "role", "Role (tank, healer, damage)" },
}

local RAID_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local MASTER_LOOTER = "Interface\\GroupFrame\\UI-Group-MasterLooter"
local ASSISTANT = "Interface\\GroupFrame\\UI-Group-AssistantIcon"
local CLASS_ATLAS = "UI-HUD-UnitFrame-Player-Portrait-ClassIcon-"
local ROLE_ATLAS = { TANK = "roleicon-tiny-tank", HEALER = "roleicon-tiny-healer", DAMAGER = "roleicon-tiny-dps" }

local function try(obj, method, ...)
    local f = obj and obj[method]
    if not f then return false end
    return (pcall(f, obj, ...))
end

local function call(fn, ...)
    if not fn then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
end

-- Shows the icon when `value` is true; `value` may be secret.
local function showIf(tex, value)
    if type(value) == "nil" then tex:Hide() return end
    tex:Show()
    if not try(tex, "SetAlphaFromBoolean", value, 1, 0) then
        tex:SetAlpha((ns.CanRead(value) and value) and 1 or 0)
    end
end

local frames = {}

function IN.Create(f)
    local holder = CreateFrame("Frame", nil, f)
    holder:SetAllPoints(f)
    holder:SetFrameLevel(f:GetFrameLevel() + 14)
    local icons = {}
    for _, k in ipairs(IN.KINDS) do
        icons[k[1]] = holder:CreateTexture(nil, "OVERLAY")
        icons[k[1]]:Hide()
    end
    icons.raidTarget:SetTexture(RAID_ICONS)
    icons.leader:SetAtlas("UI-HUD-UnitFrame-Player-Group-LeaderIcon")
    if not icons.masterLooter:SetTexture(MASTER_LOOTER) then
        icons.masterLooter:SetAtlas("Coin-Gold")
    end
    if not icons.assistant:SetTexture(ASSISTANT) then
        icons.assistant:SetAtlas("friends-icon-raidAssist")
    end
    icons.mainTank:SetAtlas("RaidFrame-Icon-MainTank")
    icons.mainAssist:SetAtlas("RaidFrame-Icon-MainAssist")
    icons.resurrect:SetAtlas("RaidFrame-Icon-Rez")
    -- pictures for the config-mode preview until real data sets them
    icons.role:SetAtlas(ROLE_ATLAS.TANK)
    icons.pvp:SetAtlas("UI-HUD-UnitFrame-Player-PVP-FFAIcon")
    icons.class:SetAtlas(CLASS_ATLAS .. "Warrior")
    icons.elite = holder:CreateTexture(nil, "ARTWORK")
    icons.elite:Hide()
    f.indicators = { holder = holder, icons = icons }
    frames[f] = true
end

-- Geometry (protected context: called from UF.Layout).
function IN.Layout(f)
    local ind = f.indicators
    if not ind then return end
    local all = f.db.indicators
    for _, k in ipairs(IN.KINDS) do
        local tex, d = ind.icons[k[1]], all[k[1]]
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", f, d.point, d.x or 0, d.y or 0)
        tex:SetSize(d.size, d.size)
    end
    -- the dragon hangs off the chosen side, facing outwards
    local e, d = ind.icons.elite, all.elite
    local h = f.db.height * (d.scale or 1.6)
    e:ClearAllPoints()
    e:SetSize(h * 1.2, h)
    local x, y = d.x or 0, d.y or 0
    if d.side == "LEFT" then
        e:SetPoint("CENTER", f, "LEFT", x, y)
    else
        e:SetPoint("CENTER", f, "RIGHT", x, y)
    end
    IN.Update(f)
end

-- ------------------------------------------------------------ update --

local function masterLooterUnit()
    if not (C_PartyInfo and C_PartyInfo.GetLootMethod) then return nil end
    local method, partyID, raidID = call(C_PartyInfo.GetLootMethod)
    if not (ns.CanRead(method) and Enum.LootMethod and method == Enum.LootMethod.Masterlooter) then return nil end
    if ns.CanRead(raidID) and raidID and IsInRaid() then return "raid" .. raidID end
    if ns.CanRead(partyID) and partyID then return partyID == 0 and "player" or "party" .. partyID end
end

local UPDATE = {}

-- One mark out of the 4x4 sheet; the index may be secret.
local function setRaidCell(tex, index)
    if try(tex, "SetSpriteSheetCell", index, 4, 4) then return true end
    if not (ns.CanRead(index) and type(index) == "number") then return false end
    local i = index - 1
    tex:SetTexCoord((i % 4) / 4, (i % 4 + 1) / 4, math.floor(i / 4) / 4, (math.floor(i / 4) + 1) / 4)
    return true
end

function UPDATE.raidTarget(tex, unit)
    local index = call(GetRaidTargetIndex, unit)
    if type(index) == "nil" or not setRaidCell(tex, index) then tex:Hide() return end
    tex:Show()
end

function UPDATE.class(tex, unit)
    local isPlayer = call(UnitIsPlayer, unit)
    local _, token = call(UnitClass, unit)
    if not (ns.CanRead(isPlayer) and isPlayer and ns.CanRead(token) and type(token) == "string") then
        tex:Hide()
        return
    end
    tex:SetAtlas(CLASS_ATLAS .. token:sub(1, 1) .. token:sub(2):lower())
    tex:Show()
end

function UPDATE.leader(tex, unit)
    showIf(tex, call(UnitIsGroupLeader, unit))
end

-- Raid assistants (the leader has its own icon). The yes/no may be secret.
function UPDATE.assistant(tex, unit)
    showIf(tex, call(UnitIsGroupAssistant, unit))
end

-- Main tank / main assist (raid roles set by the leader). GetPartyAssignment
-- answers yes/no (possibly secret); without it the roster's role is used.
local function hasRaidRole(unit, role)
    if GetPartyAssignment then
        local ok, v = pcall(GetPartyAssignment, role, unit)
        if ok and type(v) ~= "nil" then return v end
    end
    local index = call(UnitInRaid, unit)
    if not (ns.CanRead(index) and type(index) == "number") or not GetRaidRosterInfo then return false end
    local ok, r = pcall(function() return (select(10, GetRaidRosterInfo(index))) end)
    return ok and ns.CanRead(r) and r == role or false
end

function UPDATE.mainTank(tex, unit)
    showIf(tex, hasRaidRole(unit, "MAINTANK"))
end

function UPDATE.mainAssist(tex, unit)
    showIf(tex, hasRaidRole(unit, "MAINASSIST"))
end

function UPDATE.masterLooter(tex, unit)
    local looter = masterLooterUnit()
    if not looter then tex:Hide() return end
    showIf(tex, call(UnitIsUnit, unit, looter))
end

function UPDATE.pvp(tex, unit)
    local ffa, flagged = call(UnitIsPVPFreeForAll, unit), call(UnitIsPVP, unit)
    local faction = call(UnitFactionGroup, unit)
    if ns.CanRead(ffa) and ffa then
        tex:SetAtlas("UI-HUD-UnitFrame-Player-PVP-FFAIcon")
        tex:Show()
    elseif ns.CanRead(flagged) and flagged and ns.CanRead(faction)
        and (faction == "Horde" or faction == "Alliance") then
        tex:SetAtlas("UI-HUD-UnitFrame-Player-PVP-" .. faction .. "Icon")
        tex:Show()
    else
        tex:Hide()
    end
end

function UPDATE.role(tex, unit)
    local role = call(UnitGroupRolesAssigned, unit)
    local atlas = ns.CanRead(role) and ROLE_ATLAS[role]
    if not atlas then tex:Hide() return end
    tex:SetAtlas(atlas)
    tex:Show()
end

function UPDATE.resurrect(tex, unit)
    showIf(tex, call(UnitHasIncomingResurrection, unit))
end

local ELITE = {
    worldboss = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged",
    elite = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged",
    rareelite = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged",
    rare = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged",
}

local function updateElite(tex, unit, d)
    local atlas
    if ns.unlocked then
        atlas = ELITE.elite   -- config mode: show where the dragon goes
    else
        local class = call(UnitClassification, unit)
        atlas = ns.CanRead(class) and ELITE[class]
    end
    if not atlas then tex:Hide() return end
    tex:SetAtlas(atlas)
    -- Blizzard's art faces left; mirror it for the right side, and once more
    -- when "Mirror" is ticked. On an atlas texture the coordinates count
    -- within the atlas' own piece (0..1), so they are always set to fixed
    -- values: the atlas' absolute corners showed an empty area (0.13.0), and
    -- swapping the current corners flipped it on every update.
    local mirror = d.side ~= "LEFT"
    if d.flip then mirror = not mirror end
    if mirror then tex:SetTexCoord(1, 0, 0, 1) else tex:SetTexCoord(0, 1, 0, 1) end
    tex:Show()
end

function IN.Update(f)
    local ind = f.indicators
    if not ind then return end
    local all, unit = f.db.indicators, f.unit
    local exists = ns.unlocked or call(UnitExists, unit)
    for _, k in ipairs(IN.KINDS) do
        local tex, d = ind.icons[k[1]], all[k[1]]
        if not (d.enabled and exists) then
            tex:Hide()
        elseif ns.unlocked then
            -- config mode: show where the icons go (the raid mark: the real
            -- one if the unit has one, else a skull - never the whole sheet)
            if k[1] == "raidTarget" then
                local index = call(GetRaidTargetIndex, unit)
                if type(index) == "nil" or not setRaidCell(tex, index) then setRaidCell(tex, 8) end
            end
            tex:SetAlpha(1)
            tex:Show()
        else
            UPDATE[k[1]](tex, unit, d)
        end
    end
    if all.elite.enabled and exists then
        updateElite(ind.icons.elite, unit, all.elite)
    else
        ind.icons.elite:Hide()
    end
end

IN.Refresh = IN.Update

local function updateAll()
    for f in pairs(frames) do
        if f:IsVisible() then IN.Update(f) end
    end
end

for _, event in ipairs({ "RAID_TARGET_UPDATE", "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED",
    "PARTY_LOOT_METHOD_CHANGED", "UNIT_FACTION", "PLAYER_FLAGS_CHANGED", "INCOMING_RESURRECT_CHANGED",
    "UNIT_CLASSIFICATION_CHANGED", "PLAYER_ROLES_ASSIGNED" }) do
    ns:RegisterEvent(event, updateAll)
end

-- Target of target and friends get no events of their own.
local ticker = CreateFrame("Frame")
local wait = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    wait = wait + elapsed
    if wait < 0.5 then return end
    wait = 0
    updateAll()
end)

-- LizzaricksUnitFrames / Frames / Auras
--
-- Buffs and debuffs on a unit frame, shown by the client's own aura
-- container (CustomAuraContainerTemplate).
--
-- Not a single aura is read here. In combat C_UnitAuras throws at addon code,
-- so the client is told WHAT to show (a filter string such as "HELPFUL|PLAYER")
-- and it creates, filters, sorts, lays out and times the buttons itself,
-- tooltips included, in and out of combat. We own geometry and styling.
--
-- Rules of the container (seen in the client by other Forever addons):
--   * create it, add EVERY group it will ever have, and only THEN SetUnit;
--     a group added later renders nothing. A switched-off group is parked at
--     a frame count of zero;
--   * the buttons carry no size of their own: the initialiser must SetSize
--     them, or they stay 0x0 without any error;
--   * the initialiser is the only moment a button may be touched; a changed
--     setting builds a NEW container instead of editing live buttons.
local _, ns = ...

local AU = {}
ns.Auras = AU

-- Settings keys with auras. Polled units (target of target ...) get no aura
-- events from the client, so they have none.
AU.supported = { player = true, pet = true, target = true, party = true, partypet = true }

local F = AuraUtil and AuraUtil.AuraFilters or {}
local HELPFUL, HARMFUL = F.Helpful or "HELPFUL", F.Harmful or "HARMFUL"
local PLAYER, RAID = F.Player or "PLAYER", F.Raid or "RAID"

local function filter(...)
    if AuraUtil and AuraUtil.CreateFilterString then
        return AuraUtil.CreateFilterString(...)
    end
    return table.concat({ ... }, "|")
end

local BUFF_FILTERS = {
    all = function() return filter(HELPFUL) end,
    own = function() return filter(HELPFUL, PLAYER) end,
    raid = function() return filter(HELPFUL, RAID) end,     -- ones you can cast
}
local DEBUFF_FILTERS = {
    all = function() return filter(HARMFUL) end,
    own = function() return filter(HARMFUL, PLAYER) end,
    raid = function() return filter(HARMFUL, RAID) end,     -- ones you can dispel
}

-- Debuff border colours by dispel type (Blizzard's DebuffTypeColor).
local DISPEL_COLORS = {
    Magic   = { 0.20, 0.60, 1.00 },
    Curse   = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison  = { 0.00, 0.60, 0.00 },
    Bleed   = { 1.00, 0.00, 0.00 },
}

-- Every engine call is wrapped: a refusal costs that one feature only.
local function try(obj, method, ...)
    local f = obj and obj[method]
    if not f then return false end
    return (pcall(f, obj, ...))
end

local available   -- nil = not asked yet
local function canBuild()
    if available == nil then
        local ok, c = pcall(CreateFrame, "AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
        available = (ok and c) and true or false
        if c then c:Hide() end
    end
    return available
end

-- Compact remaining time: "36", "58m", "2h" (the client's default reads
-- "58 m" and runs into the next icon). The client formats the secret time.
local durationFormatter
local function compactFormatter()
    if durationFormatter ~= nil then return durationFormatter or nil end
    durationFormatter = false
    if not (C_StringUtil and C_StringUtil.CreateNumericRuleFormatter) then return nil end
    local ok, f = pcall(C_StringUtil.CreateNumericRuleFormatter)
    if not ok or not f then return nil end
    local up = Enum.NumericRuleFormatRounding and Enum.NumericRuleFormatRounding.Up
    -- rounding belongs on the component, or 91 s would read "2m"
    if not pcall(f.SetBreakpoints, f, {
        { threshold = 0, format = "%d" },
        { threshold = 60, format = "%dm", components = { { div = 60, rounding = up } } },
        { threshold = 3600, format = "%dh", components = { { div = 3600, rounding = up } } },
        { threshold = 86400, format = "%dd", components = { { div = 86400, rounding = up } } },
    }) then return nil end
    durationFormatter = f
    return f
end

-- ------------------------------------------------------------ buttons --

local function initializer(db, debuffs)
    local size = debuffs and (db.debuffSize or db.size) or db.size
    return function(button)
        button:SetSize(size, size)

        local border = button:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints(button)
        border:SetColorTexture(0, 0, 0, 1)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        try(button, "SetIcon", icon)

        if debuffs and db.dispelColors and CreateColor and Enum.CustomAuraButtonDispelTypeTextureStyle then
            -- A coloured frame behind the icon; the client decides per button
            -- whether and in which colour it shows (the type stays secret).
            local dispel = button:CreateTexture(nil, "BORDER")
            dispel:SetAllPoints(button)
            dispel:SetColorTexture(1, 1, 1, 1)
            dispel:Hide()
            local map = {}
            for k, c in pairs(DISPEL_COLORS) do map[k] = CreateColor(c[1], c[2], c[3], 1) end
            try(button, "AddDispelTypeTexture", dispel, {
                style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
                showWhenHarmful = true,
                showWhenHelpful = false,
                customDispelColorMap = map,
            })
        end

        if db.swipe then
            local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            cd:SetAllPoints(icon)
            cd:SetReverse(true)
            cd:SetDrawEdge(false)
            cd:SetHideCountdownNumbers(true)
            try(button, "SetDurationCooldown", cd)
        end

        -- Fonts before the engine is told about the strings: an unstyled
        -- FontString errors inside the engine.
        local stacks = button:CreateFontString(nil, "OVERLAY")
        stacks:SetFont(ns.media.font, math.max(7, math.floor(size * 0.5)), "OUTLINE")
        stacks:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, 0)
        try(button, "SetApplicationCount", stacks, {})

        if db.duration then
            local text = button:CreateFontString(nil, "OVERLAY")
            text:SetFont(ns.media.font, math.max(6, math.floor(size * 0.45)), "OUTLINE")
            text:SetPoint("TOP", button, "BOTTOM", 0, 1)
            local f = compactFormatter()
            if not (f and try(button, "SetDurationText", text, { textFormatter = f })) then
                try(button, "SetDurationText", text, {})   -- the client's own wording
            end
        end

        -- Hover shows the client's tooltip; clicks go through to the frame.
        try(button, "SetMouseClickEnabled", false)
        try(button, "SetMouseMotionEnabled", true)
    end
end

-- ------------------------------------------------------------ layout --

local DIR = AnchorUtil and AnchorUtil.FlowDirection

-- Where the container sits and which way it grows, by position setting.
-- gap: space to keep free next to the frame (e.g. for the cast bar).
local function place(c, f, db, gapBelow, gapAbove)
    local pos, spacing = db.position, db.spacing
    local size = math.max(db.size, db.debuffSize or db.size)
    c:ClearAllPoints()
    local anchor, h, v, line
    if pos == "TOP" then
        c:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2 + gapAbove)
        anchor, h, v, line = "BOTTOMLEFT", "Right", "Up", f.db.width
    elseif pos == "RIGHT" then
        c:SetPoint("TOPLEFT", f, "TOPRIGHT", 2, 0)
        anchor, h, v, line = "TOPLEFT", "Right", "Down", db.perRow * (size + spacing)
    elseif pos == "LEFT" then
        c:SetPoint("TOPRIGHT", f, "TOPLEFT", -2, 0)
        anchor, h, v, line = "TOPRIGHT", "Left", "Down", db.perRow * (size + spacing)
    else -- BOTTOM
        c:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -2 - gapBelow)
        anchor, h, v, line = "TOPLEFT", "Right", "Down", f.db.width
    end
    try(c, "SetFlowLayoutPadding", 0, 0, 0, 0)
    if DIR then try(c, "SetFlowLayoutGrowthDirection", DIR[h], DIR[v]) end
    try(c, "SetFlowLayoutAnchorPoint", anchor)
    try(c, "SetFlowLayoutMaximumLineSize", line)
end

local function buildContainer(f, db)
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, f, "CustomAuraContainerTemplate")
    if not ok or not c then return nil end
    local sortMethod = _G.AuraContainerSortMethod and _G.AuraContainerSortMethod.Default
    local sortDirection = _G.AuraContainerSortDirection and _G.AuraContainerSortDirection.Normal
    local function group(debuffs)
        return {
            maxFrameCount = debuffs and (db.debuffs and db.maxDebuffs or 0) or (db.buffs and db.maxBuffs or 0),
            sortMethod = sortMethod,
            sortDirection = sortDirection,
            initializeFrame = initializer(db, debuffs),
            layout = {
                elementWidth = debuffs and db.debuffSize or db.size,
                elementHeight = (debuffs and db.debuffSize or db.size) + (db.duration and 8 or 0),
                elementSpacing = db.spacing, lineSpacing = db.spacing,
                forceNewLine = debuffs,   -- debuffs start on their own row
                groupLineSpacing = debuffs and (db.groupGap or 4) or nil,   -- gap above them
            },
        }
    end
    local buffFilter = (BUFF_FILTERS[db.buffFilter] or BUFF_FILTERS.all)()
    local debuffFilter = (DEBUFF_FILTERS[db.debuffFilter] or DEBUFF_FILTERS.all)()
    if not pcall(c.AddAuraGroup, c, "buffs", buffFilter, group(false)) then return nil end
    if not pcall(c.AddAuraGroup, c, "debuffs", debuffFilter, group(true)) then return nil end
    return c
end

-- A fingerprint of everything the container was built with; a change
-- means a new container.
local function signature(db)
    return table.concat({
        tostring(db.buffs), tostring(db.debuffs), db.size, db.debuffSize, db.spacing, db.groupGap or 4, db.maxBuffs, db.maxDebuffs,
        db.buffFilter, db.debuffFilter, tostring(db.duration), tostring(db.swipe), tostring(db.dispelColors),
    }, ":")
end

-- Called from UF.Layout (out of combat).
function AU.Layout(f)
    if not AU.supported[f.key] then return end
    local db = f.db.auras
    local wanted = db and (db.buffs or db.debuffs)

    if f.auraContainer and (not wanted or f.auraSignature ~= signature(db)) then
        -- retire the old one: no unit, hidden (containers cannot be destroyed)
        try(f.auraContainer, "SetUnit", "none")
        f.auraContainer:Hide()
        f.auraContainer = nil
    end
    if not wanted or not canBuild() then return end

    if not f.auraContainer then
        f.auraContainer = buildContainer(f, db)
        f.auraSignature = signature(db)
        if not f.auraContainer then return end
        -- only now, after every group exists
        try(f.auraContainer, "SetUnit", f.realUnit or f.unit)
    end

    local cast = f.db.castBar
    local castOn = ns.CastBar and ns.CastBar.supported[f.key] and cast and cast.enabled
    local below = (castOn and cast.position ~= "ABOVE") and (cast.height + 1) or 0
    local above = (castOn and cast.position == "ABOVE") and (cast.height + 1) or 0
    place(f.auraContainer, f, db, below, above)
    f.auraContainer:Show()
end

-- The unit behind the frame changed (new target, roster change).
function AU.Refresh(f)
    try(f.auraContainer, "UpdateAllAuras")
end

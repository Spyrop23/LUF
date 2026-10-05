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
AU.supported = { player = true, pet = true, target = true, focus = true, party = true, partypet = true }

local F = AuraUtil and AuraUtil.AuraFilters or {}
local HELPFUL, HARMFUL = F.Helpful or "HELPFUL", F.Harmful or "HARMFUL"
local PLAYER, RAID = F.Player or "PLAYER", F.Raid or "RAID"

local function filter(...)
    if AuraUtil and AuraUtil.CreateFilterString then
        return AuraUtil.CreateFilterString(...)
    end
    return table.concat({ ... }, "|")
end

-- Filter components per setting; "raid" = buffs you can cast / debuffs you
-- can dispel.
local BUFF_FILTERS = { all = { HELPFUL }, own = { HELPFUL, PLAYER }, raid = { HELPFUL, RAID } }
local DEBUFF_FILTERS = { all = { HARMFUL }, own = { HARMFUL, PLAYER }, raid = { HARMFUL, RAID } }

-- The base components plus one more ("PLAYER" or "!PLAYER": cast by you or
-- not; the client documents the "!" negation and filters in C, in combat too).
local function withExtra(parts, extra)
    local list = { unpack(parts) }
    if extra then table.insert(list, extra) end
    return filter(unpack(list))
end

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

AU.CanBuild = function() return canBuild() end

-- ------------------------------------------------------------ buttons --

local function initializer(db, debuffs, size)
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
        ns.SetFont(stacks, math.max(7, math.floor(size * 0.5)), "OUTLINE")
        stacks:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, 0)
        try(button, "SetApplicationCount", stacks, {})

        if db.duration then
            local text = button:CreateFontString(nil, "OVERLAY")
            local where = db.durationPosition or "BELOW"
            if where == "INSIDE" then
                -- in the middle of the icon, a bit larger, above the swipe
                ns.SetFont(text, math.max(7, math.floor(size * 0.5)), "OUTLINE")
                text:SetPoint("CENTER", button, "CENTER", 0, 0)
                text:SetDrawLayer("OVERLAY", 7)
            elseif where == "ABOVE" then
                ns.SetFont(text, math.max(6, math.floor(size * 0.45)), "OUTLINE")
                text:SetPoint("BOTTOM", button, "TOP", 0, -1)
            else
                ns.SetFont(text, math.max(6, math.floor(size * 0.45)), "OUTLINE")
                text:SetPoint("TOP", button, "BOTTOM", 0, 1)
            end
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

-- Where a container sits and which way it grows, by position setting.
-- size: its largest icon; grow: "RIGHT" or "LEFT" (Luna's "horizontal limit
-- side": the frame edge the icons start from above/below the frame);
-- limit: row width in % of the frame width (Luna's "horizontal limit");
-- gap: space to keep free next to the frame (e.g. for the cast bar).
-- dx/dy: the user's offset (moves the whole block).
local function place(c, f, db, pos, size, grow, limit, dx, dy, gapBelow, gapAbove)
    local spacing = db.spacing
    local width = f.db.width * (limit or 100) / 100
    local fromRight = grow == "LEFT"
    dx, dy = dx or 0, dy or 0
    c:ClearAllPoints()
    local anchor, h, v, line
    if pos == "TOP" then
        anchor = fromRight and "BOTTOMRIGHT" or "BOTTOMLEFT"
        c:SetPoint(anchor, f, fromRight and "TOPRIGHT" or "TOPLEFT", dx, 2 + gapAbove + dy)
        h, v, line = fromRight and "Left" or "Right", "Up", width
    elseif pos == "RIGHT" then
        c:SetPoint("TOPLEFT", f, "TOPRIGHT", 2 + dx, dy)
        anchor, h, v, line = "TOPLEFT", "Right", "Down", db.perRow * (size + spacing)
    elseif pos == "LEFT" then
        c:SetPoint("TOPRIGHT", f, "TOPLEFT", -2 + dx, dy)
        anchor, h, v, line = "TOPRIGHT", "Left", "Down", db.perRow * (size + spacing)
    else -- BOTTOM
        anchor = fromRight and "TOPRIGHT" or "TOPLEFT"
        c:SetPoint(anchor, f, fromRight and "BOTTOMRIGHT" or "BOTTOMLEFT", dx, -2 - gapBelow + dy)
        h, v, line = fromRight and "Left" or "Right", "Down", width
    end
    try(c, "SetFlowLayoutPadding", 0, 0, 0, 0)
    if DIR then try(c, "SetFlowLayoutGrowthDirection", DIR[h], DIR[v]) end
    try(c, "SetFlowLayoutAnchorPoint", anchor)
    try(c, "SetFlowLayoutMaximumLineSize", line)
end

-- which: "both" (one container, debuffs on their own row after the buffs),
-- "buffs" or "debuffs" (each in its own container at its own position).
local function buildContainer(f, db, which)
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, f, "CustomAuraContainerTemplate")
    if not ok or not c then return nil end
    local sortMethod = _G.AuraContainerSortMethod and _G.AuraContainerSortMethod.Default
    local sortDirection = _G.AuraContainerSortDirection and _G.AuraContainerSortDirection.Normal
    -- first: the first debuff group (in a shared container: own row, gap above)
    local function group(debuffs, size, first)
        local FL = ns.Filters
        local candidate = FL and (debuffs and FL.CandidateFilters(db.debuffList, db.debuffListMode)
            or not debuffs and FL.CandidateFilters(db.buffList, db.buffListMode)) or nil
        local newRow = first and which == "both"
        return {
            candidateFilters = candidate,
            maxFrameCount = debuffs and (db.debuffs and db.maxDebuffs or 0) or (db.buffs and db.maxBuffs or 0),
            sortMethod = sortMethod,
            sortDirection = sortDirection,
            initializeFrame = initializer(db, debuffs, size),
            layout = {
                elementWidth = size,
                -- room for the time text above or below the icon (none inside)
                elementHeight = size + ((db.duration and db.durationPosition ~= "INSIDE") and 8 or 0),
                elementSpacing = db.spacing, lineSpacing = db.spacing,
                forceNewLine = newRow,   -- debuffs start on their own row
                groupLineSpacing = newRow and (db.groupGap or 4) or nil,   -- gap above them
            },
        }
    end
    -- Luna's "bigger buffs": your own auras in a group of their own, larger;
    -- everyone else's ("!PLAYER") right after them at the normal size.
    local function add(debuffs)
        local parts = debuffs and (DEBUFF_FILTERS[db.debuffFilter] or DEBUFF_FILTERS.all)
            or (BUFF_FILTERS[db.buffFilter] or BUFF_FILTERS.all)
        local key = debuffs and "debuffs" or "buffs"
        local size = debuffs and (db.debuffSize or db.size) or db.size
        local bigger = (debuffs and db.biggerDebuffs or db.biggerBuffs) or 0
        local ownOnly = (debuffs and db.debuffFilter or db.buffFilter) == "own"
        -- the first debuff group opens the debuff row
        if bigger <= 0 then
            return pcall(c.AddAuraGroup, c, key, withExtra(parts), group(debuffs, size, debuffs))
        end
        if ownOnly then   -- only your own anyway: all of them bigger
            return pcall(c.AddAuraGroup, c, key, withExtra(parts), group(debuffs, size + bigger, debuffs))
        end
        return pcall(c.AddAuraGroup, c, key .. "Mine", withExtra(parts, PLAYER), group(debuffs, size + bigger, debuffs))
            and pcall(c.AddAuraGroup, c, key, withExtra(parts, "!" .. PLAYER), group(debuffs, size, false))
    end
    if which ~= "debuffs" and not add(false) then return nil end
    if which ~= "buffs" and not add(true) then return nil end
    return c
end

-- Debuffs at their own place (not "with the buffs" and not where the buffs are).
local function separate(db)
    local p = db.debuffPosition
    return p ~= nil and p ~= "SAME" and p ~= db.position
end

-- A fingerprint of everything the container was built with; a change
-- means a new container.
local function signature(db)
    return table.concat({
        tostring(db.buffs), tostring(db.debuffs), db.size, db.debuffSize, db.spacing, db.groupGap or 4, db.maxBuffs, db.maxDebuffs,
        db.buffFilter, db.debuffFilter, tostring(db.duration), tostring(db.swipe), tostring(db.dispelColors),
        db.buffListMode or "", db.debuffListMode or "", tostring(separate(db)),
        db.biggerBuffs or 0, db.biggerDebuffs or 0, db.durationPosition or "BELOW", ns.Font(),
        ns.Filters and ns.Filters.Get(db.buffList) and ns.Filters.Signature(db.buffList) or "",
        ns.Filters and ns.Filters.Get(db.debuffList) and ns.Filters.Signature(db.debuffList) or "",
    }, ":")
end

-- Called from UF.Layout (out of combat).
function AU.Layout(f)
    if not AU.supported[f.key] then return end
    local db = f.db.auras
    local wanted = db and (db.buffs or db.debuffs)

    if (f.auraContainer or f.debuffContainer) and (not wanted or f.auraSignature ~= signature(db)) then
        -- retire the old ones: no unit, hidden (containers cannot be destroyed)
        for _, c in pairs({ buffs = f.auraContainer, debuffs = f.debuffContainer }) do
            try(c, "SetUnit", "none")
            c:Hide()
        end
        f.auraContainer, f.debuffContainer = nil, nil
    end
    if not wanted or not canBuild() then return end

    local split = separate(db)
    if not f.auraContainer then
        -- one container for both, or buffs here and debuffs in a second one
        f.auraContainer = buildContainer(f, db, split and "buffs" or "both")
        f.debuffContainer = split and buildContainer(f, db, "debuffs") or nil
        f.auraSignature = signature(db)
        if not f.auraContainer then return end
    end

    -- only now, after every group exists; config mode swaps the unit
    ns.UF.BindAuraContainer(f.auraContainer, f)
    ns.UF.BindAuraContainer(f.debuffContainer, f)

    local cast = f.db.castBar
    local castOn = ns.CastBar and ns.CastBar.supported[f.key] and cast and cast.enabled
    local below = (castOn and cast.position ~= "ABOVE") and (cast.height + 1) or 0
    local above = (castOn and cast.position == "ABOVE") and (cast.height + 1) or 0
    -- and the class power row (player)
    local CP = ns.ClassPower
    if CP then
        below = below + CP.Reserved(f, "BELOW")
        above = above + CP.Reserved(f, "ABOVE")
    end
    local buffSize = db.size + math.max(db.biggerBuffs or 0, 0)
    local debuffSize = (db.debuffSize or db.size) + math.max(db.biggerDebuffs or 0, 0)
    if split then
        place(f.auraContainer, f, db, db.position, buffSize, db.buffGrow, db.buffLimit,
            db.buffX, db.buffY, below, above)
        if f.debuffContainer then
            place(f.debuffContainer, f, db, db.debuffPosition, debuffSize, db.debuffGrow, db.debuffLimit,
                db.debuffX, db.debuffY, below, above)
            f.debuffContainer:Show()
        end
    else
        -- together: the buffs' side, width and offset count for both
        place(f.auraContainer, f, db, db.position, math.max(buffSize, debuffSize), db.buffGrow, db.buffLimit,
            db.buffX, db.buffY, below, above)
    end
    f.auraContainer:Show()
end

-- The unit behind the frame changed (new target, roster change).
function AU.Refresh(f)
    for _, c in pairs({ buffs = f.auraContainer, debuffs = f.debuffContainer }) do
        ns.UF.BindAuraContainer(c, f)
        try(c, "UpdateAllAuras")
    end
end

-- LizzaricksUnitFrames / Frames / Squares
--
-- Luna's nine indicator squares (corners, edges, centre) on a unit frame.
--
-- Types:
--   aggro      the unit has threat (Blizzard's threat colours; readable)
--   aggrotot   the unit is your target's target and the target is hostile
--   buff / debuff / ownbuff / owndebuff
--              an aura from a list of spells (or a filter list) is on the unit
--   mybuffs    any buff you cast is on the unit
--   castable   any buff you are able to cast is on the unit
--   dispel     a debuff you can dispel, coloured by its type
--   missing    a buff from the list is MISSING (red)
--
-- Aura squares never read an aura: each is an aura SLOT of the client's
-- aura container (like the buff icons), which picks the matching aura in C,
-- also in combat. The client only matches by spell ID (names are turned into
-- IDs from your spellbook when the setting is saved), and only buffs on
-- friendly units / debuffs on hostile ones. "Missing" is a red square with
-- the buff's slot on top of it: while the buff is there, it covers the red.
local _, ns = ...

local SQ = {}
ns.Squares = SQ

SQ.supported = { player = true, pet = true, target = true, party = true, partypet = true, raid = true }

SQ.POSITIONS = {
    { "topleft", "Top left", "TOPLEFT" }, { "top", "Top", "TOP" }, { "topright", "Top right", "TOPRIGHT" },
    { "leftcenter", "Left center", "LEFT" }, { "center", "Center", "CENTER" }, { "rightcenter", "Right center", "RIGHT" },
    { "bottomleft", "Bottom left", "BOTTOMLEFT" }, { "bottom", "Bottom", "BOTTOM" }, { "bottomright", "Bottom right", "BOTTOMRIGHT" },
}

SQ.TYPES = {
    { "aggro", "Aggro" },
    { "aggrotot", "Aggro (target's target)" },
    { "buff", "Buff (from filter)" },
    { "ownbuff", "My buff (from filter)" },
    { "mybuffs", "My buffs (any)" },
    { "castable", "Castable buffs (any I can cast)" },
    { "debuff", "Debuff (from filter)" },
    { "owndebuff", "My debuff (from filter)" },
    { "dispel", "Dispellable debuff" },
    { "missing", "Missing buff (from filter)" },
}

local AURA_TYPES = { buff = true, ownbuff = true, mybuffs = true, castable = true, debuff = true, owndebuff = true, dispel = true, missing = true }
SQ.LIST_TYPES = { buff = true, ownbuff = true, debuff = true, owndebuff = true, missing = true }

local COLORS = {
    buff = { 0.20, 0.90, 0.20 }, ownbuff = { 0.30, 0.75, 1.00 },
    mybuffs = { 0.30, 0.75, 1.00 }, castable = { 1.00, 0.85, 0.20 },
    debuff = { 0.80, 0.20, 0.90 }, owndebuff = { 1.00, 0.60, 0.10 },
    dispel = { 1, 1, 1 }, missing = { 0.95, 0.10, 0.10 },
    aggrotot = { 1.00, 0.35, 0.00 },
}

local DISPEL_COLORS = {
    Magic = { 0.20, 0.60, 1.00 }, Curse = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 }, Poison = { 0.00, 0.60, 0.00 }, Bleed = { 1.00, 0.00, 0.00 },
}

local F = AuraUtil and AuraUtil.AuraFilters or {}
local HELPFUL, HARMFUL = F.Helpful or "HELPFUL", F.Harmful or "HARMFUL"
local PLAYER, RAID = F.Player or "PLAYER", F.Raid or "RAID"

local function filterFor(kind)
    local join = AuraUtil and AuraUtil.CreateFilterString or function(...) return table.concat({ ... }, "|") end
    if kind == "buff" or kind == "missing" then return join(HELPFUL) end
    if kind == "ownbuff" or kind == "mybuffs" then return join(HELPFUL, PLAYER) end
    if kind == "castable" then return join(HELPFUL, RAID) end
    if kind == "debuff" then return join(HARMFUL) end
    if kind == "owndebuff" then return join(HARMFUL, PLAYER) end
    if kind == "dispel" then return join(HARMFUL, RAID) end
end

local function try(obj, method, ...)
    local f = obj and obj[method]
    if not f then return false end
    return (pcall(f, obj, ...))
end

-- "Demon Armor; 12345" -> { [id] = true }. Names resolve through the
-- spellbook (C_Spell.GetSpellInfo knows the spells you can cast).
function SQ.ParseSpells(text)
    local ids, unknown = {}, {}
    for token in (text or ""):gmatch("[^;,]+") do
        token = token:match("^%s*(.-)%s*$")
        if token ~= "" then
            local id = tonumber(token)
            if not id and C_Spell and C_Spell.GetSpellInfo then
                local ok, info = pcall(C_Spell.GetSpellInfo, token)
                if ok and type(info) == "table" and ns.CanRead(info.spellID) then id = info.spellID end
            end
            if id then ids[id] = true else table.insert(unknown, token) end
        end
    end
    return ids, unknown
end

-- ------------------------------------------------------------ building --

local function newHolder(f)
    local h = CreateFrame("Frame", nil, f)
    h:SetFrameLevel(f:GetFrameLevel() + 15)
    h.border = h:CreateTexture(nil, "BACKGROUND")
    h.border:SetAllPoints()
    h.border:SetColorTexture(0, 0, 0, 1)
    h.tex = h:CreateTexture(nil, "ARTWORK")
    h.tex:SetPoint("TOPLEFT", 1, -1)
    h.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    h.tex:SetTexture(ns.media.background)
    return h
end

-- The engine's button, styled once. A slot button is pinned to our holder
-- frame; a group button (several icons) only gets its size, the group
-- lays it out.
local function initializer(holder, db, kind)
    return function(button)
        if holder then
            button:ClearAllPoints()
            button:SetAllPoints(holder)
        else
            button:SetSize(db.size, db.size)
        end
        local border = button:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints(button)
        border:SetColorTexture(0, 0, 0, 1)
        local inner = button:CreateTexture(nil, "ARTWORK")
        inner:SetPoint("TOPLEFT", 1, -1)
        inner:SetPoint("BOTTOMRIGHT", -1, 1)
        if db.texture or kind == "missing" then
            inner:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            try(button, "SetIcon", inner)
        else
            local c = COLORS[kind] or COLORS.buff
            inner:SetColorTexture(c[1], c[2], c[3], 1)
        end
        if kind == "dispel" and CreateColor and Enum.CustomAuraButtonDispelTypeTextureStyle then
            -- the client tints this by the (secret) dispel type
            local tint = button:CreateTexture(nil, "BORDER")
            tint:SetAllPoints(button)
            tint:SetColorTexture(1, 1, 1, 1)
            tint:Hide()
            local map = {}
            for k, c in pairs(DISPEL_COLORS) do map[k] = CreateColor(c[1], c[2], c[3], 1) end
            if not db.texture then inner:SetColorTexture(1, 1, 1, 0) end   -- the tint is the colour
            try(button, "AddDispelTypeTexture", tint, {
                style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
                showWhenHarmful = true, showWhenHelpful = false, customDispelColorMap = map,
            })
        end
        if db.timer then
            local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            cd:SetAllPoints(inner)
            cd:SetReverse(true)
            cd:SetDrawEdge(false)
            cd:SetHideCountdownNumbers(true)
            try(button, "SetDurationCooldown", cd)
        end
        try(button, "SetMouseClickEnabled", false)
        try(button, "SetMouseMotionEnabled", true)
    end
end

-- Everything an aura container was built with; a change means a new one.
local function signature(f)
    local parts = {}
    for _, pos in ipairs(SQ.POSITIONS) do
        local d = f.db.squares[pos[1]]
        if d.enabled and AURA_TYPES[d.type] then
            local list = ns.Filters and ns.Filters.Get(d.list) and ns.Filters.Signature(d.list) or ""
            table.insert(parts, table.concat({ pos[1], d.type, d.spells or "", list, tostring(d.texture), tostring(d.timer),
                d.count or 1, d.grow or "RIGHT", d.size }, ":"))
        end
    end
    return table.concat(parts, "|")
end

-- A square with several icons: its own container with one aura group.
local function isMulti(d)
    return (d.count or 1) > 1 and AURA_TYPES[d.type] and d.type ~= "missing"
end

local function candidateFor(d)
    if not SQ.LIST_TYPES[d.type] then return nil end
    local ids = SQ.ParseSpells(d.spells)
    for id in pairs(ns.Filters and ns.Filters.Get(d.list) or {}) do ids[id] = true end
    return { includeSpellIDs = ids }
end

local DIR = AnchorUtil and AnchorUtil.FlowDirection
-- grow -> container corner (= holder corner), horizontal, vertical, one line?
local GROW = {
    RIGHT = { "TOPLEFT", "Right", "Down", false },
    LEFT  = { "TOPRIGHT", "Left", "Down", false },
    DOWN  = { "TOPLEFT", "Right", "Down", true },
    UP    = { "BOTTOMLEFT", "Right", "Up", true },
}
SQ.GROW = { { "RIGHT", "Right" }, { "LEFT", "Left" }, { "DOWN", "Down" }, { "UP", "Up" } }

local function buildGroup(f, key, d)
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, f, "CustomAuraContainerTemplate")
    if not ok or not c then return nil end
    c:SetFrameLevel(f:GetFrameLevel() + 16)
    local g = GROW[d.grow] or GROW.RIGHT
    local spacing = 1
    c:SetPoint(g[1], f.squares[key], g[1])
    c:SetSize(1, 1)
    local okGroup = pcall(c.AddAuraGroup, c, "square", filterFor(d.type), {
        maxFrameCount = d.count,
        sortMethod = _G.AuraContainerSortMethod and _G.AuraContainerSortMethod.Default,
        sortDirection = _G.AuraContainerSortDirection and _G.AuraContainerSortDirection.Normal,
        initializeFrame = initializer(nil, d, d.type),
        candidateFilters = candidateFor(d),
        layout = { elementWidth = d.size, elementHeight = d.size, elementSpacing = spacing, lineSpacing = spacing },
    })
    if not okGroup then c:Hide() return nil end
    try(c, "SetFlowLayoutPadding", 0, 0, 0, 0)
    if DIR then try(c, "SetFlowLayoutGrowthDirection", DIR[g[2]], DIR[g[3]]) end
    try(c, "SetFlowLayoutAnchorPoint", g[1])
    try(c, "SetFlowLayoutMaximumLineSize", g[4] and d.size or d.count * (d.size + spacing))
    ns.UF.BindAuraContainer(c, f)
    return c
end

local function buildContainer(f)
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, f, "CustomAuraContainerTemplate")
    if not ok or not c then return nil end
    c:SetFrameLevel(f:GetFrameLevel() + 16)   -- above the holders: "missing" relies on it
    c:SetSize(1, 1)
    c:SetPoint("CENTER", f, "CENTER")
    local any = false
    for _, pos in ipairs(SQ.POSITIONS) do
        local key = pos[1]
        local d = f.db.squares[key]
        if d.enabled and AURA_TYPES[d.type] and not isMulti(d) then
            local okSlot = pcall(c.AddAuraSlot, c, key, filterFor(d.type), {
                initializeFrame = initializer(f.squares[key], d, d.type),
                candidateFilters = candidateFor(d),
            })
            any = any or okSlot
        end
    end
    if not any then c:Hide(); return nil end
    ns.UF.BindAuraContainer(c, f)   -- only now, after every slot exists
    return c
end

function SQ.Create(f)
    if not SQ.supported[f.key] then return end
    f.squares = {}
    for _, pos in ipairs(SQ.POSITIONS) do
        f.squares[pos[1]] = newHolder(f)
    end
end

-- Geometry and slots (protected context: called from UF.Layout).
function SQ.Layout(f)
    if not f.squares then return end
    local all = f.db.squares
    for _, pos in ipairs(SQ.POSITIONS) do
        local h, d = f.squares[pos[1]], all[pos[1]]
        h:ClearAllPoints()
        h:SetPoint("CENTER", f, pos[3], d.x or 0, d.y or 0)
        h:SetSize(d.size, d.size)
        h:SetShown(d.enabled)
        h.kind = d.enabled and d.type or nil
        -- aura squares draw nothing themselves, except the red of "missing"
        if d.type == "missing" then
            local c = COLORS.missing
            h.tex:SetVertexColor(c[1], c[2], c[3], 1)
        end
    end

    local sig = signature(f)
    if f.squareSignature ~= sig then
        -- retire the old containers: no unit, hidden (they cannot be destroyed)
        for _, c in pairs(f.squareGroups or {}) do
            try(c, "SetUnit", "none")
            c:Hide()
        end
        if f.squareContainer then
            try(f.squareContainer, "SetUnit", "none")
            f.squareContainer:Hide()
        end
        f.squareContainer, f.squareGroups, f.squareSignature = nil, {}, nil
        if sig ~= "" and ns.Auras and ns.Auras.CanBuild() then
            f.squareContainer = buildContainer(f)
            for _, pos in ipairs(SQ.POSITIONS) do
                local d = all[pos[1]]
                if d.enabled and isMulti(d) then f.squareGroups[pos[1]] = buildGroup(f, pos[1], d) end
            end
            f.squareSignature = sig
        end
    end
    SQ.Update(f)
end

-- Non-aura squares: aggro. Also the config-mode preview.
local function aggroStatus(unit)
    local ok, status = pcall(UnitThreatSituation, unit)
    if ok and ns.CanRead(status) and type(status) == "number" and status > 0 then return status end
end

function SQ.Update(f)
    if not f.squares then return end
    for key, h in pairs(f.squares) do
        local kind = h.kind
        if kind then
            local show, r, g, b = false, 1, 1, 1
            -- config mode: aura squares show the stand-in's real auras, so
            -- only the others (aggro) get a coloured preview
            if ns.unlocked and not AURA_TYPES[kind] then
                local c = COLORS[kind] or { 1, 0, 0 }
                show, r, g, b = true, c[1], c[2], c[3]
            elseif kind == "aggro" then
                local status = aggroStatus(f.unit)
                if status then
                    show = true
                    r, g, b = GetThreatStatusColor(status)
                end
            elseif kind == "aggrotot" then
                local okA, hostile = pcall(UnitCanAttack, "player", "target")
                local okB, same = pcall(UnitIsUnit, "targettarget", f.unit)
                show = okA and okB and ns.CanRead(hostile) and ns.CanRead(same) and hostile and same or false
                r, g, b = unpack(COLORS.aggrotot)
            elseif kind == "missing" then
                show = true    -- the buff's slot covers it while the buff is there
                r, g, b = unpack(COLORS.missing)
            end
            h.tex:SetVertexColor(r, g, b, 1)
            h.border:SetShown(show)
            h.tex:SetShown(show)
        end
    end
end

-- The unit behind the frame changed.
function SQ.Refresh(f)
    ns.UF.BindAuraContainer(f.squareContainer, f)
    try(f.squareContainer, "UpdateAllAuras")
    for _, c in pairs(f.squareGroups or {}) do
        ns.UF.BindAuraContainer(c, f)
        try(c, "UpdateAllAuras")
    end
    SQ.Update(f)
end

-- Aggro changes all the time; a light poll keeps the squares honest.
local ticker = CreateFrame("Frame")
local wait = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    wait = wait + elapsed
    if wait < 0.25 then return end
    wait = 0
    if not ns.UF then return end
    for key in pairs(SQ.supported) do
        for _, f in ipairs(ns.UF.byKey[key] or {}) do
            if f.squares and f:IsVisible() then SQ.Update(f) end
        end
    end
end)

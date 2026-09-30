-- LizzaricksUnitFrames / Frames / Borders
--
-- Luna's frame borders: a coloured edge around a unit frame
--   * on mouseover  (white while the mouse is over the frame)
--   * on aggro      (Blizzard's threat colour; UnitThreatSituation is readable)
--   * on debuff     (coloured by dispel type: only ones you can dispel, or all)
-- The debuff border wins over aggro, aggro over mouseover.
--
-- The debuff border never reads an aura: it is one aura SLOT of the client's
-- aura container, sized to the frame, whose four edges the client tints by
-- the (secret) dispel type. It shows while a matching debuff is on the unit,
-- in and out of combat.
local _, ns = ...

local BO = {}
ns.Borders = BO

-- Units that get aura events (the debuff border needs them).
BO.debuffSupported = { player = true, pet = true, target = true, focus = true, party = true, partypet = true, raid = true }

BO.DEBUFF_MODES = { { "off", "Off" }, { "own", "Your own (ones you can dispel)" }, { "all", "All" } }

local HOVER = { 1, 1, 1 }
local DISPEL_COLORS = {
    Magic = { 0.20, 0.60, 1.00 }, Curse = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 }, Poison = { 0.00, 0.60, 0.00 },
    Bleed = { 1.00, 0.00, 0.00 }, None = { 0.80, 0.00, 0.00 },
}

local F = AuraUtil and AuraUtil.AuraFilters or {}
local HARMFUL, RAID = F.Harmful or "HARMFUL", F.Raid or "RAID"
local function filter(...)
    if AuraUtil and AuraUtil.CreateFilterString then return AuraUtil.CreateFilterString(...) end
    return table.concat({ ... }, "|")
end

local function try(obj, method, ...)
    local f = obj and obj[method]
    if not f then return false end
    return (pcall(f, obj, ...))
end

-- Four textures along the inside of `parent`'s edges.
local function edges(parent, layer)
    local e = {}
    for i = 1, 4 do
        e[i] = parent:CreateTexture(nil, layer or "OVERLAY")
        e[i]:SetColorTexture(1, 1, 1, 1)
    end
    return e
end

local function placeEdges(e, parent, size)
    local top, bottom, left, right = e[1], e[2], e[3], e[4]
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", parent, "TOPLEFT")
    top:SetPoint("TOPRIGHT", parent, "TOPRIGHT")
    top:SetHeight(size)
    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    bottom:SetHeight(size)
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -size)
    left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, size)
    left:SetWidth(size)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -size)
    right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, size)
    right:SetWidth(size)
end

local frames = {}

function BO.Create(f)
    local b = CreateFrame("Frame", nil, f)
    b:SetAllPoints(f)
    b.edges = edges(b)
    b:Hide()
    f.border = b
    f:HookScript("OnEnter", function() f.hovered = true; BO.Update(f) end)
    f:HookScript("OnLeave", function() f.hovered = false; BO.Update(f) end)
    frames[f] = true
end

-- ------------------------------------------------------------ debuff --

local function initializer(f, db)
    return function(button)
        button:ClearAllPoints()
        button:SetAllPoints(f)
        local map = {}
        if CreateColor then
            for k, c in pairs(DISPEL_COLORS) do map[k] = CreateColor(c[1], c[2], c[3], 1) end
        end
        local e = edges(button)
        placeEdges(e, button, db.size)
        for _, tex in ipairs(e) do
            tex:Hide()
            if Enum.CustomAuraButtonDispelTypeTextureStyle then
                try(button, "AddDispelTypeTexture", tex, {
                    style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
                    showWhenHarmful = true, showWhenHelpful = false, customDispelColorMap = map,
                })
            end
        end
        -- the frame underneath keeps its clicks and tooltip
        try(button, "SetMouseClickEnabled", false)
        try(button, "SetMouseMotionEnabled", false)
    end
end

local function signature(db)
    return table.concat({ db.debuff or "off", db.size, tostring(db.onTop) }, ":")
end

local function buildContainer(f, db)
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, f, "CustomAuraContainerTemplate")
    if not ok or not c then return nil end
    c:SetFrameLevel(f:GetFrameLevel() + (db.onTop and 31 or 6))   -- over the other border
    c:SetSize(1, 1)
    c:SetPoint("CENTER", f, "CENTER")
    local want = db.debuff == "own" and filter(HARMFUL, RAID) or filter(HARMFUL)
    if not pcall(c.AddAuraSlot, c, "border", want, { initializeFrame = initializer(f, db) }) then
        c:Hide()
        return nil
    end
    ns.UF.BindAuraContainer(c, f)
    return c
end

-- Geometry (protected context: called from UF.Layout).
function BO.Layout(f)
    local b = f.border
    if not b then return end
    local db = f.db.borders
    b:SetFrameLevel(f:GetFrameLevel() + (db.onTop and 30 or 5))
    placeEdges(b.edges, b, db.size)

    local wanted = BO.debuffSupported[f.key] and db.debuff ~= "off"
    local sig = signature(db)
    if f.borderContainer and (not wanted or f.borderSignature ~= sig) then
        try(f.borderContainer, "SetUnit", "none")
        f.borderContainer:Hide()
        f.borderContainer = nil
    end
    if wanted and not f.borderContainer and ns.Auras and ns.Auras.CanBuild() then
        f.borderContainer = buildContainer(f, db)
        f.borderSignature = sig
    end
    ns.UF.BindAuraContainer(f.borderContainer, f)
    BO.Update(f)
end

-- ------------------------------------------------------------ colour --

local function threat(unit)
    local ok, status = pcall(UnitThreatSituation, unit)
    if ok and ns.CanRead(status) and type(status) == "number" and status > 0 then return status end
end

function BO.Update(f)
    local b = f.border
    if not b then return end
    local db = f.db.borders
    local r, g, bl
    local status = db.aggro and threat(f.unit)
    if status then
        r, g, bl = GetThreatStatusColor(status)
    elseif db.mouseover and f.hovered then
        r, g, bl = HOVER[1], HOVER[2], HOVER[3]
    end
    if r then
        for _, e in ipairs(b.edges) do e:SetVertexColor(r, g, bl, 1) end
        b:Show()
    else
        b:Hide()
    end
end

-- The unit behind the frame changed.
function BO.Refresh(f)
    ns.UF.BindAuraContainer(f.borderContainer, f)
    try(f.borderContainer, "UpdateAllAuras")
    BO.Update(f)
end

-- Threat changes all the time; a light poll keeps the aggro border honest.
local ticker = CreateFrame("Frame")
local wait = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    wait = wait + elapsed
    if wait < 0.25 then return end
    wait = 0
    for f in pairs(frames) do
        if f.db.borders.aggro and f:IsVisible() then BO.Update(f) end
    end
end)

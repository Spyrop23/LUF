-- LizzaricksUnitFrames / Frames / Highlight
--
-- Luna's highlight: the whole frame lights up
--   * on mouseover      (the mouse is over the frame)
--   * on target         (the frame shows your current target)
--   * on debuff         (tinted by dispel type: ones you can dispel, or all)
--
-- "Is this my target" may be secret for other units, so it drives the
-- overlay's alpha through SetAlphaFromBoolean. The debuff tint is an aura
-- slot of the client's aura container whose one texture the client colours
-- by the (secret) dispel type, in and out of combat, as the debuff border.
local _, ns = ...

local HL = {}
ns.Highlight = HL

HL.debuffSupported = { player = true, pet = true, target = true, focus = true, party = true, partypet = true, raid = true }
HL.DEBUFF_MODES = { { "off", "Off" }, { "own", "Your own (ones you can dispel)" }, { "all", "All" } }

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

local frames = {}

function HL.Create(f)
    local h = CreateFrame("Frame", nil, f)
    h:SetAllPoints(f)
    h:SetFrameLevel(f:GetFrameLevel() + 4)
    h.tex = h:CreateTexture(nil, "OVERLAY")
    h.tex:SetAllPoints()
    h.tex:SetColorTexture(1, 1, 1, 1)
    h.tex:SetBlendMode("ADD")
    h:Hide()
    f.highlight = h
    f:HookScript("OnEnter", function() f.hovered = true; HL.Update(f) end)
    f:HookScript("OnLeave", function() f.hovered = false; HL.Update(f) end)
    frames[f] = true
end

-- ------------------------------------------------------------ debuff --

local function initializer(f, db)
    return function(button)
        button:ClearAllPoints()
        button:SetAllPoints(f)
        local tex = button:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints(button)
        tex:SetColorTexture(1, 1, 1, 1)
        tex:SetBlendMode("ADD")
        tex:Hide()
        local map = {}
        if CreateColor then
            for k, c in pairs(DISPEL_COLORS) do map[k] = CreateColor(c[1], c[2], c[3], db.alpha) end
        end
        if Enum.CustomAuraButtonDispelTypeTextureStyle then
            try(button, "AddDispelTypeTexture", tex, {
                style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
                showWhenHarmful = true, showWhenHelpful = false, customDispelColorMap = map,
            })
        end
        try(button, "SetMouseClickEnabled", false)
        try(button, "SetMouseMotionEnabled", false)
    end
end

local function signature(db)
    return table.concat({ db.debuff or "off", db.alpha }, ":")
end

local function buildContainer(f, db)
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, f, "CustomAuraContainerTemplate")
    if not ok or not c then return nil end
    c:SetFrameLevel(f:GetFrameLevel() + 4)
    c:SetSize(1, 1)
    c:SetPoint("CENTER", f, "CENTER")
    local want = db.debuff == "own" and filter(HARMFUL, RAID) or filter(HARMFUL)
    if not pcall(c.AddAuraSlot, c, "highlight", want, { initializeFrame = initializer(f, db) }) then
        c:Hide()
        return nil
    end
    ns.UF.BindAuraContainer(c, f)
    return c
end

-- (protected context: called from UF.Layout)
function HL.Layout(f)
    if not f.highlight then return end
    local db = f.db.highlight
    local wanted = HL.debuffSupported[f.key] and db.debuff ~= "off"
    local sig = signature(db)
    if f.highlightContainer and (not wanted or f.highlightSignature ~= sig) then
        try(f.highlightContainer, "SetUnit", "none")
        f.highlightContainer:Hide()
        f.highlightContainer = nil
    end
    if wanted and not f.highlightContainer and ns.Auras and ns.Auras.CanBuild() then
        f.highlightContainer = buildContainer(f, db)
        f.highlightSignature = sig
    end
    ns.UF.BindAuraContainer(f.highlightContainer, f)
    HL.Update(f)
end

function HL.Update(f)
    local h = f.highlight
    if not h then return end
    local db = f.db.highlight
    if db.mouseover and f.hovered then
        h.tex:SetAlpha(db.alpha)
        h:Show()
    elseif db.target then
        local ok, isTarget = pcall(UnitIsUnit, f.unit, "target")
        if not ok or type(isTarget) == "nil" then h:Hide() return end
        h:Show()
        if not try(h.tex, "SetAlphaFromBoolean", isTarget, db.alpha, 0) then
            h.tex:SetAlpha((ns.CanRead(isTarget) and isTarget) and db.alpha or 0)
        end
    else
        h:Hide()
    end
end

function HL.Refresh(f)
    ns.UF.BindAuraContainer(f.highlightContainer, f)
    try(f.highlightContainer, "UpdateAllAuras")
    HL.Update(f)
end

ns:RegisterEvent("PLAYER_TARGET_CHANGED", function()
    for f in pairs(frames) do
        if f:IsVisible() then HL.Update(f) end
    end
end)

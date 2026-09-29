-- FUF / Frames / UnitFrame
--
-- One Luna-style unit frame: optional portrait on the left or right, bars
-- stacked in the remaining space (heights by weight), three tag texts
-- (left / center / right) on every bar, optional cast bar below or above.
--
-- Frames are SecureUnitButtons: left click targets, right click opens the
-- unit menu, and RegisterUnitWatch shows/hides them with the unit, which
-- keeps working in combat. Creation, size and position are protected and
-- only change out of combat.
--
-- A frame knows its settings key (f.key: "party" for party1..4), its index
-- within a group (f.index) and, for party pets, the frame it hangs on
-- (f.anchorFrame).
local _, ns = ...

local UF = {}
ns.UF = UF
UF.frames = {}     -- by unit
UF.byKey = {}      -- key -> { frames }

local BORDER = 1
local POLL_EVERY = 0.2

-- Units the client sends no events for: polled while shown (Luna does the
-- same for its "fake units").
local POLLED = { targettarget = true, targettargettarget = true, pettarget = true }

-- Global events that change which unit a frame shows, by settings key.
local GLOBAL_EVENTS = {
    target = { "PLAYER_TARGET_CHANGED" },
    targettarget = { "PLAYER_TARGET_CHANGED" },
    targettargettarget = { "PLAYER_TARGET_CHANGED" },
    pet = { "UNIT_PET" },
    pettarget = { "UNIT_PET" },
    party = { "GROUP_ROSTER_UPDATE" },
    partypet = { "GROUP_ROSTER_UPDATE", "UNIT_PET" },
}

local UNIT_EVENTS = {
    "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
    "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_FACTION", "UNIT_FLAGS",
    "UNIT_CONNECTION", "UNIT_CLASSIFICATION_CHANGED",
    "UNIT_PORTRAIT_UPDATE", "UNIT_MODEL_CHANGED", "PLAYER_FLAGS_CHANGED",
    "UNIT_HAPPINESS",
}

local BAR_KEYS = { "healthBar", "powerBar" }
UF.BAR_KEYS = BAR_KEYS

-- ------------------------------------------------------------ regions --

local function createText(parent)
    local t = {}
    for _, side in ipairs({ "left", "center", "right" }) do
        local fs = parent:CreateFontString(nil, "OVERLAY")
        fs:SetFont(ns.media.font, 10, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetWordWrap(false)
        t[side] = fs
    end
    t.left:SetJustifyH("LEFT")
    t.center:SetJustifyH("CENTER")
    t.right:SetJustifyH("RIGHT")
    return t
end

local function createBar(f)
    local bar = CreateFrame("StatusBar", nil, f)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.text = createText(bar)
    return bar
end

local function buildRegions(f)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()

    f.healthBar = createBar(f)
    f.powerBar = createBar(f)

    f.portrait3D = CreateFrame("PlayerModel", nil, f)
    f.portrait2D = f:CreateTexture(nil, "ARTWORK")
    f.portrait2D:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    if f.key == "pet" then
        -- On its own frame so it draws above the bars and the 3D model.
        local holder = CreateFrame("Frame", nil, f)
        holder:SetFrameLevel(f:GetFrameLevel() + 10)
        f.happiness = holder:CreateTexture(nil, "OVERLAY")
        -- Classic art (the classic unit frame textures ship with Forever);
        -- a plain coloured square when the file is missing.
        f.happinessArt = f.happiness:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness") and true or false
        f.happiness:Hide()
    end
end

-- Texture coordinates of the three faces in UI-PetHappiness.
local HAPPINESS_COORDS = {
    { 0.375, 0.5625, 0, 0.359375 },   -- unhappy
    { 0.1875, 0.375, 0, 0.359375 },   -- content
    { 0, 0.1875, 0, 0.359375 },       -- happy
}

function UF.UpdateHappiness(f)
    local icon = f.happiness
    if not icon then return end
    local db = f.db.happiness
    local h = db and db.enabled and ns.PetHappiness(f.unit)
    if not h then
        icon:Hide()
        return
    end
    if f.happinessArt then
        icon:SetTexCoord(unpack(HAPPINESS_COORDS[h]))
        icon:SetVertexColor(1, 1, 1)
    else
        icon:SetColorTexture(unpack(ns.colors.happiness[h]))
    end
    icon:Show()
end

-- ------------------------------------------------------------ layout --

-- Where the frame goes: party members stack below the first one, party
-- pets hang on their owner's frame, everything else is placed on UIParent.
function UF.Position(f)
    local db = f.db
    f:ClearAllPoints()
    if f.anchorFrame then
        f:SetPoint("TOPLEFT", f.anchorFrame, "TOPRIGHT", db.x, db.y)
    else
        local y = db.y
        if f.index and f.index > 1 then
            y = y - (f.index - 1) * (db.height + (db.spacing or 0))
        end
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", db.x, y)
    end
end

-- Applies size, position, portrait and bar geometry from the profile.
-- Protected: out of combat only.
function UF.Layout(f)
    local db = f.db
    local texture = ns.Texture()
    f:SetScale(db.scale or 1)
    f:SetSize(db.width, db.height)
    UF.Position(f)
    f.bg:SetColorTexture(0, 0, 0, ns.db.backgroundAlpha or 0.8)

    local inner = db.width - 2 * BORDER
    local left, right = BORDER, BORDER

    -- portrait
    local p = db.portrait
    f.portrait3D:Hide()
    f.portrait2D:Hide()
    f.portrait = nil
    if p.enabled then
        local pw = math.floor(inner * p.width + 0.5)
        local region = p.type == "2D" and f.portrait2D or f.portrait3D
        region:ClearAllPoints()
        if p.side == "RIGHT" then
            region:SetPoint("TOPRIGHT", f, "TOPRIGHT", -BORDER, -BORDER)
            region:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -BORDER, BORDER)
            right = right + pw + BORDER
        else
            region:SetPoint("TOPLEFT", f, "TOPLEFT", BORDER, -BORDER)
            region:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", BORDER, BORDER)
            left = left + pw + BORDER
        end
        region:SetWidth(pw)
        region:Show()
        f.portrait = region
    end

    -- bars, top to bottom, heights by weight
    local shown, total = {}, 0
    for _, key in ipairs(BAR_KEYS) do
        local bdb = db[key]
        local bar = f[key]
        bar:SetStatusBarTexture(texture)
        bar.bg:SetTexture(texture)
        if bdb.enabled ~= false then
            table.insert(shown, key)
            total = total + bdb.weight
        else
            bar:Hide()
        end
    end
    local height = db.height - 2 * BORDER - (#shown - 1) * BORDER
    local y = -BORDER
    for _, key in ipairs(shown) do
        local bar, bdb = f[key], db[key]
        local h = height * bdb.weight / total
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", f, "TOPLEFT", left, y)
        bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -right, y)
        bar:SetHeight(h)
        bar.bg:SetShown(bdb.background)
        bar:Show()
        y = y - h - BORDER

        local tdb = db.tags[key]
        local t = bar.text
        t.left:ClearAllPoints()
        t.left:SetPoint("LEFT", bar, "LEFT", 2, 0)
        t.right:ClearAllPoints()
        t.right:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
        t.center:ClearAllPoints()
        t.center:SetPoint("CENTER", bar, "CENTER", 0, 0)
        for _, side in ipairs({ "left", "center", "right" }) do
            t[side]:SetFont(ns.media.font, tdb.size, "")
            t[side]:SetHeight(h)
        end
        -- left and right share the bar; the left text gives way first
        t.left:SetPoint("RIGHT", t.right, "LEFT", -4, 0)
    end

    if f.happiness then
        local size = db.happiness and db.happiness.size or 14
        f.happiness:ClearAllPoints()
        f.happiness:SetSize(size, size)
        f.happiness:SetPoint("CENTER", f, "TOPRIGHT", -size / 2, 0)
    end

    if ns.CastBar then ns.CastBar.Layout(f) end
    if ns.Auras then ns.Auras.Layout(f) end
    UF.Update(f)
end

-- ------------------------------------------------------------ update --

local function applyColor(bar, c, alpha)
    bar:SetStatusBarColor(c[1], c[2], c[3])
    bar.bg:SetVertexColor(c[1], c[2], c[3], alpha)
end

local function readableFlag(v)
    return ns.CanRead(v) and v
end

function UF.UpdateHealth(f)
    local unit, bar, bdb = f.unit, f.healthBar, f.db.healthBar
    ns.SetHealthFill(bar, unit)

    if not readableFlag(UnitIsConnected(unit)) then
        applyColor(bar, ns.colors.offline, bdb.backgroundAlpha)
        return
    end
    local isPlayer = readableFlag(UnitIsPlayer(unit))
    if not isPlayer and readableFlag(UnitIsTapDenied(unit)) then
        applyColor(bar, ns.colors.tapped, bdb.backgroundAlpha)
        return
    end

    local ct, c = bdb.colorType, nil
    if ct == "happiness" then
        local h = ns.PetHappiness(unit)
        c = h and ns.colors.happiness[h] or ns.ReactionColor(unit)
    elseif ct == "class" then
        c = isPlayer and ns.ClassColor(unit) or ns.ReactionColor(unit)
    elseif ct == "reaction" then
        c = ns.ReactionColor(unit)
    elseif ct == "health" then
        -- The colour comes from a secret evaluation: no test, no field
        -- access, just hand the channels to the widget.
        local ok, r, g, b = pcall(function()
            return UnitHealthPercent(unit, true, ns.HealthColorCurve()):GetRGB()
        end)
        if ok then
            bar:SetStatusBarColor(r, g, b)
            bar.bg:SetVertexColor(r, g, b, bdb.backgroundAlpha)
            return
        end
    end
    applyColor(bar, c or ns.colors.static, bdb.backgroundAlpha)
end

function UF.UpdatePower(f)
    if f.db.powerBar.enabled == false then return end
    local unit, bar = f.unit, f.powerBar
    ns.SetPowerFill(bar, unit)
    applyColor(bar, ns.PowerColor(unit), f.db.powerBar.backgroundAlpha)
end

function UF.UpdatePortrait(f)
    local p = f.portrait
    if not p then return end
    if p == f.portrait3D then
        p:ClearModel()
        p:SetUnit(f.unit)
        p:SetPortraitZoom(1)
        p:SetCamDistanceScale(1)
    else
        SetPortraitTexture(p, f.unit)
    end
end

function UF.UpdateTexts(f)
    local unit, tags = f.unit, f.db.tags
    for _, key in ipairs(BAR_KEYS) do
        local bar = f[key]
        if bar:IsShown() then
            local tdb = tags[key]
            for _, side in ipairs({ "left", "center", "right" }) do
                ns.Tags.Render(bar.text[side], tdb[side] or "", unit)
            end
        end
    end
end

function UF.Update(f)
    if not UnitExists(f.unit) then return end
    UF.UpdateHealth(f)
    UF.UpdatePower(f)
    UF.UpdatePortrait(f)
    UF.UpdateTexts(f)
    UF.UpdateHappiness(f)
end

-- Polled frames redraw bars and texts only: re-setting a 3D model five
-- times a second would make it flicker.
local function updateBarsAndTexts(f)
    if not UnitExists(f.unit) then return end
    UF.UpdateHealth(f)
    UF.UpdatePower(f)
    UF.UpdateTexts(f)
end

-- The unit behind the frame changed (new target, roster change, shown).
function UF.UnitChanged(f)
    UF.Update(f)
    if ns.CastBar then ns.CastBar.Refresh(f) end
    if ns.Auras then ns.Auras.Refresh(f) end
end

-- Which parts an event touches; everything else redraws the whole frame.
local EVENT_PARTS = {
    UNIT_HEALTH = "health", UNIT_MAXHEALTH = "health",
    UNIT_POWER_UPDATE = "power", UNIT_MAXPOWER = "power", UNIT_DISPLAYPOWER = "power",
    UNIT_PORTRAIT_UPDATE = "portrait", UNIT_MODEL_CHANGED = "portrait",
}

local function onUnitEvent(ev, event)
    local f = ev.frame
    if not f:IsVisible() then return end
    local part = EVENT_PARTS[event]
    if part == "health" then
        UF.UpdateHealth(f)
        UF.UpdateTexts(f)
    elseif part == "power" then
        UF.UpdatePower(f)
        UF.UpdateTexts(f)
    elseif part == "portrait" then
        UF.UpdatePortrait(f)
    else
        UF.Update(f)
    end
end

local function onGlobalEvent(ev)
    local f = ev.frame
    if f:IsVisible() then UF.UnitChanged(f) end
end

local function onPoll(ev, elapsed)
    ev.wait = (ev.wait or 0) + elapsed
    if ev.wait < POLL_EVERY then return end
    ev.wait = 0
    if ev.frame:IsVisible() then updateBarsAndTexts(ev.frame) end
end

local function wireEvents(f)
    local ev = CreateFrame("Frame")
    ev.frame = f
    for _, event in ipairs(UNIT_EVENTS) do
        pcall(ev.RegisterUnitEvent, ev, event, f.unit)
    end
    ev:SetScript("OnEvent", onUnitEvent)
    f.unitEvents = ev

    local glob = CreateFrame("Frame")
    glob.frame = f
    pcall(glob.RegisterEvent, glob, "PLAYER_ENTERING_WORLD")
    for _, event in ipairs(GLOBAL_EVENTS[f.key] or {}) do
        pcall(glob.RegisterEvent, glob, event)
    end
    glob:SetScript("OnEvent", onGlobalEvent)
    if POLLED[f.unit] then glob:SetScript("OnUpdate", onPoll) end
    f.globalEvents = glob
end

-- ------------------------------------------------------------ create --

-- opts: key (settings key, default unit), index (position in a group),
-- anchorFrame (frame this one is placed relative to).
function UF.Create(unit, opts)
    if UF.frames[unit] then return UF.frames[unit] end
    assert(not InCombatLockdown(), "FUF: unit frames are created out of combat")
    opts = opts or {}

    local f = CreateFrame("Button", "FUF_" .. unit, UIParent, "SecureUnitButtonTemplate")
    f.unit = unit
    f.key = opts.key or unit
    f.index = opts.index
    f.anchorFrame = opts.anchorFrame
    f.db = ns.db.units[f.key]
    f:SetFrameStrata("LOW")
    f:RegisterForClicks("AnyUp")
    f:SetAttribute("unit", unit)
    f:SetAttribute("*type1", "target")
    f:SetAttribute("*type2", "togglemenu")

    buildRegions(f)
    if ns.CastBar then ns.CastBar.Create(f) end
    wireEvents(f)
    f:HookScript("OnShow", UF.UnitChanged)

    UF.frames[unit] = f
    UF.byKey[f.key] = UF.byKey[f.key] or {}
    table.insert(UF.byKey[f.key], f)
    UF.Apply(f)
    return f
end

-- Re-reads the profile (after a change or a profile switch).
-- Protected: out of combat only.
function UF.Apply(f)
    f.db = ns.db.units[f.key]
    UF.Layout(f)
    if ns.unlocked and ns.UnlockFrame then
        ns.UnlockFrame(f)
        return
    end
    UnregisterUnitWatch(f)
    if f.db.enabled then
        RegisterUnitWatch(f)
    else
        f:Hide()
    end
end

-- ------------------------------------------------------ applying edits --

-- Settings changes arrive in bursts (a slider drag); they are collected
-- and applied once per frame, and only out of combat.
local pending, scheduled = {}, false

local function flush()
    scheduled = false
    ns:RunOutOfCombat(function()
        for key in pairs(pending) do
            for _, f in ipairs(UF.byKey[key] or {}) do UF.Apply(f) end
            -- party pets hang on party frames: follow their size/position
            if key == "party" then
                for _, f in ipairs(UF.byKey.partypet or {}) do UF.Apply(f) end
            end
            if ns.db.units[key].enabled then ns:HideBlizzard(key) end
        end
        pending = {}
    end)
end

function ns:ApplyKey(key)
    pending[key] = true
    if not scheduled then
        scheduled = true
        C_Timer.After(0, flush)
    end
end

function ns:ApplyAll()
    for key in pairs(ns.db.units) do pending[key] = true end
    if not scheduled then
        scheduled = true
        C_Timer.After(0, flush)
    end
end

-- LizzaricksUnitFrames / Frames / UnitFrame
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
local POLLED = { targettarget = true, targettargettarget = true, pettarget = true, focustarget = true,
    party1target = true, party2target = true, party3target = true, party4target = true }
-- Settings keys whose units change with the raid roster (raidNtarget ...).
local POLLED_KEYS = { maintanktarget = true, mainassisttarget = true }

-- Global events that change which unit a frame shows, by settings key.
local GLOBAL_EVENTS = {
    target = { "PLAYER_TARGET_CHANGED" },
    targettarget = { "PLAYER_TARGET_CHANGED" },
    targettargettarget = { "PLAYER_TARGET_CHANGED" },
    focus = { "PLAYER_FOCUS_CHANGED" },
    focustarget = { "PLAYER_FOCUS_CHANGED" },
    pet = { "UNIT_PET" },
    pettarget = { "UNIT_PET" },
    party = { "GROUP_ROSTER_UPDATE" },
    partypet = { "GROUP_ROSTER_UPDATE", "UNIT_PET" },
    partytarget = { "GROUP_ROSTER_UPDATE", "UNIT_TARGET" },
    maintank = { "GROUP_ROSTER_UPDATE" },
    mainassist = { "GROUP_ROSTER_UPDATE" },
    maintanktarget = { "GROUP_ROSTER_UPDATE", "UNIT_TARGET" },
    mainassisttarget = { "GROUP_ROSTER_UPDATE", "UNIT_TARGET" },
    raid = { "GROUP_ROSTER_UPDATE" },
}

-- Experience events (only for frames with an XP bar).
local XP_EVENTS = { player = { "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_LEVEL_UP" },
    pet = { "UNIT_PET_EXPERIENCE", "UNIT_PET" } }
UF.XP_SUPPORTED = { player = true, pet = true }

local UNIT_EVENTS = {
    "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
    "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_FACTION", "UNIT_FLAGS",
    "UNIT_CONNECTION", "UNIT_CLASSIFICATION_CHANGED",
    "UNIT_PORTRAIT_UPDATE", "UNIT_MODEL_CHANGED", "PLAYER_FLAGS_CHANGED",
    "UNIT_HAPPINESS", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED",
}

-- emptyBar: Luna's "empty bar", no value, only a background and texts
local BAR_KEYS = { "healthBar", "powerBar", "emptyBar", "xpBar" }
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
    f.emptyBar = createBar(f)
    f.emptyBar:SetMinMaxValues(0, 1)
    f.emptyBar:SetValue(0)
    f.xpBar = createBar(f)
    f.xpBar.rested = f.xpBar:CreateTexture(nil, "ARTWORK")   -- rested part beyond the fill
    if ns.HealPrediction then ns.HealPrediction.Create(f) end

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
    if f.key == "raid" then
        local gx, gy = UF.RaidGroupOrigin(f.raidGroup or math.ceil(f.index / 5))
        local mx, my = UF.RaidMemberOffset(f.raidSlot or ((f.index - 1) % 5 + 1))
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", gx + mx, gy + my)
    elseif f.anchorFrame then
        f:SetPoint("TOPLEFT", f.anchorFrame, "TOPRIGHT", db.x, db.y)
    else
        local y = db.y
        if f.index and f.index > 1 then
            y = y - (f.index - 1) * (db.height + (db.spacing or 0))
        end
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", db.x, y)
    end
end

-- Raid geometry. A group is a block of five members, either a column
-- (direction DOWN, as in Luna) or a row (RIGHT). Blocks sit in a grid with
-- `groupsPerRow` blocks per row, or each at its own saved spot when groups
-- are moved separately.
function UF.RaidMemberOffset(slot)
    local db = ns.db.units.raid
    if db.groupDirection == "RIGHT" then
        return (slot - 1) * (db.width + db.spacing), 0
    end
    return 0, -(slot - 1) * (db.height + db.spacing)
end

function UF.RaidGridOrigin(g)
    local db = ns.db.units.raid
    local perRow = math.max(1, db.groupsPerRow or 8)
    local col, row = (g - 1) % perRow, math.floor((g - 1) / perRow)
    local blockW, blockH
    if db.groupDirection == "RIGHT" then
        blockW, blockH = 5 * db.width + 4 * db.spacing, db.height
    else
        blockW, blockH = db.width, 5 * db.height + 4 * db.spacing
    end
    return db.x + col * (blockW + db.groupSpacing), db.y - row * (blockH + db.groupSpacing)
end

function UF.RaidGroupOrigin(g)
    local db = ns.db.units.raid
    if db.separateGroups then
        db.groupPos = db.groupPos or {}
        local pos = db.groupPos[g]
        if not pos then
            -- first time: start where the grid had the group
            local x, y = UF.RaidGridOrigin(g)
            pos = { x = x, y = y }
            db.groupPos[g] = pos
        end
        return pos.x, pos.y
    end
    return UF.RaidGridOrigin(g)
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
        local allowed = key ~= "xpBar" or UF.XP_SUPPORTED[f.key]
        if bdb and allowed and bdb.enabled ~= false then
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
        if key == "emptyBar" then
            local c = bdb.color or { 0, 0, 0 }
            bar.bg:SetVertexColor(c[1], c[2], c[3], bdb.backgroundAlpha)
        end
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

    if ns.HealPrediction then ns.HealPrediction.Layout(f, db.width - left - right) end
    if ns.CastBar then ns.CastBar.Layout(f) end
    if ns.Auras then ns.Auras.Layout(f) end
    if ns.Status then ns.Status.Layout(f) end
    if ns.Squares then ns.Squares.Layout(f) end
    if ns.Borders then ns.Borders.Layout(f) end
    if ns.Highlight then ns.Highlight.Layout(f) end
    if ns.CombatText then ns.CombatText.Layout(f) end
    if ns.Indicators then ns.Indicators.Layout(f) end
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

local function updateHealthBar(f)
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

function UF.UpdateHealth(f)
    updateHealthBar(f)
    if ns.HealPrediction then ns.HealPrediction.Update(f) end
end

function UF.UpdatePower(f)
    if f.db.powerBar.enabled == false then return end
    local unit, bar = f.unit, f.powerBar
    ns.SetPowerFill(bar, unit)
    applyColor(bar, ns.PowerColor(unit), f.db.powerBar.backgroundAlpha)
end

-- Experience: player XP with the rested part, or the hunter pet's XP.
local XP_COLOR, RESTED_COLOR = { 0.58, 0.00, 0.55 }, { 0.00, 0.39, 0.88 }

function UF.UpdateXP(f)
    local bar = f.xpBar
    if not bar:IsShown() then return end
    local cur, max, rested = 0, 1, nil
    if f.key == "pet" then
        if GetPetExperience then cur, max = GetPetExperience() end
    else
        cur, max, rested = UnitXP("player"), UnitXPMax("player"), GetXPExhaustion and GetXPExhaustion()
    end
    cur, max = ns.Readable(cur, 0) or 0, ns.Readable(max, 1) or 1
    if max <= 0 then max = 1 end
    bar:SetMinMaxValues(0, max)
    bar:SetValue(cur)
    local c = XP_COLOR
    bar:SetStatusBarColor(c[1], c[2], c[3])
    bar.bg:SetVertexColor(c[1], c[2], c[3], f.db.xpBar.backgroundAlpha or 0.2)

    -- rested XP as a lighter block right after the fill
    rested = ns.Readable(rested, nil)
    local r = bar.rested
    if rested and rested > 0 and cur < max then
        local width = bar:GetWidth()
        local fillEnd = width * cur / max
        local restedW = math.min(width - fillEnd, width * rested / max)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", bar, "TOPLEFT", fillEnd, 0)
        r:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", fillEnd, 0)
        r:SetWidth(math.max(restedW, 0.01))
        r:SetTexture(ns.Texture())
        r:SetVertexColor(RESTED_COLOR[1], RESTED_COLOR[2], RESTED_COLOR[3], 0.6)
        r:Show()
    else
        r:Hide()
    end
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
        if bar:IsShown() and tags[key] then
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
    UF.UpdateXP(f)
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

-- Points an aura container at the unit the frame shows right now: in
-- config mode that is the stand-in (the player), so squares, aura rows and
-- borders preview real auras there too.
function UF.BindAuraContainer(c, f)
    if not c or c.boundUnit == f.unit then return end
    if pcall(c.SetUnit, c, f.unit) then c.boundUnit = f.unit end
end

-- The unit behind the frame changed (new target, roster change, shown).
function UF.UnitChanged(f)
    UF.Update(f)
    if ns.CastBar then ns.CastBar.Refresh(f) end
    if ns.Auras then ns.Auras.Refresh(f) end
    if ns.Squares then ns.Squares.Refresh(f) end
    if ns.Borders then ns.Borders.Refresh(f) end
    if ns.Highlight then ns.Highlight.Refresh(f) end
    if ns.Indicators then ns.Indicators.Refresh(f) end
end

-- Which parts an event touches; everything else redraws the whole frame.
local EVENT_PARTS = {
    UNIT_HEALTH = "health", UNIT_MAXHEALTH = "health",
    UNIT_HEAL_PREDICTION = "health", UNIT_ABSORB_AMOUNT_CHANGED = "health",
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
    for _, event in ipairs(XP_EVENTS[f.key] or {}) do
        pcall(glob.RegisterEvent, glob, event)
    end
    glob:SetScript("OnEvent", onGlobalEvent)
    if POLLED[f.unit] or POLLED_KEYS[f.key] then glob:SetScript("OnUpdate", onPoll) end
    f.globalEvents = glob
end

-- Points a frame at another unit (main tank frames follow the raid roles).
-- Protected: out of combat only. In config mode the stand-in stays and the
-- new unit takes over on lock.
function UF.SetUnit(f, unit)
    local current = f.realUnit or f.unit
    if current == unit then return end
    f:SetAttribute("unit", unit)
    if f.realUnit then f.realUnit = unit else f.unit = unit end
    local ev = f.unitEvents
    ev:UnregisterAllEvents()
    for _, event in ipairs(UNIT_EVENTS) do
        pcall(ev.RegisterUnitEvent, ev, event, unit)
    end
    if f.combatTextEvents then
        f.combatTextEvents:UnregisterAllEvents()
        pcall(f.combatTextEvents.RegisterUnitEvent, f.combatTextEvents, "UNIT_COMBAT", unit)
    end
    if f:IsVisible() then UF.UnitChanged(f) end
end

-- ------------------------------------------------------------ create --

-- opts: key (settings key, default unit), index (position in a group),
-- anchorFrame (frame this one is placed relative to).
function UF.Create(unit, opts)
    if UF.frames[unit] then return UF.frames[unit] end
    assert(not InCombatLockdown(), "Lizzarick's Unit Frames: unit frames are created out of combat")
    opts = opts or {}

    local f = CreateFrame("Button", "LizUF_" .. unit, UIParent, "SecureUnitButtonTemplate")
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
    if ns.Status then ns.Status.Create(f) end
    if ns.Squares then ns.Squares.Create(f) end
    if ns.Borders then ns.Borders.Create(f) end
    if ns.Highlight then ns.Highlight.Create(f) end
    if ns.CombatText then ns.CombatText.Create(f) end
    if ns.Indicators then ns.Indicators.Create(f) end
    wireEvents(f)
    f:HookScript("OnShow", UF.UnitChanged)
    -- the unit's tooltip, as Blizzard's frames show it
    f:HookScript("OnEnter", function(self)
        if GameTooltip_SetDefaultAnchor then GameTooltip_SetDefaultAnchor(GameTooltip, self) end
        if pcall(GameTooltip.SetUnit, GameTooltip, self.unit) then GameTooltip:Show() end
    end)
    f:HookScript("OnLeave", function() GameTooltip:Hide() end)

    UF.frames[unit] = f
    UF.byKey[f.key] = UF.byKey[f.key] or {}
    table.insert(UF.byKey[f.key], f)
    UF.Apply(f)
    return f
end

-- Show/hide with the unit. Party frames (and their pets) may hide in a raid;
-- that needs a state driver instead of the plain unit watch.
function UF.Watch(f)
    UnregisterUnitWatch(f)
    if UnregisterStateDriver then UnregisterStateDriver(f, "visibility") end
    if not f.db.enabled then
        f:Hide()
        return
    end
    local party = ns.db.units.party
    if (f.key == "party" or f.key == "partypet" or f.key == "partytarget") and party.hideInRaid and RegisterStateDriver then
        RegisterStateDriver(f, "visibility", "[group:raid] hide; [@" .. f.unit .. ",exists] show; hide")
    else
        RegisterUnitWatch(f)
    end
end

function UF.Unwatch(f)
    UnregisterUnitWatch(f)
    if UnregisterStateDriver then UnregisterStateDriver(f, "visibility") end
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
    UF.Watch(f)
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
            -- (and their visibility rule: hide in raid)
            if key == "party" then
                for _, f in ipairs(UF.byKey.partypet or {}) do UF.Apply(f) end
                for _, f in ipairs(UF.byKey.partytarget or {}) do UF.Apply(f) end
            end
            -- main tank / assist targets hang on their frames
            if UF.byKey[key .. "target"] and (key == "maintank" or key == "mainassist") then
                for _, f in ipairs(UF.byKey[key .. "target"]) do UF.Apply(f) end
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

-- ------------------------------------------------------------ raid --

-- Raid frames keep their unit (raidN); out of combat they are moved into the
-- column of the member's subgroup, as Luna's group headers would do.
function UF.ArrangeRaid()
    local frames = UF.byKey.raid
    if not frames then return end
    -- The roster only counts in a real raid: outside of one the client still
    -- answers GetRaidRosterInfo (subgroup 1 for everybody), which piled all
    -- 40 frames into the first column.
    local inRaid = IsInRaid and IsInRaid()
    local count = {}
    for i = 1, 40 do
        local f = UF.frames["raid" .. i]
        if f then
            local group
            if inRaid and GetRaidRosterInfo and UnitExists("raid" .. i) then
                local ok, _, _, subgroup = pcall(GetRaidRosterInfo, i)
                if ok and ns.CanRead(subgroup) and type(subgroup) == "number"
                    and subgroup >= 1 and subgroup <= 8 then
                    group = subgroup
                end
            end
            local slot
            if group then
                count[group] = (count[group] or 0) + 1
                slot = count[group]
            end
            if not group or slot > 5 then
                -- fixed grid: raid1-5 in column 1, raid6-10 in column 2 ...
                group, slot = math.ceil(i / 5), (i - 1) % 5 + 1
            end
            f.raidGroup, f.raidSlot = group, slot
            UF.Position(f)
        end
    end
end

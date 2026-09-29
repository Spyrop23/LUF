-- LizzaricksUnitFrames / Options / Window
--
-- The options window: page list on the left, the page on the right in a
-- scroll frame. Opened with /lzuf, the minimap button or the addon
-- compartment. Changes apply at once (out of combat; in combat they wait).
local _, ns = ...

local O = {}
ns.Options = O

local WIDTH, HEIGHT = 780, 580
local NAV_W = 170

-- ------------------------------------------------------------ helpers --

-- Getter/setter pair for a dotted path in a unit's settings.
local function unitPath(key, path)
    local function resolve()
        local t = ns.db.units[key]
        local parts = {}
        for p in path:gmatch("[^%.]+") do table.insert(parts, p) end
        for i = 1, #parts - 1 do t = t[parts[i]] end
        return t, parts[#parts]
    end
    local get = function()
        local t, k = resolve()
        return t[k]
    end
    local set = function(v)
        local t, k = resolve()
        t[k] = v
        ns:ApplyKey(key)
    end
    return get, set
end

local COLOR_TYPES = {
    { "class", "Class (NPCs by reaction)" },
    { "reaction", "Reaction" },
    { "health", "Health gradient" },
    { "static", "Static green" },
}
local PORTRAIT_TYPES = { { "3D", "3D model" }, { "2D", "2D picture" } }
local SIDES = { { "LEFT", "Left" }, { "RIGHT", "Right" } }
local CAST_POS = { { "BELOW", "Below the frame" }, { "ABOVE", "Above the frame" } }
local BAR_LABELS = { healthBar = "Health bar", powerBar = "Power bar", xpBar = "Experience bar" }
local RAID_DIRECTIONS = { { "DOWN", "Below each other (columns)" }, { "RIGHT", "Next to each other (rows)" } }
local AURA_POS = { { "BOTTOM", "Below the frame" }, { "TOP", "Above the frame" },
    { "RIGHT", "Right of the frame" }, { "LEFT", "Left of the frame" } }
local BUFF_FILTERS = { { "all", "All" }, { "own", "Only mine" }, { "raid", "Ones I can cast" } }
local DEBUFF_FILTERS = { { "all", "All" }, { "own", "Only mine" }, { "raid", "Ones I can dispel" } }

-- ------------------------------------------------------------ pages --

local pages = {}   -- { id, label, build(builder) }

local function addPage(id, text, build)
    table.insert(pages, { id = id, label = text, build = build })
end

addPage("general", "General", function(b)
    b:Header("General")
    b:Check("Lock frames (untick to move them)", function() return not ns.unlocked end,
        function(v) ns:SetLocked(v) end)
    b:Check("Show minimap button", function() return not LizzaricksUFDB.minimap.hide end,
        function(v) LizzaricksUFDB.minimap.hide = not v; ns.Minimap:Update() end)
    b:Dropdown("Bar texture", function()
        local list = {}
        for _, t in ipairs(ns.textures) do table.insert(list, { t[1], t[1] }) end
        return list
    end, function() return ns.db.texture end, function(v) ns.db.texture = v; ns:ApplyAll() end)
    b:Slider("Frame background alpha", 0, 1, 0.05, function() return ns.db.backgroundAlpha end,
        function(v) ns.db.backgroundAlpha = v; ns:ApplyAll() end)
    b:Header("Help")
    b:Text("Left click on a frame targets the unit, right click opens its menu.\n" ..
        "Hidden Blizzard frames come back after a /reload once you untick \"Hide Blizzard frame\".\n" ..
        "Settings changed in combat are applied when combat ends.", 48)
    b:Text("Commands: /lzuf (this window), /lzuf unlock, /lzuf lock, /lzuf profile <name>, /lzuf reset", 16)
end)

local function unitPage(key)
    return function(b)
        local function p(path) return unitPath(key, path) end
        local label = ns.unitLabels[key]

        b:Header(label)
        b:Check("Enabled", p("enabled"))
        if ns.blizzardFrames[key] then
            b:Check("Hide Blizzard frame", p("hideBlizzard"))
        end
        b:Slider("Width", 20, 600, 1, p("width"))
        b:Slider("Height", 10, 300, 1, p("height"))
        b:Slider("Scale", 0.5, 3, 0.05, p("scale"))
        if key == "partypet" then
            b:Text("Position is relative to the party member's frame.")
        end
        -- p() returns getter and setter; spelled out where more arguments follow
        local gx, sx = p("x")
        local gy, sy = p("y")
        b:Edit("X position", gx, sx, 80, true)
        b:Edit("Y position", gy, sy, 80, true)
        if key == "party" then
            b:Slider("Space between members", 0, 200, 1, p("spacing"))
            b:Check("Hide party frames in a raid", p("hideInRaid"))
        elseif key == "raid" then
            b:Header("Raid groups")
            b:Dropdown("Members of a group", RAID_DIRECTIONS, p("groupDirection"))
            b:Slider("Groups per row", 1, 8, 1, p("groupsPerRow"))
            b:Slider("Space between members", 0, 50, 1, p("spacing"))
            b:Slider("Space between groups", 0, 50, 1, p("groupSpacing"))
            b:Check("Move each group on its own", p("separateGroups"))
            b:Button("Groups back into the grid", function()
                ns.db.units.raid.groupPos = {}
                ns:ApplyKey("raid")
            end, 220)
        end
        if ns.Range and ns.Range.supported[key] then
            b:Header("Range")
            b:Check("Fade out of range", p("range.enabled"))
            b:Slider("Alpha out of range", 0, 1, 0.05, p("range.alpha"))
        end

        b:Header("Health bar")
        local colorTypes = COLOR_TYPES
        if key == "pet" then
            colorTypes = { { "happiness", "Happiness (red / yellow / green)" } }
            for _, c in ipairs(COLOR_TYPES) do table.insert(colorTypes, c) end
        end
        b:Dropdown("Colour", colorTypes, p("healthBar.colorType"))
        local ghw, shw = p("healthBar.weight")
        b:Slider("Height (weight)", 1, 10, 0.5, ghw, shw, "%.1f")
        b:Check("Background", p("healthBar.background"))
        b:Slider("Background alpha", 0, 1, 0.05, p("healthBar.backgroundAlpha"))

        b:Header("Incoming heals")
        b:Check("Show incoming heals (own dark green, others light green)", p("healPrediction.enabled"))
        b:Slider("May reach past the bar (1 = no, 1.3 = 30%)", 1, 1.3, 0.01, p("healPrediction.overflow"))
        b:Slider("Opacity", 0.1, 1, 0.05, p("healPrediction.alpha"))
        b:Check("Show absorb shields", p("healPrediction.absorbs"))

        b:Header("Power bar")
        b:Check("Enabled", p("powerBar.enabled"))
        local gpw, spw = p("powerBar.weight")
        b:Slider("Height (weight)", 1, 10, 0.5, gpw, spw, "%.1f")
        b:Check("Background", p("powerBar.background"))
        b:Slider("Background alpha", 0, 1, 0.05, p("powerBar.backgroundAlpha"))

        if key == "pet" then
            b:Header("Happiness")
            b:Check("Show happiness icon", p("happiness.enabled"))
            b:Slider("Icon size", 8, 32, 1, p("happiness.size"))
        end

        b:Header("Portrait")
        b:Check("Enabled", p("portrait.enabled"))
        b:Dropdown("Type", PORTRAIT_TYPES, p("portrait.type"))
        b:Dropdown("Side", SIDES, p("portrait.side"))
        b:Slider("Width (part of the frame)", 0.05, 0.5, 0.01, p("portrait.width"))

        if ns.UF.XP_SUPPORTED[key] then
            b:Header("Experience bar")
            b:Check("Enabled", p("xpBar.enabled"))
            local gxw, sxw = p("xpBar.weight")
            b:Slider("Height (weight)", 1, 10, 0.5, gxw, sxw, "%.1f")
        end

        if ns.CastBar and ns.CastBar.supported[key] then
            b:Header("Cast bar")
            b:Check("Enabled", p("castBar.enabled"))
            b:Slider("Height", 4, 40, 1, p("castBar.height"))
            b:Dropdown("Position", CAST_POS, p("castBar.position"))
            b:Check("Spell icon", p("castBar.icon"))
            if key == "player" then
                b:Check("Hide Blizzard cast bar", p("castBar.hideBlizzard"))
            end
        end

        if ns.Auras and ns.Auras.supported[key] then
            b:Header("Buffs and debuffs")
            b:Check("Show buffs", p("auras.buffs"))
            b:Dropdown("Which buffs", BUFF_FILTERS, p("auras.buffFilter"))
            b:Slider("Max. buffs", 1, 40, 1, p("auras.maxBuffs"))
            b:Check("Show debuffs", p("auras.debuffs"))
            b:Dropdown("Which debuffs", DEBUFF_FILTERS, p("auras.debuffFilter"))
            b:Slider("Max. debuffs", 1, 40, 1, p("auras.maxDebuffs"))
            b:Check("Colour debuff border by type (magic, poison ...)", p("auras.dispelColors"))
            b:Dropdown("Position", AURA_POS, p("auras.position"))
            b:Slider("Buff icon size", 8, 50, 1, p("auras.size"))
            b:Slider("Debuff icon size", 8, 60, 1, p("auras.debuffSize"))
            b:Slider("Space between icons", 0, 10, 1, p("auras.spacing"))
            b:Slider("Space between buffs and debuffs", 0, 30, 1, p("auras.groupGap"))
            b:Slider("Icons per row (left/right)", 1, 20, 1, p("auras.perRow"))
            b:Check("Remaining time under the icon", p("auras.duration"))
            b:Check("Cooldown swipe on the icon", p("auras.swipe"))
        end

        for _, bar in ipairs(ns.UF.BAR_KEYS) do
          if bar ~= "xpBar" or ns.UF.XP_SUPPORTED[key] then
            b:Header("Texts on the " .. BAR_LABELS[bar]:lower())
            b:Slider("Font size", 5, 24, 1, p("tags." .. bar .. ".size"))
            b:Edit("Left", p("tags." .. bar .. ".left"))
            b:Edit("Center", p("tags." .. bar .. ".center"))
            b:Edit("Right", p("tags." .. bar .. ".right"))
          end
        end
        b:Text("Texts use tags like [name] or [smarthealth]; see the Tags page.", 16)
    end
end

for _, key in ipairs(ns.unitKeys) do
    addPage(key, ns.unitLabels[key], unitPage(key))
end

addPage("tags", "Tags", function(b)
    b:Header("Tags")
    b:Text("Put tags in square brackets and combine them freely, e.g.\n" ..
        "[levelcolor][level][shortclassification] [classcolor][smartclass]", 32)
    for _, t in ipairs(ns.Tags.help) do
        b:Text("|cffffd100[" .. t[1] .. "]|r  " .. t[2], 14)
    end
    b:Text("Not possible in WoW: Forever (values the client keeps secret): calculated heal tags, " ..
        "single incoming heals, buff counts in combat.", 32)
end)

local newProfileName = ""
addPage("profiles", "Profiles", function(b)
    b:Header("Profiles")
    b:Text("Each character uses one profile. New characters start with \"Default\".", 16)
    b:Dropdown("Current profile", function()
        local list = {}
        for _, n in ipairs(ns:ProfileNames()) do table.insert(list, { n, n }) end
        return list
    end, function() return ns:CurrentProfile() end, function(v)
        ns:SetProfile(v)
    end)
    b:Edit("New profile", function() return newProfileName end, function(v) newProfileName = v end, 200)
    b:Button("Create and use", function()
        if newProfileName ~= "" then
            ns:SetProfile(newProfileName)
            newProfileName = ""
            O:Refresh()
        end
    end)
    b:Dropdown("Copy settings from", function()
        local list = {}
        for _, n in ipairs(ns:ProfileNames()) do
            if n ~= ns:CurrentProfile() then table.insert(list, { n, n }) end
        end
        return list
    end, function() return nil end, function(v) ns:CopyProfile(v) end)
    b:Dropdown("Delete profile", function()
        local list = {}
        for _, n in ipairs(ns:ProfileNames()) do
            if n ~= ns:CurrentProfile() then table.insert(list, { n, n }) end
        end
        return list
    end, function() return nil end, function(v) ns:DeleteProfile(v); O:Refresh() end)
    b:Button("Reset current profile", function() ns:ResetProfile() end)
end)

-- ------------------------------------------------------------ window --

local window, content, navButtons, current = nil, nil, {}, nil
local built = {}   -- page id -> { frame, builder }

local function showPage(id)
    current = id
    for pid, pg in pairs(built) do pg.frame:SetShown(pid == id) end
    if not built[id] then
        for _, page in ipairs(pages) do
            if page.id == id then
                local frame = CreateFrame("Frame", nil, content)
                frame:SetPoint("TOPLEFT")
                frame:SetWidth(content:GetWidth())
                local b = ns.Widgets.NewBuilder(frame, content:GetWidth())
                page.build(b)
                frame:SetHeight(b:Height())
                built[id] = { frame = frame, builder = b }
            end
        end
    end
    local pg = built[id]
    pg.builder:Refresh()
    content:SetHeight(pg.frame:GetHeight())
    window.scroll:SetVerticalScroll(0)
    for pid, btn in pairs(navButtons) do
        if pid == id then btn.sel:Show() else btn.sel:Hide() end
    end
end

local function build()
    local w = CreateFrame("Frame", "LizUFOptionsFrame", UIParent, "BackdropTemplate")
    w:SetSize(WIDTH, HEIGHT)
    w:SetPoint("CENTER")
    w:SetFrameStrata("DIALOG")
    w:SetToplevel(true)
    w:SetClampedToScreen(true)
    w:EnableMouse(true)
    w:SetMovable(true)
    w:RegisterForDrag("LeftButton")
    w:SetScript("OnDragStart", w.StartMoving)
    w:SetScript("OnDragStop", w.StopMovingOrSizing)
    w:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    w:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    w:SetBackdropBorderColor(0, 0, 0, 1)
    w:Hide()
    table.insert(UISpecialFrames, "LizUFOptionsFrame") -- Escape closes it

    local title = w:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cff9fd4ffLizzarick's|r Unit Frames  |cff888888" .. ns.version .. "|r")

    local close = CreateFrame("Button", nil, w, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- navigation
    local nav = CreateFrame("Frame", nil, w, "BackdropTemplate")
    nav:SetPoint("TOPLEFT", 10, -40)
    nav:SetPoint("BOTTOMLEFT", 10, 10)
    nav:SetWidth(NAV_W)
    nav:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    nav:SetBackdropColor(1, 1, 1, 0.03)
    local y = -6
    for _, page in ipairs(pages) do
        local btn = CreateFrame("Button", nil, nav)
        btn:SetSize(NAV_W - 8, 22)
        btn:SetPoint("TOPLEFT", 4, y)
        btn.sel = btn:CreateTexture(nil, "BACKGROUND")
        btn.sel:SetAllPoints()
        btn.sel:SetColorTexture(0.62, 0.83, 1, 0.2)
        btn.sel:Hide()
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT", 8, 0)
        fs:SetText(page.label)
        btn:SetScript("OnClick", function() showPage(page.id) end)
        navButtons[page.id] = btn
        y = y - 24
        if page.id == "general" or page.id == "raid" then y = y - 8 end
    end

    -- page area
    local scroll = CreateFrame("ScrollFrame", "LizUFOptionsScroll", w, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", nav, "TOPRIGHT", 10, 0)
    scroll:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -32, 10)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH - NAV_W - 60, 10)
    scroll:SetScrollChild(content)
    w.scroll = scroll

    window = w
    showPage("general")
end

function O:Toggle()
    if not window then build() end
    if window:IsShown() then window:Hide() else window:Show(); O:Refresh() end
end

function O:Open(id)
    if not window then build() end
    window:Show()
    if id then showPage(id) end
    O:Refresh()
end

-- Re-reads all values of the visible page.
function O:Refresh()
    if window and window:IsShown() and current and built[current] then
        built[current].builder:Refresh()
    end
end

-- ------------------------------------------------ Blizzard integration --

-- A short page in Options -> AddOns that points to the real window.
-- (Closing Blizzard's settings panel from addon code is forbidden, so the
-- button only opens ours on top.)
ns:OnLogin(function()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    local panel = CreateFrame("Frame")
    local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 16, -16)
    text:SetText("Lizzarick's Unit Frames\n\nType /lzuf or click the minimap button.")
    text:SetJustifyH("LEFT")
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(200, 24)
    btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -12)
    btn:SetText("Open the options")
    btn:SetScript("OnClick", function()
        O:Open()
        if window then window:SetFrameStrata("FULLSCREEN_DIALOG") end
    end)
    local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, "Lizzarick's Unit Frames")
    if ok and category then pcall(Settings.RegisterAddOnCategory, category) end
end)

-- The addon compartment button (TOC: AddonCompartmentFunc).
function LizUF_OnAddonCompartmentClick()
    O:Toggle()
end

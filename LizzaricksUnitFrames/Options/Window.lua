-- LizzaricksUnitFrames / Options / Window
--
-- The options window: page list on the left, the page on the right in a
-- scroll frame; unit pages have a row of tabs above it, as in Luna. Opened with /lzuf, the minimap button or the addon
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

-- Setter for "Hide Blizzard ..." boxes: unticking one that already hid a
-- frame offers the reload that brings the Blizzard frame back.
local function blizzardToggle(get, set, what, label)
    return get, function(v)
        set(v)
        if not v and ns:IsBlizzardHidden(what) then
            ns:AskReload(label .. " will show again.")
        end
    end
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
local LIST_MODES = { { "exclude", "Hide the auras in the list" }, { "include", "Show only the auras in the list" } }

-- Filter lists for a dropdown, "None" first.
local function filterListOptions()
    local list = { { "", "None" } }
    for _, n in ipairs(ns.Filters.Names()) do table.insert(list, { n, n }) end
    return list
end

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

-- A unit page is a set of tabs, as in Luna. Each tab builds its own list of
-- controls; tabs that do not apply to a unit are left out.
local function unitTabs(key)
    local function p(path) return unitPath(key, path) end
    local label = ns.unitLabels[key]
    local tabs = {}
    local function tab(id, text, build) table.insert(tabs, { id = id, label = text, build = build }) end

    tab("general", "General", function(b)
        b:Header(label)
        b:Check("Enabled", p("enabled"))
        if ns.blizzardFrames[key] then
            local g, s = p("hideBlizzard")
            b:Check("Hide Blizzard frame", blizzardToggle(g, s, key, "Blizzard's " .. label:lower() .. " frame"))
        end
        b:Header("Size and position")
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
            b:Header("Party")
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
    end)

    tab("health", "Health bar", function(b)
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
    end)

    tab("power", "Power bar", function(b)
        b:Header("Power bar")
        b:Check("Enabled", p("powerBar.enabled"))
        local gpw, spw = p("powerBar.weight")
        b:Slider("Height (weight)", 1, 10, 0.5, gpw, spw, "%.1f")
        b:Check("Background", p("powerBar.background"))
        b:Slider("Background alpha", 0, 1, 0.05, p("powerBar.backgroundAlpha"))
    end)

    if ns.CastBar and ns.CastBar.supported[key] then
        tab("cast", "Cast bar", function(b)
            b:Header("Cast bar")
            b:Check("Enabled", p("castBar.enabled"))
            b:Slider("Height", 4, 40, 1, p("castBar.height"))
            b:Dropdown("Position", CAST_POS, p("castBar.position"))
            b:Check("Spell icon", p("castBar.icon"))
            if key == "player" then
                local g, s = p("castBar.hideBlizzard")
                b:Check("Hide Blizzard cast bar", blizzardToggle(g, s, "playercast", "Blizzard's cast bar"))
            end
        end)
    end

    if ns.UF.XP_SUPPORTED[key] then
        tab("xp", "XP bar", function(b)
            b:Header("Experience bar")
            b:Check("Enabled", p("xpBar.enabled"))
            local gxw, sxw = p("xpBar.weight")
            b:Slider("Height (weight)", 1, 10, 0.5, gxw, sxw, "%.1f")
        end)
    end

    tab("portrait", "Portrait", function(b)
        b:Header("Portrait")
        b:Check("Enabled", p("portrait.enabled"))
        b:Dropdown("Type", PORTRAIT_TYPES, p("portrait.type"))
        b:Dropdown("Side", SIDES, p("portrait.side"))
        b:Slider("Width (part of the frame)", 0.05, 0.5, 0.01, p("portrait.width"))
    end)

    tab("heals", "Incoming heals", function(b)
        b:Header("Incoming heals")
        b:Check("Show incoming heals (own dark green, others light green)", p("healPrediction.enabled"))
        b:Slider("May reach past the bar (1 = no, 1.3 = 30%)", 1, 1.3, 0.01, p("healPrediction.overflow"))
        b:Slider("Opacity", 0.1, 1, 0.05, p("healPrediction.alpha"))
        b:Check("Show absorb shields", p("healPrediction.absorbs"))
    end)

    if ns.Auras and ns.Auras.supported[key] then
        tab("auras", "Auras", function(b)
            b:Header("Buffs")
            b:Check("Show buffs", p("auras.buffs"))
            b:Dropdown("Which buffs", BUFF_FILTERS, p("auras.buffFilter"))
            b:Slider("Max. buffs", 1, 40, 1, p("auras.maxBuffs"))
            b:Slider("Buff icon size", 8, 50, 1, p("auras.size"))
            b:Header("Debuffs")
            b:Check("Show debuffs", p("auras.debuffs"))
            b:Dropdown("Which debuffs", DEBUFF_FILTERS, p("auras.debuffFilter"))
            b:Slider("Max. debuffs", 1, 40, 1, p("auras.maxDebuffs"))
            b:Slider("Debuff icon size", 8, 60, 1, p("auras.debuffSize"))
            b:Check("Colour debuff border by type (magic, poison ...)", p("auras.dispelColors"))
            b:Header("Filter lists")
            b:Text("Lists are made on the Filters page. WoW: Forever only checks spell IDs of buffs on " ..
                "friendly units and debuffs on hostile ones. \"Hide\" leaves auras it cannot check " ..
                "visible; \"show only\" hides them (e.g. every debuff on your party).", 44)
            b:Dropdown("Buff filter list", filterListOptions, p("auras.buffList"))
            b:Dropdown("Buff list mode", LIST_MODES, p("auras.buffListMode"))
            b:Dropdown("Debuff filter list", filterListOptions, p("auras.debuffList"))
            b:Dropdown("Debuff list mode", LIST_MODES, p("auras.debuffListMode"))
            b:Header("Layout")
            b:Dropdown("Position", AURA_POS, p("auras.position"))
            b:Slider("Space between icons", 0, 10, 1, p("auras.spacing"))
            b:Slider("Space between buffs and debuffs", 0, 30, 1, p("auras.groupGap"))
            b:Slider("Icons per row (left/right)", 1, 20, 1, p("auras.perRow"))
            b:Check("Remaining time under the icon", p("auras.duration"))
            b:Check("Cooldown swipe on the icon", p("auras.swipe"))
        end)
    end

    if ns.Range and ns.Range.supported[key] then
        tab("range", "Range", function(b)
            b:Header("Range")
            b:Check("Fade out of range", p("range.enabled"))
            b:Slider("Alpha out of range", 0, 1, 0.05, p("range.alpha"))
        end)
    end

    tab("borders", "Borders", function(b)
        b:Header("Borders")
        b:Check("On mouseover", p("borders.mouseover"))
        b:Check("On aggro", p("borders.aggro"))
        if ns.Borders.debuffSupported[key] then
            b:Dropdown("On debuff", ns.Borders.DEBUFF_MODES, p("borders.debuff"))
            b:Text("The debuff border is coloured by type (magic blue, curse purple, poison green, " ..
                "disease brown, others red) and wins over aggro and mouseover.", 30)
        end
        b:Slider("Size", 1, 10, 1, p("borders.size"))
        b:Check("Always on top (above auras, squares and icons)", p("borders.onTop"))
    end)

    do
        tab("indicators", "Indicators", function(b)
            for _, k in ipairs(ns.Indicators.KINDS) do
                local base = "indicators." .. k[1] .. "."
                b:Header(k[2])
                b:Check("Enabled", p(base .. "enabled"))
                b:Slider("Size", 5, 40, 1, p(base .. "size"))
                b:Dropdown("Point", ns.Indicators.POINTS, p(base .. "point"))
                b:Slider("X position", -50, 50, 1, p(base .. "x"))
                b:Slider("Y position", -100, 100, 1, p(base .. "y"))
            end
            b:Header("Elite")
            b:Text("A dragon on the side of the frame for elite, rare and boss units.", 16)
            b:Check("Enabled", p("indicators.elite.enabled"))
            b:Dropdown("Side", ns.Indicators.SIDES, p("indicators.elite.side"))
            local ges, ses = p("indicators.elite.scale")
            b:Slider("Size (x frame height)", 0.5, 3, 0.1, ges, ses, "%.1f")
            if ns.Status and ns.Status.supported[key] then
                b:Header("Status icon")
                b:Text("Crossed swords in combat, Zzz while resting.")
                b:Check("Show status icon", p("status.enabled"))
                b:Slider("Size", 8, 40, 1, p("status.size"))
                b:Dropdown("Position on the frame", ns.Status.POINTS, p("status.point"))
            end
            if key == "pet" then
                b:Header("Happiness")
                b:Text("The health bar shows the happiness as its colour (Health bar tab).")
                b:Check("Show happiness icon", p("happiness.enabled"))
                b:Slider("Icon size", 8, 32, 1, p("happiness.size"))
            end
        end)
    end

    if ns.Squares and ns.Squares.supported[key] then
        tab("squares", "Squares", function(b)
            b:Text("Nine small indicators on the frame. Aura squares match by spell: type spell IDs or " ..
                "names of spells from your spellbook, separated by ; (e.g. Demon Armor; 10938). " ..
                "WoW: Forever only matches buffs on friendly units and debuffs on hostile ones.", 44)
            for _, pos in ipairs(ns.Squares.POSITIONS) do
                local base = "squares." .. pos[1] .. "."
                b:Header(pos[2])
                b:Check("Enabled", p(base .. "enabled"))
                b:Dropdown("Type", ns.Squares.TYPES, p(base .. "type"))
                b:Slider("Size", 4, 40, 1, p(base .. "size"))
                local gs, ss = p(base .. "spells")
                b:Edit("Spells (for list types)", gs, function(v)
                    local _, unknown = ns.Squares.ParseSpells(v)
                    if #unknown > 0 then
                        ns:Print("Unknown spell (use its ID): %s", table.concat(unknown, ", "))
                    end
                    ss(v)
                end)
                b:Dropdown("Spells from filter list", filterListOptions, p(base .. "list"))
                b:Check("Show the spell icon instead of a colour", p(base .. "texture"))
                b:Check("Timer (cooldown swipe)", p(base .. "timer"))
                b:Slider("X offset", -50, 50, 1, p(base .. "x"))
                b:Slider("Y offset", -50, 50, 1, p(base .. "y"))
            end
        end)
    end

    tab("tags", "Tags", function(b)
        for _, bar in ipairs(ns.UF.BAR_KEYS) do
            if bar ~= "xpBar" or ns.UF.XP_SUPPORTED[key] then
                b:Header(BAR_LABELS[bar])
                b:Slider("Font size", 5, 24, 1, p("tags." .. bar .. ".size"))
                b:Edit("Left", p("tags." .. bar .. ".left"))
                b:Edit("Center", p("tags." .. bar .. ".center"))
                b:Edit("Right", p("tags." .. bar .. ".right"))
            end
        end
        b:Text("Texts use tags like [name] or [smarthealth]; see the Tags page.", 16)
    end)

    return tabs
end

for _, key in ipairs(ns.unitKeys) do
    table.insert(pages, { id = key, label = ns.unitLabels[key], tabs = unitTabs(key) })
end

-- Luna's filter lists: make lists, find auras by name or ID (with rank),
-- export and import them.
local newListName, renameTo, importText, searchText = "", "", "", ""
local deleteArmed = false
addPage("filters", "Filters", function(b)
    local FL = ns.Filters
    local function selected()
        if not FL.Get(FL.selected) then FL.selected = FL.Names()[1] end
        return FL.selected
    end
    local function report(ok, err)
        if not ok and err then ns:Print("%s", err) end
        O:Refresh()
    end
    FL.onChange = function() O:Refresh() end

    b:Header("Filter lists")
    b:Text("Lists of auras for the Auras and Squares tabs of each frame. Shared by all characters.", 16)
    b:Dropdown("Filter list", function()
        local list = {}
        for _, n in ipairs(FL.Names()) do table.insert(list, { n, n }) end
        return list
    end, selected, function(v) FL.selected = v; O:Refresh() end)
    b:Edit("New filter list", function() return newListName end, function(v) newListName = v end, 200)
    b:Button("Create", function()
        local name, err = FL.Create(newListName)
        if name then newListName = "" end
        report(name, err)
    end)
    b:Edit("Rename to", function() return renameTo end, function(v) renameTo = v end, 200)
    b:Button("Rename", function()
        local name, err = FL.Rename(selected(), renameTo)
        if name then renameTo = "" end
        report(name, err)
    end)
    local del
    del = b:Button("Delete list", function()
        if not selected() then return end
        if not deleteArmed then
            deleteArmed = true
            del:SetText("Click again to delete")
            C_Timer.After(3, function() deleteArmed = false; del:SetText("Delete list") end)
            return
        end
        deleteArmed = false
        del:SetText("Delete list")
        FL.Delete(selected())
        O:Refresh()
    end, 180)

    b:Header("Auras in filter")
    b:Text(function() return selected() and ("List: |cffffd100" .. selected() .. "|r") or "No list yet." end, 16)
    b:List(10, function() return FL.Items(selected()) end, "Remove", function(item)
        FL.Remove(selected(), item.id)
    end)

    b:Header("Add aura")
    b:Edit("Search name or ID", function() return searchText end, function(v)
        local changedQuery = v ~= searchText
        searchText = v
        if changedQuery or not FL.search then FL.Search(v) end
    end, 200)
    b:Text(function()
        local s = FL.SearchStatus()
        if not selected() then s = s .. "  |cffff5555Create a list first.|r" end
        return s
    end, 16)
    b:List(10, function()
        local items, list = FL.SearchItems(), FL.Get(selected())
        for _, item in ipairs(items) do
            if list and list[item.id] then item.actionText, item.disabled = "Added", true end
        end
        return items
    end, "Add", function(item)
        if not selected() then ns:Print("Create a filter list first.") return end
        FL.Add(selected(), item.id)
    end)

    b:Header("Export / Import")
    local exp = b:Edit("Export (copy this)", function() return FL.Export(selected()) end, function() end, 360)
    exp.edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    b:Edit("Import string", function() return importText end, function(v) importText = v end, 360)
    b:Button("Import", function()
        local name, err = FL.Import(importText)
        if name then
            importText = ""
            ns:Print("Imported filter list \"%s\".", name)
        end
        report(name, err)
    end)
end)

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

local window, content, tabBar, navButtons, current = nil, nil, nil, {}, nil
local built = {}      -- "page" or "page:tab" -> { frame, builder }
local lastTab = {}    -- page id -> tab id shown last
local wantedTab       -- tab id to keep when switching pages (as Luna does)
local tabButtons = {}

local TAB_H, TAB_GAP = 22, 3

local function pageById(id)
    for _, page in ipairs(pages) do
        if page.id == id then return page end
    end
end

-- Lays out the tab buttons of a page in rows; returns the bar height.
local function layoutTabs(page, tabId, onClick)
    for _, btn in ipairs(tabButtons) do btn:Hide() end
    if not page.tabs then return 0 end
    local width = WIDTH - NAV_W - 32
    local x, y = 0, 0
    for i, t in ipairs(page.tabs) do
        local btn = tabButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.text:SetPoint("CENTER")
            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.08)
            tabButtons[i] = btn
        end
        btn.tabId = t.id
        btn.text:SetText(t.label)
        local w = math.max(70, math.floor(btn.text:GetStringWidth() + 22))
        if x > 0 and x + w > width then
            x, y = 0, y + TAB_H + TAB_GAP
        end
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", tabBar, "TOPLEFT", x, -y)
        btn:SetSize(w, TAB_H)
        local selected = t.id == tabId
        btn:SetBackdropColor(0.62, 0.83, 1, selected and 0.25 or 0.06)
        btn:SetBackdropBorderColor(0.62, 0.83, 1, selected and 0.8 or 0.25)
        btn.text:SetTextColor(1, selected and 0.82 or 1, selected and 0 or 1)
        btn:SetScript("OnClick", function() onClick(t.id) end)
        btn:Show()
        x = x + w + TAB_GAP
    end
    return y + TAB_H + 8
end

local function showPage(id, tabId)
    local page = pageById(id)
    if not page then return end
    if page.tabs then
        -- keep the tab the user was on if this page has it, else its own last one
        local function has(t)
            for _, tb in ipairs(page.tabs) do if tb.id == t then return true end end
        end
        tabId = tabId or (wantedTab and has(wantedTab) and wantedTab) or lastTab[id] or page.tabs[1].id
        if not has(tabId) then tabId = page.tabs[1].id end
        lastTab[id], wantedTab = tabId, tabId
    end
    local key = page.tabs and (id .. ":" .. tabId) or id
    current = key

    local barH = layoutTabs(page, tabId, function(t) showPage(id, t) end)
    window.scroll:ClearAllPoints()
    window.scroll:SetPoint("TOPLEFT", tabBar, "TOPLEFT", 0, -barH)
    window.scroll:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -32, 10)

    for k, pg in pairs(built) do pg.frame:SetShown(k == key) end
    if not built[key] then
        local buildFn = page.build
        if page.tabs then
            for _, t in ipairs(page.tabs) do
                if t.id == tabId then buildFn = t.build end
            end
        end
        local frame = CreateFrame("Frame", nil, content)
        frame:SetPoint("TOPLEFT")
        frame:SetWidth(content:GetWidth())
        local b = ns.Widgets.NewBuilder(frame, content:GetWidth())
        buildFn(b)
        frame:SetHeight(b:Height())
        built[key] = { frame = frame, builder = b }
    end
    local pg = built[key]
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

    -- tab bar (unit pages) above the scrolling page area
    tabBar = CreateFrame("Frame", nil, w)
    tabBar:SetPoint("TOPLEFT", nav, "TOPRIGHT", 10, 0)
    -- fixed width: the window may still be hidden when the tabs are laid out
    tabBar:SetSize(WIDTH - NAV_W - 32, 1)

    local scroll = CreateFrame("ScrollFrame", "LizUFOptionsScroll", w, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", tabBar, "TOPLEFT", 0, 0)
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

-- LizzaricksUnitFrames / Options / Widgets
--
-- The few controls the options window needs, built on Blizzard templates
-- that exist in the 1.60.1 client (checked in the UI source):
-- UICheckButtonTemplate, UISliderTemplate, WowStyle1DropdownTemplate
-- (MenuUtil), InputBoxTemplate, UIPanelButtonTemplate.
--
-- Every control is bound to a getter and a setter and has :Refresh(),
-- which re-reads the getter (after a profile switch or a drag in config
-- mode). A page is a vertical list of rows built with the Builder below.
local _, ns = ...

local W = {}
ns.Widgets = W

local ROW = 26
local LABEL_W = 170

local function label(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetText(text)
    fs:SetJustifyH("LEFT")
    return fs
end

-- ------------------------------------------------------------ builder --

local Builder = {}
Builder.__index = Builder

-- parent: the page frame; width: usable width.
function W.NewBuilder(parent, width)
    return setmetatable({ parent = parent, width = width, y = -8, widgets = {} }, Builder)
end

function Builder:Add(widget, height)
    widget:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 8, self.y)
    self.y = self.y - (height or ROW)
    if widget.Refresh then table.insert(self.widgets, widget) end
    return widget
end

function Builder:Height()
    return -self.y + 8
end

function Builder:Refresh()
    for _, w in ipairs(self.widgets) do w:Refresh() end
end

function Builder:Header(text)
    self.y = self.y - 6
    local f = CreateFrame("Frame", nil, self.parent)
    f:SetSize(self.width - 16, 20)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetPoint("LEFT")
    fs:SetText(text)
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.3)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, -2)
    line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -2)
    return self:Add(f, 28)
end

-- text: a string, or a function returning one (re-read on Refresh).
function Builder:Text(text, height)
    local f = CreateFrame("Frame", nil, self.parent)
    f:SetSize(self.width - 16, height or 16)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetAllPoints()
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    f.fontString = fs
    if type(text) == "function" then
        function f:Refresh() fs:SetText(text()) end
        f:Refresh()
    else
        fs:SetText(text)
    end
    return self:Add(f, (height or 16) + 4)
end

-- A page of spell rows (icon, text, one button each) with paging.
-- items(): { { id =, icon =, text =, actionText =, disabled = }, ... };
-- onAction(item) for the button.
function Builder:List(count, items, action, onAction)
    local ROW_H = 22
    local width = self.width - 16
    local f = CreateFrame("Frame", nil, self.parent)
    f:SetSize(width, count * ROW_H + 26)
    local page = 1
    f.rows = {}
    for i = 1, count do
        local r = CreateFrame("Frame", nil, f)
        r:SetSize(width, ROW_H - 2)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(i - 1) * ROW_H)
        local bg = r:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.04 or 0.02)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", 2, 0)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.text = label(r, "")
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.text:SetWidth(width - 120)
        r.button = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
        r.button:SetSize(80, 18)
        r.button:SetPoint("RIGHT", -2, 0)
        r.button:SetText(action)
        r.button:SetScript("OnClick", function() if r.item then onAction(r.item) end end)
        -- hovering a row shows the spell's tooltip
        r:EnableMouse(true)
        r:SetScript("OnEnter", function()
            if not r.item then return end
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            if not pcall(GameTooltip.SetSpellByID, GameTooltip, r.item.id) then
                GameTooltip:SetText(r.item.text)
            end
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.rows[i] = r
    end
    local prev = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    prev:SetSize(60, 20)
    prev:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -count * ROW_H - 2)
    prev:SetText("<")
    local next = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    next:SetSize(60, 20)
    next:SetPoint("LEFT", prev, "RIGHT", 4, 0)
    next:SetText(">")
    local info = label(f, "")
    info:SetPoint("LEFT", next, "RIGHT", 10, 0)
    f.prev, f.next = prev, next
    function f:Refresh()
        local list = items()
        local pages = math.max(1, math.ceil(#list / count))
        page = math.max(1, math.min(page, pages))
        for i, r in ipairs(f.rows) do
            local item = list[(page - 1) * count + i]
            r.item = item
            r:SetShown(item ~= nil)
            if item then
                r.icon:SetTexture(item.icon)
                r.text:SetText(item.text)
                -- an item may relabel or disable its button ("Added")
                r.button:SetText(item.actionText or action)
                r.button:SetEnabled(not item.disabled)
            end
        end
        info:SetText(#list == 0 and "|cff888888(empty)|r" or string.format("Page %d / %d   (%d)", page, pages, #list))
        prev:SetEnabled(page > 1)
        next:SetEnabled(page < pages)
    end
    prev:SetScript("OnClick", function() page = page - 1; f:Refresh() end)
    next:SetScript("OnClick", function() page = page + 1; f:Refresh() end)
    f:Refresh()
    return self:Add(f, count * ROW_H + 30)
end

function Builder:Check(text, get, set)
    local f = CreateFrame("Frame", nil, self.parent)
    f:SetSize(self.width - 16, ROW)
    local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("LEFT")
    local fs = label(f, text)
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    f.check = cb
    function f:Refresh() cb:SetChecked(get() and true or false) end
    f:Refresh()
    return self:Add(f)
end

-- fmt: format for the value text, e.g. "%d" or "%.2f".
function Builder:Slider(text, min, max, step, get, set, fmt)
    fmt = fmt or (step < 1 and "%.2f" or "%d")
    local f = CreateFrame("Frame", nil, self.parent)
    f:SetSize(self.width - 16, ROW + 4)
    local fs = label(f, text)
    fs:SetPoint("LEFT")
    fs:SetWidth(LABEL_W)
    local s = CreateFrame("Slider", nil, f, "UISliderTemplate")
    s:SetPoint("LEFT", f, "LEFT", LABEL_W + 8, 0)
    s:SetSize(220, 16)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    -- The value can also be typed in (Enter applies it; it is kept inside
    -- min..max and snapped to the step).
    local value = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    value:SetAutoFocus(false)
    value:SetSize(52, 20)
    value:SetPoint("LEFT", s, "RIGHT", 16, 0)
    value:SetJustifyH("CENTER")
    local function show(v)
        if not value:HasFocus() then value:SetText(string.format(fmt, v)) end
    end
    local function commit(box)
        -- extra parentheses: gsub also returns a count, which tonumber would
        -- take as the number base
        local v = tonumber(((box:GetText() or ""):gsub(",", "."))) -- "0,35" works too
        if v then
            v = math.max(min, math.min(max, v))
            v = min + math.floor((v - min) / step + 0.5) * step
            s:SetValue(v)
        end
        box:ClearFocus()
        show(s:GetValue())
    end
    value:SetScript("OnEnterPressed", commit)
    value:SetScript("OnEditFocusLost", function(box) show(s:GetValue()) end)
    value:SetScript("OnEscapePressed", function(box) box:ClearFocus(); show(s:GetValue()) end)
    f.valueBox = value
    local refreshing = false
    s:SetScript("OnValueChanged", function(_, v)
        show(v)
        if not refreshing then set(v) end
    end)
    s:EnableMouseWheel(true)
    s:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(math.max(min, math.min(max, self:GetValue() + delta * step)))
    end)
    f.slider = s
    function f:Refresh()
        refreshing = true
        local v = tonumber(get()) or min
        s:SetValue(v)
        show(v)
        refreshing = false
    end
    f:Refresh()
    return self:Add(f, ROW + 6)
end

-- options: { { value, text }, ... } or a function returning that list.
function Builder:Dropdown(text, options, get, set)
    local f = CreateFrame("Frame", nil, self.parent)
    f:SetSize(self.width - 16, ROW + 4)
    local fs = label(f, text)
    fs:SetPoint("LEFT")
    fs:SetWidth(LABEL_W)
    local dd = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
    dd:SetPoint("LEFT", f, "LEFT", LABEL_W + 8, 0)
    dd:SetWidth(200)
    dd:SetupMenu(function(_, root)
        local list = type(options) == "function" and options() or options
        for _, o in ipairs(list) do
            root:CreateRadio(o[2], function() return get() == o[1] end, function() set(o[1]) end, o[1])
        end
    end)
    f.dropdown = dd
    function f:Refresh() dd:GenerateMenu() end
    return self:Add(f, ROW + 6)
end

-- numeric: store numbers (invalid input is thrown away).
function Builder:Edit(text, get, set, width, numeric)
    local f = CreateFrame("Frame", nil, self.parent)
    f:SetSize(self.width - 16, ROW)
    local fs = label(f, text)
    fs:SetPoint("LEFT")
    fs:SetWidth(LABEL_W)
    local e = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    e:SetAutoFocus(false)
    e:SetSize(width or 320, 20)
    e:SetPoint("LEFT", f, "LEFT", LABEL_W + 14, 0)
    local function commit(self)
        local v = self:GetText()
        if numeric then
            v = tonumber(v)
            if not v then f:Refresh() return end
        end
        set(v)
    end
    e:SetScript("OnEnterPressed", function(self) commit(self) self:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(self) f:Refresh() self:ClearFocus() end)
    e:SetScript("OnEditFocusLost", commit)
    f.edit = e
    function f:Refresh()
        if e:HasFocus() then return end
        e:SetText(tostring(get() or ""))
        e:SetCursorPosition(0)
    end
    f:Refresh()
    return self:Add(f)
end

function Builder:Button(text, fn, width)
    local b = CreateFrame("Button", nil, self.parent, "UIPanelButtonTemplate")
    b:SetSize(width or 180, 22)
    b:SetText(text)
    b:SetScript("OnClick", fn)
    return self:Add(b, ROW + 2)
end

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

function Builder:Text(text, height)
    local f = CreateFrame("Frame", nil, self.parent)
    f:SetSize(self.width - 16, height or 16)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetAllPoints()
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetText(text)
    return self:Add(f, (height or 16) + 4)
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
    local value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("LEFT", s, "RIGHT", 10, 0)
    local refreshing = false
    s:SetScript("OnValueChanged", function(_, v)
        value:SetFormattedText(fmt, v)
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
        value:SetFormattedText(fmt, v)
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

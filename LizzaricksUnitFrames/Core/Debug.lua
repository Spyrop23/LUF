-- LizzaricksUnitFrames / Core / Debug
--
-- Errors we catch (event handlers, tag functions, tickers) are kept here
-- instead of vanishing: most players have Lua errors switched off, so a bug
-- would otherwise only show as "something does not update". The first one
-- in a session prints a hint; /luf debug shows a report to copy into a
-- comment (version, game, every error with its count).
local _, ns = ...

local MAX_ERRORS = 50
local errors, byKey = {}, {}
local hinted = false

function ns.LogError(where, err)
    local msg = tostring(err or "?")
    local key = where .. "\0" .. msg
    local e = byKey[key]
    if e then
        e.count = e.count + 1
        return
    end
    if #errors >= MAX_ERRORS then return end
    e = { where = where, msg = msg, count = 1, time = date and date("%H:%M:%S") or "" }
    byKey[key] = e
    table.insert(errors, e)
    if not hinted then
        hinted = true
        if ns.Print then
            ns:Print("caught an error. Type |cffffff00/luf debug|r to see it (please send it along when you report a bug).")
        end
    end
end

-- pcall that reports a failure; returns pcall's results.
function ns.Try(where, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then ns.LogError(where, err) end
    return ok, err
end

function ns.Errors() return errors end

function ns.ClearErrors()
    errors, byKey = {}, {}
end

local function gameName()
    if ns.isForever then return "WoW: Forever" end
    if ns.isRetail then return "Retail" end
    return "unknown game"
end

function ns.DebugReport()
    local lines = {}
    local version, build, _, toc = "?", "?", nil, "?"
    if GetBuildInfo then version, build, _, toc = GetBuildInfo() end
    table.insert(lines, ("Lizzarick's Unit Frames %s, %s %s (%s, interface %s), %s"):format(
        ns.version or "?", gameName(), tostring(version), tostring(build), tostring(toc),
        GetLocale and GetLocale() or "?"))
    if #errors == 0 then
        table.insert(lines, "No errors caught this session.")
    end
    for i, e in ipairs(errors) do
        table.insert(lines, ("%d) [%s] %s x%d: %s"):format(i, e.time, e.where, e.count, e.msg))
    end
    return table.concat(lines, "\n")
end

-- A small window with the report in a text box (Ctrl+A, Ctrl+C to copy).
local window
function ns.ShowDebug()
    if not window then
        window = CreateFrame("Frame", "LizUFDebugWindow", UIParent)
        window:SetSize(560, 320)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:EnableMouse(true)
        window:SetMovable(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        local bg = window:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
        local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 12, -10)
        title:SetText("Lizzarick's Unit Frames: debug report (Ctrl+A, Ctrl+C to copy)")
        local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 2, 2)
        close:SetScript("OnClick", function() window:Hide() end)   -- also in combat
        local scroll = CreateFrame("ScrollFrame", "LizUFDebugScroll", window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -32)
        scroll:SetPoint("BOTTOMRIGHT", -32, 12)
        local box = CreateFrame("EditBox", nil, scroll)
        box:SetMultiLine(true)
        box:SetAutoFocus(false)
        box:SetFontObject(ChatFontNormal)
        box:SetWidth(510)
        box:SetScript("OnEscapePressed", function() window:Hide() end)
        scroll:SetScrollChild(box)
        window.box = box
    end
    window.box:SetText(ns.DebugReport())
    window.box:HighlightText()
    window.box:SetFocus()
    window:Show()
end

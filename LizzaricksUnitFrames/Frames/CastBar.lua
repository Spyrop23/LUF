-- LizzaricksUnitFrames / Frames / CastBar
--
-- A cast bar below (or above) a unit frame, shown only while the unit casts.
--
-- For other units every cast field can be secret in combat: name, icon,
-- times, spell id, "not interruptible". So:
--   * the fill is a timer the CLIENT runs: StatusBar:SetTimerDuration with
--     the cast's duration object (UnitCastingDuration / UnitChannelDuration);
--   * name and icon go straight into SetText / SetTexture;
--   * the remaining time is formatted from the duration object's own getter
--     with SetFormattedText, which accepts the secret number;
--   * "is there a cast" is asked with type(v) ~= "nil", which works on secrets.
-- Whether a cast is a channel comes from the event that started it, which is
-- our own plain boolean.
--
-- Stop events hide the bar and never ask the client again: under restriction
-- a cast that just ended can still come back from UnitCastingInfo as a
-- secret tuple and would look like a running cast.
local _, ns = ...

local CB = {}
ns.CastBar = CB

-- Settings keys that offer a cast bar (as in Luna).
CB.supported = { player = true, target = true, focus = true, party = true }

local ELAPSED   = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.ElapsedTime or 0
local REMAINING = Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime or 1
local IMMEDIATE = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or 0

local CAST_EVENTS = {
    UNIT_SPELLCAST_START = "start",
    UNIT_SPELLCAST_DELAYED = "start",
    UNIT_SPELLCAST_CHANNEL_START = "channel",
    UNIT_SPELLCAST_CHANNEL_UPDATE = "channel",
    UNIT_SPELLCAST_STOP = "stop",
    UNIT_SPELLCAST_INTERRUPTED = "stop",
    UNIT_SPELLCAST_CHANNEL_STOP = "stop",
    UNIT_SPELLCAST_FAILED = "failed",
}

local function exists(v)
    return type(v) ~= "nil"
end

-- ------------------------------------------------------------ ticker --

local casting = {}
local ticker = CreateFrame("Frame")
local wait = 0

local function tick(_, elapsed)
    wait = wait + elapsed
    if wait < 0.05 then return end
    wait = 0
    local any = false
    for cb in pairs(casting) do
        any = true
        local dur = cb.duration
        if exists(dur) then
            pcall(function()
                cb.time:SetFormattedText("%.1f", dur:GetRemainingDuration())
            end)
        end
    end
    if not any then ticker:SetScript("OnUpdate", nil) end
end

local function track(cb, on)
    if on then
        casting[cb] = true
        ticker:SetScript("OnUpdate", tick)
    else
        casting[cb] = nil
    end
end

-- ------------------------------------------------------------ show/hide --

local function enabled(f)
    return CB.supported[f.key] and f.db.castBar.enabled
end

function CB.Stop(f)
    local cb = f.castBar
    if not cb then return end
    cb.duration = nil
    track(cb, false)
    if not cb.preview then cb:Hide() end
end

-- isChannel: true/false from the starting event, nil to find out (a unit
-- that is already casting when it appears).
function CB.Start(f, isChannel)
    local cb = f.castBar
    if not cb or not enabled(f) then return end
    local unit = f.unit

    local name, texture
    if isChannel ~= true then
        local n, _, t = UnitCastingInfo(unit)
        if exists(n) then name, texture, isChannel = n, t, false end
    end
    if not exists(name) and isChannel ~= false then
        local n, _, t = UnitChannelInfo(unit)
        if exists(n) then name, texture, isChannel = n, t, true end
    end
    if not exists(name) then
        CB.Stop(f)
        return
    end

    cb.preview = nil
    local dur
    if isChannel then
        dur = UnitChannelDuration and UnitChannelDuration(unit)
    else
        dur = UnitCastingDuration and UnitCastingDuration(unit)
    end
    cb.duration = dur
    if exists(dur) then
        cb:SetTimerDuration(dur, IMMEDIATE, isChannel and REMAINING or ELAPSED)
    else
        cb:SetMinMaxValues(0, 1)
        cb:SetValue(1)
    end

    local c = isChannel and ns.colors.channel or ns.colors.cast
    cb:SetStatusBarColor(c[1], c[2], c[3])
    cb.bg:SetVertexColor(c[1], c[2], c[3], 0.2)
    cb.name:SetText(name)
    cb.icon:SetTexture(texture)
    cb.time:SetText("")
    cb:Show()
    track(cb, true)
end

-- The unit changed: show a cast that is already running, or nothing.
function CB.Refresh(f)
    if not f.castBar then return end
    if enabled(f) and UnitExists(f.unit) then
        CB.Start(f, nil)
    else
        CB.Stop(f)
    end
end

-- Config mode: a static bar so there is something to place.
function CB.Preview(f, on)
    local cb = f.castBar
    if not cb then return end
    if on and enabled(f) then
        cb.preview = true
        cb:SetMinMaxValues(0, 1)
        cb:SetValue(0.6)
        local c = ns.colors.cast
        cb:SetStatusBarColor(c[1], c[2], c[3])
        cb.name:SetText("Cast bar")
        cb.time:SetText("1.5")
        cb.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        cb:Show()
    else
        cb.preview = nil
        if not casting[cb] then cb:Hide() end
    end
end

-- ------------------------------------------------------------ build --

local function onCastEvent(ev, event)
    local f = ev.frame
    local what = CAST_EVENTS[event]
    if what == "start" then
        CB.Start(f, false)
    elseif what == "channel" then
        CB.Start(f, true)
    elseif what == "failed" then
        -- A failed second cast must not hide a running one; the player's
        -- own cast info is never secret, so ask again. Others: hide.
        if f.unit == "player" then CB.Refresh(f) else CB.Stop(f) end
    else
        CB.Stop(f)
    end
end

function CB.Create(f)
    if not CB.supported[f.key] then return end
    local cb = CreateFrame("StatusBar", nil, f)
    cb:Hide()
    cb.bg = cb:CreateTexture(nil, "BACKGROUND")
    cb.bg:SetAllPoints()
    cb.back = cb:CreateTexture(nil, "BACKGROUND", nil, -1)
    cb.icon = cb:CreateTexture(nil, "ARTWORK")
    cb.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cb.name = cb:CreateFontString(nil, "OVERLAY")
    cb.time = cb:CreateFontString(nil, "OVERLAY")
    for _, fs in ipairs({ cb.name, cb.time }) do
        fs:SetFont(ns.media.font, 9, "")
        fs:SetShadowOffset(1, -1)
        fs:SetWordWrap(false)
    end
    cb.name:SetJustifyH("LEFT")
    cb.time:SetJustifyH("RIGHT")
    cb.name:SetPoint("LEFT", cb, "LEFT", 2, 0)
    cb.time:SetPoint("RIGHT", cb, "RIGHT", -2, 0)
    cb.name:SetPoint("RIGHT", cb.time, "LEFT", -4, 0)
    f.castBar = cb

    local ev = CreateFrame("Frame")
    ev.frame = f
    for event in pairs(CAST_EVENTS) do
        pcall(ev.RegisterUnitEvent, ev, event, f.unit)
    end
    ev:SetScript("OnEvent", onCastEvent)
    cb.events = ev
end

-- Size and place from the settings (protected context: called from Layout).
function CB.Layout(f)
    local cb = f.castBar
    if not cb then return end
    local db = f.db.castBar
    if not enabled(f) then
        CB.Stop(f)
        cb.preview = nil
        cb:Hide()
        return
    end
    local texture = ns.Texture()
    cb:SetStatusBarTexture(texture)
    cb.bg:SetTexture(texture)
    local h = db.height
    local iconW = db.icon and h or 0

    cb:ClearAllPoints()
    if db.position == "ABOVE" then
        cb:SetPoint("BOTTOMLEFT", f, "TOPLEFT", iconW + (db.icon and 1 or 0), 1)
        cb:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 1)
    else
        cb:SetPoint("TOPLEFT", f, "BOTTOMLEFT", iconW + (db.icon and 1 or 0), -1)
        cb:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -1)
    end
    cb:SetHeight(h)

    cb.back:ClearAllPoints()
    cb.back:SetPoint("TOPLEFT", cb, "TOPLEFT", -1 - iconW - (db.icon and 1 or 0), 1)
    cb.back:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 1, -1)
    cb.back:SetColorTexture(0, 0, 0, ns.db.backgroundAlpha or 0.8)

    cb.icon:ClearAllPoints()
    cb.icon:SetShown(db.icon)
    cb.icon:SetSize(h, h)
    cb.icon:SetPoint("RIGHT", cb, "LEFT", -1, 0)

    local size = math.max(6, math.min(14, h - 1))
    cb.name:SetFont(ns.media.font, size, "")
    cb.time:SetFont(ns.media.font, size, "")
end

-- FUF smoke test: loads the addon in a mocked client and fires the login
-- sequence. Secret values are userdata that throw on arithmetic and
-- comparison, like the real client. Run: lua5.1 tools/smoketest.lua
local secretMeta = {}
local function secret(v)
    local p = newproxy(true)
    local m = getmetatable(p)
    m.__secret = v
    local function boom() error("attempt to use a secret value", 2) end
    m.__add, m.__sub, m.__mul, m.__div, m.__lt, m.__le, m.__concat, m.__unm = boom, boom, boom, boom, boom, boom, boom, boom
    m.__index = function() error("attempt to index a secret value", 2) end
    m.__tostring = function() return "<secret>" end
    secretMeta[p] = v
    return p
end
function issecretvalue(v) return secretMeta[v] ~= nil end
function canaccessvalue(v) return not issecretvalue(v) end
local function reveal(v) if secretMeta[v] ~= nil then return secretMeta[v] end return v end

-- widgets ---------------------------------------------------------------
local frames = {}
local Widget = {}
Widget.__index = function(t, k)
    local v = rawget(Widget, k)
    if v then return v end
    -- unknown methods (Capitalized) are no-ops, unknown fields are nil
    if k:match("^%u%l") and not k:match("^PlayerFrame") then return function() end end
end
local function newWidget(kind, name)
    local w = setmetatable({ kind = kind, shown = true, scripts = {}, events = {}, points = {}, w = 100, h = 20, children = {} }, Widget)
    table.insert(frames, w)
    if name then _G[name] = w end
    return w
end
function Widget:CreateTexture() return newWidget("Texture") end
function Widget:CreateFontString() return newWidget("FontString") end
function Widget:SetScript(k, fn) self.scripts[k] = fn end
function Widget:HookScript(k, fn) self.scripts[k] = fn end
function Widget:RegisterEvent(e) self.events[e] = true end
function Widget:RegisterUnitEvent(e, unit) self.events[e] = unit or true end
function Widget:UnregisterEvent(e) self.events[e] = nil end
function Widget:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function Widget:Hide() self.shown = false end
function Widget:SetShown(s) self.shown = s end
function Widget:IsShown() return self.shown end
function Widget:IsVisible() return self.shown end
function Widget:SetSize(w, h) self.w, self.h = w, h end
function Widget:SetWidth(w) self.w = w end
function Widget:SetHeight(h) self.h = h end
function Widget:GetWidth() return self.w end
function Widget:GetHeight() return self.h end
function Widget:GetLeft() return 10 end
function Widget:GetTop() return 700 end
function Widget:GetEffectiveScale() return 1 end
function Widget:GetChildren() return end
function Widget:SetFormattedText(fmt, ...)
    local args = { ... }
    for i = 1, select("#", ...) do args[i] = reveal(args[i]) end
    self.text = string.format(fmt, unpack(args, 1, select("#", ...)))
end
function Widget:SetText(t) self.text = reveal(t) end
function Widget:SetValue(v) self.value = reveal(v) end
function Widget:SetMinMaxValues(a, b) self.min, self.max = reveal(a), reveal(b) end
function CreateFrame(kind, name) return newWidget(kind, name) end
UIParent = newWidget("Frame", "UIParent")
PlayerFrame = newWidget("Frame", "PlayerFrame")
PlayerFrame.PlayerFrameContainer = newWidget("Frame")
TargetFrame = newWidget("Frame", "TargetFrame")
TargetFrame.totFrame = newWidget("Frame")

-- API --------------------------------------------------------------------
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
CurveConstants = { ScaleTo100 = { curve = true } }
C_SwingTimer = {}
C_AddOns = { GetAddOnMetadata = function() return "0.1.0" end }
C_Timer = { After = function(_, fn) fn() end }
C_CurveUtil = { CreateColorCurve = function()
    return { AddPoint = function() end }
end }
function CreateColor(r, g, b) return { r = r, g = g, b = b } end
function GetBuildInfo() return "1.60.1", "69977", "", 16001 end
function InCombatLockdown() return false end
function hooksecurefunc() end
function RegisterUnitWatch(f) f.watched = true; f.shown = UnitExists(f.unit) end
function UnregisterUnitWatch(f) f.watched = false end
function GetRealmName() return "Forever" end
local units = { player = true, target = true, targettarget = true }
function UnitExists(u) return units[u] or false end
function UnitName(u) if u == "player" then return "Thrall", nil end return secret("Name-" .. u), nil end
function UnitGUID(u) return u == "player" and "Player-1-0001" or secret("guid") end
function UnitHealth() return secret(1234) end
function UnitHealthMax(u) return u == "player" and 1500 or secret(1500) end
function UnitHealthMissing() return secret(266) end
function UnitHealthPercent(u, pred, curve)
    if curve and curve.curve then return secret(82.3) end
    if curve then return setmetatable({}, { __index = { GetRGB = function() return 1, 1, 0 end } }) end
    return secret(0.823)
end
function UnitPower() return secret(50) end
function UnitPowerMax() return 100 end
function UnitPowerMissing() return secret(50) end
function UnitPowerPercent() return secret(50) end
function UnitPowerType() return 0, "MANA" end
function UnitClass(u) if u == "target" then return secret("Mage"), secret("MAGE") end return "Warrior", "WARRIOR" end
function UnitReaction() return 4 end
function UnitIsPlayer(u) return u ~= "targettarget" end
function UnitIsConnected() return true end
function UnitIsGhost() return false end
function UnitIsDead(u) return u == "targettarget" end
function UnitIsTapDenied() return false end
function UnitLevel(u) return u == "target" and -1 or 60 end
function UnitClassification(u) return u == "target" and "worldboss" or "elite" end
function UnitCreatureType() return "Humanoid" end
function AbbreviateNumbers(v) return secretMeta[v] and secret(tostring(secretMeta[v])) or tostring(v) end
function GetCreatureDifficultyColor() return { r = 1, g = 0.8, b = 0 } end
function SetPortraitTexture() end
SlashCmdList = {}
newproxy = newproxy

-- load in TOC order -------------------------------------------------------
local ns = {}
for line in io.lines("FUF.toc") do
    if line:match("%.lua$") then
        local chunk = assert(loadfile((line:gsub("\\", "/"))))
        chunk("FUF", ns)
    end
end

-- fire events on every frame that listens --------------------------------
local function fire(event, ...)
    for _, w in ipairs(frames) do
        local filter = w.events[event]
        if filter and (filter == true or filter == ...) and w.scripts.OnEvent then
            w.scripts.OnEvent(w, event, ...)
        end
    end
end
fire("PLAYER_LOGIN")
fire("PLAYER_ENTERING_WORLD")
fire("UNIT_HEALTH", "player")
fire("PLAYER_TARGET_CHANGED")
for _, u in ipairs(ns.unitOrder) do
    local f = ns.UF.frames[u]
    assert(f, "frame missing: " .. u)
    local function t(bar, side) return bar.text[side].text or "" end
    print(string.format("%-20s health=%s power=%s | %s | %s || %s | %s", u,
        tostring(f.healthBar.value), tostring(f.powerBar.value),
        t(f.healthBar, "left"), t(f.healthBar, "right"), t(f.powerBar, "left"), t(f.powerBar, "right")))
end
SlashCmdList.FUF("unlock")
SlashCmdList.FUF("lock")
SlashCmdList.FUF("tags")
SlashCmdList.FUF("profile Raid")
SlashCmdList.FUF("profile")
print("OK")

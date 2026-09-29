-- FUF smoke test: loads the addon in a mocked client, fires the login
-- sequence, casts, and clicks through every page of the options window.
-- Secret values are userdata that throw on arithmetic and comparison, like
-- the real client. Run from the repository root: lua5.1 tools/smoketest.lua
local secretMeta = {}
local function secret(v)
    local p = newproxy(true)
    local m = getmetatable(p)
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
    local w = setmetatable({ kind = kind, shown = true, scripts = {}, events = {}, w = 100, h = 20 }, Widget)
    table.insert(frames, w)
    if name then _G[name] = w end
    return w
end
function Widget:CreateTexture() return newWidget("Texture") end
function Widget:CreateFontString() return newWidget("FontString") end
function Widget:SetScript(k, fn) self.scripts[k] = fn end
function Widget:GetScript(k) return self.scripts[k] end
function Widget:GetStatusBarTexture() self.fill = self.fill or newWidget("Texture"); return self.fill end
function Widget:HookScript(k, fn) self.scripts[k] = fn end
function Widget:RegisterEvent(e) self.events[e] = true end
function Widget:RegisterUnitEvent(e, unit) self.events[e] = unit or true end
function Widget:UnregisterEvent(e) self.events[e] = nil end
function Widget:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function Widget:Hide() self.shown = false end
function Widget:SetShown(s) self.shown = s and true or false end
function Widget:IsShown() return self.shown end
function Widget:IsVisible() return self.shown end
function Widget:SetSize(w, h) self.w, self.h = w, h end
function Widget:SetWidth(w) self.w = w end
function Widget:SetHeight(h) self.h = h end
function Widget:GetWidth() return self.w end
function Widget:GetHeight() return self.h end
function Widget:GetLeft() return 10 end
function Widget:GetRight() return 110 end
function Widget:GetTop() return 700 end
function Widget:GetCenter() return 60, 690 end
function Widget:GetEffectiveScale() return 1 end
function Widget:GetFrameLevel() return 1 end
function Widget:GetChildren() return end
function Widget:SetFormattedText(fmt, ...)
    local args = { ... }
    for i = 1, select("#", ...) do args[i] = reveal(args[i]) end
    self.text = string.format(fmt, unpack(args, 1, select("#", ...)))
end
function Widget:SetText(t) self.text = reveal(t) end
function Widget:GetText() return self.text end
function Widget:SetValue(v)
    self.value = reveal(v)
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, self.value, true) end
end
function Widget:GetValue() return self.value end
function Widget:SetMinMaxValues(a, b) self.min, self.max = reveal(a), reveal(b) end
function Widget:SetChecked(c) self.checked = c end
function Widget:GetChecked() return self.checked end
function Widget:SetTimerDuration(d) self.duration = d end
function Widget:SetTexture(t) self.texture = t; return true end
function Widget:SetStatusBarColor(r, g, b) self.color = { r, g, b } end
function Widget:SetupMenu(gen) self.menuGen = gen; self:GenerateMenu() end
function Widget:GenerateMenu()
    local radios = {}
    local root = { CreateRadio = function(_, text, isSel, setSel, data)
        table.insert(radios, { text = text, isSel = isSel, set = setSel })
    end }
    self.menuGen(self, root)
    self.radios = radios
    for _, r in ipairs(radios) do r.isSel() end
end
function Widget:AddAuraGroup(key, filterString, opts)
    assert(type(filterString) == "string" and filterString ~= "", "filter string")
    self.groups = self.groups or {}
    assert(not self.unitSet, "group added after SetUnit")
    self.groups[key] = { filter = filterString, max = opts.maxFrameCount }
    opts.initializeFrame(newWidget("AuraButton"))   -- the engine builds buttons at once
end
function Widget:SetUnit(u) self.unitSet = u end
function CreateFrame(kind, name) return newWidget(kind, name) end
UIParent = newWidget("Frame", "UIParent")
Minimap = newWidget("Frame", "Minimap")
GameTooltip = newWidget("GameTooltip", "GameTooltip")
PlayerFrame = newWidget("Frame", "PlayerFrame")
PlayerFrame.PlayerFrameContainer = newWidget("Frame")
TargetFrame = newWidget("Frame", "TargetFrame")
TargetFrame.totFrame = newWidget("Frame")
newWidget("Frame", "PetFrame")
newWidget("Frame", "PartyFrame")
newWidget("Frame", "PlayerCastingBarFrame")
UISpecialFrames = {}
AuraUtil = {
    AuraFilters = { Helpful = "HELPFUL", Harmful = "HARMFUL", Player = "PLAYER", Raid = "RAID" },
    CreateFilterString = function(...) return table.concat({ ... }, "|") end,
}
AnchorUtil = { FlowDirection = { Left = -1, Right = 1, Up = 1, Down = -1 } }
AuraContainerSortMethod = { Default = 0 }
AuraContainerSortDirection = { Normal = 0 }

-- API --------------------------------------------------------------------
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
Enum = {
    StatusBarTimerDirection = { ElapsedTime = 0, RemainingTime = 1 },
    StatusBarInterpolation = { Immediate = 0 },
    CustomAuraButtonDispelTypeTextureStyle = { PreserveAsset = 3 },
}
CurveConstants = { ScaleTo100 = { curve = true } }
C_SwingTimer = {}
C_AddOns = { GetAddOnMetadata = function() return "0.2.0" end }
C_Timer = { After = function(_, fn) fn() end }
C_CurveUtil = { CreateColorCurve = function()
    return { AddPoint = function() end }
end }
Settings = {
    RegisterCanvasLayoutCategory = function() return {} end,
    RegisterAddOnCategory = function() end,
}
C_PetInfo = {
    GetPetHappiness = function() return 2, 100, 0 end,
    GetPetLoyalty = function() return "Loyal" end,
}
function CreateColor(r, g, b) return { r = r, g = g, b = b } end
function GetBuildInfo() return "1.60.1", "69977", "", 16001 end
function GetCursorPosition() return 100, 100 end
function InCombatLockdown() return false end
function hooksecurefunc() end
function RegisterUnitWatch(f) f.watched = true; f.shown = UnitExists(f.unit) end
function UnregisterUnitWatch(f) f.watched = false end
local inRaid = false
function RegisterStateDriver(f, state, rule)
    assert(state == "visibility" and rule:find("%[group:raid%] hide"), "state driver rule")
    f.driver = rule
    f.shown = not inRaid and UnitExists(f.unit)
end
function UnregisterStateDriver(f) f.driver = nil end
function GetRaidRosterInfo(i) return "Member" .. i, 0, ({ 1, 3, 3, 2, 1 })[i] or 8 end
function UnitInRange(u) return secret(u ~= "party1"), secret(true) end
function UnitIsUnit(a, b) return a == b end
function GetPetExperience() return 150, 600 end
function GetXPExhaustion() return 400 end
function Widget:SetAlpha(a) self.alpha = a end
function Widget:SetAlphaFromBoolean(b, t, f) self.alpha = reveal(b) and t or f end
function GetRealmName() return "Forever" end
local units = { player = true, target = true, targettarget = true, pet = true, party1 = true }
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
function UnitIsPlayer(u) return u ~= "targettarget" and u ~= "pet" end
function UnitIsConnected() return true end
function UnitIsGhost() return false end
function UnitIsDead(u) return u == "targettarget" end
function UnitIsAFK(u) return u == "party1" end
function UnitAffectingCombat() return secret(true) end
function GetGuildInfo(u) return u == "player" and "Forever Guild" or nil end
function UnitXP() return 300 end
function UnitXPMax() return 1200 end
function UnitIsTapDenied() return false end
function UnitLevel(u) return u == "target" and -1 or 60 end
function UnitClassification(u) return u == "target" and "worldboss" or "elite" end
function UnitCreatureType() return "Humanoid" end
local targetCasting = false
function UnitCastingInfo(u)
    if u == "target" and targetCasting then return secret("Fireball"), secret(""), secret(135812) end
    if u == "player" and targetCasting then return "Aimed Shot", "", 135130 end
end
function UnitChannelInfo() end
local duration = { GetRemainingDuration = function() return secret(1.25) end }
function UnitCastingDuration() return duration end
Enum = Enum or {}
function CreateUnitHealPredictionCalculator()
    local c = {}
    function c:SetIncomingHealOverflowPercent(v) self.overflow = v end
    function c:SetIncomingHealClampMode() end
    function c:GetIncomingHeals() return secret(500), secret(200), secret(300), secret(false) end
    function c:GetDamageAbsorbs() return secret(50), secret(false) end
    return c
end
function UnitGetDetailedHealPrediction(unit, healer, calc) assert(calc.GetIncomingHeals) end
function UnitChannelDuration() return duration end
function BreakUpLargeNumbers(v) local n = reveal(v); local s = tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""); return secretMeta[v] and secret(s) or s end
C_StringUtil = { CreateNumericRuleFormatter = function() return { SetBreakpoints = function() end } end }
function AbbreviateNumbers(v) return secretMeta[v] and secret(tostring(secretMeta[v])) or tostring(v) end
function GetCreatureDifficultyColor() return { r = 1, g = 0.8, b = 0 } end
function SetPortraitTexture() end
SlashCmdList = {}

-- load in TOC order -------------------------------------------------------
local ns = {}
for line in io.lines("FUF/FUF.toc") do
    if line:match("%.lua$") then
        local chunk = assert(loadfile("FUF/" .. line:gsub("\\", "/")))
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
local function tick()
    for _, w in ipairs(frames) do
        if w.scripts.OnUpdate then w.scripts.OnUpdate(w, 1) end
    end
end

fire("PLAYER_LOGIN")
fire("PLAYER_ENTERING_WORLD")
fire("UNIT_HEALTH", "player")
fire("PLAYER_TARGET_CHANGED")
tick()

local function dump()
    local list = {}
    for unit in pairs(ns.UF.frames) do table.insert(list, unit) end
    table.sort(list)
    for _, u in ipairs(list) do
        local f = ns.UF.frames[u]
        if f.shown then
            local function t(bar, side) return bar.text[side].text or "" end
            print(string.format("%-20s | %s | %s || %s | %s", u,
                t(f.healthBar, "left"), t(f.healthBar, "right"), t(f.powerBar, "left"), t(f.powerBar, "right")))
        end
    end
end
dump()
assert(ns.UF.frames.party1.shown and not ns.UF.frames.party2.shown, "party visibility")
assert(ns.UF.frames.pet.shown, "pet shown")
local pet = ns.UF.frames.pet
assert(pet.healthBar.color[1] == 0.93 and pet.healthBar.color[3] == 0, "pet coloured by happiness (content = yellow)")
assert(not pet.happiness.shown, "happiness icon off by default")
fire("UNIT_HAPPINESS", "pet")
local pfs = newWidget("FontString")
ns.Tags.Render(pfs, "[happiness] [loyalty]", "pet")
print("pet tags: " .. pfs.text)
assert(pfs.text:find("Content") and pfs.text:find("Loyal"), "pet tags")

-- heal prediction: own/others split from the calculator, secrets passed through
local ph = ns.UF.frames.player.heal
fire("UNIT_HEAL_PREDICTION", "player")
assert(ph.own.value == 200 and ph.others.value == 300 and ph.absorb.value == 50, "heal prediction values")
print("heal prediction: own=" .. ph.own.value .. " others=" .. ph.others.value .. " absorb=" .. ph.absorb.value)

-- auras: pet has a container with both groups, bound to its unit
local pc = pet.auraContainer
assert(pc and pc.unitSet == "pet" and pc.groups.buffs.filter == "HELPFUL" and pc.groups.debuffs.max == 16, "pet auras")
assert(not ns.UF.frames.player.auraContainer, "player auras off by default")
print("pet auras: buffs=" .. pc.groups.buffs.filter .. " debuffs=" .. pc.groups.debuffs.filter)

-- raid: 40 frames, sorted into subgroup columns
assert(ns.UF.frames.raid40, "raid frames")
local r2, r3, r4 = ns.UF.frames.raid2, ns.UF.frames.raid3, ns.UF.frames.raid4
assert(r2.raidGroup == 3 and r2.raidSlot == 1 and r3.raidSlot == 2 and r4.raidGroup == 2, "raid arranged by subgroup")
-- party hides in raid through a state driver
assert(ns.UF.frames.party1.driver, "party uses the hide-in-raid driver")
-- range: party1 is out of range (secret false) -> faded to 0.4
tick()
assert(ns.UF.frames.party1.alpha == 0.4, "party1 faded, got " .. tostring(ns.UF.frames.party1.alpha))
assert(ns.UF.frames.pet.alpha ~= 0.4, "own pet never fades")
-- pet XP bar
assert(pet.xpBar.value == 150 and pet.xpBar.shown, "pet xp bar")
print("raid/range/xp ok")

-- tags with arguments
local fs = newWidget("FontString")
ns.Tags.Render(fs, "[shortname:3] [color:ff0000]x[nocolor] [smartlevel] [guild] [xp] [percxp] [afk][combat]", "player")
print("tags: " .. fs.text)
assert(fs.text:find("^Thr "), "shortname")
ns.Tags.Render(fs, "[smarthealth] [ssmarthealth] [shp]", "player")
print("number tags: " .. fs.text)

-- casts (target: all secret)
targetCasting = true
fire("UNIT_SPELLCAST_START", "target")
fire("UNIT_SPELLCAST_START", "player")
tick()
local tcb = ns.UF.frames.target.castBar
print("target cast: " .. tostring(tcb.name.text) .. " " .. tostring(tcb.time.text) .. " shown=" .. tostring(tcb.shown))
assert(tcb.shown and tcb.name.text == "Fireball" and tcb.time.text == "1.2", "target cast bar")
targetCasting = false
fire("UNIT_SPELLCAST_STOP", "target")
fire("UNIT_SPELLCAST_FAILED", "player")
assert(not tcb.shown and not ns.UF.frames.player.castBar.shown, "cast bars hidden")

-- config mode and dragging
SlashCmdList.FUF("unlock")
assert(ns.UF.frames.party3.shown and ns.UF.frames.party3.unit == "player", "party stand-in")
ns.UF.frames.party3.scripts.OnDragStop(ns.UF.frames.party3)
ns.UF.frames.partypet2.scripts.OnDragStop(ns.UF.frames.partypet2)
SlashCmdList.FUF("lock")
assert(ns.UF.frames.party3.unit == "party3" and not ns.UF.frames.party3.shown, "party back")

-- options window: open every page and use every control
SlashCmdList.FUF("")
local nav = {}
for _, w in ipairs(frames) do
    if w.kind == "Button" and w.sel then table.insert(nav, w) end
end
assert(#nav >= 11, "navigation buttons: " .. #nav)
local used = 0
local function use(w)
    if w.check then
        w.check:SetChecked(not w.check:GetChecked())
        w.check.scripts.OnClick(w.check)
        w.check:SetChecked(not w.check:GetChecked())
        w.check.scripts.OnClick(w.check)
    elseif w.slider then
        w.slider:SetValue(((w.slider.min or 0) + (w.slider.max or 1)) / 2)
    elseif w.dropdown then
        w.dropdown:GenerateMenu()
        local r = w.dropdown.radios[1]
        if r then r.set() end
    elseif w.edit then
        local old = w.edit:GetText() or ""
        w.edit:SetText(tonumber(old) and "25" or (old .. " [perhp]"))
        w.edit.scripts.OnEnterPressed(w.edit)
    else
        return
    end
    used = used + 1
end
for _, btn in ipairs(nav) do
    btn.scripts.OnClick(btn)
end
for _, w in ipairs(frames) do
    if w.check or w.slider or w.dropdown or w.edit then use(w) end
end
print("options: " .. #nav .. " pages, " .. used .. " controls used")
dump()

-- minimap button
FUFMinimapButton.scripts.OnClick(FUFMinimapButton, "RightButton")
FUFMinimapButton.scripts.OnClick(FUFMinimapButton, "LeftButton")
FUFMinimapButton.scripts.OnDragStart(FUFMinimapButton)
tick()
FUFMinimapButton.scripts.OnDragStop(FUFMinimapButton)
FUF_OnAddonCompartmentClick()

SlashCmdList.FUF("profile Raid")
SlashCmdList.FUF("profile")
SlashCmdList.FUF("reset")
SlashCmdList.FUF("pet")
assert(ns.Texture():find("FUF\\Media\\Smooth"), "default texture")
print("OK")

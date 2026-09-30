-- Lizzarick's Unit Frames smoke test: loads the addon in a mocked client, fires the login
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
function Widget:HookScript(k, fn)
    local old = self.scripts[k]
    self.scripts[k] = old and function(...) old(...); fn(...) end or fn
end
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
function Widget:IsMouseOver() return false end
function Widget:GetChildren() return end
function Widget:SetFormattedText(fmt, ...)
    local args = { ... }
    for i = 1, select("#", ...) do args[i] = reveal(args[i]) end
    self.text = string.format(fmt, unpack(args, 1, select("#", ...)))
end
function Widget:SetText(t) self.text = reveal(t) end
function Widget:GetText() return self.text end
function Widget:GetStringWidth() return #(self.text or "") * 6 end
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
    self.groups[key] = { filter = filterString, max = opts.maxFrameCount, cf = opts.candidateFilters }
    opts.initializeFrame(newWidget("AuraButton"))   -- the engine builds buttons at once
end
function Widget:SetUnit(u) self.unitSet = u end
function Widget:AddAuraSlot(key, filterString, opts)
    assert(type(filterString) == "string" and filterString ~= "", "slot filter")
    assert(not self.unitSet, "slot added after SetUnit")
    self.slots = self.slots or {}
    local b = newWidget("AuraButton")
    opts.initializeFrame(b)
    self.slots[key] = { filter = filterString, ids = opts.candidateFilters and opts.candidateFilters.includeSpellIDs, button = b }
    return b
end
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
    LootMethod = { Masterlooter = 2 },
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
local SPELLS = { [706] = { "Demon Armor", "Rank 1" }, [11735] = { "Demon Armor", "" }, [1454] = { "Life Tap", "Rank 1" } }
C_Spell = {
    GetSpellInfo = function(n) if n == "Demon Armor" then return { spellID = 11735 } end end,
    GetSpellName = function(id) return SPELLS[id] and SPELLS[id][1] end,
    GetSpellSubtext = function(id) return SPELLS[id] and SPELLS[id][2] or "" end,
    GetSpellTexture = function(id) return SPELLS[id] and 136185 end,
    RequestLoadSpellData = function(id) SPELLS[id][2] = SPELLS[id][2] == "" and "Rank 5" or SPELLS[id][2] end,
}
function GetRaidTargetIndex(u) if u == "target" then return secret(8) end end
function Widget:SetSpriteSheetCell(i) self.cell = reveal(i) end
function UnitIsGroupLeader(u) return secret(u == "party1") end
function UnitIsPVP(u) return u == "player" end
function UnitIsPVPFreeForAll() return false end
function UnitFactionGroup() return "Horde" end
function UnitHasIncomingResurrection(u) return secret(false) end
function UnitGroupRolesAssigned(u) return u == "party1" and "HEALER" or "NONE" end
C_PartyInfo = { GetLootMethod = function() return 2, 0, nil end }
function UnitThreatSituation(u) return u == "party1" and 3 or 0 end
function GetThreatStatusColor(s) return 1, 0, 0 end
function UnitCanAttack() return true end
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
function GetRaidRosterInfo(i) return "Member" .. i, 0, ({ 1, 3, 3, 2, 1 })[i] or 1 end
local raidMode = false
function IsInRaid() return raidMode end
function IsResting() return true end
function Widget:SetAtlas(a) self.atlas = a end
function Widget:CreateAnimationGroup()
    local g = newWidget("AnimationGroup")
    function g:CreateAnimation() return newWidget("Animation") end
    function g:Play() self.playing = true end
    function g:Stop() self.playing = false end
    function g:IsPlaying() return self.playing end
    return g
end
function ReloadUI() reloaded = true end
function UnitInRange(u) return secret(u ~= "party1"), secret(true) end
function UnitIsUnit(a, b) return a == b end
function GetPetExperience() return 150, 600 end
function GetXPExhaustion() return 400 end
function Widget:SetAlpha(a) self.alpha = a end
function Widget:SetPoint(point, rel, relPoint, x, y) self.point = { point, rel, relPoint, x, y } end
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
function UnitAffectingCombat(u) if u == "player" then return false end return secret(true) end
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
for line in io.lines("LizzaricksUnitFrames/LizzaricksUnitFrames.toc") do
    if line:match("%.lua$") then
        local chunk = assert(loadfile("LizzaricksUnitFrames/" .. line:gsub("\\", "/")))
        chunk("LizzaricksUnitFrames", ns)
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
assert(ns.db.units.pet.auras.debuffSize > ns.db.units.pet.auras.size, "debuffs larger than buffs")
assert(not ns.UF.frames.player.auraContainer, "player auras off by default")
print("pet auras: buffs=" .. pc.groups.buffs.filter .. " debuffs=" .. pc.groups.debuffs.filter)

-- raid: outside a raid the roster is ignored -> fixed 8x5 grid
assert(ns.UF.frames.raid40.raidGroup == 8 and ns.UF.frames.raid40.raidSlot == 5, "raid grid outside a raid")
assert(ns.UF.frames.raid7.raidGroup == 2 and ns.UF.frames.raid7.raidSlot == 2, "raid grid")
-- in a raid: sorted into subgroup columns
raidMode = true
for i = 1, 5 do units["raid" .. i] = true end
ns.UF.ArrangeRaid()
local r2, r3, r4 = ns.UF.frames.raid2, ns.UF.frames.raid3, ns.UF.frames.raid4
assert(r2.raidGroup == 3 and r2.raidSlot == 1 and r3.raidSlot == 2 and r4.raidGroup == 2, "raid arranged by subgroup")
-- raid grid: 4 groups per row, columns; group 2 = raid6-10
local rdb = ns.db.units.raid
rdb.groupsPerRow = 4
ns.UF.ArrangeRaid()
local p9 = ns.UF.frames.raid9.point
assert(p9[4] == 10 + 1 * (60 + 4) and p9[5] == -420 - 3 * (30 + 2), "raid grid position " .. p9[4] .. "," .. p9[5])
local p26 = ns.UF.frames.raid26.point   -- group 6 -> second row
assert(p26[4] == 10 + 1 * (60 + 4) and p26[5] == -420 - (5 * 30 + 4 * 2 + 4), "raid second row")
rdb.groupDirection = "RIGHT"
ns.UF.ArrangeRaid()
assert(ns.UF.frames.raid9.point[4] == 10 + 1 * (5 * 60 + 4 * 2 + 4) + 3 * (60 + 2), "raid rows")
rdb.groupDirection, rdb.groupsPerRow = "DOWN", 8
-- separate groups: group positions are stored per group
rdb.separateGroups = true
ns.UF.ArrangeRaid()
assert(rdb.groupPos[3], "group position saved")
rdb.separateGroups, rdb.groupPos = false, {}
ns.UF.ArrangeRaid()
-- dragging a party frame hangs the others on it
SlashCmdList.LIZUF("unlock")
local p1, p3 = ns.UF.frames.party1, ns.UF.frames.party3
p1.scripts.OnDragStart(p1)
assert(p3.point[2] == p1, "party members follow while dragging")
p1.scripts.OnDragStop(p1)
assert(p3.point[2] == UIParent, "party back on UIParent after drop")
local r6 = ns.UF.frames.raid6
assert(r6.moverLabel.text == "Grp 2" and ns.UF.frames.raid7.moverLabel.text == "", "group labels")
r6.scripts.OnDragStart(r6)
assert(ns.UF.frames.raid40.point[2] == r6, "raid follows while dragging")
r6.scripts.OnDragStop(r6)
SlashCmdList.LIZUF("lock")

-- party hides in raid through a state driver
assert(ns.UF.frames.party1.driver, "party uses the hide-in-raid driver")
-- range: party1 is out of range (secret false) -> faded to 0.4
tick()
assert(ns.UF.frames.party1.alpha == 0.4, "party1 faded, got " .. tostring(ns.UF.frames.party1.alpha))
assert(ns.UF.frames.pet.alpha ~= 0.4, "own pet never fades")
-- pet XP bar
assert(pet.xpBar.value == 150 and pet.xpBar.shown, "pet xp bar")
print("raid/range/xp ok")

-- squares: aggro on party1, a spell-list buff slot on the player
local pdb = ns.db.units.player.squares
pdb.topleft.enabled, pdb.topleft.type, pdb.topleft.spells = true, "buff", "Demon Armor; 12345"
pdb.bottom.enabled, pdb.bottom.type = true, "missing"
pdb.bottom.spells = "Demon Armor"
ns.db.units.party.squares.center.enabled = true
ns:ApplyKey("player"); ns:ApplyKey("party")
local sc = ns.UF.frames.player.squareContainer
assert(sc and sc.slots.topleft.ids[11735] and sc.slots.topleft.ids[12345] and sc.unitSet == "player", "square slot by spell ID")
assert(sc.slots.bottom and ns.UF.frames.player.squares.bottom.tex.shown, "missing buff shows red under the slot")
ns.Squares.Update(ns.UF.frames.party1)
assert(ns.UF.frames.party1.squares.center.tex.shown, "aggro square on party1")
pdb.top.enabled, pdb.top.type = true, "castable"
pdb.center.enabled, pdb.center.type = true, "mybuffs"
ns:ApplyKey("player")
sc = ns.UF.frames.player.squareContainer
assert(sc.slots.top.filter == "HELPFUL|RAID" and not sc.slots.top.ids, "castable square: any buff I can cast")
assert(sc.slots.center.filter == "HELPFUL|PLAYER" and not sc.slots.center.ids, "my buffs square")
pdb.top.enabled, pdb.center.enabled = false, false
-- several icons in one square: its own aura group, not duplicate slots
pdb.bottomright.enabled, pdb.bottomright.type, pdb.bottomright.count, pdb.bottomright.grow = true, "mybuffs", 3, "LEFT"
ns:ApplyKey("player")
local grp = ns.UF.frames.player.squareGroups.bottomright
assert(grp and grp.groups.square.max == 3 and grp.groups.square.filter == "HELPFUL|PLAYER" and grp.unitSet == "player", "multi-icon square")
assert(not ns.UF.frames.player.squareContainer.slots.bottomright, "no single slot for a multi-icon square")
pdb.bottomright.count = 1
ns:ApplyKey("player")
assert(not ns.UF.frames.player.squareGroups.bottomright and ns.UF.frames.player.squareContainer.slots.bottomright, "back to one slot")
pdb.bottomright.enabled = false
ns:ApplyKey("player")
print("squares ok")

-- filter lists: search by name (ranks after the name) and by ID, add,
-- remove, export/import, and the aura group / square wiring
local FL = ns.Filters
FL.MAX_ID = 30000
assert(FL.Create("Warlock"))
FL.Search("demon armor")
for _ = 1, 5 do tick() end
assert(FL.search.done and #FL.search.results == 2 and FL.search.results[1] == 706, "name search")
local items = FL.SearchItems()
assert(items[1].text:find("Demon Armor") and items[1].text:find("Rank 1") and items[1].text:find("ID: 706"), items[1].text)
FL.Search("1454")
assert(FL.search.done and FL.search.results[1] == 1454, "ID search")
FL.Add("Warlock", 706); FL.Add("Warlock", 1454)
assert(FL.Describe(11735):find("Rank 5"), "rank loaded later")
local exported = FL.Export("Warlock")
assert(exported == "LUF1:Warlock:706,1454", exported)
FL.Remove("Warlock", 1454)
assert(#FL.Items("Warlock") == 1, "remove")
local imported = FL.Import(exported)
assert(imported == "Warlock (2)" and FL.Get(imported)[1454], "import")
assert(not FL.Import("garbage"), "bad import rejected")
local tadb = ns.db.units.target.auras
tadb.buffList, tadb.buffListMode = "Warlock", "include"
tadb.debuffList, tadb.debuffListMode = "Warlock (2)", "exclude"
pdb.topright.enabled, pdb.topright.type, pdb.topright.list = true, "buff", "Warlock"
ns:ApplyKey("target"); ns:ApplyKey("player")
local tc = ns.UF.frames.target.auraContainer
assert(tc.groups.buffs.cf.includeSpellIDs[706] and tc.groups.debuffs.cf.excludeSpellIDs[1454], "aura group filter lists")
assert(ns.UF.frames.player.squareContainer.slots.topright.ids[706], "square takes spells from a list")
FL.Add("Warlock", 172)
assert(ns.UF.frames.target.auraContainer ~= tc, "list change rebuilds the container")
FL.Rename("Warlock", "Lock")
assert(tadb.buffList == "Lock" and pdb.topright.list == "Lock", "rename follows references")
FL.Delete("Lock")
assert(tadb.buffList == "" and pdb.topright.list == "", "delete clears references")
FL.selected = "Warlock (2)"
FL.Search("")
print("filters ok")

-- borders: mouseover and aggro, debuff border as an aura slot
local p1f = ns.UF.frames.party1
ns.db.units.party.borders.aggro = true
ns:ApplyKey("party")
ns.Borders.Update(p1f)
assert(p1f.border.shown and p1f.border.edges[1].shown, "aggro border on party1")
local plf = ns.UF.frames.player
assert(not plf.border.shown, "no border without hover")
plf.scripts.OnEnter(plf)
assert(plf.border.shown, "mouseover border")
plf.scripts.OnLeave(plf)
assert(not plf.border.shown, "mouseover border gone")
assert(plf.borderContainer and plf.borderContainer.slots.border.filter == "HARMFUL|RAID", "debuff border slot")
ns.db.units.player.borders.debuff = "all"; ns:ApplyKey("player")
assert(plf.borderContainer.slots.border.filter == "HARMFUL", "debuff border: all")
ns.db.units.player.borders.debuff = "off"; ns:ApplyKey("player")
assert(not plf.borderContainer, "debuff border off")
print("borders ok")

-- highlight: mouseover, target (secret-safe), debuff tint as an aura slot
local hdb = ns.db.units.player.highlight
hdb.mouseover, hdb.debuff = true, "own"
ns:ApplyKey("player")
plf.scripts.OnEnter(plf)
assert(plf.highlight.shown and plf.highlight.tex.alpha == hdb.alpha, "mouseover highlight")
plf.scripts.OnLeave(plf)
assert(not plf.highlight.shown, "highlight off after leaving")
assert(plf.highlightContainer.slots.highlight.filter == "HARMFUL|RAID", "debuff highlight slot")
local thdb = ns.db.units.target.highlight
thdb.target = true
ns:ApplyKey("target")
local tfr = ns.UF.frames.target
assert(tfr.highlight.shown and tfr.highlight.tex.alpha == thdb.alpha, "target frame highlighted as target")
hdb.mouseover, hdb.debuff, thdb.target = false, "off", false
ns:ApplyKey("player"); ns:ApplyKey("target")
print("highlight ok")

-- combat text: damage, crit, heal, miss; secret amounts go straight to the text
local ctx = plf.combatText
for _, w in ipairs(frames) do
    if w.events.UNIT_COMBAT == "player" then
        w.scripts.OnEvent(w, "UNIT_COMBAT", "player", "WOUND", "", secret(123), 1)
    end
end
assert(ctx.text.shown and ctx.text.text == "-123", "damage text: " .. tostring(ctx.text.text))
ns.CombatText.Show(plf, "HEAL", "CRITICAL", 50)
assert(ctx.text.text == "+50", "heal text")
MISS = "Miss"
ns.CombatText.Show(plf, "MISS", "", 0)
assert(ctx.text.text == "Miss", "miss text")
ns.CombatText.Show(plf, "WOUND", "ABSORB", 0)
assert(ctx.text.text == "Absorb", "absorbed hit shows the reason")
ctx.scripts.OnUpdate(ctx, 5)
assert(not ctx.text.shown, "combat text fades out")
print("combat text ok")

-- party targets: party1target hangs on party1, off by default, polled
local pt = ns.UF.frames.party1target
assert(pt and pt.key == "partytarget" and pt.anchorFrame == ns.UF.frames.party1, "party target frame")
assert(not pt.shown, "party targets off by default")
assert(pt.globalEvents.scripts.OnUpdate, "party target is polled")
ns.db.units.partytarget.enabled = true
units.party1target = true
ns:ApplyKey("partytarget")
assert(pt.driver and pt.shown, "party target shown with its unit, hides in raid")
ns.db.units.partytarget.enabled = false
units.party1target = nil
ns:ApplyKey("partytarget")
print("party target ok")

-- colors page: an override changes the class colour in place, reset restores it
ns.SetColor("class.WARRIOR", 1, 0, 0)
assert(ns.colors.class.WARRIOR[1] == 1 and ns.colors.class.WARRIOR[2] == 0, "class colour override")
assert(plf.healthBar.color[1] == 1 and plf.healthBar.color[2] == 0, "player bar uses the new colour")
ns.SetColor("reaction.4", 0, 0, 1)
assert(ns.colors.reaction[4][3] == 1, "reaction colour override")
ns.ResetColors()
assert(ns.colors.class.WARRIOR[1] == 0.78 and ns.colors.reaction[4][1] == 0.9, "colours reset")
print("colors ok")

-- indicators: raid mark (secret index), leader (secret bool), master looter, pvp, elite
local tgf = ns.UF.frames.target
ns.Indicators.Update(tgf)
assert(tgf.indicators.icons.raidTarget.shown and tgf.indicators.icons.raidTarget.cell == 8, "raid mark")
assert(tgf.indicators.icons.elite.shown and tgf.indicators.icons.elite.atlas:find("Winged"), "elite dragon")
ns.Indicators.Update(p1f)
assert(p1f.indicators.icons.leader.alpha == 1, "party1 leads")
ns.Indicators.Update(plf)
assert(plf.indicators.icons.leader.alpha == 0, "player not leader")
assert(plf.indicators.icons.masterLooter.alpha == 1, "player is master looter")
ns.db.units.player.indicators.pvp.enabled = true; ns:ApplyKey("player")
assert(plf.indicators.icons.pvp.shown and plf.indicators.icons.pvp.atlas:find("Horde"), "pvp icon")
assert(p1f.indicators.icons.role.shown and p1f.indicators.icons.role.atlas == "roleicon-tiny-healer", "healer role icon")
assert(not plf.indicators.icons.role.shown, "no role, no icon")
SlashCmdList.LIZUF("unlock")
assert(p1f.indicators.icons.raidTarget.cell == 8, "config mode shows one mark, not the sheet")
local markOf = GetRaidTargetIndex
GetRaidTargetIndex = function() return secret(5) end
ns.Indicators.Update(p1f)
assert(p1f.indicators.icons.raidTarget.cell == 5, "config mode shows the real mark (moon)")
GetRaidTargetIndex = markOf
SlashCmdList.LIZUF("lock")
local tl = ns.db.units.party.squares.topleft
tl.enabled, tl.type, tl.texture, tl.spells = true, "buff", true, "706"
ns:ApplyKey("party")
SlashCmdList.LIZUF("unlock")
ns.Squares.Update(p1f)
assert(not p1f.squares.topleft.tex.shown, "no placeholder for aura squares in config mode")
local p3f = ns.UF.frames.party3
assert(p3f.unit == "player" and p3f.squareContainer.unitSet == "player", "stand-in frame's squares show the player's auras")
SlashCmdList.LIZUF("lock")
ns.Squares.Update(p1f)
assert(p3f.unit == "party3" and p3f.squareContainer.unitSet == "party3", "squares back on the real unit")
tl.enabled = false
print("indicators ok")

-- status icon: resting -> Zzz, combat -> swords
local st = ns.UF.frames.player.status
fire("PLAYER_UPDATE_RESTING")
assert(st.rest.shown and not st.combat.shown and st.anim.playing, "resting icon")
fire("PLAYER_REGEN_DISABLED")
assert(st.combat.shown and not st.rest.shown, "combat icon")
fire("PLAYER_REGEN_ENABLED")
assert(st.rest.shown and not st.combat.shown, "back to resting")
print("status icon ok")

-- tags with arguments
local fs = newWidget("FontString")
ns.Tags.Render(fs, "[shortname:3] [color:ff0000]x[nocolor] [smartlevel] [guild] [xp] [percxp] [afk][combat]", "player")
print("tags: " .. fs.text)
assert(fs.text:find("^Thr "), "shortname")
ns.Tags.Render(fs, "[smarthealth] [ssmarthealth] [shp]", "player")
print("number tags: " .. fs.text)
ns.Tags.Render(fs, "[name] [resting]", "player")
assert(fs.text == "Thrall (Resting)", "resting tag: " .. fs.text)
ns.Tags.Render(fs, "[resting]", "target")
assert(fs.text == "", "resting only for the player")
ns.Tags.Render(fs, "[statuscolor][name]", "player")
assert(fs.text == "|cff33dd33Thrall", "statuscolor resting: " .. fs.text)

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
SlashCmdList.LIZUF("unlock")
assert(ns.UF.frames.party3.shown and ns.UF.frames.party3.unit == "player", "party stand-in")
ns.UF.frames.party3.scripts.OnDragStop(ns.UF.frames.party3)
ns.UF.frames.partypet2.scripts.OnDragStop(ns.UF.frames.partypet2)
SlashCmdList.LIZUF("lock")
assert(ns.UF.frames.party3.unit == "party3" and not ns.UF.frames.party3.shown, "party back")

-- options window: open every page and use every control
SlashCmdList.LIZUF("")
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
        -- typed value: out of range gets clamped to max
        w.valueBox:SetText("99999")
        w.valueBox.scripts.OnEnterPressed(w.valueBox)
        assert(w.slider.value == w.slider.max, "typed value clamped")
        if (w.slider.max or 0) <= 1 then
            w.valueBox:SetText("0,35")
            w.valueBox.scripts.OnEnterPressed(w.valueBox)
            assert(math.abs(w.slider.value - 0.35) < 0.001, "decimal typed: " .. tostring(w.slider.value))
        end
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
local tabsSeen = 0
for _, btn in ipairs(nav) do
    btn.scripts.OnClick(btn)
    -- click every tab of this page
    local tabs = {}
    for _, w in ipairs(frames) do
        if w.tabId and w.shown then table.insert(tabs, w) end
    end
    for _, t in ipairs(tabs) do
        t.scripts.OnClick(t)
        tabsSeen = tabsSeen + 1
    end
end
assert(tabsSeen >= 60, "tabs clicked: " .. tabsSeen)
for _, w in ipairs(frames) do
    if w.check or w.slider or w.dropdown or w.edit then use(w) end
end
-- colors page: a swatch opens the colour picker, picking stores the colour
local picked
ColorPickerFrame = {
    SetupColorPickerAndShow = function(_, info) picked = info end,
    GetColorRGB = function() return 0.1, 0.2, 0.3 end,
    GetPreviousValues = function() return 0.78, 0.61, 0.43 end,
}
local swatches, warrior, emptySwatch = {}, nil, nil
for _, w in ipairs(frames) do
    if w.swatch then
        table.insert(swatches, w)
        if w.label.text == "Warrior" then warrior = w end
        if w.label.text == "Background colour" and not emptySwatch then emptySwatch = w end
    end
end
assert(#swatches >= 29 and warrior and emptySwatch, "colour swatches: " .. #swatches)
warrior.swatch.scripts.OnClick(warrior.swatch)
picked.swatchFunc()
assert(ns.colors.class.WARRIOR[1] == 0.1 and ns.db.colors["class.WARRIOR"], "colour picked")
picked.cancelFunc()
assert(ns.colors.class.WARRIOR[1] == 0.78, "cancel restores the colour")
ns.ResetColors()
-- empty bar: its background colour comes from its own swatch
emptySwatch.swatch.scripts.OnClick(emptySwatch.swatch)
picked.swatchFunc()
assert(ns.db.units.player.emptyBar.color[1] == 0.1, "empty bar colour picked")
ns.db.units.player.emptyBar.enabled = true
ns:ApplyKey("player")
local eb = ns.UF.frames.player.emptyBar
assert(eb.shown and (eb.text.center.text or ""):find("^Thrall"), "empty bar shows its texts: " .. tostring(eb.text.center.text))
ns.db.units.player.emptyBar.enabled = false
ns:ApplyKey("player")
assert(not eb.shown, "empty bar off")

-- filters page: search, add from the result list, remove from the list
FL.Search("Life")
for _ = 1, 5 do tick() end
local lists = {}
for _, w in ipairs(frames) do if w.rows then table.insert(lists, w) end end
assert(#lists == 2, "two spell lists on the filters page")
lists[1], lists[2] = lists[2], lists[1]   -- the page shows the list's auras first, the results below
lists[1]:Refresh()
assert(lists[1].rows[1].shown and lists[1].rows[1].item.id == 1454, "search result row")
lists[1].rows[1].button.scripts.OnClick(lists[1].rows[1].button)
assert(FL.Get(FL.selected)[1454], "added from the result row")
lists[1]:Refresh()
assert(lists[1].rows[1].button.text == "Added", "result marked as added")
lists[2]:Refresh()
local before = #FL.Items(FL.selected)
lists[2].rows[1].button.scripts.OnClick(lists[2].rows[1].button)
assert(#FL.Items(FL.selected) == before - 1, "removed from the list row")
lists[1].next.scripts.OnClick(lists[1].next)
lists[1].prev.scripts.OnClick(lists[1].prev)
print("filters page ok")
assert(ns:IsBlizzardHidden("playercast"), "player cast bar was hidden")
print("options: " .. #nav .. " pages, " .. tabsSeen .. " tabs, " .. used .. " controls used")
dump()

-- minimap button
local wasUnlocked = ns.unlocked
LizUFMinimapButton.scripts.OnMouseUp(LizUFMinimapButton, "RightButton")
assert(ns.unlocked ~= wasUnlocked, "right click toggles lock")
LizUFMinimapButton.scripts.OnMouseUp(LizUFMinimapButton, "RightButton")
assert(ns.unlocked == wasUnlocked, "right click toggles back")
LizUFMinimapButton.scripts.OnClick(LizUFMinimapButton, "LeftButton")
LizUFMinimapButton.scripts.OnDragStart(LizUFMinimapButton)
tick()
LizUFMinimapButton.scripts.OnDragStop(LizUFMinimapButton)
LizUF_OnAddonCompartmentClick()

SlashCmdList.LIZUF("profile Raid")
SlashCmdList.LIZUF("profile")
SlashCmdList.LIZUF("reset")
SlashCmdList.LIZUF("pet")
assert(ns.Texture():find("LizzaricksUnitFrames\\Media\\Smooth"), "default texture")
print("OK")

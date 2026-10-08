-- LizzaricksUnitFrames / Core / Init
--
-- The addon table, a small event dispatcher and the load sequence.
-- Everything lives on `ns`; the only global is the saved variable LizzaricksUFDB.
local addonName, ns = ...

ns.name = addonName
ns.version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"

-- Forever: interface 16000-19999 plus the Forever-only swing timer API.
-- WOW_PROJECT_ID reports Mainline on Forever, so it cannot tell us.
-- Retail (Midnight 12.x) has the same addon rules (secret values, aura
-- containers); only a few Classic features (pet happiness, master looter,
-- pet XP) do not exist there.
do
    local toc = select(4, GetBuildInfo())
    ns.isForever = toc >= 16000 and toc < 20000 and C_SwingTimer ~= nil
    ns.isRetail = toc >= 120000
end

function ns:Print(msg, ...)
    print("|cff9fd4ffLizzarick's Unit Frames|r: " .. string.format(msg, ...))
end

-- ------------------------------------------------------------ events --

local eventFrame = CreateFrame("Frame")
local handlers = {}

-- Registering an event the client does not know throws and aborts the
-- file, so every registration goes through pcall.
function ns:RegisterEvent(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        if not pcall(eventFrame.RegisterEvent, eventFrame, event) then
            handlers[event] = nil
            return false
        end
    end
    table.insert(handlers[event], fn)
    return true
end

function ns:UnregisterEvent(event, fn)
    local list = handlers[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == fn then table.remove(list, i) end
    end
    if #list == 0 then
        handlers[event] = nil
        eventFrame:UnregisterEvent(event)
    end
end

-- Runs fn once, now if we are out of combat, else after combat ends.
local afterCombat = {}
function ns:RunOutOfCombat(fn)
    if not InCombatLockdown() then
        fn()
    else
        table.insert(afterCombat, fn)
    end
end

-- A failing handler must not stop the others; the error goes to the debug
-- log (Core/Debug.lua, /luf debug).
local function report(where, err)
    if ns.LogError then ns.LogError(where, err) end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], event, ...)
        if not ok then report(event, err) end
    end
end)

ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    local queue = afterCombat
    afterCombat = {}
    for i = 1, #queue do
        local ok, err = pcall(queue[i])
        if not ok then report("after combat", err) end
    end
end)

-- -------------------------------------------------------------- load --

-- Modules add their start-up code here; it runs once at PLAYER_LOGIN,
-- after the saved variables are ready.
ns.onLogin = {}
function ns:OnLogin(fn)
    table.insert(self.onLogin, fn)
end

ns:RegisterEvent("PLAYER_LOGIN", function()
    ns:InitDB()
    for i = 1, #ns.onLogin do
        local ok, err = pcall(ns.onLogin[i])
        if not ok then report("login", err) end
    end
    if not (ns.isForever or ns.isRetail) then
        ns:Print("This addon is built for WoW: Forever and Retail (Midnight).")
    end
end)

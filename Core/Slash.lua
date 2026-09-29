-- FUF / Core / Slash
--
-- /fuf                    help
-- /fuf lock | unlock      config mode off / on
-- /fuf profile [name]     show or switch the profile (new names are created)
-- /fuf reset              reset the current profile to defaults
-- /fuf tags               list the available tags
local _, ns = ...

local function help()
    ns:Print("v%s commands:", ns.version)
    print("  /fuf unlock - move the frames (config mode)")
    print("  /fuf lock - end config mode")
    print("  /fuf profile [name] - show or switch the profile")
    print("  /fuf reset - reset the current profile")
    print("  /fuf tags - list the available tags")
end

local commands = {
    lock = function() ns:SetLocked(true) end,
    unlock = function() ns:SetLocked(false) end,
    profile = function(arg)
        if arg == "" then
            ns:Print("Profile: %s (all: %s)", ns:CurrentProfile(), table.concat(ns:ProfileNames(), ", "))
        elseif InCombatLockdown() then
            ns:Print("Not in combat.")
        else
            ns:SetProfile(arg)
            ns:Print("Profile: %s", arg)
        end
    end,
    reset = function()
        if InCombatLockdown() then
            ns:Print("Not in combat.")
            return
        end
        ns:ResetProfile()
        ns:Print("Profile %s reset.", ns:CurrentProfile())
    end,
    tags = function()
        ns:Print("Tags: %s", "[" .. table.concat(ns.Tags.List(), "] [") .. "]")
    end,
}

SLASH_FUF1 = "/fuf"
SlashCmdList.FUF = function(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local fn = commands[cmd:lower()]
    if fn then fn(arg) else help() end
end

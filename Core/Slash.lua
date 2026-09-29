-- FUF / Core / Slash
--
-- /fuf                    options window
-- /fuf lock | unlock      config mode off / on
-- /fuf profile [name]     show or switch the profile (new names are created)
-- /fuf reset              reset the current profile to defaults
-- /fuf help               this list
local _, ns = ...

local function help()
    ns:Print("v%s commands:", ns.version)
    print("  /fuf - options window")
    print("  /fuf unlock - move the frames (config mode)")
    print("  /fuf lock - end config mode")
    print("  /fuf profile [name] - show or switch the profile")
    print("  /fuf reset - reset the current profile")
end

local commands = {
    [""] = function() ns.Options:Toggle() end,
    options = function() ns.Options:Toggle() end,
    help = help,
    lock = function() ns:SetLocked(true) end,
    unlock = function() ns:SetLocked(false) end,
    profile = function(arg)
        if arg == "" then
            ns:Print("Profile: %s (all: %s)", ns:CurrentProfile(), table.concat(ns:ProfileNames(), ", "))
        else
            ns:SetProfile(arg)
            ns:Print("Profile: %s", arg)
        end
    end,
    reset = function()
        ns:ResetProfile()
        ns:Print("Profile %s reset.", ns:CurrentProfile())
    end,
    tags = function() ns.Options:Open("tags") end,
}

SLASH_FUF1 = "/fuf"
SlashCmdList.FUF = function(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local fn = commands[cmd:lower()]
    if fn then fn(arg) else help() end
end

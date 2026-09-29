-- LizzaricksUnitFrames / Core / Slash
--
-- /lzuf                    options window
-- /lzuf lock | unlock      config mode off / on
-- /lzuf profile [name]     show or switch the profile (new names are created)
-- /lzuf reset              reset the current profile to defaults
-- /lzuf help               this list
local _, ns = ...

local function help()
    ns:Print("v%s commands:", ns.version)
    print("  /lzuf - options window")
    print("  /lzuf unlock - move the frames (config mode)")
    print("  /lzuf lock - end config mode")
    print("  /lzuf profile [name] - show or switch the profile")
    print("  /lzuf reset - reset the current profile")
    print("  /lzuf pet - show what the game reports about your pet's happiness")
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
    -- Diagnosis: what the client reports for the player's pet.
    pet = function()
        local exists = UnitExists("pet")
        ns:Print("pet exists: %s", tostring(exists))
        if not C_PetInfo or not C_PetInfo.GetPetHappiness then
            ns:Print("C_PetInfo.GetPetHappiness does not exist in this client")
            return
        end
        local ok, h, dmg, rate = pcall(C_PetInfo.GetPetHappiness)
        if not ok then
            ns:Print("GetPetHappiness error: %s", tostring(h))
        elseif ns.IsSecret(h) then
            ns:Print("GetPetHappiness: secret value")
        else
            ns:Print("GetPetHappiness: happiness=%s damage=%s%% loyaltyRate=%s", tostring(h), tostring(dmg), tostring(rate))
        end
        local okL, loyalty = pcall(C_PetInfo.GetPetLoyalty)
        ns:Print("GetPetLoyalty: %s", okL and (ns.IsSecret(loyalty) and "secret" or tostring(loyalty)) or "error")
    end,
}

SLASH_LIZUF1 = "/lzuf"
SLASH_LIZUF2 = "/lizuf"
SlashCmdList.LIZUF = function(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local fn = commands[cmd:lower()]
    if fn then fn(arg) else help() end
end

-- LizzaricksUnitFrames / Core / Slash
--
-- /luf                    options window
-- /luf lock | unlock      config mode off / on
-- /luf profile [name]     show or switch the profile (new names are created)
-- /luf reset              reset the current profile to defaults
-- /luf help               this list
local _, ns = ...

local function help()
    ns:Print("v%s commands:", ns.version)
    print("  /luf - options window")
    print("  /luf unlock - move the frames (config mode)")
    print("  /luf lock - end config mode")
    print("  /luf profile [name] - show or switch the profile")
    print("  /luf reset - reset the current profile")
    print("  /luf pet - show what the game reports about your pet's happiness")
    print("  /luf buffs - your buffs: which count as \"mine\" and \"castable\" (out of combat)")
end

-- Spell IDs of the player's buffs that pass `filter` (out of combat only:
-- in combat the client refuses addon aura reads).
local function buffIDs(filter)
    local ids = {}
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return ids end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, filter)
        if not ok or type(aura) ~= "table" then break end
        local id = aura.spellId
        if ns.CanRead(id) and id then ids[id] = aura.name end
    end
    return ids
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
    -- Diagnosis for the "My buffs" / "Castable buffs" squares: what the
    -- client's filters HELPFUL|PLAYER and HELPFUL|RAID let through.
    buffs = function()
        if InCombatLockdown() then ns:Print("Not in combat, please.") return end
        local all = buffIDs("HELPFUL")
        local mine, castable = buffIDs("HELPFUL|PLAYER"), buffIDs("HELPFUL|RAID")
        ns:Print("Your buffs (mine = cast by you, castable = you can cast it):")
        local any = false
        for id, name in pairs(all) do
            any = true
            print(string.format("  %s (%d): mine %s, castable %s", ns.CanRead(name) and tostring(name) or "?", id,
                mine[id] and "|cff33dd33yes|r" or "|cffdd3333no|r", castable[id] and "|cff33dd33yes|r" or "|cffdd3333no|r"))
        end
        if not any then print("  none (or the game hides them)") end
    end,
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

SLASH_LIZUF1 = "/luf"
-- the commands up to 0.10.0 keep working
SLASH_LIZUF2 = "/lzuf"
SLASH_LIZUF3 = "/lizuf"
SlashCmdList.LIZUF = function(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local fn = commands[cmd:lower()]
    if fn then fn(arg) else help() end
end

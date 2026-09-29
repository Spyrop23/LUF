-- FUF / Frames / Range
--
-- Out-of-range fading for group members and pets (Luna: alpha 0.4).
--
-- UnitInRange returns SECRET booleans in Forever. We never test them:
-- Frame:SetAlphaFromBoolean lets the client pick the alpha from the secret.
-- Only where the answer is readable (and "not checked", e.g. the player
-- itself) do we decide in Lua.
local _, ns = ...

local RG = {}
ns.Range = RG

-- Settings keys that fade. UnitInRange answers for group members (and their
-- pets); for the player's own pet it reports "out of range" even next to
-- you, as a secret we cannot catch, so the pet frame never fades.
RG.supported = { party = true, partypet = true, raid = true }

local POLL_EVERY = 0.25

local function isPlayer(unit)
    if unit == "player" then return true end
    local ok, same = pcall(UnitIsUnit, unit, "player")
    return ok and ns.CanRead(same) and same or false
end

function RG.Update(f)
    local db = f.db.range
    if not (RG.supported[f.key] and db and db.enabled) or ns.unlocked then
        f:SetAlpha(1)
        return
    end
    local unit = f.unit
    if isPlayer(unit) or not UnitExists(unit) then
        f:SetAlpha(1)
        return
    end
    local inRange, checked = UnitInRange(unit)
    -- a readable "not checked" means: no range information, stay opaque
    if ns.CanRead(checked) and not checked then
        f:SetAlpha(1)
        return
    end
    if ns.CanRead(inRange) then
        f:SetAlpha(inRange and 1 or db.alpha)
    elseif f.SetAlphaFromBoolean then
        f:SetAlphaFromBoolean(inRange, 1, db.alpha)
    end
end

-- One shared poll for all fading frames; plus the client's range event.
local ticker = CreateFrame("Frame")
local wait = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    wait = wait + elapsed
    if wait < POLL_EVERY then return end
    wait = 0
    if not ns.UF then return end
    for key in pairs(RG.supported) do
        for _, f in ipairs(ns.UF.byKey[key] or {}) do
            if f:IsVisible() then RG.Update(f) end
        end
    end
end)

ns:RegisterEvent("UNIT_IN_RANGE_UPDATE", function(_, unit)
    local f = ns.UF and unit and ns.UF.frames[unit]
    if f and f:IsVisible() then RG.Update(f) end
end)

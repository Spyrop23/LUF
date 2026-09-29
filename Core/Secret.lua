-- FUF / Core / Secret
--
-- Forever runs the retail 12.x addon restrictions. Health, power and many
-- other combat values reach addon code as SECRET VALUES: they may be stored,
-- passed on, handed to widget setters and formatted with string.format, but
-- arithmetic, comparison, boolean tests, `#`, and use as a table key throw.
--
--     DISPLAY a secret, never DECIDE on one.
--
-- Always secret (also out of combat): UnitHealth, UnitHealthPercent,
-- UnitPower of the player. Everything else: check with ns.CanRead first.
local _, ns = ...

local issecretvalue = _G.issecretvalue
local canaccessvalue = _G.canaccessvalue

function ns.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) or false
end

-- True when the value may be compared or used as a table key right now.
function ns.CanRead(v)
    if not issecretvalue or not issecretvalue(v) then return true end
    return canaccessvalue ~= nil and canaccessvalue(v) or false
end

-- The value if readable, else the fallback.
function ns.Readable(v, fallback)
    if ns.CanRead(v) then return v end
    return fallback
end

-- ---------------------------------------------------------- bar fills --

-- Health as a 0..1 fraction: UnitHealthPercent does the division inside
-- the client, which is the only place it may happen.
function ns.SetHealthFill(bar, unit)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(UnitHealthPercent(unit, true))
end

-- Power: both values may be secret, the widget takes them anyway.
function ns.SetPowerFill(bar, unit)
    bar:SetMinMaxValues(0, UnitPowerMax(unit))
    bar:SetValue(UnitPower(unit))
end

-- ------------------------------------------------------------ curves --

-- Percent 0..100 for text (the raw return is a 0..1 fraction).
ns.ScaleTo100 = _G.CurveConstants and CurveConstants.ScaleTo100

-- Colour by health, evaluated by the client: red -> yellow -> green.
local healthCurve
function ns.HealthColorCurve()
    if not healthCurve and C_CurveUtil then
        healthCurve = C_CurveUtil.CreateColorCurve()
        healthCurve:AddPoint(0.0, CreateColor(0.90, 0.00, 0.00, 1))
        healthCurve:AddPoint(0.5, CreateColor(0.93, 0.93, 0.00, 1))
        healthCurve:AddPoint(1.0, CreateColor(0.20, 0.90, 0.20, 1))
    end
    return healthCurve
end

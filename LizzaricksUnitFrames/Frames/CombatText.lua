-- LizzaricksUnitFrames / Frames / CombatText
--
-- Luna's combat text: damage (red), heals (green) and misses (white) of the
-- unit flash on its portrait (or the frame's centre) and fade out. Critical
-- hits are larger.
--
-- The numbers come from UNIT_COMBAT. The event name is only used when
-- readable; the amount goes straight into the font string (SetFormattedText
-- takes a secret number), so nothing is compared or counted.
local _, ns = ...

local CT = {}
ns.CombatText = CT

local COLORS = {
    WOUND = { 1.00, 0.10, 0.10 },
    HEAL = { 0.10, 1.00, 0.10 },
    ENERGIZE = { 0.41, 0.80, 0.94 },
    OTHER = { 1.00, 1.00, 1.00 },
}
local HOLD, FADE = 0.4, 1.2   -- seconds fully visible, then fading

local function fade(holder, elapsed)
    holder.age = holder.age + elapsed
    if holder.age >= HOLD + FADE then
        holder:SetScript("OnUpdate", nil)
        holder.text:Hide()
    elseif holder.age > HOLD then
        holder.text:SetAlpha(1 - (holder.age - HOLD) / FADE)
    end
end

-- The word for a miss, dodge, parry ... in the client's language.
local function word(token)
    local s = _G[token]
    return type(s) == "string" and s or token:sub(1, 1) .. token:sub(2):lower()
end

function CT.Show(f, event, flag, amount)
    local db = f.db.combatText
    if not (db and db.enabled and f:IsVisible()) or not ns.CanRead(event) or type(event) ~= "string" then return end
    local holder = f.combatText
    local fs = holder.text
    local crit = ns.CanRead(flag) and (flag == "CRITICAL" or flag == "CRUSHING")
    local c = COLORS[event] or COLORS.OTHER
    local ok
    if event == "WOUND" or event == "HEAL" or event == "ENERGIZE" then
        -- a fully absorbed/blocked hit comes with 0 and the reason as flag
        if ns.CanRead(amount) and amount == 0 and ns.CanRead(flag) and type(flag) == "string" and flag ~= "" then
            fs:SetText(word(flag))
            c, ok = COLORS.OTHER, true
        else
            ok = pcall(fs.SetFormattedText, fs, event == "WOUND" and "-%d" or "+%d", amount)
        end
    else
        fs:SetText(word(event))
        ok = true
    end
    if not ok then return end
    ns.SetFont(fs, crit and math.floor(db.size * 1.5) or db.size, "OUTLINE")
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetAlpha(1)
    fs:Show()
    holder.age = 0
    holder:SetScript("OnUpdate", fade)
end

function CT.Create(f)
    local holder = CreateFrame("Frame", nil, f)
    holder:SetAllPoints(f)
    holder:SetFrameLevel(f:GetFrameLevel() + 13)
    holder.text = holder:CreateFontString(nil, "OVERLAY")
    ns.SetFont(holder.text, 20, "OUTLINE")
    holder.text:Hide()
    holder.age = 0
    f.combatText = holder

    local ev = CreateFrame("Frame")
    pcall(ev.RegisterUnitEvent, ev, "UNIT_COMBAT", f.unit)
    ev:SetScript("OnEvent", function(_, _, _, event, flag, amount)
        CT.Show(f, event, flag, amount)
    end)
    f.combatTextEvents = ev   -- UF.SetUnit re-registers it
end

-- Where the text sits (protected context: called from UF.Layout).
function CT.Layout(f)
    local holder = f.combatText
    if not holder then return end
    holder.text:ClearAllPoints()
    holder.text:SetPoint("CENTER", f.portrait or f, "CENTER", 0, 0)
    if not f.db.combatText.enabled then holder.text:Hide() end
end

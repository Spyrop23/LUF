-- LizzaricksUnitFrames / Options / Minimap
--
-- Minimap button: left click opens the options, right click locks or
-- unlocks the frames, dragging moves it around the minimap. Its angle and
-- visibility are account-wide (LizzaricksUFDB.minimap), not part of a profile.
local _, ns = ...

local M = {}
ns.Minimap = M

local ICON = "Interface\\Icons\\Spell_Nature_StarFall"
local button

local function place()
    local angle = math.rad(LizzaricksUFDB.minimap.angle or 220)
    local r = (Minimap:GetWidth() / 2) + 10
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function onDragUpdate()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local s = Minimap:GetEffectiveScale()
    LizzaricksUFDB.minimap.angle = math.deg(math.atan2(py / s - my, px / s - mx))
    place()
end

local function create()
    button = CreateFrame("Button", "LizUFMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    -- Left click through OnClick; the right button is handled in OnMouseUp,
    -- which fires for every mouse-enabled frame (a right-click OnClick did
    -- not arrive on the Forever minimap).
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouse)
        if mouse == "LeftButton" then ns.Options:Toggle() end
    end)
    button:SetScript("OnMouseUp", function(self, mouse)
        if mouse ~= "RightButton" then return end
        ns:SetLocked(ns.unlocked)   -- unlocked -> lock, locked -> unlock
        if self:IsMouseOver() and self:GetScript("OnEnter") then self:GetScript("OnEnter")(self) end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onDragUpdate) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Lizzarick's Unit Frames")
        GameTooltip:AddLine("Left click: options", 1, 1, 1)
        GameTooltip:AddLine("Right click: " .. (ns.unlocked and "lock" or "unlock"), 1, 1, 1)
        GameTooltip:AddLine("Drag: move this button", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function M:Update()
    if LizzaricksUFDB.minimap.hide then
        if button then button:Hide() end
        return
    end
    if not button then create() end
    place()
    button:Show()
end

ns:OnLogin(function() M:Update() end)

-- Hoard Value: minimap button and addon compartment entry
-- Click to open the window, right-click for options, hover for the totals,
-- drag to move the button around the minimap.

local _, ns = ...

local ICON = "Interface\\Icons\\INV_Misc_Coin_01"

-- Button art, matching the standard minimap button look.
local BUTTON_SIZE, BORDER_SIZE, BACKGROUND_SIZE, ICON_SIZE = 31, 50, 24, 18
local EDGE_GAP = 5 -- how far outside the minimap's edge the button sits

local button
local totals -- { char, account } for the tooltip, until data, prices or settings change

local function forgetTotals()
	totals = nil
end

ns.Listen("DataChanged", forgetTotals)
ns.Listen("ItemInfoLoaded", forgetTotals)
ns.Listen("SettingChanged", function(_, key)
	totals = nil
	if key == "minimap" and button then button:SetShown(ns.db.minimap) end
end)

local function showTotals(owner)
	if not totals then
		totals = { char = ns.BuildReport("char").total, account = ns.BuildReport("account").total }
	end
	GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
	GameTooltip:SetText("Hoard Value")
	GameTooltip:AddDoubleLine(UnitName("player"), ns.Money(totals.char), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine("Account", ns.Money(totals.account), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Click to open, right-click for options", 0.6, 0.6, 0.6)
	GameTooltip:Show()
end

local function onClick(mouseButton)
	if mouseButton == "RightButton" then ns.OpenOptions() else ns.ToggleWindow() end
end

local function place()
	local angle = math.rad(ns.db.minimapAngle)
	local x, y = math.cos(angle), math.sin(angle)
	local w, h = Minimap:GetWidth() / 2 + EDGE_GAP, Minimap:GetHeight() / 2 + EDGE_GAP
	if GetMinimapShape and GetMinimapShape() == "SQUARE" then
		-- Slide along the edge of a square minimap instead of a circle
		-- (1.42 is about the square root of 2: reach the corners, then clamp).
		x = math.max(-w, math.min(x * w * 1.42, w))
		y = math.max(-h, math.min(y * h * 1.42, h))
	else
		x, y = x * w, y * h
	end
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function followCursor()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	ns.db.minimapAngle = math.deg(math.atan2(py / scale - my, px / scale - mx))
	place()
end

local function createButton()
	button = CreateFrame("Button", "HoardValueMinimapButton", Minimap)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture(136477) -- Interface\Minimap\UI-Minimap-ZoomButton-Highlight

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(BORDER_SIZE, BORDER_SIZE)
	border:SetTexture(136430) -- Interface\Minimap\MiniMap-TrackingBorder
	border:SetPoint("TOPLEFT")
	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetSize(BACKGROUND_SIZE, BACKGROUND_SIZE)
	background:SetTexture(136467) -- Interface\Minimap\UI-Minimap-Background
	background:SetPoint("CENTER")
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetTexture(ICON)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- trim the icon's built-in border
	icon:SetPoint("CENTER")

	button:SetScript("OnClick", function(_, mouseButton) onClick(mouseButton) end)
	button:SetScript("OnEnter", showTotals)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", followCursor)
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

	place()
	button:SetShown(ns.db.minimap)
end

ns.On("PLAYER_LOGIN", createButton)

-- Addon compartment (the addon menu on Retail's minimap), named in the .toc.
function HoardValue_OnAddonCompartmentClick(_, mouseButton)
	onClick(mouseButton)
end

function HoardValue_OnAddonCompartmentEnter(_, menuButton)
	showTotals(menuButton)
end

function HoardValue_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

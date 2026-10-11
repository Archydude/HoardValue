-- Hoard Value: minimap button (LibDBIcon, so minimap button collectors pick it
-- up) and addon compartment entry. Click to open the window, right-click for
-- options, hover for the totals.

local _, ns = ...

local NAME = "HoardValue" -- the button's name with LibDBIcon
local ICON = "Interface\\Icons\\INV_Misc_Coin_01"

local LDBIcon = LibStub("LibDBIcon-1.0")
local registered = false
local totals -- { char, account } for the tooltip, until data, prices or settings change

local function forgetTotals()
	totals = nil
end

ns.Listen("DataChanged", forgetTotals)
ns.Listen("ItemInfoLoaded", forgetTotals)
ns.Listen("SettingChanged", function(_, key)
	totals = nil
	if key == "minimap" and registered then
		if ns.db.minimap then LDBIcon:Show(NAME) else LDBIcon:Hide(NAME) end
	end
end)

local function fillTooltip(tooltip)
	if not totals then
		totals = { char = ns.BuildReport("char").total, account = ns.BuildReport("account").total }
	end
	tooltip:SetText("Hoard Value")
	tooltip:AddDoubleLine(ns.PlayerName(), ns.Money(totals.char), 1, 1, 1, 1, 1, 1)
	tooltip:AddDoubleLine("Account", ns.Money(totals.account), 1, 1, 1, 1, 1, 1)
	tooltip:AddLine(" ")
	tooltip:AddLine("Click to open, right-click for options", 0.6, 0.6, 0.6)
end

local function onClick(mouseButton)
	if mouseButton == "RightButton" then ns.OpenOptions() else ns.ToggleWindow() end
end

ns.On("PLAYER_LOGIN", function()
	registered = true
	ns.db.minimapIcon.hide = not ns.db.minimap
	local launcher = LibStub("LibDataBroker-1.1"):NewDataObject(NAME, {
		type = "launcher",
		label = "Hoard Value",
		icon = ICON,
		OnClick = function(_, mouseButton) onClick(mouseButton) end,
		OnTooltipShow = fillTooltip,
	})
	LDBIcon:Register(NAME, launcher, ns.db.minimapIcon)
end)

-- Addon compartment (the addon menu on Retail's minimap), named in the .toc.
function HoardValue_OnAddonCompartmentClick(_, mouseButton)
	onClick(mouseButton)
end

function HoardValue_OnAddonCompartmentEnter(_, menuButton)
	GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
	fillTooltip(GameTooltip)
	GameTooltip:Show()
end

function HoardValue_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

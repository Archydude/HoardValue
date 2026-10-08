-- Hoard Value: options
-- Esc > Options > AddOns > Hoard Value. Every change fires "SettingChanged".

local _, ns = ...

-- TSM price types offered in the options.
local TSM_SOURCES = {
	{ "dbmarket", "Market value (recommended)" },
	{ "dbminbuyout", "Lowest auction right now" },
	{ "dbhistorical", "Historical price" },
	{ "dbregionmarketavg", "Region market average" },
}

local category
local settings = {} -- key -> the options page's setting object

function ns.OpenOptions()
	if category then Settings.OpenToCategory(category:GetID()) end
end

-- Changes a setting from elsewhere (the window's Realistic checkbox) through the
-- options page, so the page stays in sync.
function ns.SetSetting(key, value)
	if settings[key] then
		settings[key]:SetValue(value)
	else
		ns.db[key] = value
		ns.Fire("SettingChanged", key)
	end
end

local function createSettings()
	local layout
	category, layout = Settings.RegisterVerticalLayoutCategory("Hoard Value")
	local VarType = Settings.VarType or { Boolean = "boolean", String = "string", Number = "number" }

	-- Section headings; skipped on clients that can't draw them.
	local function header(text)
		if CreateSettingsListSectionHeaderInitializer then
			layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
		end
	end

	local function setting(key, varType, name)
		local s = Settings.RegisterAddOnSetting(category, "HOARDVALUE_" .. key:upper(), key, ns.db, varType, name,
			ns.DEFAULTS[key])
		s:SetValueChangedCallback(function() ns.Fire("SettingChanged", key) end)
		settings[key] = s
		return s
	end

	local function checkbox(key, name, tooltip)
		Settings.CreateCheckbox(category, setting(key, VarType.Boolean, name), tooltip)
	end

	local function dropdown(key, name, choices, tooltip)
		local function getOptions()
			local container = Settings.CreateControlTextContainer()
			for _, choice in ipairs(choices) do container:Add(choice[1], choice[2]) end
			return container:GetData()
		end
		Settings.CreateDropdown(category, setting(key, VarType.String, name), getOptions, tooltip)
	end

	header("What counts")
	checkbox("countBound", "Count soulbound items",
		(ns.HAS_WARBAND and "Soulbound and warbound items" or "Soulbound items")
			.. " can't be sold on the auction house. When on, they count at what a vendor pays for them.")
	if ns.HAS_WARBAND then
		checkbox("countWarband", "Include the warband bank",
			"Add the warband bank's gold and items to the account total. It's shared by all your characters, so it counts once.")
	end

	header("Prices")
	dropdown("provider", "Price addon", {
		{ "auto", "Automatic (TSM, then Auctionator)" },
		{ "tsm", "TradeSkillMaster only" },
		{ "auctionator", "Auctionator only" },
	}, "Where prices come from. Automatic uses TSM and falls back to Auctionator for items TSM has no price for. Items with no auction price count at vendor price.")
	dropdown("tsmSource", "TSM price", TSM_SOURCES,
		"Which TSM price to use. Market value smooths out spikes; lowest auction is what's listed right now.")
	checkbox("realistic", "Realistic value",
		"What you'd actually get selling everything: each item at the lower of its market value and the cheapest auction right now, minus the auction house's 5% cut.")

	header("Display")
	checkbox("minimap", "Show minimap button",
		"Click it to open Hoard Value. Drag it to move it around the minimap."
			.. (AddonCompartmentFrame and " Hoard Value is also in the addon menu on the minimap." or ""))
	dropdown("precision", "Show amounts down to", {
		{ "gold", "Gold (2,904g)" },
		{ "silver", "Silver (2,903g 83s)" },
		{ "copper", "Copper (2,903g 83s 45c)" },
	}, "Rounds every amount to this coin. Amounts smaller than one coin still show the next coin down.")
	checkbox("showZero", "List items with no value",
		"Also list items that have no auction or vendor price (quest items, keys...).")
	checkbox("tooltipCounts", "Show who has it on item tooltips",
		"Item tooltips list which of your characters have that item and how many, in their bags and in their bank"
			.. (ns.HAS_WARBAND and ", with the warband bank on its own line." or "."))
	dropdown("tooltipSpacing", "Blank line on item tooltips", {
		{ "above", "Above Hoard Info" },
		{ "below", "Below Hoard Info" },
		{ "both", "Above and below" },
		{ "none", "None" },
	}, "Where a blank line goes to set the Hoard Info lines apart from the rest of the tooltip.")

	layout:AddInitializer(CreateSettingsButtonInitializer("Window position", "Reset", function()
		ns.ResetWindowPosition()
	end, "Put the Hoard Value window back in the middle of the screen.", true))

	Settings.RegisterAddOnCategory(category)
end

ns.Listen("Loaded", createSettings)

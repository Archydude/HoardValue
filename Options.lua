-- Hoard Value: options
-- Esc > Options > AddOns > Hoard Value. Every change fires "SettingChanged".

local _, ns = ...

-- TSM price types offered in the options.
local TSM_SOURCES = {
	{ "dbmarket", "Market value (recommended)" },
	{ "dbminbuyout", "Lowest auction right now" },
	{ ns.TSM_LOWER, "Lower of market and lowest" }, -- short: the closed dropdown cuts long names
	{ "dbhistorical", "Historical price" },
	{ "dbregionmarketavg", "Region market average" },
}

local category
local settings = {} -- key -> the options page's setting object

-- The game doesn't let addons open its settings during combat, so a request then waits for the fight to end.
local openAfterCombat = false

function ns.OpenOptions()
	if not category then return end
	if InCombatLockdown() then
		if not openAfterCombat then
			openAfterCombat = true
			print("|cffffd100Hoard Value|r the options open when you leave combat.")
		end
		return
	end
	Settings.OpenToCategory(category:GetID())
end

ns.On("PLAYER_REGEN_ENABLED", function()
	if openAfterCombat then
		openAfterCombat = false
		ns.OpenOptions()
	end
end)

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

	-- Like Settings.CreateCheckbox / CreateDropdown, but on our own row templates (see
	-- Options.xml). On Blizzard's templates, a row that drew one of our settings is later
	-- reused for Blizzard's own, which then can't call protected functions: its Discord
	-- dropdown and button get blocked (ADDON_ACTION_FORBIDDEN on IsUserOAuthed).
	local function control(template, s, options, tooltip)
		layout:AddInitializer(Settings.CreateControlInitializer(template, s, options, tooltip))
	end

	local function checkbox(key, name, tooltip)
		control("HoardValueSettingsCheckboxTemplate", setting(key, VarType.Boolean, name), nil, tooltip)
	end

	local function dropdown(key, name, choices, tooltip, varType)
		local function getOptions()
			local container = Settings.CreateControlTextContainer()
			for _, choice in ipairs(choices) do container:Add(choice[1], choice[2]) end
			return container:GetData()
		end
		control("HoardValueSettingsDropdownTemplate", setting(key, varType or VarType.String, name), getOptions, tooltip)
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
		{ "auto", "Automatic (TSM first)" },
		{ "tsm", "TradeSkillMaster only" },
		{ "auctionator", "Auctionator only" },
		{ "craftonomics", "Craftonomics only" },
	}, "Where prices come from. Automatic uses TSM, then Auctionator for items TSM has no price for, then Craftonomics for items neither has a price for. Craftonomics' prices follow its own Price addon option, so they can come from its own auction house scans. Items with no auction price, and gray junk, count at vendor price.")
	dropdown("tsmSource", "TSM price", TSM_SOURCES,
		"Which TSM price to use. Market value smooths out spikes; lowest auction is what's listed right now. "
			.. "The lower of the two is the careful one: an item never counts for more than it's listed for right now.")
	checkbox("realistic", "Realistic value",
		"What you'd actually get selling everything: each item at the lower of its market value and the cheapest auction right now, minus the auction house's 5% cut.")

	header("Display")
	checkbox("minimap", "Show minimap button",
		"Click it to open Hoard Value. Drag it to move it around the minimap."
			.. (AddonCompartmentFrame and " Hoard Value is also in the addon menu on the minimap." or ""))
	checkbox("bagValue", "Show bags value in the bag window",
		"Shows what the items in your bags are worth at the bottom of the game's own bag window, left of your gold. Hover it for this character's total, click it to open Hoard Value. Bag addons that replace the game's bags don't show it.")
	checkbox("lootValue", "Say what picked-up items are worth",
		"When you loot an item or are handed one, a chat line only you see says what it's worth. Soulbound items are only mentioned with Count soulbound items on.")
	dropdown("lootValueMin", "Only picked-up items worth at least", {
		{ 0, "Any value" },
		{ 1, "1 gold" },
		{ 10, "10 gold" },
		{ 100, "100 gold" },
		{ 1000, "1,000 gold" },
	}, "Picked-up items worth less than this, for the whole stack, aren't mentioned in chat.", VarType.Number)
	dropdown("precision", "Show amounts down to", {
		{ "gold", "Gold (2,904g)" },
		{ "silver", "Silver (2,903g 83s)" },
		{ "copper", "Copper (2,903g 83s 45c)" },
	}, "Rounds every amount to this coin. Amounts smaller than one coin still show the next coin down.")
	checkbox("showZero", "List items with no value",
		"Also list items that have no auction or vendor price (quest items, keys...).")
	checkbox("listAll", "List every item",
		"List everything in your bags and banks, so you can search all of it, including "
			.. (ns.HAS_WARBAND and "soulbound and warbound items" or "soulbound items")
			.. " and items with no value. Totals don't change: bound items only add to them with Count soulbound items on.")
	checkbox("tooltipCounts", "Show who has it on item tooltips",
		"Item tooltips list which of your characters have that item and how many, in their bags and in their bank"
			.. (ns.HAS_WARBAND and ", with the warband bank on its own line." or "."))
	dropdown("tooltipSpacing", "Blank line on item tooltips", {
		{ "above", "Above Hoard Info" },
		{ "below", "Below Hoard Info" },
		{ "both", "Above and below" },
		{ "none", "None" },
	}, "Where a blank line goes to set the Hoard Info lines apart from the rest of the tooltip.")

	-- Like CreateSettingsButtonInitializer, but on our own row template and with no search
	-- tags. Tags added from addon code are tainted, and the options search box reads every
	-- page's tags unprotected, so the whole search turns tainted and Blizzard's Discord
	-- button in the results gets blocked. Checkboxes and dropdowns get their tags in
	-- Blizzard's own secure code.
	layout:AddInitializer(Settings.CreateElementInitializer("HoardValueSettingsButtonTemplate", {
		name = "Window position",
		buttonText = "Reset",
		buttonClick = function() ns.ResetWindowPosition() end,
		tooltip = "Put the Hoard Value window back in the middle of the screen.",
	}))

	Settings.RegisterAddOnCategory(category)
end

ns.Listen("Loaded", createSettings)

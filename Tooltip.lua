-- Hoard Value: item tooltips
-- Adds to every item tooltip which of your characters have that item and how
-- many, in their bags and in their bank, plus the warband bank on its own line.

local _, ns = ...
local format = string.format

local WARBAND = "#warband" -- owner key for the warband bank

---------------------------------------------------------------------------
-- Who has what
---------------------------------------------------------------------------

-- itemID -> { [charKey or WARBAND] = { bags = n, bank = n } }. Built from the
-- saved data the first time a tooltip needs it after the data changed.
local index

-- Saved items' keys start with their link's "item:<id>:".
local function addItems(items, owner, where)
	for _, item in ipairs(items or {}) do
		local id = tonumber(item.key:match("^item:(%d+)"))
		if id then
			local owners = index[id]
			if not owners then
				owners = {}
				index[id] = owners
			end
			local place = owners[owner]
			if not place then
				place = { bags = 0, bank = 0 }
				owners[owner] = place
			end
			place[where] = place[where] + item.count
		end
	end
end

local function buildIndex()
	index = {}
	for charKey, c in pairs(ns.db.chars) do
		addItems(c.bags, charKey, "bags")
		addItems(c.bank, charKey, "bank")
	end
	if ns.HAS_WARBAND then addItems(ns.db.warband.items, WARBAND, "bank") end
end

ns.Listen("DataChanged", function() index = nil end)

---------------------------------------------------------------------------
-- Tooltip lines
---------------------------------------------------------------------------

local number = BreakUpLargeNumbers

-- "Name", with the realm added for characters on another realm.
local function charName(c, key)
	local name = ns.ClassColored(c.name and c or { name = key })
	if c.realm and c.realm ~= GetRealmName() then
		name = name .. " |cff888888(" .. c.realm .. ")|r"
	end
	return name
end

-- The addon's own icons (white, in Media), sized to the line's text and tinted.
local function icon(name, r, g, b)
	return format("|TInterface\\AddOns\\%s\\Media\\%s:0:0:0:0:64:64:0:64:0:64:%d:%d:%d|t",
		ns.ADDON_NAME, name, r, g, b)
end
local BAG_ICON = icon("bag", 230, 215, 180)
local BANK_ICON = icon("bank", 255, 209, 0)
local WARBAND_ICON = icon("bank", 51, 204, 255)

-- "5 [bag]  20 [chest]"
local function placeText(place)
	local parts = {}
	if place.bags > 0 then parts[#parts + 1] = number(place.bags) .. " " .. BAG_ICON end
	if place.bank > 0 then parts[#parts + 1] = number(place.bank) .. " " .. BANK_ICON end
	return table.concat(parts, "  ")
end

local function addLines(tooltip, id)
	if not index then buildIndex() end
	local owners = index[id]
	if not owners then return end

	-- This character first, then whoever has the most.
	local rows = {}
	for owner, place in pairs(owners) do
		if owner ~= WARBAND then
			rows[#rows + 1] = { key = owner, char = ns.db.chars[owner] or {}, place = place,
				total = place.bags + place.bank }
		end
	end
	table.sort(rows, function(a, b)
		if (a.key == ns.charKey) ~= (b.key == ns.charKey) then return a.key == ns.charKey end
		if a.total ~= b.total then return a.total > b.total end
		return a.key < b.key
	end)

	-- A heading, so it's clear these lines are Hoard Value's, with a blank line
	-- above and/or below them as the player picked.
	local spacing = ns.db.tooltipSpacing
	if spacing == "above" or spacing == "both" then tooltip:AddLine(" ") end
	tooltip:AddLine("Hoard Info", 1, 0.82, 0)

	local total, lines = 0, 0
	for _, row in ipairs(rows) do
		tooltip:AddDoubleLine(charName(row.char, row.key), placeText(row.place), 1, 1, 1, 1, 1, 1)
		total, lines = total + row.total, lines + 1
	end
	local warband = owners[WARBAND]
	if warband then
		tooltip:AddDoubleLine("Warband bank", number(warband.bank) .. " " .. WARBAND_ICON, 0, 0.8, 1, 1, 1, 1)
		total, lines = total + warband.bank, lines + 1
	end
	if lines > 1 then
		tooltip:AddDoubleLine("Total", number(total), 1, 0.82, 0, 1, 1, 1)
	end
	if spacing == "below" or spacing == "both" then tooltip:AddLine(" ") end
end

---------------------------------------------------------------------------
-- Hooking item tooltips
---------------------------------------------------------------------------

-- Tooltips that already got their lines, until they're cleared. Some tooltips
-- report the same item twice while it loads.
local done = setmetatable({}, { __mode = "k" })
local watched = setmetatable({}, { __mode = "k" })

local function watch(tooltip)
	if watched[tooltip] then return end
	watched[tooltip] = true
	local function reset() done[tooltip] = nil end
	pcall(tooltip.HookScript, tooltip, "OnTooltipCleared", reset)
	pcall(tooltip.HookScript, tooltip, "OnHide", reset)
end

-- Returns true when lines were added.
local function onItem(tooltip, id)
	if not (ns.db and ns.db.tooltipCounts) or ns.ownItemTooltip then return end
	if issecretvalue and issecretvalue(id) then return end
	if type(id) ~= "number" or not tooltip.AddDoubleLine then return end
	watch(tooltip)
	if done[tooltip] == id then return end
	done[tooltip] = id
	addLines(tooltip, id)
	return true
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
		onItem(tooltip, data and data.id)
	end)
else
	local function onSetItem(tooltip)
		local ok, _, link = pcall(tooltip.GetItem, tooltip)
		if ok and link and onItem(tooltip, ns.ItemID(link)) then tooltip:Show() end
	end
	for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
		if tooltip then tooltip:HookScript("OnTooltipSetItem", onSetItem) end
	end
end


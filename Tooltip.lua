-- Hoard Value: item tooltips
-- Adds to every item tooltip which of your characters have that item and how
-- many, in their bags and in their bank, plus the warband bank on its own line.

local _, ns = ...
local format = string.format

local WARBAND = "#warband" -- owner key for the warband bank

---------------------------------------------------------------------------
-- Who has what
---------------------------------------------------------------------------

-- Crafting materials (and crafted items) come in qualities (ranks), and each
-- rank is its own item. They're grouped by name: an item's tooltip shows the
-- rank it is, and a material slot on a recipe or order shows every rank.
local QUALITY_ICON = "|A:Professions%-ChatIcon%-Quality.-|a"

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

-- What a link's item is filed under: "q:<name>" for an item with a quality,
-- or its itemID. Also returns the quality icon and tier.
local function groupOf(link, id)
	local icon = link:match(QUALITY_ICON)
	if not icon then return id end
	return "q:" .. ns.PlainName(link), icon, tonumber(icon:match("Tier(%d+)")) or 0
end

-- group -> { [owner .. tier] = { owner, icon, tier, bags, bank } }, and
-- itemID -> group and tier for the items saved. Built from the saved data the
-- first time a tooltip needs it after the data changed.
local index, groupOfID, tierOfID

-- Saved items' keys start with their link's "item:<id>:".
local function addItems(items, owner, where)
	for _, item in ipairs(items or {}) do
		local id = tonumber(item.key:match("^item:(%d+)"))
		if id then
			local group, icon, tier = groupOf(item.link, id)
			groupOfID[id], tierOfID[id] = group, tier
			local entries = index[group]
			if not entries then
				entries = {}
				index[group] = entries
			end
			local key = owner .. "#" .. (tier or 0)
			local entry = entries[key]
			if not entry then
				entry = { owner = owner, icon = icon, tier = tier or 0, bags = 0, bank = 0 }
				entries[key] = entry
			end
			entry[where] = entry[where] + item.count
		end
	end
end

local function buildIndex()
	index, groupOfID, tierOfID = {}, {}, {}
	for charKey, c in pairs(ns.db.chars) do
		addItems(c.bags, charKey, "bags")
		addItems(c.bank, charKey, "bank")
	end
	if ns.HAS_WARBAND then addItems(ns.db.warband.items, WARBAND, "bank") end
end

-- The group and rank of the hovered item: from the saved data, or from its
-- link when you don't own that rank. The rank is nil for items without ranks.
local function hoveredGroup(id)
	if groupOfID[id] then return groupOfID[id], tierOfID[id] end
	local ok, name, link = pcall(GetItemInfo, id)
	if not (ok and link) then return id end
	local group, _, tier = groupOf(link, id)
	if group ~= id then return group, tier end
	-- A material's link may come without its quality icon; ask for its rank.
	local quality = C_TradeSkillUI and C_TradeSkillUI.GetItemReagentQualityByItemInfo
		and C_TradeSkillUI.GetItemReagentQualityByItemInfo(id)
	if quality and quality > 0 and name then return "q:" .. name, quality end
	return id
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

-- "Name", plus the quality icon when the item has qualities.
local function withIcon(name, entry)
	return entry.icon and (name .. " " .. entry.icon) or name
end

-- `allRanks`: show every rank of the item, not just the hovered one. Returns
-- true when lines were added.
local function addLines(tooltip, id, allRanks)
	if not index then buildIndex() end
	local group, tier = hoveredGroup(id)
	local entries = index[group]
	if not entries then return end
	if tier and not allRanks then
		local only = {}
		for key, entry in pairs(entries) do
			if entry.tier == tier then only[key] = entry end
		end
		if not next(only) then return end
		entries = only
	end

	-- One row per character and quality. This character first, then whoever
	-- has the most; the warband bank last. Rank 1 first, then rank 2, within each.
	local rows, ownerTotal = {}, {}
	for _, entry in pairs(entries) do
		rows[#rows + 1] = entry
		ownerTotal[entry.owner] = (ownerTotal[entry.owner] or 0) + entry.bags + entry.bank
	end
	local function rank(owner)
		return owner == ns.charKey and 0 or owner == WARBAND and 2 or 1
	end
	table.sort(rows, function(a, b)
		if a.owner ~= b.owner then
			if rank(a.owner) ~= rank(b.owner) then return rank(a.owner) < rank(b.owner) end
			if ownerTotal[a.owner] ~= ownerTotal[b.owner] then return ownerTotal[a.owner] > ownerTotal[b.owner] end
			return a.owner < b.owner
		end
		return a.tier < b.tier
	end)

	-- A heading, so it's clear these lines are Hoard Value's, with a blank line
	-- above and/or below them as the player picked.
	local spacing = ns.db.tooltipSpacing
	if spacing == "above" or spacing == "both" then tooltip:AddLine(" ") end
	tooltip:AddLine("Hoard Info", 1, 0.82, 0)

	local total = 0
	for _, row in ipairs(rows) do
		if row.owner == WARBAND then
			tooltip:AddDoubleLine(withIcon("Warband bank", row), number(row.bank) .. " " .. WARBAND_ICON,
				0, 0.8, 1, 1, 1, 1)
		else
			local name = charName(ns.db.chars[row.owner] or {}, row.owner)
			tooltip:AddDoubleLine(withIcon(name, row), placeText(row), 1, 1, 1, 1, 1, 1)
		end
		total = total + row.bags + row.bank
	end
	if #rows > 1 then
		tooltip:AddDoubleLine("Total", number(total), 1, 0.82, 0, 1, 1, 1)
	end
	if spacing == "below" or spacing == "both" then tooltip:AddLine(" ") end
	return true
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

-- A material slot on a recipe, crafting order or customer order stands for
-- every rank of its material, whichever rank's tooltip it shows.
local function isMaterialSlot(tooltip)
	local ok, frame = pcall(tooltip.GetOwner, tooltip)
	if not ok then return false end
	for _ = 1, 3 do
		if type(frame) ~= "table" then return false end
		if frame.GetReagentSlotSchematic then return true end
		frame = frame.GetParent and frame:GetParent()
	end
	return false
end

-- The Hoard Info lines for one item, for the report window's own tooltips.
-- They show even with the tooltip option off. Returns true when lines were added.
function ns.AddHoardInfo(tooltip, id)
	return id and addLines(tooltip, id, false) or false
end

-- Returns true when lines were added.
local function onItem(tooltip, id)
	if not (ns.db and ns.db.tooltipCounts) or ns.ownItemTooltip then return end
	if issecretvalue and issecretvalue(id) then return end
	if type(id) ~= "number" or not tooltip.AddDoubleLine then return end
	watch(tooltip)
	if done[tooltip] == id then return end
	done[tooltip] = id
	addLines(tooltip, id, isMaterialSlot(tooltip))
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


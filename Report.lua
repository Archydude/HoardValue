-- Hoard Value: reports
-- Totals and item lists built from the saved data. Pure data: no text for the
-- screen, which UI.lua formats from these fields.

local _, ns = ...
local format = string.format

function ns.WarbandCounted()
	return ns.HAS_WARBAND and ns.db.countWarband
end

local function newReport()
	return {
		sections = { gold = 0, bags = 0, bank = 0, warband = 0 },
		total = 0,
		rows = {},        -- one per item, see addItems
		byKey = {},
		boundSkipped = 0, -- bound items left out
		unpriced = 0,     -- items worth nothing
		zeroValue = 0,    -- rows worth nothing (hidden unless "List items with no value")
		ahPriced = 0,     -- items with an auction price (0: the price addon has no data)
	}
end

-- Adds a list of saved items to the report, merging the same item from
-- different places into one row.
local function addItems(r, items, where, section)
	for _, item in ipairs(items or {}) do
		-- Saved before warbound items counted as bound (1.0.1 and older); the
		-- next scan of that bag saves it properly.
		if not item.bound and ns.AccountBound(item.link) then item.bound = true end
		if item.bound and not ns.db.countBound then
			r.boundSkipped = r.boundSkipped + item.count
		else
			local unit, how = ns.UnitPrice(item)
			local value = unit and unit * item.count or 0
			r.sections[section] = r.sections[section] + value

			local row = r.byKey[item.key]
			if not row then
				row = {
					kind = "item", link = item.link, icon = item.icon, bound = item.bound,
					name = ns.ItemName(item.link) or "", unit = unit, how = how, -- "": still loading
					count = 0, value = 0, places = {}, placeIndex = {},
				}
				r.byKey[item.key] = row
				r.rows[#r.rows + 1] = row
				if not unit then r.unpriced = r.unpriced + 1 end
				if how == "ah" then r.ahPriced = r.ahPriced + 1 end
			end
			row.count = row.count + item.count
			row.value = row.value + value
			local place = row.placeIndex[where]
			if not place then
				place = { where = where, count = 0 }
				row.placeIndex[where] = place
				row.places[#row.places + 1] = place
			end
			place.count = place.count + item.count
		end
	end
end

local function addCharacter(r, c, prefix)
	r.sections.gold = r.sections.gold + (c.money or 0)
	addItems(r, c.bags, prefix .. "Bags", "bags")
	addItems(r, c.bank, prefix .. "Bank", "bank")
end

local function addWarband(r)
	r.sections.warband = r.sections.warband + (ns.db.warband.money or 0)
	addItems(r, ns.db.warband.items, "Warband bank", "warband")
end

-- Where an item is, short enough for one column: "Bags, Bank" or "5 places".
local function placesText(places)
	if #places > 2 then return format("%d places", #places) end
	local names = {}
	for i, place in ipairs(places) do names[i] = place.where end
	return table.concat(names, ", ")
end

local function finish(r)
	local s = r.sections
	r.total = s.gold + s.bags + s.bank + s.warband
	for _, row in ipairs(r.rows) do
		row.where = placesText(row.places)
		row.search = (row.name .. "\n" .. row.where):lower()
		if row.value <= 0 then r.zeroValue = r.zeroValue + 1 end
	end
	return r
end

-- scope: "char" (this character) or "account" (every character + warband bank)
function ns.BuildReport(scope)
	local r = newReport()
	if scope == "char" then
		addCharacter(r, ns.CharData(), "")
	else
		for _, c in pairs(ns.db.chars) do addCharacter(r, c, (c.name or "?") .. ": ") end
		if ns.WarbandCounted() then addWarband(r) end
	end
	return finish(r)
end

-- One row per character, plus the warband bank when it counts.
function ns.BuildCharacterRows()
	local rows = {}
	for key, c in pairs(ns.db.chars) do
		local r = newReport()
		addCharacter(r, c, "")
		local gold = c.money or 0
		local items = r.sections.bags + r.sections.bank
		rows[#rows + 1] = {
			kind = "char", charKey = key, char = c,
			name = (c.name or key):lower(), search = ((c.name or "") .. "\n" .. (c.realm or "")):lower(),
			gold = gold, bags = r.sections.bags, bank = r.sections.bank, items = items,
			value = gold + items, scanned = c.bankScanned,
		}
	end

	if ns.WarbandCounted() then
		local r = newReport()
		addWarband(r)
		local warband = ns.db.warband
		local gold = warband.money or 0
		local items = r.sections.warband - gold
		rows[#rows + 1] = {
			kind = "warband", name = "warband bank", search = "warband bank",
			gold = gold, items = items, value = gold + items, scanned = warband.scanned,
		}
	end
	return rows
end

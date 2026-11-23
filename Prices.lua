-- Hoard Value: prices
-- What one of an item is worth: its auction price from TSM, Auctionator or
-- Craftonomics, or
-- what a vendor pays, whichever is better. Bound and grey items only count at
-- vendor price.

local ADDON_NAME, ns = ...

local AH_CUT = 0.05

-- The lower of market value and the lowest auction, as a TSM price.
ns.TSM_LOWER = "min(dbmarket, dbminbuyout)"

---------------------------------------------------------------------------
-- Price addons
---------------------------------------------------------------------------

-- Whether the Price addon option lets this addon's prices in.
local function wants(provider)
	return ns.db.provider == "auto" or ns.db.provider == provider
end

function ns.TSMAvailable()
	return wants("tsm") and TSM_API ~= nil and TSM_API.GetCustomPriceValue ~= nil
end

function ns.AuctionatorAPI()
	if not wants("auctionator") then return nil end
	return Auctionator and Auctionator.API and Auctionator.API.v1
end

-- Craftonomics prices items the way its own options say: from TSM, TSM prices
-- saved for alts, Auctionator or its own scan of the auction house.
function ns.CraftonomicsAPI()
	if not wants("craftonomics") then return nil end
	local api = CraftonomicsAPI
	return type(api) == "table" and type(api.GetAuctionPrice) == "function" and api or nil
end

-- Whether any price addon gives auction prices.
function ns.HasAuctionPrices()
	return ns.TSMAvailable() or ns.AuctionatorAPI() ~= nil or ns.CraftonomicsAPI() ~= nil
end

local function tsmValue(source, itemString)
	local ok, value = pcall(TSM_API.GetCustomPriceValue, source, itemString)
	if ok and value and value > 0 then return value end
end

local function auctionatorValue(fn, arg)
	if not fn then return end
	local ok, value = pcall(fn, ADDON_NAME, arg)
	if ok and value and value > 0 then return value end
end

-- What one of this item goes for on the auction house.
local function auctionPrice(link)
	local db = ns.db
	if ns.TSMAvailable() then
		local ok, itemString = pcall(TSM_API.ToItemString, link)
		if ok and itemString then
			local value = tsmValue(db.tsmSource, itemString)
			if db.realistic then
				-- If it's listed cheaper right now, that's what you'd have to match.
				local lowest = tsmValue("dbminbuyout", itemString)
				if lowest and (not value or lowest < value) then value = lowest end
			end
			if value then return value end
		end
	end
	local api = ns.AuctionatorAPI()
	if api then
		local value = auctionatorValue(api.GetAuctionPriceByItemLink, link)
		if value then return value end
		local id = ns.ItemID(link)
		value = id and auctionatorValue(api.GetAuctionPriceByItemID, id)
		if value then return value end
	end
	local craftonomics = ns.CraftonomicsAPI()
	if craftonomics then
		local ok, value = pcall(craftonomics.GetAuctionPrice, link)
		if ok and type(value) == "number" and value > 0 then return value end
	end
end

function ns.SourceLabel()
	local db = ns.db
	local label
	if ns.TSMAvailable() then
		label = "TSM (" .. (db.tsmSource == ns.TSM_LOWER and "lower of dbmarket, dbminbuyout" or db.tsmSource) .. ")"
	elseif ns.AuctionatorAPI() then
		label = "Auctionator"
	elseif ns.CraftonomicsAPI() then
		label = "Craftonomics"
	elseif db.provider == "tsm" then
		return "|cffff6666TSM is not loaded|r"
	elseif db.provider == "auctionator" then
		return "|cffff6666Auctionator is not loaded|r"
	elseif db.provider == "craftonomics" then
		return "|cffff6666Craftonomics is not loaded|r"
	else
		return "|cffff6666vendor only - install TSM or Auctionator|r"
	end
	return label .. (db.realistic and ", realistic" or "")
end

---------------------------------------------------------------------------
-- Item prices
---------------------------------------------------------------------------

-- Prices by item key, so building a report asks the price addon about each item
-- once. Kept until something that changes prices happens: a setting changes, a
-- missing vendor price loads, or the window opens (fresh market data).
local cache = {}

function ns.InvalidatePrices()
	wipe(cache)
end

-- Price of one item and where it comes from ("ah" | "vendor"), or nil when
-- it's worth nothing. Takes the better of the auction and vendor price.
function ns.UnitPrice(item)
	local cached = cache[item.key]
	if cached then return cached.price, cached.how end

	local vendor = item.vendor
	if vendor == nil then
		vendor = ns.VendorPrice(item.link)
		-- Not loaded yet; "ItemInfoLoaded" below re-prices when it is.
		if vendor == nil then ns.RequestItemInfo(item.link) end
	end
	if vendor and vendor <= 0 then vendor = nil end

	local price, how
	if item.bound or ns.IsPoor(item.link) then
		-- Can't go on the auction house, or grey junk: worth what a vendor pays.
		price, how = vendor, vendor and "vendor"
	else
		local ah = auctionPrice(item.link)
		if ah and ns.db.realistic then ah = ah * (1 - AH_CUT) end
		if ah and (not vendor or ah >= vendor) then
			price, how = ah, "ah"
		elseif vendor then
			price, how = vendor, "vendor"
		end
	end
	cache[item.key] = { price = price, how = how }
	return price, how
end

ns.Listen("SettingChanged", ns.InvalidatePrices)
ns.Listen("ItemInfoLoaded", ns.InvalidatePrices)

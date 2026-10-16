-- Hoard Value: scanning
-- Reads your bags (any time) and your banks (only while one is open) into the
-- saved data, then fires "DataChanged".

local _, ns = ...
local format = string.format

---------------------------------------------------------------------------
-- Bag and bank numbers
---------------------------------------------------------------------------

-- Classic clients (MoP, TBC, Forever, Era) can carry Retail's Enum.BagIndex,
-- with warband and bank-tab entries and Retail's numbering, even though their
-- bags work the old way. So only Retail uses the enum; Classic uses the client's
-- own NUM_BAG_SLOTS / NUM_BANKBAGSLOTS, which are always right for that client.
local BagIndex = ns.IS_RETAIL and Enum.BagIndex or {}
local NUM_BAGS = NUM_BAG_SLOTS or 4

local function bagRange(list, prefix, from, to)
	for i = from, to do
		local index = BagIndex[prefix .. i]
		if index then list[#list + 1] = index end
	end
	return list
end

local BAGS = { BagIndex.Backpack or 0 }
for i = 1, NUM_BAGS do BAGS[#BAGS + 1] = BagIndex["Bag_" .. i] or i end
if BagIndex.ReagentBag then BAGS[#BAGS + 1] = BagIndex.ReagentBag end

-- Retail's bank has tabs since 11.2; Classic banks have the main slots plus
-- bank bags, numbered right after your bags.
local CHAR_BANK = bagRange({}, "CharacterBankTab_", 1, 10)
if #CHAR_BANK == 0 then
	CHAR_BANK[1] = BagIndex.Bank or BANK_CONTAINER or -1
	for i = 1, NUM_BANKBAGSLOTS or 6 do
		CHAR_BANK[#CHAR_BANK + 1] = BagIndex["BankBag_" .. i] or (NUM_BAGS + i)
	end
	if BagIndex.Reagentbank then CHAR_BANK[#CHAR_BANK + 1] = BagIndex.Reagentbank end
end

-- Retail only; everything warband-related is hidden when this is false.
local WARBAND_BANK = bagRange({}, "AccountBankTab_", 1, 10)
ns.HAS_WARBAND = ns.IS_RETAIL and #WARBAND_BANK > 0

---------------------------------------------------------------------------
-- Items
---------------------------------------------------------------------------

-- Item functions moved into C_Item; older clients may only have the globals.
local GetItemInfo = C_Item.GetItemInfo or GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant or GetItemInfoInstant

function ns.ItemID(link)
	local ok, id = pcall(GetItemInfoInstant, link)
	return ok and id or nil
end

-- Item details (names, vendor prices) load on demand. Ask for an item, and fire
-- "ItemInfoLoaded" once what we asked for has arrived.
local waitingForItemInfo = false

function ns.RequestItemInfo(link)
	local id = ns.ItemID(link)
	if id then
		C_Item.RequestLoadItemDataByID(id)
		waitingForItemInfo = true
	end
end

-- Item info arrives one item at a time; announce it once it settles.
local itemInfoArrived = ns.Debounce(1, function()
	waitingForItemInfo = false
	ns.Fire("ItemInfoLoaded")
end)

ns.On("GET_ITEM_INFO_RECEIVED", function()
	if waitingForItemInfo then itemInfoArrived() end
end)

-- Vendor sell price (GetItemInfo's 11th value), or nil when the item isn't
-- loaded yet or can't be sold to a vendor at all (battle pet cages).
function ns.VendorPrice(link)
	local ok, _, _, _, _, _, _, _, _, _, _, price = pcall(GetItemInfo, link)
	return ok and price or nil
end

-- True for a Poor (grey) quality item. Read from the link's color, so saved
-- links from other characters work without the item being loaded. Battle pets
-- are left out: a grey pet still sells on the auction house.
function ns.IsPoor(link)
	if not link:find("|Hitem:") then return false end
	local quality = link:match("^|cnIQ(%d+):")             -- Retail: "|cnIQ0:"
	if quality then return quality == "0" end
	if link:find("^|cff9d9d9d") then return true end       -- Classic: grey color
	local ok, _, _, q = pcall(GetItemInfo, link)
	return ok and q == 0
end

-- An item's name. A link saved before the item had loaded has an empty name
-- ("[]"), so ask the game then; nil until it has loaded.
function ns.ItemName(link)
	local name = ns.PlainName(link)
	if name ~= "" then return name end
	local ok, loaded = pcall(GetItemInfo, link)
	if ok and loaded then return loaded end
	ns.RequestItemInfo(link)
end

-- The same item on two characters gets a different link (item level, spec and
-- unique id are baked in). Blank those out so they count as one item.
local function itemKey(link, bound)
	local s = link:match("|H(.-)|h") or link
	local parts = { strsplit(":", s) }
	if parts[1] == "item" and #parts >= 11 then
		-- item:id:enchant:gem1:gem2:gem3:gem4:suffix:unique:linkLevel:spec:...
		parts[9], parts[10], parts[11] = "", "", ""
		s = table.concat(parts, ":")
	elseif parts[1] == "battlepet" and #parts >= 8 then
		-- battlepet:species:level:quality:health:power:speed:petGUID
		parts[8] = ""
		s = table.concat(parts, ":")
	end
	return bound and (s .. "#bound") or s
end

-- How an item binds (GetItemInfo's 14th value). These never go on the auction
-- house: Warbound, Battle.net account bound and Warbound until equipped. The
-- slot's isBound doesn't cover them; it's only true once soulbound.
local ItemBind = Enum.ItemBind or {}
local ACCOUNT_BIND = {
	[ItemBind.ToWoWAccount or 7] = true,
	[ItemBind.ToBnetAccount or 8] = true,
	[ItemBind.ToBnetAccountUntilEquipped or 9] = true,
}

-- True for an item that is always warbound / account bound. Works from a saved
-- link, so other characters' items count too; nil until the item has loaded.
function ns.AccountBound(link)
	local ok, _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = pcall(GetItemInfo, link)
	if ok and bindType then return ACCOUNT_BIND[bindType] or false end
end

-- Binding lines on a tooltip that mean this copy can't be sold, even when the
-- same item can also drop tradeable (a BoE world drop that comes Warbound until
-- equipped from a delve, say).
local BOUND_LINES = {}
for _, name in ipairs({ "ITEM_SOULBOUND", "ITEM_BIND_QUEST",
	"ITEM_ACCOUNTBOUND", "ITEM_BNETACCOUNTBOUND", "ITEM_ACCOUNTBOUND_UNTIL_EQUIP",
	"ITEM_BIND_TO_ACCOUNT", "ITEM_BIND_TO_BNETACCOUNT", "ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP" }) do
	local text = _G[name]
	if text then BOUND_LINES[text] = true end
end

local function tooltipSaysBound(bag, slot)
	if not (C_TooltipInfo and C_TooltipInfo.GetBagItem) then return false end
	local ok, data = pcall(C_TooltipInfo.GetBagItem, bag, slot)
	local lines = ok and data and data.lines
	if not lines then return false end
	-- The binding line sits just under the name, item level and tags.
	for i = 2, math.min(#lines, 6) do
		if BOUND_LINES[lines[i].leftText] then return true end
	end
	return false
end

local function isBound(info, bag, slot, link)
	if info.isBound then return true end
	if ns.AccountBound(link) or tooltipSaysBound(bag, slot) then return true end
	-- Not every client's info has isBound; ask about the slot instead.
	if info.isBound == nil and C_Item.IsBound and ItemLocation then
		local ok, bound = pcall(C_Item.IsBound, ItemLocation:CreateFromBagAndSlot(bag, slot))
		return ok and bound or false
	end
	return false
end

-- Everything in these bags, one entry per item (see the saved data layout in
-- Core.lua). Also returns the number of slots, which is 0 when the bags aren't
-- loaded.
local function scanContainers(bags)
	local list, byKey, slots = {}, {}, 0
	for _, bag in ipairs(bags) do
		local numSlots = C_Container.GetContainerNumSlots(bag) or 0
		slots = slots + numSlots
		for slot = 1, numSlots do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			local link = info and info.hyperlink
			if link then
				local bound = isBound(info, bag, slot, link)
				local key = itemKey(link, bound)
				local item = byKey[key]
				if not item then
					-- The vendor price is saved so other characters' items can be
					-- priced without the item being in the game's cache.
					item = {
						key = key, link = link, icon = info.iconFileID, count = 0, bound = bound or nil,
						vendor = info.hasNoValue and 0 or ns.VendorPrice(link),
					}
					byKey[key] = item
					list[#list + 1] = item
				end
				item.count = item.count + (info.stackCount or 1)
			end
		end
	end
	return list, slots
end

---------------------------------------------------------------------------
-- Saved snapshots
---------------------------------------------------------------------------

-- WoW: Forever characters have a first and last name, which UnitName returns
-- as two values (elsewhere the second is the realm, always nil for "player").
function ns.PlayerName()
	local first, last = UnitName("player")
	if last and last ~= "" then return first .. " " .. last end
	return first
end

function ns.CharData()
	local chars = ns.db.chars
	local c = chars[ns.charKey]
	if not c then
		c = {}
		chars[ns.charKey] = c
	end
	return c
end

local function scanWarbandMoney()
	if not (ns.HAS_WARBAND and C_Bank and C_Bank.FetchDepositedMoney and Enum.BankType) then return end
	local ok, money = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
	if ok and type(money) == "number" then ns.db.warband.money = money end
end

local function scanBags()
	local c = ns.CharData()
	c.name = ns.PlayerName()
	c.realm = GetRealmName()
	c.class = select(2, UnitClass("player"))
	c.money = GetMoney()
	c.bags = scanContainers(BAGS)
	c.updated = time()
end

-- Only possible while the bank is open. `warbandOnly`: opened somewhere that
-- gives the warband bank but not your own (e.g. a warband bank distance item).
local function scanBank(warbandOnly)
	if not warbandOnly then
		local items, slots = scanContainers(CHAR_BANK)
		-- No slots means the bank isn't loaded yet; keep the last snapshot.
		if slots > 0 then
			local c = ns.CharData()
			c.bank = items
			c.bankScanned = time()
		end
	end
	if ns.HAS_WARBAND then
		local items, slots = scanContainers(WARBAND_BANK)
		if slots > 0 then
			ns.db.warband.items = items
			ns.db.warband.scanned = time()
		end
	end
	scanWarbandMoney()
end

-- Scans your bags now, e.g. when the window opens.
function ns.ScanBags()
	if not ns.charKey then return end
	scanBags()
	ns.Fire("DataChanged")
end

function ns.ForgetCharacter(key)
	ns.db.chars[key] = nil
	ns.Fire("DataChanged")
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local bankMode -- nil | "full" | "warband": which bank is open right now

local function bankOpened(mode)
	bankMode = mode
	-- The bank's contents arrive just after it opens.
	C_Timer.After(0.5, function()
		if not bankMode then return end
		scanBank(bankMode == "warband")
		ns.Fire("DataChanged")
	end)
end

-- Bags change a slot at a time; scan once things settle.
local rescan = ns.Debounce(1, function()
	scanBags()
	if bankMode then scanBank(bankMode == "warband") end
	ns.Fire("DataChanged")
end)

ns.On("PLAYER_LOGIN", function()
	local realm = "-" .. (GetNormalizedRealmName() or GetRealmName():gsub("[%s%-]", ""))
	ns.charKey = ns.PlayerName() .. realm
	-- Older versions saved Forever characters under their first name only.
	local chars, oldKey = ns.db.chars, UnitName("player") .. realm
	if oldKey ~= ns.charKey and chars[oldKey] and not chars[ns.charKey] then
		chars[ns.charKey], chars[oldKey] = chars[oldKey], nil
	end
	scanBags()
	scanWarbandMoney()
	ns.Fire("DataChanged")
end)

ns.On("BAG_UPDATE_DELAYED", function()
	if ns.charKey then rescan() end
end)

ns.On("PLAYER_MONEY", function()
	if not ns.charKey then return end
	ns.CharData().money = GetMoney()
	ns.Fire("DataChanged")
end)

ns.On("ACCOUNT_MONEY", function()
	scanWarbandMoney()
	ns.Fire("DataChanged")
end)

-- Retail tells us which kind of banker opened; Classic only has BANKFRAME_*.
ns.On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind)
	local types = Enum.PlayerInteractionType or {}
	if types.Banker and kind == types.Banker then
		bankOpened("full")
	elseif types.AccountBanker and kind == types.AccountBanker then
		bankOpened("warband")
	end
end)

ns.On("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind)
	local types = Enum.PlayerInteractionType or {}
	if (types.Banker and kind == types.Banker) or (types.AccountBanker and kind == types.AccountBanker) then
		bankMode = nil
	end
end)

ns.On("BANKFRAME_OPENED", function()
	if not bankMode then bankOpened("full") end
end)

ns.On("BANKFRAME_CLOSED", function()
	bankMode = nil
end)

---------------------------------------------------------------------------
-- /hoard debug
---------------------------------------------------------------------------

-- What the bag scan sees, bag by bag, and what's saved.
function ns.PrintDebug()
	local out = {}
	for _, bag in ipairs(BAGS) do
		local slots, filled, linked = C_Container.GetContainerNumSlots(bag) or 0, 0, 0
		for slot = 1, slots do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info then
				filled = filled + 1
				if info.hyperlink then linked = linked + 1 end
			end
		end
		out[#out + 1] = format("%d: %d slots, %d items, %d links", bag, slots, filled, linked)
	end
	print("|cffffd100Hoard Value|r bags - " .. table.concat(out, " | "))
	local c = ns.CharData()
	print(format("|cffffd100Hoard Value|r saved: %d bag items, %d bank items, %d warband items, prices: %s",
		#(c.bags or {}), #(c.bank or {}), #(ns.db.warband.items or {}), ns.SourceLabel()))
end

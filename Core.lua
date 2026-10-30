-- Hoard Value
-- How much a character, or the whole account, is worth in gold: the gold you
-- carry plus everything in your bags, bank and warband bank, priced with TSM or
-- Auctionator. Works on Retail, MoP Classic, TBC Anniversary, WoW Forever and
-- Classic Era (incl. SoD); versions without a warband bank simply don't show it.
--
-- Files, in load order (see the .toc):
--   Core.lua     namespace, saved data, events and messages, formatting helpers
--   Scan.lua     reads bags and banks into the saved data
--   Prices.lua   what one item is worth (TSM, Auctionator, vendor)
--   Report.lua   totals and item lists built from the saved data
--   Options.lua  Esc > Options > AddOns > Hoard Value
--   Minimap.lua  minimap button and addon compartment entry
--   Tooltip.lua  who has an item, on item tooltips
--   UI.lua       the report window
--
-- The files share the addon's private table `ns`. They talk through messages
-- (ns.Fire / ns.Listen) rather than reaching into each other:
--   "Loaded"                saved data is ready
--   "DataChanged"           bags, banks, gold or the character list changed
--   "ItemInfoLoaded"        item names or vendor prices we asked the game for arrived
--   "SettingChanged", key   an option changed

local ADDON_NAME, ns = ...
local format = string.format

ns.ADDON_NAME = ADDON_NAME

---------------------------------------------------------------------------
-- Game version
---------------------------------------------------------------------------

ns.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ns.TOC_VERSION = select(4, GetBuildInfo()) -- e.g. 11509 Era, 16001 Forever, 20506 TBC, 50504 MoP
-- Forever looks like Retail; Era, TBC and MoP Classic keep the classic look.
ns.MODERN_UI = ns.IS_RETAIL or (ns.TOC_VERSION >= 16000 and ns.TOC_VERSION < 20000)

---------------------------------------------------------------------------
-- Events and messages
---------------------------------------------------------------------------

-- Runs a handler so that an error in it is reported but doesn't stop the
-- handlers after it.
local call = securecallfunction or function(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then geterrorhandler()(err) end
end

local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

-- ns.On(event, handler): handler(event, ...) runs on a game event. Several
-- files can listen to the same event. Events this game version doesn't have
-- are skipped.
function ns.On(event, handler)
	if not eventHandlers[event] then
		if not pcall(eventFrame.RegisterEvent, eventFrame, event) then return end
		eventHandlers[event] = {}
	end
	table.insert(eventHandlers[event], handler)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	for _, handler in ipairs(eventHandlers[event]) do call(handler, event, ...) end
end)

local listeners = {}

-- ns.Listen(message, handler): handler(message, ...) runs on ns.Fire(message, ...).
function ns.Listen(message, handler)
	listeners[message] = listeners[message] or {}
	table.insert(listeners[message], handler)
end

function ns.Fire(message, ...)
	for _, handler in ipairs(listeners[message] or {}) do call(handler, message, ...) end
end

-- A function that runs `fn` once, `delay` seconds after the first of any number
-- of calls. Turns bursts (a bag update per slot, a keystroke per letter) into
-- one piece of work.
function ns.Debounce(delay, fn)
	local queued = false
	return function()
		if queued then return end
		queued = true
		C_Timer.After(delay, function()
			queued = false
			fn()
		end)
	end
end

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------

-- HoardValueDB keeps the settings below at its top level (the options page
-- binds to them by key), plus:
--   version              layout version, see migrate()
--   chars["Name-Realm"]  { name, realm, class, money, updated, bags, bank, bankScanned }
--   warband              { money, items, scanned }
--   pos                  window position
--   minimapIcon          minimap button position, kept by LibDBIcon
-- bags, bank and items are lists of { key, link, icon, count, bound, vendor }.
local DB_VERSION = 2

-- Where the minimap button starts, in degrees around the minimap.
local MINIMAP_START = 200

ns.DEFAULTS = {
	provider = "auto",     -- "auto" | "tsm" | "auctionator"
	tsmSource = "dbmarket",
	realistic = false,     -- lower of market / lowest auction, minus the AH cut
	countBound = false,    -- soulbound / warbound items, at vendor price
	countWarband = true,   -- warband bank in the account total
	showZero = false,      -- list items that are worth nothing
	listAll = false,       -- list everything, bound items too, even if not counted
	precision = "gold",    -- smallest coin shown: "copper" | "silver" | "gold"
	minimap = true,
	tooltipCounts = true,  -- who has an item, on its tooltip
	tooltipSpacing = "above", -- blank line around those lines: "above" | "below" | "both" | "none"
	tab = 1,
}

-- Brings saved data from older versions up to date. Version 1 is the first
-- release; when the layout changes, raise DB_VERSION and add a step here:
--   if db.version < 3 then ... end
local function migrate(db)
	local version = db.version or 0
	if version < 2 then
		-- 1.1.0 and older drew their own minimap button and kept its angle here.
		db.minimapIcon = db.minimapIcon or { minimapPos = db.minimapAngle or MINIMAP_START }
		db.minimapAngle = nil
	end
	db.version = DB_VERSION
end

ns.On("ADDON_LOADED", function(_, name)
	if name ~= ADDON_NAME then return end
	HoardValueDB = HoardValueDB or {}
	local db = HoardValueDB
	for key, value in pairs(ns.DEFAULTS) do
		if db[key] == nil then db[key] = value end
	end
	db.chars = db.chars or {}
	db.warband = db.warband or {}
	migrate(db)
	ns.db = db
	ns.Fire("Loaded")
end)

---------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------

function ns.Money(copper)
	copper = math.floor(copper + 0.5)
	local amount = math.abs(copper)
	-- Round to the chosen coin. Amounts smaller than that coin keep the next one
	-- down, so they never show as zero.
	local precision = ns.db.precision
	local unit = (precision == "gold" and amount >= 10000 and 10000)
		or (precision ~= "copper" and amount >= 100 and 100)
	if unit then amount = math.floor(amount / unit + 0.5) * unit end
	local text = GetMoneyString(amount, true)
	return copper < 0 and ("-" .. text) or text
end

function ns.Ago(t)
	local s = time() - t
	if s < 60 then return "just now" end
	if s < 3600 then return format("%d min ago", s / 60) end
	if s < 86400 then return format("%d h ago", s / 3600) end
	local days = math.floor(s / 86400)
	return format("%d day%s ago", days, days == 1 and "" or "s")
end

function ns.ClassColored(c)
	local color = c.class and RAID_CLASS_COLORS[c.class]
	local name = c.name or "?"
	return color and ("|c" .. color.colorStr .. name .. "|r") or name
end

-- Item name without brackets, color codes or quality icons, for sorting and search.
function ns.PlainName(link)
	local name = link:match("|h%[(.-)%]|h") or link
	name = name:gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	return strtrim(name)
end

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------

SLASH_HOARDVALUE1 = "/hoard"
SLASH_HOARDVALUE2 = "/hoardvalue"
SlashCmdList.HOARDVALUE = function(msg)
	msg = strtrim(msg or ""):lower()
	if msg == "options" or msg == "config" then
		ns.OpenOptions()
	elseif msg == "minimap" then
		ns.SetSetting("minimap", not ns.db.minimap)
		print("|cffffd100Hoard Value|r minimap button " .. (ns.db.minimap and "shown."
			or "hidden. Type |cffffff00/hoard minimap|r to bring it back."))
	elseif msg == "debug" then
		ns.PrintDebug()
	else
		ns.ToggleWindow()
	end
end

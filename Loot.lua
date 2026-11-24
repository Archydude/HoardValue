-- Hoard Value: what picked-up items are worth
-- Prints a chat line with an item's value when you loot it or are handed it
-- (quest rewards, items pushed into your bags). Priced like the window does.

local _, ns = ...
local format = string.format

local RETRIES = 3       -- times to wait for an item that hasn't loaded yet
local RETRY_DELAY = 0.5 -- seconds between them

-- The game's own lines for items you get, e.g. "You receive loot: %s." and "%sx%d.".
local SELF_LINES = {}
local function addLootPatterns(names, multiple)
	for _, name in ipairs(names) do
		local text = _G[name]
		if type(text) == "string" then
			local countFirst = false
			if multiple then
				local itemPos = text:find("%%%d*%%?%$?s") or math.huge
				local countPos = text:find("%%%d*%%?%$?d") or math.huge
				countFirst = countPos < itemPos
			end
			-- Escape the pattern characters, then turn %s/%1$s and %d/%2$d into captures.
			local pattern = text:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
				:gsub("%%%d*%%?%$?s", "(.+)")
			if multiple then
				pattern = pattern:gsub("%%%d*%%?%$?d", "(%%d+)")
			end
			SELF_LINES[#SELF_LINES + 1] = { pattern = "^" .. pattern .. "$", multiple = multiple, countFirst = countFirst }
		end
	end
end
addLootPatterns({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE" }, true)
addLootPatterns({ "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_BONUS_ROLL_SELF" }, false)

-- The item link in a loot line and how many: "...|h[Name]|h|rx3."
local function parse(text)
	for _, entry in ipairs(SELF_LINES) do
		local first, second = text:match(entry.pattern)
		if first then
			local itemText = entry.multiple and entry.countFirst and second or first
			local count = entry.multiple and tonumber(entry.countFirst and first or second) or nil
			local from, to = itemText:find("|c[^|]+|H.-|h.-|h|r")
			if from then
				local link = itemText:sub(from, to)
				if not count then count = tonumber(itemText:match("^x(%d+)", to + 1)) or 1 end
				return link, count
			end
		end
	end
end

local function announce(link, count, triesLeft)
	local bound = ns.BoundWhenLooted(link)
	if bound == nil and triesLeft > 0 then
		-- Not loaded yet, so we can't tell if it can be sold; ask and try again.
		ns.RequestItemInfo(link)
		C_Timer.After(RETRY_DELAY, function() announce(link, count, triesLeft - 1) end)
		return
	end
	bound = bound or false
	-- Bound items follow "Count soulbound items", like the totals.
	if bound and not ns.db.countBound then return end

	local unit, how = ns.UnitPrice({ key = ns.ItemKey(link, bound), link = link, bound = bound })
	if not unit then return end
	local value = unit * count
	if value < (ns.db.lootValueMin or 0) * 10000 then return end

	local text = ns.Money(value)
	if count > 1 then text = text .. format(" (%s each)", ns.Money(unit)) end
	if how == "vendor" then text = text .. " |cff999999vendor|r" end
	print(format("|cffffd100Hoard Value|r %s%s: %s", link, count > 1 and ("x" .. count) or "", text))
end

ns.On("CHAT_MSG_LOOT", function(_, text)
	if not (ns.db and ns.db.lootValue) then return end
	-- The game hides some chat from addons in fights.
	if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return end
	local link, count = parse(text)
	if link then announce(link, count, RETRIES) end
end)

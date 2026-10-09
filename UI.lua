-- Hoard Value: the report window
-- Three tabs (this character, account, by character) over one sortable,
-- searchable list. The report behind it is only rebuilt when the data, prices
-- or settings change; searching and sorting just re-filter what's built.

local _, ns = ...
local format = string.format

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------

local LAYOUT = {
	width = 720, height = 540,
	insetTop = -118,      -- the inner panel starts below the header
	insetLeft = 8, insetRight = 6,
	insetBottom = 28,     -- room for the footer line under the inner panel
	listTop = -26,        -- room for the column headers inside the panel
	listLeft = 6, listBottom = 6,
	scrollBarSpace = 22,  -- right of the list, for the scroll bar
	rowHeight = 20,
	iconInset = 24,       -- the first item column starts after the icon
	cellPadding = 4,
}
LAYOUT.listWidth = LAYOUT.width - LAYOUT.insetLeft - LAYOUT.insetRight - LAYOUT.listLeft - LAYOUT.scrollBarSpace

local VIEWS = { "char", "account", "chars" }
local TAB_NAMES = { "This character", "Account", "By character" }

---------------------------------------------------------------------------
-- Columns: what each one shows for a row, and the row field it sorts by (key)
---------------------------------------------------------------------------

local function grey(text, shade)
	return "|cff" .. (shade or "888888") .. text .. "|r"
end

-- An item's name in its quality color, with its crafting-quality icon if it has
-- one. Built from parts instead of showing the link itself, because a link saved
-- before the item loaded has an empty name.
local function itemText(row)
	local color = row.link:match("^(|c.-)|H")              -- "|cnIQ4:" or "|cffa335ee"
	local inner = row.link:match("|h%[(.-)%]|h") or ""
	local icon = inner:match("|A.-|a")                      -- crafting quality star
	local name = row.name ~= "" and row.name or grey("Loading...")
	local text = color and (color .. name .. "|r") or name
	if icon then text = text .. " " .. icon end
	if row.bound then text = text .. " " .. grey("(bound)") end
	return text
end

local ITEM_COLUMNS = {
	{ key = "name", title = "Item", width = 270, justify = "LEFT", text = itemText },
	{ key = "count", title = "Qty", width = 55, justify = "RIGHT", numeric = true,
		text = function(row) return BreakUpLargeNumbers(row.count) end },
	{ key = "unit", title = "Price", width = 110, justify = "RIGHT", numeric = true,
		text = function(row)
			if not row.unit then return grey("no price") end
			-- Vendor prices in grey, so auction prices stand out.
			return row.how == "vendor" and grey(ns.Money(row.unit), "999999") or ns.Money(row.unit)
		end },
	{ key = "value", title = "Value", width = 120, justify = "RIGHT", numeric = true,
		text = function(row) return ns.Money(row.value) end },
	{ key = "where", title = "Where", width = 0, justify = "LEFT", -- width 0: the rest
		text = function(row) return row.where end },
}

local CHAR_COLUMNS = {
	{ key = "name", title = "Character", width = 200, justify = "LEFT",
		text = function(row)
			if row.kind == "warband" then return "|cff66bbffWarband bank|r" end
			return ns.ClassColored(row.char) .. " " .. grey(row.char.realm or "")
		end },
	{ key = "gold", title = "Gold", width = 115, justify = "RIGHT", numeric = true,
		text = function(row) return ns.Money(row.gold) end },
	{ key = "items", title = "Items", width = 115, justify = "RIGHT", numeric = true,
		text = function(row) return ns.Money(row.items) end },
	{ key = "value", title = "Total", width = 125, justify = "RIGHT", numeric = true,
		text = function(row) return ns.Money(row.value) end },
	{ key = "scanned", title = "Bank scanned", width = 0, justify = "LEFT", numeric = true,
		text = function(row) return row.scanned and ns.Ago(row.scanned) or "|cffff6666never - visit a banker|r" end },
}

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local frame
local view = "char"
local sortKey, sortDesc = "value", true
local search = ""
local shown        -- what the window is built from: { scope, report, rows, noAuctionPrices }
local dirty = true -- shown is out of date

local function columns()
	return view == "chars" and CHAR_COLUMNS or ITEM_COLUMNS
end

-- x offset and width of each column.
local function columnLayout()
	local x, out = 0, {}
	for i, col in ipairs(columns()) do
		local width = col.width > 0 and col.width or (LAYOUT.listWidth - x)
		out[i] = { x = x, width = width }
		x = x + width
	end
	return out
end

-- Left text inset of a column: past the icon for an item's name.
local function columnInset(i)
	return (i == 1 and view ~= "chars") and LAYOUT.iconInset or LAYOUT.cellPadding
end

---------------------------------------------------------------------------
-- Rows
---------------------------------------------------------------------------

local function itemTooltip(row)
	-- The Hoard Info lines are added below, so the item tooltip's own ones are
	-- skipped (they'd be missing with the tooltip option off).
	ns.ownItemTooltip = true
	local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, row.link)
	ns.ownItemTooltip = false
	if not ok then
		GameTooltip:SetText(row.name ~= "" and row.name or "Loading...")
	end
	if not ns.AddHoardInfo(GameTooltip, ns.ItemID(row.link)) then
		-- Not an item the Hoard Info lines cover (a caged battle pet): where it is.
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Hoard Info", 1, 0.82, 0)
		for _, place in ipairs(row.places) do
			GameTooltip:AddDoubleLine(place.where, BreakUpLargeNumbers(place.count), 1, 1, 1, 1, 1, 1)
		end
	end
	if row.unit then
		local label = row.how == "vendor" and "Vendor price, each" or "Auction price, each"
		GameTooltip:AddDoubleLine(label, ns.Money(row.unit), 0.7, 0.7, 0.7, 1, 1, 1)
	else
		GameTooltip:AddLine("No auction or vendor price", 1, 0.4, 0.4)
	end
	if row.bound then GameTooltip:AddLine("Bound: counted at vendor price", 0.6, 0.6, 0.6) end
end

local function characterTooltip(row)
	local function line(label, value) GameTooltip:AddDoubleLine(label, value, 1, 1, 1, 1, 1, 1) end
	if row.kind == "warband" then
		GameTooltip:SetText("Warband bank")
		line("Gold", ns.Money(row.gold))
		line("Items", row.scanned and ns.Money(row.items) or "not scanned")
		return
	end
	local c = row.char
	GameTooltip:SetText(ns.ClassColored(c) .. " - " .. (c.realm or ""))
	line("Gold", ns.Money(row.gold))
	line("Bags", ns.Money(row.bags))
	line("Bank", row.scanned and ns.Money(row.bank) or "not scanned")
	line("Bags updated", c.updated and ns.Ago(c.updated) or "never")
	if row.charKey ~= ns.charKey then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Right-click to forget this character", 0.6, 0.6, 0.6)
	end
end

local function onRowEnter(rowFrame)
	local row = rowFrame.element.row
	GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
	if row.kind == "item" then itemTooltip(row) else characterTooltip(row) end
	GameTooltip:Show()
end

local function onRowClick(rowFrame, mouseButton)
	local row = rowFrame.element.row
	if row.kind == "item" and mouseButton == "LeftButton" then
		-- Shift-click links it in chat, ctrl-click previews it.
		if HandleModifiedItemClick then HandleModifiedItemClick(row.link) end
	elseif row.kind == "char" and row.charKey ~= ns.charKey and mouseButton == "RightButton" and MenuUtil then
		MenuUtil.CreateContextMenu(rowFrame, function(_, root)
			root:CreateTitle(ns.ClassColored(row.char) .. " - " .. (row.char.realm or ""))
			root:CreateButton("Forget this character", function() ns.ForgetCharacter(row.charKey) end)
		end)
	end
end

local function setupRow(rowFrame)
	rowFrame.stripe = rowFrame:CreateTexture(nil, "BACKGROUND")
	rowFrame.stripe:SetAllPoints()
	rowFrame.stripe:SetColorTexture(1, 1, 1, 0.03)
	local highlight = rowFrame:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.08)
	rowFrame.icon = rowFrame:CreateTexture(nil, "ARTWORK")
	rowFrame.icon:SetSize(16, 16)
	rowFrame.icon:SetPoint("LEFT", LAYOUT.cellPadding, 0)
	rowFrame.cells = {}
	for i = 1, #ITEM_COLUMNS do
		local cell = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		cell:SetWordWrap(false)
		rowFrame.cells[i] = cell
	end
	rowFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	rowFrame:SetScript("OnEnter", onRowEnter)
	rowFrame:SetScript("OnLeave", GameTooltip_Hide)
	rowFrame:SetScript("OnClick", onRowClick)
end

-- Fills a recycled row frame. `element` is { row, index }: the report row and
-- its position in the list.
local function initRow(rowFrame, element)
	if not rowFrame.cells then setupRow(rowFrame) end
	rowFrame.element = element
	local row = element.row
	local layout = columnLayout()
	for i, col in ipairs(columns()) do
		local cell = rowFrame.cells[i]
		local inset = columnInset(i)
		cell:ClearAllPoints()
		cell:SetPoint("LEFT", rowFrame, "LEFT", layout[i].x + inset, 0)
		cell:SetWidth(layout[i].width - inset - LAYOUT.cellPadding)
		cell:SetJustifyH(col.justify)
		cell:SetText(col.text(row))
	end
	rowFrame.icon:SetShown(row.kind == "item")
	if row.kind == "item" then rowFrame.icon:SetTexture(row.icon or 134400) end -- 134400: question mark
	rowFrame.stripe:SetShown(element.index % 2 == 0)
end

---------------------------------------------------------------------------
-- Building and showing
---------------------------------------------------------------------------

local function rebuild()
	local scope = view == "char" and "char" or "account"
	local report = ns.BuildReport(scope)
	shown = {
		scope = scope,
		report = report,
		rows = view == "chars" and ns.BuildCharacterRows() or report.rows,
		-- A price addon with no data for this realm and faction prices everything
		-- at vendor value, which also makes Realistic value change nothing.
		noAuctionPrices = #report.rows > 0 and report.ahPriced == 0
			and (ns.TSMAvailable() or ns.AuctionatorAPI() ~= nil),
	}
	dirty = false
end

local function sortRows(rows)
	table.sort(rows, function(a, b)
		local x, y = a[sortKey], b[sortKey]
		if x == y then return a.name < b.name end
		-- Empty values (no price, never scanned) go last either way.
		if x == nil then return false end
		if y == nil then return true end
		if sortDesc then return x > y end
		return x < y
	end)
end

local function isVisible(row)
	if view ~= "chars" and row.value <= 0 and not ns.db.showZero then return false end
	return search == "" or row.search:find(search, 1, true) ~= nil
end

local function updateList()
	local rows = {}
	for _, row in ipairs(shown.rows) do
		if isVisible(row) then rows[#rows + 1] = row end
	end
	sortRows(rows)
	local elements = {}
	for i, row in ipairs(rows) do elements[i] = { row = row, index = i } end
	frame.scrollBox:SetDataProvider(CreateDataProvider(elements), ScrollBoxConstants.RetainScrollPosition)

	frame.empty:SetShown(#rows == 0)
	frame.empty:SetText(search ~= "" and "Nothing matches your search." or "Nothing worth anything here yet.")
end

local function updateHeaders()
	local layout = columnLayout()
	for i, col in ipairs(columns()) do
		local header = frame.headers[i]
		header:ClearAllPoints()
		header:SetPoint("BOTTOMLEFT", frame.scrollBox, "TOPLEFT", layout[i].x, 2)
		header:SetSize(layout[i].width, 18)
		header.text:ClearAllPoints()
		header.arrow:ClearAllPoints()
		if col.justify == "RIGHT" then
			header.text:SetPoint("RIGHT", -LAYOUT.cellPadding, 0)
			header.arrow:SetPoint("RIGHT", header.text, "LEFT", -2, 0)
		else
			header.text:SetPoint("LEFT", columnInset(i), 0)
			header.arrow:SetPoint("LEFT", header.text, "RIGHT", 2, 0)
		end
		header.text:SetText(col.title)
		local sorted = col.key == sortKey
		header.text:SetTextColor(1, sorted and 1 or 0.82, sorted and 1 or 0)
		header.arrow:SetShown(sorted)
		header.arrow:SetRotation(sortDesc and 0 or math.pi)
	end
end

local function breakdownText()
	local s, scope = shown.report.sections, shown.scope
	local function part(label, value) return "|cffffd100" .. label .. "|r " .. value end
	local bank = ns.Money(s.bank)
	if scope == "char" and not ns.CharData().bankScanned then bank = grey("not scanned") end
	local parts = { part("Gold", ns.Money(s.gold)), part("Bags", ns.Money(s.bags)), part("Bank", bank) }
	if scope ~= "char" and ns.WarbandCounted() then
		parts[#parts + 1] = part("Warband bank", ns.Money(s.warband))
	end
	return table.concat(parts, "     ")
end

local function footerText()
	local report, notes = shown.report, {}
	local function warn(text) notes[#notes + 1] = "|cffffaa33" .. text .. "|r" end
	if shown.scope == "char" then
		local c = ns.CharData()
		if c.bankScanned then
			notes[#notes + 1] = "Bank scanned " .. ns.Ago(c.bankScanned)
		else
			warn("Open your bank once to include it")
		end
	else
		local missing = 0
		for _, c in pairs(ns.db.chars) do
			if not c.bankScanned then missing = missing + 1 end
		end
		if missing > 0 then
			warn(format("%d character%s without a bank scan", missing, missing == 1 and "" or "s"))
		end
		if ns.WarbandCounted() and not ns.db.warband.scanned then warn("Warband bank not scanned yet") end
	end
	if report.boundSkipped > 0 then
		notes[#notes + 1] = format("%s bound item%s not counted", BreakUpLargeNumbers(report.boundSkipped),
			report.boundSkipped == 1 and "" or "s")
	end
	if view ~= "chars" and report.zeroValue > 0 and not ns.db.showZero then
		notes[#notes + 1] = format("%d with no value hidden", report.zeroValue)
	end
	return table.concat(notes, "  " .. grey("-", "555555") .. "  ")
end

local function updateSummary()
	if shown.scope == "char" then
		local c = ns.CharData()
		frame.scope:SetText(ns.ClassColored(c) .. "  " .. grey(c.realm or ""))
	else
		local count = 0
		for _ in pairs(ns.db.chars) do count = count + 1 end
		frame.scope:SetText(format("Account  " .. grey("%d character%s"), count, count == 1 and "" or "s"))
	end
	frame.total:SetText(ns.Money(shown.report.total))
	frame.breakdown:SetText(breakdownText())
	frame.footerLeft:SetText(footerText())
	if shown.noAuctionPrices then
		frame.footerRight:SetText("|cffffaa33No auction prices yet - scan the auction house|r")
	else
		frame.footerRight:SetText("Prices: " .. ns.SourceLabel())
	end
	frame.realistic:SetChecked(ns.db.realistic)
end

local function refresh()
	if not (frame and frame:IsShown()) then return end
	if dirty then
		rebuild()
		updateSummary()
	end
	updateList()
end

local queueRefresh = ns.Debounce(0.1, refresh)

local function markDirty()
	dirty = true
	queueRefresh()
end

ns.Listen("DataChanged", markDirty)
ns.Listen("ItemInfoLoaded", markDirty)
ns.Listen("SettingChanged", markDirty)

local function selectTab(index)
	ns.db.tab = index
	view = VIEWS[index]
	sortKey, sortDesc = "value", true
	PanelTemplates_SetTab(frame, index)
	updateHeaders()
	dirty = true
	refresh()
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

local function createHeaderArea()
	-- Who, the total, and what it's made of.
	frame.scope = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.scope:SetPoint("TOPLEFT", 18, -36)
	frame.total = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	frame.total:SetPoint("TOPLEFT", frame.scope, "BOTTOMLEFT", 0, -8)
	frame.total:SetTextColor(1, 1, 1)
	frame.breakdown = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.breakdown:SetPoint("TOPLEFT", frame.total, "BOTTOMLEFT", 0, -10)

	local gear = CreateFrame("Button", nil, frame)
	gear:SetSize(18, 18)
	gear:SetPoint("TOPRIGHT", -16, -36)
	gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
	gear:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	gear:SetScript("OnClick", ns.OpenOptions)
	gear:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Hoard Value options")
		GameTooltip:Show()
	end)
	gear:SetScript("OnLeave", GameTooltip_Hide)

	local realistic = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
	realistic:SetSize(24, 24)
	realistic:SetPoint("TOPRIGHT", -150, -32)
	local label = realistic:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("LEFT", realistic, "RIGHT", 2, 0)
	label:SetText("Realistic value")
	realistic:SetScript("OnClick", function(self) ns.SetSetting("realistic", self:GetChecked()) end)
	realistic:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Realistic value")
		GameTooltip:AddLine("What you'd actually get selling everything: each item at the lower of its market value and the cheapest auction right now, minus the auction house's 5% cut.", 1, 1, 1, true)
		if shown and shown.noAuctionPrices then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(ns.SourceLabel() .. " has no auction prices for this realm and faction yet, so everything counts at vendor price and this changes nothing. Scan the auction house first.", 1, 0.67, 0.2, true)
		end
		GameTooltip:Show()
	end)
	realistic:SetScript("OnLeave", GameTooltip_Hide)
	frame.realistic = realistic

	local searchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
	searchBox:SetSize(190, 20)
	searchBox:SetPoint("TOPRIGHT", -16, -64)
	searchBox:SetAutoFocus(false)
	searchBox:HookScript("OnTextChanged", function(self)
		search = strtrim(self:GetText() or ""):lower()
		refresh()
	end)
end

local function createList()
	local inset = frame.Inset
	inset:ClearAllPoints()
	inset:SetPoint("TOPLEFT", LAYOUT.insetLeft, LAYOUT.insetTop)
	inset:SetPoint("BOTTOMRIGHT", -LAYOUT.insetRight, LAYOUT.insetBottom)

	local scrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
	scrollBox:SetPoint("TOPLEFT", LAYOUT.listLeft, LAYOUT.listTop)
	scrollBox:SetPoint("BOTTOMRIGHT", -LAYOUT.scrollBarSpace, LAYOUT.listBottom)
	local scrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)
	local listView = CreateScrollBoxListLinearView()
	listView:SetElementExtent(LAYOUT.rowHeight)
	listView:SetElementInitializer("Button", initRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, listView)
	frame.scrollBox = scrollBox

	frame.empty = scrollBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	frame.empty:SetPoint("CENTER")

	-- Column headers: click to sort, click again to flip.
	frame.headers = {}
	for i = 1, #ITEM_COLUMNS do
		local header = CreateFrame("Button", nil, inset)
		header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		header.arrow = header:CreateTexture(nil, "OVERLAY")
		header.arrow:SetAtlas("auctionhouse-ui-sortarrow", true)
		header:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
		header:SetScript("OnClick", function()
			local col = columns()[i]
			if sortKey == col.key then
				sortDesc = not sortDesc
			else
				-- Numbers start biggest first, names A to Z.
				sortKey, sortDesc = col.key, col.numeric or false
			end
			updateHeaders()
			refresh()
		end)
		frame.headers[i] = header
	end
end

local function createFooter()
	frame.footerRight = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.footerRight:SetPoint("BOTTOMRIGHT", -16, 9)
	frame.footerLeft = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.footerLeft:SetPoint("BOTTOMLEFT", 16, 9)
	frame.footerLeft:SetPoint("RIGHT", frame.footerRight, "LEFT", -12, 0)
	frame.footerLeft:SetJustifyH("LEFT")
	frame.footerLeft:SetWordWrap(false)
end

-- Tabs under the window, in the style of the game's own windows: the newer tabs
-- on Retail and Forever, the classic ones on Era, TBC and MoP Classic.
local function createTabs()
	local modern = ns.MODERN_UI
	frame.Tabs = {}
	for i, text in ipairs(TAB_NAMES) do
		local tab = CreateFrame("Button", "HoardValueFrameTab" .. i, frame,
			modern and "PanelTabButtonTemplate" or "CharacterFrameTabButtonTemplate")
		tab:SetID(i)
		if not modern then
			-- The classic template's own scripts are written for the character window.
			tab:SetScript("OnShow", nil)
		end
		tab:SetText(text)
		if PanelTemplates_TabResize then PanelTemplates_TabResize(tab, 0) end
		if i == 1 then
			tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", modern and 12 or 11, modern and 2 or 3)
		elseif modern then
			tab:SetPoint("TOPLEFT", frame.Tabs[i - 1], "TOPRIGHT", 3, 0)
		else
			-- Classic tabs overlap at their rounded edges.
			tab:SetPoint("LEFT", frame.Tabs[i - 1], "RIGHT", -19, 0)
		end
		tab:SetScript("OnClick", function(self)
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
			selectTab(self:GetID())
		end)
		frame.Tabs[i] = tab
	end
	PanelTemplates_SetNumTabs(frame, #frame.Tabs)
end

local function placeFrame()
	frame:ClearAllPoints()
	local pos = ns.db.pos
	if pos then
		frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
	else
		frame:SetPoint("CENTER")
	end
end

local function createFrame()
	frame = CreateFrame("Frame", "HoardValueFrame", UIParent, "ButtonFrameTemplate")
	ButtonFrameTemplate_HidePortrait(frame)
	if ButtonFrameTemplate_HideButtonBar then ButtonFrameTemplate_HideButtonBar(frame) end
	frame:SetSize(LAYOUT.width, LAYOUT.height)
	if frame.SetTitle then
		frame:SetTitle("Hoard Value")
	elseif frame.TitleText then
		frame.TitleText:SetText("Hoard Value")
	end
	frame:SetToplevel(true)
	frame:Hide()
	tinsert(UISpecialFrames, "HoardValueFrame") -- Esc closes it

	placeFrame()
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint()
		ns.db.pos = { point, relPoint, x, y }
	end)

	createHeaderArea()
	createList()
	createFooter()
	createTabs()

	frame:SetScript("OnShow", function()
		-- Fresh bags and fresh market prices every time it opens.
		ns.ScanBags()
		ns.InvalidatePrices()
		dirty = true
		refresh()
	end)
	selectTab(VIEWS[ns.db.tab] and ns.db.tab or 1)
end

function ns.ToggleWindow()
	if not frame then createFrame() end
	frame:SetShown(not frame:IsShown())
end

function ns.ResetWindowPosition()
	ns.db.pos = nil
	if frame then placeFrame() end
end

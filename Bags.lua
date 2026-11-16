-- Hoard Value: bags value in the game's own bag window
-- What the items in your bags are worth, on the left of the money row at the
-- bottom of the backpack (or the combined bag). Hover for this character's
-- totals, click to open the window. Bag addons that replace the game's bags
-- never show that money row, so nothing shows there.

local ADDON_NAME, ns = ...
local format = string.format

local LEFT_INSET = 6          -- from the left end of the money row
local CLASSIC_LEFT_INSET = 14 -- from the left edge of the classic backpack
local GAP = 6                 -- kept clear between our text and your gold
local MAX_CONTAINER_FRAMES = 20

-- The addon's own pouch icon (white, in Media), sized to the text and tinted.
local BAG_ICON = format("|TInterface\\AddOns\\%s\\Media\\bag:0:0:0:0:64:64:0:64:0:64:230:215:180|t", ADDON_NAME)

local labels = {} -- money frame -> our button on it
local report      -- this character's report, until data, prices or settings change

local function charReport()
	report = report or ns.BuildReport("char")
	return report
end

-- Left edge of the coins the money row shows, or nil when it can't be told.
local function coinsLeft(moneyFrame)
	local name = moneyFrame:GetName() or ""
	local left
	for _, key in ipairs({ "GoldButton", "SilverButton", "CopperButton" }) do
		local coin = moneyFrame[key] or _G[name .. key]
		local x = coin and coin:IsShown() and coin:GetLeft()
		if x and (not left or x < left) then left = x end
	end
	return left
end

local function place(label, moneyFrame)
	label:ClearAllPoints()
	if ns.MODERN_UI then
		-- The money row spans the bag's width.
		label:SetPoint("LEFT", moneyFrame, "LEFT", LEFT_INSET, 0)
	else
		-- The money row hugs the coins on the right, so line up with it from the
		-- bag's left edge instead.
		local container = moneyFrame:GetParent()
		local top, containerTop = moneyFrame:GetTop(), container:GetTop()
		if top and containerTop then
			label:SetPoint("TOPLEFT", container, "TOPLEFT", CLASSIC_LEFT_INSET, top - containerTop)
		else
			label:SetPoint("RIGHT", moneyFrame, "LEFT", -GAP, 0)
		end
	end
end

local function update(label)
	local moneyFrame = label:GetParent()
	if not ns.db.bagValue then
		label:Hide()
		return
	end
	label:Show()
	if not moneyFrame:IsVisible() then return end

	label.text:SetText(BAG_ICON .. " " .. ns.Money(charReport().sections.bags))
	label:SetSize(label.text:GetStringWidth(), math.max(moneyFrame:GetHeight(), 12))
	place(label, moneyFrame)

	-- With a lot of gold in a narrow backpack there's no room for both: keep the
	-- icon, and the amount is in the tooltip.
	local right, coins = label:GetRight(), coinsLeft(moneyFrame)
	if right and coins and right > coins - GAP then
		label.text:SetText(BAG_ICON)
		label:SetWidth(label.text:GetStringWidth())
	end
end

local function showTooltip(label)
	local r = charReport()
	GameTooltip:SetOwner(label, "ANCHOR_TOPLEFT")
	GameTooltip:SetText("Hoard Value")
	GameTooltip:AddDoubleLine("Items in your bags", ns.Money(r.sections.bags), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(ns.PlayerName() .. ", everything", ns.Money(r.total), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Click to open, right-click for options", 0.6, 0.6, 0.6)
	GameTooltip:Show()
end

local function createLabel(moneyFrame)
	local label = CreateFrame("Button", nil, moneyFrame)
	label:SetFrameLevel(moneyFrame:GetFrameLevel() + 5)
	label:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	label.text = label:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label.text:SetPoint("LEFT")
	label:SetScript("OnEnter", showTooltip)
	label:SetScript("OnLeave", GameTooltip_Hide)
	label:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then ns.OpenOptions() else ns.ToggleWindow() end
	end)
	return label
end

local function updateAll()
	for _, label in pairs(labels) do update(label) end
end

-- The game shows the money row and then moves it, and it redraws your gold
-- after we hear about it, so wait a moment before measuring.
local refresh = ns.Debounce(0.05, updateAll)

local function watch(moneyFrame)
	if not moneyFrame or labels[moneyFrame] then return end
	labels[moneyFrame] = createLabel(moneyFrame)
	moneyFrame:HookScript("OnShow", refresh)
	if moneyFrame:IsVisible() then refresh() end
end

ns.On("PLAYER_LOGIN", function()
	for i = 1, MAX_CONTAINER_FRAMES do
		local container = _G["ContainerFrame" .. i]
		watch(container and container.MoneyFrame or _G["ContainerFrame" .. i .. "MoneyFrame"])
	end
	local combined = _G.ContainerFrameCombinedBags
	watch(combined and combined.MoneyFrame)
end)

local function changed()
	report = nil
	refresh()
end

ns.Listen("DataChanged", changed)
ns.Listen("ItemInfoLoaded", changed)
ns.Listen("SettingChanged", changed)

-- luacheck settings for Hoard Value (https://github.com/lunarmodules/luacheck).
-- Run from this folder:  luacheck .
-- Catches typos and use-before-define bugs: any name not declared local and not
-- listed below is reported as an unknown global.

std = "lua51"
max_line_length = false

-- Event handlers and WoW callbacks often ignore some of their arguments.
unused_args = false

-- Globals this addon sets (WoW requires these to be global).
globals = {
	"HoardValueDB",                       -- saved data
	"SLASH_HOARDVALUE1", "SLASH_HOARDVALUE2",
	"SlashCmdList",                       -- adds SlashCmdList.HOARDVALUE
	"HoardValue_OnAddonCompartmentClick", -- named in the .toc
	"HoardValue_OnAddonCompartmentEnter",
	"HoardValue_OnAddonCompartmentLeave",
}

-- WoW API and UI the addon reads. Keep sorted; add new ones as you use them.
read_globals = {
	-- Lua extras WoW adds
	"strsplit", "strtrim", "tinsert", "wipe", "time",
	"geterrorhandler", "issecretvalue", "securecallfunction",

	-- Game API
	"Auctionator", "TSM_API",
	"C_Bank", "C_Container", "C_Item", "C_Timer", "C_TooltipInfo", "TooltipDataProcessor",
	"Enum", "ItemLocation",
	"GetBuildInfo", "GetCursorPosition", "GetItemInfo", "GetItemInfoInstant",
	"GetMinimapShape", "GetMoney", "GetMoneyString", "GetNormalizedRealmName", "GetRealmName",
	"UnitClass", "UnitName",
	"BANK_CONTAINER", "NUM_BAG_SLOTS", "NUM_BANKBAGSLOTS",
	"RAID_CLASS_COLORS", "SOUNDKIT", "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE",

	-- UI
	"AddonCompartmentFrame", "GameTooltip", "ItemRefTooltip", "Minimap", "UIParent", "UISpecialFrames",
	"BreakUpLargeNumbers", "ButtonFrameTemplate_HideButtonBar", "ButtonFrameTemplate_HidePortrait",
	"CreateDataProvider", "CreateFrame", "CreateScrollBoxListLinearView",
	"CreateSettingsButtonInitializer", "CreateSettingsListSectionHeaderInitializer",
	"GameTooltip_Hide", "HandleModifiedItemClick", "MenuUtil",
	"PanelTemplates_SetNumTabs", "PanelTemplates_SetTab", "PanelTemplates_TabResize",
	"PlaySound", "ScrollBoxConstants", "ScrollUtil", "Settings",
}

-- luacheck configuration. WoW runs Lua 5.1.
-- Run the addon folders on their own (CI does): tests/stub.lua defines the
-- client's globals at the top level, and checked together with it unknown
-- client names in the addon would pass unnoticed.
--   luacheck Pathwise Pathwise_Gear Pathwise_Bags examples
--   luacheck tests tools
std = "lua51"
max_line_length = false
codes = true
ignore = {
	"212/_.*",   -- unused arguments named _ or _foo
	"212/self",
	"211/ADDON", -- local ADDON, ns = ...: the addon's name, used by some files only
}

globals = {
	"Pathwise", "ForeverLevels",
	"PathwiseSettings", "PathwiseCharSettings",
	"SLASH_PATHWISE1", "SLASH_PATHWISE2", "SLASH_PATHWISE3", "SLASH_PATHWISE4",
	"BINDING_HEADER_PATHWISE", "BINDING_NAME_PATHWISE_TOGGLE", "BINDING_NAME_PATHWISE_COMPACT",
	"BINDING_NAME_PATHWISE_PROFESSIONS", "BINDING_NAME_PATHWISE_DUNGEONS", "BINDING_NAME_PATHWISE_SETTINGS",
	"BINDING_NAME_PATHWISE_REPORT",
	SlashCmdList = { other_fields = true },
	UISpecialFrames = { other_fields = true },
}

read_globals = {
	-- Checked against Blizzard's API documentation or UI source on the
	-- Gethe/wow-ui-source "forever" branch (1.60.1.70450); see docs/API_RESEARCH.md.
	"C_AddOns", "C_ChatInfo", "C_GossipInfo", "C_Map", "C_QuestLog", "C_SuperTrack", "C_Texture",
	"C_Item", "C_SkillInfo", "C_TradeSkillUI", "GetProfessions", "GetProfessionInfo",
	"Enum", "Settings", "UiMapPoint",
	"CreateFrame", "UIParent", "DEFAULT_CHAT_FRAME", "GameTooltip", "CreateVector2D", "wipe", "GetTime", "time",
	"GetBuildInfo", "issecretvalue", "WOW_PROJECT_ID", "WOW_PROJECT_CAMELOT", "BACKDROP_DARK_DIALOG_32_32",
	"UnitClass", "UnitRace", "UnitFactionGroup", "UnitLevel", "UnitName", "GetPlayerFacing",
	"IsShiftKeyDown", "IsInGroup", "IsInRaid", "Ambiguate",
	"GetQuestID", "QuestFlagsPVP", "QuestGetAutoAccept", "AcceptQuest", "AcknowledgeAutoAcceptQuest",
	"IsQuestCompletable", "CompleteQuest", "GetQuestMoneyToGet", "GetNumQuestChoices", "GetQuestReward",
	"GetNumActiveQuests", "GetActiveTitle", "GetActiveQuestID", "SelectActiveQuest",
	"GetNumAvailableQuests", "GetAvailableQuestInfo", "SelectAvailableQuest",

	-- Added with the merge, checked against the same branch (1.60.1.70532):
	-- Blizzard_SharedXMLBase/Mixin.lua, Blizzard_SharedXML/Backdrop.lua, and the
	-- generated API docs (UITimer, ClassColor, Container, Minimap,
	-- SpecializationInfo, SpellBook, PlayerScript, CVar, Input, Item,
	-- RestrictedActions, Instance, Unit).
	"Mixin", "BackdropTemplateMixin", "BACKDROP_DIALOG_EDGE_32",
	"C_Timer", "C_ClassColor", "C_Container", "C_Minimap", "C_SpecializationInfo", "C_SpellBook",
	"GetBindLocation", "GetCVar", "GetCursorPosition", "GetItemCount", "GetMoney", "InCombatLockdown",
	"IsInInstance", "IsIndoors", "IsSpellKnown", "PlaySound", "UnitOnTaxi",

	-- Used by the code from pathwise-nn/Pathwise, whose authors checked them
	-- against the same source (CONTRIBUTING.md). Older API and FrameXML names
	-- outside the generated docs; the code reaches them behind a check that
	-- they exist, or after the C_ namespace's own function.
	"GetInventoryItemLink", "GetInventoryItemTexture", "GetItemInfo", "GetQuestItemLink", "IsPlayerSpell",
	"ReloadUI", "GetMinimapShape", "hooksecurefunc", "TooltipDataProcessor", "RaidWarningUtil", "SOUNDKIT",
	"ITEM_QUALITY_COLORS", "RAID_CLASS_COLORS", "SetItemButtonCount", "SetItemButtonDesaturated",
	"SetItemButtonQuality", "SetItemButtonTexture", "UIErrorsFrame", "ItemRefTooltip", "MerchantFrame",
	"Minimap", "WorldMapFrame", "ContainerFrameCombinedBags", "ContainerFrameContainer",
	"OpenAllBags", "OpenBackpack", "ToggleAllBags", "ToggleBackpack", "CloseAllBags", "CloseBackpack",
}

files["tests/"] = { std = "max", globals = { "_G" }, allow_defined_top = true, ignore = { "211", "212", "213", "111", "112", "113", "121", "122", "131", "311" } } -- 131: the stub defines the client for the addon
files["tools/"] = { std = "max", ignore = { "211", "212", "213", "113", "121", "421" } }

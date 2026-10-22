-- luacheck configuration. WoW runs Lua 5.1.
std = "lua51"
max_line_length = false
codes = true
ignore = {
	"212/_.*",   -- unused arguments named _ or _foo
	"212/self",
}

globals = {
	"ForeverLevels",
	"ForeverLevelsDB",
	"ForeverLevelsCharDB",
	"SLASH_FOREVERLEVELS1",
	"SLASH_FOREVERLEVELS2",
	SlashCmdList = { other_fields = true },
}

-- Every name below was checked against Blizzard's API documentation or UI source
-- on the Gethe/wow-ui-source "forever" branch (1.60.1.70450). See docs/API_RESEARCH.md.
read_globals = {
	-- namespaces
	"C_AddOns", "C_ChatInfo", "C_GossipInfo", "C_Map", "C_QuestLog", "C_SuperTrack", "C_Texture",
	"Enum", "Settings", "UiMapPoint",
	-- frames and utilities
	"CreateFrame", "UIParent", "DEFAULT_CHAT_FRAME", "CreateVector2D", "wipe", "GetTime", "time",
	"GetBuildInfo", "issecretvalue", "WOW_PROJECT_ID", "WOW_PROJECT_CAMELOT", "BACKDROP_DARK_DIALOG_32_32",
	-- unit / player
	"UnitClass", "UnitRace", "UnitFactionGroup", "UnitLevel", "UnitName", "GetPlayerFacing",
	"IsShiftKeyDown", "IsInGroup", "IsInRaid", "Ambiguate",
	-- quest dialog (Mainline QuestFrame.lua, which Forever loads)
	"GetQuestID", "QuestFlagsPVP", "QuestGetAutoAccept", "AcceptQuest", "AcknowledgeAutoAcceptQuest",
	"IsQuestCompletable", "CompleteQuest", "GetQuestMoneyToGet", "GetNumQuestChoices", "GetQuestReward",
	"GetNumActiveQuests", "GetActiveTitle", "GetActiveQuestID", "SelectActiveQuest",
	"GetNumAvailableQuests", "GetAvailableQuestInfo", "SelectAvailableQuest",
}

files["tests/"] = { std = "max", globals = { "_G" }, allow_defined_top = true, ignore = { "211", "212", "213", "111", "112", "113", "121", "122" } }
files["tools/"] = { std = "max", ignore = { "211", "212", "113", "121" } }

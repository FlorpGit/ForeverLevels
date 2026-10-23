# Forever API research

This file records what Pathwise relies on, where each piece was verified,
and which wanted features the WoW: Forever API does not support. Re-check it
whenever Blizzard ships a new Forever build.

Verified against: Blizzard's UI source and generated API documentation on the
[`forever` branch of Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source/tree/forever),
build 1.60.1 (70450), 2026-10-16. Supporting sources:
[TOC format](https://warcraft.wiki.gg/wiki/TOC_format),
[Patch 1.60.1/API changes](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes) and
[notes](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes).

## What the client is

- WoW: Forever is a separate game flavor (game type `forever`, which equals the older
  name `camelot`). `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` (18) identifies it.
- TOC: `## Interface: 16001`. The `_Forever.toc` suffix (alias `_Camelot.toc`)
  picks the TOC for this flavor. Pathwise ships an identical `Pathwise.toc`
  as a fallback; the tests keep the two the same.
- API surface: Forever runs the modern Mainline API (`C_QuestLog`, `C_Map`,
  `C_SuperTrack`, `C_GossipInfo` and so on), not the Classic Era 1.15 API. Its quest
  frame is the Mainline `QuestFrame.lua` (`Blizzard_UIPanels_Game.toc` loads
  `[Family]\QuestFrame.lua` for `camelot`).
- Midnight-era addon restrictions are active: secret values, chat-messaging
  lockdown, restricted functions. Patch notes 2026-09-15: *"The addon disarmament
  changes introduced in Midnight, including secrets, will also be active in Forever."*
- A new client means a full restart: `/reload` does not load newly installed addons.

## APIs used and where each was verified

Checked automatically: every `C_*` function and every event in the addon was matched
against the generated docs (`Blizzard_APIDocumentationGenerated/*.lua`). Global
functions were matched against those docs or against Blizzard's own Forever UI code.

| Feature | API | Verified in |
|---|---|---|
| Client detection | `WOW_PROJECT_ID`, `WOW_PROJECT_CAMELOT` | 1.60.1 API changes |
| Metadata | `C_AddOns.GetAddOnMetadata` | AddOnsDocumentation |
| Quest state | `C_QuestLog.IsOnQuest`, `IsComplete`, `IsQuestFlaggedCompleted`, `GetQuestObjectives`, `GetTitleForQuestID` | QuestLogDocumentation |
| Quest events | `QUEST_ACCEPTED(questId)`, `QUEST_TURNED_IN(questID, xp, money)`, `QUEST_REMOVED`, `QUEST_LOG_UPDATE`, `UNIT_QUEST_LOG_CHANGED` | QuestLog / Unit docs |
| Quest dialogs | `QUEST_DETAIL`, `QUEST_PROGRESS`, `QUEST_COMPLETE`, `QUEST_GREETING`, `GetQuestID`, `AcceptQuest`, `AcknowledgeAutoAcceptQuest`, `QuestGetAutoAccept`, `QuestFlagsPVP`, `IsQuestCompletable`, `CompleteQuest`, `GetNumQuestChoices`, `GetQuestReward`, `GetQuestMoneyToGet`, `GetActiveTitle`, `GetActiveQuestID`, `GetAvailableQuestInfo`, `Select*Quest` | Mainline `QuestFrame.lua` on the forever branch |
| Gossip | `GOSSIP_SHOW`, `C_GossipInfo.GetActiveQuests`, `GetAvailableQuests`, `SelectActiveQuest`, `SelectAvailableQuest` | GossipInfoDocumentation |
| Map + position | `C_Map.GetBestMapForUnit`, `GetMapInfo`, `GetPlayerMapPosition`, `GetWorldPosFromMapPos` | MapDocumentation |
| Native waypoint | `C_Map.CanSetUserWaypointOnMap`, `SetUserWaypoint`, `HasUserWaypoint`, `ClearUserWaypoint`, `UiMapPoint.CreateFromCoordinates`, `C_SuperTrack.SetSuperTrackedUserWaypoint` | Map / SuperTrackManager docs, `Blizzard_ObjectAPI/Mainline/UiMapPoint.lua` |
| Arrow direction | `GetPlayerFacing()` (returns a nilable number) | PlayerScriptDocumentation |
| Arrow art | Pathwise's own textures (`Media/arrow.tga` and the glyphs, drawn by `tools/media.js`) | none needed |
| Timers | `C_Timer.After` (else a frame's OnUpdate) | UITimerDocumentation |
| Party sync | `C_ChatInfo.RegisterAddonMessagePrefix`, `SendAddonMessage`, `InChatMessagingLockdown`, `AreOutgoingAddonChatMessagesRestricted`, `CHAT_MSG_ADDON`, `IsInGroup`, `IsInRaid`, `Ambiguate`, `GROUP_ROSTER_UPDATE` | ChatInfoDocumentation, `ChatFrameUtil.lua` |
| Secret values | `issecretvalue` | FrameScriptDocumentation |
| Options panel | `Settings.RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory` | `Blizzard_Settings_Shared/Blizzard_Settings.lua` |
| Misc | `IsShiftKeyDown`, `GetBuildInfo`, `UIPanelButtonTemplate`, `UIPanelCloseButton`, `BackdropTemplate` | Input / Build docs, `SharedUIPanelTemplates.xml`, `Backdrop.lua` |
| Classic look | `Mixin`, `BackdropTemplateMixin` (`SetBackdrop`, `OnBackdropSizeChanged`, `SetBackdropBorderColor`), `BACKDROP_DIALOG_EDGE_32` (`Interface\DialogFrame\UI-DialogBox-Border`), `Interface\Tooltips\UI-Tooltip-Border` (as `BACKDROP_TUTORIAL_16_16` uses it), `UIPanelButtonTemplate` (its ButtonText through `GetFontString`), `UIPanelCloseButton`, `InputBoxTemplate`, `Fonts\FRIZQT__.TTF` | `Blizzard_SharedXMLBase/Mixin.lua`, `Blizzard_SharedXML/Backdrop.lua`, `Mainline/SharedUIPanelTemplates.xml`, `Shared/InputBox/InputBoxTemplates.xml` (1.60.1.70532) |
| Feedback Center inputs | EditBox `SetMultiLine`, `HighlightText`, `SetAutoFocus`, `SetFocus`, `ClearFocus`, `SetFont` | SimpleEditBoxAPIDocumentation |
| Report button | Pathwise's flag glyph (`Media/glyph-flag.tga`); `GameTooltip:SetOwner` | SimpleButtonAPIDocumentation |

### Profession APIs (added in Phase 2, verified on the same build)

| Feature | API | Verified in |
|---|---|---|
| Professions, skill, cap | `GetProfessions()` returns prof1, prof2, first aid, fishing, cooking; `GetProfessionInfo(index)` returns name, icon, rank, maxRank, numSpells, spellOffset, skillLine, rankModifier, ... | Forever's `Blizzard_ProfessionsBook/Camelot/Blizzard_ProfessionsBook.lua` (the order differs from retail, where the third slot is archaeology) |
| Skill list fallback | `C_SkillInfo.GetNumSkillLines`, `GetSkillLineInfo(index)` returning `SkillLineAttributes` (skillID, name, isHeader, rank, maxRank, modifier, ...) | SkillInfoDocumentation |
| Skill changes | `SKILL_LINES_CHANGED`, `LEARNED_SPELL_IN_SKILL_LINE`, `TRAINER_SHOW`, `TRAINER_CLOSED` | SkillInfo, SpellBook and Trainer docs |
| Recipe state | `C_TradeSkillUI.GetRecipeInfo(recipeID)`, asked recipe by recipe (Forever has no `GetAllRecipeIDs`/`GetFilteredRecipeIDs`; checked again on 1.60.1.70532) returning `TradeSkillRecipeInfo` (learned, relativeDifficulty, canSkillUp, numSkillUps, ...); `Enum.TradeskillRelativeDifficulty` Optimal 0, Medium 1, Easy 2, Trivial 3 | TradeSkillUI and TradeSkillUITypes docs; called by Forever's `Blizzard_Professions/Camelot` code |
| Client reagent lists | `C_TradeSkillUI.GetRecipeSchematic(recipeID, isRecraft)` returning `reagentSlotSchematics` with `reagents[].itemID`, `quantityRequired`, `required` | TradeSkillUIDocumentation |
| Which profession window is open | `C_TradeSkillUI.GetBaseProfessionInfo()` returning `ProfessionInfo` (professionID, professionName, skillLevel, maxSkillLevel) | TradeSkillUIDocumentation |
| Recipe window events | `TRADE_SKILL_SHOW`, `TRADE_SKILL_LIST_UPDATE`, `NEW_RECIPE_LEARNED(recipeID)` | TradeSkillUIDocumentation |
| Item counts and names | `C_Item.GetItemCount(item, includeBank)`, `C_Item.GetItemNameByID(item)`, `BAG_UPDATE_DELAYED` | Item and Container docs |
| Detour re-checks | `ZONE_CHANGED_NEW_AREA` | MapDocumentation |
| Trainer name for the recorder | `UnitName("npc")` | UnitDocumentation |

Data facts (recipes, reagents, trainers) were checked on Wowhead's Forever database
(wowhead.com/forever). Its recipe lists are rendered by JavaScript and could not be read,
so each recipe was checked on its own page. Those pages do not show skill levels.

## Features the Forever API does not support (or limits)

Things I wanted but the current API does not allow, and what the addon does instead.

| Wanted feature | Status | Why / what Pathwise does instead |
|---|---|---|
| Arrow direction inside dungeons, raids and battlegrounds | Not supported | `GetPlayerFacing()` returns nil in instances, and `C_Map.GetPlayerMapPosition` returns nil there too. The arrow hides its pointer and shows distance when it can, or nothing. |
| Walking paths / pathfinding | Not supported | No navmesh or route API. `C_Navigation` only reports distance and screen position of the target Blizzard is super-tracking. The arrow points in a straight line. (Some community addons ship their own walking maps built from client data; that is out of scope here.) |
| Looking up NPC or object positions | Not supported | No API returns where an NPC stands. Pathwise takes positions from QuestieDB's spawn data (docs/DATA.md); a route may give `at = { map, x, y }`, recorded with `/pw record`. Forever also hides the server/spawn part of creature GUIDs (1.60.1 beta 5), so spawns cannot be identified either. |
| Forever uiMapIDs | Not documented by Blizzard | Routes and the data give map IDs, from QuestieDB's Forever area-to-map table (`support/Forever/Zones/areaIdToUiMapId.lua`), so every client language works. `/pw where` prints the ID. |
| Talking to NPCs or accepting quests remotely | Not supported | Automation only answers dialogs the player opened by clicking an NPC. Interacting with units is protected. |
| Picking between quest rewards | Deliberately not automated | Pathwise stops and asks. Quests that cost money are never auto-completed. |
| Setting the hearthstone, taking flight paths, training | Not automated | These are confirmations or protected actions. Routes show them as manual notes. |
| Using quest items from the guide | Not built | `UseItem`-style actions are protected; a future version could add a secure action button (out of combat only). |
| Party sync during encounters or for trial accounts | Limited | Nothing is sent during chat-messaging lockdown or when outgoing addon messages are restricted (Forever 1.60.1: trial accounts cannot send addon messages). Every party member needs Pathwise. Horde and Alliance cannot group on Forever. |
| Reading party members' quest logs without the addon | Partly possible, not used yet | `C_QuestLog.IsUnitOnQuest` exists and could show which members are on a quest. Objective counts still need the addon on their side. |
| Checkbox options | Not used | `UICheckButtonTemplate` is not in Forever's Mainline `SharedUIPanelTemplates.xml`, so the options panel uses toggle buttons. |
| Slash commands with a gamepad | Limited (community report) | Typing an addon slash command in chat with the gamepad UI active can block gamepad input. Everything is also available from the guide window and Settings panel. |
| Listing every recipe of a profession | Not available | Retail's `C_TradeSkillUI.GetAllRecipeIDs` and `GetFilteredRecipeIDs` are not in Forever's documentation. Pathwise knows the recipes of its profession routes and data packs and asks the client about those, one by one. |
| Recipe state for a closed profession | Limited | `GetRecipeInfo` answers for the profession whose window is open. Pathwise reads recipes only while that profession's window is open and caches the result; it never marks a recipe unlearned from another profession's window. |
| Live skill-up chance | Partly | The client gives a difficulty color, not a percentage, and only for your current skill. The planner labels every chance with its source. See MATERIAL_PLANNER.md. |
| Skill thresholds, rank caps, trainer coordinates | Not available from the API | No API returns them. Data packs carry them, marked verified or not. The client's current cap from `GetProfessionInfo` always wins. |
| Sending feedback from the game | Not possible | Addons cannot send email or make web requests, and must not hold credentials. The Feedback Center prepares text for the player to copy into Discord or an email. |
| Crafting, buying, selling, destroying or disenchanting from the planner | Deliberately not done | Pathwise only reads. Crafting and disenchanting are protected player actions in any case. |

## Content gaps (data, not API)

- The routes are Polestar's (1-60, every starting race including Forever's Skyborne
  and Zephras Isle); Pathwise has not walked most of them on Forever yet. Places come
  from QuestieDB's Forever data, which marks a handful as unverified (docs/DATA.md).
- The Skyborne races are known to the data by race IDs 95 and 96 (QuestieDB);
  routes name the race "Skyborne", as Polestar does. Not yet checked against
  `UnitRace()` in game.
- QuestieDB's dynamic corrections (per character, per faction) are not applied;
  a few quests may differ by faction because of it (docs/DATA.md).
- Forever changed Enchanting (Mote of Magic, renamed enchants, new reagent lists).
  The profession routes and the starter data follow Forever; 2004-era data cannot be
  reused.

## Re-verifying on a new build

```sh
# list Forever API doc files and check a function
curl -s https://api.github.com/repos/Gethe/wow-ui-source/branches/forever | grep message
curl -s https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua | grep 'Name = "IsOnQuest"'
```

In game: `/run print((select(4, GetBuildInfo())))` prints the interface number.

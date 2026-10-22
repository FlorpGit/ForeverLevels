# Forever API research

This file records what ForeverLevels relies on, where each piece was verified,
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
  picks the TOC for this flavor. ForeverLevels ships an identical `ForeverLevels.toc`
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
| Map + position | `C_Map.GetBestMapForUnit`, `GetMapInfo`, `GetMapChildrenInfo`, `GetPlayerMapPosition`, `GetWorldPosFromMapPos`, `Enum.UIMapType` | MapDocumentation |
| Native waypoint | `C_Map.CanSetUserWaypointOnMap`, `SetUserWaypoint`, `HasUserWaypoint`, `ClearUserWaypoint`, `UiMapPoint.CreateFromCoordinates`, `C_SuperTrack.SetSuperTrackedUserWaypoint` | Map / SuperTrackManager docs, `Blizzard_ObjectAPI/Mainline/UiMapPoint.lua` |
| Arrow direction | `GetPlayerFacing()` (returns a nilable number) | PlayerScriptDocumentation |
| Arrow art | atlas `Navigation-Tracked-Arrow`, `C_Texture.GetAtlasInfo` | `Blizzard_QuestNavigation/SuperTrackedFrame.xml` |
| Party sync | `C_ChatInfo.RegisterAddonMessagePrefix`, `SendAddonMessage`, `InChatMessagingLockdown`, `AreOutgoingAddonChatMessagesRestricted`, `CHAT_MSG_ADDON`, `IsInGroup`, `IsInRaid`, `Ambiguate`, `GROUP_ROSTER_UPDATE` | ChatInfoDocumentation, `ChatFrameUtil.lua` |
| Secret values | `issecretvalue` | FrameScriptDocumentation |
| Options panel | `Settings.RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory` | `Blizzard_Settings_Shared/Blizzard_Settings.lua` |
| Misc | `IsShiftKeyDown`, `GetBuildInfo`, `UIPanelButtonTemplate`, `UIPanelCloseButton`, `BackdropTemplate` | Input / Build docs, `SharedUIPanelTemplates.xml`, `Backdrop.lua` |

## Features the Forever API does not support (or limits)

Things I wanted but the current API does not allow, and what the addon does instead.

| Wanted feature | Status | Why / what ForeverLevels does instead |
|---|---|---|
| Arrow direction inside dungeons, raids and battlegrounds | Not supported | `GetPlayerFacing()` returns nil in instances, and `C_Map.GetPlayerMapPosition` returns nil there too. The arrow hides its pointer and shows distance when it can, or nothing. |
| Walking paths / pathfinding | Not supported | No navmesh or route API. `C_Navigation` only reports distance and screen position of the target Blizzard is super-tracking. The arrow points in a straight line. (Some community addons ship their own walking maps built from client data; that is out of scope here.) |
| Looking up NPC or object positions | Not supported | No API returns where an NPC stands. Coordinates must be written into routes or recorded with `/fl record`. Forever also hides the server/spawn part of creature GUIDs (1.60.1 beta 5), so spawns cannot be identified either. |
| Forever uiMapIDs | Not documented | Forever's map IDs are not public. Routes name zones in English and the addon finds the ID through `C_Map.GetMapChildrenInfo` at runtime. Non-English clients will need `map = <id>` (or `route.maps`) in route files; `/fl where` prints the ID. |
| Talking to NPCs or accepting quests remotely | Not supported | Automation only answers dialogs the player opened by clicking an NPC. Interacting with units is protected. |
| Picking between quest rewards | Deliberately not automated | ForeverLevels stops and asks. Quests that cost money are never auto-completed. |
| Setting the hearthstone, taking flight paths, training | Not automated | These are confirmations or protected actions. Routes show them as manual notes. |
| Using quest items from the guide | Not in MVP | `UseItem`-style actions are protected; a future version could add a secure action button (out of combat only). |
| Party sync during encounters or for trial accounts | Limited | Nothing is sent during chat-messaging lockdown or when outgoing addon messages are restricted (Forever 1.60.1: trial accounts cannot send addon messages). Every party member needs ForeverLevels. Horde and Alliance cannot group on Forever. |
| Reading party members' quest logs without the addon | Partly possible, not used yet | `C_QuestLog.IsUnitOnQuest` exists and could show which members are on a quest. Objective counts still need the addon on their side. |
| Checkbox options | Not used | `UICheckButtonTemplate` is not in Forever's Mainline `SharedUIPanelTemplates.xml`, so the options panel uses toggle buttons. |
| Slash commands with a gamepad | Limited (community report) | Typing an addon slash command in chat with the gamepad UI active can block gamepad input. Everything is also available from the guide window and Settings panel. |

## Content gaps (data, not API)

- Forever adds new quests in the Undead starting zones (including an Undead Paladin
  path) whose IDs are not publicly documented yet. The bundled draft does not include them.
- The new Skyborne Elf race's `UnitRace()` token is unknown. The validator accepts
  unknown race tokens with a warning so routes can add it once known.
- Forever's new 30-60 zones and nine new dungeons are not in the data.
- Bundled coordinates are approximate and have not been walked on Forever yet.

## Re-verifying on a new build

```sh
# list Forever API doc files and check a function
curl -s https://api.github.com/repos/Gethe/wow-ui-source/branches/forever | grep message
curl -s https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua | grep 'Name = "IsOnQuest"'
```

In game: `/run print((select(4, GetBuildInfo())))` prints the interface number.

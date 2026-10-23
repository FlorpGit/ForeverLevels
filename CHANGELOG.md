# Changelog

All notable changes to Pathwise. Versions follow `major.minor.patch`; set a
new one with `npm run set-version -- <x.y.z>`, which turns "Unreleased" into
that version's section.

## Unreleased

Version 0.3.0-dev. Pathwise was two projects with one name: florp's
ForeverLevels/Pathwise (github.com/FlorpGit/Pathwise, released up to
0.2.0-alpha.3, history below) and leight_nn's Pathwise
(github.com/pathwise-nn/Pathwise, not released). They are now one repository
and one download, with both histories. leight_nn's guide engine, data, routes and
interface are the base; what only the ForeverLevels builds had is carried over,
and where both had the same thing they are joined.

### One project from two
- Pathwise UI: the windows, panels, looks, arrow, map and minimap pins,
  minimap buttons, key bindings and media are an addon of their own
  (`Pathwise_UI`), in the same download beside Pathwise, Pathwise Gear and
  Pathwise Bags. Pathwise runs without it (no windows, and it says so once
  at login); Gear and Bags need it. Its files work in Pathwise's namespace,
  so nothing about how the windows behave changed.
- Auto accept and turn-in (from ForeverLevels): the route's quests are
  accepted and handed in at their NPC, on by default; Shift skips it once,
  each part can be turned off (Settings > Quests at their NPC, `/pw auto`).
  Never a reward choice, never a quest that costs gold.
- Party sync (from ForeverLevels), off by default: group members see each
  other's step and quest counts in the guide window. Same wire format, so the
  ForeverLevels builds still see Pathwise and the other way round.
- The game's own map pin and in-world marker follow the arrow (from
  ForeverLevels), on by default (`/pw waypoint`).
- The recorder (from ForeverLevels) logs quests with their NPC and place,
  and trainers; `tools/recorder_to_route.lua` turns the log into a route.
- One Feedback Center: leight's Report this step and florp's Feedback
  Center. Step reports with nine kinds of problem, bug reports and
  suggestions; the step's goals with their status and quest log state; drafts
  that survive a reload; character details and diagnostics only when turned
  on; sent by the player to Discord or by email, never by the game.
- One profession system: Polestar's twelve profession routes are the plan;
  recipe facts from the routes, checked data packs
  (`Pathwise.RegisterProfessionData`, with the Tailoring and Enchanting
  starter data) and the profession window meet in one place; the planner
  adds skill-up chances, crafts to a target, materials and intermediates, the
  next rank and recipes to learn; one detour card offers training on the way,
  crafting what the bags make, or the profession you follow (Go, Later,
  Skip); material reminders; `/pw track`, `/pw reminders`, `/pw detour`.
- Looks: Modern (leight's Signature look) and Classic (the game's dialogs,
  gold headings, red buttons) for every window, panel, the arrow, minimap
  buttons, Pathwise Gear and Pathwise Bags; Settings > Look or `/pw style`,
  after a reload. They replace the ForeverLevels window styles; a third look
  can be added.
- Esc > Options > AddOns > Pathwise: a page leading into Pathwise's settings.
- The `ForeverLevels` name, `/fl`, `/foreverlevels` and
  `Pathwise:RegisterRoute()` still work. Routes in the old ForeverLevels format
  are refused with a pointer to the route format; the example route pack is
  rewritten. Settings are new (`PathwiseSettings`); progress is read from the
  quest log.
- The draft Undead 1-10 routes and the hand-written dungeon list of the
  ForeverLevels builds are gone: Polestar's routes and QuestieDB's dungeons
  cover them.
- Fixed: the profession window scan asked for a list of recipes Forever's
  client does not give (`GetAllRecipeIDs`) and would never have read one; it
  now asks about each recipe Pathwise knows.
- CI runs the tests on Lua 5.1 and 5.4, checks every route and data pack,
  lints the addon apart from the test stub, and builds the release zip, which
  now carries NOTICE.md in every addon folder.
- Licence and credits: code GPL-3.0-only with NOTICE.md's additional terms;
  THIRD_PARTY.md lists Polestar, QuestieDB, Inter, Wowhead and Blizzard's
  tables (CREDITS.md is folded into it); SECURITY.md says exactly what
  Pathwise does for the player.

### Leveling
- Leveling routes from 1 to 60 for every starting race on both sides
  (Durotar, Mulgore, Tirisfal Glades, Zephras Isle; Elwynn Forest, Dun Morogh,
  Teldrassil, Zephras Isle), handing over to the next zone by themselves.
- The guide follows the quest log: steps tick off as quests are taken,
  completed and handed in; class, race and faction steps show only to those
  characters; a quest not offered yet never holds the route.
- Skip a quest (or a quest and its follow-ups) and pick one nearby instead;
  the route resumes after it.
- Zones for your level, and a Routes panel with leveling, class quest,
  reputation, mount, pet and exploration guides.

### Pathwise Gear (new addon, part of the Pathwise suite)
- Upgrade advice in gold: a line on item tooltips ("+12.4% upgrade · Head"),
  an arrow on bag items that are upgrades, and the best quest reward.
- Scores on its own, needing no other addon: Pathwise's weights for all 27
  specs, ordered as the Icy Veins and Mobalytics Forever guides advise and
  spaced by Forever's stat rules (Warcraft Tavern). Picks the spec from your
  talents, or you choose. Shows each spec's stat priority.
- Forever's stats: shared crit for casters and melee, attack power that
  counts for ranged, Haste and Expertise (their names on items are not yet
  checked in game).
- Optional custom weights you paste in ("Intellect=1.2, Stamina=0.5").
- Best in Slot (Level): slot by slot, the best item this character can
  get by now (or a few levels ahead), where it comes from (quest, dungeon
  and boss, monster, vendor, world drop) and whether you have it. Click a
  slot: the arrow leads to the quest giver, dungeon entrance, monster or
  vendor. Worked out in game from the item stats the game gives and
  QuestieDB's Forever data; no BiS site's lists are used.
- Crafted gear in the list (1,576 weapons and armour from Forever's recipes):
  "Craft it: Tailoring 110", the recipe and where it is sold or drops (the
  arrow leads there), or "Crafted: ... (Auction House or a crafter)" for
  someone else's craft. Bind-on-pickup crafts count only for their crafter.
  Choose all crafts, only your professions', or none. Season of Discovery
  recipes Forever's files hold (99 make gear) are shown, marked "found in
  Forever, not confirmed", and can be hidden.
- Picking up a best-in-slot item for your level, or for the higher level it
  needs, is announced on screen with a sound and a chat line; such items
  get a gold star in the bags and a "Best in slot" tooltip line.
- Knows what each class can wear and wield, two-handers against both hands,
  rings and trinkets against the weaker one.

### Pathwise Bags (new addon, part of the Pathwise suite)
- One bag window in the Pathwise look (green), opened by your bag key: items
  grouped by what they are to you (Quest, Upgrades, Equipment, Consumables,
  Professions, Other, Junk) or as one grid; search by name, quest, upgrade or
  junk; the game's sort; free slots and money. Uses the game's own item
  buttons, so using, selling and dragging work as usual. Can be turned off.
- Markers on items: needed for a quest (in your log or later), material for
  your profession route, Pathwise Gear upgrade or best in slot, kept by you,
  can be sold.
- Selling junk: a "Sell junk" button on the vendor window with the count and
  gold (or sell on its own): greys and items you mark; optionally bound gear
  you can't use or is worse. Never what you keep, quest items you need,
  profession materials, upgrades.
- Bag space: a warning when bags are nearly full, with what to let go first.
- Mark items: keep (never sold) or junk, from the bag window.

### Maps and dungeons
- World map pins for the step shown (the arrow's target, the other goals,
  and where an objective's monsters are) and minimap pins that follow zoom,
  indoor scale and a rotating minimap; the arrow's target stays on the rim.
  Pathwise only reads the map, so it never taints it.
- Dungeons and raids for your level (29, Forever's own included): levels
  from the monsters inside, their quests with what stands for each, and the
  nearest entrance with an arrow to it; entrance pins on the world map.

### Professions
- Profession routes from 1 to 300 for all twelve professions, followed
  beside the leveling route: the next profession step shows in the guide
  window when it is on the way (Speed, Balanced or Crafting).
- Professions: a list of yours with skill and what is next; click one for its
  page. Professions dashboard: skill, where the guide stands, the best craft now and
  how many the bags make, materials for this rank, disenchanting, and the
  Tailoring + Enchanting tip. Advice only.

### No commands needed
- A minimap button (guide, settings; drag to move), key bindings in the
  game's Key Bindings menu, and a Waypoint & tools panel (a waypoint by
  coordinates, where you are, what the arrow sees). Every command's job is in
  the menus; the commands still work.

### Interface
- The Pathwise Signature look: guide window with full and compact modes,
  waypoint arrow, settings panel with sliders and exact values, window size
  50-150%, About, and Report this step (now part of the Feedback Center).

### Data and credits
- Quest facts from QuestieDB's Forever data; routes adapted from Polestar
  (both GPL-3.0; see THIRD_PARTY.md).

### Suite
- Accent colour (Settings > Colour): Pathwise blue, your class colour, or one
  you type; "Whole suite in this colour" puts Gear, Bags and the rest in it
  too. Pathwise UI, when installed, keeps the same accent.
- Each suite addon has its own minimap button in its colour (Pathwise Gear:
  gold arrow, Pathwise Bags: green bag), placed apart, draggable, each with
  its own show/hide switch; its settings open beside it.
- Back in the side panel: from a suite addon's settings to where you came
  from, or to Pathwise's settings.

### Fixed
- Map pins for an objective's monsters had lost the monster's name.
- Settings, Professions and the other panels drew at the top left of the
  screen with "anchor family connection" errors: the panel's scrolling area
  was anchored to its own contents.
- Sliders swung between their ends while dragged ("Window size" moved the
  panel under the pointer): the panel now holds still while a slider is
  dragged, and the value follows the pointer step by step.
- Count sliders (bag window width, free slots) showed "1200 %".
- Setting labels ran under their buttons; they now wrap.
- The bag key opened the Pathwise bag window and closed it at once.
- An error at login on Forever: Pathwise listened for a Classic event name
  (LEARNED_SPELL_IN_TAB); it uses Forever's (LEARNED_SPELL_IN_SKILL_LINE)
  and skips any event the client does not have. Tests now reject events
  Forever lacks.

### Not verified in game yet
- Reading recipes from the profession window, and the Enchanting skill needed
  per item level (Classic's table, shown with "≈").
- Most routes past the Tirisfal Glades start.
- From the merge: auto accept and turn-in against Forever's quest dialogs,
  the game's map pin and marker beside the arrow, party sync between two
  players, the recorder's NPC names, the Classic look's border art and
  templates on Forever, the page in the game's Settings window, and the
  planner's numbers once the profession window has been read.

## History of the ForeverLevels / Pathwise builds (FlorpGit/Pathwise)

### 0.2.0-alpha.4 (unreleased)

- New default window style "Pathwise" in the logo's colors (blue-black background, silver frame and headings, ice-blue titles, steel-blue buttons), used by the guide, detour banner, dashboard, Feedback Center and arrow label. Classic, tooltip and minimal remain (`/pathwise style`). Settings saved by earlier builds keep the style they had; switch with `/pathwise style pathwise`.

### 0.2.0-alpha.3 - Phase 2 test build (pre-release, 2026-10-22)

- Renamed to "Pathwise: Leveling Guide & Professions". The addon folder and TOC files are now `Pathwise`; the GitHub repository is FlorpGit/Pathwise. Internal names (`ForeverLevelsDB`, the `ForeverLevels` global, `/fl`, the sync prefix) are unchanged. Testers of earlier builds: see Compatibility in the README.

- License change: code is now GPL-3.0-only (Copyright The Pathwise Authors), with an additional permission letting data-only route and profession packs use any license, and a section 7(e) term reserving the Pathwise names. Bundled guide data stays CC BY-SA 4.0. Earlier ForeverLevels versions remain MIT. Adds NOTICE.md, TRADEMARKS.md and CREDITS.md.
- Renamed to Pathwise ("Every quest. Every craft. Every level.", by leight_nn & florp). `/pathwise` is the main command; `/fl`, `/foreverlevels`, `ForeverLevels:RegisterRoute()`, the addon folder and saved progress all keep working. About section in the options panel.
- Profession tracking: detects professions, skill and cap; reads learned recipes, difficulty and the client's reagent lists while a profession window is open; counts materials in bags (bank optional).
- Profession data registry (`Pathwise:RegisterProfessionData`) with validation and verification flags. Starter Tailoring and Enchanting data checked against Wowhead's Forever database; unverified values are labeled.
- Material planner: next craft, expected crafts with the source of every estimate, owned and missing materials, intermediate expansion, reservations across steps, one-time material reminders.
- Optional profession detours under the guide window (Go, Later, Skip; Done, Cancel). They never change route progress, step numbers or Back/Next; an active detour with coordinates temporarily takes over the arrow.
- Profession dashboard in all three window styles, with profession settings.
- SavedVariables version 2 with an in-place upgrade from version 1.
- Recorder also logs trainer positions.
- Example profession data pack; the offline validator checks profession data too.
- Feedback Center (`/pathwise feedback`) for bug reports, suggestions and guide step reports, with a "Report this step" ticket button next to Back that fills in the current step. Reports are prepared as copyable text for pathwise.nn@gmail.com and never sent automatically. Character details and diagnostics are opt-in. Drafts are saved per step. SavedVariables version 3.

### 0.1.0 - MVP (unreleased)

- Classic window style (dialog border used by the classic UI) as the default, plus tooltip and minimal styles. `/fl style` or the options panel.

- Movable step-by-step guide window with live quest objectives, Back/Next, lock and scale.
- Quest detection: accept, objectives complete, turn-in and level goals; auto-advance; skip; fast-forward on login.
- Automatic accept and turn-in for route quests (gossip, greeting and quest dialogs), Shift to pause, no reward auto-pick.
- Waypoints: Blizzard map pin + in-world marker (super-tracked user waypoint) and a ForeverLevels direction arrow with distance.
- Class- and race-filtered steps and goals; per-class step text.
- Route registry with validation, route chaining and a public `ForeverLevels:RegisterRoute()` for community route addons.
- Dungeon suggestions by level.
- Optional party progress sync over addon messages, respecting Forever's lockdown rules.
- SavedVariables: per-character route progress, account-wide settings.
- Recorder for route authors plus offline tools (`validate_routes.lua`, `recorder_to_route.lua`).
- Draft routes: Undead 1-6 Deathknell, Undead 6-10 Brill (coordinates not yet verified on Forever).
- Offline test suite against a WoW API stub; CI on Lua 5.1 and 5.4.

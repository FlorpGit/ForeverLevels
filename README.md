# Pathwise: Leveling Guide & Professions

Every quest. Every craft. Every level.

Pathwise is an open source leveling and profession guide addon for World of Warcraft:
Forever, made by leight_nn & florp. It tells you what to do next, points an arrow at it,
tracks your quests as you pick them up and hand them in, handles the accept/turn-in
clicks for quests on the route, and plans your professions alongside it.

Code is GPL-3.0, bundled guides are CC BY-SA 4.0. Routes and profession data are written for
this project; nothing is taken from paid guides.

Current state: 0.2.0-alpha.3, a test build. The addon works and has offline tests, but
nothing has been run on the live Forever client yet. The Undead 1-10 route is a draft
(quest IDs correct, coordinates rough), and profession data is a small verified starter
set for Tailoring and Enchanting. If you play with it, please send feedback (see
Contributing below).

Pathwise used to be called ForeverLevels. `/fl` and `ForeverLevels:RegisterRoute()` still
work; see Compatibility.

## Features

Leveling
- Guide window you can move, lock and scale. Shows the current step, quest objectives as they update, notes, and Back/Next buttons. Three looks: classic (the stone dialog border from the old UI, default), tooltip, or minimal.
- Waypoints: puts Blizzard's map pin and in-world marker on the target, plus its own arrow with distance.
- Detects quest accept, objectives done, turn-in and "reach level X" goals. Moves to the next step on its own and skips steps you already did when you log in.
- Accepts and turns in quests that are on the route when you talk to the NPC. Hold Shift to skip that for one NPC. It won't choose between rewards for you or complete quests that cost gold.
- Steps can be limited to certain classes or races, with class specific text (trainer names and so on).
- Dungeon suggestions for your level.
- Party sync (off by default, `/pathwise sync on`) so you can see where your group mates are in the route.
- Routes are separate data files that register themselves, so new routes can be added in this repo or shipped as their own addon.

Professions (new in 0.2)
- Detects your professions, skill and cap, and which recipes you know once you open the profession window.
- Dashboard with the next trainer rank, a crafting plan, materials you have and are missing, and what to gather.
- Material planner that estimates how many crafts a skill range takes and says how sure it is.
- Optional profession detours under the guide window (visit a trainer, craft something you have materials for) that never change your route progress.
- Profession data packs register themselves, so more recipes and professions can be added without changing Pathwise.

Feedback
- Feedback Center for bug reports, suggestions and guide step reports. The ticket button next to Back fills in the current step (route, step, quest IDs, waypoint). Pathwise prepares the text; you copy it and email it to pathwise.nn@gmail.com. Nothing is sent automatically. See [docs/FEEDBACK_SYSTEM.md](docs/FEEDBACK_SYSTEM.md).

Progress is saved per character, settings per account. `/pathwise record` logs where you accept and turn in quests and where trainers stand, and there are scripts to turn that into route files.

Included: Undead 1-6 (Deathknell), then Undead 6-10 (Brill). Tailoring and Enchanting starter data.

## Install

1. Open the [Releases page](https://github.com/FlorpGit/Pathwise/releases) and download `Pathwise-<version>.zip` from the latest release. Not "Source code": that is the whole developer repository.
2. Unzip it into your AddOns folder:
   - live: `World of Warcraft/_forever_/Interface/AddOns/`
   - beta: `World of Warcraft/_classic_beta_/Interface/AddOns/`

   You want `Interface/AddOns/Pathwise/Pathwise_Forever.toc`, not `AddOns/Pathwise-x/Pathwise/...`.
3. Restart the game completely. A `/reload` won't load a newly added addon.
4. Check that Pathwise is enabled in the AddOns list on the character screen.
5. Log in on an Undead character and the guide shows up on the right side of the screen. Open each profession window once so Pathwise can read your recipes.

There are example packs in `examples/` (a route pack and a profession data pack) if you want to see how separate add-on data works. Install them the same way.

## Commands

`/fl` works as a short alias for all of these.

| Command | What it does |
|---|---|
| `/pathwise` | Show/hide the guide |
| `/pathwise next`, `/pathwise back` | Change step (`skip` is the same as `next`) |
| `/pathwise routes`, `/pathwise route <id>` | List routes, switch route |
| `/pathwise reset` | Start the current route over |
| `/pathwise lock`, `/pathwise unlock`, `/pathwise scale 1.2` | Window position and size |
| `/pathwise style [classic\|tooltip\|minimal]` | Window look |
| `/pathwise arrow`, `waypoint`, `auto`, `sync`, `dungeons` `[on\|off]` | Turn features on or off |
| `/pathwise feedback` | Report a bug or make a suggestion |
| `/pathwise report` | Report a problem with the current guide step |
| `/pathwise prof` | Profession dashboard |
| `/pathwise tracking`, `/pathwise reminders` `[on\|off]` | Profession tracking, material reminders |
| `/pathwise track <profession> [on\|off]` | Show or hide one profession |
| `/pathwise detour go\|later\|skip\|done\|cancel\|on\|off` | Profession detours |
| `/pathwise record [on\|off]`, `/pathwise recorder [clear]`, `/pathwise where` | Tools for writing routes |
| `/pathwise options` | Settings panel (Esc > Options > AddOns) |

## Compatibility

| Kept | Why |
|---|---|
| `ForeverLevelsDB`, `ForeverLevelsCharDB` | Saved data keeps its format; older data is upgraded in place |
| `/fl`, `/foreverlevels` | Same handler as `/pathwise` |
| `ForeverLevels:RegisterRoute()` | `Pathwise` and `ForeverLevels` are the same table, so both work, as does `Pathwise:RegisterRoute()` |
| Party sync prefix | Players on older versions still see each other |

Test builds before 0.2.0-alpha.3 used the folder name `ForeverLevels`. If you tested one,
delete that folder, install the `Pathwise` folder, and to keep your progress rename
`WTF/Account/<ACCOUNT>/SavedVariables/ForeverLevels.lua` (and the same file under each
character's `SavedVariables` folder) to `Pathwise.lua` while the game is closed.

## Forever API notes

Forever uses the modern retail-style API (C_QuestLog, C_Map, C_TradeSkillUI, etc.) with
the same addon restrictions as Midnight, not the Classic Era API. I checked every
function the addon uses against Blizzard's UI source for build 1.60.1.70450. The list,
with sources, is in [docs/API_RESEARCH.md](docs/API_RESEARCH.md), along with the things
the API doesn't allow. The main ones:

- The arrow can't show direction in dungeons/raids, `GetPlayerFacing()` returns nil there.
- No pathfinding, the arrow points in a straight line.
- No way to look up NPC positions, so coordinates are part of the data.
- Forever's map IDs aren't public. Zones are looked up by English name, so non-English clients need map IDs in the route files.
- Party sync can't send during chat lockdown, and trial accounts can't send addon messages at all.
- Talking to NPCs, picking rewards, setting your hearthstone and taking flight paths can't be automated.
- There's no list of all recipes, and recipe details are only available while that profession's window is open.

## Layout

```
Pathwise/                 the addon folder (this is what you install)
  Pathwise_Forever.toc    Interface 16001, Pathwise.toc is an identical fallback
  Core/                        engine, quests, waypoints, auto quest, sync, professions, planner, detours
  UI/                          guide window, arrow, detour banner, profession dashboard, options
  Guides/                      route, dungeon and profession data (CC BY-SA 4.0)
examples/                      example route pack and profession data pack
tools/                         data validator, recorder log converter
tests/                         offline tests with a fake WoW API
docs/                          API notes, data formats, professions, in-game test checklist
```

## Development

You need a Lua interpreter (5.1 like the game, or newer).

```sh
lua tests/run.lua
lua tools/validate_routes.lua
```

CI runs the tests on Lua 5.1 and 5.4 and runs luacheck. The in-game test list is in
[docs/TEST_CHECKLIST.md](docs/TEST_CHECKLIST.md).

### Writing routes and profession data

Routes: [docs/ROUTE_FORMAT.md](docs/ROUTE_FORMAT.md). Profession data:
[docs/PROFESSION_DATA_FORMAT.md](docs/PROFESSION_DATA_FORMAT.md). Both ship as a small
addon with `## Dependencies: Pathwise` and a file like this:

```lua
Pathwise:RegisterRoute({
	id = "you.horde.troll.01", title = "Troll 1-6", author = "You", license = "CC BY-SA 4.0",
	faction = "Horde", races = { "Troll" }, levels = { 1, 6 }, zone = "Durotar",
	steps = {
		{ id = "start", title = "First quest", text = "Talk to ...", x = 42.0, y = 68.0, accept = { 1234 } },
	},
})
```

More about professions: [docs/PROFESSIONS.md](docs/PROFESSIONS.md),
[docs/MATERIAL_PLANNER.md](docs/MATERIAL_PLANNER.md),
[docs/PROFESSION_DETOURS.md](docs/PROFESSION_DETOURS.md).

## Contributing

Found a wrong step? Click the ticket button next to Back and email the report to
pathwise.nn@gmail.com.

What helps most right now is someone playing on Forever with `/pathwise record on`,
opening their profession windows, and sending their SavedVariables file, or a PR fixing
coordinates and profession data. See [CONTRIBUTING.md](CONTRIBUTING.md). Routes and data
have to be your own work or facts you checked.

## License

Copyright (C) 2026 The Pathwise Authors (leight_nn and florp, and contributors).

- Code: [GPL-3.0-only](LICENSE). Modified versions you share must stay open source under the same license. See [NOTICE.md](NOTICE.md).
- Route and profession data in `Pathwise/Guides/`: [CC BY-SA 4.0](Pathwise/Guides/LICENSE.md)
- Route and profession packs that only contain data and use the registration functions can use any license (an additional permission in [NOTICE.md](NOTICE.md)). Packs that copy Pathwise code must be GPL-3.0.
- The name "Pathwise" and the Pathwise family of add-ons are not covered by these licenses. See [TRADEMARKS.md](TRADEMARKS.md).
- Versions published before this change (as ForeverLevels) were MIT and stay MIT for anyone who got them then.
- Sources used for research: [CREDITS.md](CREDITS.md).

World of Warcraft is a trademark of Blizzard Entertainment. This is a fan project and
isn't affiliated with or endorsed by Blizzard.

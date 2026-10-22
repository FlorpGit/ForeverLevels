# ForeverLevels

Open source leveling guide addon for World of Warcraft: Forever. It tells you what to
do next, points an arrow at it, tracks your quests as you pick them up and hand them
in, and handles the accept/turn-in clicks for quests on the route.

Code is MIT, routes are CC BY-SA 4.0. The routes are written from scratch for this
project, nothing is taken from paid guides.

Current state: version 0.1.0. The addon itself works and has offline tests, but the
Undead 1-10 route is still a draft. Quest IDs are correct, coordinates are rough and
haven't been checked on the live Forever client yet. If you play through it, please
send feedback (see Contributing below).

## Features

- Guide window you can move, lock and scale. Shows the current step, quest objectives as they update, notes, and Back/Next buttons.
- Waypoints: puts Blizzard's map pin and in-world marker on the target, plus its own arrow with distance.
- Detects quest accept, objectives done, turn-in and "reach level X" goals. Moves to the next step on its own and skips steps you already did when you log in.
- Accepts and turns in quests that are on the route when you talk to the NPC. Hold Shift to skip that for one NPC. It won't choose between rewards for you or complete quests that cost gold.
- Steps can be limited to certain classes or races, with class specific text (trainer names and so on).
- Dungeon suggestions for your level.
- Party sync (off by default, `/fl sync on`) so you can see where your group mates are in the route.
- Progress is saved per character, settings per account.
- Routes are separate data files that register themselves, so new routes can be added in this repo or shipped as their own addon.
- `/fl record` logs where you accept and turn in quests, and there are scripts to turn that into a route file.

Included routes: Undead 1-6 (Deathknell), then Undead 6-10 (Brill).

## Install

1. Download the repo (Code > Download ZIP) and unzip it.
2. Copy the inner `ForeverLevels` folder, the one with `ForeverLevels_Forever.toc` in it, to:
   - live: `World of Warcraft/_forever_/Interface/AddOns/`
   - beta: `World of Warcraft/_classic_beta_/Interface/AddOns/`

   You want `Interface/AddOns/ForeverLevels/ForeverLevels_Forever.toc`, not `AddOns/ForeverLevels-main/ForeverLevels/...`.
3. Restart the game completely. A `/reload` won't load a newly added addon.
4. Check that ForeverLevels is enabled in the AddOns list on the character screen.
5. Log in on an Undead character and the guide shows up on the right side of the screen.

There's also an example route pack in `examples/ForeverLevels_ExampleRoute` if you want to see how a separate route addon works. Install it the same way.

## Commands

| Command | What it does |
|---|---|
| `/fl` | Show/hide the guide |
| `/fl next`, `/fl back` | Change step (`skip` is the same as `next`) |
| `/fl routes`, `/fl route <id>` | List routes, switch route |
| `/fl reset` | Start the current route over |
| `/fl lock`, `/fl unlock`, `/fl scale 1.2` | Window position and size |
| `/fl arrow`, `/fl waypoint`, `/fl auto`, `/fl sync`, `/fl dungeons` `[on\|off]` | Turn features on or off |
| `/fl record [on\|off]`, `/fl recorder [clear]`, `/fl where` | Tools for writing routes |
| `/fl options` | Settings panel (Esc > Options > AddOns) |

## Forever API notes

Forever uses the modern retail-style API (C_QuestLog, C_Map, etc.) with the same addon
restrictions as Midnight, not the Classic Era API. I checked every function the addon
uses against Blizzard's UI source for build 1.60.1.70450. The list, with sources, is in
[docs/API_RESEARCH.md](docs/API_RESEARCH.md), along with the things the API doesn't
allow. The main ones:

- The arrow can't show direction in dungeons/raids, `GetPlayerFacing()` returns nil there.
- No pathfinding, the arrow points in a straight line.
- No way to look up NPC positions, so coordinates are part of the route data.
- Forever's map IDs aren't public. Zones are looked up by English name, so non-English clients need map IDs in the route files.
- Party sync can't send during chat lockdown, and trial accounts can't send addon messages at all.
- Talking to NPCs, picking rewards, setting your hearthstone and taking flight paths can't be automated.

## Layout

```
ForeverLevels/                 the addon folder (this is what you install)
  ForeverLevels_Forever.toc    Interface 16001, ForeverLevels.toc is an identical fallback
  Core/                        engine, quest tracking, waypoints, auto quest, sync, commands
  UI/                          guide window, arrow, options
  Guides/                      route and dungeon data (CC BY-SA 4.0)
examples/                      example route pack
tools/                         route validator, recorder log converter
tests/                         offline tests with a fake WoW API
docs/                          API notes, route format, in-game test checklist
```

## Development

You need a Lua interpreter (5.1 like the game, or newer).

```sh
lua tests/run.lua
lua tools/validate_routes.lua
```

CI runs the tests on Lua 5.1 and 5.4 and runs luacheck. The in-game test list is in
[docs/TEST_CHECKLIST.md](docs/TEST_CHECKLIST.md).

### Writing routes

The format is in [docs/ROUTE_FORMAT.md](docs/ROUTE_FORMAT.md). A route pack is just an
addon with `## Dependencies: ForeverLevels` and a file like this:

```lua
ForeverLevels:RegisterRoute({
	id = "you.horde.troll.01", title = "Troll 1-6", author = "You", license = "CC BY-SA 4.0",
	faction = "Horde", races = { "Troll" }, levels = { 1, 6 }, zone = "Durotar",
	steps = {
		{ id = "start", title = "First quest", text = "Talk to ...", x = 42.0, y = 68.0, accept = { 1234 } },
	},
})
```

## Contributing

What helps most right now is someone playing the Undead route on Forever with
`/fl record on` and sending me their SavedVariables file, or a PR fixing coordinates.
See [CONTRIBUTING.md](CONTRIBUTING.md). Routes have to be your own work.

## License

- Code: [MIT](LICENSE)
- Route data in `ForeverLevels/Guides/`: [CC BY-SA 4.0](ForeverLevels/Guides/LICENSE.md)
- Route packs from other people use whatever license they put in the route's `license` field

World of Warcraft is a trademark of Blizzard Entertainment. This is a fan project and
isn't affiliated with or endorsed by Blizzard.

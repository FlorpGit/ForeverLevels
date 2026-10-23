# Contributing to Pathwise

Thanks for helping. Pathwise is a free, open-source leveling and profession
companion for World of Warcraft: Forever, under GPL-3.0 (see NOTICE.md for the
additional terms).

## The rules that matter most

- **Never invent game facts.** Quest IDs, NPC IDs, item IDs, coordinates,
  recipes and client APIs come from the data (QuestieDB), the routes
  (Polestar), Blizzard's Forever UI source (Gethe/wow-ui-source, `forever`
  branch), a source that covers Forever (wowhead.com/forever), or what you
  checked in game. If something is not verified, say so in the code, the data's
  `verified` flags and the pull request.
- **Never claim a test passed you did not run,** and never claim something
  works in game unless you checked it in game.
- **Do not copy RestedXP's guides** or any other paid or proprietary guide, nor
  text from sources whose licence does not allow it. Routes and data you write
  must be your own work or facts you checked.
- **Keep credits intact**: THIRD_PARTY.md, NOTICE.md, the headers of generated
  files, and the About panel.

## Set up

You need Lua 5.1 (`lua5.1`, `luac5.1`; the tests also run on 5.4), luacheck
(`luarocks install luacheck`) and Node 24 or newer.

```bash
npm test            # the tests, against a stub of the game client
npm run validate    # every route and profession data pack
npm run lint        # luacheck: the addon folders, then tests and tools
npm run link        # link the addon folders into the game
```

`npm run link` links `Pathwise/`, `Pathwise_Gear/` and `Pathwise_Bags/` into the
game (set `WOW_FOREVER_ADDONS` to your `Interface\AddOns` folder first); `/reload`
in game picks up changes.

## Where things are

| Path | What |
|---|---|
| `Pathwise/Core` | Start-up, settings, commands, the one place client APIs are read (`Compat.lua`), feedback reports |
| `Pathwise/Guide` | Quest facts (`Quests.lua`), the guide engine (`Engine.lua`), auto accept and turn-in, party sync, the recorder, dungeons |
| `Pathwise/Professions` | Recipes from routes, packs and the game (`Recipes.lua`), professions and the window scan, the planner, the detour card |
| `Pathwise/UI`, `Pathwise/Theme`, `Pathwise/Nav` | The guide window, side panels (Settings, Feedback, professions...), the game's Settings page, the looks (`Signature.lua`), the arrow, waypoint and pins |
| `Pathwise/Data/Data.lua` | Generated from QuestieDB: `npm run data` (docs/DATA.md) |
| `Pathwise/Routes/*.lua` | Generated from Polestar: `npm run routes` (tools/port/polestar.lua) |
| `Pathwise/Guides/Professions` | Pathwise's checked starter profession data (CC BY-SA 4.0) |
| `Pathwise_Gear`, `Pathwise_Bags` | The suite addons; they use `Pathwise.Suite` |
| `examples/` | A route pack and a profession data pack to copy |
| `tests/` | Lua tests against a stub of the game client |

Do not edit generated files by hand: change their generator and rebuild.

## Fixing a route

1. In game, open the step and use **Report this step** (the flag): paste the
   report into the issue or pull request.
2. Routes use the format in docs/ROUTE_FORMAT.md (also at the top of
   `Guide/Engine.lua`). Quest goals only need the quest ID; the data fills in
   the rest. `/pw record on` logs where quests and trainers really are, and
   `tools/recorder_to_route.lua` turns that into route goals.
3. Run `npm test` and `npm run validate`, then play the fix.

## Adding profession data

Write a data pack (docs/PROFESSION_DATA_FORMAT.md) or extend the starter data
in `Pathwise/Guides/Professions`. Mark every fact you did not check with
`verified = { ... = false }`, and say where each checked one comes from.

## Feedback without code

Click the flag in the guide window, or `/pw feedback`, and send the report to
Pathwise's Discord (https://discord.gg/hSDjBrG8EK) or pathwise.nn@gmail.com.
What helps most right now is someone playing on Forever with `/pw record on`,
opening their profession windows, and sending their SavedVariables file.

## Pull requests

- One change per pull request, with a line on what players will notice.
- Add a test for behaviour changes (`tests/`).
- Add a line under "Unreleased" in CHANGELOG.md.
- If an AI assistant helped, say which one in the description.

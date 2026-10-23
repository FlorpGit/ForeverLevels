# Pathwise: Leveling Guide & Professions

**Every quest. Every craft. Every level.**

A free, open-source leveling and profession companion for World of Warcraft:
Forever, made by leight_nn & florp. It tells you what to do next, points an
arrow at it, follows your quest log as you pick quests up and hand them in,
accepts and hands in the quests of your route at their NPC, and plans your
professions beside it.

> **Test build (0.3.0-dev).** Everything below works in the offline tests;
> most of it has not been played on the live Forever client yet. If you play
> with it, please send feedback (see [Feedback](#feedback)). What is known not
> to be checked in game is listed at the end of [CHANGELOG.md](CHANGELOG.md).

Pathwise used to be two projects, florp's ForeverLevels/Pathwise and leight_nn's
Pathwise. They are one addon now; [CHANGELOG.md](CHANGELOG.md) says what
came from where.

## What it does

**Leveling, 1 to 60**
- Routes for every starting race on both sides, from your first quest to level
  60, moving on to the next zone by themselves; class quest, reputation, mount,
  pet and exploration guides.
- Follows your quest log: steps tick off as you take, complete and hand in
  quests; class, race and faction steps show only to those characters.
- Accepts and hands in your route's quests when you talk to their NPC. Hold
  Shift to skip it once. It never chooses a reward or pays gold.
- Don't want a quest? Skip it (or its whole chain) and pick one nearby
  instead; the route picks up again after it. Zones for your level.
- A waypoint arrow with the distance in yards, the game's own map pin and
  in-world marker at the same place, and pins on the world map and minimap.
- Dungeons and raids for your level, their quests and entrances.
- Party sync (off by default): your group sees your step and quest counts.

**Professions**
- Guides from 1 to 300 for all twelve professions, followed beside your route.
- One detour card under the guide's step: train your next rank at a trainer
  on the way, craft what your bags make now, or the next step of the
  profession you follow. Go points the arrow there, Later waits for your route
  to move on, the cross skips it.
- A page per profession: the best craft now with its skill-up chance and the
  crafts to your target, materials (and what a missing one is made from), the
  next rank and what it asks, recipes to learn, disenchanting.
- Recipe data from the routes, checked data packs and your own profession
  window; data packs from other addons can add more.

**Pathwise Gear and Pathwise Bags** (separate folders in the same download)
- Gear: upgrade advice for your spec, stat priority, Best in Slot (Level),
  the best quest reward. Bags: one bag window, keep and sell markers, junk
  selling, bag space help. Switch either off in the AddOns list.

**Looks**: Modern (dark, flat, ice blue) or Classic (the game's own dialogs,
gold headings, red buttons), for every Pathwise window. Settings > Look.

## Install

1. Download `Pathwise-<version>.zip` from the
   [Releases page](https://github.com/FlorpGit/Pathwise/releases) (not
   "Source code", which is the whole developer repository).
2. Unzip it into your AddOns folder:
   - live: `World of Warcraft/_forever_/Interface/AddOns/`
   - beta: `World of Warcraft/_classic_beta_/Interface/AddOns/`

   You want `Interface/AddOns/Pathwise/Pathwise_Forever.toc` (and
   `Pathwise_Gear/`, `Pathwise_Bags/` beside it), not an extra folder level.
3. Restart the game completely: `/reload` does not load a new addon.
4. Check that Pathwise is enabled in the AddOns list on the character screen.
5. Open each profession window once so Pathwise can read your recipes.

## Using it

Everything is in Pathwise's own menus:
- **Minimap button**: click to show or hide the guide, right-click for
  Settings, drag to move it.
- **Guide window**: Dungeons, Professions, Zones, Settings, compact mode;
  the footer has Back, Skip, Report this step (the flag) and Next.
- **Settings**: look, window size and opacity, colour, the arrow and the
  game's waypoint, map pins, routes and the side guide, quests at their NPC,
  party sync, profession detours, Waypoint & tools, feedback, About. Also
  reachable from Esc > Options > AddOns > Pathwise.
- **Key bindings**: Game Menu > Key Bindings > Pathwise.

Commands still work for those who like them; `/pw help` lists them all.
`/pathwise`, `/fl` and `/foreverlevels` are the same command.

| Command | What it does |
|---|---|
| `/pw` | Show or hide the guide |
| `/pw next`, `/pw back`, `/pw skip` | Look at the next or previous step; skip a quest |
| `/pw routes`, `/pw route <id>`, `/pw zones` | Routes for you; switch route |
| `/pw prof`, `/pw dungeons` | Professions, dungeons for your level |
| `/pw settings`, `/pw style modern\|classic` | Settings; the look (after a reload) |
| `/pw auto`, `/pw sync`, `/pw waypoint` `[on\|off]` | Quests at their NPC, party sync, the game's waypoint |
| `/pw detour go\|later\|skip\|done\|on\|off` | The profession detour card |
| `/pw reminders [on\|off]`, `/pw track <profession> [on\|off]` | Material reminders; a profession in detours |
| `/pw report`, `/pw feedback` | Report this step; a bug or an idea |
| `/pw way <x> <y>`, `/pw where`, `/pw tools` | A waypoint by coordinates; where you are |
| `/pw record [on\|off]`, `/pw recorder [clear]` | For route authors (below) |

## Feedback

Found a wrong step? Click the flag in the guide window's footer (Report this
step), describe what happened and click Prepare report. Pathwise prepares the
text; copy it into [Pathwise's Discord](https://discord.gg/hSDjBrG8EK) or an
email to pathwise.nn@gmail.com. Nothing is sent from the game. Character
details and diagnostics are only included if you turn them on. See
[docs/FEEDBACK_SYSTEM.md](docs/FEEDBACK_SYSTEM.md).

## Compatibility with the ForeverLevels builds

| Kept | Why |
|---|---|
| `ForeverLevels` (the global), `/fl`, `/foreverlevels` | Same table and same commands as `Pathwise` and `/pw` |
| `Pathwise:RegisterRoute()` and `:RegisterProfessionData()` | Work with `:` or `.` and under either name |
| Party sync's prefix and message format | Players on the older builds still see each other |

Changed: routes are written as goal lists now ([docs/ROUTE_FORMAT.md](docs/ROUTE_FORMAT.md));
a route in the old format is refused with a pointer to the new one. Settings
are saved in `PathwiseSettings` and `PathwiseCharSettings`; the older
`ForeverLevelsDB` is not read, so settings start fresh. Progress needs no
moving: the guide reads it from your quest log.

## Forever API notes

Forever uses the modern client API (`C_QuestLog`, `C_Map`, `C_TradeSkillUI`
and so on) with Midnight's addon restrictions (secret values, chat lockdown).
Every client function Pathwise uses was checked against Blizzard's Forever UI
source; the list, and what the API does not allow, is in
[docs/API_RESEARCH.md](docs/API_RESEARCH.md). The main limits:

- No position or facing inside dungeons and raids: the arrow hides there.
- No pathfinding: the arrow points in a straight line.
- The client cannot list a profession's recipes and answers only for the
  window that is open: open each profession window once.
- Talking to NPCs, choosing rewards, setting your hearthstone, taking flight
  paths and training cannot be automated, and Pathwise does not try.

## Repository

```
Pathwise/            the main addon (Core, Guide, Nav, UI, Theme, Professions,
                     Routes, Data, Guides, Media)
Pathwise_Gear/       Pathwise Gear
Pathwise_Bags/       Pathwise Bags
examples/            an example route pack and an example profession data pack
tools/               data and route builders, route validator, recorder converter,
                     zip builder, version setter, link
tests/               offline tests against a stub of the game client
docs/                formats, the data's sources, API notes, the in-game checklist
```

## Development

You need Lua 5.1 (`lua5.1`; 5.4 works for the tests too) and Node 24 or newer.

```sh
npm test            # lua5.1 tests/run.lua
npm run validate    # every route and profession data pack
npm run lint        # luacheck (install it with luarocks)
npm run link        # link the addon folders into the game (set WOW_FOREVER_ADDONS first)
npm run pack        # dist/Pathwise-<version>.zip
```

CI runs the tests on Lua 5.1 and 5.4, the validator, lint and the zip build.
The in-game checks are in [docs/TEST_CHECKLIST.md](docs/TEST_CHECKLIST.md).

Writing routes: [docs/ROUTE_FORMAT.md](docs/ROUTE_FORMAT.md). Profession data:
[docs/PROFESSION_DATA_FORMAT.md](docs/PROFESSION_DATA_FORMAT.md). Professions,
the planner and detours: [docs/PROFESSIONS.md](docs/PROFESSIONS.md),
[docs/MATERIAL_PLANNER.md](docs/MATERIAL_PLANNER.md),
[docs/PROFESSION_DETOURS.md](docs/PROFESSION_DETOURS.md). Where the quest data
comes from: [docs/DATA.md](docs/DATA.md). How to contribute:
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

Copyright (C) 2026 The Pathwise Authors (leight_nn and florp, and contributors).

- Code: [GPL-3.0-only](LICENSE), with the additional terms in [NOTICE.md](NOTICE.md):
  data-only route and profession packs that only call the registration
  functions may use any license.
- Routes: adapted from [Polestar](https://github.com/fitzforge/polestar)
  (GPL-3.0). Quest data: [QuestieDB](https://github.com/Questie/QuestieDB).
  Typeface: Inter (SIL OFL 1.1). See [THIRD_PARTY.md](THIRD_PARTY.md).
- Starter profession data in `Pathwise/Guides/`: [CC BY-SA 4.0](Pathwise/Guides/LICENSE.md).
- The name "Pathwise" and the Pathwise family of add-ons are not covered by
  these licenses: [TRADEMARKS.md](TRADEMARKS.md).
- Versions published as ForeverLevels before the change to GPL-3.0 were MIT
  and stay MIT for anyone who got them then.

World of Warcraft is a trademark of Blizzard Entertainment. This is a fan
project and isn't affiliated with or endorsed by Blizzard.

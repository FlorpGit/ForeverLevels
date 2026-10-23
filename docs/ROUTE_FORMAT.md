# Route format

A route is a Lua table passed to `Pathwise.RegisterRoute()` (also
`Pathwise:RegisterRoute()`, and the same under the older name `ForeverLevels`).
Bundled routes are in `Pathwise/Routes/` (generated from Polestar's guides by
`tools/port/polestar.lua`; edit the converter, not the files). Community routes
ship as their own addon: see `examples/Pathwise_ExampleRoute`. The same format
is described at the top of `Pathwise/Guide/Engine.lua`.

Check routes offline (every bundled route, or the files you name):

```sh
lua tools/validate_routes.lua
lua tools/validate_routes.lua path/to/MyRoute.lua
```

A route lists **goals**; Pathwise fills in the facts (quest names, givers,
finishers, objectives and their places) from its quest data (docs/DATA.md).
Progress is read from the game every time and never stored, so a route needs
no step ids.

## Route fields

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Unique and stable, e.g. `myguild/horde/troll/01-durotar`. Saved choices use it. |
| `title` | yes | Shown in the guide header and the Routes panel. |
| `steps` | yes | The steps (below). |
| `category` | no | `"Leveling"` (default), `"Class"`, `"Professions"`, `"Reputation"`, `"Collectibles"`, `"Exploration"`, `"Miscellaneous"`. Only Leveling routes are picked for a character on their own. |
| `levels` | for Leveling routes | `{ min, max }`, for picking a route and listing routes near the character's level. |
| `map` | no | The route's zone (a uiMapID, as `/pw where` prints it). A route in the zone you stand in is preferred. |
| `faction` | no | `"Horde"` or `"Alliance"`. |
| `races` | no | Race file names (`"Scourge"`; `"Undead"` works too) or race IDs. |
| `classes` | no | Class file names, e.g. `{ "WARLOCK" }`. |
| `next` | no | The route to go on with when this one is done, if it is for the character. |

## Steps

A step is a list of goals plus a few fields:

```lua
{ title = "Shadow Priest Sarvis", note = "Follow the path north into Deathknell.",
	{ "turnin", 363 }, { "accept", 364 } },
```

| Field | Meaning |
|---|---|
| `title` | The step's heading; without one, the quest to complete or the first place. |
| `note` | What to do, in your own words. Without one, a quest's own text. |
| `only` | `{ classes = {...}, races = {...}, factions = {...} }`: the step is only for these characters. |
| `when` | `{ { k = "onquest", q = 123 } }` or `k = "turnedin"`: the step applies only then (`q` may be a list). |

A step is done when none of its goals is open. A step that is not for the
character is passed over. Back and Next look at other steps without changing
anything.

## Goals

| Goal | Done when |
|---|---|
| `{ "accept", q }` | quest `q` is in the log (or done). An accept the game does not offer yet (level, a quest before it) waits without holding the route. |
| `{ "complete", q }` | its objectives are finished (or it was handed in) |
| `{ "turnin", q }` | it was handed in |
| `{ "goto", map, x, y, "label" }` | the arrow arrived there |
| `{ "level", n }` | the character reaches level `n` |
| `{ "note", "text" }` | never holds the step (an instruction: hearth, fly) |
| `{ "have", item, count, name = }` | the bags hold `count` of `item` |
| `{ "bind", "Brill", at = }` | the hearthstone is bound there |
| `{ "skill", line, level }` | the profession `line` (Tailoring 197) reaches `level` |
| `{ "train", line, rankMax }` | its cap is `rankMax` (75, 150, 225, 300) |
| `{ "learn", spell, name = }` | the spell or recipe is known |
| `{ "craft", spell, name =, untilSkill =, item =, count =, reagents =, skillLine = }` | the skill reaches `untilSkill`, or the bags hold `count` of `item` |

Any goal may carry:
- `optional = true`: never holds the step;
- `only = { classes, races, factions }`: only for these characters;
- `at = { map, x, y }` and `who = "name"`: where to go and whom to see, when the
  data's place is not the one you want;
- `from = { { map, x, y, "name", "H" | "A" | "AH" }, ... }`: places to choose
  from, the nearest for the character's side (trainers, vendors).

Profession routes use `have`, `train`, `learn` and `craft`; the profession
planner reads them (docs/PROFESSIONS.md).

## Auto accept and turn-in

When the player talks to an NPC, Pathwise accepts a quest an `accept` goal of
the route asks for from the first open step on, and hands in a quest any
`turnin` goal asks for. Quests the route never names are left alone.

## Getting places right

`/pw record on` logs every quest accepted and handed in with its NPC and place
(and every trainer opened). After `/reload`,
`lua tools/recorder_to_route.lua WTF/Account/<ACCOUNT>/SavedVariables/Pathwise.lua my/route`
writes those as goals with `at` and `who`, a starting point to edit.

## Writing original routes

Routes in this repository must be your own work or adapted from a source
whose licence allows it (the bundled routes are Polestar's, GPL-3.0). Quest
IDs, quest names, NPC names and zone names are game facts and are fine to use.
Do not copy text, ordering or notes from paid guides. A route pack that is
only data and only calls the registration functions may use any licence
(NOTICE.md).

## Routes in the ForeverLevels format

The ForeverLevels builds wrote steps as `{ id, title, text, x, y, accept = {...},
turnin = {...} }`. Pathwise refuses such a route with a message pointing here.
To convert one: each quest in `accept`, `complete`, `turnin` becomes a goal,
`x`/`y` become `at = { map, x, y }` on the goal they belong to, `text` becomes
`note`, and `class`/`race`/`faction` become `only`.

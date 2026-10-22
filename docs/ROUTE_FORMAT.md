# Route format

A route is a Lua table passed to `ForeverLevels:RegisterRoute()`. Bundled routes
live in `ForeverLevels/Guides/`; community routes ship as their own addon
(see `examples/ForeverLevels_ExampleRoute`). Check a route offline with:

```sh
lua tools/validate_routes.lua path/to/MyRoute.lua
```

## Route fields

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Unique, stable id: letters, digits, `.`, `_`, `-`. Saved progress is keyed on it. Prefix with your name or pack, e.g. `myguild.horde.troll.01`. |
| `title` | yes | Shown in the guide header and `/fl routes`. |
| `author` | yes | Credit line. |
| `license` | yes | License of the route data, e.g. `CC BY-SA 4.0`, `CC0 1.0`. |
| `levels` | yes | `{ min, max }`. Used to pick a route automatically. |
| `steps` | yes | List of steps (below). |
| `faction` | no | `"Horde"` or `"Alliance"`. |
| `races` | no | `UnitRace()` file tokens, e.g. `{ "Scourge" }`. Unknown tokens only warn. |
| `classes` | no | Class tokens, e.g. `{ "WARLOCK" }`, for class-only routes. |
| `zone` | no | Default English zone name for step coordinates. |
| `maps` | no | `{ ["Tirisfal Glades"] = 1234 }` uiMapID overrides (needed for non-English clients). |
| `next` | no | Route id to continue with when this one finishes. |
| `quests` | no | `{ [questID] = "Name" }` fallback names, shown until the client has the quest cached. |
| `hidden` | no | `true` to never auto-select; players pick it with `/fl route <id>`. |
| `verified` | no | `true` once the whole route has been walked on Forever. |
| `apiVersion` | no | Route API version required (currently `1`). |

## Step fields

| Field | Meaning |
|---|---|
| `id` | Required, unique within the route, stable. |
| `title` | Required. Short heading. |
| `text` | What to do, in your own words. |
| `classText` | `{ WARRIOR = "...", MAGE = "..." }` appended for that class. |
| `note` | Extra hint, shown dimmed. |
| `x`, `y` | Waypoint, 0-100 map coordinates (as `/fl where` prints them). |
| `zone` / `map` | Override the route zone, or give a uiMapID directly. |
| `accept` | Quest IDs that must be in the log (or already turned in). |
| `complete` | Quest IDs whose objectives must be finished. |
| `turnin` | Quest IDs that must be turned in. |
| `level` | Player level to reach. |
| `class`, `race`, `faction` | Show the step only to these players. |
| `dungeon` | Dungeon id from `Guides/Dungeons.lua` to suggest on this step. |
| `verified` | `true` once this step's coordinates were checked on Forever. |

A goal entry is either a quest ID or a table that narrows it to classes/races:

```lua
accept = { 3901, { 3099, class = { "WARLOCK" } } },
```

## How steps complete

- A step is done when every goal that applies to the player is met; the guide
  then moves on by itself.
- A step with no goals is manual: the player presses Next.
- A step whose goals are all filtered out for the player (for example a class
  trainer step for a class it does not list) is skipped.
- Next on an unfinished step skips it. Back shows an earlier step and pauses
  auto-advance until Next.
- Automation accepts quests listed under `accept` from the current step onward, and
  turns in anything listed under `turnin`. Quests the route never lists are left alone.

## Writing original routes

Routes in this repository must be your own work: your ordering, your wording, your
notes. Quest IDs, quest names, NPC names and zone names are game facts and are fine to
use. Do not copy text, ordering or notes from paid guides, or from guides whose license
does not allow redistribution under the route's license. Coordinates should come from
your own play (`/fl record`, `/fl where`).

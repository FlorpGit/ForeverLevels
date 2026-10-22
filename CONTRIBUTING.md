# Contributing

If you want to help, the thing I need most is coordinates and quest data checked
on the live Forever client.

## Ground rules

1. Original work only. Routes must be written by you: your ordering, wording and
   notes. Do not paste or paraphrase text from paid or proprietary guides, or from
   guides whose license does not allow redistribution under CC BY-SA 4.0 (for example
   GPL-licensed guide text). Quest IDs, quest/NPC/zone names and coordinates you
   measured yourself are fine.
2. Only use functions that actually exist on Forever. If you
   add a call, cite where you verified it in `docs/API_RESEARCH.md` (Blizzard's API
   docs or UI source on the `forever` branch of Gethe/wow-ui-source). If a feature
   needs an API that does not exist, add it to the "not supported" table instead.
3. Licenses. Code contributions are MIT. Contributions to `ForeverLevels/Guides/`
   are CC BY-SA 4.0. By opening a pull request you agree to license your work that way.

## Fixing or adding route data

1. In game: `/fl record on`, then play the section.
2. `/reload`, then open `WTF/Account/<ACCOUNT>/SavedVariables/ForeverLevels.lua`.
3. Either edit the route file by hand using the recorded `x`, `y` and `mapID`, or start
   from a skeleton: `lua tools/recorder_to_route.lua path/to/ForeverLevels.lua my.route`.
4. Set `verified = true` on each step you walked yourself on Forever.
5. Run `lua tools/validate_routes.lua` and `lua tests/run.lua`.
6. Open a pull request with your build number (`/run print(GetBuildInfo())`).

New routes for other races, zones or level ranges can go in this repository (under
`ForeverLevels/Guides/`, add the file to both TOCs) or in your own addon
(see `examples/ForeverLevels_ExampleRoute`, and `docs/ROUTE_FORMAT.md`).

## Code

- Lua 5.1 (what WoW embeds). No `goto`, integer division or bit operators.
- Tabs for indentation, match the style of nearby code.
- Modules talk through `FL:Fire()` / `FL:On()` messages; keep UI out of `Core/`.
- Add or update a test in `tests/` for behavior changes. `lua tests/run.lua` must pass,
  and CI also runs on Lua 5.1 with luacheck.
- Keep both TOC files identical.

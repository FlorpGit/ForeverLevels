# Profession data format

Profession data is a Lua table passed to `Pathwise:RegisterProfessionData()` (the same
function exists on the `ForeverLevels` global). Bundled data is in
`Pathwise/Guides/Professions/`. Community data ships as its own addon; see
`examples/Pathwise_ExampleProfessionData`.

Check a file offline:

```sh
lua tools/validate_routes.lua path/to/MyProfessionData.lua
```

## Why profession data is not part of routes

Two options were considered: optional profession fields on route steps, or a separate
profession layer. Route steps drive quest progress and saved step numbers, so profession
fields there would either be ignored by the engine or risk changing how steps complete.
A separate layer leaves the route format, the bundled Undead routes and every existing
route pack untouched, and lets profession data be added or removed on its own. Pathwise
uses the separate layer: profession packs plus detours that only read the route
position. The route format is unchanged.

## Pack fields

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Unique pack id, e.g. `myname.tailoring.wool`. |
| `profession` | yes | Lowercase key: `tailoring`, `enchanting`, `first_aid` ... |
| `name` | yes | English profession name as the client shows it. |
| `author`, `license` | yes | Credit and the data license. |
| `skillLine` | no | Skill line ID (Tailoring 197, Enchanting 333). Used to match the client's profession. |
| `apiVersion` | no | Profession data API version required (currently 1). |
| `sources` | no | Where the data was checked. |
| `ranks` | no | Trainer ranks (below). The last pack that has ranks wins. |
| `trainers` | no | Trainers (below). Added to other packs' trainers. |
| `items` | no | `[itemID] = { name, acquire, verified }`. Fallback names and how to get an item. |
| `recipes` | yes | Recipes (below). Merged with other packs by recipe ID; later packs replace earlier ones. |

Several packs can describe the same profession. That is how a community pack adds
recipes for 75-150 without touching the bundled 1-75 starter set.

## Ranks

```lua
{ name = "Journeyman", trainAt = 50, maxSkill = 150, level = 10, verified = { values = false } }
```

`trainAt` is the skill needed to train it, `maxSkill` the cap it gives, `level` the
character level needed.

## Trainers

```lua
{ name = "Bowen Brisboise", npc = 3523, title = "Journeyman Tailor", zone = "Tirisfal Glades",
  x = 61.2, y = 52.4, faction = "Horde",
  verified = { name = true, zone = true, coords = true, teaches = false } }
```

Coordinates are optional. Without them a trainer detour shows text but no waypoint.
Record them in game with `/pathwise record on` and opening the trainer window.

## Recipes

```lua
{
  id = 2387,                         -- recipe spell ID
  name = "Linen Cloak",
  creates = 2570,                    -- item ID, if it makes an item
  kind = "enchant",                  -- optional; "enchant" means it needs an item to enchant
  reagents = { { 2996, 1 }, { 2320, 1 } },   -- { itemID, quantity }, direct reagents only
  skill = { 1, 35, 47, 60 },         -- optional: orange, yellow, green, grey
  source = "trainer",                -- trainer, vendor, drop, quest, unknown
  note = "...",                      -- optional
  verified = { reagents = true, skill = false, source = false },
}
```

Only list direct reagents. If a reagent is made by another recipe of the same
profession (Bolt of Linen Cloth), list that recipe too; the planner expands it.

## Verification flags

`verified` is a table of field = true/false. Set a field to true only when you checked it
on Forever: in game, or in a source that covers Forever (such as wowhead.com/forever).
Leave out fields you did not check rather than guessing values. The dashboard shows
unverified values as estimates, and the validator lists recipes whose skill levels are
unverified.

## Writing a pack

1. Copy `examples/Pathwise_ExampleProfessionData` to a new folder and rename the folder,
   the `.toc` and the pack id.
2. Keep `## Dependencies: Pathwise` in the `.toc`.
3. Add recipes you verified. Give sources.
4. Run `lua tools/validate_routes.lua YourFile.lua`.
5. Pick a license. Bundled data is CC BY-SA 4.0; your pack can use any license and
   declares it in `license`.

Data must be your own work or facts you checked. Do not copy from paid guides or from
sources whose license does not allow it.

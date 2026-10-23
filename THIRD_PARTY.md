# Third-party material

| What | Used for | Licence | Where |
|---|---|---|---|
| [Inter](https://github.com/rsms/inter) by Rasmus Andersson | The interface typeface (Regular, Medium, SemiBold) | SIL Open Font License 1.1 | `Pathwise/Media/Fonts/`, licence in `Inter-OFL.txt` |
| [QuestieDB](https://github.com/Questie/QuestieDB) by the Questie team and contributors (Forever data, commit `1f538335`) | Quest, NPC, object and item facts (ids, givers, finishers, objectives, spawn positions, levels, prerequisites) that Pathwise's routes are built on | The Questie team permits use under GPL-3.0; parts of the historic data have no recorded licence from every contributor (QuestieDB `LICENSE.md`). The Questie name and logo are not used | Downloaded to `data/sources/questiedb` (not committed); Pathwise ships only the fields it needs, built by its own tools |
| Blizzard's Forever client tables (SkillLineAbility, SpellEffect, Item, ItemSparse, ItemEffect, ItemXItemEffect), as CSV from [wago.tools](https://wago.tools) (product `wowf`) | Recipes for Pathwise Gear's crafted gear: which profession and skill make each item, which recipe item teaches it, the item's type and levels. `tools/data/recipes.js` follows Polestar's profession tool's method (below), keeping Season of Discovery recipes, marked | © Blizzard Entertainment | Downloaded to `data/sources/wago/` (not committed); `data/recipes.lua` is generated from them |
| Blizzard's Forever UI source ([Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), `forever` branch) | Checking which client APIs exist on Forever | © Blizzard Entertainment | Read while developing; nothing copied |
| [Polestar](https://github.com/fitzforge/polestar), Copyright (c) 2026 The Polestar authors | Its leveling routes (1-60, both factions, every starting race), class quest routes, profession routes and reputation, mount, pet and exploration guides, adapted into Pathwise's route format by `tools/port/polestar.lua` (what changes is listed in that file). Also a reference for how Forever behaves (secret values, map and world positions, facing, skills, the client folder's name, and a gamepad issue with addon slash commands); Pathwise's addon code is its own | GPL-3.0 | `Pathwise/Routes/Leveling.lua`, `Class.lua`, `Professions.lua`, `Other.lua` (generated; each file names its source) |
| [Wowhead's World of Warcraft: Forever database](https://www.wowhead.com/forever) | Checking the facts of Pathwise's starter profession data: recipe IDs and names, direct reagents, created items, trainer names, titles and zones. Only individual facts are used; each data file cites its pages | Facts, not copied text | `Pathwise/Guides/Professions/` (Pathwise's own data, CC BY-SA 4.0) |

## References, nothing copied

Blizzard's Forever UI source (above) and the generated API documentation in
it are what every client API, event, template and texture Pathwise uses was
checked against (docs/API_RESEARCH.md); the [Warcraft Wiki](https://warcraft.wiki.gg)
for the TOC format and patch API notes.

Pathwise Gear's weights are its own numbers. The order of stats for each spec
follows these guides, and the stat rules follow Warcraft Tavern's. Only the
facts (which stat comes before which, and how many points give what) are
used. None of their text is in Pathwise (`Pathwise_Gear/Weights.lua`
explains how the numbers were set).

| Reference | Used for |
|---|---|
| [Icy Veins: WoW Forever class guides](https://www.icy-veins.com/wow-forever/all-class-guides) | Each spec's stat priority at level 30; their Classic Era guides for level 60 |
| [Mobalytics: WoW Forever class guides](https://mobalytics.gg/wow-forever/classes) | Each spec's levelling stat priority, and Forever's talent changes that move it |
| [Warcraft Tavern: WoW Forever stats guide](https://www.warcrafttavern.com/forever/guides/stats/) | Forever's stat rules (attack power, crit, Spirit for healers, Haste) |
| [Wowhead: WoW Forever class guides](https://www.wowhead.com/forever/guides/classes) | Read as a cross-check; they list gear rather than stat orders |

Pathwise Gear's "Best in Slot (Level)" list is worked out in game: which items
exist and where they come from is QuestieDB's Forever data (above), their
stats are what the game client reports. ForeverChanges' BiS lists (its terms
forbid copying its compiled data) and Foresight's data (all rights reserved
since 15 October 2026) were looked at and are not used.

Pathwise Bags is its own code. Features were compared with
[Bagnon](https://github.com/Jaliborc/Bagnon) (its code is All Rights Reserved)
and Baganator by plusmouse (its main source is not public); nothing of either
is used. Its item buttons are the game's own (`ContainerFrameItemButtonTemplate`).

Pathwise Gear needs no other addon. Its custom-weights box also reads the
`( Pawn: v1: ... )` text format that guide sites share, without Pawn
installed; no Pawn code is in Pathwise.

The Classic look draws with the game's own art and templates (the dialog and
tooltip borders, UIPanelButtonTemplate, UIPanelCloseButton, InputBoxTemplate):
Pathwise names them; it ships none of Blizzard's files.

Development tools (not distributed): Lua, luacheck, Node.js, and the GitHub
Actions actions/checkout, actions/setup-node, leafo/gh-actions-lua and
leafo/gh-actions-luarocks, for tests, lint and CI.

Everything else in this repository (code, textures drawn by `tools/media.js`,
documents) is Pathwise's own, under GPL-3.0 (see `LICENSE` and `NOTICE.md`),
except the starter profession data in `Pathwise/Guides/`, which is CC BY-SA 4.0
(`Pathwise/Guides/LICENSE.md`).

Quest, NPC, item and zone names and IDs belong to Blizzard Entertainment.
World of Warcraft is a trademark of Blizzard Entertainment, Inc. Pathwise is a
fan project and is not affiliated with or endorsed by Blizzard Entertainment.

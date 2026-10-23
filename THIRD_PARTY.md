# Third-party material

| What | Used for | Licence | Where |
|---|---|---|---|
| [Inter](https://github.com/rsms/inter) by Rasmus Andersson | The interface typeface (Regular, Medium, SemiBold) | SIL Open Font License 1.1 | `Pathwise/Media/Fonts/`, licence in `Inter-OFL.txt` |
| [QuestieDB](https://github.com/Questie/QuestieDB) by the Questie team and contributors (Forever data, commit `1f538335`) | Quest, NPC, object and item facts (ids, givers, finishers, objectives, spawn positions, levels, prerequisites) that Pathwise's routes are built on | The Questie team permits use under GPL-3.0; parts of the historic data have no recorded licence from every contributor (QuestieDB `LICENSE.md`). The Questie name and logo are not used | Downloaded to `data/sources/questiedb` (not committed); Pathwise ships only the fields it needs, built by its own tools |
| Blizzard's Forever UI source ([Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), `forever` branch) | Checking which client APIs exist on Forever | © Blizzard Entertainment | Read while developing; nothing copied |
| [Polestar](https://github.com/fitzforge/polestar) (GPL-3.0) | A reference for how Forever behaves (secret values, map and world positions, facing). Pathwise's code is its own; nothing is copied | GPL-3.0 | Read while developing; nothing copied |

Everything else in this repository (code, textures drawn by `tools/media.js`,
documents) is Pathwise's own, under GPL-3.0 (see `LICENSE`).

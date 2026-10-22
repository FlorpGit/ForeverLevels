# Professions

Pathwise tracks professions next to the leveling guide. Phase 2 covers Tailoring and
Enchanting with a small starter dataset. Other professions are detected and shown with
their skill, but have no plan until someone adds data for them.

Profession tracking is separate from the leveling route. It has its own saved data and
never changes route progress, the current step, or quest detection.

## What Pathwise reads from the game

| What | How | When |
|---|---|---|
| Professions, skill and cap | `GetProfessions()` and `GetProfessionInfo()`; `C_SkillInfo` as a fallback | login, `SKILL_LINES_CHANGED`, `LEARNED_SPELL_IN_SKILL_LINE`, `TRAINER_CLOSED` |
| Learned recipes and their difficulty color | `C_TradeSkillUI.GetRecipeInfo()` | while a profession window is open (`TRADE_SKILL_SHOW`, `TRADE_SKILL_LIST_UPDATE`), plus `NEW_RECIPE_LEARNED` |
| The recipe's real reagent list | `C_TradeSkillUI.GetRecipeSchematic()` | while a profession window is open |
| Materials you own | `C_Item.GetItemCount()` (bags, or bags and bank if you turn that on) | `BAG_UPDATE_DELAYED` |

The client only answers recipe questions for the profession whose window is open, so
open each profession window once after logging in. Pathwise caches what it read:
recipe state per character, reagent lists account-wide. Until then, Pathwise falls back
to the bundled data and says so.

All of these functions and events are listed with sources in
[API_RESEARCH.md](API_RESEARCH.md).

## Data and verification

Bundled data lives in `Pathwise/Guides/Professions/`. Every fact was either checked
against Wowhead's World of Warcraft: Forever database or is marked as unverified.

- Verified: recipe IDs and names, direct reagents (item IDs and quantities), created
  items, trainer names, titles and zones.
- Not verified: skill levels (Tailoring keeps the 2004 values as a labeled fallback;
  Enchanting has none), rank caps and training levels, trainer coordinates, and how raw
  materials are obtained.

Forever changed Enchanting compared with the 2004 game. It adds Mote of Magic (item
247786), made from Strange Dust with "Dust to Motes" or bought from vendors in Undercity
and Tirisfal Glades. Several enchants were renamed (recipe 7418 is now "Enchant Bracer -
Inferior Stamina") and some reagent lists changed. Data copied from older guides is
wrong for Forever, which is why the bundled set is small.

The dashboard always shows where a number comes from:
"chance from your client", "estimate from unverified skill levels",
"reagents checked on Wowhead (Forever)" and so on.

## Using it

- Professions button on the guide window, or `/pathwise prof`: the dashboard.
- Profession detours appear under the guide window. See
  [PROFESSION_DETOURS.md](PROFESSION_DETOURS.md).
- `/pathwise tracking on|off`, `/pathwise reminders on|off`,
  `/pathwise track <profession> on|off`, `/pathwise detour on|off`.
- The same switches are in the options panel and on the dashboard.

## Helping with data

Turn on the recorder (`/pathwise record on`). It now also logs where you open a trainer
window, which is how trainer coordinates get verified. Opening a profession window also
stores the client's reagent lists, which you can compare with the bundled data.

To add recipes or professions without changing Pathwise, write a profession data pack.
See [PROFESSION_DATA_FORMAT.md](PROFESSION_DATA_FORMAT.md).

## Known limits

- Forever has no API to list every recipe ID, so Pathwise only knows about recipes in its
  data packs.
- Difficulty colors are only current at the skill they were read at. After a skill-up,
  Pathwise uses skill levels or an older reading until you open the window again.
- Rank caps and training levels are 2004 values marked unverified. Forever may differ;
  the cap shown in the overview always comes from the client.
- Pathwise never crafts, buys, sells, destroys or disenchants anything.

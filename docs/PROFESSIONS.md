# Professions

Pathwise follows professions beside the leveling route. It is one system with
three parts:

- **The plan**: a profession route from 1 to 300 for each of the twelve
  professions (`Pathwise/Routes/Professions.lua`, adapted from Polestar):
  trainers, materials to get, what to craft until which skill.
- **The facts** (`Professions/Recipes.lua`): one record per recipe, from the
  routes' craft goals, profession data packs (Pathwise's checked starter data
  for Tailoring and Enchanting, and any community pack) and what the
  profession window says.
- **The advice**: the planner (`Professions/Planner.lua`) puts numbers on the
  route's next step; the detour card (`Professions/Detours.lua`) offers what is
  worth doing now; the professions panel shows it all.

None of it changes the leveling route, its steps or quest progress, and
Pathwise never crafts, buys, sells, destroys or disenchants anything.

## What Pathwise reads from the game

| What | How | When |
|---|---|---|
| Professions, skill and cap | `C_SkillInfo.GetSkillLineInfoByID`, then `GetProfessions()`/`GetProfessionInfo()`, then the skill list (`Compat.SkillRank`) | whenever asked; `SKILL_LINES_CHANGED`, `LEARNED_SPELL_IN_SKILL_LINE` refresh the guide |
| Which recipes are learned, their colour, and at which skill | `C_TradeSkillUI.GetRecipeInfo()` for each recipe Pathwise knows for the open profession | while a profession window is open (`TRADE_SKILL_SHOW`, `TRADE_SKILL_LIST_UPDATE`); `NEW_RECIPE_LEARNED` marks one learned |
| A recipe's real reagents | `C_TradeSkillUI.GetRecipeSchematic()` | while the window is open; kept for the account |
| Materials you own | `C_Item.GetItemCount()` (bags and bank by default) | `BAG_UPDATE_DELAYED` |

Forever's client cannot list a profession's recipes (`GetAllRecipeIDs` is not
in its API) and only answers for the profession whose window is open, so open
each profession window once. Pathwise keeps what it read: recipe states per
character, reagent lists for the account. Until then it uses the route's and
the packs' facts and says so.

The functions and events are listed with sources in [API_RESEARCH.md](API_RESEARCH.md).

## Where the facts come from, and how sure they are

When sources differ, the window's own reagent list wins, then a pack's checked
facts, then the route's, then a pack's unchecked facts. The starter data in
`Pathwise/Guides/Professions/` was checked against Wowhead's Forever database:
recipe IDs and names, direct reagents, created items, trainer names and zones.
Skill levels there are the 2004 values, kept as a labelled fallback (Tailoring)
or left out (Enchanting).

Forever changed Enchanting: it adds Mote of Magic (item 247786, from Strange
Dust with "Dust to Motes" or from vendors in Undercity and Tirisfal Glades),
renamed several enchants (recipe 7418 is "Enchant Bracer - Inferior Stamina")
and changed some reagents. Both the routes and the starter data follow Forever.

Every number the panel shows says where it comes from: "from your profession
window", "from skill levels not yet checked on Forever", and so on.

## Using it

- The Professions button on the guide window (or `/pw prof`): your
  professions with their skill and what is next; click one for its page: the
  route's step, the best craft now with its chance and the crafts to the
  target, the materials for it (and what a missing one is made from), the next
  rank and what it asks, recipes to learn, the materials for the whole rank,
  following it beside your route, and for Enchanting, disenchanting.
- The detour card under the guide's step: [PROFESSION_DETOURS.md](PROFESSION_DETOURS.md).
- A line in chat when your bags newly make a profession's next craft
  (`/pw reminders on|off`).
- `/pw track <profession> on|off` (or the switch on its page) leaves a
  profession out of detours and reminders.

## Helping with data

Turn on the recorder (`/pw record on`): it logs where you open a trainer
window, which is how trainer positions get checked. Opening a profession
window keeps the client's reagent lists, which you can compare with the data.

To add recipes or facts without changing Pathwise, write a profession data
pack: [PROFESSION_DATA_FORMAT.md](PROFESSION_DATA_FORMAT.md).

## Known limits

- Colours are only current at the skill they were read at; after a skill-up
  Pathwise uses skill levels or the older reading until you open the window
  again.
- Rank requirements come from the routes' notes (Journeyman: level 10 and
  skill 50; Expert: 20 and 125; Artisan: 35 and 200); the cap shown is always
  the client's.
- The Enchanting skill needed to disenchant an item is the Classic table, not
  checked on Forever (shown with "≈", or "~" in the Classic look).

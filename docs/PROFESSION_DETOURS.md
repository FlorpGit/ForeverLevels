# Profession detours

A detour is an optional profession task in a card under the guide's step while
you follow a leveling route, for example "Train Journeyman Tailoring" or
"Craft 23 Bolt of Linen Cloth". One card at a time (`Professions/Detours.lua`,
drawn by Pathwise UI's `UI/GuideWindow.lua`).

## Guarantees

- The leveling route, its steps, the step shown and Back/Next are never changed
  by a detour. Detours only read where the route is.
- Quest steps never move on because a profession task finished.
- Nothing is written into route files.

## What the card offers

First that applies:

1. **The detour you chose with Go**, until it is done.
2. **Train**: the next rank of one of your professions can be trained now (you
   have the level and the skill it asks) at a trainer on the way. The trainer
   is the nearest for your side among those the profession route names.
3. **Craft**: your bags make the profession's next craft now, a recipe you
   know (Planner.Next). It can be done anywhere, so it shows wherever you are.
4. **Side guide**: the next step of the profession route you follow beside the
   leveling route (Routes panel, or "Follow beside your route" on a profession's
   page), unless 2 or 3 is already about that profession.

Professions you leave out (`/pw track <profession> off`, or the switch on its
page) get no train or craft detours.

## On the way: the mode

Settings > Profession detours:

| Mode | A detour with a place shows |
|---|---|
| Speed | within about 150 yards |
| Balanced (default) | within about 600 yards |
| Crafting | always |
| Off (the card's switch) | never |

## Buttons and states

| Button | Effect |
|---|---|
| Go | Chooses the detour. If it has a place, the arrow and the game's waypoint lead there. Becomes Stop. |
| Stop | Goes back to the route's step; the detour can be offered again. |
| Later | Hides it until the leveling route moves to another step, then offers it again. |
| The cross | Skips it for good (that rank, that craft at this skill, that side step). |

Saved per character in `PathwiseCharSettings.detours`: `active` (the chosen
detour), `states[id]` (`done` or `skipped`), `postponed[id]` (the route's
place at "Later"). Settings > Profession detours brings skipped and postponed
detours back.

A chosen detour finishes on its own: training when your cap goes up, crafting
when you reach its target skill or the materials run out ("detour done" in
chat); a side step when its goals are met. The arrow then goes back to the
route's step.

## Commands

`/pw detour go | later | skip | done | on | off | speed | balanced | craft`
(also as `/fl detour ...`).

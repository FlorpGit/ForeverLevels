# Profession detours

A detour is an optional profession task shown under the guide window while you follow a
leveling route, for example "Train Journeyman Tailoring" or "Craft 5 x Bolt of Linen
Cloth". Detours are a separate layer (`Core/Detours.lua`, `UI/DetourBanner.lua`).

## Guarantees

- The route, its step numbers, the current step and saved route progress are never
  changed by a detour. Detours only read which step you are on.
- Quest steps never advance because a profession task finished.
- Back and Next work exactly as before, with or without a detour.
- Nothing is inserted into route files.

## Where suggestions come from

Pathwise looks for one suggestion at a time, for tracked professions that have data:

1. Trainer visit: you can train the next rank now, or the client reported trainer
   recipes you could learn. Only suggested when that trainer is in your current zone or
   the route's zone.
2. Craft: a recipe that still gives skill and that you have materials for right now.

Suggestions are re-checked after profession changes, bag changes, route step changes,
level-ups and zone changes. Those events are merged into one check, so bursts do not
cause repeated work, and there is no polling.

## Buttons and states

| Button | Effect |
|---|---|
| Go | Accepts the detour. If it has coordinates, the arrow and map pin point at it. |
| Later | Hides it until the route moves to another step, then offers it again. |
| Skip | Hides it for good (for that milestone). |
| Done | Marks the active detour finished. |
| Cancel | Drops the active detour; it is not offered again. |

Saved per character in `ForeverLevelsCharDB.professions.detours`:

- `active`: the accepted detour
- `states[id]`: `done` or `skipped`
- `postponed[id]`: the route step it was postponed at

Active detours finish on their own: a trainer detour when your cap goes up or you learn a
recipe, a craft detour when you reach the target skill or run out of materials.

## Navigation

While a detour with coordinates is active, the arrow and Blizzard's map pin point at it
and the arrow label starts with "Detour:". When it ends (done, cancelled or detours
turned off) the waypoint goes back to the current route step. The bundled trainers have
no verified coordinates yet, so their detours show text only and the arrow stays on the
route.

## Turning detours off

Any of: the Detours button on the dashboard, the options panel, or
`/pathwise detour off`. Turning them off removes the current suggestion and active
detour without marking them done or skipped.

## Commands

`/pathwise detour go | later | skip | done | cancel | on | off` (also `/fl detour ...`).

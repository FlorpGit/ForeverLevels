# In-game test checklist (MVP: Undead 1-10)

Run this on a new Undead character on the Forever client (or beta). Note the
build first: `/run print(GetBuildInfo())`. Turn on the recorder for the whole run
(`/fl record on`) and attach `WTF/Account/<ACCOUNT>/SavedVariables/ForeverLevels.lua`
to your report. That file is what lets us fix coordinates.

Before you start, the offline checks should pass:

```sh
lua tests/run.lua
lua tools/validate_routes.lua
```

## 1. Install and load

- [ ] The `ForeverLevels` folder is in `_forever_/Interface/AddOns/` (or `_classic_beta_/...`), with `ForeverLevels_Forever.toc` directly inside it.
- [ ] After a full game restart, the AddOns list on the character screen shows ForeverLevels and does not mark it out of date.
- [ ] Login shows no Lua errors (`/console scriptErrors 1` first, or use BugSack).
- [ ] No "does not report itself as World of Warcraft: Forever" warning.
- [ ] `/fl routes` lists both Undead routes and marks Deathknell active.

## 2. Guide window

- [ ] The window shows "Undead 1-6: Deathknell", "1/15", "Wake up" and an Accept goal for Rude Awakening.
- [ ] Dragging moves it; position survives `/reload`.
- [ ] `/fl lock` prevents dragging; `/fl unlock` allows it again.
- [ ] `/fl scale 1.3` resizes it; the close button hides it; `/fl` shows it again.
- [ ] The window uses the classic stone dialog border by default. `/fl style` cycles to tooltip and minimal; the choice survives `/reload`. Note if the border art looks wrong on Forever.
- [ ] Back and Next buttons work, and "(viewing)" appears after Back.

## 3. Waypoint and arrow

- [ ] A Blizzard map pin appears at the step location on the world map, and the in-world navigation marker shows.
- [ ] The ForeverLevels arrow points at the target. Turn on the spot: the arrow turns the opposite way and goes green when you face the target.
- [ ] Distance counts down while you walk toward the target and shows "arrived" within about 10 yards.
- [ ] `/fl waypoint off` removes our map pin but keeps the arrow; `/fl arrow off` hides the arrow.
- [ ] If you had placed your own map pin, ForeverLevels only replaces it when a step sets a new target (note any surprises).
- [ ] `/fl where` prints a map ID, "Tirisfal Glades" and coordinates.

## 4. Quest detection and automation

- [ ] Talking to Undertaker Mordo auto-accepts Rude Awakening and the guide advances.
- [ ] Shift + right-click on an NPC opens the dialog without automation.
- [ ] Turning in at Shadow Priest Sarvis completes without clicks when there is no reward choice.
- [ ] On a quest with a reward choice, the dialog stays open and chat says "pick your reward".
- [ ] Killing zombies updates the objective lines live; the step advances when the quest is complete.
- [ ] Quests not in the route (if any NPC offers one) are not auto-accepted.
- [ ] `/fl auto off` stops all automation; `/fl auto on` restores it.

## 5. Class and race steps

Test at least one of each, on separate characters if you can:

- [ ] Warrior / Rogue / Priest / Mage: your scroll quest appears at "Back to the church", and "Visit your trainer" names your trainer.
- [ ] Warlock: trainer step also asks for Piercing the Veil from Venya Marthand; the fields step includes it.
- [ ] Paladin (Forever): the trainer step is skipped; note which Paladin quests Forever offers here (the route does not cover them yet).
- [ ] A non-Undead Horde character gets "no installed route fits this character".

## 6. Route chaining and level 10

- [ ] After "Orders for Brill", the guide switches to "Undead 6-10: Brill" by itself.
- [ ] Brill steps detect Calvin Montague, Gordo, Zygand, Innkeeper Renee, Holland, Dillinger and Johaan correctly.
- [ ] The final step completes on reaching level 10 and chat says the route is finished.
- [ ] Note your level at the end of Deathknell and at each Brill step (helps tune `levels`).

## 7. Dungeons

- [ ] At level 13+ (any Horde character), the guide shows "Dungeons at your level: Ragefire Chasm (13-18)".
- [ ] `/fl dungeons off` hides the line.

## 8. Party sync (needs two players with ForeverLevels)

- [ ] Both run `/fl sync on` and group up. Each sees the other's step and objective counts under the guide within a few seconds.
- [ ] Leaving the group clears the party lines.
- [ ] With sync off on one side, nothing from that player appears.
- [ ] Inside an instance during a boss fight there are no errors (sends are skipped during lockdown).

## 9. Persistence

- [ ] `/reload` mid-route keeps the same step.
- [ ] Logging out and back in keeps the step and all settings.
- [ ] A second character has its own progress.
- [ ] `/fl reset` restarts the route; the guide fast-forwards past quests you already finished.

## 10. Options panel

- [ ] Esc > Options > AddOns > ForeverLevels shows toggle buttons, and `/fl options` opens it.
- [ ] Each toggle flips ON/OFF and matches the slash-command state.

## 11. Instances and edge cases

- [ ] Inside an instance the arrow hides its pointer (no facing there); no Lua errors.
- [ ] Abandoning a quest the current step needs does not break the guide (it waits for you to pick it up again).
- [ ] Gamepad mode: everything works from the window and options panel without slash commands.

## Reporting

For each failed item give: build, character race/class/level, step id (the number in the
header and the step title), what you expected, what happened, and your SavedVariables file.

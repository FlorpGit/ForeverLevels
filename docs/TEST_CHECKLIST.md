# In-game test checklist (Pathwise 0.2.0-alpha.2)

Run sections 1-11 on a new Undead character, and 12-16 on an Undead Mage with Tailoring and Enchanting, on the Forever client (or beta). Note the
build first: `/run print(GetBuildInfo())`. Turn on the recorder for the whole run
(`/pathwise record on`) and attach `WTF/Account/<ACCOUNT>/SavedVariables/ForeverLevels.lua`
to your report. That file is what lets us fix coordinates.

Before you start, the offline checks should pass:

```sh
lua tests/run.lua
lua tools/validate_routes.lua
```

## 1. Install and load

- [ ] The `ForeverLevels` folder is in `_forever_/Interface/AddOns/` (or `_classic_beta_/...`), with `ForeverLevels_Forever.toc` directly inside it.
- [ ] After a full game restart, the AddOns list on the character screen shows Pathwise and does not mark it out of date.
- [ ] Login shows no Lua errors (`/console scriptErrors 1` first, or use BugSack).
- [ ] No "does not report itself as World of Warcraft: Forever" warning.
- [ ] `/pathwise routes` lists both Undead routes and marks Deathknell active.

## 2. Guide window

- [ ] The window shows "Undead 1-6: Deathknell", "1/15", "Wake up" and an Accept goal for Rude Awakening.
- [ ] Dragging moves it; position survives `/reload`.
- [ ] `/pathwise lock` prevents dragging; `/pathwise unlock` allows it again.
- [ ] `/pathwise scale 1.3` resizes it; the close button hides it; `/pathwise` shows it again.
- [ ] The window uses the classic stone dialog border by default. `/pathwise style` cycles to tooltip and minimal; the choice survives `/reload`. Note if the border art looks wrong on Forever.
- [ ] Back and Next buttons work, and "(viewing)" appears after Back.

## 3. Waypoint and arrow

- [ ] A Blizzard map pin appears at the step location on the world map, and the in-world navigation marker shows.
- [ ] The ForeverLevels arrow points at the target. Turn on the spot: the arrow turns the opposite way and goes green when you face the target.
- [ ] Distance counts down while you walk toward the target and shows "arrived" within about 10 yards.
- [ ] `/pathwise waypoint off` removes our map pin but keeps the arrow; `/pathwise arrow off` hides the arrow.
- [ ] If you had placed your own map pin, ForeverLevels only replaces it when a step sets a new target (note any surprises).
- [ ] `/pathwise where` prints a map ID, "Tirisfal Glades" and coordinates.

## 4. Quest detection and automation

- [ ] Talking to Undertaker Mordo auto-accepts Rude Awakening and the guide advances.
- [ ] Shift + right-click on an NPC opens the dialog without automation.
- [ ] Turning in at Shadow Priest Sarvis completes without clicks when there is no reward choice.
- [ ] On a quest with a reward choice, the dialog stays open and chat says "pick your reward".
- [ ] Killing zombies updates the objective lines live; the step advances when the quest is complete.
- [ ] Quests not in the route (if any NPC offers one) are not auto-accepted.
- [ ] `/pathwise auto off` stops all automation; `/pathwise auto on` restores it.

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
- [ ] `/pathwise dungeons off` hides the line.

## 8. Party sync (needs two players with Pathwise)

- [ ] Both run `/pathwise sync on` and group up. Each sees the other's step and objective counts under the guide within a few seconds.
- [ ] Leaving the group clears the party lines.
- [ ] With sync off on one side, nothing from that player appears.
- [ ] Inside an instance during a boss fight there are no errors (sends are skipped during lockdown).

## 9. Persistence

- [ ] `/reload` mid-route keeps the same step.
- [ ] Logging out and back in keeps the step and all settings.
- [ ] A second character has its own progress.
- [ ] `/pathwise reset` restarts the route; the guide fast-forwards past quests you already finished.

## 10. Options panel

- [ ] Esc > Options > AddOns > ForeverLevels shows toggle buttons, and `/pathwise options` opens it.
- [ ] Each toggle flips ON/OFF and matches the slash-command state.

## 11. Instances and edge cases

- [ ] Inside an instance the arrow hides its pointer (no facing there); no Lua errors.
- [ ] Abandoning a quest the current step needs does not break the guide (it waits for you to pick it up again).
- [ ] Gamepad mode: everything works from the window and options panel without slash commands.

## 12. Pathwise branding and compatibility

- [ ] The guide header reads "Pathwise - Undead 1-6: Deathknell"; chat lines start with "Pathwise:".
- [ ] Esc > Options > AddOns shows "Pathwise" with the tagline, "By leight_nn & florp", and the note that /fl still works.
- [ ] `/pathwise`, `/fl` and `/foreverlevels` all toggle the guide.
- [ ] Upgrading from a 0.1 install keeps the route, step, window position and settings.
- [ ] The example route pack (uses `ForeverLevels:RegisterRoute`) still loads.

## 13. Profession detection (Undead Mage, Tailoring + Enchanting)

- [ ] `/pathwise prof` (or the Professions button) opens the dashboard; it lists Tailoring and Enchanting with the same skill and cap as your character sheet.
- [ ] Skilling up updates the dashboard without a reload.
- [ ] Open the Tailoring window once: recipes you know show as learned on the dashboard, and the plan says "chance from your client".
- [ ] Same for Enchanting. Note which bundled Enchanting recipes the trainer offers and their difficulty colors.
- [ ] Learning a recipe at the trainer is picked up (`NEW_RECIPE_LEARNED`).
- [ ] A profession Pathwise has no data for (for example a gathering profession) shows "(no Pathwise data yet)".

## 14. Material planner

- [ ] With some Linen Cloth in your bags, the plan shows owned and missing amounts that match your bags.
- [ ] Missing Bolts of Linen Cloth show "make with Bolt of Linen Cloth" and the linen needed.
- [ ] Moving items to the bank changes counts only when "Count bank items" is on.
- [ ] Getting materials for a craft prints one "you have materials for" line, not one per bag update.
- [ ] Compare each bundled recipe's reagents with the game. Report any difference (Forever changed several Enchanting recipes).

## 15. Profession detours

- [ ] With materials for a craft, a detour banner appears under the guide window with Go, Later and Skip.
- [ ] Go: the banner shows Done and Cancel; the route step and step number do not change; accepting and turning in quests still advances the route.
- [ ] Later: the detour disappears and comes back after the route moves to another step.
- [ ] Skip: it does not come back, also after `/reload`.
- [ ] Reaching the target skill or running out of materials finishes the craft detour by itself.
- [ ] At a trainer milestone in Tirisfal or Undercity, a trainer detour appears. With no verified coordinates it says so and the arrow stays on the route.
- [ ] `/pathwise detour off` removes the banner; `on` brings suggestions back.

## 16. Dashboard and styles

- [ ] The dashboard follows `/pathwise style classic`, `tooltip` and `minimal`.
- [ ] The dashboard can be dragged, and its position survives `/reload`.
- [ ] The settings buttons (Tracking, Detours, Reminders, one per profession) change behavior right away.
- [ ] Use `/pathwise record on` and open the Tailoring and Enchanting trainer windows; the trainer positions appear in the SavedVariables file.

## 17. Feedback Center and Report This Step

- [ ] The ticket icon sits right of Back in all three styles (`/pathwise style classic|tooltip|minimal`) and at `/pathwise scale 0.8` and `1.3`, without overlapping the Professions button.
- [ ] Hovering it shows "Report an issue with this guide step."
- [ ] Clicking it opens the Feedback Center with this step's route, step number, title, quest IDs and waypoint. The guide stays on the same step and nothing is accepted, skipped or completed.
- [ ] With no route active (for example on a non-Undead character) the icon is hidden, and `/pathwise report` says so and opens a general report.
- [ ] The "Information in this report" section lists character and diagnostics as "not included" until you turn them on.
- [ ] "Prepare report" without a description, or without a problem type, shows what is missing.
- [ ] The prepared text can be selected with Ctrl+A and copied with Ctrl+C into an email; typing in that box does not change it. The window says "not sent".
- [ ] Typed text survives `/reload`; each step keeps its own draft; "Discard draft" removes only the current one.
- [ ] `/pathwise feedback` and `/fl feedback` open the same window; the options panel button does too.

## Reporting

For each failed item give: build, character race/class/level, step id (the number in the
header and the step title), what you expected, what happened, and your SavedVariables file.

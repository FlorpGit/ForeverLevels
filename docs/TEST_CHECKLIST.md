# In-game test checklist (Pathwise 0.3.0-dev)

Run sections 1-8 on a new Undead character, 9-11 on an Undead Mage with
Tailoring and Enchanting, and the rest on any character, on the Forever client
(or beta). Note the build first: `/run print(GetBuildInfo())`. Turn on the
recorder for the whole run (`/pw record on`) and attach
`WTF/Account/<ACCOUNT>/SavedVariables/Pathwise.lua` to your report: that file is
what lets us fix coordinates.

Before you start, the offline checks should pass:

```sh
lua tests/run.lua
lua tools/validate_routes.lua
```

## 1. Install and load

- [ ] `Pathwise`, `Pathwise_UI`, `Pathwise_Gear` and `Pathwise_Bags` are in `_forever_/Interface/AddOns/` (or `_classic_beta_/...`), with `Pathwise_Forever.toc` directly inside `Pathwise`.
- [ ] After a full game restart, the AddOns list shows all four and does not mark them out of date.
- [ ] With Pathwise UI turned off in the AddOns list: no Lua errors, one chat line saying Pathwise UI is off, no windows; quests at their NPC and `/pw where` still work. Turn it back on.
- [ ] Login shows no Lua errors (`/console scriptErrors 1` first, or use BugSack).
- [ ] No "does not report itself as World of Warcraft: Forever" warning.

## 2. Guide window

- [ ] At Undertaker Mordo the guide shows "Tirisfal Glades", step 1, "Undertaker Mordo" and Accept Rude Awakening.
- [ ] Dragging the header moves it; the position survives `/reload`.
- [ ] Compact mode, window size and opacity (Settings) work; the close button hides it and the minimap button brings it back.
- [ ] Back and Next look at other steps; the step counter and "Then" follow.

## 3. Looks

- [ ] Modern is the default: dark, flat, thin lines, ice-blue accents, the Inter font.
- [ ] Settings > Look > Classic says it takes effect after a reload; "Reload now" reloads.
- [ ] In Classic: the guide window and every side panel have the game's dialog border; Back, Skip and Next are the game's red buttons; close buttons are the game's; headings are gold in the game's font; boxes have the tooltip border.
- [ ] In Classic: the Pathwise Bags window and Pathwise Gear's panel look the same way; the arrow and the minimap buttons are gold; nothing overlaps the border.
- [ ] Note any border art or button that looks wrong on Forever (screenshot).
- [ ] `/pw style modern` and a reload bring Modern back.

## 4. Waypoint, arrow and pins

- [ ] The arrow points at the step's place and the distance counts down in yards; "Arrived" when you get there.
- [ ] The game's own map pin and in-world marker sit at the same place; `/pw waypoint off` removes them and keeps the arrow.
- [ ] A map pin you place yourself stays: the guide moving on does not replace it and clearing the arrow does not remove it; once you remove it, Pathwise's pin comes back with the next target.
- [ ] World map and minimap pins show the step's places and the objective's monsters.
- [ ] `/pw where` prints the map ID, "Tirisfal Glades" and coordinates.

## 5. Quests at their NPC

- [ ] Talking to Undertaker Mordo accepts Rude Awakening; the guide moves on.
- [ ] Holding Shift while you open an NPC's dialog leaves it to you.
- [ ] Handing in at Shadow Priest Sarvis completes without clicks when there is no reward to choose.
- [ ] With a reward to choose, the dialog stays open and chat says "pick your reward".
- [ ] Quests not on the route are not accepted. Note any NPC whose dialog was not handled.
- [ ] Settings > Quests at their NPC: each switch works; `/pw auto off` stops it all.

## 6. Following the route

- [ ] Objectives update live; steps tick off as quests are taken, completed and handed in.
- [ ] Your class's quests show and others' don't (try two classes if you can).
- [ ] Skip offers "just this quest" or "with its follow-ups" and nearby alternatives; a picked alternative goes first, then the route resumes.
- [ ] A finished zone hands over to the next route by itself.

## 7. Dungeons

- [ ] The Dungeons panel lists the dungeons for your level with their quests; "Go to the entrance" points the arrow there.

## 8. Party sync (two players with Pathwise)

- [ ] Both turn on Settings > Party (or `/pw sync on`) and group up: each sees the other under "Party" in the guide window within a few seconds.
- [ ] Leaving the group clears the line; with sync off on one side nothing from that player appears.
- [ ] No errors during a boss fight (nothing is sent in chat lockdown).

## 9. Professions (Undead Mage with Tailoring and Enchanting)

- [ ] The Professions panel lists both with the same skill and cap as your character sheet; skilling up updates it.
- [ ] Open the Tailoring window once: the Tailoring page shows the best craft's colour and "Skill-up chance ... (from your profession window)". This is the first in-game check of reading recipes one by one; note if nothing changes.
- [ ] The page shows the materials for the next crafts (and "make from" for missing bolts), the next rank with what it asks, recipes to learn, and the materials for the rank, matching your bags.
- [ ] Learning a recipe at the trainer removes it from "Learn at a trainer".
- [ ] Getting materials for the next craft prints one "you have materials for" line, not one per bag update; `/pw reminders off` stops it.
- [ ] The Enchanting page lists disenchantable gear with the skill it asks.

## 10. Detours

- [ ] With materials for the next craft, the card under the step offers "Craft N ..." with Go, Later and the cross.
- [ ] Go keeps the route's step and number; quests still move the route on. The craft detour finishes on its own when the materials run out or the target skill is reached.
- [ ] Later hides it until the route moves to another step; the cross hides it for good, also after `/reload`; Settings brings skipped detours back.
- [ ] At level 10 with Tailoring 50, near a Tailoring trainer, the card offers "Train Journeyman Tailoring"; Go points the arrow at the trainer; training finishes the detour and the arrow goes back to the route.
- [ ] Following a profession beside your route shows its next step when it is on the way; Speed, Balanced and Crafting change how near it must be; the card's switch turns it off.

## 11. Feedback Center

- [ ] The flag in the footer opens "Report this step" with the step's route, number, title, quest IDs, goals and waypoint; nothing about the route or quests changes.
- [ ] Without a route (a character no route is for), `/pw report` says so and opens a general report, with no "Guide step" type.
- [ ] Character details and diagnostics say "not included" until you turn them on.
- [ ] "Prepare report" without a description, or without a problem, says what is missing.
- [ ] The prepared text can be selected and copied (Ctrl+C) but not edited; the panel says "not sent" and names Discord and the email address.
- [ ] Typed text survives `/reload`; each step keeps its own draft; "Discard draft" removes only the current one.

## 12. Recorder

- [ ] With `/pw record on`, accepting and handing in quests prints "recorded ..." with the NPC and place; opening a trainer window records the trainer.
- [ ] After `/reload`, `lua tools/recorder_to_route.lua <SavedVariables/Pathwise.lua>` writes a route with those places.

## 13. Pathwise Gear and Pathwise Bags

- [ ] Gear: upgrade lines on item tooltips, the stat priority for your spec, Best in Slot (Level).
- [ ] Bags: the bag key opens the Pathwise bag window and the next press closes it; "Sell junk" at a vendor sells only greys and items you marked.
- [ ] Turning either off in the AddOns list leaves Pathwise working.

## 14. The game's Settings window

- [ ] Esc > Options > AddOns > Pathwise shows the version, the look buttons and buttons that open Pathwise's settings, the guide and feedback.

## 15. Compatibility

- [ ] `/pw`, `/pathwise`, `/fl` and `/foreverlevels` all toggle the guide.
- [ ] The example route pack (`ForeverLevels:RegisterRoute`) loads and is listed under Routes > More guides.
- [ ] Coming from a ForeverLevels build: the guide finds your place from your quest log; settings start fresh.

## 16. Instances and edge cases

- [ ] Inside an instance the arrow hides; no Lua errors.
- [ ] Abandoning a quest the step needs does not break the guide.
- [ ] Gamepad mode: everything works from the windows and the minimap button without slash commands.

## Reporting

For each failed item give: build, character race/class/level, the route and
step (or a Report this step text), what you expected, what happened, and your
SavedVariables file.

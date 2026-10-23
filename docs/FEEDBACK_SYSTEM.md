# Feedback system

Pathwise has one place for feedback: the Feedback Center, a panel beside the
guide window. Players use it to prepare reports about a guide step, bug reports
and suggestions, then copy the text into Pathwise's Discord
(https://discord.gg/hSDjBrG8EK) or an email to pathwise.nn@gmail.com.

Pathwise never sends anything. A WoW addon cannot send email or make web
requests, and it must never contain passwords or API keys. The panel says
"Report ready, not sent" and where to send it.

Code: `Core/Feedback.lua` (collecting, drafts, building and formatting reports)
and `Pathwise_UI/UI/Feedback.lua` (the panel).

## Opening it

| Way | Opens |
|---|---|
| The flag in the guide window's footer (Report this step) | A report about the step shown, filled in |
| `/pw report`, the minimap button's menu, the Report key binding, Waypoint & tools | The same; without a step it says so and opens a general report |
| `/pw feedback` (also `/pw bug`, `/fl feedback`), Settings > "Report a bug or make a suggestion", About, the page in the game's Settings window | A general report (bug or suggestion) |

Opening it only reads the guide: it does not move, skip or complete the step,
the route or any quest.

## Report this step

1. Click the flag. The panel opens with type "Guide step" and the step from the
   guide: route and id, step number and total, the first open step, title and
   instructions, its goals (each with its status, and for quests whether they
   are in the log, done or ready, with objective counts), the quest IDs, and
   where the arrow leads (map, coordinates, name).
2. Pick what is wrong:
   - Incorrect waypoint or coordinates
   - Wrong NPC location
   - Quest missing or unavailable
   - Quest objectives are incorrect
   - Quest does not complete or advance
   - Incorrect class or race requirements
   - Incorrect profession instructions
   - Missing quest or leveling step
   - Other issue
3. Describe what happened (required). Optional: correct coordinates (with a
   "Use my position" button), correct NPC name, suggested instructions.
4. Look at "Information in this report": what will be included. Character
   details (level, race, class, faction) and diagnostics (game build, your
   position, the arrow's target, the active detour, the look, auto quest
   settings, the data version) are "not included" until you turn them on.
5. Click "Prepare report". The text appears in a box you can select but not
   edit: click it, Ctrl+C, and paste it into Discord or an email.

Bug reports have "Steps to reproduce"; suggestions only need a description.

## Drafts

What you type is saved as you type, in `PathwiseSettings.feedback.drafts`
(account-wide): one draft per guide step (route and step number) and one
general draft. They survive `/reload` and logging out until you click "Discard
draft"; preparing a report keeps it, as Pathwise cannot know whether you sent
it. The 20 most recently used drafts are kept.

## Report format

```
PATHWISE - GUIDE STEP REPORT

Report type: Guide step - Incorrect waypoint or coordinates
Route: Tirisfal Glades (forever/horde/undead/01-tirisfal-glades)
Step: 1/70 (first open step: 1)
Step title: Undertaker Mordo
Instructions: You rise in the crypt at the south end of Deathknell. ...
Quest IDs: 363 (accept: Rude Awakening)
Waypoint: 30.2, 71.7 Tirisfal Glades (map 1420), Undertaker Mordo
Goals:
  1. open: accept 363 Rude Awakening  [log: not in log]
Zone: Tirisfal Glades
Addon version: Pathwise 0.3.0-dev

Player description:
The arrow points to the wrong place.

Correct coordinates:
30.5, 70.9 Tirisfal Glades

Character: not included
Diagnostics: not included

Report data (format 2): format=2; type=step; category=waypoint; addon=0.3.0-dev; zone=Tirisfal Glades; route=forever/horde/undead/01-tirisfal-glades; step=1; live=1; quests=363; waypoint=30.2,71.7; map=1420

Send to: Pathwise's Discord (https://discord.gg/hSDjBrG8EK) or pathwise.nn@gmail.com
```

(The values are an example.)

The "Report data" line repeats the key facts as `key=value` pairs separated by
`; `. Inside values, `\n`, `\e` and `\s` stand for a newline, `=` and `;`, and
`\\` for a backslash. `Feedback.ParseKeyValue()` reads it back. Format 2 (this
one) numbers steps and adds `live`; format 1, from the ForeverLevels builds,
had `stepId`, `routeVersion` and `verified`.

## Structured report (for a future portal)

`Feedback.Build(draft)` returns one table that the text is rendered from:

| Field | Meaning |
|---|---|
| `format` | Report format version (2) |
| `type` | `step`, `bug` or `suggestion` |
| `category` | Step problem key, e.g. `waypoint`, `npc_location`, `no_advance` |
| `description` | The player's text |
| `corrections` | `coordinates`, `npc`, `instructions`, `reproduction` (may be empty) |
| `step` | `routeId`, `routeTitle`, `stepIndex`, `stepCount`, `liveStep`, `stepTitle`, `stepText`, `quests[]` (`id`, `kind`, `name`), `goals[]` (`verb`, `status`, `text`, `quest`, `name`, `log`), `waypoint` (`map`, `x`, `y`, `zone`, `name`), `extra` |
| `addonVersion`, `zone` | Always present |
| `character` | Only when the player turned it on |
| `diagnostics` | Only when the player turned it on |

## Future feedback portal (not built)

Not implemented until separately agreed. What the format is prepared for: a web
form or pasted text that gives each report a ticket, groups likely duplicates
by `route + step + category`, and lets maintainers mark them Open,
Investigating, Fixed or Closed, with every credential on the server. The addon
keeps working offline: it only ever prepares text.

## Privacy

Nothing leaves the game unless the player copies it. Character details and
diagnostics are off by default and shown in the preview before they are
included. Reports contain no account name, character name, realm or chat text.

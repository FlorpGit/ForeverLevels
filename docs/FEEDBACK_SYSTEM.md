# Feedback system

Pathwise has one place for feedback: the Feedback Center. Players use it to prepare
bug reports, suggestions and guide step reports, then copy the text and email it to
pathwise.nn@gmail.com.

Pathwise never sends anything. A WoW addon cannot send email or make web requests, and
it must never contain passwords or API keys. The window says "Report ready, not sent"
and tells the player where to send it.

Code: `Core/Feedback.lua` (collecting, drafts, building and formatting reports) and
`UI/FeedbackCenter.lua` (the window).

## Opening it

| Way | Opens |
|---|---|
| Report button (ticket icon) next to Back on the guide window | A guide step report with the current step filled in |
| `/pathwise report` | Same as the button. Without an active step it explains that and opens a general report |
| `/pathwise feedback` (also `/fl feedback`, `/pathwise bug`) | A general report (bug or suggestion) |
| Options panel: "Report a bug or make a suggestion" | A general report |

The report button only shows while a guide step is active. Its tooltip reads "Report an
issue with this guide step." Clicking it only reads the step: it does not advance, skip,
complete or otherwise change the step, route progress or quest state.

## Report this step workflow

1. Click the report button. The Feedback Center opens with type "Guide step" and the
   step's details collected from the guide: route name and id, step number and total,
   step title and instructions, quest IDs for the step's goals that apply to your
   character, the step's waypoint and map, your zone, the Pathwise version, the route's
   version if the route sets `version`, and whether the step is verified.
2. Pick what is wrong:
   - Incorrect waypoint or coordinates
   - Wrong NPC location
   - Quest missing or unavailable
   - Quest objectives are incorrect
   - Quest does not auto-complete or advance
   - Incorrect class or race requirements
   - Incorrect profession instructions
   - Missing quest or leveling step
   - Other issue
3. Describe what happened (required). Optional: correct coordinates (with a "Use my
   position" button), correct NPC name, suggested instructions, steps to reproduce.
   Nobody needs to know quest IDs; Pathwise adds them.
4. Review "Information in this report". It is read-only and shows exactly what will be
   included. Character details (level, race, class, faction) and diagnostics (game
   build, your map position, the arrow's current target, active detour, window style,
   automation settings) are listed as "not included" until you turn them on.
5. Click "Prepare report". The finished text appears in a box you can select but not
   edit. Click it, press Ctrl+A, then Ctrl+C, and email it to pathwise.nn@gmail.com.

General reports work the same way, without the step section. Bug reports show the
"steps to reproduce" field; suggestions only need a description.

## Drafts

Drafts are saved as you type, in `ForeverLevelsDB.feedback.drafts`: one per guide step
(keyed by route and step id) and one general draft. They survive `/reload` and logout.
A draft stays until you click "Discard draft". Preparing a report does not delete it,
since Pathwise cannot know whether you sent it. The 20 most recently used drafts are
kept.

## Report format

```
PATHWISE - GUIDE STEP REPORT

Report type: Guide step - Incorrect waypoint or coordinates
Route: Undead 6-10: Brill (fl.horde.undead.02-brill)
Route version: not set
Step: 4/12 (br-inn)
Step title: Gallows' End Tavern
Instructions: Turn in A Rogue's Deal to Innkeeper Renee and make Brill your home.
Quest IDs: 8 (turn in: A Rogue's Deal)
Waypoint: 61.7, 52.0 Tirisfal Glades (map 2001)
Step verification: Unverified
Zone: Tirisfal Glades
Addon version: Pathwise 0.2.0-alpha.1

Player description:
The arrow points to the wrong location.

Correct coordinates:
62.1, 51.4 Tirisfal Glades

Character: not included
Diagnostics: not included

Report data (format 1): format=1; type=step; category=waypoint; addon=0.2.0-alpha.1; zone=Tirisfal Glades; route=fl.horde.undead.02-brill; step=4; stepId=br-inn; quests=8; verified=no; waypoint=61.7,52.0; map=2001

Send to: pathwise.nn@gmail.com
```

(Values are an example; the map number comes from the player's client.)

The "Report data" line repeats the key facts as `key=value` pairs separated by `; `.
Inside values, `\n`, `\e` and `\s` stand for a newline, `=` and `;`, and `\\` for a
backslash. `Feedback.ParseKeyValue()` reads it back.

## Structured report (for a future portal)

`Feedback.Build(draft)` returns one table that the text format is rendered from. A
future Pathwise Feedback Portal can accept the same fields:

| Field | Meaning |
|---|---|
| `format` | Report format version (1) |
| `type` | `step`, `bug` or `suggestion` |
| `category` | Step problem key, e.g. `waypoint`, `npc_location`, `no_advance` |
| `description` | Player's text |
| `corrections` | `coordinates`, `npc`, `instructions`, `reproduction` (may be empty) |
| `step` | `routeId`, `routeTitle`, `routeVersion`, `stepIndex`, `stepCount`, `stepId`, `stepTitle`, `stepText`, `quests[]` (`id`, `kind`, `name`), `waypoint` (`x`, `y`, `zone`, `mapID`), `verified` |
| `addonVersion`, `zone` | Always present |
| `character` | Only when the player opted in |
| `diagnostics` | Only when the player opted in |
| `recipient` | pathwise.nn@gmail.com |

## Future feedback portal (not built)

Not implemented until separately approved. The design the formatter is prepared for:

- Accept bug reports, suggestions and guide step reports, either pasted text (parsed
  from the "Report data" line plus the readable sections) or a web form with the same
  fields.
- Give each report a ticket ID and forward a notification to pathwise.nn@gmail.com.
- Categorize by route, step and problem type, and group likely duplicates by
  `route + stepId + category`.
- Let maintainers set a status: Open, Investigating, Fixed, Closed.
- Keep all credentials on the server. The addon keeps working offline: it only ever
  prepares text, and at most could show a portal address for the player to visit.

## Privacy

Nothing leaves the game unless the player copies it. Character details and diagnostics
are off by default and shown in the preview before they are included. Reports contain
no account name, character name, realm or chat text.

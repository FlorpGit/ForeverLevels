# Changelog

## 0.2.0-alpha.4 (unreleased)

- New default window style "Pathwise" in the logo's colors (blue-black background, silver frame and headings, ice-blue titles, steel-blue buttons), used by the guide, detour banner, dashboard, Feedback Center and arrow label. Classic, tooltip and minimal remain (`/pathwise style`). Settings saved by earlier builds keep the style they had; switch with `/pathwise style pathwise`.

## 0.2.0-alpha.3 - Phase 2 test build (pre-release, 2026-10-22)

- Renamed to "Pathwise: Leveling Guide & Professions". The addon folder and TOC files are now `Pathwise`; the GitHub repository is FlorpGit/Pathwise. Internal names (`ForeverLevelsDB`, the `ForeverLevels` global, `/fl`, the sync prefix) are unchanged. Testers of earlier builds: see Compatibility in the README.

- License change: code is now GPL-3.0-only (Copyright The Pathwise Authors), with an additional permission letting data-only route and profession packs use any license, and a section 7(e) term reserving the Pathwise names. Bundled guide data stays CC BY-SA 4.0. Earlier ForeverLevels versions remain MIT. Adds NOTICE.md, TRADEMARKS.md and CREDITS.md.
- Renamed to Pathwise ("Every quest. Every craft. Every level.", by leight_nn & florp). `/pathwise` is the main command; `/fl`, `/foreverlevels`, `ForeverLevels:RegisterRoute()`, the addon folder and saved progress all keep working. About section in the options panel.
- Profession tracking: detects professions, skill and cap; reads learned recipes, difficulty and the client's reagent lists while a profession window is open; counts materials in bags (bank optional).
- Profession data registry (`Pathwise:RegisterProfessionData`) with validation and verification flags. Starter Tailoring and Enchanting data checked against Wowhead's Forever database; unverified values are labeled.
- Material planner: next craft, expected crafts with the source of every estimate, owned and missing materials, intermediate expansion, reservations across steps, one-time material reminders.
- Optional profession detours under the guide window (Go, Later, Skip; Done, Cancel). They never change route progress, step numbers or Back/Next; an active detour with coordinates temporarily takes over the arrow.
- Profession dashboard in all three window styles, with profession settings.
- SavedVariables version 2 with an in-place upgrade from version 1.
- Recorder also logs trainer positions.
- Example profession data pack; the offline validator checks profession data too.
- Feedback Center (`/pathwise feedback`) for bug reports, suggestions and guide step reports, with a "Report this step" ticket button next to Back that fills in the current step. Reports are prepared as copyable text for pathwise.nn@gmail.com and never sent automatically. Character details and diagnostics are opt-in. Drafts are saved per step. SavedVariables version 3.

## 0.1.0 - MVP (unreleased)

- Classic window style (dialog border used by the classic UI) as the default, plus tooltip and minimal styles. `/fl style` or the options panel.

- Movable step-by-step guide window with live quest objectives, Back/Next, lock and scale.
- Quest detection: accept, objectives complete, turn-in and level goals; auto-advance; skip; fast-forward on login.
- Automatic accept and turn-in for route quests (gossip, greeting and quest dialogs), Shift to pause, no reward auto-pick.
- Waypoints: Blizzard map pin + in-world marker (super-tracked user waypoint) and a ForeverLevels direction arrow with distance.
- Class- and race-filtered steps and goals; per-class step text.
- Route registry with validation, route chaining and a public `ForeverLevels:RegisterRoute()` for community route addons.
- Dungeon suggestions by level.
- Optional party progress sync over addon messages, respecting Forever's lockdown rules.
- SavedVariables: per-character route progress, account-wide settings.
- Recorder for route authors plus offline tools (`validate_routes.lua`, `recorder_to_route.lua`).
- Draft routes: Undead 1-6 Deathknell, Undead 6-10 Brill (coordinates not yet verified on Forever).
- Offline test suite against a WoW API stub; CI on Lua 5.1 and 5.4.

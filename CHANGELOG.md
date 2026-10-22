# Changelog

## 0.1.0 - MVP (unreleased)

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

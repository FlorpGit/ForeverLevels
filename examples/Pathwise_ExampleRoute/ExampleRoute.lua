-- SPDX-License-Identifier: CC0-1.0
-- Example community route pack for Pathwise. It calls the older name,
-- ForeverLevels:RegisterRoute, on purpose: packs written that way still
-- register. Pathwise.RegisterRoute and Pathwise:RegisterRoute are the same.
-- Copy this folder, rename it (folder name, .toc name and route id), and edit.
-- Full format: docs/ROUTE_FORMAT.md in the Pathwise repository.
--
-- A route lists goals; Pathwise fills in quest names, givers, finishers,
-- objectives and places from its quest data. `at` and `who` override them
-- (here: places checked in game with /pw record on).
--
-- This example is released under CC0 1.0 so you can reuse it freely. Your
-- own route can use any license you like (see NOTICE.md in Pathwise).

local Pathwise = _G.Pathwise or _G.ForeverLevels
if not Pathwise then return end

Pathwise:RegisterRoute({
	id = "example/horde/undead/deathknell-sprint",
	title = "Example: Deathknell sprint",
	-- Not "Leveling", so it is never picked for a character on its own; it is
	-- listed under Routes > More guides.
	category = "Miscellaneous",
	faction = "Horde",
	races = { "Scourge" },
	levels = { 1, 3 },
	map = 1420, -- Tirisfal Glades

	steps = {
		{ title = "Talk to Mordo", note = "Speak with Undertaker Mordo outside the crypt.",
			{ "accept", 363, at = { 1420, 30.2, 71.6 }, who = "Undertaker Mordo" } },
		{ title = "Find Sarvis", note = "Run north to Shadow Priest Sarvis.",
			{ "turnin", 363 }, { "accept", 364 } },
		{ title = "Zombies", note = "Kill zombies in the graveyard.",
			{ "complete", 364 } },
		{ title = "Hand in", note = "Back to Sarvis. This example ends here.",
			{ "turnin", 364 } },
	},
})

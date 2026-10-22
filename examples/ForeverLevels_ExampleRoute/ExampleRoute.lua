-- Example community route pack for ForeverLevels.
-- Copy this folder, rename it (folder name, .toc name and route id), and edit.
-- Full schema: docs/ROUTE_FORMAT.md in the ForeverLevels repository.
--
-- This example is released under CC0 1.0 so you can reuse it freely. Your own
-- route can use any license you like; declare it in the 'license' field.

local ForeverLevels = _G.ForeverLevels
if not ForeverLevels then return end

ForeverLevels:RegisterRoute({
	apiVersion = 1,
	id = "example.horde.undead.deathknell-sprint",
	title = "Example: Deathknell sprint",
	author = "Your Name",
	license = "CC0 1.0",
	faction = "Horde",
	races = { "Scourge" },
	levels = { 1, 3 },
	zone = "Tirisfal Glades",
	hidden = true,   -- never auto-selected; pick it with /fl route <id>

	quests = {
		[363] = "Rude Awakening",
		[364] = "The Mindless Ones",
	},

	steps = {
		{
			id = "start",
			title = "Talk to Mordo",
			text = "Speak with Undertaker Mordo outside the crypt.",
			x = 30.2, y = 71.6,
			accept = { 363 },
		},
		{
			id = "sarvis",
			title = "Find Sarvis",
			text = "Run north to Shadow Priest Sarvis.",
			x = 30.9, y = 66.3,
			turnin = { 363 },
			accept = { 364 },
		},
		{
			id = "zombies",
			title = "Zombies",
			text = "Kill zombies in the graveyard.",
			x = 32.6, y = 68.4,
			complete = { 364 },
		},
		{
			id = "done",
			title = "Hand in",
			text = "Return to Sarvis. This example ends here; press Next to finish.",
			x = 30.9, y = 66.3,
			turnin = { 364 },
		},
	},
})

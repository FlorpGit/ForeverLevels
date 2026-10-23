-- Route: Tirisfal Glades, Undead, levels 1-10 (Deathknell, then Brill).
-- Quest ids are QuestieDB's (Pathwise/Data/Data.lua); names, givers,
-- finishers, objectives and places come from the data, so none are typed here.
-- First draft, written from the data: play-test before calling it final.
-- Class quests are listed for every class; the engine shows each character
-- only its own (the data's class masks).

Pathwise.RegisterRoute({
	id = "horde/undead/tirisfal",
	title = "Tirisfal Glades",
	map = 1420,
	levels = { 1, 10 },
	faction = "Horde",
	races = { 5 }, -- Undead
	steps = {
		-- Deathknell
		{ { "accept", 363 } },
		{ { "turnin", 363 }, { "accept", 364 } },
		{ { "accept", 376 }, { "accept", 1470 } },
		{ title = "North of Deathknell", note = "Zombies, young scavengers and duskbats in the fields north of the church.",
			{ "complete", 364 }, { "complete", 376 }, { "complete", 1470 } },
		{ { "turnin", 364 }, { "accept", 3901 },
			{ "accept", 3095 }, { "accept", 3096 }, { "accept", 3097 }, { "accept", 3098 }, { "accept", 3099 }, { "accept", 98601 } },
		{ title = "Your class trainer", note = "Read the scroll, then hand it to your trainer.",
			{ "turnin", 3095 }, { "turnin", 3096 }, { "turnin", 3097 }, { "turnin", 3098 }, { "turnin", 3099 }, { "turnin", 98601 } },
		{ { "turnin", 376 }, { "accept", 6395 } },
		{ { "turnin", 1470 } },
		{ { "accept", 3902 } },
		{ { "accept", 380 } },
		{ title = "Around Deathknell", note = "Rattlecage skeletons to the north; scavenged goods in boxes around the village; Marla's grave is beside the church.",
			{ "complete", 3901 }, { "complete", 3902 }, { "complete", 6395 } },
		{ { "turnin", 3901 } },
		{ { "turnin", 3902 } },
		{ { "turnin", 6395 } },
		{ title = "Night Web's Hollow", note = "The spider cave west of Deathknell.", { "complete", 380 } },
		{ { "turnin", 380 }, { "accept", 381 } },
		{ title = "Scarlet converts", note = "East of Deathknell.", { "complete", 381 } },
		{ { "turnin", 381 }, { "accept", 382 } },
		{ title = "Meven Korgal", note = "The Scarlet messenger at the Crusader camp.", { "complete", 382 } },
		{ { "turnin", 382 }, { "accept", 383 }, { "accept", 96656 } },

		-- The road to Brill
		{ { "accept", 8 } },
		{ { "accept", 5481 } },
		{ { "accept", 365 } },
		{ title = "Pumpkins and Gloom Weed", note = "Pumpkins at the farm west of the road; Gloom Weed along the way to Brill.",
			{ "complete", 365 }, { "complete", 5481 } },

		-- Brill
		{ { "turnin", 383 }, { "accept", 427 } },
		{ note = "Make the inn your home while you are here.", { "turnin", 8 } },
		{ { "turnin", 365 }, { "accept", 407 }, { "accept", 367 } },
		{ { "turnin", 407 } },
		{ { "accept", 404 } },
		{ { "accept", 358 } },
		{ { "turnin", 5481 }, { "accept", 5482 } },
		{ { "turnin", 96656 } },
		{ title = "Around Brill", note = "Rotting Dead and darkhounds near the road, Doom Weed and the Rot Hide gnolls to the north.",
			{ "complete", 404 }, { "complete", 367 }, { "complete", 5482 }, { "complete", 358 } },
		{ { "turnin", 404 }, { "accept", 426 } },
		{ { "turnin", 367 }, { "accept", 368 } },
		{ { "turnin", 5482 } },
		{ { "turnin", 358 }, { "accept", 359 } },
		{ title = "Scarlet warriors", note = "At the Crusader outpost west of Brill.", { "complete", 427 } },
		{ title = "The mills and the lake", note = "Rattlecage soldiers and Darkeye bonecasters at the mills; Vile Fin murlocs by the lake.",
			{ "complete", 426 }, { "complete", 368 } },
		{ { "turnin", 359 }, { "accept", 360 } },
		{ { "turnin", 427 }, { "accept", 370 }, { "accept", 374 } },
		{ { "turnin", 426 } },
		{ { "turnin", 368 } },
		{ { "turnin", 360 } },
		{ title = "Level 10", { "level", 10 } },
	},
})

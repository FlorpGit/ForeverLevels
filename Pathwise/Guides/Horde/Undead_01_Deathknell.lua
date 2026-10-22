-- SPDX-License-Identifier: CC-BY-SA-4.0
-- ForeverLevels route: Undead 1-6, Deathknell.
-- Guide data license: CC BY-SA 4.0 (see Guides/LICENSE.md). Original route by
-- The Pathwise Authors. Quest IDs are game facts; the ordering, text and
-- notes are written for this project.
--
-- STATUS: draft. Quest IDs match the 2004 game and are present in Forever's quest
-- data, but coordinates are approximate and have not been walked on Forever yet.
-- Forever adds new Deathknell quests (including an Undead Paladin path) that are
-- not in this route yet. Use /pathwise record to help verify and extend it.

local _, FL = ...

FL:RegisterRoute({
	id = "fl.horde.undead.01-deathknell",
	title = "Undead 1-6: Deathknell",
	author = "The Pathwise Authors",
	license = "CC BY-SA 4.0",
	faction = "Horde",
	races = { "Scourge" },
	levels = { 1, 6 },
	zone = "Tirisfal Glades",
	next = "fl.horde.undead.02-brill",

	quests = {
		[363] = "Rude Awakening",
		[364] = "The Mindless Ones",
		[3901] = "Rattling the Rattlecages",
		[376] = "The Damned",
		[3095] = "Simple Scroll",
		[3096] = "Encrypted Scroll",
		[3097] = "Hallowed Scroll",
		[3098] = "Glyphic Scroll",
		[3099] = "Tainted Scroll",
		[1470] = "Piercing the Veil",
		[3902] = "Scavenging Deathknell",
		[380] = "Night Web's Hollow",
		[381] = "The Scarlet Crusade",
		[6395] = "Marla's Last Wish",
		[382] = "The Red Messenger",
		[383] = "Vital Intelligence",
	},

	steps = {
		{
			id = "dk-mordo",
			title = "Wake up",
			text = "Step out of the crypt and speak with Undertaker Mordo right outside.",
			x = 30.2, y = 71.6,
			accept = { 363 },
		},
		{
			id = "dk-sarvis-1",
			title = "Report to Sarvis",
			text = "Follow the path north to Shadow Priest Sarvis in front of the Deathknell church.",
			x = 30.9, y = 66.3,
			turnin = { 363 },
			accept = { 364 },
		},
		{
			id = "dk-mindless",
			title = "Thin out the zombies",
			text = "Kill Mindless and Wretched Zombies in the graveyard around the crypt you came from.",
			x = 32.6, y = 68.4,
			complete = { 364 },
		},
		{
			id = "dk-sarvis-2",
			title = "Back to the church",
			text = "Turn in to Sarvis, then pick up the new work around the church, including your class scroll if one is offered, and Novice Elreth's request.",
			x = 30.9, y = 66.3,
			note = "Undead Paladins: Forever adds a Paladin path here that this draft does not cover yet.",
			turnin = { 364 },
			accept = {
				3901, 376,
				{ 3095, class = { "WARRIOR" } },
				{ 3096, class = { "ROGUE" } },
				{ 3097, class = { "PRIEST" } },
				{ 3098, class = { "MAGE" } },
				{ 3099, class = { "WARLOCK" } },
			},
		},
		{
			id = "dk-class-trainer",
			title = "Visit your trainer",
			text = "Deliver your scroll to your class trainer near the church and learn your first new spell.",
			x = 31.2, y = 65.9,
			classText = {
				WARRIOR = "Dannal Stern is your trainer.",
				ROGUE = "David Trias is your trainer.",
				PRIEST = "Dark Cleric Duesten is your trainer, inside the church.",
				MAGE = "Isabella is your trainer, inside the church.",
				WARLOCK = "Maximillion is your trainer. Also take Piercing the Veil from Venya Marthand nearby.",
			},
			turnin = {
				{ 3095, class = { "WARRIOR" } },
				{ 3096, class = { "ROGUE" } },
				{ 3097, class = { "PRIEST" } },
				{ 3098, class = { "MAGE" } },
				{ 3099, class = { "WARLOCK" } },
			},
			accept = {
				{ 1470, class = { "WARLOCK" } },
			},
		},
		{
			id = "dk-fields",
			title = "Skeletons, scavengers and bats",
			text = "Work the fields north and east of the church: Rattlecage Skeletons for Sarvis, Scavengers and Duskbats for Elreth.",
			x = 33.8, y = 62.0,
			note = "Warlocks: the skeletons also drop what Venya needs.",
			complete = { 3901, 376, { 1470, class = { "WARLOCK" } } },
		},
		{
			id = "dk-church-2",
			title = "Turn in at the church",
			text = "Hand in to Sarvis and Elreth. Deathguard Saltain and Executor Arren have new orders.",
			x = 31.2, y = 65.8,
			turnin = { 3901, 376, { 1470, class = { "WARLOCK" } } },
			accept = { 3902, 380 },
		},
		{
			id = "dk-scavenge",
			title = "Scavenging Deathknell",
			text = "Search the ruined houses around Deathknell for scavenged goods (look for crates and sacks).",
			x = 34.4, y = 63.2,
			complete = { 3902 },
		},
		{
			id = "dk-spiders",
			title = "Night Web's Hollow",
			text = "Head west to the spider cave. Clear the young spiders near the mouth first, the bigger ones are deeper inside.",
			x = 27.0, y = 59.2,
			complete = { 380 },
		},
		{
			id = "dk-church-3",
			title = "Report back",
			text = "Return to Saltain and Arren. Arren sends you after the Scarlet Crusade; Elreth asks you to put Marla's husband to rest.",
			x = 31.6, y = 65.6,
			turnin = { 3902, 380 },
			accept = { 381, 6395 },
		},
		{
			id = "dk-scarlet",
			title = "The Scarlet camp",
			text = "East of Deathknell the Scarlet Crusade has camped. Collect armbands from Converts and Initiates, and take Samuel Fipps' remains.",
			x = 36.8, y = 61.4,
			complete = { 381 },
		},
		{
			id = "dk-marla",
			title = "Marla's grave",
			text = "Bury Samuel's remains at Marla's grave in the small graveyard north of the church.",
			x = 31.6, y = 61.8,
			complete = { 6395 },
		},
		{
			id = "dk-church-4",
			title = "Arren's next order",
			text = "Turn in to Arren and Elreth. Arren wants the Scarlet messenger stopped.",
			x = 31.6, y = 65.6,
			turnin = { 381, 6395 },
			accept = { 382 },
		},
		{
			id = "dk-meven",
			title = "The Red Messenger",
			text = "Find and kill Meven Korgal at the Scarlet camp. He hits harder than the recruits; pull him alone.",
			x = 36.6, y = 61.6,
			complete = { 382 },
		},
		{
			id = "dk-leave",
			title = "Orders for Brill",
			text = "Turn in to Arren and take Vital Intelligence. Train if you can, then follow the road east out of Deathknell.",
			x = 31.6, y = 65.6,
			turnin = { 382 },
			accept = { 383 },
		},
	},
})

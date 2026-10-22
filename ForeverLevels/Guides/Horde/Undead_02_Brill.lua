-- ForeverLevels route: Undead 6-10, the road to Brill and the town's first tasks.
-- Guide data license: CC BY-SA 4.0 (see Guides/LICENSE.md). Original route by
-- ForeverLevels contributors.
--
-- STATUS: draft, less certain than Deathknell. NPC positions in Brill and the
-- farm/lake locations are approximate, and Forever adds new Tirisfal quests that
-- are not included. Please record and correct (see CONTRIBUTING.md).

local _, FL = ...

FL:RegisterRoute({
	id = "fl.horde.undead.02-brill",
	title = "Undead 6-10: Brill",
	author = "ForeverLevels contributors",
	license = "CC BY-SA 4.0",
	faction = "Horde",
	races = { "Scourge" },
	levels = { 5, 10 },
	zone = "Tirisfal Glades",

	quests = {
		[383] = "Vital Intelligence",
		[8] = "A Rogue's Deal",
		[5481] = "Gordo's Task",
		[5482] = "Doom Weed",
		[404] = "A Putrid Task",
		[365] = "Fields of Grief",
		[367] = "A New Plague",
		[368] = "A New Plague",
	},

	steps = {
		{
			id = "br-calvin",
			title = "The house on the road",
			text = "On the road east of Deathknell, Calvin Montague waits in the ruined house. Take his deal.",
			x = 38.3, y = 56.8,
			accept = { 8 },
		},
		{
			id = "br-gordo",
			title = "Gordo on the road",
			text = "Gordo the abomination walks the road toward Brill. Take his task, then pick Gloom Weed along the roadside as you walk.",
			x = 44.6, y = 53.8,
			note = "Gordo patrols; if he is not at the marker, follow the road.",
			accept = { 5481 },
			complete = { 5481 },
		},
		{
			id = "br-zygand",
			title = "Arrive in Brill",
			text = "Deliver Vital Intelligence to Executor Zygand at the center of Brill.",
			x = 60.6, y = 51.8,
			turnin = { 383 },
		},
		{
			id = "br-inn",
			title = "Gallows' End Tavern",
			text = "Turn in A Rogue's Deal to Innkeeper Renee and make Brill your home.",
			x = 61.7, y = 52.0,
			note = "Setting your hearthstone is manual: talk to the innkeeper and choose 'Make this inn your home'.",
			turnin = { 8 },
		},
		{
			id = "br-holland",
			title = "The apothecary's helper",
			text = "Bring Gordo's Gloom Weed to Junior Apothecary Holland and take the follow-up.",
			x = 58.4, y = 48.8,
			turnin = { 5481 },
			accept = { 5482 },
		},
		{
			id = "br-town-quests",
			title = "Work in Brill",
			text = "Pick up A Putrid Task from Deathguard Dillinger, then Fields of Grief and A New Plague from Apothecary Johaan.",
			x = 59.4, y = 52.4,
			accept = { 404, 365, 367 },
		},
		{
			id = "br-graveyard",
			title = "The Brill graveyard",
			text = "Kill the walking dead around the graveyard for their claws and gather Doom Weed between the graves.",
			x = 56.4, y = 47.6,
			complete = { 404, 5482 },
		},
		{
			id = "br-turnin-1",
			title = "Back to Brill",
			text = "Turn in to Holland and Dillinger.",
			x = 58.4, y = 50.4,
			turnin = { 5482, 404 },
		},
		{
			id = "br-pumpkins",
			title = "Solliden Farmstead",
			text = "Ride west to Solliden Farmstead and gather pumpkins from the fields. Scarlet Crusaders patrol here; clear around you before looting.",
			x = 36.6, y = 49.6,
			complete = { 365 },
		},
		{
			id = "br-murlocs",
			title = "Vile Fin scales",
			text = "Kill Vile Fin murlocs at the water north of the farm for their scales. They come in pairs; fight at the shore edge.",
			x = 36.0, y = 43.0,
			complete = { 367 },
		},
		{
			id = "br-johaan",
			title = "Apothecary Johaan",
			text = "Return to Brill and turn in to Johaan. Take the next part of A New Plague; it continues past level 10.",
			x = 59.4, y = 52.4,
			turnin = { 365, 367 },
			accept = { 368 },
		},
		{
			id = "br-level-10",
			title = "Reach level 10",
			text = "Visit your class trainer in Brill. If you are short of 10, keep killing on the way to your next quests in the fields around Brill.",
			x = 61.0, y = 52.0,
			note = "Level 10 class quests and Forever's new Tirisfal content are not in this draft yet.",
			level = 10,
		},
	},
})

-- SPDX-License-Identifier: CC-BY-SA-4.0
-- Pathwise profession data: Tailoring (starter set).
-- Guide data license: CC BY-SA 4.0 (see Guides/LICENSE.md).
--
-- Verified on 2026-10-22 against Wowhead's World of Warcraft: Forever database
-- (wowhead.com/forever/spell=<id>): recipe names, direct reagents with item IDs
-- and quantities, and created items. Trainer names, titles and zones were checked
-- on wowhead.com/forever/npc=<id>.
--
-- NOT verified: skill levels (the four numbers in 'skill' are the 2004 values,
-- kept as a labeled fallback), trainer coordinates, rank caps and training levels,
-- and how items are obtained. Pathwise prefers the client's own recipe difficulty
-- and reagent lists once you open the Tailoring window.

-- Registered through the same public function a community pack calls.

local VERIFIED_REAGENTS = { reagents = true, skill = false, source = false }

Pathwise.RegisterProfessionData({
	apiVersion = 1,
	id = "pathwise.tailoring.starter",
	profession = "tailoring",
	name = "Tailoring",
	skillLine = 197,
	author = "leight_nn & florp",
	license = "CC BY-SA 4.0",
	sources = { "https://www.wowhead.com/forever/skill=197/tailoring" },

	-- Fallback rank table from the 2004 game. Forever's live cap from the client wins.
	ranks = {
		{ name = "Apprentice", trainAt = 1, maxSkill = 75, level = 5, verified = { values = false } },
		{ name = "Journeyman", trainAt = 50, maxSkill = 150, level = 10, verified = { values = false } },
		{ name = "Expert", trainAt = 125, maxSkill = 225, level = 20, verified = { values = false } },
		{ name = "Artisan", trainAt = 200, maxSkill = 300, level = 35, verified = { values = false } },
	},

	trainers = {
		{ name = "Bowen Brisboise", npc = 3523, title = "Journeyman Tailor", zone = "Tirisfal Glades", faction = "Horde",
			verified = { name = true, zone = true, coords = false, teaches = false } },
		{ name = "Josef Gregorian", npc = 4576, title = "Artisan Tailor", zone = "Undercity", faction = "Horde",
			verified = { name = true, zone = true, coords = false, teaches = false } },
	},

	items = {
		[2589] = { name = "Linen Cloth", acquire = "Drops from humanoids.", verified = { acquire = false } },
		[2592] = { name = "Wool Cloth", acquire = "Drops from humanoids.", verified = { acquire = false } },
		[2320] = { name = "Coarse Thread", acquire = "Trade supply vendors.", verified = { acquire = false } },
		[2996] = { name = "Bolt of Linen Cloth", acquire = "Tailoring: Bolt of Linen Cloth.", verified = { acquire = true } },
		[2997] = { name = "Bolt of Woolen Cloth", acquire = "Tailoring: Bolt of Woolen Cloth.", verified = { acquire = true } },
	},

	recipes = {
		{ id = 2963, name = "Bolt of Linen Cloth", creates = 2996, reagents = { { 2589, 2 } },
			skill = { 1, 25, 37, 50 }, source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 2387, name = "Linen Cloak", creates = 2570, reagents = { { 2996, 1 }, { 2320, 1 } },
			skill = { 1, 35, 47, 60 }, source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 12044, name = "Simple Linen Pants", creates = 10045, reagents = { { 2996, 1 }, { 2320, 1 } },
			skill = { 1, 35, 47, 60 }, source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 2385, name = "Brown Linen Vest", creates = 2568, reagents = { { 2996, 1 }, { 2320, 1 } },
			skill = { 10, 45, 57, 70 }, source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 8776, name = "Linen Belt", creates = 7026, reagents = { { 2996, 1 }, { 2320, 1 } },
			skill = { 15, 50, 67, 85 }, source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 3755, name = "Linen Bag", creates = 4238, reagents = { { 2996, 3 }, { 2320, 3 } },
			skill = { 45, 70, 82, 95 }, source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 2964, name = "Bolt of Woolen Cloth", creates = 2997, reagents = { { 2592, 3 } },
			skill = { 75, 90, 97, 105 }, source = "trainer", verified = VERIFIED_REAGENTS },
	},
})

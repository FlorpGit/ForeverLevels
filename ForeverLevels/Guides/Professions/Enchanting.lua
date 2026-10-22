-- Pathwise profession data: Enchanting (starter set).
-- Guide data license: CC BY-SA 4.0 (see Guides/LICENSE.md).
--
-- Forever changed Enchanting compared with the 2004 game: it adds Mote of Magic
-- (item 247786, made from Strange Dust with "Dust to Motes" or bought from vendors in
-- Undercity and Tirisfal Glades), renames several enchants and changes their reagents.
-- Older guide data is therefore wrong for Forever and is not used here.
--
-- Verified on 2026-10-22 against wowhead.com/forever/spell=<id>: names, direct
-- reagents with item IDs and quantities, created items. Trainer name, title and zone
-- checked on wowhead.com/forever/npc=4616.
--
-- NOT verified: every skill level (left out entirely, so Pathwise relies on the
-- difficulty the client reports once you open the Enchanting window), how many Motes
-- one Dust to Motes makes, rank caps, trainer coordinates, and whether a Runed Copper
-- Rod is still needed as a tool.

local _, FL = ...

local VERIFIED_REAGENTS = { reagents = true, skill = false, source = false }

FL:RegisterProfessionData({
	apiVersion = 1,
	id = "pathwise.enchanting.starter",
	profession = "enchanting",
	name = "Enchanting",
	skillLine = 333,
	author = "leight_nn & florp",
	license = "CC BY-SA 4.0",
	sources = { "https://www.wowhead.com/forever/skill=333/enchanting" },

	ranks = {
		{ name = "Apprentice", trainAt = 1, maxSkill = 75, level = 5, verified = { values = false } },
		{ name = "Journeyman", trainAt = 50, maxSkill = 150, level = 10, verified = { values = false } },
		{ name = "Expert", trainAt = 125, maxSkill = 225, level = 20, verified = { values = false } },
		{ name = "Artisan", trainAt = 200, maxSkill = 300, level = 35, verified = { values = false } },
	},

	trainers = {
		{ name = "Lavinia Crowe", npc = 4616, title = "Expert Enchanter", zone = "Undercity", faction = "Horde",
			verified = { name = true, zone = true, coords = false, teaches = false } },
	},

	items = {
		[10940] = { name = "Strange Dust", acquire = "Disenchanting low-level green items.", verified = { acquire = false } },
		[10938] = { name = "Lesser Magic Essence", acquire = "Disenchanting low-level green items.", verified = { acquire = false } },
		[247786] = { name = "Mote of Magic", acquire = "Enchanting: Dust to Motes (Strange Dust), or vendors in Undercity and Tirisfal Glades.",
			verified = { acquire = true } },
		[6217] = { name = "Copper Rod", acquire = "Trade supply vendors.", verified = { acquire = false } },
		[6218] = { name = "Runed Copper Rod", acquire = "Enchanting: Runed Copper Rod.", verified = { acquire = true } },
	},

	recipes = {
		{ id = 1245320, name = "Dust to Motes", creates = 247786, reagents = { { 10940, 1 } },
			source = "unknown", note = "Number of Motes per craft not verified.", verified = VERIFIED_REAGENTS },
		{ id = 7421, name = "Runed Copper Rod", creates = 6218, reagents = { { 6217, 1 }, { 247786, 1 } },
			source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 7418, name = "Enchant Bracer - Inferior Stamina", kind = "enchant", reagents = { { 247786, 1 } },
			source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 7420, name = "Enchant Chest - Inferior Stamina", kind = "enchant", reagents = { { 10940, 1 } },
			source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 7443, name = "Enchant Chest - Minor Intellect", kind = "enchant", reagents = { { 10938, 1 } },
			source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 7426, name = "Enchant Chest - Minor Absorption", kind = "enchant", reagents = { { 10938, 1 } },
			source = "trainer", verified = VERIFIED_REAGENTS },
		{ id = 7457, name = "Enchant Bracer - Minor Stamina", kind = "enchant", reagents = { { 10940, 2 } },
			source = "trainer", verified = VERIFIED_REAGENTS },
	},
})

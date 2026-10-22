-- ForeverLevels: dungeon suggestions by level.
-- Guide data license: CC BY-SA 4.0 (see Guides/LICENSE.md).
--
-- Level ranges are this project's own suggested windows for a party of five at
-- normal pace. Forever adds nine new dungeons; they are not listed until their
-- names and level ranges are confirmed in game. Routes can point at an entry
-- with dungeon = "<id>" on a step.

local _, FL = ...

local dungeons = {
	{ id = "RFC", name = "Ragefire Chasm", zone = "Orgrimmar", min = 13, max = 18, faction = "Horde" },
	{ id = "WC", name = "Wailing Caverns", zone = "The Barrens", min = 17, max = 24 },
	{ id = "DM", name = "The Deadmines", zone = "Westfall", min = 17, max = 24, faction = "Alliance" },
	{ id = "SFK", name = "Shadowfang Keep", zone = "Silverpine Forest", min = 22, max = 30 },
	{ id = "BFD", name = "Blackfathom Deeps", zone = "Ashenvale", min = 24, max = 32 },
	{ id = "STOCKS", name = "The Stockade", zone = "Stormwind City", min = 24, max = 32, faction = "Alliance" },
	{ id = "GNOMER", name = "Gnomeregan", zone = "Dun Morogh", min = 29, max = 38 },
	{ id = "RFK", name = "Razorfen Kraul", zone = "The Barrens", min = 29, max = 38 },
	{ id = "SM", name = "Scarlet Monastery", zone = "Tirisfal Glades", min = 30, max = 44 },
	{ id = "RFD", name = "Razorfen Downs", zone = "The Barrens", min = 37, max = 46 },
	{ id = "ULDA", name = "Uldaman", zone = "Badlands", min = 41, max = 51 },
	{ id = "ZF", name = "Zul'Farrak", zone = "Tanaris", min = 44, max = 54 },
	{ id = "MARA", name = "Maraudon", zone = "Desolace", min = 46, max = 55 },
	{ id = "ST", name = "Sunken Temple", zone = "Swamp of Sorrows", min = 50, max = 56 },
	{ id = "BRD", name = "Blackrock Depths", zone = "Blackrock Mountain", min = 52, max = 60 },
	{ id = "LBRS", name = "Lower Blackrock Spire", zone = "Blackrock Mountain", min = 55, max = 60 },
	{ id = "DIREMAUL", name = "Dire Maul", zone = "Feralas", min = 56, max = 60 },
	{ id = "SCHOLO", name = "Scholomance", zone = "Western Plaguelands", min = 58, max = 60 },
	{ id = "STRAT", name = "Stratholme", zone = "Eastern Plaguelands", min = 58, max = 60 },
}

for _, dungeon in ipairs(dungeons) do
	FL:RegisterDungeon(dungeon)
end

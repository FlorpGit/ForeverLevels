-- Example community profession data pack for Pathwise.
-- Copy this folder, rename it (folder name, .toc name and pack id), and edit.
-- Full format: docs/PROFESSION_DATA_FORMAT.md in the Pathwise repository.
--
-- This example only repeats facts already in Pathwise's verified Tailoring data, so
-- installing it changes nothing. Replace it with recipes and trainers you checked.
-- Released under CC0 1.0; your own pack can use any license.

local Pathwise = _G.Pathwise or _G.ForeverLevels
if not Pathwise or not Pathwise.RegisterProfessionData then return end

Pathwise:RegisterProfessionData({
	apiVersion = 1,
	id = "example.tailoring.wool",
	profession = "tailoring",
	name = "Tailoring",
	skillLine = 197,
	author = "Your Name",
	license = "CC0 1.0",
	sources = { "https://www.wowhead.com/forever/spell=2964" },

	items = {
		[2592] = { name = "Wool Cloth" },
	},

	recipes = {
		{
			id = 2964,
			name = "Bolt of Woolen Cloth",
			creates = 2997,
			reagents = { { 2592, 3 } },
			source = "trainer",
			-- Set a field to true only after checking it on Forever.
			verified = { reagents = true, skill = false, source = false },
		},
	},
})

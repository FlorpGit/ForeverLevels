local T = ...

-- Undead Mage with Tailoring and Enchanting, the Phase 2 test character.
function T.BootCrafter(opts)
	opts = opts or {}
	local before = opts.beforeLogin
	opts.player = opts.player or { class = "MAGE", race = "Scourge", level = 8 }
	opts.beforeLogin = function(ns)
		T.Stub.professions = {
			{ name = "Tailoring", skillLine = 197, rank = opts.tailoring or 30, maxRank = 75 },
			{ name = "Enchanting", skillLine = 333, rank = opts.enchanting or 12, maxRank = 75 },
		}
		if before then before(ns) end
	end
	local FL = T.Boot(opts)
	T.Stub.Advance(0.5)
	return FL
end

T.Test("Professions: detects Tailoring and Enchanting with skill and cap", function()
	local FL = T.BootCrafter()
	local tailoring = FL.Professions:Get("tailoring")
	local enchanting = FL.Professions:Get("enchanting")
	T.True(tailoring and enchanting, "both detected")
	T.Equal(tailoring.rank, 30, "tailoring skill")
	T.Equal(tailoring.maxRank, 75, "tailoring cap")
	T.Equal(enchanting.rank, 12, "enchanting skill")
	T.True(tailoring.hasData and enchanting.hasData, "matched to bundled data by skill line")
	T.Equal(FL.char.professions.skills.tailoring.rank, 30, "saved per character")
end)

T.Test("Professions: falls back to C_SkillInfo when GetProfessions is missing", function()
	local FL = T.BootCrafter({ beforeLogin = function() _G.GetProfessions = nil end })
	T.Equal(FL.Professions:Get("tailoring").rank, 30, "found through C_SkillInfo")
end)

T.Test("Professions: profession without Pathwise data is still listed", function()
	local FL = T.BootCrafter({ beforeLogin = function()
		T.Stub.professions[2] = { name = "Herbalism", skillLine = 182, rank = 5, maxRank = 75 }
	end })
	local herb = FL.Professions:Get("herbalism")
	T.True(herb, "listed")
	T.True(not herb.hasData, "flagged as having no data")
end)

T.Test("Professions: skill changes fire PROFESSION_SKILL_CHANGED with old and new values", function()
	local FL = T.BootCrafter()
	local seen
	FL:On("PROFESSION_SKILL_CHANGED", function(key, old, new) if key == "tailoring" then seen = { old, new } end end)
	T.Stub.professions[1].rank = 31
	T.Stub.FireEvent("SKILL_LINES_CHANGED")
	T.Stub.FireEvent("SKILL_LINES_CHANGED")   -- bursts merge into one scan
	T.Stub.Advance(0.5)
	T.True(seen, "event fired")
	T.Equal(seen[1], 30, "old")
	T.Equal(seen[2], 31, "new")
	T.Equal(FL.char.professions.skills.tailoring.rank, 31, "saved")
end)

T.Test("Professions: opening the Tailoring window reads recipes and client reagents", function()
	local FL = T.BootCrafter()
	T.Stub.openProfession = { professionID = 197, professionName = "Tailoring" }
	T.Stub.recipeInfo[2963] = { learned = true, relativeDifficulty = 1, canSkillUp = true, numSkillUps = 1 }
	T.Stub.recipeInfo[2387] = { learned = false, relativeDifficulty = 0, canSkillUp = true, numSkillUps = 1 }
	T.Stub.recipeInfo[7418] = { learned = true, relativeDifficulty = 0 }   -- enchanting: must be ignored
	T.Stub.schematics[2387] = { { 2996, 2 }, { 2320, 1 } }               -- pretend Forever changed it
	T.Stub.FireEvent("TRADE_SKILL_SHOW")
	T.Stub.Advance(0.5)
	T.Equal(FL.Professions.IsLearned(2963), true, "learned")
	T.Equal(FL.Professions.IsLearned(2387), false, "not learned")
	T.Equal(FL.Professions.IsLearned(7418), nil, "other profession left unknown")
	T.Equal(FL.Professions.GetRecipeState(2963).difficulty, 1, "difficulty stored")
	local reagents, origin = FL.Professions.GetReagents(FL:GetRecipe(2387))
	T.Equal(origin, "client", "client reagents win")
	T.Equal(reagents[1][2], 2, "client quantity used")
	local _, bundledOrigin = FL.Professions.GetReagents(FL:GetRecipe(12044))
	T.Equal(bundledOrigin, "source", "bundled reagents are source-verified")
end)

T.Test("Professions: NEW_RECIPE_LEARNED marks a recipe learned", function()
	local FL = T.BootCrafter()
	T.Equal(FL.Professions.IsLearned(2385), nil, "unknown first")
	T.Stub.FireEvent("NEW_RECIPE_LEARNED", 2385)
	T.Equal(FL.Professions.IsLearned(2385), true, "learned")
end)

T.Test("Professions: individual professions can be hidden", function()
	local FL = T.BootCrafter()
	T.Equal(#FL.Professions:List(true), 2, "both tracked")
	FL.db.profile.professions.tracked.enchanting = false
	local list = FL.Professions:List(true)
	T.Equal(#list, 1, "one tracked")
	T.Equal(list[1].key, "tailoring", "tailoring left")
	FL.db.profile.professions.enabled = false
	T.Equal(#FL.Professions:List(true), 0, "tracking off hides all")
end)

T.Test("Inventory: counts bags, and the bank only when enabled", function()
	local FL = T.BootCrafter()
	T.Stub.items[2589] = 7
	T.Stub.bankItems[2589] = 20
	T.Equal(FL.Inventory.Count(2589), 7, "bags")
	FL.db.profile.professions.countBank = true
	T.Equal(FL.Inventory.Count(2589), 27, "bags + bank")
	local fired = 0
	FL:On("INVENTORY_CHANGED", function() fired = fired + 1 end)
	T.Stub.FireEvent("BAG_UPDATE_DELAYED"); T.Stub.FireEvent("BAG_UPDATE_DELAYED")
	T.Stub.Advance(0.5)
	T.Equal(fired, 1, "bag bursts merged")
end)

T.Test("Profession data: bundled packs validate; bad packs are rejected", function()
	local FL = T.Boot()
	T.True(FL:GetProfessionData("tailoring") and FL:GetProfessionData("enchanting"), "bundled data loaded")
	T.True(not T.ChatContains("profession data rejected"), "nothing rejected at load")
	local function Pack()
		return { id = "test.pack", profession = "tailoring", name = "Tailoring", author = "a", license = "CC0",
			recipes = { { id = 1, name = "R", reagents = { { 2589, 1 } } } } }
	end
	local cases = {
		{ "missing license", function(p) p.license = nil end },
		{ "uppercase key", function(p) p.profession = "Tailoring" end },
		{ "reagent without quantity", function(p) p.recipes[1].reagents = { { 2589 } } end },
		{ "skill out of order", function(p) p.recipes[1].skill = { 10, 5, 20, 30 } end },
		{ "duplicate recipe", function(p) p.recipes[2] = { id = 1, name = "R2", reagents = { { 1, 1 } } } end },
		{ "trainer x without y", function(p) p.trainers = { { name = "T", zone = "Z", x = 5 } } end },
		{ "verified not boolean", function(p) p.recipes[1].verified = { reagents = "yes" } end },
	}
	for _, case in ipairs(cases) do
		local pack = Pack()
		case[2](pack)
		T.True(not FL.ProfessionData.Validate(pack), "should reject: " .. case[1])
	end
	T.True(FL.ProfessionData.Validate(Pack()), "base pack valid")
end)

T.Test("Profession data: a community pack adds recipes without touching bundled ones", function()
	local FL = T.Boot()
	local before = #FL:GetProfessionData("tailoring").recipes
	T.True(_G.Pathwise:RegisterProfessionData({
		id = "community.tailoring.extra", profession = "tailoring", name = "Tailoring", author = "Someone", license = "CC0 1.0",
		recipes = { { id = 999001, name = "Test Shirt", creates = 999002, reagents = { { 2996, 1 } } } },
	}), "registered")
	local data = FL:GetProfessionData("tailoring")
	T.Equal(#data.recipes, before + 1, "recipe added")
	T.True(data.recipeByID[2963], "bundled recipe kept")
	T.Equal(#data.packs, 2, "both packs listed")
	T.Equal(FL:GetProfessionPack("community.tailoring.extra").license, "CC0 1.0", "pack license kept")
end)

T.Test("SavedVariables: version 1 data migrates to version 2 without losing progress", function()
	local saved = {
		db = { profile = { autoAccept = false }, recorder = { { kind = "accept", questID = 363 } }, dbVersion = 1 },
		char = { routeId = "fl.horde.undead.01-deathknell", progress = { ["fl.horde.undead.01-deathknell"] = { step = 4, skipped = { ["dk-mordo"] = true } } }, turnedIn = { [363] = true }, dbVersion = 1 },
	}
	local FL = T.BootCrafter({ saved = saved })
	T.Equal(FL.db.dbVersion, 2, "account db upgraded")
	T.Equal(FL.char.dbVersion, 2, "character db upgraded")
	T.Equal(FL.char.progress["fl.horde.undead.01-deathknell"].skipped["dk-mordo"], true, "skips kept")
	T.Equal(FL.char.turnedIn[363], true, "turn-ins kept")
	T.Equal(#FL.db.recorder, 1, "recorder log kept")
	T.Equal(FL.db.profile.autoAccept, false, "settings kept")
	T.True(FL.char.professions.detours.states, "new profession tables exist")
	T.Equal(FL.db.profile.professions.detours, true, "new defaults")
	-- Reload: profession data persists.
	local FL2 = T.BootCrafter({ saved = { db = FL.db, char = FL.char } })
	T.Equal(FL2.char.professions.skills.tailoring.rank, 30, "skills persisted")
end)

T.Test("Recorder: logs trainer positions when recording", function()
	local FL = T.BootCrafter()
	FL.HandleSlash("record on")
	T.Stub.npcName = "Bowen Brisboise"
	T.Stub.FireEvent("TRAINER_SHOW")
	local entry = FL.db.recorder[#FL.db.recorder]
	T.Equal(entry.kind, "trainer", "kind")
	T.Equal(entry.npc, "Bowen Brisboise", "npc")
	T.Equal(entry.zone, "Tirisfal Glades", "zone")
end)

T.Test("Profession data: the example community pack loads next to bundled data", function()
	local FL = T.Boot({ extraFiles = { T.root .. "/examples/Pathwise_ExampleProfessionData/ExampleProfessionData.lua" } })
	T.True(FL:GetProfessionPack("example.tailoring.wool"), "example pack registered")
	local recipe = FL:GetRecipe(2964)
	T.Equal(recipe.reagents[1][1], 2592, "same verified reagent")
	T.Equal(#FL:GetProfessionData("tailoring").recipes, 7, "no duplicate recipe")
	T.True(FL:GetRoute("fl.horde.undead.01-deathknell"), "routes unaffected")
end)

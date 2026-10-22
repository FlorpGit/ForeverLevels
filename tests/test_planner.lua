local T = ...

local function Near(a, b) return math.abs(a - b) < 1e-6 end

local function Recipe(FL, id) return (FL:GetRecipe(id)) end

T.Test("Planner: chance from skill thresholds (orange, yellow, green, grey)", function()
	local FL = T.BootCrafter()
	local P = FL.Planner
	local levels = { 1, 25, 37, 50 }
	T.Equal(P.ChanceFromThresholds({ 10, 20, 30, 40 }, 5), nil, "below orange: not craftable")
	local c, color = P.ChanceFromThresholds(levels, 10)
	T.Equal(c, 1, "orange is certain"); T.Equal(color, "orange", "orange")
	c, color = P.ChanceFromThresholds(levels, 30)
	T.True(Near(c, 20 / 25), "yellow estimate"); T.Equal(color, "yellow", "yellow")
	c, color = P.ChanceFromThresholds(levels, 45)
	T.True(Near(c, 5 / 25), "green estimate"); T.Equal(color, "green", "green")
	c, color = P.ChanceFromThresholds(levels, 50)
	T.Equal(c, 0, "grey never"); T.Equal(color, "grey", "grey")
end)

T.Test("Planner: expected crafts add up per skill point and do not assume certainty", function()
	local FL = T.BootCrafter()
	local bolt = Recipe(FL, 2963)
	local crafts, basis = FL.Planner.ExpectedCrafts(bolt, 1, 25)
	T.True(Near(crafts, 24), "orange range: one craft per point")
	T.Equal(basis, "thresholds-unverified", "labeled as fallback data")
	crafts = FL.Planner.ExpectedCrafts(bolt, 25, 27)
	T.True(Near(crafts, 1 + 25 / 24), "yellow range costs more than one craft per point")
	T.Equal(FL.Planner.ExpectedCrafts(bolt, 45, 51), nil, "impossible past grey")
end)

T.Test("Planner: material rows show required, owned and missing, with intermediates", function()
	local FL = T.BootCrafter()
	T.Stub.items[2996] = 1    -- Bolt of Linen Cloth
	T.Stub.items[2320] = 5    -- Coarse Thread
	T.Stub.items[2589] = 3    -- Linen Cloth
	local rows = FL.Planner.Materials(Recipe(FL, 2387), 3)
	local bolt, thread = rows[1], rows[2]
	T.Equal(bolt.itemID, 2996, "bolt row")
	T.Equal(bolt.required, 3, "3 bolts needed"); T.Equal(bolt.owned, 1, "1 owned"); T.Equal(bolt.missing, 2, "2 missing")
	T.Equal(thread.missing, 0, "thread covered")
	T.True(bolt.madeFrom, "missing bolts expanded")
	local linen = bolt.madeFrom.rows[1]
	T.Equal(linen.required, 4, "2 bolts need 4 linen")
	T.Equal(linen.missing, 1, "1 linen short")
	T.Equal(FL.Planner.TotalMissing(rows), 2, "total missing")
	T.Equal(FL.Planner.CraftableCount(Recipe(FL, 2387)), 1, "can make 1 now")
end)

T.Test("Planner: recipe eligibility respects learned state and skill requirements", function()
	local FL = T.BootCrafter()
	local step = FL.Planner.Recommend("tailoring")
	T.True(step and step.recipe, "has a recommendation")
	T.True(step.recipe.id ~= 3755, "Linen Bag needs 45 skill")
	T.True(step.recipe.id ~= 2964, "Woolen bolts need 75 skill")
	-- Client says everything but the vest is unlearned.
	T.Stub.openProfession = { professionID = 197, professionName = "Tailoring" }
	for _, id in ipairs({ 2963, 2387, 12044, 8776, 3755, 2964 }) do
		T.Stub.recipeInfo[id] = { learned = false, relativeDifficulty = 0 }
	end
	T.Stub.recipeInfo[2385] = { learned = true, relativeDifficulty = 0 }
	T.Stub.FireEvent("TRADE_SKILL_SHOW"); T.Stub.Advance(0.5)
	step = FL.Planner.Recommend("tailoring")
	T.Equal(step.recipe.id, 2385, "only learned recipe suggested")
	T.Equal(step.basis, "client", "client difficulty used at the current skill")
	T.True(step.confirmedLearned, "marked as confirmed learned")
end)

T.Test("Planner: grey recipes are never suggested", function()
	local FL = T.BootCrafter()
	T.Stub.openProfession = { professionID = 197, professionName = "Tailoring" }
	for _, id in ipairs({ 2963, 2387, 12044, 2385, 8776 }) do
		T.Stub.recipeInfo[id] = { learned = true, relativeDifficulty = 3 }
	end
	T.Stub.FireEvent("TRADE_SKILL_SHOW"); T.Stub.Advance(0.5)
	T.Equal(FL.Planner.Recommend("tailoring"), nil, "nothing gives skill")
end)

T.Test("Planner: Enchanting without skill data suggests a small batch and says it is unknown", function()
	local FL = T.BootCrafter()
	local step = FL.Planner.Recommend("enchanting")
	T.True(step and step.recipe, "something suggested")
	T.Equal(step.basis, "unknown", "basis unknown")
	T.Equal(step.chance, nil, "no invented chance")
	T.Equal(step.crafts, FL.Planner.UNKNOWN_BATCH, "small batch")
end)

T.Test("Planner: a plan reserves materials for earlier steps", function()
	local FL = T.BootCrafter({ tailoring = 1 })
	T.Stub.items[2589] = 20    -- enough linen for 10 bolts
	local plan = FL.Planner.Plan("tailoring", 3)
	T.True(#plan >= 2, "multi-step plan")
	local firstLinen
	for _, row in ipairs(plan[1].materials) do if row.itemID == 2589 then firstLinen = row end end
	T.True(firstLinen, "first step uses linen")
	T.True(plan[2].skill >= plan[1].toSkill, "second step starts where the first ends")
	-- Whatever the first step used is no longer counted as owned later on.
	local reservedLinen = math.min(firstLinen.required, firstLinen.owned)
	for _, step in ipairs(plan) do
		for _, row in ipairs(step.materials) do
			if step ~= plan[1] and row.itemID == 2589 then
				T.True(row.owned <= 20 - reservedLinen, "later steps see reserved linen as used")
			end
		end
	end
end)

T.Test("Planner: trainer milestones need both skill and level", function()
	local FL = T.BootCrafter()
	local m = FL.Planner.NextMilestone("tailoring")
	T.Equal(m.rank.name, "Journeyman", "next rank")
	T.Equal(m.needSkill, 20, "20 more skill")
	T.Equal(m.needLevel, 2, "2 more levels")
	T.True(not m.ready, "not ready")
	T.Equal(m.verified, false, "rank values flagged unverified")
	T.Stub.professions[1].rank = 55
	T.Stub.player.level = 10
	T.Stub.FireEvent("PLAYER_LEVEL_UP", 10)
	T.Stub.FireEvent("SKILL_LINES_CHANGED"); T.Stub.Advance(0.5)
	m = FL.Planner.NextMilestone("tailoring", "Undercity")
	T.True(m.ready, "ready")
	T.Equal(m.trainer.name, "Josef Gregorian", "trainer in the given zone preferred")
end)

T.Test("Planner: learnable trainer recipes are listed once the client says they are unlearned", function()
	local FL = T.BootCrafter()
	T.Equal(#FL.Planner.LearnableRecipes("tailoring"), 0, "unknown until the window is opened")
	T.Stub.openProfession = { professionID = 197, professionName = "Tailoring" }
	T.Stub.recipeInfo[8776] = { learned = false, relativeDifficulty = 0 }
	T.Stub.FireEvent("TRADE_SKILL_SHOW"); T.Stub.Advance(0.5)
	local list = FL.Planner.LearnableRecipes("tailoring")
	T.Equal(#list, 1, "one learnable")
	T.Equal(list[1].name, "Linen Belt", "Linen Belt")
end)

T.Test("Planner: material reminder prints once when materials arrive", function()
	local FL = T.BootCrafter()
	local function Reminders()
		local n = 0
		for _, line in ipairs(T.Stub.chat) do if line:find("you have materials for", 1, true) then n = n + 1 end end
		return n
	end
	T.Stub.items[2996] = 5; T.Stub.items[2320] = 5; T.Stub.items[2589] = 10
	T.Stub.FireEvent("BAG_UPDATE_DELAYED"); T.Stub.Advance(0.5)
	local first = Reminders()
	T.True(first >= 1, "reminded")
	T.Stub.FireEvent("BAG_UPDATE_DELAYED"); T.Stub.Advance(0.5)
	T.Equal(Reminders(), first, "not repeated")
	FL.db.profile.professions.reminders = false
	T.Stub.items[2589] = 0; T.Stub.items[2996] = 0
	T.Stub.FireEvent("BAG_UPDATE_DELAYED"); T.Stub.Advance(0.5)
	T.Equal(Reminders(), first, "no reminders when turned off")
end)

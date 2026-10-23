-- Tests for the profession system as one: recipes from routes, packs and the
-- game (Professions/Recipes.lua), the window scan (Professions.lua), the
-- planner (Planner.lua), the detour card (Detours.lua) and the profession
-- page. Loaded by tests/run.lua. The route-side basics (stage, shopping,
-- disenchanting) are in tests/guide.lua.
local h = ...
local test, eq, ok, near, fresh, lastPrint = h.test, h.eq, h.ok, h.near, h.fresh, h.lastPrint

local TAILORING = 197

-- An Undead Mage in Deathknell with Tailoring trained (and Enchanting).
local function tailor(setup)
	local stub, ns = fresh()
	stub.player.level = 2
	stub.moveTo(1420, 30.2, 71.6)
	stub.skills[TAILORING] = { 1, 75 }
	stub.skills[333] = { 30, 75 }
	stub.items[2320] = 96 -- Coarse Thread
	stub.spells[2963] = true -- Bolt of Linen Cloth, known from training
	if setup then setup(stub) end
	stub.login()
	return stub, ns
end

local function texts(stub) return table.concat(stub.texts(), " | ") end
local function shown(stub, text)
	for _, t in ipairs(stub.texts()) do if t:find(text, 1, true) then return true end end
	return false
end

---------------------------------------------------------------------------
-- Recipes
---------------------------------------------------------------------------

test("recipes: one record per recipe from the route and the starter pack", function()
	local _, ns = tailor()
	local R = ns.Recipes
	local bolt = R.Get(2963)
	eq(bolt.name, "Bolt of Linen Cloth")
	eq(bolt.line, TAILORING)
	eq(bolt.creates, 2996)
	eq(bolt.routeReagents[1][1], 2589, "from the route")
	eq(bolt.skill[4], 50, "skill levels from the pack")
	eq(bolt.skillVerified, false, "marked unchecked")
	local reagents, from = R.Reagents(bolt)
	eq(from, "source", "the pack's checked reagents before the route's")
	eq(reagents[1][2], 2)
	eq(R.Creating(2996, TAILORING).id, 2963, "what makes a bolt")
	ok(R.Get(7183), "Alchemy's recipes come from its route alone")
	local data = R.Data(TAILORING)
	eq(data.packs[1], "pathwise.tailoring.starter")
	eq(data.ranks[2].name, "Journeyman")
end)

test("recipes: packs register with . or :, under either name; bad ones are refused", function()
	local stub, ns = tailor()
	local pack = { id = "test.pack", profession = "tailoring", skillLine = TAILORING, name = "Tailoring", author = "a", license = "CC0",
		recipes = { { id = 999001, name = "Test Shirt", creates = 999002, reagents = { { 2996, 1 } }, skill = { 1, 10, 20, 30 } } } }
	ok(ForeverLevels:RegisterProfessionData(pack), "colon, old name")
	eq(ns.Recipes.Get(999001).name, "Test Shirt")
	ok(not Pathwise.RegisterProfessionData({ id = "bad pack!", profession = "Tailoring" }), "refused")
	ok(lastPrint(stub):find("profession data"), lastPrint(stub))
	-- The example community pack loads beside the bundled data.
	assert(loadfile("examples/Pathwise_ExampleProfessionData/ExampleProfessionData.lua"))("Pathwise_ExampleProfessionData", {})
	ok(ns.Recipes.Pack("example.tailoring.wool"), "example pack")
	eq(ns.Recipes.Get(2963).name, "Bolt of Linen Cloth", "bundled recipes untouched")
end)

test("recipes: the profession window's reagents win, are kept for the account, and learning is noticed", function()
	local stub, ns = tailor()
	stub.tradeSkill = {
		professionID = TAILORING,
		recipes = { [2963] = { name = "Bolt of Linen Cloth", learned = true, relativeDifficulty = 0, numSkillUps = 1 },
			[8776] = { name = "Linen Belt", learned = false, relativeDifficulty = 0 } },
		reagents = { [2963] = { { 2589, 3 } } },
	}
	stub.fire("TRADE_SKILL_SHOW")
	local reagents, from = ns.Recipes.Reagents(ns.Recipes.Get(2963))
	eq(from, "client")
	eq(reagents[1][2], 3, "what the window says")
	eq(PathwiseSettings.professions.schematics[2963].reagents[1][2], 3, "kept for the account")
	local st = ns.Professions.RecipeState(TAILORING, 2963)
	eq(st.atRank, 1, "the colour is for skill 1")
	eq(ns.Professions.RecipeState(TAILORING, 8776).learned, false)
	stub.fire("NEW_RECIPE_LEARNED", 8776)
	eq(ns.Professions.RecipeState(TAILORING, 8776).learned, true, "learned at the trainer")
end)

---------------------------------------------------------------------------
-- Planner
---------------------------------------------------------------------------

test("planner: chance from skill levels, and crafts expected per skill point", function()
	local _, ns = tailor()
	local Pl = ns.Planner
	local L = { 1, 25, 37, 50 }
	eq(Pl.ChanceFromThresholds(L, 0), nil, "needs more skill")
	eq(Pl.ChanceFromThresholds(L, 10), 1)
	near(Pl.ChanceFromThresholds(L, 30), 0.8, 1e-9)
	eq(select(2, Pl.ChanceFromThresholds(L, 40)), "green")
	eq(Pl.ChanceFromThresholds(L, 50), 0, "grey")
	local bolt = ns.Recipes.Get(2963)
	eq(Pl.ExpectedCrafts(bolt, 1, 25), 24, "orange: one each")
	near(Pl.ExpectedCrafts(bolt, 25, 27), 1 + 25 / 24, 1e-9, "yellow: more than one each")
	eq(Pl.ExpectedCrafts(bolt, 45, 55), nil, "it goes grey first")
	local c, _, basis = Pl.Chance(bolt, 1, { difficulty = 2, atRank = 1 })
	eq(c, 0.25)
	eq(basis, "client", "the window's colour at this skill first")
	eq(select(3, Pl.Chance(bolt, 5, { difficulty = 2, atRank = 1 })), "thresholds-unverified", "an older colour gives way to skill levels")
end)

test("planner: materials with what is missing made from what is in the bags, held back for earlier crafts", function()
	local stub, ns = tailor(function(s) s.items[2589] = 4 end)
	local Pl = ns.Planner
	local pants = ns.Recipes.Get(12044)
	local rows = Pl.Materials(pants, 5)
	local bolts
	for _, r in ipairs(rows) do if r.item == 2996 then bolts = r end end
	eq(bolts.required, 5)
	eq(bolts.missing, 5)
	eq(bolts.madeFrom.recipe.id, 2963, "made from linen")
	eq(bolts.madeFrom.rows[1].required, 10)
	eq(bolts.madeFrom.rows[1].missing, 6)
	local reserved = {}
	Pl.Reserve(Pl.Materials(ns.Recipes.Get(2963), 2), reserved)
	eq(reserved[2589], 4, "two bolts hold back the four linen")
	eq(Pl.CraftableCount(ns.Recipes.Get(2963), nil, reserved), 0, "nothing left for more")
end)

test("planner: the route's next craft with its numbers, the next rank and what to learn", function()
	local stub, ns = tailor(function(s) s.items[2589] = 46 end)
	local prof = ns.Professions.BY_KEY.tailoring
	local c = ns.Planner.Next(prof)
	eq(c.name, "Bolt of Linen Cloth")
	eq(c.craftable, 23)
	eq(c.planned, 53, "the route asks for 53 bolts")
	eq(c.chance, 1)
	eq(c.basis, "thresholds-unverified")
	local m = ns.Planner.Milestone(prof)
	eq(m.rankMax, 150)
	eq(m.rankName, "Journeyman")
	eq(m.needLevel, 10)
	eq(m.needSkill, 50)
	eq(m.ready, false)
	eq(m.trainer.name, "Bowen Brisboise", "the Horde trainer on this map")
	local learn = ns.Planner.Learnable(prof)
	eq(learn[1].name, "Linen Belt")
end)

test("planner: with nothing open in the route it recommends from the known recipes", function()
	local _, ns = tailor(function(s) s.items[2589] = 10 end)
	local rec = ns.Planner.Recommend(TAILORING)
	ok(rec and rec.recipe, "a recipe")
	eq(rec.chance, 1, "a sure skill-up first")
	ok(rec.craftable > 0, "one the bags make")
	local _, ns2 = tailor(function(s) s.skills[TAILORING] = { 75, 75 } end)
	eq(ns2.Planner.Recommend(TAILORING).capped, true, "at the cap: train first")
end)

test("planner: a reminder when the bags newly make the next craft, not at login, once", function()
	local stub, ns = tailor(function(s) s.items[2589] = 46 end)
	for _, m in ipairs(stub.printed) do ok(not m:find("you have materials"), "not at login: " .. m) end
	stub.items[2589] = 0
	stub.fire("BAG_UPDATE_DELAYED")
	stub.advance(1)
	stub.items[2589] = 20
	stub.fire("BAG_UPDATE_DELAYED")
	stub.advance(1)
	ok(lastPrint(stub):find("Tailoring: you have materials for 10 Bolt of Linen Cloth", 1, true), lastPrint(stub))
	local n = #stub.printed
	stub.fire("BAG_UPDATE_DELAYED")
	stub.advance(1)
	eq(#stub.printed, n, "once")
	ns.Set("professions.reminders", false)
	stub.items[2589] = 0
	stub.fire("BAG_UPDATE_DELAYED")
	stub.advance(1)
	stub.items[2589] = 20
	stub.fire("BAG_UPDATE_DELAYED")
	stub.advance(1)
	eq(#stub.printed, n, "turned off")
end)

---------------------------------------------------------------------------
-- Detours
---------------------------------------------------------------------------

test("detours: craft what the bags make, wherever you are; the route is untouched", function()
	local stub, ns = tailor(function(s) s.items[2589] = 46 end)
	local E = ns.Engine
	local card = ns.Guide.View().detour
	ok(card, "a card")
	eq(card.kind, "craft")
	eq(card.text, "Craft 23 Bolt of Linen Cloth")
	ok(card.sub:find("You can make 23 now", 1, true), card.sub)
	local live, target = E.LiveStep(), ns.Nav.Target().title
	ns.Fire("DETOUR_GO")
	ok(ns.Guide.View().detour.aimed, "chosen")
	eq(ns.Nav.Target().title, target, "nowhere to go: the arrow stays on the route")
	eq(E.LiveStep(), live, "the route did not move")
	stub.items[2589] = 0
	stub.fire("BAG_UPDATE_DELAYED")
	ok(lastPrint(stub):find("detour done: Craft 23 Bolt of Linen Cloth", 1, true), lastPrint(stub))
	eq(ns.Guide.View().detour, nil, "materials used up")
	eq(E.LiveStep(), live, "and the route still did not move")
end)

test("detours: train the next rank at the trainer on the way, the arrow there and back", function()
	local stub, ns = tailor(function(s)
		s.player.level = 10
		s.skills[TAILORING] = { 50, 75 }
		s.moveTo(1420, 52.0, 55.0) -- Brill, by Bowen Brisboise
	end)
	local card = ns.Guide.View().detour
	ok(card and card.kind == "train", texts(stub))
	eq(card.text, "Train Journeyman Tailoring")
	ok(card.sub:find("Bowen Brisboise", 1, true) and card.sub:find("yd", 1, true), card.sub)
	local before = ns.Nav.Target().title
	ns.Fire("DETOUR_GO")
	eq(ns.Nav.Target().title, "Bowen Brisboise", "the arrow leads to the trainer")
	stub.skills[TAILORING] = { 50, 150 }
	stub.fire("SKILL_LINES_CHANGED")
	ok(lastPrint(stub):find("detour done: Train Journeyman Tailoring", 1, true), lastPrint(stub))
	eq(ns.Nav.Target().title, before, "back to the route")
	stub.moveTo(1420, 30.2, 71.6)
	stub.skills[TAILORING] = { 50, 75 }
	ns.Engine.Update()
	eq(ns.Guide.View().detour, nil, "done stays done; and Deathknell is too far for Balanced anyway")
end)

test("detours: Later waits for the route to move, Skip is for good, Off shows none", function()
	local stub, ns = tailor(function(s) s.items[2589] = 46 end)
	ok(ns.Guide.View().detour, "card")
	ns.Fire("DETOUR_LATER")
	eq(ns.Guide.View().detour, nil, "later")
	stub.accept(363) -- the leveling route moves on
	ok(ns.Guide.View().detour, "offered again")
	ns.Fire("DETOUR_SKIP")
	eq(ns.Guide.View().detour, nil, "skipped")
	stub.turnin(363)
	eq(ns.Guide.View().detour, nil, "for good")
	eq(ns.Detours.SkippedCount(), 1)
	ns.Detours.Unskip()
	ns.Engine.Update()
	ok(ns.Guide.View().detour, "brought back")
	SlashCmdList.PATHWISE("detour off")
	eq(ns.Get("professions.detour"), "off")
	eq(ns.Guide.View().detour, nil, "off")
	SlashCmdList.PATHWISE("detour on")
	eq(ns.Get("professions.detour"), "balanced")
	ns.Professions.SetShown(ns.Professions.BY_KEY.tailoring, false)
	ns.Engine.Update()
	eq(ns.Guide.View().detour, nil, "Tailoring hidden from detours")
end)

test("professions: /pw track and /pw reminders, also as /fl", function()
	local stub, ns = tailor(function(s) s.items[2589] = 46 end)
	SlashCmdList.PATHWISE("track tailoring off")
	eq(ns.Professions.Shown(ns.Professions.BY_KEY.tailoring), false)
	eq(ns.Guide.View().detour, nil, "no detour for it")
	SlashCmdList.PATHWISE("track first_aid off")
	eq(ns.Professions.Shown(ns.Professions.BY_KEY["first-aid"]), false, "the old key spelling works")
	SlashCmdList.PATHWISE("track nonsense")
	ok(lastPrint(stub):find("usage", 1, true))
	SlashCmdList.PATHWISE("reminders off")
	eq(ns.Get("professions.reminders"), false)
	eq(SLASH_PATHWISE3, "/fl", "the same handler serves /fl")
end)

test("detours: choices survive a reload", function()
	local stub, ns = tailor(function(s) s.items[2589] = 46 end)
	ns.Fire("DETOUR_SKIP")
	local saved, char = PathwiseSettings, PathwiseCharSettings
	local stub2, ns2 = fresh()
	PathwiseSettings, PathwiseCharSettings = saved, char
	stub2.player.level = 2
	stub2.moveTo(1420, 30.2, 71.6)
	stub2.skills[TAILORING] = { 1, 75 }
	stub2.items[2320], stub2.items[2589], stub2.spells[2963] = 96, 46, true
	stub2.login()
	eq(ns2.Guide.View().detour, nil, "still skipped")
end)

---------------------------------------------------------------------------
-- The profession page
---------------------------------------------------------------------------

test("profession page: the planner's numbers, the next rank, recipes to learn, the switch", function()
	local stub, ns = tailor(function(s) s.items[2589] = 46 end)
	SlashCmdList.PATHWISE("prof")
	ok(stub.clickLabelText("Tailoring   1 / 75"))
	ok(shown(stub, "Skill-up chance 100% (from skill levels not yet checked on Forever)."), texts(stub))
	ok(shown(stub, "FOR THE NEXT CRAFTS"))
	ok(shown(stub, "Next rank: Journeyman (150)  ·  needs level 10 and Tailoring 50  ·  Bowen Brisboise"), texts(stub))
	ok(shown(stub, "Learn at a trainer: Linen Belt"))
	ok(shown(stub, "Recipe data: the guide, pathwise.tailoring.starter"), texts(stub))
	ok(shown(stub, "In detours and reminders"))
	ok(stub.clickLabel("Turn off"))
	eq(ns.Professions.Shown(ns.Professions.BY_KEY.tailoring), false)
	eq(ns.Guide.View().detour, nil, "no detour for it")
end)

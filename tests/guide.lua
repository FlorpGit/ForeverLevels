-- Tests for the data (Pathwise/Data/Data.lua), the guide engine, the
-- Tirisfal route and the panels. Loaded by tests/run.lua.
local h = ...
local test, eq, near, ok, fresh, lastPrint = h.test, h.eq, h.near, h.ok, h.fresh, h.lastPrint

-- Level 2 by default: The Damned asks for level 2, and the first two quests
-- get a new character there.
local function login(setup)
	local stub, ns = fresh()
	stub.player.level = 2
	if setup then setup(stub) end
	stub.moveTo(1420, 30.2, 71.6) -- Undertaker Mordo's crypt, where Undead start
	stub.login()
	return stub, ns
end

local function contains(list, text)
	for _, t in ipairs(list) do if tostring(t):find(text, 1, true) then return true end end
	return false
end

test("data: the Deathknell quests, their people and places, and Skyborne race bits", function()
	local _, ns = fresh()
	local Q = ns.Quests
	eq(Q.Name(364), "The Mindless Ones")
	local giver = Q.Giver(364)
	eq(giver.name, "Shadow Priest Sarvis")
	eq(giver.map, 1420)
	near(giver.x, 30.84, 0.01, "x")
	near(giver.y, 66.2, 0.01, "y")
	eq(Q.Finisher(383).name, "Executor Zygand")
	-- 8589934770: every Horde race including Skyborne (bit 33); stored whole, not cut to 32 bits.
	eq(Q.Get(364)[4], 8589934770)
	ok(Q.HasBit(Q.Get(364)[4], 8589934592), "Skyborne Horde bit")
	ok(Q.HasBit(Q.Get(364)[4], 16), "Undead bit")
	ok(not Q.HasBit(Q.Get(364)[4], 1), "not Human")
end)

test("data: zone levels for Tirisfal and Silverpine are leveling ranges, Horde only", function()
	local _, ns = fresh()
	local z = ns.Quests.Data.zones
	ok(z[1420] and z[1420].horde, "Tirisfal has a Horde range")
	ok(z[1420].horde[1] <= 5 and z[1420].horde[2] <= 15, "Tirisfal is a starting zone")
	ok(z[1421].horde[1] >= 8 and z[1421].horde[2] <= 25, "Silverpine follows it")
	eq(z[1420].alliance, nil, "no Alliance range in Tirisfal")
end)

test("the Tirisfal route checks clean against the data", function()
	local _, ns = fresh()
	local r = ns.Engine.routes["horde/undead/tirisfal"]
	ok(r, "registered")
	local problems = ns.Engine.Check(r)
	eq(#problems, 0, table.concat(problems, "; "))
end)

test("a route with a quest the data does not have is refused", function()
	local stub, ns = fresh()
	local okay = Pathwise.RegisterRoute({ id = "test/bad", title = "Bad", steps = { { { "accept", 123456789 } } } })
	eq(okay, false)
	ok(lastPrint(stub):find("not in the data"), lastPrint(stub))
end)

test("an Undead character starts on the Tirisfal route at Undertaker Mordo", function()
	local stub, ns = login()
	eq(ns.Engine.Route().id, "horde/undead/tirisfal")
	local v = ns.Guide.View()
	eq(v.title, "Undertaker Mordo")
	eq(v.index, 1)
	local t = ns.Nav.Target()
	eq(t.title, "Undertaker Mordo")
	near(t.x, 30.22, 0.01)
end)

test("a Human gets no Undead route and the window explains", function()
	local stub, ns = login(function(s) s.player.raceID, s.player.race, s.player.faction = 1, "Human", "Alliance" end)
	eq(ns.Engine.Route(), nil)
	eq(ns.Guide.View(), nil)
	ok(contains(stub.texts(), "No route for this character yet"), "empty state")
end)

test("the route follows the quest log: accept, hand in, objectives", function()
	local stub, ns = login()
	stub.accept(363)
	eq(ns.Guide.View().title, "Shadow Priest Sarvis", "after accepting: hand in at Sarvis")
	stub.turnin(363)
	eq(ns.Engine.LiveStep(), 2, "still at Sarvis: accept The Mindless Ones")
	stub.accept(364, { { text = "Mindless Zombie slain: 0/8", numFulfilled = 0, numRequired = 8, finished = false },
		{ text = "Wretched Zombie slain: 0/8", numFulfilled = 0, numRequired = 8, finished = false } })
	eq(ns.Engine.LiveStep(), 3, "on to Novice Elreth")
	eq(ns.Guide.View().title, "Novice Elreth")
	stub.accept(376, { { text = "Scavenger Paw: 0/6", numFulfilled = 0, numRequired = 6, finished = false },
		{ text = "Duskbat Wing: 0/6", numFulfilled = 0, numRequired = 6, finished = false } })
	local v = ns.Guide.View()
	eq(v.title, "North of Deathknell")
	eq(v.objectives[1].text, "Mindless Zombie", "the log's text without the count")
	eq(v.objectives[1].need, 8)
	stub.progress(364, 1, 5)
	eq(ns.Guide.View().objectives[1].have, 5)
	eq(ns.Nav.Target().title, "Mindless Zombie", "the arrow leads to the first unfinished objective")
	stub.progress(364, 1, 8)
	eq(ns.Nav.Target().title, "Wretched Zombie", "then to the next")
end)

test("warlock quests are left out for a mage; the mage gets the Glyphic Scroll", function()
	local stub, ns = login()
	stub.accept(363) stub.turnin(363)
	stub.accept(364, {}) stub.accept(376, {})
	local v = ns.Guide.View()
	for _, row in ipairs(v.objectives) do ok(not row.text:find("Piercing the Veil"), "no warlock quest") end
	-- The class scroll needs The Mindless Ones handed in first (the data's prerequisite).
	stub.turnin(364) stub.turnin(376)
	local rows = ns.Guide.View().objectives
	local texts = {}
	for _, r in ipairs(rows) do texts[#texts + 1] = r.text end
	ok(contains(texts, "Accept Glyphic Scroll"), table.concat(texts, " | "))
	ok(not contains(texts, "Simple Scroll"), "no warrior scroll")
end)

test("a quest not offered yet does not hold the route, which comes back for it", function()
	local stub, ns = login(function(s) s.player.level = 1 end)
	stub.accept(363) stub.turnin(363) stub.accept(364, {})
	-- The Damned asks for level 2: at level 1 the route goes on to the zombies...
	eq(ns.Guide.View().title, "North of Deathknell")
	-- ...and comes back to Novice Elreth once the character reaches level 2.
	stub.player.level = 2
	stub.fire("PLAYER_LEVEL_UP", 2)
	eq(ns.Guide.View().title, "Novice Elreth")
end)

test("skip: just the quest, or the quest and its follow-ups", function()
	local stub, ns = login()
	stub.accept(363) stub.turnin(363) stub.accept(364, {})
	local E = ns.Engine
	eq(E.SkippableQuests()[1], 376, "The Damned is the open quest at Novice Elreth")
	local list = E.SkipQuest(376, true)
	ok(#list > 3, "follow-ups skipped too: " .. #list)
	local skipped = {}
	for _, q in ipairs(list) do skipped[q] = true end
	ok(skipped[380] and skipped[3902] and skipped[6395], "Night Web's Hollow, Scavenging Deathknell, Marla's Last Wish")
	ok(E.LiveStep() > 3, "the route moved past Elreth")
	E.UnskipQuest(376)
	eq(E.LiveStep(), 3, "brought back")
end)

test("alternatives: nearby, at the player's level, not already in the route", function()
	local stub, ns = login()
	stub.player.level = 7
	stub.moveTo(1420, 60.6, 51.8) -- Brill
	local alts = ns.Engine.Alternatives(5)
	ok(#alts > 0, "some quests around Brill at level 7")
	local route = ns.Engine.Route()
	local inRoute = {}
	for _, step in ipairs(route.steps) do for _, g in ipairs(step) do if g[2] then inRoute[g[2]] = true end end end
	local last = 0
	for _, a in ipairs(alts) do
		ok(not inRoute[a.quest], a.name .. " is in the route")
		ok(a.level >= 5 and a.level <= 10, a.name .. " level " .. a.level)
		ok((a.yards or 0) >= last, "nearest first")
		last = a.yards or last
	end
end)

test("an alternative goes ahead of the route, which resumes after it", function()
	local stub, ns = login()
	stub.player.level = 7
	stub.moveTo(1420, 60.6, 51.8)
	local alt = ns.Engine.Alternatives(1)[1]
	ns.Engine.AddExtra(alt.quest)
	local v = ns.Guide.View()
	ok(v.extra, "the extra quest is shown")
	eq(v.title, alt.name)
	stub.accept(alt.quest)
	stub.turnin(alt.quest)
	ok(not ns.Guide.View().extra, "back to the route")
	eq(ns.Guide.View().title, "Undertaker Mordo")
end)

test("Back and Next look at other steps without changing the live one", function()
	local stub, ns = login()
	stub.accept(363) stub.turnin(363) stub.accept(364, {})
	local E = ns.Engine
	eq(E.LiveStep(), 3)
	E.Next()
	eq(E.CurrentStep(), 4)
	eq(E.LiveStep(), 3)
	ok(ns.Guide.View().pinned, "marked as looked-at")
	E.Back() E.Back()
	eq(E.CurrentStep(), 2)
	E.Next()
	eq(E.CurrentStep(), 3, "back on the live step")
	ok(not ns.Guide.View().pinned)
end)

test("zones for the player's level list Tirisfal with its route", function()
	local stub, ns = login()
	stub.player.level = 5
	local zones = ns.Engine.Zones()
	local tirisfal
	for _, z in ipairs(zones) do if z.map == 1420 then tirisfal = z end end
	ok(tirisfal, "Tirisfal listed at level 5")
	eq(tirisfal.name, "Tirisfal Glades")
	eq(tirisfal.route.id, "horde/undead/tirisfal")
	for _, z in ipairs(zones) do ok(z.low <= 7 and z.high >= 3, z.name .. " fits level 5") end
end)

test("settings panel: opacity, compact, arrow size, without commands", function()
	local stub, ns = login()
	ns.Fire("SHOW_SETTINGS")
	ok(_G.PathwisePanel and _G.PathwisePanel.shown, "panel open")
	ok(contains(stub.texts(), "Background opacity"), "opacity row")
	stub.slider("ui.opacity"):SetValue(0.7)
	near(ns.Get("ui.opacity"), 0.7, 1e-9, "opacity slider")
	near(_G.PathwiseGuide.pwGround.color[4], 0.7, 1e-9, "the window follows")
	stub.slider("arrow.scale"):SetValue(1.5)
	near(ns.Get("arrow.scale"), 1.5, 1e-9, "arrow size slider")
	ok(stub.clickLabel("Turn on"), "compact toggle")
	eq(ns.Get("guide.compact"), true)
	ok(stub.clickLabel("Hide"), "arrow toggle")
	eq(ns.Get("arrow.shown"), false)
end)

test("window size slider: the guide shrinks as it moves, saved, steps of 5%", function()
	local stub, ns = login()
	ns.Fire("SHOW_SETTINGS")
	ok(contains(stub.texts(), "Window size"), "size row")
	ok(contains(stub.texts(), "100%"), "shows 100% at first")
	local s = stub.slider("ui.scale")
	s:SetValue(0.73) -- a drag lands between steps
	near(ns.Get("ui.scale"), 0.75, 1e-9, "rounded to the 5% step")
	near(_G.PathwiseGuide.scale, 0.75, 1e-9, "the guide window scales at once")
	eq(PathwiseSettings.ui.scale, 0.75, "saved")
	ok(contains(stub.texts(), "75%"), "the value beside the slider")
	s:SetValue(0.1)
	near(ns.Get("ui.scale"), 0.5, 1e-9, "never below 50%")
	s:SetValue(1)
	eq(PathwiseSettings.ui.scale, nil, "back to 100% is the default, not stored")
end)

test("/pw scale sets the window size; the panel opens at that size", function()
	local stub, ns = login()
	SlashCmdList.PATHWISE("scale 80")
	near(_G.PathwiseGuide.scale, 0.8, 1e-9)
	SlashCmdList.PATHWISE("scale 20")
	ok(lastPrint(stub):find("usage"), "out of range explains")
	ns.Fire("SHOW_SETTINGS")
	near(_G.PathwisePanel.scale, 0.8, 1e-9, "settings panel at the same size")
end)

test("skip panel lists the step's quest and nearby alternatives", function()
	local stub, ns = login()
	stub.accept(363) stub.turnin(363) stub.accept(364, {})
	ns.Fire("GUIDE_SKIP")
	local texts = stub.texts()
	ok(contains(texts, "The Damned"), "the quest")
	ok(contains(texts, "Skip just this quest"), "skip one")
	ok(contains(texts, "Skip it and its follow-ups"), "skip chain")
	ok(contains(texts, "INSTEAD, NEARBY"), "alternatives heading")
end)

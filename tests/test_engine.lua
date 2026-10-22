-- SPDX-License-Identifier: GPL-3.0-only
local T = ...

local DK = "fl.horde.undead.01-deathknell"
local BRILL = "fl.horde.undead.02-brill"

local function StepId(FL)
	return FL.Engine:GetCurrentStep().id
end

T.Test("Engine: level 1 Undead gets the Deathknell route automatically", function()
	local FL = T.Boot()
	T.Equal(FL.Engine.route.id, DK, "auto-selected route")
	T.Equal(StepId(FL), "dk-mordo", "first step")
end)

T.Test("Engine: a level 7 Undead with no saved route starts in Brill", function()
	local FL = T.Boot({ player = { level = 7 } })
	T.Equal(FL.Engine.route.id, BRILL, "auto-selected route")
end)

T.Test("Engine: non-Undead Horde gets no route and a helpful message", function()
	local FL = T.Boot({ player = { race = "Orc" } })
	T.Equal(FL.Engine.route, nil, "no route")
	T.True(T.ChatContains("no installed route fits"), "message")
end)

T.Test("Engine: accept / complete / turn-in detection advances steps", function()
	local FL = T.Boot()
	T.Accept(363)
	T.Equal(StepId(FL), "dk-sarvis-1", "after accepting Rude Awakening")
	T.TurnIn(363)
	T.Equal(StepId(FL), "dk-sarvis-1", "still needs to accept 364")
	T.Accept(364)
	T.Equal(StepId(FL), "dk-mindless", "kill step")
	T.Finish(364)
	T.Equal(StepId(FL), "dk-sarvis-2", "objectives done -> turn-in step")
end)

T.Test("Engine: class-specific goals only apply to that class", function()
	local FL = T.Boot({ player = { class = "MAGE" } })
	local step
	for _, s in ipairs(FL.Engine.route.steps) do
		if s.id == "dk-sarvis-2" then step = s end
	end
	local goals = FL.Engine.GetGoals(step, FL.player)
	local ids = {}
	for _, goal in ipairs(goals) do ids[goal.questID] = true end
	T.True(ids[3098], "mage scroll included")
	T.True(not ids[3095], "warrior scroll excluded")
	T.True(not ids[3099], "warlock scroll excluded")
	T.True(ids[3901] and ids[376], "shared quests included")
end)

T.Test("Engine: class-only step is skipped for a class with no goals there (Paladin)", function()
	local FL = T.Boot({ player = { class = "PALADIN" } })
	for _, id in ipairs({ 363, 364 }) do T.Do(id) end
	T.Accept(3901); T.Accept(376)
	T.Equal(StepId(FL), "dk-fields", "trainer step skipped for Paladin")
end)

T.Test("Engine: Warlock sees the trainer step and the imp quest", function()
	local FL = T.Boot({ player = { class = "WARLOCK" } })
	for _, id in ipairs({ 363, 364 }) do T.Do(id) end
	T.Accept(3901); T.Accept(376); T.Accept(3099)
	T.Equal(StepId(FL), "dk-class-trainer", "trainer step")
	T.True(FL.Engine.GetStepText(FL.Engine:GetCurrentStep(), FL.player):find("Maximillion"), "class text")
	T.TurnIn(3099)
	T.Equal(StepId(FL), "dk-class-trainer", "still needs Piercing the Veil")
	T.Accept(1470)
	T.Equal(StepId(FL), "dk-fields", "advanced")
end)

T.Test("Engine: finishing Deathknell chains into Brill", function()
	local FL = T.Boot({ player = { class = "ROGUE" } })
	local order = { 363, 364, 3096, 3901, 376, 3902, 380, 381, 6395, 382 }
	for _, id in ipairs(order) do T.Do(id) end
	T.Accept(383)
	T.Equal(FL.Engine.route.id, BRILL, "switched to next route")
	T.Equal(StepId(FL), "br-calvin", "first Brill step")
	T.True(T.ChatContains("continuing with"), "announced")
end)

T.Test("Engine: a character mid-route fast-forwards past finished steps on login", function()
	local FL = T.Boot({ beforeLogin = function()
		for _, id in ipairs({ 363, 364 }) do
			local q = T.Stub.Quest(id); q.turnedIn = true
		end
		T.Stub.Quest(3901).onQuest = true
		T.Stub.Quest(376).onQuest = true
		T.Stub.Quest(3095).turnedIn = true
	end })
	T.Equal(StepId(FL), "dk-fields", "skipped completed steps")
end)

T.Test("Engine: Back holds the step, Next resumes", function()
	local FL = T.Boot()
	T.Accept(363)
	T.Equal(StepId(FL), "dk-sarvis-1", "start")
	FL.Engine:Prev()
	T.Equal(StepId(FL), "dk-mordo", "went back")
	T.True(FL.Engine.hold, "holding")
	T.Stub.FireEvent("QUEST_LOG_UPDATE"); T.Stub.Advance(0.5)
	T.Equal(StepId(FL), "dk-mordo", "hold survives quest updates")
	FL.Engine:Next()
	T.Equal(StepId(FL), "dk-sarvis-1", "resumed")
	T.True(not FL.Engine.hold, "hold cleared")
end)

T.Test("Engine: Next on an unfinished step skips it and it stays skipped", function()
	local FL = T.Boot()
	FL.Engine:Next()
	T.Equal(StepId(FL), "dk-sarvis-1", "skipped Mordo")
	T.Stub.FireEvent("QUEST_LOG_UPDATE"); T.Stub.Advance(0.5)
	T.Equal(StepId(FL), "dk-sarvis-1", "skipped step does not pull back")
end)

T.Test("Engine: level goal completes on PLAYER_LEVEL_UP", function()
	local FL = T.Boot({ player = { level = 9 } })
	FL.Engine:SelectRoute(BRILL)
	FL.Engine:GoTo(#FL.Engine.route.steps)
	FL.Engine.hold = false
	T.Equal(StepId(FL), "br-level-10", "on level step")
	T.Stub.player.level = 10
	T.Stub.FireEvent("PLAYER_LEVEL_UP", 10)
	T.Stub.Advance(0.2)
	T.True(T.ChatContains("finished Undead 6-10: Brill"), "route finished")
end)

T.Test("SavedVariables: progress persists across a reload", function()
	local FL = T.Boot()
	T.Accept(363)
	local db, char = _G.ForeverLevelsDB, _G.ForeverLevelsCharDB
	T.Equal(char.routeId, DK, "route saved")
	T.Equal(char.progress[DK].step, 2, "step saved")
	db.profile.autoAccept = false

	local FL2 = T.Boot({ saved = { db = db, char = char } })
	T.Equal(FL2.Engine.route.id, DK, "route restored")
	T.Equal(FL2.Engine.index, 2, "step restored")
	T.Equal(FL2.db.profile.autoAccept, false, "setting restored")
	T.Equal(FL2.db.profile.arrow, true, "new defaults merged")
end)

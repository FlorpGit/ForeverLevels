-- Tests for accepting and handing in the route's quests at their NPC
-- (Guide/AutoQuest.lua). Loaded by tests/run.lua.
local h = ...
local test, eq, ok, fresh, lastPrint = h.test, h.eq, h.ok, h.fresh, h.lastPrint

-- An Undead in Deathknell on Polestar's Tirisfal Glades route, which starts
-- with Rude Awakening (363) and then The Mindless Ones (364).
local function login(setup)
	local stub, ns = fresh()
	stub.player.level = 2
	stub.moveTo(1420, 30.2, 71.6)
	if setup then setup(stub) end
	stub.login()
	return stub, ns
end

local function detail(stub, q)
	stub.dialog.quest = q
	stub.fire("QUEST_DETAIL")
end

local function pressed(stub, name) return stub.calls[name] or 0 end

test("auto quests: accepts the route's quest, nothing else", function()
	local stub, ns = login()
	eq(ns.Engine.Route().id, "forever/horde/undead/01-tirisfal-glades", "the Undead route")
	detail(stub, 363)
	eq(pressed(stub, "AcceptQuest"), 1, "Rude Awakening accepted")
	detail(stub, 424242)
	eq(pressed(stub, "AcceptQuest"), 1, "a quest the route does not use")
end)

test("auto quests: Shift pauses it, and the settings turn it off", function()
	local stub, ns = login()
	IsShiftKeyDown = function() return true end
	detail(stub, 363)
	eq(pressed(stub, "AcceptQuest"), 0, "Shift held")
	IsShiftKeyDown = function() return false end
	ns.Set("auto.accept", false)
	detail(stub, 363)
	eq(pressed(stub, "AcceptQuest"), 0, "turned off")
	SlashCmdList.PATHWISE("auto on")
	eq(ns.Get("auto.accept"), true, "/pw auto on")
	detail(stub, 363)
	eq(pressed(stub, "AcceptQuest"), 1, "on again")
	SlashCmdList.PATHWISE("auto off")
	eq(ns.Get("auto.turnin"), false, "/pw auto off turns every part off")
	eq(ns.Get("auto.gossip"), false)
end)

test("auto quests: a quest the game accepts by itself is acknowledged, not accepted again", function()
	local stub = login()
	stub.dialog.auto = true
	detail(stub, 363)
	eq(pressed(stub, "AcknowledgeAutoAcceptQuest"), 1)
	eq(pressed(stub, "AcceptQuest"), 0)
end)

test("auto quests: a PvP quest is left to the player", function()
	local stub = login()
	stub.dialog.pvp = true
	detail(stub, 363)
	eq(pressed(stub, "AcceptQuest"), 0)
end)

test("auto quests: a quest the route took earlier is not accepted again", function()
	local stub = login()
	stub.accept(363)
	stub.turnin(363)
	detail(stub, 363)
	eq(pressed(stub, "AcceptQuest"), 0, "363 is behind the route now")
	detail(stub, 364)
	eq(pressed(stub, "AcceptQuest"), 1, "364 is next")
end)

test("auto quests: hands in, but never chooses a reward or pays", function()
	local stub = login()
	stub.accept(363)
	stub.dialog.quest, stub.dialog.completable = 363, true
	stub.fire("QUEST_PROGRESS")
	eq(pressed(stub, "CompleteQuest"), 1, "Continue")
	stub.fire("QUEST_COMPLETE")
	eq(pressed(stub, "GetQuestReward"), 1, "no reward to choose")
	stub.choices = { 1001, 1002, 1003 }
	stub.fire("QUEST_COMPLETE")
	eq(pressed(stub, "GetQuestReward"), 1, "three rewards: the player picks")
	ok(lastPrint(stub):find("pick your reward for Rude Awakening"), lastPrint(stub))
	stub.choices = {}
	stub.dialog.money = 500
	stub.fire("QUEST_COMPLETE")
	eq(pressed(stub, "GetQuestReward"), 1, "a quest that costs money")
end)

test("auto quests: gossip hands in first, one choice at a time, route quests only", function()
	local stub = login()
	stub.accept(363)
	stub.gossip.active = { { questID = 363, isComplete = true } }
	stub.gossip.available = { { questID = 364 } }
	stub.fire("GOSSIP_SHOW")
	eq(pressed(stub, "gossip active"), 1, "hand in")
	eq(pressed(stub, "gossip available"), 0, "one at a time")
	stub.turnin(363)
	stub.gossip.active = {}
	stub.fire("GOSSIP_SHOW")
	eq(pressed(stub, "gossip available"), 1, "then take the next")
	stub.gossip.available = { { questID = 424242 } }
	stub.fire("GOSSIP_SHOW")
	eq(pressed(stub, "gossip available"), 1, "not a quest of the route")
end)

test("auto quests: the old quest greeting works the same way", function()
	local stub = login()
	stub.accept(363)
	stub.greeting.active = { { id = 363, complete = true } }
	stub.greeting.available = { 364 }
	stub.fire("QUEST_GREETING")
	eq(pressed(stub, "greeting active"), 1)
	eq(pressed(stub, "greeting available"), 0)
end)

test("auto quests: an extra quest the player picked counts as the route's", function()
	local stub, ns = login()
	detail(stub, 366)
	eq(pressed(stub, "AcceptQuest"), 0, "not in the route")
	ns.Engine.AddExtra(366)
	detail(stub, 366)
	eq(pressed(stub, "AcceptQuest"), 1, "picked as an alternative")
end)

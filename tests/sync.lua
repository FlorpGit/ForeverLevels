-- Tests for party sync (Guide/Sync.lua). Loaded by tests/run.lua.
local h = ...
local test, eq, ok, fresh = h.test, h.eq, h.ok, h.fresh

local function contains(list, v)
	for _, x in ipairs(list) do if x == v then return true end end
	return false
end

local function login()
	local stub, ns = fresh()
	stub.player.level = 2
	stub.moveTo(1420, 30.2, 71.6)
	stub.login()
	return stub, ns
end

test("party sync: a message reads back the same, whatever the title holds", function()
	local _, ns = login()
	local S = ns.Sync
	local state = { routeId = "forever/horde/undead/01-tirisfal-glades", index = 3, total = 90, level = 2,
		title = "Mindless Zombies", quests = { { id = 364, done = 5, required = 13 } } }
	local back = S.Decode(S.Encode(state))
	eq(back.routeId, state.routeId)
	eq(back.index, 3)
	eq(back.total, 90)
	eq(back.level, 2)
	eq(back.title, "Mindless Zombies")
	eq(back.quests[1].id, 364)
	eq(back.quests[1].done, 5)
	eq(back.quests[1].required, 13)
	local m = S.Encode({ routeId = "r", index = 1, total = 2, level = 1, title = "a|b,c:d", quests = {} })
	eq(S.Decode(m).title, "a b c d", "separators cleaned")
	ok(#m <= 250, "fits an addon message")
	eq(S.Decode("hello"), nil, "garbage")
	eq(S.Decode("2|S|r|1|2|3|t|"), nil, "another protocol")
	ok(#S.PREFIX <= 16, "prefix length")
end)

test("party sync: off by default, nothing sent", function()
	local stub = login()
	stub.inGroup = true
	stub.accept(363)
	stub.advance(4)
	eq(#stub.sent, 0)
end)

test("party sync: on and in a group, one message every few seconds to the party", function()
	local stub, ns = login()
	SlashCmdList.PATHWISE("sync on")
	eq(ns.Get("party.sync"), true)
	stub.inGroup = true
	stub.accept(363)
	stub.accept(364, { { text = "Mindless Zombie slain: 2/8", numFulfilled = 2, numRequired = 8, finished = false } })
	stub.advance(4)
	eq(#stub.sent, 1, "one message for the burst")
	eq(stub.sent[1].prefix, "ForeverLevels")
	eq(stub.sent[1].channel, "PARTY")
	local st = ns.Sync.Decode(stub.sent[1].message)
	eq(st.routeId, "forever/horde/undead/01-tirisfal-glades")
	eq(st.level, 2)
	stub.inRaid = true
	stub.fire("GROUP_ROSTER_UPDATE")
	stub.advance(4)
	eq(stub.sent[#stub.sent].channel, "RAID")
	ok(contains(stub.prefixes, "ForeverLevels"), "prefix registered")
end)


test("party sync: nothing in chat lockdown or when addon messages are restricted", function()
	local stub, ns = login()
	ns.Set("party.sync", true)
	stub.inGroup, stub.lockdown = true, true
	stub.accept(363)
	stub.advance(4)
	eq(#stub.sent, 0, "lockdown")
	stub.lockdown, stub.restricted = false, true
	ns.Sync.Send()
	eq(#stub.sent, 0, "restricted (trial accounts)")
end)

test("party sync: members show in the guide window, not yourself", function()
	local stub, ns = login()
	ns.Set("party.sync", true)
	local m = ns.Sync.Encode({ routeId = "forever/horde/undead/01-tirisfal-glades", index = 3, total = 90, level = 3,
		title = "Mindless Zombies", quests = { { id = 364, done = 4, required = 8 } } })
	stub.fire("CHAT_MSG_ADDON", "ForeverLevels", m, "PARTY", "Friend-Realm")
	stub.fire("CHAT_MSG_ADDON", "ForeverLevels", m, "PARTY", "Tester-Realm")
	stub.fire("CHAT_MSG_ADDON", "SomethingElse", m, "PARTY", "Other-Realm")
	local members = ns.Sync.Members()
	eq(#members, 1)
	eq(members[1].name, "Friend")
	local line
	for _, t in ipairs(stub.texts()) do if t:find("^Friend") then line = t end end
	ok(line and line:find("step 3/90", 1, true) and line:find("4/8", 1, true), tostring(line))
	stub.inGroup = false
	stub.fire("GROUP_ROSTER_UPDATE")
	eq(#ns.Sync.Members(), 0, "left the group")
end)

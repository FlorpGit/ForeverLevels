local T = ...

T.Test("Sync: encode/decode round trip", function()
	local FL = T.Boot()
	local state = {
		routeId = "fl.horde.undead.01-deathknell", index = 3, total = 15, level = 2,
		title = "Thin out the zombies", quests = { { id = 364, done = 5, required = 13 } },
	}
	local decoded = FL.Sync.Decode(FL.Sync.Encode(state))
	T.Equal(decoded.routeId, state.routeId, "route")
	T.Equal(decoded.index, 3, "index")
	T.Equal(decoded.total, 15, "total")
	T.Equal(decoded.level, 2, "level")
	T.Equal(decoded.title, state.title, "title")
	T.Equal(decoded.quests[1].id, 364, "quest id")
	T.Equal(decoded.quests[1].done, 5, "done")
	T.Equal(decoded.quests[1].required, 13, "required")
end)

T.Test("Sync: separators in titles cannot break the format", function()
	local FL = T.Boot()
	local message = FL.Sync.Encode({ routeId = "r", index = 1, total = 2, level = 1, title = "a|b,c:d", quests = {} })
	local decoded = FL.Sync.Decode(message)
	T.Equal(decoded.title, "a b c d", "sanitized")
	T.True(#message <= 250, "fits addon message limit")
end)

T.Test("Sync: garbage and other protocol versions are ignored", function()
	local FL = T.Boot()
	T.Equal(FL.Sync.Decode("hello"), nil, "garbage")
	T.Equal(FL.Sync.Decode("2|S|r|1|2|3|t|"), nil, "future protocol")
end)

T.Test("Sync: off by default, sends nothing", function()
	T.Boot()
	T.Stub.inGroup = true
	T.Accept(363)
	T.Stub.Advance(4)
	T.Equal(#T.Stub.sent, 0, "nothing sent")
end)

T.Test("Sync: when enabled and grouped, broadcasts to PARTY with throttling", function()
	local FL = T.Boot()
	FL.Options.Set("sync", true)
	T.Stub.inGroup = true
	T.Accept(363)
	T.Stub.Advance(4)
	T.Equal(#T.Stub.sent, 1, "one message")
	T.Equal(T.Stub.sent[1].prefix, "ForeverLevels", "prefix")
	T.Equal(T.Stub.sent[1].channel, "PARTY", "channel")
	T.True(#"ForeverLevels" <= 16, "prefix length limit")
end)

T.Test("Sync: respects chat lockdown and restricted outgoing addon messages", function()
	local FL = T.Boot()
	FL.Options.Set("sync", true)
	T.Stub.inGroup = true
	T.Stub.lockdown = true
	T.Accept(363)
	T.Stub.Advance(4)
	T.Equal(#T.Stub.sent, 0, "nothing sent in lockdown")
	T.Stub.lockdown = false
	T.Stub.addonRestricted = true
	FL.Sync:Send()
	T.Equal(#T.Stub.sent, 0, "nothing sent when restricted (e.g. trial accounts)")
end)

T.Test("Sync: receives party members and ignores own messages", function()
	local FL = T.Boot()
	FL.Options.Set("sync", true)
	local message = FL.Sync.Encode({ routeId = "fl.horde.undead.01-deathknell", index = 4, total = 15, level = 3, title = "X", quests = {} })
	T.Stub.FireEvent("CHAT_MSG_ADDON", "ForeverLevels", message, "PARTY", "Friend-Realm")
	T.Stub.FireEvent("CHAT_MSG_ADDON", "ForeverLevels", message, "PARTY", "Tester-Realm")
	local members = FL.Sync:GetMembers()
	T.Equal(#members, 1, "one member")
	T.Equal(members[1].name, "Friend", "short name")
	T.Equal(members[1].state.index, 4, "their step")
end)

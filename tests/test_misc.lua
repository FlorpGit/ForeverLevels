local T = ...

T.Test("Recorder: off by default, logs accept and turn-in with position when on", function()
	local FL = T.Boot()
	T.Accept(363)
	T.Equal(#FL.db.recorder, 0, "nothing recorded by default")
	FL.HandleSlash("record on")
	T.Stub.Quest(364).title = "The Mindless Ones"
	T.Accept(364)
	T.TurnIn(364)
	T.Equal(#FL.db.recorder, 2, "two entries")
	local entry = FL.db.recorder[1]
	T.Equal(entry.kind, "accept", "kind")
	T.Equal(entry.questID, 364, "quest")
	T.Equal(entry.mapID, 2001, "map")
	T.Equal(entry.zone, "Tirisfal Glades", "zone")
	T.Equal(entry.x, 30.0, "x")
	T.Equal(entry.y, 70.0, "y")
	T.Equal(entry.build, "70450", "build")
end)

T.Test("Dungeons: suggestions by level and faction", function()
	local FL = T.Boot()
	local list = FL:GetDungeonSuggestions(15, "Horde")
	T.Equal(#list, 1, "one dungeon at 15 for Horde")
	T.Equal(list[1].id, "RFC", "Ragefire Chasm")
	for _, dungeon in ipairs(FL:GetDungeonSuggestions(20, "Horde")) do
		T.True(dungeon.faction ~= "Alliance", "no Alliance-only dungeons for Horde")
	end
end)

T.Test("Commands: every slash command runs without error", function()
	local FL = T.Boot()
	for _, input in ipairs({
		"", "", "help", "routes", "route fl.horde.undead.02-brill", "route nope", "next", "back", "skip",
		"lock", "unlock", "scale 1.2", "scale 9", "arrow off", "arrow on", "waypoint", "auto off", "auto on",
		"sync on", "sync off", "dungeons", "record", "recorder", "recorder clear", "debug", "where",
		"style", "style tooltip", "style nope", "style classic", "options", "reset", "unknowncommand",
	}) do
		FL.HandleSlash(input)
	end
	T.Equal(FL.db.profile.frame.scale, 1.2, "scale applied")
	T.Equal(FL.db.profile.autoAccept, true, "auto toggled back on")
end)

T.Test("GuideFrame: renders a step with goals and the unverified notice", function()
	local FL = T.Boot()
	local guide
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, "nextButton") then guide = frame end
	end
	T.True(guide, "guide frame created")
	FL.GuideFrame:Update()
	T.True(guide.header.text:find("Deathknell"), "route title shown")
	T.Equal(guide.counter.text, "1/15", "counter")
	T.True(guide.lines[1].text:find("Rude Awakening"), "goal line uses quest name")
	T.True(guide.note.text:find("Not yet verified"), "verification notice")
end)

T.Test("GuideFrame: classic style by default, switchable and saved", function()
	local FL = T.Boot()
	local guide
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, "nextButton") then guide = frame end
	end
	T.Equal(FL.db.profile.frame.style, "classic", "default style")
	T.Equal(guide.backdrop.edgeFile, [[Interface\DialogFrame\UI-DialogBox-Border]], "classic dialog border")
	FL.HandleSlash("style tooltip")
	T.Equal(guide.backdrop.edgeFile, [[Interface\Tooltips\UI-Tooltip-Border]], "tooltip border")
	FL.HandleSlash("style")
	T.Equal(FL.db.profile.frame.style, "minimal", "cycled to minimal")
	FL.HandleSlash("style")
	T.Equal(FL.db.profile.frame.style, "classic", "cycled back to classic")
	FL.HandleSlash("style nope")
	T.Equal(FL.db.profile.frame.style, "classic", "unknown style ignored")
	T.True(T.ChatContains("usage: /fl style"), "usage shown")
end)

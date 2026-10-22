local T = ...

T.Test("Branding: Pathwise and ForeverLevels globals are the same namespace", function()
	local FL = T.Boot()
	T.True(_G.Pathwise == FL, "Pathwise global")
	T.True(_G.ForeverLevels == FL, "ForeverLevels global kept")
	T.Equal(FL.BRAND, "Pathwise", "brand")
	T.Equal(FL.CREATORS, "leight_nn & florp", "creators")
end)

T.Test("Branding: /pathwise is the main command and /fl, /foreverlevels still work", function()
	local FL = T.Boot()
	T.Equal(_G.SLASH_FOREVERLEVELS1, "/pathwise", "main command")
	T.Equal(_G.SLASH_FOREVERLEVELS2, "/fl", "short alias kept")
	T.Equal(_G.SLASH_FOREVERLEVELS3, "/foreverlevels", "long alias kept")
	-- All three share one handler, so typing /fl next behaves like /pathwise next.
	T.Accept(363)
	T.Equal(FL.Engine.index, 2, "start")
	_G.SlashCmdList.FOREVERLEVELS("back")
	T.Equal(FL.Engine.index, 1, "back via the shared handler")
end)

T.Test("Branding: Pathwise:RegisterRoute and ForeverLevels:RegisterRoute both register", function()
	local FL = T.Boot()
	local function Route(id)
		return { id = id, title = id, author = "a", license = "CC0", levels = { 1, 2 },
			steps = { { id = "s", title = "S", accept = { 1 } } } }
	end
	T.True(_G.Pathwise:RegisterRoute(Route("via.pathwise")), "Pathwise API")
	T.True(_G.ForeverLevels:RegisterRoute(Route("via.foreverlevels")), "legacy API")
	T.True(FL:GetRoute("via.pathwise") and FL:GetRoute("via.foreverlevels"), "both stored in one registry")
end)

T.Test("Branding: chat prefix and guide header say Pathwise", function()
	local FL = T.Boot()
	T.True(T.ChatContains("Pathwise"), "chat prefix")
	local guide
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, "nextButton") then guide = frame end
	end
	FL.GuideFrame:Update()
	T.True(guide.header.text:find("^Pathwise %- Undead 1%-6"), "header: " .. tostring(guide.header.text))
end)

T.Test("Branding: saved progress from a ForeverLevels install loads unchanged", function()
	local saved = {
		db = { profile = { autoAccept = false, frame = { style = "tooltip" } }, recorder = {}, dbVersion = 1 },
		char = { routeId = "fl.horde.undead.01-deathknell", progress = { ["fl.horde.undead.01-deathknell"] = { step = 3, skipped = {} } }, turnedIn = {}, dbVersion = 1 },
	}
	T.Stub.Reset()
	local FL = T.Boot({ saved = saved })
	T.Equal(FL.Engine.route.id, "fl.horde.undead.01-deathknell", "route kept")
	T.Equal(FL.Engine.index, 3, "step kept")
	T.Equal(FL.db.profile.autoAccept, false, "setting kept")
	T.Equal(FL.db.profile.frame.style, "tooltip", "style kept")
end)

local T = ...

local function Settle()
	T.Stub.FireEvent("BAG_UPDATE_DELAYED")
	T.Stub.Advance(1.2)
end

-- Crafter on the Brill route (level 8) with linen for Bolt of Linen Cloth.
local function BootWithLinen(opts)
	opts = opts or {}
	local FL = T.BootCrafter(opts)
	T.Stub.items[2589] = 10
	Settle()
	return FL
end

local function AddTrainerWithCoords(FL)
	T.True(_G.Pathwise:RegisterProfessionData({
		id = "test.trainer.coords", profession = "tailoring", name = "Tailoring", author = "test", license = "CC0",
		trainers = { { name = "Test Trainer", zone = "Tirisfal Glades", x = 61.0, y = 52.0 } },
		recipes = { { id = 999100, name = "Test Recipe", reagents = { { 999101, 1 } } } },
	}), "test pack registered")
end

local function Banner()
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, "buttons") and rawget(frame, "label") then return frame end
	end
end

T.Test("Detours: craft suggestion appears when materials are owned; route untouched", function()
	local FL = BootWithLinen()
	local route, index = FL.Engine.route.id, FL.Engine.index
	local suggestion = FL.Detours.suggestion
	T.True(suggestion, "suggested")
	T.Equal(suggestion.kind, "craft", "craft detour")
	T.True(suggestion.title:find("Bolt of Linen Cloth"), "bolt craft: " .. suggestion.title)
	T.Equal(FL.Engine.route.id, route, "route unchanged")
	T.Equal(FL.Engine.index, index, "step index unchanged")
	local banner = Banner()
	T.True(banner and banner.shown, "banner shown")
	T.Equal(banner.buttons[1].text, "Go", "Go button")
	T.Equal(banner.buttons[2].text, "Later", "Later button")
	T.Equal(banner.buttons[3].text, "Skip", "Skip button")
end)

T.Test("Detours: turned off means no suggestions and no active detour", function()
	local FL = BootWithLinen()
	FL.Detours:Accept()
	FL.HandleSlash("detour off")
	T.Equal(FL.db.profile.professions.detours, false, "setting saved")
	T.Equal(FL.Detours:GetActive(), nil, "active dropped")
	Settle()
	T.Equal(FL.Detours.suggestion, nil, "nothing suggested")
	T.True(not Banner().shown, "banner hidden")
	FL.HandleSlash("detour on")
	Settle()
	T.True(FL.Detours.suggestion, "back on")
end)

T.Test("Detours: accepting keeps route progress, quest detection and Back/Next", function()
	local FL = BootWithLinen()
	T.Equal(FL.Engine:GetCurrentStep().id, "br-calvin", "route start")
	T.True(FL.Detours:Accept(), "accepted")
	T.True(FL.Detours:GetActive(), "active")
	T.Equal(Banner().buttons[1].text, "Done", "Done button")
	T.Accept(8)                                   -- route keeps working during a detour
	T.Equal(FL.Engine:GetCurrentStep().id, "br-gordo", "quest still advances the route")
	FL.Engine:Prev()
	T.Equal(FL.Engine:GetCurrentStep().id, "br-calvin", "Back unchanged")
	FL.Engine:Next()
	T.Equal(FL.Engine:GetCurrentStep().id, "br-gordo", "Next unchanged")
	T.True(FL.Detours:GetActive(), "detour still active")
end)

T.Test("Detours: Skip hides a detour for good; Later brings it back after the route moves", function()
	local FL = BootWithLinen()
	local first = FL.Detours.suggestion.id
	FL.Detours:Postpone()
	Settle()
	T.True(not FL.Detours.suggestion or FL.Detours.suggestion.id ~= first, "postponed detour waits")
	T.Accept(8)                                   -- route moves to the next step
	Settle()
	T.Equal(FL.Detours.suggestion and FL.Detours.suggestion.id, first, "postponed detour returns")
	FL.Detours:Skip()
	T.Accept(5481); T.Finish(5481)
	Settle()
	T.True(not FL.Detours.suggestion or FL.Detours.suggestion.id ~= first, "skipped detour stays gone")
	T.Equal(FL.char.professions.detours.states[first], "skipped", "skip saved")
end)

T.Test("Detours: trainer detour points the arrow at the trainer, then restores the route waypoint", function()
	local FL = T.BootCrafter({ tailoring = 55, player = { class = "MAGE", race = "Scourge", level = 10 } })
	AddTrainerWithCoords(FL)
	Settle()
	local routeTitle = FL.Waypoint.target.title
	local suggestion = FL.Detours.suggestion
	T.True(suggestion and suggestion.kind == "trainer", "trainer detour")
	T.True(suggestion.title:find("Train Journeyman Tailoring"), suggestion.title)
	T.Equal(FL.Waypoint.target.title, routeTitle, "no navigation change before Go")
	FL.Detours:Accept()
	T.True(FL.Waypoint.target.title:find("^Detour:"), "arrow targets the detour")
	T.Equal(FL.Waypoint.target.x, 61.0, "trainer x")
	T.True(math.abs(T.Stub.userWaypoint.position.x - 0.61) < 1e-9, "map pin moved")
	-- Training raises the cap; the detour completes on its own.
	T.Stub.professions[1].maxRank = 150
	T.Stub.FireEvent("SKILL_LINES_CHANGED")
	T.Stub.Advance(1.2)
	T.Equal(FL.Detours:GetActive(), nil, "completed")
	T.Equal(FL.Waypoint.target.title, routeTitle, "route waypoint restored")
	local step = FL.Engine:GetCurrentStep()
	T.True(math.abs(T.Stub.userWaypoint.position.x - step.x / 100) < 1e-9, "map pin back on the route step")
end)

T.Test("Detours: trainers without verified coordinates get no waypoint", function()
	local FL = T.BootCrafter({ tailoring = 55, player = { class = "MAGE", race = "Scourge", level = 10 } })
	Settle()
	local suggestion = FL.Detours.suggestion
	T.True(suggestion and suggestion.kind == "trainer", "trainer detour")
	T.Equal(suggestion.x, nil, "no coordinates")
	T.True(suggestion.note:find("not verified"), "says why")
	local routeTitle = FL.Waypoint.target.title
	FL.Detours:Accept()
	T.Equal(FL.Waypoint.target.title, routeTitle, "arrow stays on the route")
end)

T.Test("Detours: finishing a craft detour never advances quest steps", function()
	local FL = BootWithLinen({ tailoring = 30 })
	local index = FL.Engine.index
	FL.Detours:Accept()
	local active = FL.Detours:GetActive()
	T.Equal(active.kind, "craft", "craft detour")
	T.Stub.professions[1].rank = active.targetRank
	T.Stub.FireEvent("SKILL_LINES_CHANGED")
	T.Stub.Advance(1.2)
	T.Equal(FL.Detours:GetActive(), nil, "craft detour completed")
	T.Equal(FL.char.professions.detours.states[active.id], "done", "saved as done")
	T.Equal(FL.Engine.index, index, "route step unchanged")
end)

T.Test("Detours: states survive a reload", function()
	local FL = BootWithLinen()
	local id = FL.Detours.suggestion.id
	FL.Detours:Skip()
	FL.Detours:Accept()    -- next candidate, if any
	local FL2 = T.BootCrafter({ saved = { db = FL.db, char = FL.char } })
	T.Stub.items[2589] = 10
	Settle()
	T.Equal(FL2.char.professions.detours.states[id], "skipped", "skip kept")
	T.True(not FL2.Detours.suggestion or FL2.Detours.suggestion.id ~= id, "not offered again")
end)

T.Test("Detours: bursts of events evaluate once", function()
	local FL = BootWithLinen()
	local calls = 0
	local original = FL.Detours.Evaluate
	FL.Detours.Evaluate = function(self) calls = calls + 1 return original(self) end
	for _ = 1, 5 do T.Stub.FireEvent("BAG_UPDATE_DELAYED") end
	T.Stub.FireEvent("ZONE_CHANGED_NEW_AREA")
	T.Stub.FireEvent("SKILL_LINES_CHANGED")
	T.Stub.Advance(1.5)
	T.Equal(calls, 1, "one evaluation")
	FL.Detours.Evaluate = original
end)

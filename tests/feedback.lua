-- Tests for the Feedback Center (Core/Feedback.lua, UI/Feedback.lua).
-- Loaded by tests/run.lua.
local h = ...
local test, eq, ok, fresh, lastPrint = h.test, h.eq, h.ok, h.fresh, h.lastPrint

local function login(setup)
	local stub, ns = fresh()
	stub.player.level = 2
	stub.moveTo(1420, 30.2, 71.6)
	if setup then setup(stub) end
	stub.login()
	return stub, ns
end

-- Types into the shown box of input row `key` ("feedback.description").
local function typeInto(stub, key, text)
	for _, f in ipairs(stub.frames) do
		if rawget(f, "key") == key and f.shown and rawget(f, "box") then
			f.box:SetText(text)
			f.box.scripts.OnTextChanged(f.box, true)
			return
		end
	end
	error("no box for " .. key)
end

local function boxText(stub, key)
	for _, f in ipairs(stub.frames) do
		if rawget(f, "key") == key and f.shown and rawget(f, "box") then return f.box.text end
	end
end

-- The shown copy box that holds the prepared report.
local function reportBox(stub)
	for _, f in ipairs(stub.frames) do
		local t = rawget(f, "text")
		if type(t) == "string" and t:find("^PATHWISE %- ") and f.shown and rawget(f, "box") then return f end
	end
end

local function shownText(stub, text)
	for _, t in ipairs(stub.texts()) do if t:find(text, 1, true) then return true end end
	return false
end

test("feedback: the step's route, number, title, quests, goals and place", function()
	local stub, ns = login()
	local ctx = ns.Feedback.CollectStepContext()
	eq(ctx.routeId, "forever/horde/undead/01-tirisfal-glades")
	eq(ctx.stepIndex, 1)
	eq(ctx.stepTitle, "Undertaker Mordo")
	ok(ctx.stepText:find("crypt", 1, true), ctx.stepText)
	eq(ctx.quests[1].id, 363)
	eq(ctx.quests[1].kind, "accept")
	eq(ctx.goals[1].status, "open")
	eq(ctx.waypoint.map, 1420)
	ok(math.abs(ctx.waypoint.x - 30.22) < 1e-6, "x")
	stub.accept(363)
	eq(ns.Feedback.CollectStepContext().stepIndex, 2, "follows the guide")
end)

test("feedback: the flag opens a report of this step and changes nothing", function()
	local stub, ns = login()
	stub.accept(363)
	local E = ns.Engine
	local before = { E.LiveStep(), E.CurrentStep(), E.Route().id }
	ns.Fire("REPORT_STEP")
	ok(ns.FeedbackCenter.IsShown(), "open")
	ok(shownText(stub, "REPORT THIS STEP"), "the step report")
	local draft = ns.Feedback.CurrentDraft()
	eq(draft.type, "step")
	eq(draft.context.stepIndex, 2, "this step")
	eq(E.LiveStep(), before[1])
	eq(E.CurrentStep(), before[2])
	eq(E.Route().id, before[3])
	ok(stub.log[363], "the quest log is untouched")
end)

test("feedback: preparing needs a description and a problem, and never says it was sent", function()
	local stub, ns = login()
	ns.Fire("REPORT_STEP")
	stub.clickLabel("Prepare report")
	ok(shownText(stub, "Describe what happened"), "description first")
	eq(reportBox(stub), nil, "no report yet")
	typeInto(stub, "feedback.description", "Mordo is not where the arrow points.")
	stub.clickLabel("Prepare report")
	ok(shownText(stub, "Pick what is wrong with this step"), "then the problem")
	ok(stub.clickLabelText("Wrong NPC location"), "pick it")
	eq(ns.Feedback.CurrentDraft().category, "npc_location")
	stub.clickLabel("Prepare report")
	ok(shownText(stub, "Report ready, not sent"), "says it was not sent")
	ok(shownText(stub, "discord.gg") and shownText(stub, "pathwise.nn@gmail.com"), "where to send it")
	for _, t in ipairs(stub.texts()) do
		for _, phrase in ipairs({ "has been sent", "was sent", "Report sent", "submitted" }) do
			ok(not t:find(phrase, 1, true), "never claims: " .. phrase)
		end
	end
	local box = reportBox(stub)
	ok(box, "the report to copy")
	box.box:SetText("edited")
	box.box.scripts.OnTextChanged(box.box, true)
	eq(box.box.text, box.text, "the report box cannot be edited")
end)

test("feedback: the report's text, the goals with their status, and the data line", function()
	local stub, ns = login()
	ns.Fire("REPORT_STEP")
	local F = ns.Feedback
	F.SetField("category", "waypoint")
	F.SetField("description", "The arrow points to the wrong place.")
	F.SetField("correctCoords", "30.5, 70.9 Tirisfal Glades")
	local text, report = F.Prepare()
	for _, line in ipairs({
		"PATHWISE - GUIDE STEP REPORT",
		"Report type: Guide step - Incorrect waypoint or coordinates",
		"Route: Tirisfal Glades (forever/horde/undead/01-tirisfal-glades)",
		"Step: 1/",
		"Step title: Undertaker Mordo",
		"Quest IDs: 363 (accept: Rude Awakening)",
		"Waypoint: 30.2, 71.7 Tirisfal Glades (map 1420)",
		"  1. open: accept 363 Rude Awakening  [log: not in log]",
		"Zone: Tirisfal Glades",
		"Addon version: Pathwise 0.1.0-test",
		"Player description:\nThe arrow points to the wrong place.",
		"Correct coordinates:\n30.5, 70.9 Tirisfal Glades",
		"Send to: Pathwise's Discord (https://discord.gg/hSDjBrG8EK) or pathwise.nn@gmail.com",
	}) do ok(text:find(line, 1, true), "missing: " .. line .. "\n" .. text) end
	ok(not text:find("\226\128", 1, true), "plain ASCII punctuation")
	local data = F.ParseKeyValue(text:match("Report data %(format 2%): ([^\n]+)"))
	eq(data.route, "forever/horde/undead/01-tirisfal-glades")
	eq(data.step, "1")
	eq(data.quests, "363")
	eq(data.category, "waypoint")
	eq(data.map, "1420")
	report.zone = "Odd; zone = name\nline"
	eq(F.ParseKeyValue(F.ToKeyValue(report)).zone, report.zone, "escaping survives separators")
end)

test("feedback: character details and diagnostics only when turned on", function()
	local stub, ns = login()
	ns.Fire("REPORT_STEP")
	ok(shownText(stub, "Character (not included)"), "the preview says so")
	ns.Feedback.SetField("category", "objectives")
	typeInto(stub, "feedback.description", "Objectives differ.")
	local text = ns.Feedback.Prepare()
	ok(text:find("Character: not included", 1, true))
	ok(text:find("Diagnostics: not included", 1, true))
	ok(not text:find("Mage", 1, true), "no class without consent")
	ok(stub.clickLabel("Include"), "character")
	ok(stub.clickLabel("Include"), "diagnostics")
	text = ns.Feedback.Prepare()
	ok(text:find("Character: level 2 Undead Mage, Horde", 1, true), text)
	ok(text:find("Game: 1.60.1 build 70532 (Forever)", 1, true), "game build")
	ok(text:find("Arrow target: 30.2, 71.7 map 1420", 1, true), "arrow")
end)

test("feedback: drafts per step and a general one survive a reload; discarding removes one", function()
	local stub, ns = login()
	ns.Fire("REPORT_STEP")
	typeInto(stub, "feedback.description", "Mordo is not here.")
	typeInto(stub, "feedback.correctNpc", "Undertaker Mordo")
	SlashCmdList.PATHWISE("feedback")
	typeInto(stub, "feedback.description", "An idea.")
	local saved = PathwiseSettings

	local stub2, ns2 = fresh()
	PathwiseSettings = saved
	stub2.player.level = 2
	stub2.moveTo(1420, 30.2, 71.6)
	stub2.login()
	ns2.Fire("REPORT_STEP")
	eq(boxText(stub2, "feedback.description"), "Mordo is not here.", "the step's draft")
	eq(boxText(stub2, "feedback.correctNpc"), "Undertaker Mordo")
	SlashCmdList.PATHWISE("feedback")
	eq(boxText(stub2, "feedback.description"), "An idea.", "the general draft, apart")
	stub2.clickLabel("Discard draft")
	local drafts = ns2.Get("feedback.drafts")
	eq(drafts.general, nil, "discarded")
	ok(drafts["step:forever/horde/undead/01-tirisfal-glades:1"], "the step's draft stays")
end)

test("feedback: without a route it is a general report, and Guide step is not offered", function()
	local stub, ns = login(function(s) s.player.raceID, s.player.race, s.player.faction = 99, "Nobody", "Neutral" end)
	eq(ns.Feedback.CollectStepContext(), nil)
	SlashCmdList.PATHWISE("report")
	ok(lastPrint(stub):find("general report", 1, true), lastPrint(stub))
	ok(ns.FeedbackCenter.IsShown())
	eq(ns.Feedback.CurrentDraft().type, "bug")
	ok(not stub.clickLabel("Guide step"), "no step to report")
	ok(stub.clickLabel("Suggestion"))
	eq(ns.Feedback.CurrentDraft().type, "suggestion")
end)

test("feedback: /pw feedback, /fl feedback and Settings open the same panel", function()
	local stub, ns = login()
	SlashCmdList.PATHWISE("feedback")
	ok(ns.FeedbackCenter.IsShown())
	eq(ns.Feedback.CurrentDraft().type, "bug")
	ns.Panels.Close()
	eq(SLASH_PATHWISE3, "/fl")
	SlashCmdList.PATHWISE("bug")
	ok(ns.FeedbackCenter.IsShown(), "/pw bug")
	ns.Panels.Close()
	ns.Fire("SHOW_SETTINGS")
	ok(stub.clickLabelText("Report a bug or make a suggestion"), "in Settings")
	ok(ns.FeedbackCenter.IsShown())
end)

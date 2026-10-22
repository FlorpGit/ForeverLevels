local T = ...

local function Find(key)
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, key) then return frame end
	end
end

local function Center() return Find("typeButton") end
local function Guide() return Find("nextButton") end

-- Simulates the player typing into an edit box (or a scroll frame holding one).
local function Type(input, text)
	local box = rawget(input, "box") or input
	box:SetText(text)
	box.scripts.OnTextChanged(box, true)
end

local function Snapshot(FL)
	local progress = FL.char.progress[FL.Engine.route.id]
	return { index = FL.Engine.index, hold = FL.Engine.hold, step = progress.step, route = FL.Engine.route.id }
end

T.Test("Feedback: collects the current step's route, step, quest IDs, waypoint and verification", function()
	local FL = T.Boot()
	local ctx = FL.Feedback.CollectStepContext()
	T.Equal(ctx.routeId, "fl.horde.undead.01-deathknell", "route id")
	T.Equal(ctx.routeTitle, "Undead 1-6: Deathknell", "route title")
	T.Equal(ctx.stepIndex, 1, "step number"); T.Equal(ctx.stepCount, 15, "total steps")
	T.Equal(ctx.stepTitle, "Wake up", "title")
	T.True(ctx.stepText:find("Undertaker Mordo"), "instructions")
	T.Equal(ctx.quests[1].id, 363, "quest id"); T.Equal(ctx.quests[1].kind, "accept", "goal kind")
	T.Equal(ctx.waypoint.x, 30.2, "x"); T.Equal(ctx.waypoint.mapID, 2001, "map id")
	T.Equal(ctx.verified, false, "unverified")
	T.Accept(363)
	T.Equal(FL.Feedback.CollectStepContext().stepIndex, 2, "follows the current step")
end)

T.Test("Feedback: report text includes quest IDs, or says there are none", function()
	local FL = T.Boot()
	FL.FeedbackCenter:OpenForStep()
	FL.Feedback.SetField("category", "waypoint")
	FL.Feedback.SetField("description", "The arrow points to the wrong location.")
	local text = FL.Feedback.Prepare()
	T.True(text:find("Quest IDs: 363 (accept: Rude Awakening)", 1, true), "quest id listed")

	local FL2 = T.Boot({ player = { level = 9 } })
	FL2.Engine:SelectRoute("fl.horde.undead.02-brill")
	FL2.Engine:GoTo(12)                                 -- "Reach level 10": no quests
	FL2.FeedbackCenter:OpenForStep()
	FL2.Feedback.SetField("category", "other")
	FL2.Feedback.SetField("description", "Level step test.")
	T.True(FL2.Feedback.Prepare():find("Quest IDs: none for this step", 1, true), "no quest id handled")
end)

T.Test("Feedback: a step without coordinates says there is no waypoint", function()
	local FL = T.Boot()
	T.True(FL:RegisterRoute({ id = "test.nowaypoint", title = "No waypoint", author = "a", license = "CC0", levels = { 1, 60 },
		steps = { { id = "talk", title = "Talk", text = "Talk to someone.", accept = { 424242 } } } }), "route")
	FL.Engine:SelectRoute("test.nowaypoint")
	local ctx = FL.Feedback.CollectStepContext()
	T.Equal(ctx.waypoint, nil, "no waypoint")
	FL.FeedbackCenter:Open(ctx)
	FL.Feedback.SetField("category", "waypoint")
	FL.Feedback.SetField("description", "No arrow.")
	T.True(FL.Feedback.Prepare():find("Waypoint: none for this step", 1, true), "handled")
end)

T.Test("Feedback: the report button opens the step report without touching progress", function()
	local FL = T.Boot()
	T.Accept(363)
	local guide = Guide()
	local button = guide.reportButton
	T.True(button.shown, "visible with an active step")
	button.scripts.OnEnter(button)
	T.Equal(_G.GameTooltip.text, "Report an issue with this guide step.", "tooltip")
	button.scripts.OnLeave(button)
	local before = Snapshot(FL)
	local stepChanged = false
	FL:On("STEP_CHANGED", function() stepChanged = true end)
	button.scripts.OnClick(button)
	T.True(FL.FeedbackCenter:IsShown(), "Feedback Center open")
	local draft = FL.Feedback.GetCurrentDraft()
	T.Equal(draft.type, "step", "step report")
	T.Equal(draft.context.stepId, "dk-sarvis-1", "current step filled in")
	local after = Snapshot(FL)
	for key, value in pairs(before) do T.Equal(after[key], value, "unchanged " .. key) end
	T.True(not stepChanged, "no step change")
	T.Equal(T.Stub.Quest(363).onQuest, true, "quest state untouched")
end)

T.Test("Feedback: with no active route the button hides and reports fall back to a general report", function()
	local FL = T.Boot({ player = { race = "Orc" } })
	T.True(not Guide().reportButton.shown, "hidden without a step")
	T.Equal(FL.Feedback.CollectStepContext(), nil, "no context")
	FL.HandleSlash("report")
	T.True(T.ChatContains("no guide step is selected"), "explained")
	T.True(FL.FeedbackCenter:IsShown(), "general report opened")
	T.Equal(FL.Feedback.GetCurrentDraft().type, "bug", "bug report")
	Center().typeButton.scripts.OnClick()
	T.Equal(FL.Feedback.GetCurrentDraft().type, "suggestion", "step type skipped without a step")
	Center().typeButton.scripts.OnClick()
	T.Equal(FL.Feedback.GetCurrentDraft().type, "bug", "cycles back")
end)

T.Test("Feedback: read-only preview lists what is collected and what is included", function()
	local FL = T.Boot()
	FL.FeedbackCenter:OpenForStep()
	local preview = Center().preview.text
	T.True(preview:find("Route: Undead 1-6: Deathknell, step 1/15", 1, true), "route and step")
	T.True(preview:find("Quest IDs: 363", 1, true), "quest ids")
	T.True(preview:find("Waypoint: 30.2, 71.6 Tirisfal Glades (map 2001)", 1, true), "waypoint")
	T.True(preview:find("Character (not included)", 1, true), "character opt-in shown")
	T.True(preview:find("Diagnostics (not included)", 1, true), "diagnostics opt-in shown")
	-- The prepared report box can be selected but not edited.
	FL.Feedback.SetField("category", "waypoint")
	Type(Center().inputs.description, "Wrong spot.")
	Center().prepareButton.scripts.OnClick()
	local output = Center().output.box
	local prepared = output.text
	Type(Center().output, "edited by player")
	T.Equal(output.text, prepared, "output box stays read-only")
end)

T.Test("Feedback: character details and diagnostics are only included after opting in", function()
	local FL = T.Boot({ player = { class = "MAGE", level = 8 } })
	FL.FeedbackCenter:OpenForStep()
	FL.Feedback.SetField("category", "objectives")
	Type(Center().inputs.description, "Objectives differ.")
	local text = FL.Feedback.Prepare()
	T.True(text:find("Character: not included", 1, true), "character off by default")
	T.True(text:find("Diagnostics: not included", 1, true), "diagnostics off by default")
	T.True(not text:find("Mage", 1, true), "no class without consent")
	Center().characterButton.scripts.OnClick()
	Center().diagnosticsButton.scripts.OnClick()
	text = FL.Feedback.Prepare()
	T.True(text:find("Character: level 8 Undead Mage, Horde", 1, true), "character included")
	T.True(text:find("Game: 1.60.1 build 70450 (Forever)", 1, true), "diagnostics included")
	T.True(text:find("Arrow target:", 1, true), "arrow target included")
end)

T.Test("Feedback: drafts are kept per step, survive a reload, and can be discarded", function()
	local FL = T.Boot()
	FL.FeedbackCenter:OpenForStep()
	Type(Center().inputs.description, "Mordo is not here.")
	Type(Center().inputs.correctNpc, "Undertaker Mordo")
	FL.FeedbackCenter:Open(nil)
	Type(Center().inputs.description, "General idea.")
	local db, char = _G.ForeverLevelsDB, _G.ForeverLevelsCharDB

	local FL2 = T.Boot({ saved = { db = db, char = char } })
	FL2.FeedbackCenter:OpenForStep()
	T.Equal(rawget(Center().inputs.description, "box").text, "Mordo is not here.", "step draft restored")
	T.Equal(Center().inputs.correctNpc.text, "Undertaker Mordo", "optional field restored")
	FL2.FeedbackCenter:Open(nil)
	T.Equal(rawget(Center().inputs.description, "box").text, "General idea.", "general draft separate")
	Center().discardButton.scripts.OnClick()
	T.Equal(FL2.db.feedback.drafts.general, nil, "general draft discarded")
	T.True(FL2.db.feedback.drafts["step:fl.horde.undead.01-deathknell:dk-mordo"], "step draft kept")
end)

T.Test("Feedback: report format, recipient and machine-readable block", function()
	local FL = T.Boot()
	FL.FeedbackCenter:OpenForStep()
	FL.Feedback.SetField("category", "waypoint")
	FL.Feedback.SetField("description", "The arrow points to the wrong location.")
	FL.Feedback.SetField("correctCoords", "30.5, 70.9 Tirisfal Glades")
	local text, report = FL.Feedback.Prepare()
	local expected = {
		"PATHWISE - GUIDE STEP REPORT",
		"Report type: Guide step - Incorrect waypoint or coordinates",
		"Route: Undead 1-6: Deathknell (fl.horde.undead.01-deathknell)",
		"Route version: not set",
		"Step: 1/15 (dk-mordo)",
		"Step title: Wake up",
		"Waypoint: 30.2, 71.6 Tirisfal Glades (map 2001)",
		"Step verification: Unverified",
		"Zone: Tirisfal Glades",
		"Addon version: Pathwise 0.1.0-test",
		"Player description:\nThe arrow points to the wrong location.",
		"Correct coordinates:\n30.5, 70.9 Tirisfal Glades",
		"Send to: pathwise.nn@gmail.com",
	}
	for _, line in ipairs(expected) do T.True(text:find(line, 1, true), "missing: " .. line) end
	T.True(not text:find("\226\128", 1, true), "plain ASCII punctuation")
	local block = text:match("Report data %(format 1%): ([^\n]+)")
	local data = FL.Feedback.ParseKeyValue(block)
	T.Equal(data.route, "fl.horde.undead.01-deathknell", "route")
	T.Equal(data.step, "1", "step")
	T.Equal(data.quests, "363", "quests")
	T.Equal(data.category, "waypoint", "category")
	T.Equal(data.map, "2001", "map")
	-- Escaping survives separators in values.
	report.zone = "Odd; zone = name\nline"
	T.Equal(FL.Feedback.ParseKeyValue(FL.Feedback.ToKeyValue(report)).zone, report.zone, "escaped round trip")
end)

T.Test("Feedback: preparing needs a description and a problem type, and never claims it was sent", function()
	local FL = T.Boot()
	FL.FeedbackCenter:OpenForStep()
	Center().prepareButton.scripts.OnClick()
	T.True(Center().status.text:find("Describe what happened", 1, true), "description required")
	T.Equal(Center().output.box.fixedText, false, "no report")
	Type(Center().inputs.description, "Something is off.")
	Center().prepareButton.scripts.OnClick()
	T.True(Center().status.text:find("Pick what is wrong", 1, true), "category required")
	Center().categoryButton.scripts.OnClick()
	T.Equal(FL.Feedback.GetCurrentDraft().category, "waypoint", "first category chosen")
	Center().prepareButton.scripts.OnClick()
	local status = Center().status.text
	T.True(status:find("not sent", 1, true), "says it was not sent")
	T.True(status:find("pathwise.nn@gmail.com", 1, true), "where to send it")
	for _, phrase in ipairs({ "has been sent", "was sent", "Report sent", "submitted" }) do
		T.True(not status:find(phrase, 1, true), "never claims: " .. phrase)
	end
	T.True(Center().output.box.text:find("PATHWISE - GUIDE STEP REPORT", 1, true), "copyable report shown")
end)

T.Test("Feedback: works in all three window styles", function()
	local FL = T.Boot()
	FL.FeedbackCenter:OpenForStep()
	local edges = {
		classic = [[Interface\DialogFrame\UI-DialogBox-Border]],
		tooltip = [[Interface\Tooltips\UI-Tooltip-Border]],
		minimal = [[Interface\Buttons\WHITE8X8]],
	}
	for _, style in ipairs({ "tooltip", "minimal", "classic" }) do
		FL.HandleSlash("style " .. style)
		T.Equal(Center().backdrop.edgeFile, edges[style], "feedback window follows " .. style)
		T.True(Guide().reportButton.shown, "report button shown in " .. style)
	end
end)

T.Test("Feedback: /pathwise feedback and /fl feedback open the same Feedback Center", function()
	local FL = T.Boot()
	FL.HandleSlash("feedback")
	T.True(FL.FeedbackCenter:IsShown(), "opened")
	T.Equal(FL.Feedback.GetCurrentDraft().type, "bug", "general report")
	FL.FeedbackCenter:Hide()
	_G.SlashCmdList.FOREVERLEVELS("feedback")
	T.True(FL.FeedbackCenter:IsShown(), "/fl feedback works")
	local count = 0
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, "typeButton") then count = count + 1 end
	end
	T.Equal(count, 1, "one Feedback Center")
end)

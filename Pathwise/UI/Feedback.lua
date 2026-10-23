-- Pathwise Feedback Center: one panel for reports about a guide step, bug
-- reports and suggestions (Core/Feedback.lua builds them). It opens from the
-- flag in the guide window's footer (with this step filled in), /pw report,
-- /pw feedback, the minimap button's menu, a key binding and Settings.
-- Pathwise prepares the text; the player copies it into Pathwise's Discord
-- or an email. Nothing is sent from the game, and the panel says so.
--
-- What is typed is saved to the draft as it is typed: a draft per guide step
-- and one general draft survive a reload until discarded.

local ADDON, ns = ...
local Panels, F = ns.Panels, ns.Feedback
local FB = {}
ns.FeedbackCenter = FB

local INPUTS = {
	{ field = "description", label = "What happened? (required)", lines = 4 },
	{ field = "correctCoords", label = "Correct coordinates (optional)", lines = 1, types = { step = true } },
	{ field = "correctNpc", label = "Correct NPC name (optional)", lines = 1, types = { step = true } },
	{ field = "replacement", label = "Suggested instructions (optional)", lines = 2, types = { step = true } },
	{ field = "repro", label = "Steps to reproduce (optional)", lines = 3, types = { bug = true } },
}

local status, output -- the last message, and the prepared report
local choosing = false -- the list of step problems is open
local loadedKey -- the draft whose text the boxes hold

local function key(field) return "feedback." .. field end

local function load(draft, k)
	for _, i in ipairs(INPUTS) do Panels.SetInput(key(i.field), draft[i.field] or "") end
	status, output, choosing, loadedKey = nil, nil, false, k
end

-- Opens the draft for a step context, or the general draft (context nil).
function FB.Open(context)
	local draft, k = F.OpenDraft(context)
	load(draft, k)
	if Panels.IsOpen("feedback") then Panels.Refresh() else Panels.Open("feedback") end
end

-- A report about the step the guide shows; a general report without one.
function FB.OpenForStep()
	local context = F.CollectStepContext()
	if not context then ns.Print("no guide step is shown, so this is a general report.") end
	FB.Open(context)
end

function FB.IsShown() return Panels.IsOpen("feedback") end

-- -> the report text, or nil (the panel says what is missing).
function FB.Prepare()
	local text, problem = F.Prepare()
	if text then
		status, output = ("Report ready, not sent. Copy it and send it to %s."):format(F.SendTo()), text
	else
		status, output = problem, nil
	end
	Panels.Refresh()
	return text
end

local function changed() output, status = nil, nil end

Panels.Define("feedback", function()
	local draft, k = F.CurrentDraft()
	if not draft then draft, k = F.OpenDraft(F.CollectStepContext()) end
	if loadedKey ~= k then load(draft, k) end
	local rows = {
		{ "heading", draft.type == "step" and "Report this step" or "Feedback" },
		{ "text", "Pathwise prepares the report and you send it. Nothing leaves the game on its own.", "muted" },
	}

	local types = {}
	for _, t in ipairs(F.TYPES) do
		if t.key ~= "step" or draft.context then
			types[#types + 1] = { t.label, function() F.SetField("type", t.key) changed() Panels.Refresh() end,
				draft.type == t.key and "accent" or "default" }
		end
	end
	rows[#rows + 1] = { "setting", "Type", "", types }

	if draft.type == "step" then
		if draft.category and not choosing then
			rows[#rows + 1] = { "setting", F.Label(F.STEP_CATEGORIES, draft.category), "",
				{ { "Change", function() choosing = true Panels.Refresh() end } } }
		else
			rows[#rows + 1] = { "heading", "What is wrong with this step?" }
			for _, c in ipairs(F.STEP_CATEGORIES) do
				rows[#rows + 1] = { "choice", c.label, draft.category == c.key and "Selected" or nil, function()
					F.SetField("category", c.key)
					choosing = false
					changed()
					Panels.Refresh()
				end }
			end
		end
	end

	for _, i in ipairs(INPUTS) do
		if not i.types or i.types[draft.type] then
			rows[#rows + 1] = { "heading", i.label }
			rows[#rows + 1] = { "input", key(i.field), i.lines, function(text) F.SetField(i.field, text) changed() end }
			if i.field == "correctCoords" then
				rows[#rows + 1] = { "buttons", { { "Use my position", "default", function()
					local C = ns.Compat
					local map, x, y = C.PlayerMapPosition()
					if not map then
						ns.Print("no map position here (inside an instance?).")
						return
					end
					local text = ("%.1f, %.1f %s"):format(x, y, C.MapName(map) or ("map " .. map))
					Panels.SetInput(key("correctCoords"), text)
					F.SetField("correctCoords", text)
					changed()
					Panels.Refresh()
				end } } }
			end
		end
	end

	local function flip(field)
		return function() F.SetField(field, not draft[field]) changed() Panels.Refresh() end
	end
	rows[#rows + 1] = { "heading", "Information in this report" }
	rows[#rows + 1] = { "setting", "Character details", draft.includeCharacter and "Included" or "Not included",
		{ { draft.includeCharacter and "Leave out" or "Include", flip("includeCharacter") } } }
	rows[#rows + 1] = { "setting", "Diagnostics", draft.includeDiagnostics and "Included" or "Not included",
		{ { draft.includeDiagnostics and "Leave out" or "Include", flip("includeDiagnostics") } } }
	for _, line in ipairs(F.PreviewLines(draft)) do rows[#rows + 1] = { "text", line, "muted" } end
	if status then rows[#rows + 1] = { "text", status, output and "success" or "warning" } end
	rows[#rows + 1] = { "buttons", {
		{ "Discard draft", "default", function()
			F.DiscardCurrent()
			loadedKey = nil
			Panels.Close()
			ns.Print("draft discarded.")
		end },
		{ "Prepare report", "accent", FB.Prepare },
	} }

	if output then
		local n = 1
		for _ in output:gmatch("\n") do n = n + 1 end
		rows[#rows + 1] = { "heading", "Report ready, not sent" }
		rows[#rows + 1] = { "text", "Click the box, press Ctrl+C, then paste it into Pathwise's Discord or an email." }
		rows[#rows + 1] = { "copy", output, math.min(16, n) }
		rows[#rows + 1] = { "heading", "Pathwise's Discord" }
		rows[#rows + 1] = { "copy", F.DISCORD, 1 }
		rows[#rows + 1] = { "heading", "Email" }
		rows[#rows + 1] = { "copy", F.EMAIL, 1 }
	end
	rows[#rows + 1] = { "buttons", { { "Close", "default", Panels.Close } } }
	return rows
end)

ns.On("REPORT_STEP", function() FB.OpenForStep() end)
ns.On("SHOW_FEEDBACK", function() FB.Open(nil) end)
ns.Command("feedback", function() FB.Open(nil) end, "report a bug or make a suggestion")
ns.Command("bug", function() FB.Open(nil) end, "same as /pw feedback")

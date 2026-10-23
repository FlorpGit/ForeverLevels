-- Pathwise feedback: bug reports, suggestions and reports about a guide step.
--
-- Reports are prepared in game and copied by the player, who pastes them into
-- Pathwise's Discord or an email. Pathwise never sends anything: an addon
-- cannot send email or make web requests, and it must never hold
-- credentials. A report is built as a table (Feedback.Build) and rendered as
-- text (Feedback.Format) ending in a one-line key=value block, so a future
-- feedback portal can read the same data. See docs/FEEDBACK_SYSTEM.md.
--
-- Collecting a report only reads the guide. It never changes the route, the
-- step or quest progress. Character details and diagnostics are only added
-- when the player turns them on; the preview shows what is and is not in.

local ADDON, ns = ...
local C = ns.Compat
local Feedback = {}
ns.Feedback = Feedback

Feedback.EMAIL = "pathwise.nn@gmail.com"
Feedback.DISCORD = "https://discord.gg/hSDjBrG8EK"
Feedback.FORMAT_VERSION = 2 -- 2: steps by number (routes have no step ids), goals with their status
Feedback.MAX_DRAFTS = 20

Feedback.TYPES = {
	{ key = "step", label = "Guide step" },
	{ key = "bug", label = "Bug" },
	{ key = "suggestion", label = "Suggestion" },
}

Feedback.STEP_CATEGORIES = {
	{ key = "waypoint", label = "Incorrect waypoint or coordinates" },
	{ key = "npc_location", label = "Wrong NPC location" },
	{ key = "quest_missing", label = "Quest missing or unavailable" },
	{ key = "objectives", label = "Quest objectives are incorrect" },
	{ key = "no_advance", label = "Quest does not complete or advance" },
	{ key = "requirements", label = "Incorrect class or race requirements" },
	{ key = "profession", label = "Incorrect profession instructions" },
	{ key = "missing_step", label = "Missing quest or leveling step" },
	{ key = "other", label = "Other issue" },
}

Feedback.TEXT_FIELDS = { "description", "correctCoords", "correctNpc", "replacement", "repro" }

local QUEST_VERBS = { accept = "accept", complete = "complete", turnin = "turn in" }

function Feedback.Label(list, key)
	for _, entry in ipairs(list) do
		if entry.key == key then return entry.label end
	end
end
local label = Feedback.Label

local function zone()
	local map = C.PlayerMapPosition()
	return map and C.MapName(map) or nil
end

---------------------------------------------------------------------------
-- What a report is about
---------------------------------------------------------------------------

local function goalLog(q)
	local Q = ns.Quests
	local parts = { Q.OnQuest(q) and "on quest" or "not in log" }
	if Q.Done(q) then parts[#parts + 1] = "done" end
	if Q.OnQuest(q) and Q.Ready(q) then parts[#parts + 1] = "ready" end
	for _, o in ipairs(Q.Objectives(q) or {}) do
		parts[#parts + 1] = ("%s %s/%s"):format(o.text, tostring(o.have), tostring(o.need))
	end
	return table.concat(parts, ", ")
end

-- The step the guide shows, or nil without a route or step: route, step
-- number, title, instructions, its goals (quest ids with their status) and
-- where it leads.
function Feedback.CollectStepContext()
	local E, Q = ns.Engine, ns.Quests
	local route, s = E.Route(), E.CurrentStep()
	if not (route and s) then return nil end
	local player = Q.Player()
	local goals, quests = {}, {}
	for g, goal in ipairs(route.steps[s]) do
		if not (goal.only and not E.Fits(goal.only, player)) then
			local verb = goal[1]
			local entry = { verb = verb, status = E.GoalStatus(route, s, g, goal), text = E.GoalText(goal) }
			if QUEST_VERBS[verb] then
				entry.quest, entry.name, entry.log = goal[2], goal.name or Q.Name(goal[2]), goalLog(goal[2])
				quests[#quests + 1] = { id = goal[2], kind = verb, name = entry.name }
			end
			goals[#goals + 1] = entry
		end
	end
	local place = E.StepPlace()
	local extra = E.Extra()
	return {
		routeId = route.id, routeTitle = route.title,
		stepIndex = s, stepCount = #route.steps, liveStep = E.LiveStep(),
		stepTitle = E.StepTitle(route, s) or "", stepText = E.StepText(route, s) or "",
		goals = goals, quests = quests,
		waypoint = place and { map = place.map, x = place.x, y = place.y, zone = C.MapName(place.map), name = place.name } or nil,
		extra = extra and { quest = extra.quest, verb = extra.verb, name = Q.Name(extra.quest) } or nil,
	}
end

local RACE_NAMES = { Scourge = "Undead", NightElf = "Night Elf" }

-- Character details: only in a report when the player turns them on.
function Feedback.CollectCharacter()
	local p = ns.Quests.Player()
	local class = tostring(p.class or "?")
	class = class:sub(1, 1) .. class:sub(2):lower()
	return { level = p.level or 0, class = class, race = RACE_NAMES[p.race] or tostring(p.race), faction = tostring(p.faction) }
end

-- Diagnostics: only in a report when the player turns them on.
function Feedback.CollectDiagnostics()
	local version, build = "?", "?"
	if GetBuildInfo then version, build = GetBuildInfo() end
	local map, x, y = C.PlayerMapPosition()
	local t = ns.Nav.Target()
	local auto = {}
	for _, k in ipairs({ "accept", "turnin", "gossip" }) do if ns.Get("auto." .. k) then auto[#auto + 1] = k end end
	local detour = ns.Detours and ns.Detours.Active and ns.Detours.Active()
	return {
		gameVersion = version, build = build, forever = C.IsForeverClient(),
		position = map and ("%.1f, %.1f map %d (%s)"):format(x, y, map, tostring(C.MapName(map))) or "unavailable",
		arrowTarget = t and ("%.1f, %.1f map %d (%s)"):format(t.x, t.y, t.map, tostring(t.title)) or "none",
		detour = detour and detour.id or "none",
		style = ns.Get("ui.style") or "modern",
		automation = #auto > 0 and table.concat(auto, " ") or "off",
		data = ns.Quests.Data.SOURCE,
	}
end

---------------------------------------------------------------------------
-- Drafts: account-wide, one per guide step plus one general draft
---------------------------------------------------------------------------

local function store()
	local s = ns.Get("feedback.drafts")
	if type(s) ~= "table" then
		s = {}
		ns.Set("feedback.drafts", s)
	end
	return s
end

function Feedback.DraftKey(context)
	if context then return ("step:%s:%d"):format(context.routeId, context.stepIndex) end
	return "general"
end

local function prune(drafts)
	local keys = {}
	for key in pairs(drafts) do keys[#keys + 1] = key end
	if #keys <= Feedback.MAX_DRAFTS then return end
	table.sort(keys, function(a, b) return (drafts[a].updated or 0) < (drafts[b].updated or 0) end)
	for i = 1, #keys - Feedback.MAX_DRAFTS do drafts[keys[i]] = nil end
end

local function now() return time and time() or 0 end

-- Opens (or starts) the draft for a step, or the general draft.
function Feedback.OpenDraft(context)
	local drafts = store()
	local key = Feedback.DraftKey(context)
	local draft = drafts[key]
	if not draft then
		draft = { type = context and "step" or "bug", includeCharacter = false, includeDiagnostics = false }
		for _, field in ipairs(Feedback.TEXT_FIELDS) do draft[field] = "" end
		drafts[key] = draft
	end
	if context then draft.context = context end -- the step as it is now
	draft.updated = now()
	ns.Set("feedback.current", key)
	prune(drafts)
	return draft, key
end

function Feedback.CurrentDraft()
	local key = ns.Get("feedback.current")
	return key and store()[key] or nil, key
end

function Feedback.SetField(field, value)
	local draft = Feedback.CurrentDraft()
	if not draft then return end
	draft[field] = value
	draft.updated = now()
	draft.prepared = nil
end

function Feedback.DiscardCurrent()
	local _, key = Feedback.CurrentDraft()
	if key then store()[key] = nil end
	ns.Set("feedback.current", nil)
end

---------------------------------------------------------------------------
-- Building and formatting
---------------------------------------------------------------------------

local function trim(text)
	return ((text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- -> report, or nil and what is missing.
function Feedback.Build(draft)
	if not draft then return nil, "Nothing to report yet." end
	if trim(draft.description) == "" then return nil, "Describe what happened before preparing the report." end
	local isStep = draft.type == "step"
	if isStep and not draft.category then return nil, "Pick what is wrong with this step." end
	if isStep and not draft.context then return nil, "This report has no guide step. Make it a bug report instead." end
	return {
		format = Feedback.FORMAT_VERSION,
		type = draft.type,
		typeLabel = label(Feedback.TYPES, draft.type) or draft.type,
		category = isStep and draft.category or nil,
		categoryLabel = isStep and label(Feedback.STEP_CATEGORIES, draft.category) or nil,
		description = trim(draft.description),
		corrections = {
			coordinates = trim(draft.correctCoords), npc = trim(draft.correctNpc),
			instructions = trim(draft.replacement), reproduction = trim(draft.repro),
		},
		step = isStep and draft.context or nil,
		addonVersion = ns.VERSION,
		zone = zone(),
		character = draft.includeCharacter and Feedback.CollectCharacter() or nil,
		diagnostics = draft.includeDiagnostics and Feedback.CollectDiagnostics() or nil,
	}
end

local function questList(quests)
	if not quests or #quests == 0 then return "none for this step" end
	local parts = {}
	for _, q in ipairs(quests) do parts[#parts + 1] = ("%d (%s: %s)"):format(q.id, QUEST_VERBS[q.kind] or q.kind, q.name) end
	return table.concat(parts, ", ")
end

local function waypointText(w)
	if not w then return "none for this step" end
	return ("%.1f, %.1f %s (map %d)%s"):format(w.x, w.y, tostring(w.zone or "?"), w.map, w.name and (", " .. w.name) or "")
end

-- The key=value block for a future portal: split on "; " and "=".
-- Inside values \n, \e and \s stand for a newline, "=" and ";", and \\ for "\".
local function escape(value)
	return (tostring(value):gsub("\\", "\\\\"):gsub(";", "\\s"):gsub("=", "\\e"):gsub("\r?\n", "\\n"))
end

function Feedback.ToKeyValue(report)
	local list = {
		{ "format", report.format }, { "type", report.type }, { "category", report.category },
		{ "addon", report.addonVersion }, { "zone", report.zone },
	}
	local step = report.step
	if step then
		local ids = {}
		for _, q in ipairs(step.quests) do ids[#ids + 1] = q.id end
		list[#list + 1] = { "route", step.routeId }
		list[#list + 1] = { "step", step.stepIndex }
		list[#list + 1] = { "live", step.liveStep }
		list[#list + 1] = { "quests", table.concat(ids, ",") }
		if step.waypoint then
			list[#list + 1] = { "waypoint", ("%.1f,%.1f"):format(step.waypoint.x, step.waypoint.y) }
			list[#list + 1] = { "map", step.waypoint.map }
		end
	end
	local parts = {}
	for _, pair in ipairs(list) do
		if pair[2] ~= nil and pair[2] ~= "" then parts[#parts + 1] = pair[1] .. "=" .. escape(pair[2]) end
	end
	return table.concat(parts, "; ")
end

local UNESCAPE = { n = "\n", e = "=", s = ";", ["\\"] = "\\" }

function Feedback.ParseKeyValue(line)
	local out = {}
	for part in (line .. "; "):gmatch("(.-); ") do
		local key, value = part:match("^(%w+)=(.*)$")
		if key then out[key] = (value:gsub("\\(.)", UNESCAPE)) end
	end
	return out
end

local TITLES = { step = "GUIDE STEP REPORT", bug = "BUG REPORT", suggestion = "SUGGESTION" }

function Feedback.SendTo()
	return ("Pathwise's Discord (%s) or %s"):format(Feedback.DISCORD, Feedback.EMAIL)
end

function Feedback.Format(report)
	local out = {}
	local function w(line) out[#out + 1] = line end
	w("PATHWISE - " .. (TITLES[report.type] or "REPORT"))
	w("")
	w("Report type: " .. report.typeLabel .. (report.categoryLabel and (" - " .. report.categoryLabel) or ""))
	local step = report.step
	if step then
		w(("Route: %s (%s)"):format(step.routeTitle, step.routeId))
		w(("Step: %d/%d (first open step: %s)"):format(step.stepIndex, step.stepCount, tostring(step.liveStep or "none")))
		w("Step title: " .. step.stepTitle)
		w("Instructions: " .. (step.stepText ~= "" and step.stepText:gsub("\n", " ") or "none"))
		w("Quest IDs: " .. questList(step.quests))
		w("Waypoint: " .. waypointText(step.waypoint))
		w("Goals:")
		for i, g in ipairs(step.goals) do
			local what = g.quest and ("%s %d %s"):format(g.verb, g.quest, g.name) or tostring(g.text)
			w(("  %d. %s: %s%s"):format(i, g.status, what, g.log and ("  [log: " .. g.log .. "]") or ""))
		end
		if step.extra then w(("Extra quest: %d %s (%s)"):format(step.extra.quest, step.extra.name, step.extra.verb)) end
	end
	w("Zone: " .. (report.zone or "unknown"))
	w("Addon version: Pathwise " .. tostring(report.addonVersion))
	w("")
	w("Player description:")
	w(report.description)
	local c = report.corrections
	for _, entry in ipairs({
		{ c.coordinates, "Correct coordinates" }, { c.npc, "Correct NPC name" },
		{ c.instructions, "Suggested instructions" }, { c.reproduction, "Steps to reproduce" },
	}) do
		if entry[1] ~= "" then
			w("")
			w(entry[2] .. ":")
			w(entry[1])
		end
	end
	w("")
	if report.character then
		local ch = report.character
		w(("Character: level %d %s %s, %s"):format(ch.level, ch.race, ch.class, ch.faction))
	else
		w("Character: not included")
	end
	if report.diagnostics then
		local d = report.diagnostics
		w("Diagnostics:")
		w("  Game: " .. tostring(d.gameVersion) .. " build " .. tostring(d.build) .. (d.forever and " (Forever)" or " (not Forever)"))
		w("  Position: " .. d.position)
		w("  Arrow target: " .. d.arrowTarget)
		w("  Active detour: " .. d.detour)
		w("  Look: " .. tostring(d.style) .. ", auto quests: " .. d.automation)
		w("  Data: " .. tostring(d.data))
	else
		w("Diagnostics: not included")
	end
	w("")
	w(("Report data (format %d): %s"):format(report.format, Feedback.ToKeyValue(report)))
	w("")
	w("Send to: " .. Feedback.SendTo())
	return table.concat(out, "\n")
end

-- What a report would hold, read-only, saying what is and is not included.
function Feedback.PreviewLines(draft)
	local lines = {}
	local step = draft and draft.type == "step" and draft.context
	if step then
		lines[#lines + 1] = ("Route: %s, step %d/%d"):format(step.routeTitle, step.stepIndex, step.stepCount)
		lines[#lines + 1] = "Step: " .. step.stepTitle
		lines[#lines + 1] = "Quest IDs: " .. questList(step.quests)
		lines[#lines + 1] = "Waypoint: " .. waypointText(step.waypoint)
	end
	lines[#lines + 1] = ("Zone: %s  ·  Pathwise %s"):format(zone() or "unknown", tostring(ns.VERSION))
	local ch = Feedback.CollectCharacter()
	lines[#lines + 1] = ("Character (%s): level %d %s %s, %s"):format(draft and draft.includeCharacter and "included" or "not included",
		ch.level, ch.race, ch.class, ch.faction)
	local d = Feedback.CollectDiagnostics()
	lines[#lines + 1] = ("Diagnostics (%s): build %s, position %s, arrow %s"):format(
		draft and draft.includeDiagnostics and "included" or "not included", tostring(d.build), d.position, d.arrowTarget)
	return lines
end

-- Builds and formats the current draft. -> text, report; or nil, what is missing.
function Feedback.Prepare()
	local draft = Feedback.CurrentDraft()
	local report, problem = Feedback.Build(draft)
	if not report then return nil, problem end
	draft.prepared = now()
	return Feedback.Format(report), report
end

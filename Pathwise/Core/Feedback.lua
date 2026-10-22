-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: feedback reports (bug reports, suggestions, guide step reports).
--
-- Reports are prepared in game and copied by the player. Pathwise never sends
-- anything: an addon cannot send email or make web requests, and it must never hold
-- credentials. Each report is built as a structured table (Feedback.Build) and then
-- rendered as text (Feedback.Format) with a one-line key=value block, so a future
-- Pathwise feedback portal can accept the same data. See docs/FEEDBACK_SYSTEM.md.
--
-- Collecting a report only reads guide state. It never changes the route, the step,
-- or quest progress.

local _, FL = ...

local Feedback = {}
FL.Feedback = Feedback

Feedback.EMAIL = "pathwise.nn@gmail.com"
Feedback.FORMAT_VERSION = 1
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
	{ key = "no_advance", label = "Quest does not auto-complete or advance" },
	{ key = "requirements", label = "Incorrect class or race requirements" },
	{ key = "profession", label = "Incorrect profession instructions" },
	{ key = "missing_step", label = "Missing quest or leveling step" },
	{ key = "other", label = "Other issue" },
}

Feedback.TEXT_FIELDS = { "description", "correctCoords", "correctNpc", "replacement", "repro" }

local function Label(list, key)
	for _, entry in ipairs(list) do
		if entry.key == key then return entry.label end
	end
end
Feedback.Label = Label

local GOAL_WORDS = { accept = "accept", complete = "complete", turnin = "turn in" }

local function CurrentZone()
	local mapID = C_Map.GetBestMapForUnit("player")
	local info = mapID and C_Map.GetMapInfo(mapID)
	if info and info.name and not FL.IsSecret(info.name) then return info.name end
end

------------------------------------------------------------------------
-- Context
------------------------------------------------------------------------

-- Snapshot of the current guide step, or nil when no route or step is active.
-- Quest IDs are the step's goals that apply to this character.
function Feedback.CollectStepContext()
	local engine = FL.Engine
	local route, step = engine.route, engine:GetCurrentStep()
	if not route or not step then return nil end
	local player = FL.player
	local quests = {}
	for _, goal in ipairs((engine.GetGoals(step, player))) do
		if goal.questID then
			quests[#quests + 1] = { id = goal.questID, kind = goal.kind, name = FL.Quests.GetTitle(goal.questID, route) }
		end
	end
	local waypoint
	if step.x then
		waypoint = {
			x = step.x, y = step.y, zone = step.zone or route.zone,
			mapID = FL.Waypoint.ResolveMap(step, route),
		}
	end
	return {
		routeId = route.id, routeTitle = route.title, routeVersion = route.version,
		stepIndex = engine.index, stepCount = #route.steps,
		stepId = step.id, stepTitle = step.title, stepText = engine.GetStepText(step, player),
		quests = quests, waypoint = waypoint,
		verified = (step.verified or route.verified) and true or false,
	}
end

local RACE_NAMES = { Scourge = "Undead", NightElf = "Night Elf" }

-- Character details. Only added to a report when the player opts in.
function Feedback.CollectCharacter()
	local player = FL.player
	local class = player.class:sub(1, 1) .. player.class:sub(2):lower()
	return { level = player.level, class = class, race = RACE_NAMES[player.race] or player.race, faction = player.faction }
end

-- Technical details. Only added to a report when the player opts in.
function Feedback.CollectDiagnostics()
	local version, build = GetBuildInfo()
	local mapID, zone, x, y = FL.Recorder.GetPosition()
	local target = FL.Waypoint.target
	local active = FL.Detours and FL.Detours:GetActive()
	local profile = FL.db.profile
	return {
		gameVersion = version, build = build, forever = FL:IsForeverClient(),
		position = mapID and string.format("%s, %s map %d (%s)", x and string.format("%.1f", x) or "?",
			y and string.format("%.1f", y) or "?", mapID, tostring(zone)) or "unavailable",
		arrowTarget = target and string.format("%.1f, %.1f map %d (%s)", target.x, target.y, target.mapID, tostring(target.title)) or "none",
		detour = active and active.id or "none",
		style = profile.frame.style,
		automation = (profile.autoAccept and "accept " or "") .. (profile.autoTurnIn and "turn-in " or "") .. (profile.autoGossip and "gossip" or ""),
	}
end

------------------------------------------------------------------------
-- Drafts (saved account-wide; one per guide step plus one general draft)
------------------------------------------------------------------------

local function Store()
	return FL.db.feedback
end

function Feedback.DraftKey(context)
	if context then return "step:" .. context.routeId .. ":" .. context.stepId end
	return "general"
end

local function Prune(drafts)
	local keys = {}
	for key in pairs(drafts) do keys[#keys + 1] = key end
	if #keys <= Feedback.MAX_DRAFTS then return end
	table.sort(keys, function(a, b) return (drafts[a].updated or 0) < (drafts[b].updated or 0) end)
	for i = 1, #keys - Feedback.MAX_DRAFTS do drafts[keys[i]] = nil end
end

-- Opens (or creates) the draft for a step context, or the general draft.
function Feedback.OpenDraft(context)
	local store = Store()
	local key = Feedback.DraftKey(context)
	local draft = store.drafts[key]
	if not draft then
		draft = {
			type = context and "step" or "bug", category = nil,
			includeCharacter = false, includeDiagnostics = false,
		}
		for _, field in ipairs(Feedback.TEXT_FIELDS) do draft[field] = "" end
		store.drafts[key] = draft
	end
	if context then draft.context = context end   -- refresh the step snapshot
	draft.updated = time()
	store.current = key
	Prune(store.drafts)
	return draft, key
end

function Feedback.GetCurrentDraft()
	local store = Store()
	local key = store.current
	return key and store.drafts[key] or nil, key
end

function Feedback.SetField(field, value)
	local draft = Feedback.GetCurrentDraft()
	if not draft then return end
	draft[field] = value
	draft.updated = time()
	draft.prepared = nil
end

function Feedback.DiscardCurrent()
	local store = Store()
	if store.current then store.drafts[store.current] = nil end
	store.current = nil
end

------------------------------------------------------------------------
-- Building and formatting
------------------------------------------------------------------------

local function Trim(text)
	return ((text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Returns report, or nil and a message explaining what is missing.
function Feedback.Build(draft)
	if not draft then return nil, "Nothing to report yet." end
	if Trim(draft.description) == "" then
		return nil, "Describe what happened before preparing the report."
	end
	local isStep = draft.type == "step"
	if isStep and not draft.category then
		return nil, "Pick what is wrong with this step."
	end
	if isStep and not draft.context then
		return nil, "This report has no guide step. Use a bug report instead."
	end
	return {
		format = Feedback.FORMAT_VERSION,
		type = draft.type,
		typeLabel = Label(Feedback.TYPES, draft.type) or draft.type,
		category = isStep and draft.category or nil,
		categoryLabel = isStep and Label(Feedback.STEP_CATEGORIES, draft.category) or nil,
		description = Trim(draft.description),
		corrections = {
			coordinates = Trim(draft.correctCoords), npc = Trim(draft.correctNpc),
			instructions = Trim(draft.replacement), reproduction = Trim(draft.repro),
		},
		step = isStep and draft.context or nil,
		addonVersion = FL.version,
		zone = CurrentZone(),
		character = draft.includeCharacter and Feedback.CollectCharacter() or nil,
		diagnostics = draft.includeDiagnostics and Feedback.CollectDiagnostics() or nil,
		recipient = Feedback.EMAIL,
	}
end

local function QuestList(quests)
	if not quests or #quests == 0 then return "none for this step" end
	local parts = {}
	for _, quest in ipairs(quests) do
		parts[#parts + 1] = string.format("%d (%s: %s)", quest.id, GOAL_WORDS[quest.kind] or quest.kind, quest.name)
	end
	return table.concat(parts, ", ")
end

local function WaypointText(waypoint)
	if not waypoint then return "none for this step" end
	return string.format("%.1f, %.1f %s (map %s)", waypoint.x, waypoint.y, tostring(waypoint.zone or "?"),
		waypoint.mapID and tostring(waypoint.mapID) or "not resolved")
end

-- Single-line key=value block for a future portal. Values are escaped so the line
-- can be split on "; " and "=" again.
local function Escape(value)
	return (tostring(value):gsub("\\", "\\\\"):gsub(";", "\\s"):gsub("=", "\\e"):gsub("\r?\n", "\\n"))
end

function Feedback.ToKeyValue(report)
	local pairsList = {
		{ "format", report.format }, { "type", report.type }, { "category", report.category },
		{ "addon", report.addonVersion }, { "zone", report.zone },
	}
	local step = report.step
	if step then
		local ids = {}
		for _, quest in ipairs(step.quests) do ids[#ids + 1] = quest.id end
		pairsList[#pairsList + 1] = { "route", step.routeId }
		pairsList[#pairsList + 1] = { "routeVersion", step.routeVersion }
		pairsList[#pairsList + 1] = { "step", step.stepIndex }
		pairsList[#pairsList + 1] = { "stepId", step.stepId }
		pairsList[#pairsList + 1] = { "quests", table.concat(ids, ",") }
		pairsList[#pairsList + 1] = { "verified", step.verified and "yes" or "no" }
		if step.waypoint then
			pairsList[#pairsList + 1] = { "waypoint", string.format("%.1f,%.1f", step.waypoint.x, step.waypoint.y) }
			pairsList[#pairsList + 1] = { "map", step.waypoint.mapID }
		end
	end
	local parts = {}
	for _, pair in ipairs(pairsList) do
		if pair[2] ~= nil and pair[2] ~= "" then parts[#parts + 1] = pair[1] .. "=" .. Escape(pair[2]) end
	end
	return table.concat(parts, "; ")
end

local UNESCAPE = { n = "\n", e = "=", s = ";", ["\\"] = "\\" }

function Feedback.ParseKeyValue(line)
	local result = {}
	for part in (line .. "; "):gmatch("(.-); ") do
		local key, value = part:match("^([%w]+)=(.*)$")
		if key then
			result[key] = (value:gsub("\\(.)", UNESCAPE))
		end
	end
	return result
end

local TITLES = { step = "GUIDE STEP REPORT", bug = "BUG REPORT", suggestion = "SUGGESTION" }

function Feedback.Format(report)
	local out = {}
	local function W(line) out[#out + 1] = line end
	W("PATHWISE - " .. (TITLES[report.type] or "REPORT"))
	W("")
	W("Report type: " .. report.typeLabel .. (report.categoryLabel and (" - " .. report.categoryLabel) or ""))
	local step = report.step
	if step then
		W("Route: " .. step.routeTitle .. " (" .. step.routeId .. ")")
		W("Route version: " .. (step.routeVersion or "not set"))
		W(string.format("Step: %d/%d (%s)", step.stepIndex, step.stepCount, step.stepId))
		W("Step title: " .. step.stepTitle)
		W("Instructions: " .. (step.stepText ~= "" and step.stepText:gsub("\n", " ") or "none"))
		W("Quest IDs: " .. QuestList(step.quests))
		W("Waypoint: " .. WaypointText(step.waypoint))
		W("Step verification: " .. (step.verified and "Verified" or "Unverified"))
	end
	W("Zone: " .. (report.zone or "unknown"))
	W("Addon version: Pathwise " .. tostring(report.addonVersion))
	W("")
	W("Player description:")
	W(report.description)
	local c = report.corrections
	local labels = {
		{ c.coordinates, "Correct coordinates" }, { c.npc, "Correct NPC name" },
		{ c.instructions, "Suggested instructions" }, { c.reproduction, "Steps to reproduce" },
	}
	for _, entry in ipairs(labels) do
		if entry[1] ~= "" then
			W("")
			W(entry[2] .. ":")
			W(entry[1])
		end
	end
	W("")
	if report.character then
		local ch = report.character
		W(string.format("Character: level %d %s %s, %s", ch.level, ch.race, ch.class, ch.faction))
	else
		W("Character: not included")
	end
	if report.diagnostics then
		local d = report.diagnostics
		W("Diagnostics:")
		W("  Game: " .. tostring(d.gameVersion) .. " build " .. tostring(d.build) .. (d.forever and " (Forever)" or " (not Forever)"))
		W("  Position: " .. d.position)
		W("  Arrow target: " .. d.arrowTarget)
		W("  Active detour: " .. d.detour)
		W("  Window style: " .. tostring(d.style) .. ", automation: " .. (d.automation ~= "" and d.automation or "off"))
	else
		W("Diagnostics: not included")
	end
	W("")
	W("Report data (format " .. report.format .. "): " .. Feedback.ToKeyValue(report))
	W("")
	W("Send to: " .. report.recipient)
	return table.concat(out, "\n")
end

-- Read-only preview of what a report would contain, with what is and is not included.
function Feedback.PreviewLines(draft)
	local lines = {}
	local step = draft and draft.type == "step" and draft.context
	if step then
		lines[#lines + 1] = string.format("Route: %s, step %d/%d", step.routeTitle, step.stepIndex, step.stepCount)
		lines[#lines + 1] = "Step: " .. step.stepTitle .. (step.verified and " (verified)" or " (unverified)")
		lines[#lines + 1] = "Quest IDs: " .. QuestList(step.quests)
		lines[#lines + 1] = "Waypoint: " .. WaypointText(step.waypoint)
	end
	lines[#lines + 1] = "Zone: " .. (CurrentZone() or "unknown") .. "; Pathwise " .. tostring(FL.version)
	local ch = Feedback.CollectCharacter()
	lines[#lines + 1] = string.format("Character (%s): level %d %s %s, %s",
		draft and draft.includeCharacter and "included" or "not included", ch.level, ch.race, ch.class, ch.faction)
	local d = Feedback.CollectDiagnostics()
	lines[#lines + 1] = string.format("Diagnostics (%s): build %s, position %s, detour %s",
		draft and draft.includeDiagnostics and "included" or "not included", tostring(d.build), d.position, d.detour)
	return lines
end

-- Builds and formats the current draft. Returns text, or nil and a message.
function Feedback.Prepare()
	local draft = Feedback.GetCurrentDraft()
	local report, problem = Feedback.Build(draft)
	if not report then return nil, problem end
	draft.prepared = time()
	return Feedback.Format(report), report
end

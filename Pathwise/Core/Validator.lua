-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: route schema validation.
-- Pure Lua with no game API calls, so tools/validate_routes.lua can run it offline.
-- The schema is documented in docs/ROUTE_FORMAT.md.

local _, FL = ...

local Validator = {}
FL.Validator = Validator

Validator.CLASSES = {
	WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
	SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
}

-- UnitRace() file tokens known from the 2004 client. Forever adds a new race whose
-- token is not public yet, so unknown race tokens are a warning, not an error.
Validator.RACES = {
	Human = true, Dwarf = true, NightElf = true, Gnome = true,
	Orc = true, Scourge = true, Tauren = true, Troll = true,
}

Validator.FACTIONS = { Horde = true, Alliance = true }

Validator.GOAL_KINDS = { "accept", "complete", "turnin" }

local function IsQuestID(value)
	return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function CheckTokenList(list, known, label, where, errors, warnings)
	if list == nil then return end
	if type(list) ~= "table" then
		errors[#errors + 1] = where .. ": '" .. label .. "' must be a list"
		return
	end
	for _, token in ipairs(list) do
		if type(token) ~= "string" then
			errors[#errors + 1] = where .. ": '" .. label .. "' entries must be strings"
		elseif not known[token] then
			if label == "races" then
				warnings[#warnings + 1] = where .. ": unknown race token '" .. token .. "'"
			else
				errors[#errors + 1] = where .. ": unknown " .. label .. " token '" .. token .. "'"
			end
		end
	end
end

local function CheckGoalList(goals, kind, where, errors, warnings)
	if goals == nil then return 0 end
	if type(goals) ~= "table" then
		errors[#errors + 1] = where .. ": '" .. kind .. "' must be a list"
		return 0
	end
	for i, goal in ipairs(goals) do
		local goalWhere = where .. "." .. kind .. "[" .. i .. "]"
		if type(goal) == "table" then
			if not IsQuestID(goal[1]) then
				errors[#errors + 1] = goalWhere .. ": first entry must be a quest ID"
			end
			CheckTokenList(goal.class, Validator.CLASSES, "class", goalWhere, errors, warnings)
			CheckTokenList(goal.race, Validator.RACES, "races", goalWhere, errors, warnings)
		elseif not IsQuestID(goal) then
			errors[#errors + 1] = goalWhere .. ": must be a quest ID or { questID, class = {...}, race = {...} }"
		end
	end
	return #goals
end

local function CheckCoordinate(value, axis, where, errors)
	if value == nil then return end
	if type(value) ~= "number" or value < 0 or value > 100 then
		errors[#errors + 1] = where .. ": '" .. axis .. "' must be a number from 0 to 100"
	end
end

-- Returns ok, errors, warnings.
function Validator.ValidateRoute(route)
	local errors, warnings = {}, {}

	if type(route) ~= "table" then
		return false, { "route must be a table" }, warnings
	end

	local where = "route " .. tostring(route.id)

	if type(route.id) ~= "string" or not route.id:match("^[%w%._%-]+$") then
		errors[#errors + 1] = where .. ": 'id' must be a string of letters, digits, '.', '_' or '-'"
	end
	for _, field in ipairs({ "title", "author", "license" }) do
		if type(route[field]) ~= "string" or route[field] == "" then
			errors[#errors + 1] = where .. ": '" .. field .. "' is required"
		end
	end
	if route.faction ~= nil and not Validator.FACTIONS[route.faction] then
		errors[#errors + 1] = where .. ": 'faction' must be 'Horde' or 'Alliance'"
	end
	CheckTokenList(route.races, Validator.RACES, "races", where, errors, warnings)
	CheckTokenList(route.classes, Validator.CLASSES, "class", where, errors, warnings)

	local levels = route.levels
	if type(levels) ~= "table" or type(levels[1]) ~= "number" or type(levels[2]) ~= "number" or levels[1] > levels[2] then
		errors[#errors + 1] = where .. ": 'levels' must be { min, max }"
	end
	if route.apiVersion ~= nil and (type(route.apiVersion) ~= "number" or route.apiVersion > (FL.ROUTE_API_VERSION or 1)) then
		errors[#errors + 1] = where .. ": requires route API version " .. tostring(route.apiVersion)
	end
	if route.next ~= nil and type(route.next) ~= "string" then
		errors[#errors + 1] = where .. ": 'next' must be a route id string"
	end
	if route.quests ~= nil and type(route.quests) ~= "table" then
		errors[#errors + 1] = where .. ": 'quests' must be a table of [questID] = name"
	end

	if type(route.steps) ~= "table" or #route.steps == 0 then
		errors[#errors + 1] = where .. ": 'steps' must be a non-empty list"
		return #errors == 0, errors, warnings
	end

	local seen = {}
	for index, step in ipairs(route.steps) do
		local stepWhere = where .. " step " .. index
		if type(step) ~= "table" then
			errors[#errors + 1] = stepWhere .. ": must be a table"
		else
			if type(step.id) ~= "string" or step.id == "" then
				errors[#errors + 1] = stepWhere .. ": 'id' is required (keep it stable; saved progress uses it)"
			elseif seen[step.id] then
				errors[#errors + 1] = stepWhere .. ": duplicate step id '" .. step.id .. "'"
			else
				seen[step.id] = true
			end
			if type(step.title) ~= "string" then
				errors[#errors + 1] = stepWhere .. ": 'title' is required"
			end
			if step.text ~= nil and type(step.text) ~= "string" then
				errors[#errors + 1] = stepWhere .. ": 'text' must be a string"
			end
			if step.classText ~= nil then
				if type(step.classText) ~= "table" then
					errors[#errors + 1] = stepWhere .. ": 'classText' must be a table of [CLASS] = text"
				else
					for token in pairs(step.classText) do
						if not Validator.CLASSES[token] then
							errors[#errors + 1] = stepWhere .. ": unknown class token '" .. tostring(token) .. "' in classText"
						end
					end
				end
			end

			local goalCount = 0
			for _, kind in ipairs(Validator.GOAL_KINDS) do
				goalCount = goalCount + CheckGoalList(step[kind], kind, stepWhere, errors, warnings)
			end
			if step.level ~= nil then
				if type(step.level) ~= "number" or step.level < 1 then
					errors[#errors + 1] = stepWhere .. ": 'level' must be a positive number"
				else
					goalCount = goalCount + 1
				end
			end
			if goalCount == 0 then
				warnings[#warnings + 1] = stepWhere .. ": no goals; the player must press Next manually"
			end

			CheckTokenList(step.class, Validator.CLASSES, "class", stepWhere, errors, warnings)
			CheckTokenList(step.race, Validator.RACES, "races", stepWhere, errors, warnings)
			CheckCoordinate(step.x, "x", stepWhere, errors)
			CheckCoordinate(step.y, "y", stepWhere, errors)
			if (step.x == nil) ~= (step.y == nil) then
				errors[#errors + 1] = stepWhere .. ": 'x' and 'y' must be given together"
			end
			if step.x and not (step.map or step.zone or route.zone) then
				errors[#errors + 1] = stepWhere .. ": coordinates need 'zone' or 'map' (on the step or route)"
			end
			if step.map ~= nil and not IsQuestID(step.map) then
				errors[#errors + 1] = stepWhere .. ": 'map' must be a uiMapID number"
			end
		end
	end

	return #errors == 0, errors, warnings
end

return Validator

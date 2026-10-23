-- Pathwise guide engine: routes, the current step, what each goal's status is,
-- where the arrow points, skipping and alternatives.
--
-- A route lists actions; the facts (names, NPCs, places, objectives) come
-- from the data (Guide/Quests.lua), so a route never types in an id's name or
-- a coordinate. Progress is read from the quest log every time, never stored:
-- what is saved per character is only the route chosen, the quests skipped,
-- the extra quests picked as alternatives, and the step being looked at.
--
-- Route definition:
--   Pathwise.RegisterRoute({
--     id = "horde/undead/tirisfal", title = "Tirisfal Glades", map = 1420,
--     levels = { 1, 10 }, faction = "Horde", races = { 5 },  -- race IDs
--     next = "<route id>" or nil,
--     steps = {
--       { title = "...", note = "...", { "accept", 363 }, { "turnin", 363 }, ... },
--     },
--   })
-- Goals: { "accept", q }, { "turnin", q }, { "complete", q },
--        { "goto", map, x, y, "label" }, { "level", n }, { "note", "text" }

local ADDON, ns = ...
local Q = ns.Quests
local Engine = {}
ns.Engine = Engine
Pathwise.Engine = Engine

local routes, routeOrder = {}, {}
Engine.routes = routes

local GOTO_YARDS = 12

---------------------------------------------------------------------------
-- Routes
---------------------------------------------------------------------------

local VERBS = { accept = 2, turnin = 2, complete = 2, ["goto"] = 4, level = 2, note = 2 }

-- Problems found in a route: { "step 3: unknown verb 'x'", ... }.
function Engine.Check(def)
	local problems = {}
	if type(def) ~= "table" or type(def.id) ~= "string" or type(def.steps) ~= "table" then
		return { "a route needs an id and steps" }
	end
	for i, step in ipairs(def.steps) do
		if #step == 0 then problems[#problems + 1] = ("step %d: no goals"):format(i) end
		for _, g in ipairs(step) do
			local need = VERBS[g[1]]
			if not need then
				problems[#problems + 1] = ("step %d: unknown verb '%s'"):format(i, tostring(g[1]))
			elseif #g < need then
				problems[#problems + 1] = ("step %d: '%s' needs %d values"):format(i, g[1], need - 1)
			elseif (g[1] == "accept" or g[1] == "turnin" or g[1] == "complete") and not Q.Get(g[2]) then
				problems[#problems + 1] = ("step %d: quest %s is not in the data"):format(i, tostring(g[2]))
			end
		end
	end
	return problems
end

function Pathwise.RegisterRoute(def)
	local problems = Engine.Check(def)
	if #problems > 0 then
		ns.Error("route " .. tostring(def and def.id), table.concat(problems, "; "))
		return false
	end
	if not routes[def.id] then routeOrder[#routeOrder + 1] = def.id end
	routes[def.id] = def
	return true
end

function Engine.Routes()
	local out = {}
	for _, id in ipairs(routeOrder) do out[#out + 1] = routes[id] end
	return out
end

-- The routes made for this character, best first: their race, then faction.
function Engine.RoutesFor(p)
	p = p or Q.Player()
	local out = {}
	for _, id in ipairs(routeOrder) do
		local r = routes[id]
		local ok = not r.faction or r.faction == p.faction
		if ok and r.races then
			ok = false
			for _, race in ipairs(r.races) do if race == p.raceID then ok = true end end
		end
		if ok then out[#out + 1] = r end
	end
	return out
end

---------------------------------------------------------------------------
-- Per-character state
---------------------------------------------------------------------------

local function state()
	local c = ns.CharState()
	c.guide = type(c.guide) == "table" and c.guide or {}
	local g = c.guide
	g.skipped = type(g.skipped) == "table" and g.skipped or {}
	g.extras = type(g.extras) == "table" and g.extras or {}
	g.reached = type(g.reached) == "table" and g.reached or {}
	return g
end
Engine.State = state

function Engine.Route()
	local id = state().route
	return id and routes[id]
end

function Engine.SetRoute(id)
	if id and not routes[id] then return false end
	local s = state()
	s.route, s.pin = id, nil
	Engine.Update()
	return true
end

---------------------------------------------------------------------------
-- Goal status: "done", "open", "na" (not for this character, skipped or
-- closed), "wait" (an accept not offered yet: a prerequisite or the level;
-- it does not hold the route, which comes back to it once it opens),
-- "info" (a note: never blocks)
---------------------------------------------------------------------------

local player

local function skipped(q) return state().skipped[q] ~= nil end

local function questStatus(verb, q)
	if skipped(q) or not Q.ForPlayer(q, player) then return "na" end
	if verb == "accept" then
		if Q.OnQuest(q) or Q.Done(q) then return "done" end
		if Q.Closed(q) then return "na" end
		if not Q.PrereqsMet(q) or Q.MinLevel(q) > (player.level or 1) then return "wait" end
		return "open"
	elseif verb == "turnin" then
		if Q.Done(q) then return "done" end
		if not Q.OnQuest(q) then return "na" end -- never taken or abandoned: nothing to hand in
		return "open"
	else -- complete
		if Q.Done(q) or (Q.OnQuest(q) and Q.Ready(q)) then return "done" end
		if not Q.OnQuest(q) then return "na" end
		return "open"
	end
end

local function goalKey(route, s, g) return route.id .. ":" .. s .. ":" .. g end

local function goalStatus(route, s, g, goal)
	local verb = goal[1]
	if verb == "accept" or verb == "turnin" or verb == "complete" then return questStatus(verb, goal[2]) end
	if verb == "level" then return (player.level or 1) >= goal[2] and "done" or "open" end
	if verb == "goto" then return state().reached[goalKey(route, s, g)] and "done" or "open" end
	return "info"
end

local function stepOpen(route, s)
	local step = route.steps[s]
	for g, goal in ipairs(step) do
		if goalStatus(route, s, g, goal) == "open" then return true end
	end
	return false
end

-- Extra quests the player picked (alternatives): a virtual step each, ahead of
-- the route, until done. Returns the first open one: { quest, verb }.
local function openExtra()
	local s = state()
	local keep = {}
	local first
	for _, q in ipairs(s.extras) do
		if not Q.Done(q) and not skipped(q) and not Q.Closed(q) then
			keep[#keep + 1] = q
			if not first then
				local verb = not Q.OnQuest(q) and "accept" or (Q.Ready(q) and "turnin" or "complete")
				first = { quest = q, verb = verb }
			end
		end
	end
	s.extras = keep
	return first
end

---------------------------------------------------------------------------
-- The current step
---------------------------------------------------------------------------

local live, current, extra -- live: first open route step; current: shown; extra: open extra

local function compute()
	player = Q.Player()
	extra = openExtra()
	local route = Engine.Route()
	live = nil
	if route then
		for s = 1, #route.steps do
			if stepOpen(route, s) then live = s break end
		end
	end
	local pin = state().pin
	if pin and route and route.steps[pin] and pin ~= live then current = pin
	else
		state().pin = nil
		current = live
	end
end

function Engine.LiveStep() return live end
function Engine.CurrentStep() return current end
function Engine.Extra() return extra end

-- The player's map position, for nearest places.
local function here()
	local map, x, y = ns.Compat.PlayerMapPosition()
	return map and { map = map, x = x, y = y } or nil
end

-- Where a goal leads: { map, x, y, name } or nil.
local function placeOf(goal)
	local verb, q = goal[1], goal[2]
	local from = here()
	if verb == "accept" then return Q.Giver(q, from) end
	if verb == "turnin" then return Q.Finisher(q, from) end
	if verb == "complete" then
		local log = Q.Objectives(q)
		local n = Q.ObjectiveCount(q)
		for i = 1, n do
			if not (log and log[i] and log[i].done) then
				local p = Q.ObjectivePlace(q, i, from)
				if p then return p end
			end
		end
		return Q.ObjectivePlace(q, 1, from)
	end
	if verb == "goto" then return { map = goal[2], x = goal[3], y = goal[4], name = goal[5] } end
	return nil
end
Engine.PlaceOf = placeOf

-- The goal the arrow and the window lead with.
local function leadGoal()
	if extra then return { extra.verb, extra.quest } end
	local route = Engine.Route()
	if not (route and current) then return nil end
	for g, goal in ipairs(route.steps[current]) do
		if goalStatus(route, current, g, goal) == "open" and placeOf(goal) then return goal, g end
	end
	return nil
end

---------------------------------------------------------------------------
-- What the window shows
---------------------------------------------------------------------------

local VERB_TEXT = { accept = "Accept %s", turnin = "Turn in %s", complete = "Complete %s" }

local function goalText(goal)
	local verb = goal[1]
	if VERB_TEXT[verb] then return VERB_TEXT[verb]:format(Q.Name(goal[2])) end
	if verb == "goto" then return goal[5] or "Go to the marked spot" end
	if verb == "level" then return ("Reach level %d"):format(goal[2]) end
	return goal[2]
end

-- A step's headline: its own title, the quest being done, or who to see.
local function titleOf(step, route, s)
	if step.title then return step.title end
	for _, goal in ipairs(step) do
		if goal[1] == "complete" then return Q.Name(goal[2]) end
	end
	for g, goal in ipairs(step) do
		if goalStatus(route, s, g, goal) ~= "na" then
			local p = placeOf(goal)
			if p and p.name then return p.name end
		end
	end
	return goalText(step[1])
end

local function rowsOf(route, s)
	local rows = {}
	local step = route.steps[s]
	for g, goal in ipairs(step) do
		local st = goalStatus(route, s, g, goal)
		if st ~= "na" and st ~= "wait" and goal[1] ~= "note" then
			if goal[1] == "complete" and st == "open" then
				for _, o in ipairs(Q.Objectives(goal[2]) or {}) do
					rows[#rows + 1] = { text = o.text, have = o.have, need = o.need, done = o.done }
				end
			else
				rows[#rows + 1] = { text = goalText(goal), done = st == "done" }
			end
		end
	end
	return rows
end

local function textOf(step)
	if step.note then return step.note end
	for _, goal in ipairs(step) do
		if goal[1] == "complete" then return Q.Text(goal[2]) end
		if goal[1] == "note" then return goal[2] end
	end
	return nil
end

local function coordsOf(p)
	if not (p and p.x) then return nil end
	local zone = ns.Compat.MapName(p.map)
	local here_ = here()
	local xy = ("%.1f, %.1f"):format(p.x, p.y)
	if zone and not (here_ and here_.map == p.map) then xy = xy .. "  ·  " .. zone end
	return xy
end

local function progressOf(route)
	local done = 0
	for s = 1, #route.steps do if not stepOpen(route, s) then done = done + 1 end end
	return done / math.max(1, #route.steps)
end

local function nextSummary(route, from)
	for s = from + 1, #route.steps do
		if stepOpen(route, s) then
			local step = route.steps[s]
			for g, goal in ipairs(step) do
				if goalStatus(route, s, g, goal) == "open" then return goalText(goal) end
			end
		end
	end
	return nil
end

function Engine.View()
	local route = Engine.Route()
	if extra then
		local goal = { extra.verb, extra.quest }
		local p = placeOf(goal)
		local rows = {}
		if extra.verb == "complete" then
			for _, o in ipairs(Q.Objectives(extra.quest) or {}) do rows[#rows + 1] = { text = o.text, have = o.have, need = o.need, done = o.done } end
		else
			rows[1] = { text = goalText(goal) }
		end
		return {
			route = route and route.title or "Extra quest", extra = true,
			index = route and live or nil, count = route and #route.steps or nil,
			progress = route and progressOf(route) or 0,
			title = Q.Name(extra.quest),
			text = extra.verb == "complete" and Q.Text(extra.quest) or (p and p.name and ((extra.verb == "accept" and "From " or "To ") .. p.name)) or nil,
			coords = coordsOf(p), objectives = rows,
			next = route and live and ("Then back to the route: " .. (titleOf(route.steps[live], route, live) or "")) or nil,
		}
	end
	if not route then return nil end
	if not current then
		return {
			route = route.title, index = #route.steps, count = #route.steps, progress = 1,
			title = "Route complete",
			text = route.next and routes[route.next] and ("Next: " .. routes[route.next].title .. ". Pick it from Zones for your level.") or "Pick your next zone from Zones for your level.",
			objectives = {},
		}
	end
	local step = route.steps[current]
	local goal = leadGoal()
	local p = goal and placeOf(goal)
	return {
		route = route.title, index = current, count = #route.steps, progress = progressOf(route),
		title = titleOf(step, route, current), text = textOf(step), coords = coordsOf(p),
		objectives = rowsOf(route, current), next = nextSummary(route, current),
		pinned = current ~= live,
	}
end

---------------------------------------------------------------------------
-- Updating: the window and the arrow, after quest-log events
---------------------------------------------------------------------------

local lastWaypoint

local function updateWaypoint()
	local goal = leadGoal()
	local p = goal and placeOf(goal)
	local key = p and ("%d:%.2f:%.2f"):format(p.map, p.x, p.y) or nil
	if key == lastWaypoint then return end
	lastWaypoint = key
	if p then ns.Nav.SetTarget(p.map, p.x, p.y, p.name or goalText(goal)) else ns.Nav.Clear() end
end

function Engine.Update()
	compute()
	if ns.Guide and ns.Guide.SetView then ns.Guide.SetView(Engine.View()) end
	updateWaypoint()
	ns.Fire("GUIDE_UPDATED")
end

-- Quest-log events come in bursts: one update a moment after the last.
local pending = false
function Engine.Schedule()
	if pending then return end
	pending = true
	local function run() pending = false Engine.Update() end
	if C_Timer and C_Timer.After then C_Timer.After(0.2, run) else run() end
end

for _, ev in ipairs({ "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE", "PLAYER_LEVEL_UP", "ZONE_CHANGED_NEW_AREA" }) do
	ns.RegisterEvent(ev, Engine.Schedule)
end

-- "Go to" goals are reached by arriving: the arrow says so.
ns.On("WAYPOINT_ARRIVED", function()
	local route = Engine.Route()
	local goal, g = leadGoal()
	if route and goal and goal[1] == "goto" and current then
		state().reached[goalKey(route, current, g)] = true
		Engine.Schedule()
	end
end)

ns.On("READY", function()
	local s = state()
	if not s.route then
		local best = Engine.RoutesFor()[1]
		if best then s.route = best.id end
	end
	Engine.Update()
end)

---------------------------------------------------------------------------
-- Navigation (Back / Next look at other steps; they change nothing)
---------------------------------------------------------------------------

function Engine.Back()
	local route = Engine.Route()
	if not (route and current) then return end
	state().pin = math.max(1, current - 1)
	Engine.Update()
end

function Engine.Next()
	local route = Engine.Route()
	if not route then return end
	local to = (current or #route.steps) + 1
	if to > #route.steps then return end
	state().pin = to
	if to == live then state().pin = nil end
	Engine.Update()
end

function Engine.BackToLive()
	state().pin = nil
	Engine.Update()
end

---------------------------------------------------------------------------
-- Skipping and alternatives
---------------------------------------------------------------------------

-- The open quests of the step shown (what Skip offers).
function Engine.SkippableQuests()
	local out, seen = {}, {}
	if extra then return { extra.quest } end
	local route = Engine.Route()
	if not (route and current) then return out end
	for g, goal in ipairs(route.steps[current]) do
		local q = goal[2]
		if (goal[1] == "accept" or goal[1] == "turnin" or goal[1] == "complete") and not seen[q]
			and goalStatus(route, current, g, goal) == "open" then
			seen[q] = true
			out[#out + 1] = q
		end
	end
	return out
end

-- Skip quest q (and, with followUps, every quest that needs it, as far as
-- the data knows). Returns the quests skipped.
function Engine.SkipQuest(q, followUps)
	local s = state()
	local list = { q }
	s.skipped[q] = followUps and "chain" or true
	if followUps then
		local queue, seen = { q }, { [q] = true }
		local depth = 0
		while #queue > 0 and depth < 200 do
			depth = depth + 1
			for _, f in ipairs(Q.FollowUps(table.remove(queue, 1))) do
				if not seen[f] then
					seen[f] = true
					s.skipped[f] = "chain"
					list[#list + 1] = f
					queue[#queue + 1] = f
				end
			end
		end
	end
	Engine.Update()
	return list
end

function Engine.UnskipQuest(q)
	state().skipped[q] = nil
	Engine.Update()
end

function Engine.Skipped()
	local out = {}
	for q in pairs(state().skipped) do out[#out + 1] = q end
	table.sort(out)
	return out
end

-- Quests to do instead: for this character, at their level, available now
-- (prerequisites met, not closed), not already part of the route ahead,
-- given on the map the player is on; nearest giver first.
-- -> { { quest, name, level, giver, yards }, ... }
function Engine.Alternatives(limit)
	limit = limit or 5
	player = Q.Player()
	local from = here()
	if not from then return {} end
	local inRoute = {}
	local route = Engine.Route()
	if route then
		for s = live or 1, #route.steps do
			for _, goal in ipairs(route.steps[s]) do if goal[2] then inRoute[goal[2]] = true end end
		end
	end
	local _, pn, pw = ns.Compat.MapToWorld(from.map, from.x, from.y)
	local list = {}
	for id, q in pairs(Q.Data.quests) do
		local level, minLevel = q[2] or 0, q[3] or 0
		if level >= player.level - 2 and level <= player.level + 3 and minLevel <= player.level
			and not inRoute[id] and not q[16] and not skipped(id) and Q.ForPlayer(id, player) then
			local giver = Q.Giver(id, from)
			if giver and giver.map == from.map and not Q.Done(id) and not Q.OnQuest(id)
				and Q.PrereqsMet(id) and not Q.Closed(id) then
				local yards
				local _, gn, gw = ns.Compat.MapToWorld(giver.map, giver.x, giver.y)
				if pn and gn then yards = math.sqrt((gn - pn) ^ 2 + (gw - pw) ^ 2) end
				list[#list + 1] = { quest = id, name = Q.Name(id), level = level, giver = giver.name, yards = yards }
			end
		end
	end
	table.sort(list, function(a, b)
		if (a.yards or 1e9) ~= (b.yards or 1e9) then return (a.yards or 1e9) < (b.yards or 1e9) end
		return a.quest < b.quest
	end)
	while #list > limit do table.remove(list) end
	return list
end

function Engine.AddExtra(q)
	local s = state()
	for _, x in ipairs(s.extras) do if x == q then return end end
	s.extras[#s.extras + 1] = q
	s.skipped[q] = nil
	Engine.Update()
end

-- Zones for the player's level: { { map, name, low, high, route }, ... }.
function Engine.Zones()
	player = Q.Player()
	local out = {}
	local byMap = {}
	for _, r in ipairs(Engine.RoutesFor(player)) do byMap[r.map] = byMap[r.map] or r end
	for _, z in ipairs(Q.ZonesFor(player.level, player.faction)) do
		z.name = ns.Compat.MapName(z.map) or ("Map " .. z.map)
		z.route = byMap[z.map]
		out[#out + 1] = z
	end
	return out
end

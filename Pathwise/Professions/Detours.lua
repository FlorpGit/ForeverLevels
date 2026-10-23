-- Pathwise profession detours: the optional card under the guide's step, one
-- at a time. It never changes the leveling route, its steps, Back/Next or
-- quest progress: it only reads where the route is.
--
-- What it can show, first that applies:
--   1. the detour the player chose with Go, until it is done;
--   2. "train": the next rank of a profession can be trained now (level and
--      skill are there) at a trainer on the way;
--   3. "craft": the bags make the profession's next craft now (Planner.Next);
--   4. "side": the next step of the profession route followed beside the
--      leveling route (Settings > Routes), unless 2 or 3 is about it.
-- "On the way" is the detour mode (Settings > Profession detours): Speed
-- within about 150 yd, Balanced 600 yd, Crafting always, Off never. A
-- detour with nowhere to go (crafting) shows in every mode but Off.
--
-- Buttons, and their states (saved per character):
--   Go / Stop   the arrow leads to it (when it has a place) until it is done
--   Later       hidden until the leveling route moves on, then offered again
--   Skip (x)    hidden for good (that rank, that craft, that side step)
-- A train detour is done when the cap goes up, a craft detour when the
-- skill reaches its target or the materials run out; then the card moves on.
-- See docs/PROFESSION_DETOURS.md.

local ADDON, ns = ...
local C = ns.Compat
local D = {}
ns.Detours = D

ns.Defaults("professions", { detour = "balanced" }) -- "off" | "speed" | "balanced" | "craft"
D.YARDS = { speed = 150, balanced = 600 }

local function store()
	local c = ns.CharState()
	c.detours = type(c.detours) == "table" and c.detours or {}
	local d = c.detours
	d.states = type(d.states) == "table" and d.states or {} -- [id] = "done" | "skipped"
	d.postponed = type(d.postponed) == "table" and d.postponed or {} -- [id] = route place at "Later"
	return d
end

-- Where the leveling route is, for "Later".
local function routeKey()
	local E = ns.Engine
	local r = E.Route()
	return r and (r.id .. ":" .. tostring(E.LiveStep())) or "none"
end

---------------------------------------------------------------------------
-- Candidates
---------------------------------------------------------------------------

local function goTo(place) return { "goto", place.map, place.x, place.y, place.name } end

local function lineOfRoute(route)
	for _, step in ipairs(route.steps) do
		for _, g in ipairs(step) do
			if g[1] == "train" or g[1] == "skill" or g[1] == "craft" then return g[2] end
		end
	end
end

-- Every detour that could show now, before the mode and the player's
-- choices filter them: { id, kind, line, label, text, sub, place, goal, g, ... }.
local function candidates()
	local P, Pl, E = ns.Professions, ns.Planner, ns.Engine
	local out, lines = {}, {}
	for _, k in ipairs(P.Known()) do
		local prof = k.prof
		if P.Shown(prof) then
			local m = Pl.Milestone(prof)
			if m and m.ready and m.trainer then
				lines[prof.line] = true
				out[#out + 1] = {
					id = ("train:%d:%d"):format(prof.line, m.rankMax), kind = "train", line = prof.line, rankMax = m.rankMax,
					label = "Optional · " .. prof.name, text = ("Train %s %s"):format(m.rankName or "the next rank of", prof.name),
					place = m.trainer, goal = goTo(m.trainer), g = 0,
				}
			end
			local c = Pl.Next(prof)
			if c and (c.craftable or 0) > 0 and c.known ~= false then
				lines[prof.line] = true
				local n = math.min(c.craftable, math.max(1, c.planned or c.craftable))
				local sub = ("You can make %d now"):format(c.craftable)
				if c.expected and c.untilSkill then sub = sub .. ("  ·  about %d to reach %d"):format(math.ceil(c.expected), c.untilSkill) end
				out[#out + 1] = {
					id = ("craft:%d:%d:%d"):format(prof.line, c.spell, math.floor(k.rank / 10)), kind = "craft", line = prof.line,
					target = c.untilSkill or (k.rank + 1), spell = c.spell,
					label = "Optional · " .. prof.name, text = ("Craft %d %s"):format(n, c.name or "?"), sub = sub,
				}
			end
		end
	end
	local side = E.SideCard()
	if side and not lines[lineOfRoute(side.route) or 0] then
		out[#out + 1] = {
			id = ("side:%s:%d"):format(side.route.id, side.step), kind = "side",
			label = "Optional · " .. side.route.title, text = side.text, title = side.title,
			place = side.place, goal = side.goal, g = side.g,
		}
	end
	return out
end

local cache, shown -- this update's candidates, and the one the card shows

local function find(list, id)
	for _, c in ipairs(list) do if c.id == id then return c end end
end

-- Whether the player's choices allow a detour now.
local function allowed(c)
	local st = store()
	if st.states[c.id] then return false end
	local at = st.postponed[c.id]
	if at then
		if at == routeKey() then return false end
		st.postponed[c.id] = nil -- the route moved on: offer it again
	end
	return true
end

local function onTheWay(c, mode)
	if not c.place or mode == "craft" then return true end
	local yards = ns.Engine.YardsTo(c.place)
	return yards ~= nil and yards <= (D.YARDS[mode] or 0)
end

-- The active detour is gone from the candidates: done, or no longer for now.
local function finish(active)
	local st = store()
	st.active = nil
	local P = ns.Professions
	if active.kind == "train" then
		local _, cap = C.SkillRank(active.line)
		if cap and cap >= (active.rankMax or 0) then
			st.states[active.id] = "done"
			ns.Print("detour done: " .. active.text .. ".")
		end
	elseif active.kind == "craft" then
		local rank = C.SkillRank(active.line)
		local prof = P.BY_LINE[active.line]
		local c = prof and P.Shown(prof) and ns.Planner.Next(prof)
		if (rank and rank >= (active.target or 0)) or not (c and c.spell == active.spell and (c.craftable or 0) > 0) then
			st.states[active.id] = "done"
			ns.Print("detour done: " .. active.text .. ".")
		end
	end
end

-- The card the guide window shows, or nil: { label, text, sub, aimed, yards, id, kind }.
function D.Card()
	local mode = ns.Get("professions.detour")
	shown = nil
	if mode == "off" then
		cache = {}
		store().active = nil
		return nil
	end
	cache = candidates()
	local st = store()
	local c, aimed
	if st.active then
		c = find(cache, st.active.id)
		if c then aimed = true else finish(st.active) end
	end
	if not c then
		for _, kind in ipairs({ "train", "craft", "side" }) do
			for _, x in ipairs(cache) do
				if not c and x.kind == kind and allowed(x) and onTheWay(x, mode) then c = x end
			end
		end
	end
	if not c then return nil end
	shown = c
	local yards = c.place and ns.Engine.YardsTo(c.place)
	local sub
	if aimed then sub = c.place and "The arrow leads here now" or (c.sub or "Wherever you are")
	elseif c.sub then sub = c.sub
	elseif not c.place then sub = "Wherever you are"
	elseif yards then sub = ("%s  ·  %s"):format(c.place.name or c.title or "On your way", ns.Nav.FormatYards(yards))
	else sub = c.place.name or c.title end
	return { label = c.label, text = c.text, sub = sub, aimed = aimed, yards = yards, id = c.id, kind = c.kind }
end

-- The detour the arrow leads to (chosen with Go and with a place), or nil:
-- { goal, g, kind }.
function D.Aimed()
	local st = store()
	if not (st.active and cache) then return nil end
	local c = find(cache, st.active.id)
	if c and c.goal then return c end
	return nil
end

function D.Active() return store().active end

-- Detours skipped or postponed, and bringing them all back.
function D.SkippedCount()
	local n, st = 0, store()
	for _, state in pairs(st.states) do if state == "skipped" then n = n + 1 end end
	for _ in pairs(st.postponed) do n = n + 1 end
	return n
end
function D.Unskip()
	local st = store()
	for id, state in pairs(st.states) do if state == "skipped" then st.states[id] = nil end end
	st.postponed = {}
end

---------------------------------------------------------------------------
-- The buttons (and /pw detour)
---------------------------------------------------------------------------

local function update() ns.Engine.Update() end

-- Go on the card's detour, or Stop the one chosen. -> true when there was one
function D.Go()
	local st = store()
	if st.active then
		st.active = nil
	elseif shown then
		st.active = { id = shown.id, kind = shown.kind, line = shown.line, text = shown.text,
			rankMax = shown.rankMax, target = shown.target, spell = shown.spell }
	else
		return false
	end
	update()
	return true
end

local function settle(state)
	local st = store()
	local c = (st.active and st.active) or shown
	if not c then return false end
	if state == "later" then st.postponed[c.id] = routeKey() else st.states[c.id] = state end
	st.active = nil
	update()
	return true
end
function D.Later() return settle("later") end
function D.Skip() return settle("skipped") end
function D.Done() return settle("done") end

ns.On("DETOUR_GO", D.Go)
ns.On("DETOUR_LATER", D.Later)
ns.On("DETOUR_SKIP", D.Skip)

local MODES = { off = true, speed = true, balanced = true, craft = true }
local ACTIONS = { go = D.Go, stop = D.Go, later = D.Later, skip = D.Skip, done = D.Done }

ns.Command("detour", function(args)
	local a = (args or ""):lower():gsub("%s+", "")
	if a == "on" then a = ns.Get("professions.detour") == "off" and "balanced" or ns.Get("professions.detour") end
	if MODES[a] then
		ns.Set("professions.detour", a)
		update()
		ns.Print("profession detours: " .. a .. ".")
	elseif ACTIONS[a] then
		if not ACTIONS[a]() then ns.Print("no profession detour to " .. a .. ".") end
	else
		ns.Print("usage: /pw detour go | later | skip | done | on | off | speed | balanced | craft")
	end
end, "profession detours: /pw detour go | later | skip | done | on | off | speed | balanced | craft")

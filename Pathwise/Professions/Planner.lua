-- Pathwise profession planner: the numbers behind a profession's next step.
-- The profession route is the plan (Professions.NextCraft, Stage, Shopping);
-- the planner works out how sure a skill-up is, how many crafts a skill
-- range takes, which materials those crafts use (with intermediates, and
-- with materials already promised to earlier crafts held back), the next
-- rank to train, and recipes to learn. With no open craft in the route it
-- recommends one from the recipes Pathwise knows (Recipes.lua). Read-only:
-- it never crafts, buys, sells or disenchants.
--
-- Skill-up chance, in order of preference:
--   1. "client"     the colour the profession window showed at this skill
--   2. "thresholds" a pack's { orange, yellow, green, grey } skill levels and
--                   the usual estimate chance = (grey - skill) / (grey - yellow);
--                   "thresholds-unverified" when those levels are a fallback
--   3. "client-stale" the colour the window showed at a lower skill (rough)
--   4. "unknown"    nothing known: a few crafts, then look again
-- Every result carries its basis so the dashboard says how sure it is.
-- See docs/MATERIAL_PLANNER.md.

local ADDON, ns = ...
local C = ns.Compat
local Pl = {}
ns.Planner = Pl

Pl.COLORS = { [0] = "orange", [1] = "yellow", [2] = "green", [3] = "grey" }
-- Rough chances by colour, only when no skill levels are known.
Pl.CLIENT_CHANCE = { [0] = 1, [1] = 0.75, [2] = 0.25, [3] = 0 }
Pl.UNKNOWN_BATCH = 5 -- crafts to suggest when the chance is unknown
Pl.STOP_CHANCE = 0.5 -- move on once a recipe drops below this chance
Pl.MAX_STEP = 10 -- plan at most this many skill points per recommendation

-- Each rank's cap, its name and what training it asks: character level and
-- skill, as the profession routes' notes give them (Polestar: "Journeyman
-- needs character level 10 and Alchemy 50").
Pl.RANKS = {
	[75] = { name = "Apprentice", level = 1, skill = 0 },
	[150] = { name = "Journeyman", level = 10, skill = 50 },
	[225] = { name = "Expert", level = 20, skill = 125 },
	[300] = { name = "Artisan", level = 35, skill = 200 },
}

---------------------------------------------------------------------------
-- Chances
---------------------------------------------------------------------------

-- Chance of a skill-up at `skill` from { orange, yellow, green, grey }.
-- -> chance (nil when the recipe needs more skill), colour name
function Pl.ChanceFromThresholds(levels, skill)
	local orange, yellow, green, grey = levels[1], levels[2], levels[3], levels[4]
	if skill < orange then return nil, "red" end
	if skill >= grey then return 0, "grey" end
	if skill < yellow then return 1, "orange" end
	return (grey - skill) / (grey - yellow), skill < green and "yellow" or "green"
end

-- -> chance, colour, basis for a recipe at a skill. `state` is what the
-- profession window said about it (Professions.RecipeState).
function Pl.Chance(recipe, skill, state)
	if state and state.difficulty ~= nil and state.atRank == skill then
		return Pl.CLIENT_CHANCE[state.difficulty], Pl.COLORS[state.difficulty], "client"
	end
	if recipe.skill then
		local chance, color = Pl.ChanceFromThresholds(recipe.skill, skill)
		return chance, color, recipe.skillVerified and "thresholds" or "thresholds-unverified"
	end
	if state and state.difficulty ~= nil then
		return Pl.CLIENT_CHANCE[state.difficulty], Pl.COLORS[state.difficulty], "client-stale"
	end
	return nil, "unknown", "unknown"
end

-- Crafts expected from skill `from` to `to`: per skill point when the skill
-- levels are known, else one flat chance. -> crafts (fractional; nil when
-- it cannot get there), basis
function Pl.ExpectedCrafts(recipe, from, to, state)
	if to <= from then return 0, "none" end
	if recipe.skill then
		local total = 0
		for skill = from, to - 1 do
			local chance = Pl.ChanceFromThresholds(recipe.skill, skill)
			if not chance or chance <= 0 then return nil, "grey" end
			total = total + 1 / chance
		end
		return total, recipe.skillVerified and "thresholds" or "thresholds-unverified"
	end
	local chance, _, basis = Pl.Chance(recipe, from, state)
	if not chance or chance <= 0 then return nil, basis end
	return (to - from) / chance, basis
end

---------------------------------------------------------------------------
-- Materials
---------------------------------------------------------------------------

local function defaultCount(item) return ns.Professions.Count(item) end

-- How many times the bags make the recipe, after what is held back.
function Pl.CraftableCount(recipe, count, reserved)
	count, reserved = count or defaultCount, reserved or {}
	local best
	for _, r in ipairs((ns.Recipes.Reagents(recipe))) do
		local n = math.floor(math.max(0, count(r[1]) - (reserved[r[1]] or 0)) / r[2])
		if not best or n < best then best = n end
	end
	return best or 0
end

-- Materials for `crafts` crafts of a recipe:
--   { item, name, perCraft, required, owned, missing, origin, madeFrom }
-- `reserved` holds what earlier crafts of a plan already use. A missing
-- material the same profession makes (Bolt of Linen Cloth) gets `madeFrom`,
-- one level deep.
function Pl.Materials(recipe, crafts, count, reserved)
	count, reserved = count or defaultCount, reserved or {}
	local reagents, origin = ns.Recipes.Reagents(recipe)
	local rows = {}
	for _, r in ipairs(reagents) do
		local item, per = r[1], r[2]
		local required = per * crafts
		local owned = math.max(0, count(item) - (reserved[item] or 0))
		local row = { item = item, name = ns.Recipes.ItemName(item), perCraft = per, required = required,
			owned = owned, missing = math.max(0, required - owned), origin = origin }
		if row.missing > 0 and recipe.line then
			local sub = ns.Recipes.Creating(item, recipe.line)
			if sub and sub.id ~= recipe.id then
				row.madeFrom = { recipe = sub, rows = Pl.Materials(sub, row.missing, count, reserved) }
			end
		end
		rows[#rows + 1] = row
	end
	return rows
end

function Pl.Reserve(rows, reserved)
	for _, row in ipairs(rows) do
		reserved[row.item] = (reserved[row.item] or 0) + math.min(row.required, row.owned)
	end
end

function Pl.TotalMissing(rows)
	local n = 0
	for _, row in ipairs(rows) do n = n + row.missing end
	return n
end

---------------------------------------------------------------------------
-- The next craft
---------------------------------------------------------------------------

-- The route's next craft with the numbers: chance now, crafts expected to
-- its target skill, crafts planned, materials for them. With no open craft
-- in the route, a recommendation from the known recipes (`recommended`).
-- -> Professions.NextCraft's table plus { chance, color, basis, expected,
--    planned, materials, missing } or nil
function Pl.Next(prof)
	local P = ns.Professions
	local rank = C.SkillRank(prof.line)
	if not rank then return nil end
	local craft = P.NextCraft(prof)
	if not craft then
		local rec = Pl.Recommend(prof.line)
		if not rec or rec.capped then return nil end
		local state = P.RecipeState(prof.line, rec.recipe.id)
		return {
			name = rec.recipe.name, spell = rec.recipe.id, untilSkill = rec.toSkill, craftable = rec.craftable,
			known = state and state.learned or C.SpellKnown(rec.recipe.id), difficulty = rec.color,
			chance = rec.chance, color = rec.color, basis = rec.basis, expected = rec.expectedCrafts,
			planned = rec.crafts, materials = rec.materials, missing = rec.missing, recommended = true,
		}
	end
	local recipe = ns.Recipes.Get(craft.spell)
		or { id = craft.spell, name = craft.name, line = prof.line, routeReagents = craft.reagents }
	local state = P.RecipeState(prof.line, craft.spell)
	craft.chance, craft.color, craft.basis = Pl.Chance(recipe, rank, state)
	if craft.untilSkill and craft.untilSkill > rank then
		craft.expected = Pl.ExpectedCrafts(recipe, rank, craft.untilSkill, state)
	end
	if craft.count and craft.goal and craft.goal.item then
		craft.planned = math.max(0, craft.count - P.Count(craft.goal.item))
	else
		craft.planned = craft.expected and math.ceil(craft.expected) or Pl.UNKNOWN_BATCH
	end
	craft.materials = Pl.Materials(recipe, craft.planned)
	craft.missing = Pl.TotalMissing(craft.materials)
	return craft
end

---------------------------------------------------------------------------
-- Recommendations from the known recipes (no open craft in the route)
---------------------------------------------------------------------------

-- Recipes the character can use at `skill`: learned, or not known to be
-- unlearned (the window not opened yet), as long as the skill allows it.
local function usable(recipe, skill)
	local state = ns.Professions.RecipeState(recipe.line, recipe.id)
	if state and state.learned == false then return false end
	if recipe.skill and skill < recipe.skill[1] then return false end
	return true, state and state.learned == true
end

-- The best recipe to craft next for a skill line, at `opts.skill` (default
-- the character's). opts.craftableOnly: only what the bags make now.
-- -> { recipe, skill, toSkill, maxRank, chance, color, basis, expectedCrafts,
--      crafts, materials, missing, craftable } or { capped = true } or nil
function Pl.Recommend(line, opts)
	opts = opts or {}
	local rank, cap = C.SkillRank(line)
	if not rank then return nil end
	local skill = opts.skill or rank
	local maxRank = (cap or 0) > 0 and cap or skill
	if skill >= maxRank then return { capped = true, skill = skill, maxRank = maxRank } end
	local count, reserved = opts.count or defaultCount, opts.reserved or {}
	local P = ns.Professions
	local best, bestScore
	for _, recipe in ipairs(ns.Recipes.ForLine(line)) do
		local ok, confirmed = usable(recipe, skill)
		local chance, color, basis = Pl.Chance(recipe, skill, P.RecipeState(line, recipe.id))
		local craftable = ok and Pl.CraftableCount(recipe, count, reserved) or 0
		if ok and (chance == nil or chance > 0) and (not opts.craftableOnly or craftable > 0) then
			-- Sure skill-ups first, then what the bags make, known recipes, known chances.
			local score = (chance or 0.3) * 100 + math.min(craftable, 10) * 2
				+ (confirmed and 5 or 0) - (recipe.kind == "enchant" and 3 or 0)
			if not bestScore or score > bestScore then
				best, bestScore = { recipe = recipe, chance = chance, color = color, basis = basis, confirmed = confirmed }, score
			end
		end
	end
	if not best then return nil end
	local recipe = best.recipe
	local to = math.min(maxRank, skill + Pl.MAX_STEP)
	if recipe.skill then
		local stop = skill + 1
		while stop < to do
			local chance = Pl.ChanceFromThresholds(recipe.skill, stop)
			if not chance or chance < Pl.STOP_CHANCE then break end
			stop = stop + 1
		end
		to = math.max(skill + 1, stop)
	elseif not best.chance then
		to = skill -- chance unknown: a batch, then look again
	end
	local crafts, craftBasis
	if best.chance then crafts, craftBasis = Pl.ExpectedCrafts(recipe, skill, to, P.RecipeState(line, recipe.id)) end
	local planned = crafts and math.ceil(crafts) or Pl.UNKNOWN_BATCH
	local rows = Pl.Materials(recipe, planned, count, reserved)
	return {
		recipe = recipe, skill = skill, toSkill = to, maxRank = maxRank,
		chance = best.chance, color = best.color, basis = best.basis, confirmedLearned = best.confirmed,
		expectedCrafts = crafts, crafts = planned, craftBasis = craftBasis or "unknown",
		materials = rows, missing = Pl.TotalMissing(rows), craftable = Pl.CraftableCount(recipe, count, reserved),
	}
end

-- A few recommendations in a row, as the skill would grow, each holding
-- back what the ones before it use.
function Pl.Plan(line, steps, count)
	local rank = C.SkillRank(line)
	if not rank then return {} end
	local plan, reserved, skill = {}, {}, rank
	for _ = 1, steps or 3 do
		local step = Pl.Recommend(line, { skill = skill, count = count, reserved = reserved })
		if not step or step.capped then break end
		plan[#plan + 1] = step
		Pl.Reserve(step.materials, reserved)
		if step.toSkill <= skill then break end -- chance unknown: one batch
		skill = step.toSkill
	end
	return plan
end

---------------------------------------------------------------------------
-- Training
---------------------------------------------------------------------------

-- The next rank to train: the route's next "train" goal above the current
-- cap, what it asks (character level, skill) and the nearest trainer for
-- this side. Without a route, the packs' ranks (trainers named, no place).
-- -> { line, rankMax, rankName, needLevel, needSkill, ready, trainer, verified } or nil
function Pl.Milestone(prof)
	local rank, cap = C.SkillRank(prof.line)
	if not rank then return nil end
	cap = cap or 0
	local level = ns.Quests.Player().level or 1
	local route = ns.Professions.Route(prof)
	for _, step in ipairs(route and route.steps or {}) do
		for _, goal in ipairs(step) do
			if goal[1] == "train" and goal[3] > cap then
				local info = Pl.RANKS[goal[3]] or {}
				local needLevel = info.level or 1
				for _, g in ipairs(step) do if g[1] == "level" then needLevel = g[2] end end
				local needSkill = info.skill or 0
				return {
					line = prof.line, rankMax = goal[3], rankName = info.name,
					needLevel = needLevel, needSkill = needSkill,
					ready = level >= needLevel and rank >= needSkill,
					trainer = ns.Engine.PlaceOf(goal), verified = true,
				}
			end
		end
	end
	local data = ns.Recipes.Data(prof.line)
	for _, r in ipairs(data.ranks) do
		if r.maxSkill > cap then
			local t = data.trainers[1]
			return {
				line = prof.line, rankMax = r.maxSkill, rankName = r.name,
				needLevel = r.level or 1, needSkill = r.trainAt,
				ready = level >= (r.level or 1) and rank >= r.trainAt,
				trainer = t and t.x and t.map and { map = t.map, x = t.x, y = t.y, name = t.name } or nil,
				trainerName = t and t.name, verified = r.verified and r.verified.values or false,
			}
		end
	end
	return nil
end

-- Recipes to learn now: the route's open "learn" goals in this rank, and
-- trainer recipes from the packs the window says are not learned yet.
-- -> { { name, spell }, ... }
function Pl.Learnable(prof)
	local out, seen = {}, {}
	local P, E = ns.Professions, ns.Engine
	local st = P.Stage(prof)
	if st then
		for s = st.step, st.last do
			for g, goal in ipairs(st.route.steps[s]) do
				if goal[1] == "learn" and not seen[goal[2]] and E.GoalStatus(st.route, s, g, goal) == "open" then
					seen[goal[2]] = true
					out[#out + 1] = { name = goal.name, spell = goal[2] }
				end
			end
		end
	end
	local rank = C.SkillRank(prof.line) or 0
	for _, recipe in ipairs(ns.Recipes.ForLine(prof.line)) do
		local state = P.RecipeState(prof.line, recipe.id)
		if recipe.source == "trainer" and state and state.learned == false and not seen[recipe.id]
			and (not recipe.skill or rank >= recipe.skill[1]) then
			seen[recipe.id] = true
			out[#out + 1] = { name = recipe.name, spell = recipe.id }
		end
	end
	return out
end

---------------------------------------------------------------------------
-- Material reminders: one line in chat when the bags newly make the next
-- craft of a profession (not at login: only when it changes)
---------------------------------------------------------------------------

local ready, seeded = {}, false

function Pl.CheckReminders()
	local P = ns.Professions
	for _, k in ipairs(P.Known()) do
		local prof = k.prof
		local c = P.Shown(prof) and Pl.Next(prof)
		local now = c and (c.craftable or 0) > 0 and c.known ~= false and c.spell or nil
		if now and ready[prof.line] ~= now and seeded and ns.Get("professions.reminders") then
			ns.Print(("%s: you have materials for %d %s."):format(prof.name, c.craftable, c.name or "?"))
		end
		ready[prof.line] = now
	end
	seeded = true
end

local pending = false
local function queue()
	if pending then return end
	pending = true
	ns.After(0.5, function() pending = false Pl.CheckReminders() end)
end
ns.On("READY", Pl.CheckReminders)
ns.On("PROFESSIONS_CHANGED", queue)

-- ForeverLevels: profession planner. Recommends the next craft, counts materials and
-- estimates how many crafts a skill range takes. Read-only: it never crafts, buys,
-- sells, destroys or disenchants anything.
--
-- Skill-up chance, in order of preference:
--   1. "client"     difficulty the client reported at the current skill (C_TradeSkillUI)
--   2. "thresholds" the recipe's { orange, yellow, green, grey } skill levels, using the
--                    commonly used estimate chance = (grey - skill) / (grey - yellow);
--                    "thresholds-unverified" when those levels are a fallback
--   3. "client-stale" difficulty read at a lower skill (rough)
--   4. "unknown"    no data: suggest a few crafts and re-check
-- Every recommendation carries its basis so the UI can say how sure it is.
-- See docs/MATERIAL_PLANNER.md.

local _, FL = ...

local Planner = {}
FL.Planner = Planner

Planner.COLORS = { [0] = "orange", [1] = "yellow", [2] = "green", [3] = "grey" }
-- Rough chances per client difficulty, used only when no skill thresholds exist.
Planner.CLIENT_CHANCE = { [0] = 1, [1] = 0.75, [2] = 0.25, [3] = 0 }
Planner.UNKNOWN_BATCH = 5      -- crafts to suggest when the chance is unknown
Planner.STOP_CHANCE = 0.5      -- move on once a recipe drops below this chance
Planner.MAX_STEP = 10          -- plan at most this many skill points per recommendation

------------------------------------------------------------------------
-- Chances
------------------------------------------------------------------------

-- Chance of a skill-up at `skill` from { orange, yellow, green, grey }.
-- Returns chance (nil when the recipe needs more skill) and a color name.
function Planner.ChanceFromThresholds(levels, skill)
	local orange, yellow, green, grey = levels[1], levels[2], levels[3], levels[4]
	if skill < orange then return nil, "red" end
	if skill >= grey then return 0, "grey" end
	if skill < yellow then return 1, "orange" end
	local chance = (grey - skill) / (grey - yellow)
	return chance, skill < green and "yellow" or "green"
end

-- Returns chance, color, basis for a recipe at a skill level.
function Planner.Chance(recipe, skill, state)
	if state and state.difficulty ~= nil and state.atRank == skill then
		return Planner.CLIENT_CHANCE[state.difficulty], Planner.COLORS[state.difficulty], "client"
	end
	if recipe.skill then
		local chance, color = Planner.ChanceFromThresholds(recipe.skill, skill)
		local verified = recipe.verified and recipe.verified.skill
		return chance, color, verified and "thresholds" or "thresholds-unverified"
	end
	if state and state.difficulty ~= nil then
		return Planner.CLIENT_CHANCE[state.difficulty], Planner.COLORS[state.difficulty], "client-stale"
	end
	return nil, "unknown", "unknown"
end

-- Expected number of crafts to go from `from` to `to` skill. Uses the threshold
-- formula per skill point when available, otherwise one flat chance.
-- Returns crafts (fractional, nil if impossible) and the basis.
function Planner.ExpectedCrafts(recipe, from, to, state)
	if to <= from then return 0, "none" end
	if recipe.skill then
		local total = 0
		for skill = from, to - 1 do
			local chance = Planner.ChanceFromThresholds(recipe.skill, skill)
			if not chance or chance <= 0 then return nil, "grey" end
			total = total + 1 / chance
		end
		local verified = recipe.verified and recipe.verified.skill
		return total, verified and "thresholds" or "thresholds-unverified"
	end
	local chance, _, basis = Planner.Chance(recipe, from, state)
	if not chance or chance <= 0 then return nil, basis end
	return (to - from) / chance, basis
end

------------------------------------------------------------------------
-- Materials
------------------------------------------------------------------------

local function DefaultCount(itemID)
	return FL.Inventory.Count(itemID)
end

-- How many times the recipe can be crafted from what you own.
function Planner.CraftableCount(recipe, count, reserved)
	count = count or DefaultCount
	reserved = reserved or {}
	local reagents = FL.Professions.GetReagents(recipe)
	local best
	for _, reagent in ipairs(reagents) do
		local available = math.max(0, count(reagent[1]) - (reserved[reagent[1]] or 0))
		local possible = math.floor(available / reagent[2])
		if not best or possible < best then best = possible end
	end
	return best or 0
end

-- Material rows for `crafts` crafts of a recipe:
--   { itemID, name, perCraft, required, owned, missing, origin, madeFrom }
-- `reserved` holds amounts already promised to earlier steps of a plan.
-- Missing intermediates that this profession can make (Bolt of Linen Cloth) get a
-- `madeFrom` breakdown, one level deep.
function Planner.Materials(recipe, crafts, count, reserved)
	count = count or DefaultCount
	reserved = reserved or {}
	local reagents, origin = FL.Professions.GetReagents(recipe)
	local rows = {}
	for _, reagent in ipairs(reagents) do
		local itemID, perCraft = reagent[1], reagent[2]
		local required = perCraft * crafts
		local owned = math.max(0, count(itemID) - (reserved[itemID] or 0))
		local missing = math.max(0, required - owned)
		local row = {
			itemID = itemID, name = FL:GetItemName(itemID), perCraft = perCraft,
			required = required, owned = owned, missing = missing, origin = origin,
		}
		if missing > 0 and recipe.profession then
			local sub = FL:GetRecipeCreating(itemID, recipe.profession)
			if sub and sub.id ~= recipe.id then
				row.madeFrom = { recipe = sub, rows = Planner.Materials(sub, missing, count, reserved) }
			end
		end
		rows[#rows + 1] = row
	end
	return rows
end

function Planner.Reserve(rows, reserved)
	for _, row in ipairs(rows) do
		reserved[row.itemID] = (reserved[row.itemID] or 0) + math.min(row.required, row.owned)
	end
end

function Planner.TotalMissing(rows)
	local total = 0
	for _, row in ipairs(rows) do total = total + row.missing end
	return total
end

------------------------------------------------------------------------
-- Recommendations
------------------------------------------------------------------------

-- Recipes the character can use at `skill`: learned, or not known to be unlearned
-- (the client has not been asked yet) as long as the skill requirement is met.
local function Usable(recipe, skill)
	local learned = FL.Professions.IsLearned(recipe.id)
	if learned == false then return false end
	if recipe.skill and skill < recipe.skill[1] then return false end
	return true, learned == true
end

-- Recommends the next craft for a profession at `skill` (defaults to the current
-- skill). Returns nil when nothing useful is known.
function Planner.Recommend(key, opts)
	opts = opts or {}
	local data = FL:GetProfessionData(key)
	local info = FL.Professions:Get(key)
	if not data or not info then return nil end
	local skill = opts.skill or info.rank
	local maxRank = info.maxRank > 0 and info.maxRank or skill
	if skill >= maxRank then return { capped = true, skill = skill, maxRank = maxRank } end
	local count, reserved = opts.count or DefaultCount, opts.reserved or {}

	local best, bestScore
	for _, recipe in ipairs(data.recipes) do
		local usable, confirmed = Usable(recipe, skill)
		local state = FL.Professions.GetRecipeState(recipe.id)
		local chance, color, basis = Planner.Chance(recipe, skill, state)
		if usable and (chance == nil or chance > 0) then
			local craftable = Planner.CraftableCount(recipe, count, reserved)
			-- Prefer: sure skill-ups, recipes you can make now, confirmed learned, known chance.
			local score = (chance or 0.3) * 100 + math.min(craftable, 10) * 2
				+ (confirmed and 5 or 0) - (recipe.kind == "enchant" and 3 or 0)
			if not bestScore or score > bestScore then
				best, bestScore = { recipe = recipe, chance = chance, color = color, basis = basis, confirmed = confirmed }, score
			end
		end
	end
	if not best then return nil end

	-- How far to take this recipe.
	local recipe = best.recipe
	local to = math.min(maxRank, skill + Planner.MAX_STEP)
	if recipe.skill then
		local stop = skill + 1
		while stop < to do
			local chance = Planner.ChanceFromThresholds(recipe.skill, stop)
			if not chance or chance < Planner.STOP_CHANCE then break end
			stop = stop + 1
		end
		to = math.max(skill + 1, stop)
	elseif not best.chance then
		to = skill   -- unknown chance: batch, then re-check
	end

	local crafts, craftBasis
	if best.chance then
		crafts, craftBasis = Planner.ExpectedCrafts(recipe, skill, to, FL.Professions.GetRecipeState(recipe.id))
	end
	local plannedCrafts = crafts and math.ceil(crafts) or Planner.UNKNOWN_BATCH

	local rows = Planner.Materials(recipe, plannedCrafts, count, reserved)
	return {
		profession = key, recipe = recipe, skill = skill, toSkill = to, maxRank = maxRank,
		chance = best.chance, color = best.color, basis = best.basis, confirmedLearned = best.confirmed,
		expectedCrafts = crafts, crafts = plannedCrafts, craftBasis = craftBasis or "unknown",
		materials = rows, missing = Planner.TotalMissing(rows),
		craftable = Planner.CraftableCount(recipe, count, reserved),
	}
end

-- A short sequence of recommendations, simulating skill gains and reserving
-- materials for earlier steps so later steps show what is really left.
function Planner.Plan(key, steps, count)
	local info = FL.Professions:Get(key)
	if not info then return {} end
	local plan, reserved, skill = {}, {}, info.rank
	for _ = 1, steps or 3 do
		local step = Planner.Recommend(key, { skill = skill, count = count, reserved = reserved })
		if not step or step.capped then break end
		plan[#plan + 1] = step
		Planner.Reserve(step.materials, reserved)
		if step.toSkill <= skill then break end   -- unknown chance: stop after one batch
		skill = step.toSkill
	end
	return plan
end

------------------------------------------------------------------------
-- Trainer milestones
------------------------------------------------------------------------

-- Next rank to train, with whether you can train it now. Rank values may be an
-- unverified fallback (see the profession data); the client's current cap is used
-- to work out which rank you have.
function Planner.NextMilestone(key, zone)
	local data = FL:GetProfessionData(key)
	local info = FL.Professions:Get(key)
	if not data or not info or #data.ranks == 0 then return nil end
	local nextRank
	for _, rank in ipairs(data.ranks) do
		if rank.maxSkill > info.maxRank then
			nextRank = rank
			break
		end
	end
	if not nextRank then return nil end

	local level = FL.player.level
	local needSkill = math.max(0, nextRank.trainAt - info.rank)
	local needLevel = math.max(0, (nextRank.level or 0) - level)
	local trainer
	for _, candidate in ipairs(data.trainers) do
		if not trainer or (zone and candidate.zone == zone and trainer.zone ~= zone) then trainer = candidate end
	end
	return {
		profession = key, rank = nextRank, ready = needSkill == 0 and needLevel == 0,
		needSkill = needSkill, needLevel = needLevel, trainer = trainer,
		verified = nextRank.verified and nextRank.verified.values or false,
	}
end

-- Recipes a trainer teaches that you could learn at your skill but have not.
-- Only reported once the client has said they are unlearned.
function Planner.LearnableRecipes(key)
	local data = FL:GetProfessionData(key)
	local info = FL.Professions:Get(key)
	local list = {}
	if not data or not info then return list end
	for _, recipe in ipairs(data.recipes) do
		if recipe.source == "trainer" and FL.Professions.IsLearned(recipe.id) == false
			and (not recipe.skill or info.rank >= recipe.skill[1]) then
			list[#list + 1] = recipe
		end
	end
	return list
end

------------------------------------------------------------------------
-- Material reminders: one chat line when you newly have everything for the next craft
------------------------------------------------------------------------

local ready = {}

function Planner.CheckReminders()
	local settings = FL.db and FL.db.profile.professions
	if not (settings and settings.enabled and settings.reminders) then return end
	for _, info in ipairs(FL.Professions:List(true)) do
		local step = Planner.Recommend(info.key)
		if step and step.recipe then
			local id = info.key .. ":" .. step.recipe.id
			local isReady = step.craftable > 0
			if isReady and not ready[id] then
				FL:Print(string.format("%s: you have materials for %d x %s.", info.name, step.craftable, step.recipe.name))
			end
			ready[id] = isReady
		end
	end
end

FL:On("INVENTORY_CHANGED", Planner.CheckReminders)

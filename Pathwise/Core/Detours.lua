-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: optional profession detours.
--
-- A detour is a profession suggestion shown next to the leveling route: visit a
-- trainer you can train with now, or craft something you have materials for. It is
-- a separate layer. It never changes the route, its step index, Back/Next, or quest
-- completion. Detours have their own states, saved per character:
--   suggestion  shown, waiting for Go / Later / Skip (not saved)
--   active      accepted; may point the arrow at a trainer until done or cancelled
--   done        finished (or completed automatically)
--   skipped     dismissed; never suggested again for that milestone
--   postponed   "Later": comes back once the route has moved to another step
-- See docs/PROFESSION_DETOURS.md.

local _, FL = ...

local Detours = {}
FL.Detours = Detours

Detours.suggestion = nil

local function Settings()
	return FL.db and FL.db.profile.professions
end

local function Store()
	return FL.char and FL.char.professions.detours
end

function Detours.IsEnabled()
	local settings = Settings()
	return settings and settings.enabled and settings.detours or false
end

-- Identifies the route position for "Later". Read-only use of the engine.
local function RouteKey()
	local engine = FL.Engine
	if not engine.route then return "none" end
	return engine.route.id .. ":" .. engine.index
end

local function CurrentZone()
	local mapID = C_Map.GetBestMapForUnit("player")
	local info = mapID and C_Map.GetMapInfo(mapID)
	if info and info.name and not FL.IsSecret(info.name) then return info.name end
end

local function LearnedCount(key)
	local data = FL:GetProfessionData(key)
	local count = 0
	for _, recipe in ipairs(data and data.recipes or {}) do
		if FL.Professions.IsLearned(recipe.id) then count = count + 1 end
	end
	return count
end

------------------------------------------------------------------------
-- Candidates
------------------------------------------------------------------------

-- Trainer visit, only when the trainer is in your zone or the route's zone.
local function TrainerCandidate(info, zone)
	local milestone = FL.Planner.NextMilestone(info.key, zone)
	local learnable = FL.Planner.LearnableRecipes(info.key)
	local ready = milestone and milestone.ready
	if not ready and #learnable == 0 then return nil end
	local data = FL:GetProfessionData(info.key)
	local trainer = milestone and milestone.trainer or data.trainers[1]
	if not trainer then return nil end
	local routeZone = FL.Engine.route and FL.Engine.route.zone
	if trainer.zone ~= zone and trainer.zone ~= routeZone then return nil end

	local id, title
	if ready then
		id = "train:" .. info.key .. ":" .. milestone.rank.name
		title = "Train " .. milestone.rank.name .. " " .. info.name
	else
		local ids = {}
		for _, recipe in ipairs(learnable) do ids[#ids + 1] = recipe.id end
		id = "learn:" .. info.key .. ":" .. table.concat(ids, ",")
		title = "Learn " .. #learnable .. " new " .. info.name .. " recipe" .. (#learnable > 1 and "s" or "")
	end
	local where = trainer.name .. (trainer.title and (" <" .. trainer.title .. ">") or "") .. " in " .. (trainer.zone or "?")
	local notes = {}
	if not trainer.x then notes[#notes + 1] = "Trainer position not verified yet; no waypoint." end
	if ready and not milestone.verified then notes[#notes + 1] = "Rank requirements are unverified fallback values." end
	return {
		id = id, kind = "trainer", profession = info.key, title = title, text = where,
		note = #notes > 0 and table.concat(notes, " ") or nil,
		zone = trainer.zone, map = trainer.map, x = trainer.x, y = trainer.y,
		startMax = info.maxRank, startLearned = LearnedCount(info.key),
	}
end

-- Craft something you already have materials for.
local function CraftCandidate(info)
	local step = FL.Planner.Recommend(info.key, { craftableOnly = true })
	if not step or not step.recipe or step.craftable <= 0 then return nil end
	local recipe = step.recipe
	local bucket = math.floor(info.rank / 10)
	local amount = math.min(step.craftable, step.crafts)
	local text = string.format("You can make %d now.", step.craftable)
	if step.expectedCrafts then
		text = text .. string.format(" About %d crafts to reach %d.", math.ceil(step.expectedCrafts), step.toSkill)
	end
	return {
		id = "craft:" .. info.key .. ":" .. recipe.id .. ":" .. bucket, kind = "craft", profession = info.key,
		title = string.format("Craft %d x %s", amount, recipe.name), text = text,
		note = (step.basis == "client") and nil or "Skill-up chance is an estimate.",
		recipeID = recipe.id, startRank = info.rank, targetRank = math.max(info.rank + 1, step.toSkill),
	}
end

local function Allowed(candidate)
	local store = Store()
	if not candidate or store.states[candidate.id] then return false end
	local postponedAt = store.postponed[candidate.id]
	if postponedAt then
		if postponedAt == RouteKey() then return false end
		store.postponed[candidate.id] = nil   -- the route moved on; offer it again
	end
	return true
end

function Detours:FindCandidate()
	local zone = CurrentZone()
	local crafts = {}
	for _, info in ipairs(FL.Professions:List(true)) do
		if info.hasData then
			local trainer = TrainerCandidate(info, zone)
			if Allowed(trainer) then return trainer end
			crafts[#crafts + 1] = CraftCandidate(info)
		end
	end
	for _, candidate in ipairs(crafts) do
		if Allowed(candidate) then return candidate end
	end
	return nil
end

------------------------------------------------------------------------
-- State changes
------------------------------------------------------------------------

local function Changed()
	FL:Fire("DETOUR_CHANGED", Detours:GetActive(), Detours.suggestion)
end

function Detours:GetActive()
	local store = Store()
	return store and store.active or nil
end

function Detours:Evaluate()
	if not Store() then return end
	local before = self.suggestion and self.suggestion.id
	if not self.IsEnabled() or not FL.Engine.route or self:GetActive() then
		self.suggestion = nil
	else
		self.suggestion = self:FindCandidate()
	end
	if (self.suggestion and self.suggestion.id) ~= before then Changed() end
end

function Detours:Accept()
	local candidate = self.suggestion
	if not candidate then return false end
	Store().active = candidate
	self.suggestion = nil
	Changed()
	return true
end

function Detours:Postpone()
	local candidate = self.suggestion
	if not candidate then return false end
	Store().postponed[candidate.id] = RouteKey()
	self.suggestion = nil
	Changed()
	self:Evaluate()
	return true
end

function Detours:Skip()
	local candidate = self.suggestion
	if not candidate then return false end
	Store().states[candidate.id] = "skipped"
	self.suggestion = nil
	Changed()
	self:Evaluate()
	return true
end

local function Finish(state)
	local store = Store()
	local active = store and store.active
	if not active then return false end
	store.states[active.id] = state
	store.active = nil
	Changed()
	Detours:Evaluate()
	return true
end

function Detours:Complete() return Finish("done") end
function Detours:Cancel() return Finish("skipped") end

function Detours:SetEnabled(enabled)
	Settings().detours = enabled and true or false
	if not enabled then
		-- Turning detours off drops the current one without marking it done or skipped.
		Store().active = nil
		self.suggestion = nil
		Changed()
	else
		self:Evaluate()
	end
end

-- Completes the active detour when its goal is met. Profession progress never
-- touches the route: this only changes detour state.
function Detours:CheckActive()
	local active = self:GetActive()
	if not active then return end
	local info = FL.Professions:Get(active.profession)
	if not info then return end
	if active.kind == "trainer" then
		if info.maxRank > (active.startMax or 0) or LearnedCount(active.profession) > (active.startLearned or 0) then
			FL:Print("detour done:", active.title)
			self:Complete()
		end
	elseif active.kind == "craft" then
		local recipe = FL:GetRecipe(active.recipeID)
		local outOfMaterials = recipe and FL.Planner.CraftableCount(recipe) == 0
		if info.rank >= (active.targetRank or math.huge) or outOfMaterials then
			FL:Print("detour done:", active.title)
			self:Complete()
		end
	end
end

-- Arrow target for an active detour with coordinates, or nil.
function Detours:GetNavigationTarget()
	local active = self:GetActive()
	if not active or not active.x or not self.IsEnabled() then return nil end
	local mapID = FL.Waypoint.ResolveMap(active, nil)
	if not mapID then return nil end
	return { mapID = mapID, x = active.x, y = active.y, title = "Detour: " .. active.title }
end

------------------------------------------------------------------------
-- Events: everything funnels into one debounced evaluation
------------------------------------------------------------------------

local function Queue()
	FL:Debounce("DETOUR_EVALUATE", 0.5, function()
		Detours:CheckActive()
		Detours:Evaluate()
	end)
end

FL:On("PROFESSIONS_CHANGED", Queue)
FL:On("INVENTORY_CHANGED", Queue)
FL:On("STEP_CHANGED", Queue)
FL:On("PLAYER_CHANGED", Queue)
FL:RegisterEvent("ZONE_CHANGED_NEW_AREA", Queue)

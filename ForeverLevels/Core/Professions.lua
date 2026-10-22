-- ForeverLevels: profession detection.
--
-- Skills come from GetProfessions()/GetProfessionInfo() (used by Forever's own
-- Blizzard_ProfessionsBook/Camelot code), with C_SkillInfo as a fallback.
-- Recipe state (learned, difficulty) and the client's own reagent lists come from
-- C_TradeSkillUI while a profession window is open, and are cached in SavedVariables
-- because the client only answers for the profession that is open.
-- All APIs here are listed in docs/API_RESEARCH.md.

local _, FL = ...

local Professions = {}
FL.Professions = Professions

Professions.known = {}   -- [key] = { key, name, skillLine, rank, maxRank, modifier, hasData }

local function Settings()
	return FL.db and FL.db.profile.professions
end

function Professions.IsTracked(key)
	local settings = Settings()
	if not settings or not settings.enabled then return false end
	return settings.tracked[key] ~= false
end

local function KeyFor(skillLine, name)
	local data = FL:GetProfessionDataBySkillLine(skillLine) or FL:GetProfessionDataByName(name)
	if data then return data.profession, true end
	return (name:lower():gsub("[^%w]+", "_")), false
end

local function Add(found, name, skillLine, rank, maxRank, modifier)
	if not name or FL.IsSecret(name) or FL.IsSecret(rank) then return end
	local key, hasData = KeyFor(skillLine, name)
	found[key] = {
		key = key, name = name, skillLine = skillLine, hasData = hasData,
		rank = rank or 0, maxRank = maxRank or 0, modifier = modifier or 0,
	}
end

-- Reads the player's professions. Returns a table keyed by profession key.
function Professions.Scan()
	local found = {}
	if GetProfessions and GetProfessionInfo then
		-- Forever order: primary 1, primary 2, first aid, fishing, cooking.
		local p1, p2, firstAid, fishing, cooking = GetProfessions()
		local indices = { p1, p2, firstAid, fishing, cooking }
		for i = 1, 5 do
			local index = indices[i]
			if index then
				local name, _, rank, maxRank, _, _, skillLine, modifier = GetProfessionInfo(index)
				Add(found, name, skillLine, rank, maxRank, modifier)
			end
		end
	elseif C_SkillInfo and C_SkillInfo.GetNumSkillLines then
		for i = 1, C_SkillInfo.GetNumSkillLines() do
			local info = C_SkillInfo.GetSkillLineInfo(i)
			if info and not info.isHeader and (FL:GetProfessionDataBySkillLine(info.skillID) or FL:GetProfessionDataByName(info.name)) then
				Add(found, info.name, info.skillID, info.rank, info.maxRank, info.modifier)
			end
		end
	end
	return found
end

-- Rescans and fires PROFESSION_SKILL_CHANGED for each change, then PROFESSIONS_CHANGED.
function Professions:Refresh()
	if not FL.char then return end
	local saved = FL.char.professions.skills
	local found = Professions.Scan()
	local changed = false
	for key, info in pairs(found) do
		local before = saved[key]
		if not before or before.rank ~= info.rank or before.maxRank ~= info.maxRank then
			changed = true
			FL:Fire("PROFESSION_SKILL_CHANGED", key, before and before.rank or nil, info.rank, before and before.maxRank or nil, info.maxRank)
		end
		saved[key] = { rank = info.rank, maxRank = info.maxRank, name = info.name }
	end
	for key in pairs(saved) do
		if not found[key] then
			saved[key] = nil
			changed = true
		end
	end
	self.known = found
	FL:Fire("PROFESSIONS_CHANGED", changed)
end

function Professions:Get(key)
	return self.known[key]
end

-- Known professions as a sorted list, optionally only tracked ones.
function Professions:List(trackedOnly)
	local list = {}
	for key, info in pairs(self.known) do
		if not trackedOnly or Professions.IsTracked(key) then list[#list + 1] = info end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

------------------------------------------------------------------------
-- Recipes: learned state, difficulty and the client's reagent list
------------------------------------------------------------------------

-- nil = unknown (profession window never opened), true/false otherwise.
function Professions.IsLearned(recipeID)
	local state = FL.char and FL.char.professions.recipes[recipeID]
	if state then return state.learned end
	return nil
end

function Professions.GetRecipeState(recipeID)
	return FL.char and FL.char.professions.recipes[recipeID]
end

-- Client reagents for a recipe, if it was ever read: { { itemID, quantity }, ... }.
function Professions.GetClientReagents(recipeID)
	local cache = FL.db and FL.db.professionCache.schematics[recipeID]
	return cache and cache.reagents
end

-- Reagents to plan with: the client's list when known, otherwise the pack's.
function Professions.GetReagents(recipe)
	local client = Professions.GetClientReagents(recipe.id)
	if client and #client > 0 then return client, "client" end
	return recipe.reagents, (recipe.verified and recipe.verified.reagents) and "source" or "unverified"
end

local function ReadSchematic(recipeID)
	local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
	if not ok or type(schematic) ~= "table" or type(schematic.reagentSlotSchematics) ~= "table" then return nil end
	local reagents = {}
	for _, slot in ipairs(schematic.reagentSlotSchematics) do
		local first = slot.reagents and slot.reagents[1]
		if slot.required ~= false and first and first.itemID and slot.quantityRequired then
			reagents[#reagents + 1] = { first.itemID, slot.quantityRequired }
		end
	end
	return reagents
end

local function OpenProfessionData()
	if not (C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo) then return nil end
	local ok, info = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
	if not ok or type(info) ~= "table" then return nil end
	return FL:GetProfessionDataBySkillLine(info.professionID) or FL:GetProfessionDataByName(info.professionName)
end

-- Called while a profession window is open. Only the open profession's recipes are
-- read, so a closed profession is never marked "not learned" by mistake.
function Professions:ReadOpenProfession()
	if not (FL.char and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo) then return end
	local data = OpenProfessionData()
	if not data then return end
	local recipes = FL.char.professions.recipes
	local schematics = FL.db.professionCache.schematics
	local build = select(2, GetBuildInfo())
	for _, recipe in ipairs(data.recipes) do
		local info = C_TradeSkillUI.GetRecipeInfo(recipe.id)
		if info then
			recipes[recipe.id] = {
				learned = info.learned and true or false,
				difficulty = info.relativeDifficulty,
				canSkillUp = info.canSkillUp,
				numSkillUps = info.numSkillUps,
				at = time(),
			}
			local reagents = ReadSchematic(recipe.id)
			if reagents and #reagents > 0 then
				schematics[recipe.id] = { reagents = reagents, build = build }
			end
		end
	end
	FL:Fire("PROFESSIONS_CHANGED", true)
end

------------------------------------------------------------------------
-- Events (one registration each; bursts are merged)
------------------------------------------------------------------------

local function QueueRefresh()
	FL:Debounce("PROFESSION_SCAN", 0.3, function() Professions:Refresh() end)
end

local function QueueRecipeRead()
	FL:Debounce("PROFESSION_RECIPES", 0.3, function() Professions:ReadOpenProfession() end)
end

FL:RegisterEvent("SKILL_LINES_CHANGED", QueueRefresh)
FL:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE", QueueRefresh)
FL:RegisterEvent("TRAINER_CLOSED", QueueRefresh)
FL:RegisterEvent("TRADE_SKILL_SHOW", QueueRecipeRead)
FL:RegisterEvent("TRADE_SKILL_LIST_UPDATE", QueueRecipeRead)
FL:RegisterEvent("NEW_RECIPE_LEARNED", function(_, recipeID)
	if FL.char and recipeID then
		local state = FL.char.professions.recipes[recipeID] or {}
		state.learned = true
		state.at = time()
		FL.char.professions.recipes[recipeID] = state
	end
	QueueRefresh()
end)

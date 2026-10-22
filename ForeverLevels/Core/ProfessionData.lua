-- ForeverLevels: profession data registry and validation.
--
-- Profession data packs register with Pathwise:RegisterProfessionData({ ... }) (the
-- same function exists on the ForeverLevels global). Several packs may describe the
-- same profession; recipes merge by recipe ID, later packs win, trainers and items add up.
-- The format is documented in docs/PROFESSION_DATA_FORMAT.md. Validation is plain
-- Lua so tools/validate_routes.lua can run it offline.

local _, FL = ...

local ProfessionData = {}
FL.ProfessionData = ProfessionData

ProfessionData.API_VERSION = 1

local function IsID(value)
	return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function CheckVerified(verified, where, errors)
	if verified == nil then return end
	if type(verified) ~= "table" then
		errors[#errors + 1] = where .. ": 'verified' must be a table of field = true/false"
		return
	end
	for field, value in pairs(verified) do
		if type(field) ~= "string" or type(value) ~= "boolean" then
			errors[#errors + 1] = where .. ": 'verified' entries must be field = true/false"
		end
	end
end

-- Returns ok, errors, warnings.
function ProfessionData.Validate(pack)
	local errors, warnings = {}, {}
	if type(pack) ~= "table" then return false, { "profession data must be a table" }, warnings end
	local where = "profession pack " .. tostring(pack.id)

	if type(pack.id) ~= "string" or not pack.id:match("^[%w%._%-]+$") then
		errors[#errors + 1] = where .. ": 'id' must be letters, digits, '.', '_' or '-'"
	end
	if type(pack.profession) ~= "string" or not pack.profession:match("^[a-z_]+$") then
		errors[#errors + 1] = where .. ": 'profession' must be a lowercase key such as 'tailoring'"
	end
	for _, field in ipairs({ "name", "author", "license" }) do
		if type(pack[field]) ~= "string" or pack[field] == "" then
			errors[#errors + 1] = where .. ": '" .. field .. "' is required"
		end
	end
	if pack.skillLine ~= nil and not IsID(pack.skillLine) then
		errors[#errors + 1] = where .. ": 'skillLine' must be a skill line ID"
	end
	if pack.apiVersion ~= nil and (type(pack.apiVersion) ~= "number" or pack.apiVersion > ProfessionData.API_VERSION) then
		errors[#errors + 1] = where .. ": requires profession data API version " .. tostring(pack.apiVersion)
	end

	for i, rank in ipairs(pack.ranks or {}) do
		local rankWhere = where .. " rank " .. i
		if type(rank.name) ~= "string" then errors[#errors + 1] = rankWhere .. ": 'name' is required" end
		for _, field in ipairs({ "trainAt", "maxSkill" }) do
			if type(rank[field]) ~= "number" then errors[#errors + 1] = rankWhere .. ": '" .. field .. "' must be a number" end
		end
		if rank.level ~= nil and type(rank.level) ~= "number" then errors[#errors + 1] = rankWhere .. ": 'level' must be a number" end
		CheckVerified(rank.verified, rankWhere, errors)
	end

	for i, trainer in ipairs(pack.trainers or {}) do
		local trainerWhere = where .. " trainer " .. i
		if type(trainer.name) ~= "string" then errors[#errors + 1] = trainerWhere .. ": 'name' is required" end
		if (trainer.x == nil) ~= (trainer.y == nil) then
			errors[#errors + 1] = trainerWhere .. ": 'x' and 'y' must be given together"
		end
		for _, axis in ipairs({ "x", "y" }) do
			local value = trainer[axis]
			if value ~= nil and (type(value) ~= "number" or value < 0 or value > 100) then
				errors[#errors + 1] = trainerWhere .. ": '" .. axis .. "' must be 0-100"
			end
		end
		if trainer.x and not (trainer.zone or trainer.map) then
			errors[#errors + 1] = trainerWhere .. ": coordinates need 'zone' or 'map'"
		end
		CheckVerified(trainer.verified, trainerWhere, errors)
	end

	for itemID, item in pairs(pack.items or {}) do
		if not IsID(itemID) or type(item) ~= "table" or type(item.name) ~= "string" then
			errors[#errors + 1] = where .. ": items must be [itemID] = { name = ... }"
		else
			CheckVerified(item.verified, where .. " item " .. itemID, errors)
		end
	end

	if type(pack.recipes) ~= "table" or #pack.recipes == 0 then
		errors[#errors + 1] = where .. ": 'recipes' must be a non-empty list"
		return #errors == 0, errors, warnings
	end
	local seen = {}
	for i, recipe in ipairs(pack.recipes) do
		local recipeWhere = where .. " recipe " .. i
		if not IsID(recipe.id) then
			errors[#errors + 1] = recipeWhere .. ": 'id' must be the recipe (spell) ID"
		elseif seen[recipe.id] then
			errors[#errors + 1] = recipeWhere .. ": duplicate recipe id " .. recipe.id
		else
			seen[recipe.id] = true
		end
		if type(recipe.name) ~= "string" then errors[#errors + 1] = recipeWhere .. ": 'name' is required" end
		if recipe.creates ~= nil and not IsID(recipe.creates) then
			errors[#errors + 1] = recipeWhere .. ": 'creates' must be an item ID"
		end
		if type(recipe.reagents) ~= "table" or #recipe.reagents == 0 then
			errors[#errors + 1] = recipeWhere .. ": 'reagents' must list { itemID, quantity } pairs"
		else
			for _, reagent in ipairs(recipe.reagents) do
				if type(reagent) ~= "table" or not IsID(reagent[1]) or not IsID(reagent[2]) then
					errors[#errors + 1] = recipeWhere .. ": each reagent must be { itemID, quantity }"
				end
			end
		end
		local skill = recipe.skill
		if skill ~= nil then
			local valid = type(skill) == "table" and #skill == 4
			for k = 1, 4 do
				if not valid or type(skill[k]) ~= "number" or (k > 1 and skill[k] < skill[k - 1]) then valid = false end
			end
			if not valid then
				errors[#errors + 1] = recipeWhere .. ": 'skill' must be { orange, yellow, green, grey } in rising order"
			end
		end
		if recipe.skill and not (recipe.verified and recipe.verified.skill) then
			warnings[#warnings + 1] = recipeWhere .. ": skill levels are an unverified fallback"
		end
		CheckVerified(recipe.verified, recipeWhere, errors)
	end

	return #errors == 0, errors, warnings
end

------------------------------------------------------------------------
-- Registry
------------------------------------------------------------------------

local professions = {}     -- [professionKey] = merged data
local packs = {}           -- [packID] = original pack

local function Merge(pack)
	local merged = professions[pack.profession]
	if not merged then
		merged = {
			profession = pack.profession, name = pack.name, skillLine = pack.skillLine,
			ranks = {}, trainers = {}, items = {}, recipes = {}, recipeByID = {}, packs = {},
		}
		professions[pack.profession] = merged
	end
	merged.skillLine = merged.skillLine or pack.skillLine
	merged.packs[#merged.packs + 1] = pack.id
	if pack.ranks and #pack.ranks > 0 then merged.ranks = pack.ranks end
	for _, trainer in ipairs(pack.trainers or {}) do merged.trainers[#merged.trainers + 1] = trainer end
	for itemID, item in pairs(pack.items or {}) do merged.items[itemID] = item end
	for _, recipe in ipairs(pack.recipes) do
		local existing = merged.recipeByID[recipe.id]
		recipe.profession = pack.profession
		recipe.pack = pack.id
		if existing then
			for i, r in ipairs(merged.recipes) do
				if r.id == recipe.id then merged.recipes[i] = recipe end
			end
		else
			merged.recipes[#merged.recipes + 1] = recipe
		end
		merged.recipeByID[recipe.id] = recipe
	end
end

function FL:RegisterProfessionData(pack)
	local ok, errors, warnings = ProfessionData.Validate(pack)
	if not ok then
		for _, message in ipairs(errors) do
			self:Print("|cffff5555profession data rejected|r", message)
		end
		return false, errors
	end
	for _, message in ipairs(warnings) do
		self:Debug("profession data warning:", message)
	end
	packs[pack.id] = pack
	Merge(pack)
	self:Fire("PROFESSION_DATA_CHANGED", pack.profession)
	return true
end

function FL:GetProfessionData(key)
	return professions[key]
end

function FL:GetAllProfessionData()
	local list = {}
	for _, data in pairs(professions) do list[#list + 1] = data end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

function FL:GetProfessionDataBySkillLine(skillLine)
	if not skillLine then return nil end
	for _, data in pairs(professions) do
		if data.skillLine == skillLine then return data end
	end
end

function FL:GetProfessionDataByName(name)
	if not name then return nil end
	for _, data in pairs(professions) do
		if data.name == name then return data end
	end
end

function FL:GetRecipe(recipeID)
	for _, data in pairs(professions) do
		if data.recipeByID[recipeID] then return data.recipeByID[recipeID], data end
	end
end

-- Recipe that creates an item, within one profession (used to expand intermediates
-- such as Bolt of Linen Cloth into Linen Cloth).
function FL:GetRecipeCreating(itemID, professionKey)
	local data = professions[professionKey]
	if not data then return nil end
	for _, recipe in ipairs(data.recipes) do
		if recipe.creates == itemID then return recipe end
	end
end

-- Item name: client first (when cached), then pack data, then a placeholder.
function FL:GetItemName(itemID)
	if C_Item and C_Item.GetItemNameByID then
		local name = C_Item.GetItemNameByID(itemID)
		if name and name ~= "" and not FL.IsSecret(name) then return name end
	end
	for _, data in pairs(professions) do
		if data.items[itemID] then return data.items[itemID].name end
	end
	return "Item #" .. itemID
end

function FL:GetItemInfoData(itemID)
	for _, data in pairs(professions) do
		if data.items[itemID] then return data.items[itemID] end
	end
end

return ProfessionData

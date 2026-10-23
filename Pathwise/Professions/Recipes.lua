-- Pathwise recipes: one place for what is known about each recipe, whoever
-- knows it. Three sources feed it:
--   * the profession routes (Routes/Professions.lua): every "craft" goal's
--     recipe, the item it makes and its reagents;
--   * profession data packs, registered with Pathwise.RegisterProfessionData
--     (Pathwise's checked starter data in Guides/Professions, and community
--     packs): skill levels, where a recipe is learned, ranks, trainers, items,
--     each fact marked checked or not;
--   * the game: reagents read from the open profession window (cached for the
--     account), and per character which recipes are learned and their colour
--     (Professions.lua).
-- Where they differ, the game wins, then a pack's checked facts, then the
-- route, then a pack's unchecked facts. The planner, the dashboard and the
-- detours all read recipes from here.
--
-- The pack format is in docs/PROFESSION_DATA_FORMAT.md. Validation is plain
-- Lua so tools/validate_routes.lua runs it offline.

local ADDON, ns = ...
local R = {}
ns.Recipes = R

R.API_VERSION = 1

local function isID(v) return type(v) == "number" and v > 0 and v == math.floor(v) end

local function checkVerified(verified, where, errors)
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

---------------------------------------------------------------------------
-- Validating a pack: -> ok, errors, warnings
---------------------------------------------------------------------------

function R.Validate(pack)
	local errors, warnings = {}, {}
	if type(pack) ~= "table" then return false, { "profession data must be a table" }, warnings end
	local where = "profession pack " .. tostring(pack.id)

	if type(pack.id) ~= "string" or not pack.id:match("^[%w%._%-]+$") then
		errors[#errors + 1] = where .. ": 'id' must be letters, digits, '.', '_' or '-'"
	end
	if type(pack.profession) ~= "string" or not pack.profession:match("^[a-z][a-z_%-]*$") then
		errors[#errors + 1] = where .. ": 'profession' must be a lowercase key such as 'tailoring'"
	end
	for _, field in ipairs({ "name", "author", "license" }) do
		if type(pack[field]) ~= "string" or pack[field] == "" then
			errors[#errors + 1] = where .. ": '" .. field .. "' is required"
		end
	end
	if pack.skillLine ~= nil and not isID(pack.skillLine) then
		errors[#errors + 1] = where .. ": 'skillLine' must be a skill line ID"
	end
	if pack.apiVersion ~= nil and (type(pack.apiVersion) ~= "number" or pack.apiVersion > R.API_VERSION) then
		errors[#errors + 1] = where .. ": requires profession data API version " .. tostring(pack.apiVersion)
	end

	for i, rank in ipairs(pack.ranks or {}) do
		local w = where .. " rank " .. i
		if type(rank.name) ~= "string" then errors[#errors + 1] = w .. ": 'name' is required" end
		for _, field in ipairs({ "trainAt", "maxSkill" }) do
			if type(rank[field]) ~= "number" then errors[#errors + 1] = w .. ": '" .. field .. "' must be a number" end
		end
		if rank.level ~= nil and type(rank.level) ~= "number" then errors[#errors + 1] = w .. ": 'level' must be a number" end
		checkVerified(rank.verified, w, errors)
	end

	for i, trainer in ipairs(pack.trainers or {}) do
		local w = where .. " trainer " .. i
		if type(trainer.name) ~= "string" then errors[#errors + 1] = w .. ": 'name' is required" end
		if (trainer.x == nil) ~= (trainer.y == nil) then errors[#errors + 1] = w .. ": 'x' and 'y' must be given together" end
		for _, axis in ipairs({ "x", "y" }) do
			local v = trainer[axis]
			if v ~= nil and (type(v) ~= "number" or v < 0 or v > 100) then errors[#errors + 1] = w .. ": '" .. axis .. "' must be 0-100" end
		end
		if trainer.x and not trainer.map then errors[#errors + 1] = w .. ": coordinates need 'map' (a map id)" end
		checkVerified(trainer.verified, w, errors)
	end

	for itemID, item in pairs(pack.items or {}) do
		if not isID(itemID) or type(item) ~= "table" or type(item.name) ~= "string" then
			errors[#errors + 1] = where .. ": items must be [itemID] = { name = ... }"
		else
			checkVerified(item.verified, where .. " item " .. itemID, errors)
		end
	end

	if type(pack.recipes) ~= "table" or #pack.recipes == 0 then
		errors[#errors + 1] = where .. ": 'recipes' must be a non-empty list"
		return #errors == 0, errors, warnings
	end
	local seen = {}
	for i, recipe in ipairs(pack.recipes) do
		local w = where .. " recipe " .. i
		if not isID(recipe.id) then
			errors[#errors + 1] = w .. ": 'id' must be the recipe (spell) ID"
		elseif seen[recipe.id] then
			errors[#errors + 1] = w .. ": duplicate recipe id " .. recipe.id
		else
			seen[recipe.id] = true
		end
		if type(recipe.name) ~= "string" then errors[#errors + 1] = w .. ": 'name' is required" end
		if recipe.creates ~= nil and not isID(recipe.creates) then errors[#errors + 1] = w .. ": 'creates' must be an item ID" end
		if type(recipe.reagents) ~= "table" or #recipe.reagents == 0 then
			errors[#errors + 1] = w .. ": 'reagents' must list { itemID, quantity } pairs"
		else
			for _, reagent in ipairs(recipe.reagents) do
				if type(reagent) ~= "table" or not isID(reagent[1]) or not isID(reagent[2]) then
					errors[#errors + 1] = w .. ": each reagent must be { itemID, quantity }"
				end
			end
		end
		local skill = recipe.skill
		if skill ~= nil then
			local valid = type(skill) == "table" and #skill == 4
			for k = 1, 4 do
				if not valid or type(skill[k]) ~= "number" or (k > 1 and skill[k] < skill[k - 1]) then valid = false end
			end
			if not valid then errors[#errors + 1] = w .. ": 'skill' must be { orange, yellow, green, grey } in rising order" end
		end
		if recipe.skill and not (recipe.verified and recipe.verified.skill) then
			warnings[#warnings + 1] = w .. ": skill levels are an unverified fallback"
		end
		checkVerified(recipe.verified, w, errors)
	end
	return #errors == 0, errors, warnings
end

---------------------------------------------------------------------------
-- Packs
---------------------------------------------------------------------------

local packs, packOrder = {}, {}
local book -- built on first use: [spell] = recipe; rebuilt when a source changes
local bookRoutes = -1

-- Pathwise.RegisterProfessionData(pack), also as Pathwise:RegisterProfessionData(pack).
-- -> true, or false and the problems
function Pathwise.RegisterProfessionData(a, b)
	local pack = a == Pathwise and b or a
	local ok, errors = R.Validate(pack)
	if not ok then
		for _, message in ipairs(errors) do ns.Error("profession data " .. tostring(type(pack) == "table" and pack.id), message) end
		return false, errors
	end
	if not packs[pack.id] then packOrder[#packOrder + 1] = pack.id end
	packs[pack.id] = pack
	book = nil
	ns.Fire("PROFESSION_DATA_CHANGED", pack.profession)
	return true
end

function R.Pack(id) return packs[id] end
function R.Packs()
	local out = {}
	for _, id in ipairs(packOrder) do out[#out + 1] = packs[id] end
	return out
end

-- A pack's skill line: given, or its profession's (Professions.LIST).
local function lineOf(pack)
	if pack.skillLine then return pack.skillLine end
	local P = ns.Professions
	local key = pack.profession:gsub("_", "-")
	local p = P and P.BY_KEY and P.BY_KEY[key]
	return p and p.line or nil
end

-- What the packs say about a profession, merged in registration order (later
-- packs replace ranks; trainers and items add up): { ranks, trainers, items, packs }.
function R.Data(line)
	local out = { ranks = {}, trainers = {}, items = {}, packs = {} }
	for _, pack in ipairs(R.Packs()) do
		if lineOf(pack) == line then
			out.packs[#out.packs + 1] = pack.id
			if pack.ranks and #pack.ranks > 0 then out.ranks = pack.ranks end
			for _, t in ipairs(pack.trainers or {}) do out.trainers[#out.trainers + 1] = t end
			for id, item in pairs(pack.items or {}) do out.items[id] = item end
		end
	end
	return out
end

---------------------------------------------------------------------------
-- The recipe book
---------------------------------------------------------------------------

local function routeCount()
	return ns.Engine and ns.Engine.routeCount or 0
end

local taught -- [line] = { spell, ... }: recipes the routes craft or teach

-- A profession route's skill line: its first train, skill or craft goal's.
local function routeLine(route)
	for _, step in ipairs(route.steps) do
		for _, g in ipairs(step) do
			if g[1] == "train" or g[1] == "skill" then return g[2] end
			if g[1] == "craft" and g.skillLine then return g.skillLine end
		end
	end
end

local function build()
	book, taught = {}, {}
	-- Routes first: every craft goal of the profession routes.
	local E = ns.Engine
	for _, route in ipairs(E and E.Routes() or {}) do
		if route.category == "Professions" then
			local line = routeLine(route)
			for _, step in ipairs(route.steps) do
				for _, g in ipairs(step) do
					if line and (g[1] == "craft" or g[1] == "learn") and isID(g[2]) then
						taught[line] = taught[line] or {}
						taught[line][g[2]] = true
					end
					if g[1] == "craft" and isID(g[2]) and not book[g[2]] then
						local reagents = {}
						for _, r in ipairs(g.reagents or {}) do reagents[#reagents + 1] = { r[1], r[2] } end
						book[g[2]] = { id = g[2], name = g.name, line = g.skillLine, creates = g.item,
							routeReagents = #reagents > 0 and reagents or nil, route = route.id }
					end
				end
			end
		end
	end
	-- Then the packs, later ones over earlier ones.
	for _, pack in ipairs(R.Packs()) do
		local line = lineOf(pack)
		for _, r in ipairs(pack.recipes) do
			local rec = book[r.id] or { id = r.id }
			book[r.id] = rec
			rec.name = r.name or rec.name
			rec.line = rec.line or line
			rec.creates = r.creates or rec.creates
			rec.packReagents, rec.packVerified = r.reagents, r.verified and r.verified.reagents or false
			if r.skill then rec.skill, rec.skillVerified = r.skill, (r.verified and r.verified.skill) == true end
			rec.source, rec.kind, rec.pack = r.source or rec.source, r.kind or rec.kind, pack.id
		end
	end
	bookRoutes = routeCount()
end

local function current()
	if not book or bookRoutes ~= routeCount() then build() end
	return book
end

function R.Get(spell) return current()[spell] end

-- Every recipe of a skill line, by name.
function R.ForLine(line)
	local out = {}
	for _, r in pairs(current()) do if r.line == line then out[#out + 1] = r end end
	table.sort(out, function(a, b) return (a.name or "") < (b.name or "") end)
	return out
end

-- Every recipe id Pathwise knows for a skill line: the packs' and those the
-- routes craft or teach. Forever's client has no call that lists a
-- profession's recipes (GetAllRecipeIDs is not in its TradeSkillUI), so the
-- window scan asks about these one by one.
function R.KnownIDs(line)
	local set = {}
	for _, r in ipairs(R.ForLine(line)) do set[r.id] = true end
	for id in pairs(taught[line] or {}) do set[id] = true end
	local out = {}
	for id in pairs(set) do out[#out + 1] = id end
	table.sort(out)
	return out
end

-- The recipe of a skill line that makes an item (Bolt of Linen Cloth from
-- Linen Cloth), for working out intermediates.
function R.Creating(item, line)
	for _, r in pairs(current()) do
		if r.creates == item and (not line or r.line == line) then return r end
	end
end

-- Reagents read from the profession window, for the whole account:
-- [spell] = { reagents = { { item, count } }, build }.
local function schematics()
	local s = ns.Get("professions.schematics")
	if type(s) ~= "table" then
		s = {}
		ns.Set("professions.schematics", s)
	end
	return s
end
R.Schematics = schematics

-- The reagents to plan with and where they come from:
-- "client" (the profession window), "source" (a pack's checked facts),
-- "route" (the profession route) or "unverified" (a pack's unchecked facts).
function R.Reagents(recipe)
	local client = schematics()[recipe.id]
	if client and client.reagents and #client.reagents > 0 then return client.reagents, "client" end
	if recipe.packReagents and recipe.packVerified then return recipe.packReagents, "source" end
	if recipe.routeReagents then return recipe.routeReagents, "route" end
	if recipe.packReagents then return recipe.packReagents, "unverified" end
	return {}, "unknown"
end

-- An item's name: the game's when it has it, then a pack's, then the data's.
function R.ItemName(item)
	local fn = C_Item and C_Item.GetItemNameByID
	local name = fn and ns.Compat.Readable(fn(item))
	if type(name) == "string" and name ~= "" then return name end
	for _, pack in ipairs(R.Packs()) do
		if pack.items and pack.items[item] then return pack.items[item].name end
	end
	local d = ns.Quests and ns.Quests.Data.items[item]
	return d and d[1] or ("Item #" .. tostring(item))
end

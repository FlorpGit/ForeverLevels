-- Pathwise professions: what the dashboard shows, read from the profession
-- routes (Routes/Professions.lua) and the game.
--
--   P.Known()            the character's professions: { { prof, rank, cap }, ... }
--   P.Stage(prof)        where the route stands: { first, last, rankMax, step }
--   P.Shopping(prof)     materials still to get for this rank
--   P.NextCraft(prof)    the route's next craft and how many the bags make
--   P.Disenchantable()   green to epic gear in the bags, with the skill it asks
--   P.TailorEnchant()    for Tailoring + Enchanting: crafts to disenchant
--   P.Scan()             reads the open profession window (learned, colour, reagents)
--   P.Shown(prof)        whether a profession takes part in detours and reminders
-- Recipes (Recipes.lua) and the planner (Planner.lua) build on this; the
-- detours (Detours.lua) and the dashboard (UI/Panels.lua) read all three.
-- It only advises: it never crafts, buys, sells or disenchants.
--
-- Client APIs (all through pcall; checked against Blizzard's Forever UI
-- source; the recipe list is NOT verified in game yet):
--   C_TradeSkillUI.GetBaseProfessionInfo, GetAllRecipeIDs / GetFilteredRecipeIDs,
--   GetRecipeInfo (learned, relativeDifficulty, numSkillUps), GetRecipeSchematic
--   (reagentSlotSchematics), C_Container.GetContainerNumSlots,
--   GetContainerItemInfo, C_Item.GetItemInfo (quality 3rd, level 4th, sell 11th, class 12th).

local ADDON, ns = ...
local C = ns.Compat
local P = {}
ns.Professions = P
Pathwise.Professions = P

-- Skill lines (SkillLine.db2 ids) and their routes.
P.LIST = {
	{ key = "alchemy", line = 171, name = "Alchemy", kind = "craft" },
	{ key = "blacksmithing", line = 164, name = "Blacksmithing", kind = "craft" },
	{ key = "enchanting", line = 333, name = "Enchanting", kind = "craft" },
	{ key = "engineering", line = 202, name = "Engineering", kind = "craft" },
	{ key = "leatherworking", line = 165, name = "Leatherworking", kind = "craft" },
	{ key = "tailoring", line = 197, name = "Tailoring", kind = "craft" },
	{ key = "herbalism", line = 182, name = "Herbalism", kind = "gather" },
	{ key = "mining", line = 186, name = "Mining", kind = "gather" },
	{ key = "skinning", line = 393, name = "Skinning", kind = "gather" },
	{ key = "cooking", line = 185, name = "Cooking", kind = "craft" },
	{ key = "first-aid", line = 129, name = "First Aid", kind = "craft" },
	{ key = "fishing", line = 356, name = "Fishing", kind = "gather" },
}
P.BY_LINE, P.BY_KEY = {}, {}
for _, p in ipairs(P.LIST) do
	p.route = "forever/professions/" .. p.key
	P.BY_LINE[p.line], P.BY_KEY[p.key] = p, p
end
local TAILORING, ENCHANTING = 197, 333

ns.Defaults("professions", {
	includeBank = true, -- count materials in the bank too
	reminders = true, -- a line in chat when the bags newly make the next craft
})

local function count(item) return C.ItemCount(item, ns.Get("professions.includeBank")) end
P.Count = count

-- Professions the player hid from detours and reminders (the dashboard
-- still lists them): PathwiseCharSettings, per character.
local function hidden()
	local c = ns.CharState()
	c.professionsHidden = type(c.professionsHidden) == "table" and c.professionsHidden or {}
	return c.professionsHidden
end
function P.Shown(prof) return not hidden()[prof.key] end
function P.SetShown(prof, on)
	hidden()[prof.key] = not on or nil
	ns.Fire("PROFESSIONS_CHANGED")
end

function P.Known()
	local out = {}
	for _, p in ipairs(P.LIST) do
		local rank, cap = C.SkillRank(p.line)
		if rank then out[#out + 1] = { prof = p, rank = rank, cap = cap or 0 } end
	end
	return out
end

function P.Route(prof)
	return ns.Engine and ns.Engine.routes[prof.route] or nil
end

-- A step's training goal, or nil.
local function trainOf(step)
	for _, g in ipairs(step) do if g[1] == "train" then return g end end
end

-- The route cut at its training steps; the stage holding the first open step.
-- -> { first, last, rankMax, step } or nil (route done, or no route).
function P.Stage(prof)
	local route = P.Route(prof)
	if not route then return nil end
	local step = ns.Engine.FirstOpen(route)
	if not step then return nil end
	local first = step
	while first > 1 and not trainOf(route.steps[first]) do first = first - 1 end
	local last = step
	while route.steps[last + 1] and not trainOf(route.steps[last + 1]) do last = last + 1 end
	local t = trainOf(route.steps[first])
	return { first = first, last = last, rankMax = t and t[3], step = step, route = route }
end

local function itemName(item, given)
	if given then return given end
	local d = ns.Quests.Data.items[item]
	if d then return d[1] end
	local fn = C_Item and C_Item.GetItemNameByID
	return fn and C.Readable(fn(item)) or ("item " .. item)
end

-- The nearest place a "have" goal names (a vendor, or a farm spot's mobs).
local function whereOf(goal)
	local place = ns.Engine.PlaceOf(goal)
	return place and place.name or nil
end

-- Materials still to get from the route's open step to the end of the rank:
-- { { item, name, need, have, missing, src, where }, ... }, missing first.
-- A route asks for totals ("have 192 Linen Cloth"), so an item's need is the
-- largest count still open for it.
function P.Shopping(prof)
	local st = P.Stage(prof)
	if not st then return {} end
	local rows, byItem = {}, {}
	for s = st.step, st.last do
		local step = st.route.steps[s]
		for g, goal in ipairs(step) do
			if goal[1] == "have" and ns.Engine.GoalStatus(st.route, s, g, goal) ~= "na" then
				local item, need = goal[2], goal[3] or 1
				local row = byItem[item]
				if not row then
					row = { item = item, name = itemName(item, goal.name), need = 0, src = goal.src, where = whereOf(goal) }
					byItem[item] = row
					rows[#rows + 1] = row
				end
				if need > row.need then row.need = need end
			end
		end
	end
	for _, r in ipairs(rows) do
		r.have = count(r.item)
		r.missing = math.max(0, r.need - r.have)
	end
	table.sort(rows, function(a, b)
		if (a.missing > 0) ~= (b.missing > 0) then return a.missing > 0 end
		return a.name < b.name
	end)
	return rows
end

---------------------------------------------------------------------------
-- Recipes the profession window shows (kept per character)
---------------------------------------------------------------------------

local function store()
	local c = ns.CharState()
	c.professions = type(c.professions) == "table" and c.professions or {}
	local p = c.professions
	p.recipes = type(p.recipes) == "table" and p.recipes or {}
	return p
end

local function call(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, a = pcall(fn, ...)
	return ok and a or nil
end

-- A recipe's reagents as the profession window lists them: { { item, count } }.
local function schematic(T, id)
	local s = call(T.GetRecipeSchematic, id, false)
	if type(s) ~= "table" or type(s.reagentSlotSchematics) ~= "table" then return nil end
	local out = {}
	for _, slot in ipairs(s.reagentSlotSchematics) do
		local first = slot.reagents and slot.reagents[1]
		if slot.required ~= false and first and first.itemID and slot.quantityRequired then
			out[#out + 1] = { first.itemID, slot.quantityRequired }
		end
	end
	return #out > 0 and out or nil
end

-- Reads the open profession window: every recipe's name, whether it is
-- learned and its colour (at the skill it was read at), and the reagents of
-- the recipes Pathwise knows (kept for the account). Only the open
-- profession is read, so a closed one is never marked unlearned. -> skill line or nil.
function P.Scan()
	local T = C_TradeSkillUI
	if not (T and T.GetBaseProfessionInfo and T.GetRecipeInfo) then return nil end
	local info = call(T.GetBaseProfessionInfo)
	if type(info) ~= "table" then return nil end
	local prof = P.BY_LINE[C.Readable(info.professionID)]
	if not prof and type(info.professionName) == "string" then
		local want = info.professionName:lower()
		for _, p in ipairs(P.LIST) do if p.name:lower() == want then prof = p end end
	end
	if not prof then return nil end
	local ids = call(T.GetAllRecipeIDs) or call(T.GetFilteredRecipeIDs)
	if type(ids) ~= "table" or #ids == 0 then return nil end
	local rank = C.SkillRank(prof.line)
	local recipes = {}
	local cache = ns.Recipes and ns.Recipes.Schematics()
	local build = GetBuildInfo and select(2, GetBuildInfo()) or nil
	for _, id in ipairs(ids) do
		local r = call(T.GetRecipeInfo, id)
		if type(r) == "table" then
			recipes[id] = { name = r.name, learned = r.learned and true or false, difficulty = r.relativeDifficulty,
				atRank = rank, skillUps = r.numSkillUps }
			if cache and T.GetRecipeSchematic and ns.Recipes.Get(id) then
				local reagents = schematic(T, id)
				if reagents then cache[id] = { reagents = reagents, build = build } end
			end
		end
	end
	store().recipes[prof.line] = recipes
	ns.Fire("PROFESSIONS_CHANGED")
	return prof.line
end

function P.Recipes(line) return store().recipes[line] end

-- What the window said about one recipe, or nil (never read).
function P.RecipeState(line, spell)
	local list = line and store().recipes[line]
	return list and list[spell] or nil
end

-- relativeDifficulty (Enum.TradeskillRelativeDifficulty): 0 optimal (orange),
-- 1 medium (yellow), 2 easy (green), 3 trivial (grey).
local DIFFICULTY = { [0] = "orange", [1] = "yellow", [2] = "green", [3] = "grey" }

-- The route's next craft in this rank, and how many the bags make:
-- { name, spell, untilSkill, count, craftable, difficulty, known, reagents,
--   reagentsFrom, step, goal } or nil. The planner adds the numbers.
function P.NextCraft(prof)
	local st = P.Stage(prof)
	if not st then return nil end
	for s = st.step, st.last do
		local step = st.route.steps[s]
		for g, goal in ipairs(step) do
			if goal[1] == "craft" and ns.Engine.GoalStatus(st.route, s, g, goal) == "open" then
				-- The reagents to count: the window's, a pack's or the route's (Recipes.lua).
				local book = ns.Recipes and ns.Recipes.Get(goal[2])
				local reagents, from = goal.reagents or {}, "route"
				if book then reagents, from = ns.Recipes.Reagents(book) end
				local craftable
				for _, r in ipairs(reagents) do
					local n = math.floor(count(r[1]) / (r[2] or 1))
					craftable = craftable and math.min(craftable, n) or n
				end
				local scanned = P.RecipeState(prof.line, goal[2])
				return {
					name = goal.name, spell = goal[2], untilSkill = goal.untilSkill, count = goal.count,
					craftable = craftable, reagents = reagents, reagentsFrom = from,
					difficulty = scanned and DIFFICULTY[scanned.difficulty],
					known = scanned and scanned.learned or C.SpellKnown(goal[2]),
					step = s, goal = goal,
				}
			end
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- Disenchanting and Tailoring + Enchanting
---------------------------------------------------------------------------

-- An item's facts from the client's cache, or nil while it is not cached.
function P.ItemFacts(item)
	local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
	if not fn then return nil end
	local ok, name, _, quality, ilvl, _, _, _, _, _, _, sell, classID = pcall(fn, item)
	if not ok or not name then return nil end
	return { name = name, quality = quality, ilvl = ilvl, sell = sell or 0, classID = classID }
end

-- The Enchanting skill an uncommon item asks, by item level: the Classic
-- table, NOT verified on Forever. The dashboard marks it with ≈.
P.DE_SKILL_VERIFIED = false
local DE_SKILL = { { 20, 1 }, { 25, 25 }, { 30, 50 }, { 35, 75 }, { 40, 100 }, { 45, 125 }, { 50, 150 }, { 55, 175 }, { 60, 200 }, { 65, 225 } }
function P.DisenchantSkill(ilvl)
	if type(ilvl) ~= "number" then return nil end
	for _, row in ipairs(DE_SKILL) do if ilvl <= row[1] then return row[2] end end
	return 250
end

local WEAPON, ARMOR = 2, 4

-- Uncommon to epic weapons and armour in the bags.
-- -> { { item, name, quality, ilvl, sell, skill, canNow }, ... }, highest level first.
function P.Disenchantable(skill)
	local out = {}
	local Cn = C_Container
	if not (Cn and Cn.GetContainerNumSlots and Cn.GetContainerItemInfo) then return out end
	for bag = 0, 4 do
		for slot = 1, call(Cn.GetContainerNumSlots, bag) or 0 do
			local info = call(Cn.GetContainerItemInfo, bag, slot)
			local q = info and C.Readable(info.quality)
			if info and info.itemID and q and q >= 2 and q <= 4 then
				local f = P.ItemFacts(info.itemID)
				if f and (f.classID == WEAPON or f.classID == ARMOR) then
					local need = P.DisenchantSkill(f.ilvl)
					out[#out + 1] = { item = info.itemID, name = f.name, quality = q, ilvl = f.ilvl, sell = f.sell,
						skill = need, canNow = need ~= nil and (skill or 0) >= need }
				end
			end
		end
	end
	table.sort(out, function(a, b) return (a.ilvl or 0) > (b.ilvl or 0) end)
	return out
end

-- For a character with Tailoring and Enchanting: the Tailoring crafts of the
-- current rank that make uncommon (green) items, worth disenchanting for
-- Enchanting instead of selling. -> { names } or nil.
function P.TailorEnchant()
	if not (C.SkillRank(TAILORING) and C.SkillRank(ENCHANTING)) then return nil end
	local st = P.Stage(P.BY_LINE[TAILORING])
	if not st then return {} end
	local names, seen = {}, {}
	for s = st.step, st.last do
		for _, goal in ipairs(st.route.steps[s]) do
			if goal[1] == "craft" and goal.item and not seen[goal.item] then
				seen[goal.item] = true
				local f = P.ItemFacts(goal.item)
				if f and f.quality == 2 then names[#names + 1] = goal.name or f.name end
			end
		end
	end
	return names
end

-- Whether Enchanting's rank still needs materials that come from
-- disenchanting (not sold by vendors): then disenchanting beats selling.
function P.EnchantingNeedsDust()
	local ench = P.BY_LINE[ENCHANTING]
	if not C.SkillRank(ENCHANTING) then return false end
	for _, row in ipairs(P.Shopping(ench)) do
		if row.missing > 0 and row.src ~= "vendor" then return true, row end
	end
	return false
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local function scan() if P.Scan() then return end end
ns.RegisterEvent("TRADE_SKILL_SHOW", scan)
ns.RegisterEvent("TRADE_SKILL_LIST_UPDATE", scan)
-- A recipe learned (from a trainer or a recipe item) is known at once.
ns.RegisterEvent("NEW_RECIPE_LEARNED", function(_, spell)
	spell = C.Readable(spell)
	local recipe = spell and ns.Recipes and ns.Recipes.Get(spell)
	if not (recipe and recipe.line) then return end
	local list = store().recipes[recipe.line] or {}
	store().recipes[recipe.line] = list
	list[spell] = list[spell] or { name = recipe.name }
	list[spell].learned = true
end)
for _, ev in ipairs({ "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED", "NEW_RECIPE_LEARNED", "CHAT_MSG_SKILL" }) do
	ns.RegisterEvent(ev, function() ns.Fire("PROFESSIONS_CHANGED") end)
end

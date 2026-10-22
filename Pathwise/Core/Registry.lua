-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: route and dungeon registry.
-- This is the public extension point: any addon that depends on ForeverLevels can call
--   ForeverLevels:RegisterRoute({ ... })
-- at file load time. See docs/ROUTE_FORMAT.md and examples/Pathwise_ExampleRoute.

local _, FL = ...

local routes = {}
local routeOrder = {}
local dungeons = {}

function FL:RegisterRoute(route)
	local ok, errors, warnings = FL.Validator.ValidateRoute(route)
	if not ok then
		for _, message in ipairs(errors) do
			self:Print("|cffff5555route rejected|r", message)
		end
		return false, errors
	end
	for _, message in ipairs(warnings) do
		self:Debug("route warning:", message)
	end

	if routes[route.id] then
		self:Print("|cffffaa00route replaced|r", route.id)
	else
		routeOrder[#routeOrder + 1] = route.id
	end

	route.quests = route.quests or {}
	routes[route.id] = route
	self:Fire("ROUTES_CHANGED", route.id)
	return true
end

function FL:GetRoute(id)
	return routes[id]
end

-- Returns routes in registration order.
function FL:GetRoutes()
	local list = {}
	for _, id in ipairs(routeOrder) do
		list[#list + 1] = routes[id]
	end
	return list
end

local function Contains(list, value)
	if not list then return true end
	for _, entry in ipairs(list) do
		if entry == value then return true end
	end
	return false
end
FL.Contains = Contains

function FL:RouteFitsPlayer(route, player)
	if route.faction and route.faction ~= player.faction then return false end
	if not Contains(route.races, player.race) then return false end
	if not Contains(route.classes, player.class) then return false end
	return true
end

-- Picks the best route for the player's faction, race, class and level.
-- Race-specific routes beat generic ones; a route that starts at or below the
-- player's level and still covers it beats one that only overlaps.
function FL:FindRouteFor(player)
	local best, bestScore
	for _, route in ipairs(self:GetRoutes()) do
		if self:RouteFitsPlayer(route, player) and not route.hidden then
			local minLevel, maxLevel = route.levels[1], route.levels[2]
			if player.level >= minLevel and player.level <= maxLevel then
				local score = 0
				if route.races then score = score + 10 end
				if route.classes then score = score + 5 end
				score = score - (player.level - minLevel) * 0.01
				if not bestScore or score > bestScore then
					best, bestScore = route, score
				end
			end
		end
	end
	return best
end

------------------------------------------------------------------------
-- Dungeons
------------------------------------------------------------------------

function FL:RegisterDungeon(dungeon)
	assert(type(dungeon.id) == "string", "dungeon id required")
	assert(type(dungeon.min) == "number" and type(dungeon.max) == "number", "dungeon level range required")
	dungeons[dungeon.id] = dungeon
end

function FL:GetDungeon(id)
	return dungeons[id]
end

-- Dungeons whose suggested range contains the level, for the player's faction.
function FL:GetDungeonSuggestions(level, faction)
	local list = {}
	for _, dungeon in pairs(dungeons) do
		if level >= dungeon.min and level <= dungeon.max
			and (dungeon.faction == nil or dungeon.faction == faction) then
			list[#list + 1] = dungeon
		end
	end
	table.sort(list, function(a, b) return a.min < b.min end)
	return list
end

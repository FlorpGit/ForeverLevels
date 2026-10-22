-- ForeverLevels: waypoint targets, map resolution and bearing math.
--
-- Two outputs, both optional:
--   * Blizzard's own user waypoint (C_Map.SetUserWaypoint) super-tracked with
--     C_SuperTrack, which drives the client's built-in in-world navigation marker.
--   * FL.Waypoint.target, which UI/Arrow.lua turns into a directional arrow.

local _, FL = ...

local Waypoint = {}
FL.Waypoint = Waypoint

Waypoint.target = nil
Waypoint.ownsUserWaypoint = false

local ZONE_MAP_TYPE = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
local zoneCache

------------------------------------------------------------------------
-- Map resolution. Route files name zones in English ("Tirisfal Glades") and may
-- also give a uiMapID. Forever's uiMapIDs are not publicly documented, so we
-- resolve names at runtime by walking the client's own map tree.
------------------------------------------------------------------------

local function FindRootMap()
	local mapID = C_Map.GetBestMapForUnit("player")
	local guard = 0
	while mapID and guard < 20 do
		local info = C_Map.GetMapInfo(mapID)
		if not info or not info.parentMapID or info.parentMapID == 0 then
			return mapID
		end
		mapID = info.parentMapID
		guard = guard + 1
	end
	return mapID
end

local function BuildZoneCache()
	local root = FindRootMap()
	if not root then return nil end
	local cache = {}
	for _, info in ipairs(C_Map.GetMapChildrenInfo(root, ZONE_MAP_TYPE, true) or {}) do
		if info.name and not FL.IsSecret(info.name) and not cache[info.name] then
			cache[info.name] = info.mapID
		end
	end
	return cache
end

function Waypoint.FindZoneByName(name)
	if not name then return nil end
	if not zoneCache then
		zoneCache = BuildZoneCache()
		if not zoneCache then return nil end
	end
	return zoneCache[name]
end

function Waypoint.ResolveMap(step, route)
	if step.map then return step.map end
	local zone = step.zone or (route and route.zone)
	if route and route.maps and zone and route.maps[zone] then
		return route.maps[zone]
	end
	return Waypoint.FindZoneByName(zone)
end

FL:RegisterEvent("PLAYER_ENTERING_WORLD", function()
	-- Continent changes can make the cache incomplete; rebuild lazily.
	zoneCache = nil
	Waypoint:Update()
end)

------------------------------------------------------------------------
-- Math. World coordinates: x grows north, y grows west (yards).
-- Facing (GetPlayerFacing) is radians counter-clockwise from north, so the
-- bearing to a target is atan2(west, north) in the same convention.
------------------------------------------------------------------------

local atan2 = math.atan2 or math.atan
local TWO_PI = math.pi * 2

function Waypoint.Bearing(px, py, tx, ty)
	local north, west = tx - px, ty - py
	local distance = math.sqrt(north * north + west * west)
	local bearing = atan2(west, north) % TWO_PI
	return bearing, distance
end

-- Angle to rotate an up-pointing arrow so it points at the target.
function Waypoint.RelativeAngle(bearing, facing)
	return (bearing - facing) % TWO_PI
end

local function ToWorld(mapID, x, y)
	local continentID, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
	if not continentID or not world then return nil end
	return continentID, world.x, world.y
end

-- Returns distance (yards) and bearing to the current target, or nil plus a reason.
function Waypoint:GetVector()
	local target = self.target
	if not target then return nil, "none" end

	local playerMap = C_Map.GetBestMapForUnit("player")
	if not playerMap then return nil, "nomap" end
	local position = C_Map.GetPlayerMapPosition(playerMap, "player")
	if not position then return nil, "instance" end
	local px, py = position:GetXY()

	local playerContinent, pwx, pwy = ToWorld(playerMap, px, py)
	local targetContinent, twx, twy = ToWorld(target.mapID, target.x / 100, target.y / 100)
	if not playerContinent or not targetContinent then return nil, "nomap" end
	if playerContinent ~= targetContinent then return nil, "continent" end

	local bearing, distance = Waypoint.Bearing(pwx, pwy, twx, twy)
	return distance, bearing
end

------------------------------------------------------------------------
-- Target management
------------------------------------------------------------------------

local function ClearOwnUserWaypoint()
	if Waypoint.ownsUserWaypoint and C_Map.HasUserWaypoint() then
		C_Map.ClearUserWaypoint()
	end
	Waypoint.ownsUserWaypoint = false
end

local function SetNativeWaypoint(target)
	if not FL.db.profile.nativeWaypoint then
		ClearOwnUserWaypoint()
		return
	end
	if not C_Map.CanSetUserWaypointOnMap(target.mapID) then return end
	C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(target.mapID, target.x / 100, target.y / 100))
	C_SuperTrack.SetSuperTrackedUserWaypoint(true)
	Waypoint.ownsUserWaypoint = true
end

function Waypoint:SetTarget(mapID, x, y, title)
	self.target = { mapID = mapID, x = x, y = y, title = title }
	SetNativeWaypoint(self.target)
	FL:Fire("WAYPOINT_CHANGED", self.target)
end

function Waypoint:Clear()
	self.target = nil
	ClearOwnUserWaypoint()
	FL:Fire("WAYPOINT_CHANGED", nil)
end

-- Points at the current step's coordinates.
function Waypoint:Update()
	local Engine = FL.Engine
	local step = Engine and Engine:GetCurrentStep()
	if not step or not step.x then
		self:Clear()
		return
	end
	local mapID = Waypoint.ResolveMap(step, Engine.route)
	if not mapID then
		FL:Debug("could not resolve map for step", step.id, step.zone or Engine.route.zone)
		self.target = nil
		FL:Fire("WAYPOINT_CHANGED", nil)
		return
	end
	self:SetTarget(mapID, step.x, step.y, step.title)
end

FL:On("STEP_CHANGED", function() Waypoint:Update() end)

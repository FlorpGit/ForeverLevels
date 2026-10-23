-- Pathwise waypoint: the one place the arrow points at. Anything (the guide,
-- a profession detour, /pw way) sets it; the arrow only reads it.
--
-- Pathwise.SetWaypoint(map, x, y, title) / Pathwise.ClearWaypoint()
-- Fires WAYPOINT_CHANGED(target or nil).

local ADDON, ns = ...
local Nav = {}
ns.Nav = Nav

local sqrt, atan2, pi = math.sqrt, math.atan2, math.pi
local TWO_PI = 2 * pi
local YARDS_ARRIVED = 8

local target -- { map, x, y, title, inst, north, west }

-- Angle wrapped into -pi..pi.
local function wrap(a)
	a = a % TWO_PI
	if a > pi then a = a - TWO_PI end
	return a
end
Nav.Wrap = wrap

-- Pure maths, tested: distance in yards and the arrow's rotation (radians,
-- counter-clockwise, 0 = straight ahead) from the player to a point.
-- World coordinates grow north and west; facing is 0 at north, CCW.
function Nav.Direction(pNorth, pWest, facing, tNorth, tWest)
	local dn, dw = tNorth - pNorth, tWest - pWest
	local dist = sqrt(dn * dn + dw * dw)
	local bearing = atan2(dw, dn) -- 0 = north, CCW toward west
	local rotation = facing and wrap(bearing - facing) or nil
	return dist, rotation, bearing
end

---------------------------------------------------------------------------
-- Blizzard's own waypoint: with "arrow.native" on, the target is also the
-- game's user waypoint (its map pin), super-tracked so the game draws its
-- in-world marker and distance. Pathwise only replaces or clears a pin it
-- set itself: a pin the player placed stays until the player removes it,
-- and only then does Pathwise's come back.
-- APIs (MapDocumentation, SuperTrackManagerDocumentation):
--   C_Map.CanSetUserWaypointOnMap, SetUserWaypoint, GetUserWaypoint,
--   HasUserWaypoint, ClearUserWaypoint, UiMapPoint.CreateFromCoordinates,
--   C_SuperTrack.SetSuperTrackedUserWaypoint.
---------------------------------------------------------------------------

ns.Defaults("arrow", { native = true })

local mine -- { map, x, y } (0-1) of the pin Pathwise set, while it is the one shown

-- Whether the game shows a pin, and whether it is the one Pathwise set.
local function pins()
	local M = C_Map
	if not (M and M.HasUserWaypoint and M.HasUserWaypoint()) then return false, false end
	if not (mine and M.GetUserWaypoint) then return true, false end
	local ok, p = pcall(M.GetUserWaypoint)
	if not (ok and type(p) == "table" and p.position) then return true, false end
	local x, y
	if p.position.GetXY then x, y = p.position:GetXY() else x, y = p.position.x, p.position.y end
	local same = p.uiMapID == mine.map and x and y and math.abs(x - mine.x) < 1e-4 and math.abs(y - mine.y) < 1e-4
	return true, same and true or false
end

local function clearNative()
	local shown, ours = pins()
	if shown and ours then pcall(C_Map.ClearUserWaypoint) end
	mine = nil
end

local function setNative(t)
	local M = C_Map
	if not (t and ns.Get("arrow.native") and M and M.SetUserWaypoint and UiMapPoint) then return clearNative() end
	local shown, ours = pins()
	if shown and not ours then mine = nil return end -- the player's own pin: leave it
	if M.CanSetUserWaypointOnMap and not M.CanSetUserWaypointOnMap(t.map) then return clearNative() end
	local x, y = t.x / 100, t.y / 100
	local ok = pcall(function() M.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(t.map, x, y)) end)
	if not ok then return clearNative() end
	mine = { map = t.map, x = x, y = y }
	if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
		pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
	end
end

function Nav.SetTarget(map, x, y, title)
	if not (map and x and y) then return false end
	local inst, north, west = ns.Compat.MapToWorld(map, x, y)
	target = { map = map, x = x, y = y, title = title, inst = inst, north = north, west = west }
	setNative(target)
	ns.Fire("WAYPOINT_CHANGED", target)
	return true
end

function Nav.Clear()
	if not target then return end
	target = nil
	clearNative()
	ns.Fire("WAYPOINT_CHANGED", nil)
end

ns.On("SETTING_CHANGED", function(path)
	if path == "arrow.native" then setNative(target) end
end)

function Nav.Target() return target end

-- The player's relation to the target, for the arrow:
--   "none"      no target
--   "instance"  inside a dungeon or raid: no positions there, the arrow hides
--   "taxi"      on a flight
--   "unknown"   no position for the player or the target
--   "far"       on another continent or instance
--   "arrived"   within YARDS_ARRIVED
--   "travel"    with distance and rotation
function Nav.Sample()
	if not target then return "none" end
	local C = ns.Compat
	if C.InInstance() then return "instance" end
	if C.OnTaxi() then return "taxi" end
	if not target.inst then
		target.inst, target.north, target.west = C.MapToWorld(target.map, target.x, target.y)
		if not target.inst then return "unknown" end
	end
	local inst, north, west = C.PlayerWorldPosition()
	if not inst then return "unknown" end
	if inst ~= target.inst then return "far" end
	local dist, rotation = Nav.Direction(north, west, C.PlayerFacing(), target.north, target.west)
	if dist <= YARDS_ARRIVED then return "arrived", dist end
	return "travel", dist, rotation
end

-- What the arrow sees, as text for bug reports (Waypoint & tools, /pw debug).
function Nav.DebugText()
	local C = ns.Compat
	local function n(v) return v and ("%.1f"):format(v) or "nil" end
	local lines = {}
	local map, x, y = C.PlayerMapPosition()
	lines[#lines + 1] = ("player map %s (%s) at %s, %s"):format(tostring(map), tostring(map and C.MapName(map)), n(x), n(y))
	local inst, north, west = C.PlayerWorldPosition()
	lines[#lines + 1] = ("player world inst %s north %s west %s, facing %s"):format(tostring(inst), n(north), n(west), n(C.PlayerFacing()))
	local t = target
	if t then
		lines[#lines + 1] = ("target %s: map %s at %s, %s -> world inst %s north %s west %s"):format(tostring(t.title), tostring(t.map), n(t.x), n(t.y), tostring(t.inst), n(t.north), n(t.west))
		local state, dist, rot = Nav.Sample()
		lines[#lines + 1] = ("state %s, distance %s yd, rotation %s"):format(tostring(state), n(dist), n(rot))
	else
		lines[#lines + 1] = "no waypoint set"
	end
	lines[#lines + 1] = ("instance %s, taxi %s"):format(tostring(C.InInstance()), tostring(C.OnTaxi()))
	return table.concat(lines, "\n")
end

Pathwise.SetWaypoint = function(map, x, y, title) return Nav.SetTarget(map, x, y, title) end
Pathwise.ClearWaypoint = function() Nav.Clear() end

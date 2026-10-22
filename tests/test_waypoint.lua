-- SPDX-License-Identifier: GPL-3.0-only
local T = ...

local function Near(a, b, eps) return math.abs(a - b) < (eps or 1e-6) end

T.Test("Waypoint: bearing math (0 = north, counter-clockwise)", function()
	local FL = T.Boot()
	local W = FL.Waypoint
	-- World x = north, y = west.
	local north = W.Bearing(0, 0, 10, 0)
	local west = W.Bearing(0, 0, 0, 10)
	local south = W.Bearing(0, 0, -10, 0)
	local east, distance = W.Bearing(0, 0, 0, -10)
	T.True(Near(north, 0), "north = 0, got " .. north)
	T.True(Near(west, math.pi / 2), "west = pi/2, got " .. west)
	T.True(Near(south, math.pi), "south = pi, got " .. south)
	T.True(Near(east, 3 * math.pi / 2), "east = 3pi/2, got " .. east)
	T.True(Near(distance, 10), "distance")
	T.True(Near(W.RelativeAngle(math.pi / 2, math.pi / 2), 0), "facing the target -> 0")
	T.True(Near(W.RelativeAngle(0, math.pi / 2), 3 * math.pi / 2), "target to the right")
end)

T.Test("Waypoint: zone name resolves to a uiMapID through the client's map tree", function()
	local FL = T.Boot()
	T.Equal(FL.Waypoint.FindZoneByName("Tirisfal Glades"), 2001, "resolved")
	T.Equal(FL.Waypoint.FindZoneByName("Nowhere"), nil, "unknown zone")
end)

T.Test("Waypoint: step change places a Blizzard user waypoint and super-tracks it", function()
	local FL = T.Boot()
	local point = T.Stub.userWaypoint
	T.True(point, "user waypoint set")
	T.Equal(point.uiMapID, 2001, "map")
	T.True(Near(point.position.x, 0.302) and Near(point.position.y, 0.716), "coordinates scaled to 0-1")
	T.True(T.Stub.superTracked, "super-tracked")
	T.Equal(FL.Waypoint.target.title, "Wake up", "arrow target title")
end)

T.Test("Waypoint: native waypoint can be turned off and is then cleared", function()
	local FL = T.Boot()
	FL.Options.Set("nativeWaypoint", false)
	T.Equal(T.Stub.userWaypoint, nil, "our waypoint cleared")
	T.True(FL.Waypoint.target, "arrow target kept")
end)

T.Test("Waypoint: vector to target uses world coordinates", function()
	local FL = T.Boot()
	-- Player at 30.2, 66.6 is 50 yards south of Mordo (30.2, 71.6)? No: y grows south,
	-- so 66.6 is north of 71.6. Target is 50 yards south -> bearing pi.
	T.Stub.playerPos = { x = 0.302, y = 0.666 }
	local distance, bearing = FL.Waypoint:GetVector()
	T.True(Near(distance, 50, 1e-3), "distance 50 yd, got " .. tostring(distance))
	T.True(Near(bearing, math.pi, 1e-6), "bearing south, got " .. tostring(bearing))
end)

T.Test("Waypoint: no position (instance) is reported, not an error", function()
	local FL = T.Boot()
	T.Stub.playerPos = nil
	local distance, reason = FL.Waypoint:GetVector()
	T.Equal(distance, nil, "no distance")
	T.Equal(reason, "instance", "reason")
end)

T.Test("Arrow: rotates toward target and hides when facing is unavailable", function()
	local FL = T.Boot()
	T.Stub.playerPos = { x = 0.302, y = 0.666 }
	T.Stub.facing = 0
	T.Stub.Advance(0.2)
	local arrowFrame
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, "arrow") then arrowFrame = frame end
	end
	T.True(arrowFrame, "arrow frame exists")
	T.Equal(arrowFrame.arrow.atlas, "Navigation-Tracked-Arrow", "uses Forever atlas")
	T.True(Near(arrowFrame.arrow.rotation, math.pi, 1e-6), "points behind when target is south and we face north")
	T.Stub.facing = nil
	T.Stub.Advance(0.2)
	T.True(not arrowFrame.arrow.shown, "hidden without facing (instances)")
end)

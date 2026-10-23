-- Tests for the game's own waypoint beside Pathwise's arrow (Nav/Waypoint.lua).
-- Loaded by tests/run.lua. The arrow's maths and states are in tests/run.lua.
local h = ...
local test, eq, ok, near, fresh = h.test, h.eq, h.ok, h.near, h.fresh

local function login()
	local stub, ns = fresh()
	stub.player.level = 2
	stub.moveTo(1420, 30.2, 71.6)
	stub.login()
	return stub, ns
end

local function pin(stub)
	local w = stub.userWaypoint
	if not w then return nil end
	return w.uiMapID, w.position.x, w.position.y
end

test("the game's waypoint: follows the guide's target and is super-tracked", function()
	local stub = login()
	local map, x, y = pin(stub)
	eq(map, 1420, "set at login for the route's first step")
	near(x, 0.3022, 1e-6, "x as 0-1")
	near(y, 0.7165, 1e-6, "y as 0-1")
	eq(stub.superTracked, true)
	stub.accept(363)
	local _, _, y2 = pin(stub)
	near(y2, 0.662, 1e-6, "moved with the step: Shadow Priest Sarvis")
end)

test("the game's waypoint: turned off, Pathwise's is cleared; on, it comes back", function()
	local stub, ns = login()
	SlashCmdList.PATHWISE("waypoint off")
	eq(ns.Get("arrow.native"), false)
	eq(stub.userWaypoint, nil, "cleared")
	ns.Set("arrow.native", true)
	ns.Nav.SetTarget(1420, 40, 40, "Here")
	local _, x = pin(stub)
	near(x, 0.4, 1e-9)
	ns.Nav.Clear()
	eq(stub.userWaypoint, nil, "Pathwise's own: cleared with the target")
end)

test("the game's waypoint: a pin the player placed is never replaced or cleared", function()
	local stub, ns = login()
	ok(stub.userWaypoint, "Pathwise's pin")
	stub.placePin(1420, 0.5, 0.5) -- the player's own
	stub.accept(363) -- the guide moves on
	local map, x, y = pin(stub)
	ok(map == 1420 and x == 0.5 and y == 0.5, "the player's pin stays when the step changes")
	ns.Nav.Clear()
	ok(stub.userWaypoint, "and when the target is cleared")
	stub.userWaypoint = nil -- the player removes it
	ns.Nav.SetTarget(1420, 40, 40, "Here")
	local _, x2 = pin(stub)
	near(x2, 0.4, 1e-9, "then Pathwise's comes back")
end)

test("the game's waypoint: a map it cannot take clears the old one", function()
	local stub, ns = login()
	ok(stub.userWaypoint, "set")
	ns.Nav.SetTarget(9999, 50, 50, "Nowhere")
	eq(stub.userWaypoint, nil, "no stale pin at the old place")
end)

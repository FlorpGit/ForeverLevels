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

test("the game's waypoint: follows the guide's target and is super-tracked", function()
	local stub, ns = login()
	local w = stub.userWaypoint
	ok(w, "set at login for the route's first step")
	eq(w.map, 1420)
	near(w.x, 0.3022, 1e-6, "x as 0-1")
	near(w.y, 0.7165, 1e-6, "y as 0-1")
	eq(stub.superTracked, true)
	stub.accept(363)
	ok(stub.userWaypoint ~= w, "moved with the step")
	near(stub.userWaypoint.y, 0.662, 1e-6, "Shadow Priest Sarvis")
end)

test("the game's waypoint: turned off, Pathwise's is cleared; one it did not set is left alone", function()
	local stub, ns = login()
	SlashCmdList.PATHWISE("waypoint off")
	eq(ns.Get("arrow.native"), false)
	eq(stub.userWaypoint, nil, "cleared")
	stub.userWaypoint = { map = 1420, x = 0.5, y = 0.5 } -- the player's own
	ns.Nav.Clear()
	ok(stub.userWaypoint, "not Pathwise's: kept")
	ns.Set("arrow.native", true)
	ns.Nav.SetTarget(1420, 40, 40, "Here")
	near(stub.userWaypoint.x, 0.4, 1e-9)
	ns.Nav.Clear()
	eq(stub.userWaypoint, nil, "Pathwise's own: cleared with the target")
end)

test("the game's waypoint: a map it cannot take clears the old one", function()
	local stub, ns = login()
	ok(stub.userWaypoint, "set")
	ns.Nav.SetTarget(9999, 50, 50, "Nowhere")
	eq(stub.userWaypoint, nil, "no stale pin at the old place")
end)

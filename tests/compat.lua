-- Tests for what carries over from the ForeverLevels builds: the old names,
-- the old commands, the old way of registering. Loaded by tests/run.lua.
local h = ...
local test, eq, ok, fresh, lastPrint = h.test, h.eq, h.ok, h.fresh, h.lastPrint

test("compat: ForeverLevels and Pathwise are one table; /fl and /foreverlevels run /pw's commands", function()
	local stub, ns = fresh()
	stub.login()
	ok(ForeverLevels == Pathwise, "one table")
	eq(SLASH_PATHWISE3, "/fl")
	eq(SLASH_PATHWISE4, "/foreverlevels")
	SlashCmdList.PATHWISE("where")
	ok(lastPrint(stub):find("Tirisfal Glades"), lastPrint(stub))
end)

test("compat: Pathwise:RegisterRoute works like Pathwise.RegisterRoute; the old format is refused with a pointer", function()
	local stub, ns = fresh()
	stub.login()
	ok(ForeverLevels:RegisterRoute({ id = "test/colon", title = "Colon", levels = { 1, 10 },
		steps = { { { "accept", 363 } } } }), "colon call")
	ok(ns.Engine.routes["test/colon"], "registered")
	ok(not Pathwise:RegisterRoute({ id = "test/old", title = "Old", levels = { 1, 10 },
		steps = { { id = "a", title = "A", x = 30, y = 70, accept = { 363 } } } }), "old format refused")
	ok(lastPrint(stub):find("ForeverLevels route format", 1, true), lastPrint(stub))
end)

test("compat: the example route pack loads", function()
	local stub, ns = fresh()
	stub.login()
	assert(loadfile("examples/Pathwise_ExampleRoute/ExampleRoute.lua"))("Pathwise_ExampleRoute", {})
	local found
	for _, r in ipairs(ns.Engine.Routes()) do if r.id:find("^example/") then found = r end end
	ok(found, "the example route registered")
	eq(#ns.Engine.Check(found), 0, "no problems")
end)

test("compat: Pathwise_Forever.toc (the Forever client's own) and Pathwise.toc are the same", function()
	local a = assert(io.open("Pathwise/Pathwise.toc", "rb")):read("*a")
	local b = assert(io.open("Pathwise/Pathwise_Forever.toc", "rb")):read("*a")
	eq(b, a, "Pathwise_Forever.toc must match Pathwise.toc")
	ok(a:find("## Interface: 16001", 1, true), "the Forever interface")
	local versions = {}
	for _, toc in ipairs({ "Pathwise/Pathwise.toc", "Pathwise_Gear/Pathwise_Gear.toc", "Pathwise_Bags/Pathwise_Bags.toc" }) do
		versions[#versions + 1] = assert(io.open(toc, "rb")):read("*a"):match("## Version: (%S+)")
	end
	eq(versions[2], versions[1], "Gear's version")
	eq(versions[3], versions[1], "Bags' version")
end)

test("compat: a client that is not Forever is warned about at login", function()
	local stub = fresh()
	WOW_PROJECT_ID = 1
	stub.login()
	local warned = false
	for _, m in ipairs(stub.printed) do if m:find("does not report itself as World of Warcraft: Forever", 1, true) then warned = true end end
	WOW_PROJECT_ID = WOW_PROJECT_CAMELOT
	ok(warned)
end)

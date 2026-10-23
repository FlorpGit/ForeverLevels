-- Tests for the recorder (Guide/Recorder.lua) and tools/recorder_to_route.lua.
-- Loaded by tests/run.lua.
local h = ...
local test, eq, ok, fresh = h.test, h.eq, h.ok, h.fresh

local function login()
	local stub, ns = fresh()
	stub.player.level = 2
	stub.moveTo(1420, 30.22, 71.65)
	stub.login()
	return stub, ns
end

test("recorder: off by default; on, it logs quests with their NPC and place, and trainers", function()
	local stub, ns = login()
	stub.npcName = "Undertaker Mordo"
	stub.accept(363)
	eq(#ns.Recorder.Log(), 0, "off by default")
	SlashCmdList.PATHWISE("record on")
	stub.accept(363)
	local e = ns.Recorder.Log()[1]
	eq(e.kind, "accept")
	eq(e.quest, 363)
	eq(e.title, "Rude Awakening")
	eq(e.npc, "Undertaker Mordo")
	eq(e.map, 1420)
	eq(e.x, 30.2)
	eq(e.y, 71.7)
	eq(e.zone, "Tirisfal Glades")
	stub.moveTo(1420, 30.84, 66.2)
	stub.npcName = "Shadow Priest Sarvis"
	stub.turnin(363)
	eq(ns.Recorder.Log()[2].kind, "turnin")
	stub.npcName = "Isabella"
	stub.fire("TRAINER_SHOW")
	eq(ns.Recorder.Log()[3].kind, "trainer")
	eq(ns.Recorder.Log()[3].npc, "Isabella")
	SlashCmdList.PATHWISE("record off")
	stub.accept(364)
	eq(#ns.Recorder.Log(), 3, "off again")
	SlashCmdList.PATHWISE("recorder clear")
	eq(#ns.Recorder.Log(), 0, "cleared")
end)

-- A value as Lua source (for a SavedVariables file).
local function serialize(v)
	if type(v) == "table" then
		local parts = {}
		for k, x in pairs(v) do
			local key = type(k) == "number" and ("[" .. k .. "]") or ("[%q]"):format(k)
			parts[#parts + 1] = key .. " = " .. serialize(x)
		end
		return "{ " .. table.concat(parts, ", ") .. " }"
	end
	if type(v) == "string" then return ("%q"):format(v) end
	return tostring(v)
end

test("recorder: tools/recorder_to_route.lua makes a route the engine accepts", function()
	local stub, ns = login()
	ns.Set("recorder.on", true)
	stub.npcName = "Undertaker Mordo"
	stub.accept(363)
	stub.moveTo(1420, 30.84, 66.2)
	stub.npcName = "Shadow Priest Sarvis"
	stub.turnin(363)
	stub.accept(364)
	local saved = os.tmpname()
	local f = assert(io.open(saved, "w"))
	f:write("PathwiseSettings = ", serialize(PathwiseSettings), "\n")
	f:close()
	local lua = arg and arg[-1] or "lua"
	local cmd = ('"%s" tools/recorder_to_route.lua "%s" test/recorded'):format(lua, saved)
	-- cmd.exe drops the outer quotes of a command that starts with one.
	if package.config:sub(1, 1) == "\\" then cmd = '"' .. cmd .. '"' end
	local p = io.popen(cmd)
	local source = p:read("*a")
	p:close()
	os.remove(saved)
	ok(source:find('{ "accept", 363, at = { 1420, 30.2, 71.7 }, who = "Undertaker Mordo" }', 1, true), source)
	ok(source:find('{ "turnin", 363, at = { 1420, 30.8, 66.2 }, who = "Shadow Priest Sarvis" }, { "accept", 364', 1, true), "same spot, one step")
	local _, ns2 = fresh()
	assert((loadstring or load)(source))() -- Lua 5.1 loads a string with loadstring
	local route = ns2.Engine.routes["test/recorded"]
	ok(route, "registered")
	eq(#route.steps, 2, "two places")
	eq(#ns2.Engine.Check(route), 0, "no problems")
end)

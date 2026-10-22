-- Offline test runner. From the repository root:  lua tests/run.lua
-- Loads the addon exactly in TOC order against tests/wowstub.lua.

local root = (arg and arg[0] or ""):gsub("[/\\]?tests[/\\]run%.lua$", "")
if root == "" then root = "." end
package.path = root .. "/tests/?.lua;" .. package.path

local Stub = require("wowstub")

local ADDON_DIR = root .. "/ForeverLevels"
local ADDON_NAME = "ForeverLevels"

local T = { Stub = Stub, root = root, addonDir = ADDON_DIR }

------------------------------------------------------------------------
-- Loading
------------------------------------------------------------------------

function T.ReadToc(name)
	local files, directives = {}, {}
	local handle = assert(io.open(ADDON_DIR .. "/" .. name, "r"))
	for line in handle:lines() do
		line = line:gsub("\r$", "")
		local key, value = line:match("^##%s*([^:]+):%s*(.*)$")
		if key then
			directives[key] = value
		elseif line:match("%S") and not line:match("^#") then
			files[#files + 1] = (line:gsub("\\", "/"):gsub("%s+$", ""))
		end
	end
	handle:close()
	return files, directives
end

function T.LoadFile(path, namespace)
	local chunk = assert(loadfile(path))
	return chunk(ADDON_NAME, namespace)
end

-- Fresh client + fresh addon instance. opts.player overrides; opts.saved = { db, char }.
function T.Boot(opts)
	opts = opts or {}
	Stub.Reset()
	Stub.Install(_G)
	for key, value in pairs(opts.player or {}) do Stub.player[key] = value end
	_G.ForeverLevels = nil
	_G.ForeverLevelsDB = opts.saved and opts.saved.db or nil
	_G.ForeverLevelsCharDB = opts.saved and opts.saved.char or nil

	local namespace = {}
	local files = T.ReadToc("ForeverLevels_Forever.toc")
	for _, file in ipairs(files) do
		T.LoadFile(ADDON_DIR .. "/" .. file, namespace)
	end
	for _, extra in ipairs(opts.extraFiles or {}) do
		local chunk = assert(loadfile(extra))
		chunk("ExtraAddon", {})
	end
	if opts.beforeLogin then opts.beforeLogin(namespace) end
	Stub.FireEvent("ADDON_LOADED", ADDON_NAME)
	Stub.FireEvent("PLAYER_LOGIN")
	Stub.FireEvent("PLAYER_ENTERING_WORLD", true, false)
	Stub.Advance(0.5)
	return namespace
end

------------------------------------------------------------------------
-- Quest simulation
------------------------------------------------------------------------

local function Settle() Stub.Advance(0.5) end

function T.Accept(id)
	Stub.Quest(id).onQuest = true
	Stub.FireEvent("QUEST_ACCEPTED", id)
	Settle()
end

function T.Finish(id)
	Stub.Quest(id).complete = true
	Stub.FireEvent("QUEST_LOG_UPDATE")
	Settle()
end

function T.TurnIn(id)
	local quest = Stub.Quest(id)
	quest.onQuest, quest.complete, quest.turnedIn = false, false, true
	Stub.FireEvent("QUEST_TURNED_IN", id, 100, 0)
	Stub.FireEvent("QUEST_REMOVED", id, false)
	Settle()
end

function T.Do(id)
	T.Accept(id); T.Finish(id); T.TurnIn(id)
end

------------------------------------------------------------------------
-- Assertions and runner
------------------------------------------------------------------------

function T.Equal(actual, expected, message)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", message or "values differ", tostring(expected), tostring(actual)), 2)
	end
end

function T.True(value, message)
	if not value then error(message or "expected true", 2) end
end

function T.ChatContains(fragment)
	for _, line in ipairs(Stub.chat) do
		if line:find(fragment, 1, true) then return true end
	end
	return false
end

local tests = {}
function T.Test(name, fn) tests[#tests + 1] = { name = name, fn = fn } end

local suites = { "test_toc", "test_routes", "test_engine", "test_autoquest", "test_waypoint", "test_sync", "test_misc", "test_branding", "test_professions", "test_planner" }
for _, suite in ipairs(suites) do
	local chunk = assert(loadfile(root .. "/tests/" .. suite .. ".lua"))
	chunk(T)
end

local passed, failed = 0, 0
for _, test in ipairs(tests) do
	local ok, err = xpcall(test.fn, debug.traceback)
	if ok then
		passed = passed + 1
		print("  ok    " .. test.name)
	else
		failed = failed + 1
		print("  FAIL  " .. test.name .. "\n" .. tostring(err))
	end
end
print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)

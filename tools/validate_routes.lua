-- SPDX-License-Identifier: GPL-3.0-only
-- Checks routes and profession data packs offline, with the checks the addon
-- itself runs (Engine.Check against Pathwise's quest data, and the profession
-- data validation). Loads the addon through the test client stub.
--
--   lua tools/validate_routes.lua                   bundled routes, starter data and the examples
--   lua tools/validate_routes.lua path/to/Pack.lua  any route or profession data files
--
-- Exit code 0 when everything passes, 1 otherwise.

local root = (arg[0]:gsub("[/\\]?tools[/\\]validate_routes%.lua$", ""))
if root == "" then root = "." end

local stub = dofile(root .. "/tests/stub.lua")
local ns = stub.load(root)

-- Every file registers through these while it is checked.
local routes, packs, file = {}, {}, nil
Pathwise.RegisterRoute = function(a, b)
	routes[#routes + 1] = { def = a == Pathwise and b or a, file = file }
	return true
end
Pathwise.RegisterProfessionData = function(a, b)
	packs[#packs + 1] = { def = a == Pathwise and b or a, file = file }
	return true
end

local files = {}
for i = 1, #arg do files[#files + 1] = arg[i] end
if #files == 0 then
	for _, f in ipairs({
		"Pathwise/Routes/Leveling.lua", "Pathwise/Routes/Class.lua", "Pathwise/Routes/Professions.lua", "Pathwise/Routes/Other.lua",
		"Pathwise/Guides/Professions/Tailoring.lua", "Pathwise/Guides/Professions/Enchanting.lua",
		"examples/Pathwise_ExampleRoute/ExampleRoute.lua", "examples/Pathwise_ExampleProfessionData/ExampleProfessionData.lua",
	}) do files[#files + 1] = root .. "/" .. f end
end

local failures = 0
for _, f in ipairs(files) do
	file = f
	local chunk, err = loadfile(f)
	local before = #routes + #packs
	if not chunk then
		print("ERROR  " .. f .. ": " .. err)
		failures = failures + 1
	else
		local ok, runErr = pcall(chunk, "Pathwise", ns)
		if not ok then
			print("ERROR  " .. f .. ": " .. tostring(runErr))
			failures = failures + 1
		elseif #routes + #packs == before then
			print("WARN   " .. f .. ": registered no routes or profession data")
		end
	end
end

local ids = {}
for id in pairs(ns.Engine.routes) do ids[id] = true end
local seen = {}
for _, r in ipairs(routes) do
	local def = r.def
	local first = type(def) == "table" and type(def.steps) == "table" and def.steps[1]
	local problems
	if type(first) == "table" and #first == 0 and (first.accept or first.turnin or first.complete or first.x) then
		problems = { "written in the ForeverLevels route format (accept = { ... }): see docs/ROUTE_FORMAT.md" }
	else
		problems = ns.Engine.Check(def)
	end
	if type(def) == "table" and def.id then
		if seen[def.id] then problems[#problems + 1] = "the id " .. def.id .. " is used twice" end
		seen[def.id], ids[def.id] = true, true
	end
	if #problems > 0 then
		failures = failures + 1
		print(("FAIL   %s (%s)"):format(tostring(type(def) == "table" and def.id), r.file))
		for _, p in ipairs(problems) do print("       " .. p) end
	end
end
for _, r in ipairs(routes) do
	if type(r.def) == "table" and r.def.next and not ids[r.def.next] then
		print(("NOTE   %s goes on to '%s', which is not installed"):format(r.def.id, r.def.next))
	end
end

local unverified = 0
for _, p in ipairs(packs) do
	local ok, errors, warnings = ns.Recipes.Validate(p.def)
	for _, w in ipairs(warnings) do if w:find("unverified fallback", 1, true) then unverified = unverified + 1 end end
	if not ok then
		failures = failures + 1
		print(("FAIL   profession pack %s (%s)"):format(tostring(type(p.def) == "table" and p.def.id), p.file))
		for _, e in ipairs(errors) do print("       " .. e) end
	end
end

print(("%d routes and %d profession data packs checked (%d recipes with unverified skill levels); %d failed."):format(
	#routes, #packs, unverified, failures))
os.exit(failures == 0 and 0 or 1)

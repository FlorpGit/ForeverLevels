-- Validate route files offline, with the same validator the addon uses.
--
--   lua tools/validate_routes.lua                       (all bundled routes)
--   lua tools/validate_routes.lua path/to/MyRoute.lua   (any route files)
--
-- Exit code 0 when every route is valid, 1 otherwise.

local root = (arg[0]:gsub("[/\\]?tools[/\\]validate_routes%.lua$", ""))
if root == "" then root = "." end

local FL = { ROUTE_API_VERSION = 1, routes = {} }
assert(loadfile(root .. "/ForeverLevels/Core/Validator.lua"))("ForeverLevels", FL)

function FL:RegisterRoute(route)
	self.routes[#self.routes + 1] = route
	return true
end
function FL:RegisterDungeon() end
_G.ForeverLevels = FL

local files = {}
for i = 1, #arg do files[#files + 1] = arg[i] end
if #files == 0 then
	files = {
		root .. "/ForeverLevels/Guides/Horde/Undead_01_Deathknell.lua",
		root .. "/ForeverLevels/Guides/Horde/Undead_02_Brill.lua",
		root .. "/examples/ForeverLevels_ExampleRoute/ExampleRoute.lua",
	}
end

local failures = 0
for _, file in ipairs(files) do
	local chunk, loadError = loadfile(file)
	if not chunk then
		print("ERROR  " .. file .. ": " .. loadError)
		failures = failures + 1
	else
		local before = #FL.routes
		local ok, runError = pcall(chunk, "ForeverLevels", FL)
		if not ok then
			print("ERROR  " .. file .. ": " .. tostring(runError))
			failures = failures + 1
		elseif #FL.routes == before then
			print("WARN   " .. file .. ": registered no routes")
		end
	end
end

local ids = {}
for _, route in ipairs(FL.routes) do
	local ok, errors, warnings = FL.Validator.ValidateRoute(route)
	if ids[route.id] then
		ok = false
		errors[#errors + 1] = "duplicate route id " .. tostring(route.id)
	end
	ids[route.id] = true
	print(string.format("%s  %s (%d steps)", ok and "OK   " or "FAIL ", tostring(route.id), type(route.steps) == "table" and #route.steps or 0))
	for _, message in ipairs(errors) do print("       error: " .. message) end
	for _, message in ipairs(warnings) do print("       warn:  " .. message) end
	if not ok then failures = failures + 1 end
end

for _, route in ipairs(FL.routes) do
	if route.next and not ids[route.next] then
		print("NOTE   " .. route.id .. " continues to '" .. route.next .. "', which is not among the checked files")
	end
end

os.exit(failures == 0 and 0 or 1)

local T = ...

T.Test("Routes: bundled routes register and validate without errors", function()
	local FL = T.Boot()
	local routes = FL:GetRoutes()
	T.Equal(#routes, 2, "bundled route count")
	for _, route in ipairs(routes) do
		local ok, errors = FL.Validator.ValidateRoute(route)
		T.True(ok, route.id .. ": " .. table.concat(errors or {}, "; "))
	end
	T.True(not T.ChatContains("route rejected"), "no route was rejected")
end)

T.Test("Routes: every quest ID in a route has a fallback name", function()
	local FL = T.Boot()
	for _, route in ipairs(FL:GetRoutes()) do
		for _, step in ipairs(route.steps) do
			for _, kind in ipairs({ "accept", "complete", "turnin" }) do
				for _, goal in ipairs(step[kind] or {}) do
					local id = type(goal) == "table" and goal[1] or goal
					T.True(route.quests[id], route.id .. " step " .. step.id .. ": no name for quest " .. id)
				end
			end
		end
	end
end)

T.Test("Routes: chained route ids resolve", function()
	local FL = T.Boot()
	for _, route in ipairs(FL:GetRoutes()) do
		if route.next then
			T.True(FL:GetRoute(route.next), route.id .. " -> missing next route " .. route.next)
		end
	end
end)

T.Test("Routes: quests are accepted before they are completed or turned in", function()
	local FL = T.Boot()
	local accepted = {}
	local routes = { FL:GetRoute("fl.horde.undead.01-deathknell"), FL:GetRoute("fl.horde.undead.02-brill") }
	for _, route in ipairs(routes) do
		for _, step in ipairs(route.steps) do
			for _, goal in ipairs(step.accept or {}) do
				accepted[type(goal) == "table" and goal[1] or goal] = true
			end
			for _, kind in ipairs({ "complete", "turnin" }) do
				for _, goal in ipairs(step[kind] or {}) do
					local id = type(goal) == "table" and goal[1] or goal
					T.True(accepted[id], route.id .. " step " .. step.id .. ": " .. kind .. " before accept for " .. id)
				end
			end
		end
	end
end)

T.Test("Validator: rejects malformed routes", function()
	local FL = T.Boot()
	local base = function()
		return {
			id = "test.bad", title = "Bad", author = "me", license = "CC0", levels = { 1, 5 }, zone = "Somewhere",
			steps = { { id = "a", title = "A", accept = { 1 } } },
		}
	end
	local cases = {
		{ "missing license", function(r) r.license = nil end },
		{ "bad levels", function(r) r.levels = { 5, 1 } end },
		{ "duplicate step id", function(r) r.steps[2] = { id = "a", title = "B" } end },
		{ "coordinate out of range", function(r) r.steps[1].x, r.steps[1].y = 150, 20 end },
		{ "x without y", function(r) r.steps[1].x = 10 end },
		{ "unknown class", function(r) r.steps[1].class = { "DEATHKNIGHT" } end },
		{ "non-integer quest id", function(r) r.steps[1].accept = { 1.5 } end },
		{ "bad id characters", function(r) r.id = "has spaces" end },
		{ "future api version", function(r) r.apiVersion = 99 end },
	}
	for _, case in ipairs(cases) do
		local route = base()
		case[2](route)
		local ok = FL.Validator.ValidateRoute(route)
		T.True(not ok, "should reject: " .. case[1])
	end
	local ok, errors = FL.Validator.ValidateRoute(base())
	T.True(ok, "base route should be valid: " .. table.concat(errors, "; "))
end)

T.Test("Validator: unknown race tokens warn instead of failing (new Forever race)", function()
	local FL = T.Boot()
	local ok, _, warnings = FL.Validator.ValidateRoute({
		id = "test.newrace", title = "New race", author = "me", license = "CC0", levels = { 1, 5 },
		races = { "SkyborneElf" },
		steps = { { id = "a", title = "A", accept = { 1 } } },
	})
	T.True(ok, "route with unknown race should still be valid")
	T.Equal(#warnings, 1, "one warning")
end)

T.Test("Registry: community route from another addon registers and is selectable", function()
	local FL = T.Boot({ extraFiles = { T.root .. "/examples/ForeverLevels_ExampleRoute/ExampleRoute.lua" } })
	local route = FL:GetRoute("example.horde.undead.deathknell-sprint")
	T.True(route, "example route registered")
	T.True(FL.Engine:SelectRoute(route.id), "example route selectable")
	T.Equal(FL.Engine.route.id, route.id, "active route")
end)

T.Test("Registry: invalid community route is rejected with a message", function()
	local FL = T.Boot()
	local ok = FL:RegisterRoute({ id = "broken" })
	T.True(not ok, "rejected")
	T.True(T.ChatContains("route rejected"), "message printed")
	T.True(not FL:GetRoute("broken"), "not stored")
end)

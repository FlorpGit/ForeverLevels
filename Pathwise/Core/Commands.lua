-- Pathwise slash commands (/pw, /pathwise). Loaded last: every module exists.

local ADDON, ns = ...
local Nav, Guide = ns.Nav, ns.Guide

ns.Command("help", function()
	ns.Print("commands:")
	for _, c in ipairs(ns.CommandHelp()) do
		ns.Print(("  /pw %s  -  %s"):format(c.name, c.help or ""))
	end
end, "this list")

ns.Command("way", function(args)
	local a = (args or ""):lower()
	if a == "" or a == "clear" or a == "off" then
		Nav.Clear()
		ns.Print("waypoint cleared.")
		return
	end
	-- /pw way 45.2 61.8 [title]   (on the map you are on)
	local x, y, title = args:match("^%s*([%d%.]+)[,%s]+([%d%.]+)%s*(.*)$")
	x, y = tonumber(x), tonumber(y)
	if not (x and y) or x < 0 or x > 100 or y < 0 or y > 100 then
		ns.Print("usage: /pw way <x> <y> [title]   e.g. /pw way 45.2 61.8 Inn")
		return
	end
	local map = ns.Compat.PlayerMapPosition()
	if not map then
		ns.Print("no map position here (inside an instance?).")
		return
	end
	if title == "" then title = ("%.1f, %.1f"):format(x, y) end
	Nav.SetTarget(map, x, y, title)
	ns.Print(("waypoint set: %s on %s."):format(title, ns.Compat.MapName(map) or ("map " .. map)))
end, "set a waypoint on this map: /pw way <x> <y> [title]; /pw way clear")

ns.Command("where", function()
	local C = ns.Compat
	local map, x, y = C.PlayerMapPosition()
	if not map then
		ns.Print("no map position here (inside an instance?).")
		return
	end
	ns.Print(("you are at %.1f, %.1f on %s (map %d)."):format(x, y, C.MapName(map) or "?", map))
end, "your coordinates on this map")

-- What the arrow sees, to tell a position problem from a display one.
ns.Command("debug", function()
	local C = ns.Compat
	local function n(v) return v and ("%.1f"):format(v) or "nil" end
	local map, x, y = C.PlayerMapPosition()
	ns.Print(("player map %s at %s, %s"):format(tostring(map), n(x), n(y)))
	local inst, north, west = C.PlayerWorldPosition()
	ns.Print(("player world inst %s north %s west %s, facing %s"):format(tostring(inst), n(north), n(west), n(C.PlayerFacing())))
	local t = Nav.Target()
	if not t then
		ns.Print("no waypoint set.")
		return
	end
	ns.Print(("target map %s at %s, %s -> world inst %s north %s west %s"):format(tostring(t.map), n(t.x), n(t.y), tostring(t.inst), n(t.north), n(t.west)))
	local state, dist, rot = Nav.Sample()
	ns.Print(("state %s, distance %s yd, rotation %s"):format(tostring(state), n(dist), n(rot)))
end, "what the arrow sees (for bug reports)")

ns.Command("compact", function()
	Guide.SetCompact(not ns.Get("guide.compact"))
end, "switch the guide between full and compact")

ns.Command("opacity", function(args)
	local v = tonumber(args)
	if not v or v < 40 or v > 100 then
		ns.Print("usage: /pw opacity <40-100>   (now " .. math.floor(ns.Get("ui.opacity") * 100 + 0.5) .. ")")
		return
	end
	ns.Set("ui.opacity", v / 100)
end, "window background opacity, 40-100")

ns.Command("arrow", function(args)
	local sub, rest = (args or ""):lower():match("^(%S*)%s*(.-)%s*$")
	if sub == "scale" then
		local v = tonumber((rest:gsub("%%", "")))
		if not v or v < 50 or v > 200 then
			ns.Print(("usage: /pw arrow scale <50-200>   (now %d%%)"):format(math.floor((ns.Get("arrow.scale") or 1) * 100 + 0.5)))
			return
		end
		ns.Set("arrow.scale", v / 100)
		ns.Print(("arrow size %d%%."):format(v))
		return
	end
	ns.Set("arrow.shown", not ns.Get("arrow.shown"))
	ns.Print(ns.Get("arrow.shown") and "arrow on (Shift-drag to move)." or "arrow off.")
end, "show or hide the arrow; /pw arrow scale <50-200> sets its size")

ns.Command("reset", function()
	ns.Set("guide.point", nil)
	ns.Set("arrow.point", nil)
	ns.Print("window positions reset; /reload to apply.")
end, "reset window positions")

-- A labelled sample so the layout can be checked in game before the guide
-- engine exists. Quest names are from the Undead start in Tirisfal Glades.
ns.Command("demo", function()
	if Guide.View() then
		Guide.SetView(nil)
		ns.Print("sample cleared.")
		return
	end
	Guide.SetView({
		route = "Sample · Tirisfal Glades", index = 6, count = 48, progress = 0.12,
		title = "The Mindless Ones",
		text = "Kill Mindless and Wretched Zombies in the fields just north of Deathknell.",
		coords = "30.7, 64.2",
		objectives = {
			{ text = "Mindless Zombie", have = 5, need = 8 },
			{ text = "Wretched Zombie", have = 8, need = 8, done = true },
		},
		detour = { label = "Optional · Tailoring", text = "Train Apprentice Tailoring", sub = "On your way · about 1 min" },
		next = "Turn in The Mindless Ones at Shadow Priest Sarvis",
	})
	ns.Set("guide.shown", true)
	ns.Print("showing a sample step (/pw demo again to clear).")
end, "preview the guide window with a sample step")

ns.Command("about", function()
	ns.Print(("Pathwise %s  ·  Every quest. Every craft. Every level.  ·  created by leight_nn & florp  _nn"):format(ns.VERSION))
end, "version and credits")

-- Buttons whose features arrive with the guide engine say so instead of
-- doing nothing.
local function later(what)
	return function() ns.Print(what .. " arrives with the guide engine.") end
end
ns.On("GUIDE_BACK", later("Step navigation"))
ns.On("GUIDE_NEXT", later("Step navigation"))
ns.On("GUIDE_SKIP", later("Skipping a quest (with alternatives)"))
ns.On("SHOW_ZONES", later("The zone list for your level"))
ns.On("REPORT_STEP", later("Reporting a step"))
ns.On("DETOUR_GO", later("Profession detours"))
ns.On("DETOUR_SKIP", later("Profession detours"))

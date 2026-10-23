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
	for line in Nav.DebugText():gmatch("[^\n]+") do ns.Print(line) end
end, "what the arrow sees (also in Settings > Waypoint & tools)")
ns.Command("tools", function() ns.Panels.Open("tools") end, "Waypoint & tools")

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

ns.Command("scale", function(args)
	local v = tonumber(((args or ""):gsub("%%", "")))
	if not v or v < 50 or v > 150 then
		ns.Print(("usage: /pw scale <50-150>   (now %d%%)"):format(math.floor((ns.Get("ui.scale") or 1) * 100 + 0.5)))
		return
	end
	ns.Set("ui.scale", v / 100)
	ns.Print(("window size %d%%."):format(v))
end, "guide window size, 50-150 (also in Settings)")

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

ns.Command("style", function(args)
	local T = ns.Theme
	local name = (args or ""):lower():gsub("%s+", "")
	if name ~= "" and T.Choose(name) then return end
	local list = {}
	for _, key in ipairs(T.STYLE_ORDER) do list[#list + 1] = key end
	ns.Print(("look: %s. /pw style %s"):format(T.Style().label, table.concat(list, " | ")))
end, "the look of every Pathwise window: /pw style modern | classic (after a reload)")

ns.Command("waypoint", function(args)
	local a = (args or ""):lower()
	local on
	if a == "on" then on = true elseif a == "off" then on = false else on = not ns.Get("arrow.native") end
	ns.Set("arrow.native", on)
	ns.Print(on and "the game's map pin and marker follow the arrow." or "the game's map pin and marker off.")
end, "the game's own map pin and in-world marker at the arrow's target: /pw waypoint [on|off]")

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
	ns.Fire("SHOW_ABOUT")
end, "version and credits")
ns.Command("report", function() ns.Fire("REPORT_STEP") end, "report a problem with this guide step (for Discord or email)")

ns.Command("settings", function() ns.Fire("SHOW_SETTINGS") end, "open the settings panel")
ns.Command("zones", function() ns.Fire("SHOW_ZONES") end, "zones for your level (and switching routes)")
ns.Command("routes", function() ns.Fire("SHOW_ROUTES") end, "every route for you: leveling, class quests, professions")
ns.Command("prof", function() ns.Fire("SHOW_PROFESSIONS") end, "your professions: skill, best craft, materials")
ns.Command("dungeons", function() ns.Fire("SHOW_DUNGEONS") end, "dungeons and raids for your level, their quests and entrances")
ns.Command("professions", function() ns.Fire("SHOW_PROFESSIONS") end, "same as /pw prof")
ns.Command("skip", function() ns.Fire("GUIDE_SKIP") end, "skip the current quest, or pick one nearby instead")

ns.Command("route", function(args)
	local E = ns.Engine
	if args and args ~= "" then
		for _, r in ipairs(E.Routes()) do
			if r.id == args or r.title:lower() == args:lower() then
				E.SetRoute(r.id)
				ns.Print("route: " .. r.title)
				return
			end
		end
		ns.Print("no route called '" .. args .. "'.")
		return
	end
	local r = E.Route()
	ns.Print("route: " .. (r and (r.title .. " (" .. r.id .. ")") or "none"))
	for _, x in ipairs(E.Routes()) do ns.Print("  " .. x.id .. "  " .. x.title) end
end, "show or choose the route: /pw route <id or title>")

ns.Command("next", function() ns.Fire("GUIDE_NEXT") end, "look at the next step")
ns.Command("back", function() ns.Fire("GUIDE_BACK") end, "look at the step before")

ns.On("GUIDE_BACK", function() ns.Engine.Back() end)
ns.On("GUIDE_NEXT", function() ns.Engine.Next() end)

-- Pathwise is made for Forever; elsewhere positions, quests and the
-- interface may not be what it expects.
ns.On("READY", function()
	if not ns.Compat.IsForeverClient() then
		ns.Print("|cffe4b96dthis client does not report itself as World of Warcraft: Forever.|r Pathwise is made for Forever only.")
	end
end)

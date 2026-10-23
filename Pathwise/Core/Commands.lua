-- Pathwise slash commands (/pw, /pathwise) of the core. Loaded last: every core module
-- exists. The window commands (compact, scale, style ...) are in Pathwise_UI/UI/Commands.lua.

local ADDON, ns = ...
local Nav = ns.Nav

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


ns.Command("waypoint", function(args)
	local a = (args or ""):lower()
	local on
	if a == "on" then on = true elseif a == "off" then on = false else on = not ns.Get("arrow.native") end
	ns.Set("arrow.native", on)
	ns.Print(on and "the game's map pin and marker follow the arrow." or "the game's map pin and marker off.")
end, "the game's own map pin and in-world marker at the arrow's target: /pw waypoint [on|off]")


ns.Command("about", function()
	ns.Print(("Pathwise %s  ·  Every quest. Every craft. Every level.  ·  created by leight_nn & florp  _nn"):format(ns.VERSION))
	ns.Fire("SHOW_ABOUT")
end, "version and credits")
ns.Command("report", function() ns.Fire("REPORT_STEP") end, "report a problem with this guide step (for Discord or email)")

ns.Command("settings", function() ns.Fire("SHOW_SETTINGS") end, "open the settings panel")
ns.Command("options", function() ns.Fire("SHOW_SETTINGS") end, "same as /pw settings")
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
	-- Pathwise runs without Pathwise UI (quests at their NPC, party sync, the
	-- game's waypoint, commands), but shows no windows.
	if not ns.UI then
		ns.Print("Pathwise UI is turned off, so Pathwise shows no windows. Turn it on in the AddOns list on the character screen.")
	end
end)

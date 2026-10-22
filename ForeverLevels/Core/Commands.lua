-- ForeverLevels: slash commands. /pathwise is the main one; /fl and /foreverlevels
-- are kept so older macros and habits keep working.
-- Polestar's README mentions that Forever's gamepad UI can freeze after an addon slash
-- command is typed in chat. Everything here is also reachable from the guide window
-- and the Settings panel, so gamepad players do not need slash commands.

local _, FL = ...

local Engine = FL.Engine

local HELP = {
	"/pathwise - show or hide the guide",
	"/pathwise next | back | skip - move between steps",
	"/pathwise routes - list installed routes",
	"/pathwise route <id> - switch route",
	"/pathwise reset - restart the current route",
	"/pathwise lock | unlock - lock the guide and arrow in place",
	"/pathwise scale <0.5-2> - guide window scale",
	"/pathwise style [classic|tooltip|minimal] - guide window look",
	"/pathwise arrow | waypoint | auto | sync | dungeons | record | debug [on|off]",
	"/pathwise where - print map ID, zone and coordinates",
	"/pathwise options - open the Settings panel",
	"/fl works as a short alias for every command.",
}

local TOGGLE_ALIASES = {
	arrow = { "arrow" },
	waypoint = { "nativeWaypoint" },
	auto = { "autoAccept", "autoTurnIn", "autoGossip" },
	sync = { "sync" },
	dungeons = { "suggestDungeons" },
	record = { "record" },
	debug = { "debug" },
}

local function ParseOnOff(arg, current)
	if arg == "on" then return true end
	if arg == "off" then return false end
	return not current
end

local commands = {}

commands.help = function()
	for _, line in ipairs(HELP) do FL:Print(line) end
end

commands.show = function() FL.GuideFrame:SetShown(true) end
commands.hide = function() FL.GuideFrame:SetShown(false) end
commands.next = function() Engine:Next() end
commands.skip = commands.next
commands.back = function() Engine:Prev() end
commands.prev = commands.back
commands.options = function() FL.Options:Open() end
commands.config = commands.options

commands.routes = function()
	local routes = FL:GetRoutes()
	if #routes == 0 then
		FL:Print("no routes installed")
		return
	end
	for _, route in ipairs(routes) do
		local fits = FL:RouteFitsPlayer(route, FL.player) and "" or " |cff888888(not for this character)|r"
		local active = (Engine.route == route) and " |cff55dd55<- active|r" or ""
		FL:Print(string.format("%s - %s (%d-%d, %s)%s%s", route.id, route.title,
			route.levels[1], route.levels[2], route.license, fits, active))
	end
end

commands.route = function(id)
	if not id or id == "" then
		FL:Print("usage: /pathwise route <id>  (see /pathwise routes)")
		return
	end
	Engine:SelectRoute(id)
end

commands.reset = function()
	Engine:ResetRoute()
	FL:Print("route progress reset")
end

commands.lock = function()
	FL.db.profile.frame.locked = true
	FL.db.profile.arrowFrame.locked = true
	FL:Print("locked")
end

commands.unlock = function()
	FL.db.profile.frame.locked = false
	FL.db.profile.arrowFrame.locked = false
	FL:Print("unlocked - drag to move")
end

commands.scale = function(arg)
	local scale = tonumber(arg)
	if not scale or scale < 0.5 or scale > 2 then
		FL:Print("usage: /pathwise scale 0.5-2")
		return
	end
	FL.db.profile.frame.scale = scale
	FL.GuideFrame:ApplySettings()
end

commands.style = function(arg)
	local name = arg ~= "" and arg:lower() or nil
	if name then
		if not FL.GuideFrame:SetStyle(name) then
			FL:Print("usage: /pathwise style classic | tooltip | minimal")
			return
		end
	else
		name = FL.GuideFrame:CycleStyle()
	end
	if FL.Options.panel then FL.Options.Refresh() end
	FL:Print("window style:", name)
end

commands.where = function()
	local mapID, zone, x, y = FL.Recorder.GetPosition()
	if not mapID then
		FL:Print("no map position available here")
		return
	end
	FL:Print(string.format("map %d (%s) %.1f, %.1f", mapID, tostring(zone), x or -1, y or -1))
end

commands.recorder = function(arg)
	if arg == "clear" then
		FL.Recorder:Clear()
		FL:Print("recorder log cleared")
	else
		FL:Print(#FL.db.recorder .. " recorded entries (saved on /reload or logout). /pathwise recorder clear to wipe.")
	end
end

for alias, keys in pairs(TOGGLE_ALIASES) do
	commands[alias] = function(arg)
		local value = ParseOnOff(arg, FL.db.profile[keys[1]])
		for _, key in ipairs(keys) do
			FL.Options.Set(key, value)
		end
		FL:Print(alias, value and "on" or "off")
	end
end

local function Handle(input)
	local command, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
	command = command:lower()
	if command == "" then
		FL.GuideFrame:Toggle()
		return
	end
	local handler = commands[command]
	if handler then
		handler(rest)
	else
		commands.help()
	end
end

SLASH_FOREVERLEVELS1 = "/pathwise"
SLASH_FOREVERLEVELS2 = "/fl"
SLASH_FOREVERLEVELS3 = "/foreverlevels"
SlashCmdList.FOREVERLEVELS = Handle

FL.HandleSlash = Handle

-- ForeverLevels: slash commands (/fl and /foreverlevels).
-- Polestar's README mentions that Forever's gamepad UI can freeze after an addon slash
-- command is typed in chat. Everything here is also reachable from the guide window
-- and the Settings panel, so gamepad players do not need slash commands.

local _, FL = ...

local Engine = FL.Engine

local HELP = {
	"/fl - show or hide the guide",
	"/fl next | back | skip - move between steps",
	"/fl routes - list installed routes",
	"/fl route <id> - switch route",
	"/fl reset - restart the current route",
	"/fl lock | unlock - lock the guide and arrow in place",
	"/fl scale <0.5-2> - guide window scale",
	"/fl arrow | waypoint | auto | sync | dungeons | record | debug [on|off]",
	"/fl where - print map ID, zone and coordinates",
	"/fl options - open the Settings panel",
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
		FL:Print("usage: /fl route <id>  (see /fl routes)")
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
		FL:Print("usage: /fl scale 0.5-2")
		return
	end
	FL.db.profile.frame.scale = scale
	FL.GuideFrame:ApplySettings()
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
		FL:Print(#FL.db.recorder .. " recorded entries (saved on /reload or logout). /fl recorder clear to wipe.")
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

SLASH_FOREVERLEVELS1 = "/fl"
SLASH_FOREVERLEVELS2 = "/foreverlevels"
SlashCmdList.FOREVERLEVELS = Handle

FL.HandleSlash = Handle

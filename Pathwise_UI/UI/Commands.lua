-- Pathwise UI's slash commands: the ones about windows and looks. The rest
-- are Pathwise's (Pathwise/Core/Commands.lua); /pw help lists both.

local ADDON, ns = ...
local Guide = ns.Guide

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

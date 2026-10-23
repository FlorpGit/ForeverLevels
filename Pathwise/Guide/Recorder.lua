-- Pathwise recorder, for route authors. With /pw record on (or Settings >
-- Waypoint & tools), every quest accepted and handed in is logged with the
-- quest, the NPC, the map and the player's coordinates, and every trainer
-- opened with its name and place. After /reload or logging out the log is in
-- WTF/Account/<ACCOUNT>/SavedVariables/Pathwise.lua, and
-- tools/recorder_to_route.lua turns it into a route to edit. This is how
-- positions in routes get checked on Forever.
--
-- The log is account-wide (PathwiseSettings.recorder.log), at most
-- MAX_ENTRIES long; the oldest entries go first.

local ADDON, ns = ...
local C = ns.Compat
local R = C.Readable
local Recorder = {}
ns.Recorder = Recorder

local MAX_ENTRIES = 2000

ns.Defaults("recorder", { on = false })

function Recorder.Log()
	local log = ns.Get("recorder.log")
	if type(log) ~= "table" then
		log = {}
		ns.Set("recorder.log", log)
	end
	return log
end

-- The player's map, its name and the position on it, to a tenth.
function Recorder.Position()
	local map, x, y = C.PlayerMapPosition()
	if not map then return nil end
	return map, C.MapName(map), math.floor(x * 10 + 0.5) / 10, math.floor(y * 10 + 0.5) / 10
end

local function add(entry)
	local map, zone, x, y = Recorder.Position()
	entry.map, entry.zone, entry.x, entry.y = map, zone, x, y
	local p = ns.Quests.Player()
	entry.level, entry.race, entry.class = p.level, p.race, p.class
	entry.time = time and time() or nil
	entry.build = GetBuildInfo and select(2, GetBuildInfo()) or nil
	local log = Recorder.Log()
	log[#log + 1] = entry
	while #log > MAX_ENTRIES do table.remove(log, 1) end
	return entry
end

local function where(e)
	return e.map and ("%s (map %d) %.1f, %.1f"):format(tostring(e.zone), e.map, e.x, e.y) or "no map position"
end

local function quest(kind, q)
	q = R(q)
	if not ns.Get("recorder.on") or type(q) ~= "number" then return end
	local npc = UnitName and R(UnitName("npc")) or nil
	local e = add({ kind = kind, quest = q, title = ns.Quests.Name(q), npc = npc })
	ns.Print(("recorded %s %d %s at %s."):format(kind, q, e.title, where(e)))
end

ns.RegisterEvent("QUEST_ACCEPTED", function(_, q) quest("accept", q) end)
ns.RegisterEvent("QUEST_TURNED_IN", function(_, q) quest("turnin", q) end)

-- Trainers, so profession routes can get checked positions.
ns.RegisterEvent("TRAINER_SHOW", function()
	if not ns.Get("recorder.on") then return end
	local npc = UnitName and R(UnitName("npc")) or nil
	if not npc then return end
	local e = add({ kind = "trainer", npc = npc })
	ns.Print(("recorded trainer %s at %s."):format(npc, where(e)))
end)

function Recorder.Clear() ns.Set("recorder.log", {}) end

ns.Command("record", function(args)
	local a = (args or ""):lower()
	local on
	if a == "on" then on = true elseif a == "off" then on = false else on = not ns.Get("recorder.on") end
	ns.Set("recorder.on", on)
	ns.Print(on and "recording quests and trainers (/pw record off to stop; /reload saves the log)." or "recording off.")
end, "log where quests and trainers are, for writing routes: /pw record [on|off]")

ns.Command("recorder", function(args)
	if (args or ""):lower() == "clear" then
		Recorder.Clear()
		ns.Print("recorder log cleared.")
		return
	end
	ns.Print(("%d recorded entries (saved on /reload or logout). /pw recorder clear empties the log."):format(#Recorder.Log()))
end, "how many entries the recorder holds; /pw recorder clear")

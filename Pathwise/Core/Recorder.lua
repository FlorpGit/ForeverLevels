-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: route-author recorder.
--
-- With /pathwise record on, every quest accept and turn-in is logged with the quest ID,
-- title, uiMapID, zone name and player coordinates into ForeverLevelsDB.recorder.
-- After /reload or logout, tools/recorder_to_route.lua turns that log into a
-- route skeleton. This is how coordinates in bundled routes get verified on Forever.

local _, FL = ...

local Recorder = {}
FL.Recorder = Recorder

local MAX_ENTRIES = 2000

function Recorder.GetPosition()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return nil end
	local info = C_Map.GetMapInfo(mapID)
	local position = C_Map.GetPlayerMapPosition(mapID, "player")
	local x, y
	if position then
		x, y = position:GetXY()
		x, y = math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10
	end
	return mapID, info and info.name, x, y
end

local function Log(kind, questID)
	if not FL.db.profile.record then return end
	local log = FL.db.recorder
	local mapID, zone, x, y = Recorder.GetPosition()
	log[#log + 1] = {
		kind = kind,
		questID = questID,
		title = FL.Quests.GetTitle(questID),
		mapID = mapID,
		zone = zone,
		x = x,
		y = y,
		level = UnitLevel("player"),
		race = FL.player.race,
		class = FL.player.class,
		time = time(),
		build = select(2, GetBuildInfo()),
	}
	while #log > MAX_ENTRIES do
		table.remove(log, 1)
	end
	FL:Print(string.format("recorded %s %d at %s (%s) %.1f, %.1f", kind, questID, tostring(zone), tostring(mapID), x or -1, y or -1))
end

FL:On("QUEST_ACCEPTED", function(questID) Log("accept", questID) end)
FL:On("QUEST_TURNED_IN", function(questID) Log("turnin", questID) end)

-- Trainer positions, so profession data can get verified coordinates.
FL:RegisterEvent("TRAINER_SHOW", function()
	if not (FL.db and FL.db.profile.record) then return end
	local npc = UnitName("npc")
	if not npc or FL.IsSecret(npc) then return end
	local mapID, zone, x, y = Recorder.GetPosition()
	local log = FL.db.recorder
	log[#log + 1] = { kind = "trainer", npc = npc, mapID = mapID, zone = zone, x = x, y = y, time = time(), build = select(2, GetBuildInfo()) }
	FL:Print(string.format("recorded trainer %s at %s (%s) %.1f, %.1f", npc, tostring(zone), tostring(mapID), x or -1, y or -1))
end)

function Recorder:Clear()
	wipe(FL.db.recorder)
end

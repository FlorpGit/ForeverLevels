-- ForeverLevels: SavedVariables defaults and migration.
-- ForeverLevelsDB          account-wide settings and recorder log
-- ForeverLevelsCharDB      per-character route progress

local _, FL = ...

FL.DB_VERSION = 1

FL.defaults = {
	profile = {
		autoAccept = true,       -- accept quests the active route asks for
		autoTurnIn = true,       -- complete quests the active route asks for
		autoGossip = true,       -- pick route quests from NPC gossip lists
		pauseWithShift = true,   -- hold Shift while talking to an NPC to skip automation
		arrow = true,            -- ForeverLevels' own directional arrow
		nativeWaypoint = true,   -- also place Blizzard's map pin + in-world marker
		sync = false,            -- party progress sharing (opt-in)
		suggestDungeons = true,
		autoSelectRoute = true,
		debug = false,
		record = false,          -- log quest accept/turn-in positions for route authors
		frame = { point = "RIGHT", relPoint = "RIGHT", x = -60, y = 120, scale = 1, locked = false, shown = true },
		arrowFrame = { point = "TOP", relPoint = "TOP", x = 0, y = -140, scale = 1, locked = false },
	},
	recorder = {},
}

FL.charDefaults = {
	routeId = nil,
	progress = {},   -- [routeId] = { step = n, skipped = { [stepId] = true } }
	turnedIn = {},   -- [questID] = true, filled from QUEST_TURNED_IN
}

-- Copies keys from src that are missing in dst (recursively). Never overwrites user values.
local function MergeDefaults(dst, src)
	for key, value in pairs(src) do
		if type(value) == "table" then
			if type(dst[key]) ~= "table" then dst[key] = {} end
			MergeDefaults(dst[key], value)
		elseif dst[key] == nil then
			dst[key] = value
		end
	end
	return dst
end
FL.MergeDefaults = MergeDefaults

function FL:InitDatabase()
	ForeverLevelsDB = ForeverLevelsDB or {}
	ForeverLevelsCharDB = ForeverLevelsCharDB or {}

	MergeDefaults(ForeverLevelsDB, self.defaults)
	MergeDefaults(ForeverLevelsCharDB, self.charDefaults)

	-- Future schema migrations go here, keyed on dbVersion.
	ForeverLevelsDB.dbVersion = self.DB_VERSION
	ForeverLevelsCharDB.dbVersion = self.DB_VERSION

	self.db = ForeverLevelsDB
	self.char = ForeverLevelsCharDB
end

function FL:GetRouteProgress(routeId)
	local progress = self.char.progress[routeId]
	if not progress then
		progress = { step = 1, skipped = {} }
		self.char.progress[routeId] = progress
	end
	return progress
end

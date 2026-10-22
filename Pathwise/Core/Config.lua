-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: SavedVariables defaults and migration.
-- ForeverLevelsDB          account-wide settings and recorder log
-- ForeverLevelsCharDB      per-character route progress

local _, FL = ...

FL.DB_VERSION = 3

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
		frame = { point = "RIGHT", relPoint = "RIGHT", x = -60, y = 120, scale = 1, locked = false, shown = true, style = "pathwise" },
		arrowFrame = { point = "TOP", relPoint = "TOP", x = 0, y = -140, scale = 1, locked = false },
		professions = {
			enabled = true,          -- profession tracking
			detours = true,          -- optional profession detours next to the route
			reminders = true,        -- chat note when you have materials for the next craft
			countBank = false,       -- include bank items in material counts
			tracked = {},            -- [professionKey] = false hides a profession
		},
		dashboard = { point = "CENTER", relPoint = "CENTER", x = -200, y = 40, scale = 1, locked = false, shown = false },
		feedbackFrame = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
	},
	recorder = {},
	feedback = {
		drafts = {},                 -- [draftKey] = unfinished report; kept until discarded
		current = nil,               -- draft shown in the Feedback Center
	},
	professionCache = {
		schematics = {},             -- [recipeID] = { reagents = { { itemID, qty } }, build } read from the client
	},
}

FL.charDefaults = {
	routeId = nil,
	progress = {},   -- [routeId] = { step = n, skipped = { [stepId] = true } }
	turnedIn = {},   -- [questID] = true, filled from QUEST_TURNED_IN
	professions = {
		skills = {},     -- [professionKey] = { rank, maxRank, name } from the last scan
		recipes = {},    -- [recipeID] = { learned, difficulty, canSkillUp, numSkillUps, at }
		detours = {
			states = {},     -- [detourID] = "done" | "skipped"
			postponed = {},  -- [detourID] = route step key at the time of "Later"
			active = nil,    -- accepted detour: { id, startRank, startMax, ... }
		},
	},
}

-- Schema migrations, run once per database when dbVersion is below the key.
-- Defaults are merged afterwards, so a migration only needs to move or rewrite data.
FL.Migrations = {
	-- 2: profession tracking. New tables only; route progress is untouched.
	[2] = function() end,
	-- 3: Feedback Center drafts. New tables only.
	[3] = function() end,
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

	local from = math.min(ForeverLevelsDB.dbVersion or 1, ForeverLevelsCharDB.dbVersion or 1)
	for version = from + 1, self.DB_VERSION do
		if self.Migrations[version] then
			self.Migrations[version](ForeverLevelsDB, ForeverLevelsCharDB)
		end
	end

	MergeDefaults(ForeverLevelsDB, self.defaults)
	MergeDefaults(ForeverLevelsCharDB, self.charDefaults)

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

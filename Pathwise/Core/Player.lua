-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: the player's faction, race, class and level.

local _, FL = ...

FL.player = { class = "UNKNOWN", race = "Unknown", faction = "Neutral", level = 1 }

function FL:UpdatePlayer()
	local player = self.player
	player.class = select(2, UnitClass("player")) or player.class
	player.race = select(2, UnitRace("player")) or player.race
	player.faction = UnitFactionGroup("player") or player.faction
	player.level = UnitLevel("player") or player.level
	player.name = UnitName("player")
end

FL:RegisterEvent("PLAYER_LEVEL_UP", function(_, newLevel)
	FL.player.level = newLevel or UnitLevel("player")
	FL:Fire("PLAYER_CHANGED")
end)

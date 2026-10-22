-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: quest state queries and quest log events.
-- Uses only C_QuestLog functions present in the Forever 1.60.1 API documentation.

local _, FL = ...

local Quests = {}
FL.Quests = Quests

function Quests.IsOnQuest(questID)
	return C_QuestLog.IsOnQuest(questID) and true or false
end

function Quests.IsTurnedIn(questID)
	if FL.char and FL.char.turnedIn[questID] then return true end
	return C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
end

-- Objectives finished (ready to turn in), or already turned in.
function Quests.IsObjectivesDone(questID)
	if Quests.IsTurnedIn(questID) then return true end
	return Quests.IsOnQuest(questID) and C_QuestLog.IsComplete(questID) and true or false
end

function Quests.HasAccepted(questID)
	return Quests.IsOnQuest(questID) or Quests.IsTurnedIn(questID)
end

function Quests.GetObjectives(questID)
	if not Quests.IsOnQuest(questID) then return {} end
	return C_QuestLog.GetQuestObjectives(questID) or {}
end

function Quests.GetTitle(questID, route)
	local title = C_QuestLog.GetTitleForQuestID(questID)
	if title and title ~= "" and not FL.IsSecret(title) then return title end
	if route and route.quests and route.quests[questID] then return route.quests[questID] end
	return "Quest #" .. questID
end

-- Sum of numFulfilled/numRequired across a quest's objectives (used by party sync).
function Quests.GetProgress(questID)
	local fulfilled, required = 0, 0
	for _, objective in ipairs(Quests.GetObjectives(questID)) do
		fulfilled = fulfilled + (objective.numFulfilled or 0)
		required = required + (objective.numRequired or 0)
	end
	return fulfilled, required
end

local function QuestsChanged()
	FL:Debounce("QUESTS_CHANGED", 0.2, function()
		FL:Fire("QUESTS_CHANGED")
	end)
end

FL:RegisterEvent("QUEST_ACCEPTED", function(_, questID)
	FL:Fire("QUEST_ACCEPTED", questID)
	QuestsChanged()
end)

FL:RegisterEvent("QUEST_TURNED_IN", function(_, questID)
	-- IsQuestFlaggedCompleted can lag behind this event, so remember it ourselves.
	if FL.char then FL.char.turnedIn[questID] = true end
	FL:Fire("QUEST_TURNED_IN", questID)
	QuestsChanged()
end)

FL:RegisterEvent("QUEST_REMOVED", QuestsChanged)
FL:RegisterEvent("QUEST_LOG_UPDATE", QuestsChanged)
FL:RegisterEvent("UNIT_QUEST_LOG_CHANGED", function(_, unit)
	if unit == "player" then QuestsChanged() end
end)

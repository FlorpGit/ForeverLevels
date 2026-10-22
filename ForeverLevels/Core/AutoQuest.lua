-- ForeverLevels: automatic quest accept / turn-in for quests on the active route.
--
-- This only reacts to quest dialogs the player opened by talking to an NPC.
-- It never accepts quests the route does not use, never picks between reward
-- choices, and skips PvP-flagged quests and quests that cost money.
-- Hold Shift while opening the dialog to skip automation once.

local _, FL = ...

local Engine = FL.Engine

local function Paused()
	return FL.db.profile.pauseWithShift and IsShiftKeyDown()
end

local function Wanted(questID, kind)
	return questID and questID ~= 0 and Engine:IsWantedQuest(questID, kind)
end

-- Quest detail panel: Accept button.
FL:RegisterEvent("QUEST_DETAIL", function()
	if not FL.db.profile.autoAccept or Paused() then return end
	local questID = GetQuestID()
	if not Wanted(questID, "accept") then return end
	if QuestFlagsPVP and QuestFlagsPVP() then return end
	if QuestGetAutoAccept and QuestGetAutoAccept() then
		AcknowledgeAutoAcceptQuest()
	else
		AcceptQuest()
	end
	FL:Debug("auto-accepted", questID)
end)

-- Quest progress panel: Continue button.
FL:RegisterEvent("QUEST_PROGRESS", function()
	if not FL.db.profile.autoTurnIn or Paused() then return end
	local questID = GetQuestID()
	if Wanted(questID, "turnin") and IsQuestCompletable() then
		CompleteQuest()
	end
end)

-- Quest reward panel: Complete Quest button.
FL:RegisterEvent("QUEST_COMPLETE", function()
	if not FL.db.profile.autoTurnIn or Paused() then return end
	local questID = GetQuestID()
	if not Wanted(questID, "turnin") then return end
	local money = GetQuestMoneyToGet and GetQuestMoneyToGet() or 0
	if money > 0 then return end
	local choices = GetNumQuestChoices()
	if choices <= 1 then
		GetQuestReward(choices)
		FL:Debug("auto-turned-in", questID)
	else
		FL:Print("pick your reward for", Engine.route and FL.Quests.GetTitle(questID, Engine.route) or questID)
	end
end)

-- Gossip window (modern NPC dialog). Turn-ins first, then new quests.
FL:RegisterEvent("GOSSIP_SHOW", function()
	if not FL.db.profile.autoGossip or Paused() then return end
	local profile = FL.db.profile
	if profile.autoTurnIn then
		for _, info in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
			if info.isComplete and Wanted(info.questID, "turnin") then
				C_GossipInfo.SelectActiveQuest(info.questID)
				return
			end
		end
	end
	if profile.autoAccept then
		for _, info in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
			if Wanted(info.questID, "accept") then
				C_GossipInfo.SelectAvailableQuest(info.questID)
				return
			end
		end
	end
end)

-- Old-style quest greeting window (NPCs with several quests and no gossip text).
FL:RegisterEvent("QUEST_GREETING", function()
	if not FL.db.profile.autoGossip or Paused() then return end
	local profile = FL.db.profile
	local numActive = GetNumActiveQuests()
	if profile.autoTurnIn then
		for i = 1, numActive do
			local _, isComplete = GetActiveTitle(i)
			if isComplete and Wanted(GetActiveQuestID(i), "turnin") then
				SelectActiveQuest(i)
				return
			end
		end
	end
	if profile.autoAccept then
		for i = 1, GetNumAvailableQuests() do
			local questID = select(5, GetAvailableQuestInfo(i))
			if Wanted(questID, "accept") then
				SelectAvailableQuest(i)
				return
			end
		end
	end
end)

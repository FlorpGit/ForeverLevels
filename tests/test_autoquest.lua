-- SPDX-License-Identifier: GPL-3.0-only
local T = ...

local function OpenDetail(questID)
	T.Stub.questDialog.questID = questID
	T.Stub.FireEvent("QUEST_DETAIL")
end

T.Test("AutoQuest: accepts a quest the route wants", function()
	T.Boot()
	OpenDetail(363)
	T.Equal(T.Stub.Called("AcceptQuest"), 1, "AcceptQuest called")
end)

T.Test("AutoQuest: ignores quests the route does not use", function()
	T.Boot()
	OpenDetail(99999)
	T.Equal(T.Stub.Called("AcceptQuest"), 0, "not accepted")
end)

T.Test("AutoQuest: holding Shift pauses automation", function()
	T.Boot()
	T.Stub.shift = true
	OpenDetail(363)
	T.Equal(T.Stub.Called("AcceptQuest"), 0, "not accepted")
end)

T.Test("AutoQuest: disabled setting is respected", function()
	local FL = T.Boot()
	FL.db.profile.autoAccept = false
	OpenDetail(363)
	T.Equal(T.Stub.Called("AcceptQuest"), 0, "not accepted")
end)

T.Test("AutoQuest: auto-accept quests are acknowledged, not re-accepted", function()
	T.Boot()
	T.Stub.questDialog.autoAccept = true
	OpenDetail(363)
	T.Equal(T.Stub.Called("AcknowledgeAutoAcceptQuest"), 1, "acknowledged")
	T.Equal(T.Stub.Called("AcceptQuest"), 0, "AcceptQuest not called")
end)

T.Test("AutoQuest: does not accept a quest the route only uses earlier", function()
	T.Boot()
	T.Accept(363)
	T.TurnIn(363)
	OpenDetail(363)
	T.Equal(T.Stub.Called("AcceptQuest"), 0, "quest from an earlier step is not wanted for accept")
end)

T.Test("AutoQuest: progress panel completes when completable", function()
	T.Boot()
	T.Accept(363)
	T.Stub.questDialog.questID = 363
	T.Stub.questDialog.completable = true
	T.Stub.FireEvent("QUEST_PROGRESS")
	T.Equal(T.Stub.Called("CompleteQuest"), 1, "CompleteQuest")
end)

T.Test("AutoQuest: reward panel takes the only reward, waits when there is a choice", function()
	T.Boot()
	T.Stub.questDialog.questID = 363
	T.Stub.questDialog.choices = 1
	T.Stub.FireEvent("QUEST_COMPLETE")
	T.Equal(T.Stub.Called("GetQuestReward"), 1, "single reward taken")

	T.Stub.questDialog.choices = 3
	T.Stub.FireEvent("QUEST_COMPLETE")
	T.Equal(T.Stub.Called("GetQuestReward"), 1, "no auto-pick with a choice")
	T.True(T.ChatContains("pick your reward"), "player told to pick")
end)

T.Test("AutoQuest: quests that cost money are never auto-completed", function()
	T.Boot()
	T.Stub.questDialog.questID = 363
	T.Stub.questDialog.money = 500
	T.Stub.FireEvent("QUEST_COMPLETE")
	T.Equal(T.Stub.Called("GetQuestReward"), 0, "not completed")
end)

T.Test("AutoQuest: gossip prefers completed turn-ins, then route quests", function()
	T.Boot()
	T.Stub.gossip.active = { { questID = 363, isComplete = true, title = "Rude Awakening" } }
	T.Stub.gossip.available = { { questID = 364, title = "The Mindless Ones" } }
	T.Stub.FireEvent("GOSSIP_SHOW")
	T.Equal(T.Stub.Called("SelectActiveQuest"), 1, "turn-in selected")
	T.Equal(T.Stub.Called("SelectAvailableQuest"), 0, "one action per gossip")

	T.Stub.gossip.active = {}
	T.Stub.FireEvent("GOSSIP_SHOW")
	T.Equal(T.Stub.Called("SelectAvailableQuest"), 1, "available route quest selected")
end)

T.Test("AutoQuest: gossip ignores quests not on the route", function()
	T.Boot()
	T.Stub.gossip.available = { { questID = 424242, title = "Unrelated" } }
	T.Stub.FireEvent("GOSSIP_SHOW")
	T.Equal(T.Stub.Called("SelectAvailableQuest"), 0, "ignored")
end)

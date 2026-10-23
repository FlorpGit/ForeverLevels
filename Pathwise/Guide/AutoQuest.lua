-- Pathwise auto quests: accepts and hands in the quests the route asks for
-- (Engine.Wants) when the player talks to their NPC.
--
-- It only reacts to quest dialogs the player opened by talking to an NPC.
-- It never accepts a quest the route does not use, never picks between
-- rewards, and skips PvP-flagged quests and quests that cost money. Hold
-- Shift while opening the dialog to skip it once. On by default; each part
-- can be turned off in Settings > Quests (or /pw auto off).
--
-- Client APIs (Mainline QuestFrame.lua, which Forever loads, and
-- GossipInfoDocumentation): GetQuestID, QuestFlagsPVP, QuestGetAutoAccept,
-- AcknowledgeAutoAcceptQuest, AcceptQuest, IsQuestCompletable,
-- CompleteQuest, GetQuestMoneyToGet, GetNumQuestChoices, GetQuestReward,
-- C_GossipInfo.GetActiveQuests / GetAvailableQuests / SelectActiveQuest /
-- SelectAvailableQuest; for the old quest greeting GetNumActiveQuests,
-- GetActiveTitle, GetActiveQuestID, SelectActiveQuest,
-- GetNumAvailableQuests, GetAvailableQuestInfo, SelectAvailableQuest.

local ADDON, ns = ...
local R = ns.Compat.Readable

ns.Defaults("auto", {
	accept = true, -- accept the route's quests
	turnin = true, -- hand in the route's quests (a single reward or none)
	gossip = true, -- pick the route's quests from an NPC's list
	shift = true, -- holding Shift while talking skips it for that NPC
})

local function paused()
	return ns.Get("auto.shift") and IsShiftKeyDown and IsShiftKeyDown()
end

local function wants(q, verb)
	q = R(q)
	return type(q) == "number" and q ~= 0 and ns.Engine.Wants(q, verb)
end

-- The quest's details: Accept.
ns.RegisterEvent("QUEST_DETAIL", function()
	if not ns.Get("auto.accept") or paused() then return end
	if not wants(GetQuestID and GetQuestID(), "accept") then return end
	if QuestFlagsPVP and R(QuestFlagsPVP()) then return end
	if QuestGetAutoAccept and R(QuestGetAutoAccept()) then
		if AcknowledgeAutoAcceptQuest then AcknowledgeAutoAcceptQuest() end
	elseif AcceptQuest then
		AcceptQuest()
	end
end)

-- The quest's progress: Continue.
ns.RegisterEvent("QUEST_PROGRESS", function()
	if not ns.Get("auto.turnin") or paused() then return end
	if wants(GetQuestID and GetQuestID(), "turnin") and IsQuestCompletable and R(IsQuestCompletable()) then
		CompleteQuest()
	end
end)

-- The quest's rewards: Complete Quest, unless there is a reward to choose
-- or it costs money.
ns.RegisterEvent("QUEST_COMPLETE", function()
	if not ns.Get("auto.turnin") or paused() then return end
	local q = GetQuestID and R(GetQuestID())
	if not wants(q, "turnin") then return end
	if (GetQuestMoneyToGet and R(GetQuestMoneyToGet()) or 0) > 0 then return end
	local choices = R(GetNumQuestChoices()) or 0
	if choices <= 1 then
		GetQuestReward(choices)
	else
		ns.Print(("pick your reward for %s."):format(ns.Quests.Name(q)))
	end
end)

-- An NPC's gossip: a finished route quest first, then a route quest to take.
ns.RegisterEvent("GOSSIP_SHOW", function()
	if not ns.Get("auto.gossip") or paused() or not C_GossipInfo then return end
	if ns.Get("auto.turnin") then
		for _, info in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
			if R(info.isComplete) and wants(info.questID, "turnin") then
				C_GossipInfo.SelectActiveQuest(info.questID)
				return
			end
		end
	end
	if ns.Get("auto.accept") then
		for _, info in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
			if wants(info.questID, "accept") then
				C_GossipInfo.SelectAvailableQuest(info.questID)
				return
			end
		end
	end
end)

-- The old quest greeting (an NPC with several quests and no gossip text).
ns.RegisterEvent("QUEST_GREETING", function()
	if not ns.Get("auto.gossip") or paused() then return end
	if ns.Get("auto.turnin") then
		for i = 1, R(GetNumActiveQuests()) or 0 do
			local _, complete = GetActiveTitle(i)
			if R(complete) and wants(GetActiveQuestID(i), "turnin") then
				SelectActiveQuest(i)
				return
			end
		end
	end
	if ns.Get("auto.accept") then
		for i = 1, R(GetNumAvailableQuests()) or 0 do
			if wants(select(5, GetAvailableQuestInfo(i)), "accept") then
				SelectAvailableQuest(i)
				return
			end
		end
	end
end)

-- /pw auto [on|off]: every part at once.
ns.Command("auto", function(args)
	local a = (args or ""):lower()
	local on
	if a == "on" then on = true elseif a == "off" then on = false else on = not ns.Get("auto.accept") end
	for _, k in ipairs({ "accept", "turnin", "gossip" }) do ns.Set("auto." .. k, on) end
	ns.Print(on and "auto accept and turn-in on (hold Shift at an NPC to skip it once)." or "auto accept and turn-in off.")
end, "accept and hand in the route's quests at their NPC: /pw auto [on|off]")

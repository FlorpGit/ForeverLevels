-- ForeverLevels: optional party progress sharing over addon messages.
--
-- Off by default (/pathwise sync on). Each member broadcasts which route step they are on
-- and objective counts for that step's quests. Nothing is sent when:
--   * not in a group,
--   * the client is in chat messaging lockdown (Midnight-era restriction, active on Forever),
--   * outgoing addon messages are restricted (e.g. trial accounts on Forever 1.60.1).

local _, FL = ...

local Sync = {}
FL.Sync = Sync

Sync.PREFIX = "ForeverLevels"   -- must stay <= 16 characters
Sync.PROTOCOL = 1
Sync.members = {}              -- [shortName] = { routeId, index, total, level, title, quests, time }

local MAX_LENGTH = 250
local MIN_INTERVAL = 3          -- seconds between broadcasts
local STALE_AFTER = 120

local lastSent = 0
local pending = false

------------------------------------------------------------------------
-- Wire format (pipe separated, versioned):
--   1|S|<routeId>|<stepIndex>|<stepCount>|<level>|<stepTitle>|<qid>:<done>/<req>,...
------------------------------------------------------------------------

local function Clean(text)
	return (tostring(text or ""):gsub("[|,:]", " "))
end

function Sync.Encode(state)
	local quests = {}
	for _, quest in ipairs(state.quests or {}) do
		quests[#quests + 1] = string.format("%d:%d/%d", quest.id, quest.done, quest.required)
	end
	local message = table.concat({
		Sync.PROTOCOL, "S", Clean(state.routeId), state.index, state.total, state.level,
		Clean(state.title), table.concat(quests, ","),
	}, "|")
	if #message > MAX_LENGTH then
		message = message:sub(1, MAX_LENGTH)
	end
	return message
end

function Sync.Decode(message)
	local fields = {}
	for field in (message .. "|"):gmatch("([^|]*)|") do
		fields[#fields + 1] = field
	end
	if tonumber(fields[1]) ~= Sync.PROTOCOL or fields[2] ~= "S" then return nil end
	local state = {
		routeId = fields[3],
		index = tonumber(fields[4]),
		total = tonumber(fields[5]),
		level = tonumber(fields[6]),
		title = fields[7],
		quests = {},
	}
	if not state.index then return nil end
	for id, done, required in (fields[8] or ""):gmatch("(%d+):(%d+)/(%d+)") do
		state.quests[#state.quests + 1] = { id = tonumber(id), done = tonumber(done), required = tonumber(required) }
	end
	return state
end

------------------------------------------------------------------------
-- Sending
------------------------------------------------------------------------

local function CanSend()
	if not FL.db.profile.sync then return false end
	if not IsInGroup() then return false end
	if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return false end
	if C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted() then
		return false
	end
	return true
end

local function BuildState()
	local Engine = FL.Engine
	local route, step = Engine.route, Engine:GetCurrentStep()
	if not route or not step then return nil end
	local state = {
		routeId = route.id, index = Engine.index, total = #route.steps,
		level = FL.player.level, title = step.title, quests = {},
	}
	for _, goal in ipairs((FL.Engine.GetGoals(step, FL.player))) do
		if goal.kind == "complete" and FL.Quests.IsOnQuest(goal.questID) then
			local done, required = FL.Quests.GetProgress(goal.questID)
			state.quests[#state.quests + 1] = { id = goal.questID, done = done, required = required }
		end
	end
	return state
end

function Sync:Send()
	pending = false
	if not CanSend() then return end
	local state = BuildState()
	if not state then return end
	local channel = IsInRaid() and "RAID" or "PARTY"
	local ok, err = pcall(C_ChatInfo.SendAddonMessage, Sync.PREFIX, Sync.Encode(state), channel)
	if not ok then
		FL:Debug("sync send failed:", err)
	end
	lastSent = GetTime()
end

function Sync:Queue()
	if pending or not FL.db or not FL.db.profile.sync then return end
	pending = true
	local wait = math.max(0.5, MIN_INTERVAL - (GetTime() - lastSent))
	FL:After(wait, function() Sync:Send() end)
end

------------------------------------------------------------------------
-- Receiving
------------------------------------------------------------------------

local function ShortName(sender)
	if Ambiguate then return Ambiguate(sender, "short") end
	return (sender:gsub("%-.*$", ""))
end

FL:RegisterEvent("CHAT_MSG_ADDON", function(_, prefix, message, _channel, sender)
	if prefix ~= Sync.PREFIX or not FL.db or not FL.db.profile.sync then return end
	if FL.IsSecret(message) or FL.IsSecret(sender) then return end
	local name = ShortName(sender)
	if name == UnitName("player") then return end
	local state = Sync.Decode(message)
	if not state then return end
	state.time = GetTime()
	Sync.members[name] = state
	FL:Fire("PARTY_UPDATED")
end)

function Sync:GetMembers()
	local list, now = {}, GetTime()
	for name, state in pairs(self.members) do
		if now - state.time < STALE_AFTER then
			list[#list + 1] = { name = name, state = state }
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

FL:RegisterEvent("GROUP_ROSTER_UPDATE", function()
	if not IsInGroup() then
		wipe(Sync.members)
		FL:Fire("PARTY_UPDATED")
	else
		Sync:Queue()
	end
end)

FL:On("STEP_UPDATED", function() Sync:Queue() end)

function Sync:Init()
	C_ChatInfo.RegisterAddonMessagePrefix(Sync.PREFIX)
end

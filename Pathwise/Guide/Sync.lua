-- Pathwise party sync: optional sharing of where each group member is in
-- their route, over addon messages. Off by default (Settings > Party, or
-- /pw sync on). Each member sends their route, the step they are on and the
-- objective counts of its quests; the guide window lists the others.
--
-- Nothing is sent when:
--   * not in a group,
--   * the client is in chat messaging lockdown (Midnight's restriction,
--     active on Forever),
--   * outgoing addon messages are restricted (trial accounts on Forever).
--
-- Client APIs (ChatInfoDocumentation, ChatFrameUtil.lua):
--   C_ChatInfo.RegisterAddonMessagePrefix, SendAddonMessage,
--   InChatMessagingLockdown, AreOutgoingAddonChatMessagesRestricted,
--   CHAT_MSG_ADDON, IsInGroup, IsInRaid, Ambiguate, GROUP_ROSTER_UPDATE.

local ADDON, ns = ...
local R = ns.Compat.Readable
local Sync = {}
ns.Sync = Sync

-- The prefix the ForeverLevels builds used, so players on those still see
-- each other. Addon message prefixes are 16 characters at most.
Sync.PREFIX = "ForeverLevels"
Sync.PROTOCOL = 1
Sync.members = {} -- [short name] = { routeId, index, total, level, title, quests, time }

local MAX_LENGTH = 250 -- an addon message's limit is 255
local MIN_INTERVAL = 3 -- seconds between messages
local STALE_AFTER = 120 -- a member not heard from for this long is dropped

ns.Defaults("party", { sync = false })

local function now() return GetTime and GetTime() or 0 end

---------------------------------------------------------------------------
-- Wire format (pipe separated, versioned):
--   1|S|<routeId>|<step>|<steps>|<level>|<step title>|<quest>:<done>/<need>,...
---------------------------------------------------------------------------

local function clean(text)
	return (tostring(text or ""):gsub("[|,:]", " "))
end

function Sync.Encode(state)
	local quests = {}
	for _, q in ipairs(state.quests or {}) do
		quests[#quests + 1] = ("%d:%d/%d"):format(q.id, q.done, q.required)
	end
	local message = table.concat({
		Sync.PROTOCOL, "S", clean(state.routeId), state.index, state.total, state.level,
		clean(state.title), table.concat(quests, ","),
	}, "|")
	if #message > MAX_LENGTH then message = message:sub(1, MAX_LENGTH) end
	return message
end

function Sync.Decode(message)
	local fields = {}
	for field in (tostring(message) .. "|"):gmatch("([^|]*)|") do fields[#fields + 1] = field end
	if tonumber(fields[1]) ~= Sync.PROTOCOL or fields[2] ~= "S" then return nil end
	local state = {
		routeId = fields[3], index = tonumber(fields[4]), total = tonumber(fields[5]),
		level = tonumber(fields[6]), title = fields[7], quests = {},
	}
	if not state.index then return nil end
	for id, done, need in (fields[8] or ""):gmatch("(%d+):(%d+)/(%d+)") do
		state.quests[#state.quests + 1] = { id = tonumber(id), done = tonumber(done), required = tonumber(need) }
	end
	return state
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------

local function canSend()
	if not ns.Get("party.sync") or not (IsInGroup and R(IsInGroup())) then return false end
	local C = C_ChatInfo
	if not (C and C.SendAddonMessage) then return false end
	if C.InChatMessagingLockdown and R(C.InChatMessagingLockdown()) then return false end
	if C.AreOutgoingAddonChatMessagesRestricted and R(C.AreOutgoingAddonChatMessagesRestricted()) then return false end
	return true
end

-- What this character shares: the route's first open step and the counts
-- of the quests to complete there.
function Sync.State()
	local E, Q = ns.Engine, ns.Quests
	local route, s = E.Route(), E.LiveStep()
	if not (route and s) then return nil end
	local state = {
		routeId = route.id, index = s, total = #route.steps, level = Q.Player().level or 1,
		title = E.StepTitle(route, s) or "", quests = {},
	}
	for _, goal in ipairs(route.steps[s]) do
		if goal[1] == "complete" and Q.OnQuest(goal[2]) then
			local done, need = 0, 0
			for _, o in ipairs(Q.Objectives(goal[2]) or {}) do
				done, need = done + (o.have or 0), need + (o.need or 0)
			end
			state.quests[#state.quests + 1] = { id = goal[2], done = done, required = need }
		end
	end
	return state
end

local lastSent, pending = -MIN_INTERVAL, false

function Sync.Send()
	pending = false
	if not canSend() then return false end
	local state = Sync.State()
	if not state then return false end
	local channel = (IsInRaid and R(IsInRaid())) and "RAID" or "PARTY"
	local ok = pcall(C_ChatInfo.SendAddonMessage, Sync.PREFIX, Sync.Encode(state), channel)
	lastSent = now()
	return ok
end

-- At most one message every few seconds, however often the guide updates.
function Sync.Queue()
	if pending or not ns.Get("party.sync") then return end
	pending = true
	ns.After(math.max(0.5, MIN_INTERVAL - (now() - lastSent)), Sync.Send)
end

---------------------------------------------------------------------------
-- Receiving
---------------------------------------------------------------------------

local function shortName(sender)
	if Ambiguate then return Ambiguate(sender, "short") end
	return (sender:gsub("%-.*$", ""))
end

ns.RegisterEvent("CHAT_MSG_ADDON", function(_, prefix, message, _, sender)
	if prefix ~= Sync.PREFIX or not ns.Get("party.sync") then return end
	message, sender = R(message), R(sender)
	if type(message) ~= "string" or type(sender) ~= "string" then return end
	local name = shortName(sender)
	if name == R(UnitName("player")) then return end
	local state = Sync.Decode(message)
	if not state then return end
	state.time = now()
	Sync.members[name] = state
	ns.Fire("PARTY_UPDATED")
end)

-- Members heard from lately: { { name, state }, ... } by name.
function Sync.Members()
	local list, t = {}, now()
	for name, state in pairs(Sync.members) do
		if t - state.time < STALE_AFTER then list[#list + 1] = { name = name, state = state } end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

-- One line per member for the guide window, at most `max` (4).
function Sync.Lines(max)
	local out = {}
	if not ns.Get("party.sync") then return out end
	local route = ns.Engine.Route()
	for _, m in ipairs(Sync.Members()) do
		local st = m.state
		local counts = {}
		for _, q in ipairs(st.quests) do counts[#counts + 1] = q.done .. "/" .. q.required end
		local where = (route and st.routeId == route.id) and ("step %d/%d"):format(st.index, st.total or 0) or "another route"
		out[#out + 1] = ("%s (%d)  ·  %s  ·  %s%s"):format(m.name, st.level or 0, where, st.title or "",
			#counts > 0 and ("  " .. table.concat(counts, " ")) or "")
		if #out == (max or 4) then break end
	end
	return out
end

ns.RegisterEvent("GROUP_ROSTER_UPDATE", function()
	if IsInGroup and R(IsInGroup()) then
		Sync.Queue()
	elseif next(Sync.members) then
		Sync.members = {}
		ns.Fire("PARTY_UPDATED")
	end
end)

ns.On("GUIDE_UPDATED", Sync.Queue)
ns.On("READY", function()
	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		pcall(C_ChatInfo.RegisterAddonMessagePrefix, Sync.PREFIX)
	end
end)
ns.On("SETTING_CHANGED", function(path, value)
	if path ~= "party.sync" then return end
	if value then Sync.Queue() else Sync.members = {} end
	ns.Fire("PARTY_UPDATED")
end)

ns.Command("sync", function(args)
	local a = (args or ""):lower()
	local on
	if a == "on" then on = true elseif a == "off" then on = false else on = not ns.Get("party.sync") end
	ns.Set("party.sync", on)
	ns.Print(on and "party sync on: your group sees your step, you see theirs." or "party sync off.")
end, "share your route progress with your group: /pw sync [on|off]")

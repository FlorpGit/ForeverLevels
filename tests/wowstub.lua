-- Minimal fake of the WoW: Forever client API, enough to load ForeverLevels and
-- drive it from tests. Signatures follow Blizzard's API documentation on the
-- Gethe/wow-ui-source "forever" branch (1.60.1). This is not a game emulator.

local Stub = {}

local function noop() end

function Stub.Reset()
	Stub.time = 1000
	Stub.frames = {}
	Stub.chat = {}
	Stub.calls = {}
	Stub.quests = {}        -- [id] = { onQuest, complete, turnedIn, title, objectives }
	Stub.player = { class = "WARRIOR", race = "Scourge", faction = "Horde", level = 1, name = "Tester" }
	Stub.shift = false
	Stub.inGroup = false
	Stub.lockdown = false
	Stub.addonRestricted = false
	Stub.sent = {}
	Stub.questDialog = { questID = 0, choices = 0, completable = false, money = 0, autoAccept = false }
	Stub.gossip = { active = {}, available = {} }
	Stub.facing = 0
	Stub.playerMap = 2001
	Stub.playerPos = { x = 0.30, y = 0.70 }
	Stub.userWaypoint = nil
	Stub.superTracked = false
	-- Tiny map tree: world 1 -> continent 1000 -> Tirisfal 2001.
	-- Map positions convert to world yards with a 1000-yard square zone.
	Stub.maps = {
		[1] = { mapID = 1, name = "World", mapType = 1, parentMapID = 0 },
		[1000] = { mapID = 1000, name = "Eastern Kingdoms", mapType = 2, parentMapID = 1 },
		[2001] = { mapID = 2001, name = "Tirisfal Glades", mapType = 3, parentMapID = 1000 },
	}
end

local function Record(name, ...)
	Stub.calls[#Stub.calls + 1] = { name = name, args = { ... } }
end

function Stub.Called(name)
	local count = 0
	for _, call in ipairs(Stub.calls) do
		if call.name == name then count = count + 1 end
	end
	return count
end

function Stub.Quest(id)
	local quest = Stub.quests[id]
	if not quest then
		quest = { onQuest = false, complete = false, turnedIn = false, objectives = {} }
		Stub.quests[id] = quest
	end
	return quest
end

------------------------------------------------------------------------
-- Frames
------------------------------------------------------------------------

local FrameMethods = {}
FrameMethods.__index = function(self, key)
	local method = FrameMethods[key]
	if method then return method end
	return noop
end

function FrameMethods:SetScript(name, fn) self.scripts[name] = fn end
function FrameMethods:GetScript(name) return self.scripts[name] end
function FrameMethods:RegisterEvent(event) self.events[event] = true end
function FrameMethods:UnregisterEvent(event) self.events[event] = nil end
function FrameMethods:Show() self.shown = true end
function FrameMethods:Hide() self.shown = false end
function FrameMethods:SetShown(shown) self.shown = shown and true or false end
function FrameMethods:IsShown() return self.shown end
function FrameMethods:IsVisible() return self.shown end
function FrameMethods:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function FrameMethods:GetTop() return 500 end
function FrameMethods:GetBottom() return 300 end
function FrameMethods:SetText(text) self.text = text end
function FrameMethods:GetText() return self.text end
function FrameMethods:GetStringHeight() return 12 end
function FrameMethods:SetRotation(angle) self.rotation = angle end
function FrameMethods:SetAtlas(atlas) self.atlas = atlas end
function FrameMethods:SetBackdrop(backdrop) self.backdrop = backdrop end

local function NewObject()
	local object = setmetatable({ scripts = {}, events = {}, shown = true }, FrameMethods)
	return object
end
function FrameMethods:CreateFontString() return NewObject() end
function FrameMethods:CreateTexture() return NewObject() end

function Stub.FireEvent(event, ...)
	for _, frame in ipairs(Stub.frames) do
		if frame.events[event] and frame.scripts.OnEvent then
			frame.scripts.OnEvent(frame, event, ...)
		end
	end
end

-- Advances time and runs OnUpdate scripts (drives FL:After timers).
function Stub.Advance(seconds)
	local step = 0.1
	local elapsed = 0
	while elapsed < seconds do
		Stub.time = Stub.time + step
		elapsed = elapsed + step
		for _, frame in ipairs(Stub.frames) do
			local onUpdate = frame.scripts.OnUpdate
			if onUpdate then onUpdate(frame, step) end
		end
	end
end

------------------------------------------------------------------------
-- Global API
------------------------------------------------------------------------

function Stub.Install(env)
	env.CreateFrame = function()
		local frame = NewObject()
		frame.shown = true
		Stub.frames[#Stub.frames + 1] = frame
		return frame
	end
	env.UIParent = NewObject()
	env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) Stub.chat[#Stub.chat + 1] = text end }
	env.GetTime = function() return Stub.time end
	env.time = function() return 1790000000 end
	env.GetBuildInfo = function() return "1.60.1", "70450", "Oct 16 2026", 16001 end
	env.WOW_PROJECT_ID = 18
	env.WOW_PROJECT_CAMELOT = 18
	env.Enum = { UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3 } }
	env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
	env.SlashCmdList = {}
	env.Ambiguate = function(name) return (name:gsub("%-.*$", "")) end

	env.UnitClass = function() return "Class", Stub.player.class end
	env.UnitRace = function() return "Race", Stub.player.race end
	env.UnitFactionGroup = function() return Stub.player.faction end
	env.UnitLevel = function() return Stub.player.level end
	env.UnitName = function() return Stub.player.name end
	env.IsShiftKeyDown = function() return Stub.shift end
	env.IsInGroup = function() return Stub.inGroup end
	env.IsInRaid = function() return false end
	env.GetPlayerFacing = function() return Stub.facing end

	env.C_AddOns = { GetAddOnMetadata = function(_, field) if field == "Version" then return "0.1.0-test" end end }
	env.C_Texture = { GetAtlasInfo = function(atlas) return atlas == "Navigation-Tracked-Arrow" and {} or nil end }

	env.C_QuestLog = {
		IsOnQuest = function(id) return Stub.Quest(id).onQuest end,
		IsComplete = function(id) return Stub.Quest(id).complete end,
		IsQuestFlaggedCompleted = function(id) return Stub.Quest(id).turnedIn end,
		GetQuestObjectives = function(id) return Stub.Quest(id).objectives end,
		GetTitleForQuestID = function(id) return Stub.Quest(id).title end,
	}

	-- Quest dialog globals (Mainline QuestFrame.lua uses these on Forever).
	env.GetQuestID = function() return Stub.questDialog.questID end
	env.QuestFlagsPVP = function() return false end
	env.QuestGetAutoAccept = function() return Stub.questDialog.autoAccept end
	env.AcceptQuest = function() Record("AcceptQuest", Stub.questDialog.questID) end
	env.AcknowledgeAutoAcceptQuest = function() Record("AcknowledgeAutoAcceptQuest") end
	env.IsQuestCompletable = function() return Stub.questDialog.completable end
	env.CompleteQuest = function() Record("CompleteQuest") end
	env.GetQuestMoneyToGet = function() return Stub.questDialog.money end
	env.GetNumQuestChoices = function() return Stub.questDialog.choices end
	env.GetQuestReward = function(choice) Record("GetQuestReward", choice) end
	env.GetNumActiveQuests = function() return 0 end
	env.GetNumAvailableQuests = function() return 0 end

	env.C_GossipInfo = {
		GetActiveQuests = function() return Stub.gossip.active end,
		GetAvailableQuests = function() return Stub.gossip.available end,
		SelectActiveQuest = function(id) Record("SelectActiveQuest", id) end,
		SelectAvailableQuest = function(id) Record("SelectAvailableQuest", id) end,
	}

	local function Vector(x, y)
		return { x = x, y = y, GetXY = function(self) return self.x, self.y end }
	end
	env.CreateVector2D = Vector
	env.UiMapPoint = {
		CreateFromCoordinates = function(mapID, x, y) return { uiMapID = mapID, position = Vector(x, y) } end,
	}

	env.C_Map = {
		GetBestMapForUnit = function() return Stub.playerMap end,
		GetMapInfo = function(id) return Stub.maps[id] end,
		GetMapChildrenInfo = function(root, mapType)
			local list = {}
			for _, info in pairs(Stub.maps) do
				if info.mapType == mapType then list[#list + 1] = info end
			end
			return list
		end,
		GetPlayerMapPosition = function()
			if not Stub.playerPos then return nil end
			return Vector(Stub.playerPos.x, Stub.playerPos.y)
		end,
		-- Map x grows east, y grows south. World x grows north, y grows west.
		GetWorldPosFromMapPos = function(mapID, pos)
			if mapID ~= 2001 then return nil end
			return 0, Vector(-pos.y * 1000, -pos.x * 1000)
		end,
		CanSetUserWaypointOnMap = function() return true end,
		SetUserWaypoint = function(point) Stub.userWaypoint = point; Record("SetUserWaypoint", point) end,
		HasUserWaypoint = function() return Stub.userWaypoint ~= nil end,
		ClearUserWaypoint = function() Stub.userWaypoint = nil; Record("ClearUserWaypoint") end,
	}
	env.C_SuperTrack = {
		SetSuperTrackedUserWaypoint = function(on) Stub.superTracked = on end,
	}
	env.C_ChatInfo = {
		RegisterAddonMessagePrefix = function(prefix) Record("RegisterAddonMessagePrefix", prefix) return 0 end,
		SendAddonMessage = function(prefix, text, channel)
			Stub.sent[#Stub.sent + 1] = { prefix = prefix, text = text, channel = channel }
			return 0
		end,
		InChatMessagingLockdown = function() return Stub.lockdown end,
		AreOutgoingAddonChatMessagesRestricted = function() return Stub.addonRestricted end,
	}
	env.Settings = nil
end

return Stub

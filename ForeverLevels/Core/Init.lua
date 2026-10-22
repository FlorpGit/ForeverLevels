-- ForeverLevels: core namespace, event dispatch, internal messages and timers.
-- MIT License. See LICENSE.txt.

local addonName, FL = ...

-- Public namespace. Community route addons call ForeverLevels:RegisterRoute().
_G.ForeverLevels = FL

FL.name = addonName
FL.ROUTE_API_VERSION = 1

local function GetMetadata(field)
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		return C_AddOns.GetAddOnMetadata(addonName, field)
	end
end

FL.version = GetMetadata("Version") or "dev"

-- True on the World of Warcraft: Forever client (game type "forever"/"camelot").
function FL:IsForeverClient()
	return WOW_PROJECT_ID ~= nil and WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
end

-- Midnight-era "secret values" are active on Forever. Never compare or index a secret.
-- issecretvalue is documented with SecretArguments = "AllowedWhenUntainted", so an
-- error from tainted addon code is treated as "secret".
function FL.IsSecret(value)
	if issecretvalue == nil then return false end
	local ok, secret = pcall(issecretvalue, value)
	return not ok or secret and true or false
end

------------------------------------------------------------------------
-- Output
------------------------------------------------------------------------

local PREFIX = "|cff4fc3f7ForeverLevels|r: "

function FL:Print(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. table.concat(parts, " "))
end

function FL:Debug(...)
	if self.db and self.db.profile.debug then
		self:Print("|cff999999[debug]|r", ...)
	end
end

------------------------------------------------------------------------
-- Game events
------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
FL.eventFrame = eventFrame
local eventHandlers = {}

function FL:RegisterEvent(event, handler)
	local list = eventHandlers[event]
	if not list then
		list = {}
		eventHandlers[event] = list
		eventFrame:RegisterEvent(event)
	end
	list[#list + 1] = handler
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = eventHandlers[event]
	if not list then return end
	for i = 1, #list do
		list[i](event, ...)
	end
end)

------------------------------------------------------------------------
-- Internal messages (decouple modules from each other)
------------------------------------------------------------------------

local messageHandlers = {}

function FL:On(message, handler)
	local list = messageHandlers[message]
	if not list then
		list = {}
		messageHandlers[message] = list
	end
	list[#list + 1] = handler
end

function FL:Fire(message, ...)
	local list = messageHandlers[message]
	if not list then return end
	for i = 1, #list do
		list[i](...)
	end
end

------------------------------------------------------------------------
-- Timers. Implemented on OnUpdate so we depend on nothing beyond frames.
------------------------------------------------------------------------

local timerFrame = CreateFrame("Frame")
local timers = {}
local debounced = {}

local function OnTimerUpdate(_, elapsed)
	local now = GetTime()
	for i = #timers, 1, -1 do
		local timer = timers[i]
		if now >= timer.at then
			table.remove(timers, i)
			timer.fn()
		end
	end
	if #timers == 0 then
		timerFrame:SetScript("OnUpdate", nil)
	end
end

function FL:After(delay, fn)
	timers[#timers + 1] = { at = GetTime() + delay, fn = fn }
	timerFrame:SetScript("OnUpdate", OnTimerUpdate)
end

-- Coalesces bursts (QUEST_LOG_UPDATE fires many times in a row) into one call.
function FL:Debounce(key, delay, fn)
	if debounced[key] then return end
	debounced[key] = true
	self:After(delay, function()
		debounced[key] = nil
		fn()
	end)
end

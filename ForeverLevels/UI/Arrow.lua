-- ForeverLevels: directional arrow toward the current step's coordinates.
--
-- Direction needs GetPlayerFacing(), which Blizzard restricts: it returns nil in
-- instances (dungeons, raids, battlegrounds). There the arrow shows distance only,
-- or nothing if the client gives no position either.

local _, FL = ...

local Arrow = {}
FL.Arrow = Arrow

local Waypoint = FL.Waypoint

local UPDATE_INTERVAL = 0.05
local ARRIVAL_YARDS = 10
local ARROW_ATLAS = "Navigation-Tracked-Arrow"   -- used by Blizzard_QuestNavigation on Forever

local frame, elapsedSinceUpdate = nil, 0

local function SavePosition()
	local point, _, relPoint, x, y = frame:GetPoint(1)
	local saved = FL.db.profile.arrowFrame
	saved.point, saved.relPoint, saved.x, saved.y = point, relPoint, x, y
end

local function FormatDistance(yards)
	if yards >= 1000 then
		return string.format("%.1fk yd", yards / 1000)
	end
	return string.format("%d yd", math.floor(yards + 0.5))
end

local function SetArrowColor(angle)
	-- angle is 0..2pi; 0 means straight ahead.
	local off = math.min(angle, math.pi * 2 - angle)
	if off < 0.26 then
		frame.arrow:SetVertexColor(0.35, 1, 0.35)
	elseif off < 1.2 then
		frame.arrow:SetVertexColor(1, 0.85, 0.3)
	else
		frame.arrow:SetVertexColor(1, 0.4, 0.3)
	end
end

local function OnUpdate(_, elapsed)
	elapsedSinceUpdate = elapsedSinceUpdate + elapsed
	if elapsedSinceUpdate < UPDATE_INTERVAL then return end
	elapsedSinceUpdate = 0

	local distance, bearingOrReason = Waypoint:GetVector()
	if not distance then
		frame.arrow:Hide()
		if bearingOrReason == "continent" then
			frame.distance:SetText("on another continent")
		elseif bearingOrReason == "instance" then
			frame.distance:SetText("no position here")
		else
			frame.distance:SetText("")
		end
		return
	end

	if distance <= ARRIVAL_YARDS then
		frame.arrow:Hide()
		frame.distance:SetText("|cff55dd55arrived|r")
		return
	end

	frame.distance:SetText(FormatDistance(distance))
	local facing = GetPlayerFacing and GetPlayerFacing()
	if facing == nil or FL.IsSecret(facing) then
		frame.arrow:Hide()
		return
	end
	local angle = Waypoint.RelativeAngle(bearingOrReason, facing)
	frame.arrow:SetRotation(angle)
	SetArrowColor(angle)
	frame.arrow:Show()
end

function Arrow:Create()
	if frame then return frame end
	local saved = FL.db.profile.arrowFrame

	frame = CreateFrame("Frame", "ForeverLevelsArrow", UIParent)
	frame:SetSize(80, 84)
	frame:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
	frame:SetScale(saved.scale or 1)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		if not FL.db.profile.arrowFrame.locked then self:StartMoving() end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition()
	end)

	frame.arrow = frame:CreateTexture(nil, "ARTWORK")
	frame.arrow:SetSize(44, 44)
	frame.arrow:SetPoint("TOP", 0, -2)
	local hasAtlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(ARROW_ATLAS)
	if hasAtlas then
		frame.arrow:SetAtlas(ARROW_ATLAS)
	else
		frame.arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
	end

	frame.distance = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.distance:SetPoint("TOP", frame.arrow, "BOTTOM", 0, -2)

	frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.label:SetPoint("TOP", frame.distance, "BOTTOM", 0, -2)
	frame.label:SetWidth(180)
	frame.label:SetWordWrap(false)

	frame:SetScript("OnUpdate", OnUpdate)
	frame:Hide()
	self:Update()
	return frame
end

function Arrow:Update()
	if not frame then return end
	local target = Waypoint.target
	local show = FL.db.profile.arrow and target ~= nil
	if show then
		frame.label:SetText(target.title or "")
		elapsedSinceUpdate = UPDATE_INTERVAL
	end
	frame:SetShown(show)
end

FL:On("WAYPOINT_CHANGED", function() Arrow:Update() end)

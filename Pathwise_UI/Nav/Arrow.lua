-- Pathwise arrow: the Signature waypoint indicator. A faceted, compass-needle
-- dart (Media/arrow.tga) in icy blue, amber when the target is behind, a
-- compass mark when arrived; distance under it, the destination's name under
-- that. Shown only while there is a waypoint; hidden in instances and on
-- flights. Positions are sampled 10 times a second; between samples only the
-- rotation is eased toward the facing, so the work per frame is a few
-- arithmetic operations and one SetRotation.

local ADDON, ns = ...
local T, Nav = ns.Theme, ns.Nav
local abs, floor = math.abs, math.floor

ns.Defaults("arrow", {
	shown = true,
	scale = 1,
	point = nil, -- { point, x, y } once moved
})

local SAMPLE = 0.1 -- seconds between position samples
local BEHIND = 2.4 -- radians: past this the target counts as behind
local EASE = 12 -- rotation easing per second

local frame, dart, glow, mark, distText, titleText
local curRot, goalRot, hasRot = 0, 0, false
local accum = 0
local mode

local function build()
	frame = CreateFrame("Frame", "PathwiseArrow", UIParent)
	frame:SetSize(96, 120)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self) if IsShiftKeyDown and IsShiftKeyDown() then self:StartMoving() end end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, _, x, y = self:GetPoint(1)
		ns.Set("arrow.point", { p, floor(x + 0.5), floor(y + 0.5) })
	end)
	local saved = ns.Get("arrow.point")
	if type(saved) == "table" then
		frame:SetPoint(saved[1], UIParent, saved[1], saved[2], saved[3])
	else
		frame:SetPoint("TOP", UIParent, "TOP", 0, -140)
	end
	frame:SetScale(ns.Get("arrow.scale") or 1)

	glow = frame:CreateTexture(nil, "BACKGROUND")
	glow:SetTexture(T.MEDIA .. "arrow-glow")
	glow:SetSize(84, 84)
	glow:SetPoint("TOP", 0, 2)
	glow:SetBlendMode("ADD")

	dart = frame:CreateTexture(nil, "ARTWORK")
	dart:SetTexture(T.MEDIA .. "arrow")
	dart:SetSize(64, 64)
	dart:SetPoint("CENTER", glow, "CENTER")

	mark = frame:CreateTexture(nil, "ARTWORK")
	mark:SetTexture(T.MEDIA .. "arrived")
	mark:SetSize(48, 48)
	mark:SetPoint("CENTER", glow, "CENTER")
	mark:Hide()

	distText = T.Text(frame, "number", "text")
	distText:SetJustifyH("CENTER")
	distText:SetPoint("TOP", glow, "BOTTOM", 0, -2)
	distText:SetWidth(160)
	T.Shadow(distText)

	titleText = T.Text(frame, "meta", "text2")
	titleText:SetJustifyH("CENTER")
	titleText:SetPoint("TOP", distText, "BOTTOM", 0, -3)
	titleText:SetWidth(180)
	titleText:SetWordWrap(false)
	T.Shadow(titleText)

	frame:Hide()
end

local function tint(name, glowAlpha)
	local c = T.Color(name)
	dart:SetVertexColor(c[1], c[2], c[3])
	glow:SetVertexColor(c[1], c[2], c[3], glowAlpha or 0.35)
end

local function setMode(m)
	if m == mode then return end
	mode = m
	local arrived = m == "arrived"
	mark:SetShown(arrived)
	dart:SetShown(m == "travel")
	glow:SetShown(m == "travel")
	if arrived then
		ns.Fire("WAYPOINT_ARRIVED", Nav.Target())
		local c = T.Color("success")
		mark:SetVertexColor(c[1], c[2], c[3])
		T.TextColor(distText, "success")
		distText:SetText("Arrived")
	elseif m == "travel" then
		T.TextColor(distText, "text")
	else
		T.TextColor(distText, "text2")
		distText:SetText(m == "far" and "Far away" or "")
	end
end

local function sample()
	local state, dist, rot = Nav.Sample()
	if state == "none" or state == "instance" or state == "taxi" then
		frame:Hide()
		return
	end
	if state == "travel" then
		setMode("travel")
		local yards = Nav.FormatYards(dist)
		distText:SetText(yards)
		if ns.Guide and ns.Guide.SetDistance then ns.Guide.SetDistance(yards) end
		if rot then
			goalRot = rot
			if not hasRot then curRot, hasRot = rot, true end
			tint(abs(rot) > BEHIND and "warning" or "accent")
		end
	elseif state == "arrived" then
		setMode("arrived")
	else
		setMode(state)
	end
end

local function onUpdate(_, elapsed)
	accum = accum + elapsed
	if accum >= SAMPLE then
		accum = 0
		sample()
	end
	if mode == "travel" and hasRot then
		local d = Nav.Wrap(goalRot - curRot)
		local step = d * math.min(1, EASE * elapsed)
		curRot = Nav.Wrap(curRot + step)
		dart:SetRotation(curRot)
		glow:SetRotation(curRot)
	end
end

local function refresh(target)
	if not frame then build() end
	if not target or not ns.Get("arrow.shown") then
		frame:SetScript("OnUpdate", nil)
		frame:Hide()
		return
	end
	titleText:SetText(target.title or "")
	mode, hasRot, accum = nil, false, SAMPLE
	frame:Show()
	frame:SetScript("OnUpdate", onUpdate)
end

ns.On("WAYPOINT_CHANGED", refresh)
ns.On("SETTING_CHANGED", function(path)
	if path == "arrow.shown" then refresh(Nav.Target())
	elseif path == "arrow.scale" and frame then frame:SetScale(ns.Get("arrow.scale") or 1) end
end)
-- Leaving an instance or a flight shows the arrow again.
for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_CONTROL_GAINED" }) do
	ns.RegisterEvent(ev, function() if Nav.Target() then refresh(Nav.Target()) end end)
end

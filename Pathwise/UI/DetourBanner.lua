-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: profession detour banner, shown under the guide window.
-- It only calls the Detours module; it never touches the route.

local _, FL = ...

local Banner = {}
FL.DetourBanner = Banner

local Detours = FL.Detours

local frame

local function CreateText(parent, font)
	local text = parent:CreateFontString(nil, "OVERLAY", font)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(true)
	return text
end

local function CreateButton(parent)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(82, 22)
	return button
end

function Banner:Create(parent)
	if frame or not parent then return frame end
	frame = CreateFrame("Frame", "ForeverLevelsDetourBanner", parent, "BackdropTemplate")
	frame:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -4)
	frame:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, -4)
	frame:SetHeight(90)
	frame.label = CreateText(frame, "GameFontNormalSmall")
	frame.title = CreateText(frame, "GameFontNormal")
	frame.text = CreateText(frame, "GameFontHighlightSmall")
	frame.note = CreateText(frame, "GameFontDisableSmall")
	frame.buttons = { CreateButton(frame), CreateButton(frame), CreateButton(frame) }
	frame:Hide()
	self:Update()
	return frame
end

local function SetButtons(actions)
	for i, button in ipairs(frame.buttons) do
		local action = actions[i]
		if action then
			button:SetText(action[1])
			button:SetScript("OnClick", action[2])
			button:Show()
		else
			button:Hide()
		end
	end
end

function Banner:Update()
	if not frame then return end
	local active = Detours:GetActive()
	local suggestion = Detours.suggestion
	local detour = active or suggestion
	if not detour then
		frame:Hide()
		return
	end

	local pad = FL.GuideFrame.ApplyBackdrop(frame)
	local width = (frame:GetWidth() or 320) - pad * 2
	if width <= 0 then width = 320 - pad * 2 end

	frame.label:SetText(active and "Profession detour (active)" or "Profession detour (optional)")
	frame.title:SetText(detour.title)
	frame.text:SetText(detour.text or "")
	frame.note:SetText(detour.note or "")

	local last
	for _, text in ipairs({ frame.label, frame.title, frame.text, frame.note }) do
		text:SetWidth(width)
		text:ClearAllPoints()
		if last then
			text:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -3)
		else
			text:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -pad)
		end
		last = text
	end

	if active then
		SetButtons({
			{ "Done", function() Detours:Complete() end },
			{ "Cancel", function() Detours:Cancel() end },
		})
	else
		SetButtons({
			{ "Go", function() Detours:Accept() end },
			{ "Later", function() Detours:Postpone() end },
			{ "Skip", function() Detours:Skip() end },
		})
	end
	for i, button in ipairs(frame.buttons) do
		button:ClearAllPoints()
		button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", pad + (i - 1) * 88, pad)
	end

	local top, bottom = frame:GetTop(), last:GetBottom()
	local height = 96
	if top and bottom then height = (top - bottom) + pad + 30 end
	frame:SetHeight(math.max(70, height))
	frame:Show()
end

FL:On("DETOUR_CHANGED", function() Banner:Update() end)
FL:On("STYLE_CHANGED", function() Banner:Update() end)

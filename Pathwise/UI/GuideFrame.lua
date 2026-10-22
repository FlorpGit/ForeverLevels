-- SPDX-License-Identifier: GPL-3.0-only
-- ForeverLevels: the movable step-by-step guide window.

local _, FL = ...

local GuideFrame = {}
FL.GuideFrame = GuideFrame

local Engine, Quests = FL.Engine, FL.Quests

local WIDTH = 320
local MAX_LINES = 16
local MAX_PARTY = 4

-- Window styles. "classic" and "tooltip" use the same art as Forever's own classic
-- dialogs and tooltips (see Blizzard_SharedXML/Backdrop.lua on the forever branch).
-- "pathwise" is the same dialog art recolored to the Pathwise logo: blue-black
-- background, cool silver frame, silver headings, ice-blue titles and steel-blue
-- buttons (Blizzard's button art desaturated and tinted, not replaced).
-- Optional per-style colors: heading, title, buttonText ({ r, g, b }) and tint
-- (button texture tint). Styles without them use Blizzard's gold.
local DIALOG_BACKDROP = BACKDROP_DARK_DIALOG_32_32 or {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileEdge = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local STYLES = {
	pathwise = {
		label = "Pathwise",
		backdrop = DIALOG_BACKDROP,
		pad = 18, bg = { 0.42, 0.52, 0.70, 0.96 }, border = { 0.78, 0.86, 1, 1 }, close = { -5, -5 },
		heading = { 0.80, 0.85, 0.91 }, title = { 0.43, 0.80, 1 },
		tint = { 0.55, 0.72, 0.95 }, buttonText = { 0.88, 0.94, 1 },
	},
	classic = {
		label = "Classic",
		backdrop = DIALOG_BACKDROP,
		pad = 18, bg = { 1, 1, 1, 0.92 }, border = { 1, 1, 1, 1 }, close = { -5, -5 },
	},
	tooltip = {
		label = "Tooltip",
		backdrop = {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		},
		pad = 12, bg = { 0, 0, 0, 0.85 }, border = { 0.8, 0.8, 0.8, 1 }, close = { -1, -1 },
	},
	minimal = {
		label = "Minimal",
		backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 },
		pad = 10, bg = { 0.04, 0.05, 0.07, 0.86 }, border = { 0.31, 0.76, 0.97, 0.55 }, close = { 2, 2 },
	},
}
GuideFrame.STYLES = STYLES
GuideFrame.STYLE_ORDER = { "pathwise", "classic", "tooltip", "minimal" }
GuideFrame.DEFAULT_STYLE = "pathwise"

local GOLD = { 1, 0.82, 0 }   -- GameFontNormal

local pad = STYLES.pathwise.pad

function GuideFrame.GetStyle()
	return STYLES[FL.db.profile.frame.style] or STYLES[GuideFrame.DEFAULT_STYLE]
end

-- Colors a font string for its role ("heading" or "title") in the current style.
function GuideFrame.ColorText(fontString, role)
	local c = GuideFrame.GetStyle()[role] or GOLD
	fontString:SetTextColor(c[1], c[2], c[3])
end

-- Inline color code for highlighted text in the current style, e.g. "|cff6ecbff".
function GuideFrame.AccentCode()
	local c = GuideFrame.GetStyle().title or GOLD
	return string.format("|cff%02x%02x%02x", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- Recolors a Blizzard template button (UIPanelButtonTemplate, UIPanelCloseButton) for
-- the current style. Textures are desaturated and tinted; nothing is replaced, so
-- switching back to a gold style restores the original look.
function GuideFrame.StyleButton(button)
	local style = GuideFrame.GetStyle()
	local tint = style.tint
	for _, region in ipairs({ button:GetRegions() }) do
		if region:GetObjectType() == "Texture" then
			region:SetDesaturated(tint ~= nil)
			if tint then
				region:SetVertexColor(tint[1], tint[2], tint[3])
			else
				region:SetVertexColor(1, 1, 1)
			end
		end
	end
	local text = button:GetFontString()
	if text then
		local c = style.buttonText or GOLD
		text:SetTextColor(c[1], c[2], c[3])
	end
end

local COLOR_DONE = "|cff55dd55"
local COLOR_OPEN = "|cffdddddd"
local COLOR_DIM = "|cff888888"
local COLOR_WARN = "|cffffcc55"

local GOAL_LABELS = { accept = "Accept", complete = "Complete", turnin = "Turn in" }

local frame

local function CreateText(parent, font, justify)
	local text = parent:CreateFontString(nil, "OVERLAY", font)
	text:SetJustifyH(justify or "LEFT")
	text:SetWordWrap(true)
	parent.texts[#parent.texts + 1] = text
	return text
end

local function CreateButton(parent, label, width, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 22)
	button:SetText(label)
	button:SetScript("OnClick", onClick)
	return button
end

local function SavePosition()
	local point, _, relPoint, x, y = frame:GetPoint(1)
	local saved = FL.db.profile.frame
	saved.point, saved.relPoint, saved.x, saved.y = point, relPoint, x, y
end

function GuideFrame:Create()
	if frame then return frame end
	local saved = FL.db.profile.frame

	frame = CreateFrame("Frame", "ForeverLevelsGuideFrame", UIParent, "BackdropTemplate")
	frame:SetSize(WIDTH, 200)
	frame:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
	frame:SetScale(saved.scale or 1)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(f)
		if not FL.db.profile.frame.locked then f:StartMoving() end
	end)
	frame:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
		SavePosition()
	end)
	frame.texts = {}

	frame.header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.header:SetJustifyH("LEFT")
	frame.header:SetWordWrap(false)

	frame.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

	frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	frame.close:SetSize(22, 22)
	frame.close:SetScript("OnClick", function() GuideFrame:SetShown(false) end)

	frame.title = CreateText(frame, "GameFontNormalLarge")
	frame.body = CreateText(frame, "GameFontHighlight")
	frame.lines = {}
	for i = 1, MAX_LINES do
		frame.lines[i] = CreateText(frame, "GameFontHighlightSmall")
	end
	frame.note = CreateText(frame, "GameFontDisableSmall")
	frame.dungeon = CreateText(frame, "GameFontNormalSmall")
	frame.party = {}
	for i = 1, MAX_PARTY do
		frame.party[i] = CreateText(frame, "GameFontHighlightSmall")
	end

	frame.prev = CreateButton(frame, "Back", 70, function() Engine:Prev() end)
	frame.nextButton = CreateButton(frame, "Next", 70, function() Engine:Next() end)
	frame.professionsButton = CreateButton(frame, "Professions", 92, function() FL.Dashboard:Toggle() end)

	-- Report button next to Back. Opens the Feedback Center with this step filled in;
	-- it only reads the step and never changes it.
	frame.reportButton = CreateFrame("Button", nil, frame)
	frame.reportButton:SetSize(20, 20)
	frame.reportButton:SetNormalTexture("Interface\\HelpFrame\\OpenTicketIcon")
	frame.reportButton:SetHighlightTexture("Interface\\HelpFrame\\OpenTicketIcon", "ADD")
	frame.reportButton:SetScript("OnClick", function() FL.FeedbackCenter:OpenForStep() end)
	frame.reportButton:SetScript("OnEnter", function(button)
		GameTooltip:SetOwner(button, "ANCHOR_TOP")
		GameTooltip:SetText("Report an issue with this guide step.")
		GameTooltip:Show()
	end)
	frame.reportButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

	self:ApplyStyle()
	frame:SetShown(saved.shown)
	return frame
end

function GuideFrame.GetFrame()
	return frame
end

-- Applies the current window style's backdrop to any BackdropTemplate frame and
-- returns the style's padding. Other Pathwise windows use this to match the guide.
function GuideFrame.ApplyBackdrop(target)
	local style = GuideFrame.GetStyle()
	target:SetBackdrop(style.backdrop)
	target:SetBackdropColor(style.bg[1], style.bg[2], style.bg[3], style.bg[4])
	target:SetBackdropBorderColor(style.border[1], style.border[2], style.border[3], style.border[4])
	return style.pad, style
end

-- Applies the saved window style: backdrop, colors, padding and anchors.
function GuideFrame:ApplyStyle()
	if not frame then return end
	local style
	pad, style = GuideFrame.ApplyBackdrop(frame)

	frame.header:ClearAllPoints()
	frame.header:SetPoint("TOPLEFT", pad, -pad)
	frame.header:SetPoint("RIGHT", -70, 0)
	frame.counter:ClearAllPoints()
	frame.counter:SetPoint("TOPRIGHT", -(pad + 18), -pad)
	frame.close:ClearAllPoints()
	frame.close:SetPoint("TOPRIGHT", style.close[1], style.close[2])
	frame.prev:ClearAllPoints()
	frame.prev:SetPoint("BOTTOMLEFT", pad, pad)
	frame.nextButton:ClearAllPoints()
	frame.nextButton:SetPoint("BOTTOMRIGHT", -pad, pad)
	frame.professionsButton:ClearAllPoints()
	frame.professionsButton:SetPoint("BOTTOM", 0, pad)
	frame.reportButton:ClearAllPoints()
	frame.reportButton:SetPoint("LEFT", frame.prev, "RIGHT", 2, 0)

	local inner = WIDTH - pad * 2
	for _, text in ipairs(frame.texts) do
		text:SetWidth(inner)
	end
	GuideFrame.ColorText(frame.header, "heading")
	GuideFrame.ColorText(frame.title, "title")
	GuideFrame.ColorText(frame.dungeon, "heading")
	for _, button in ipairs({ frame.prev, frame.nextButton, frame.professionsButton, frame.close }) do
		GuideFrame.StyleButton(button)
	end
	self:Update()
	FL:Fire("STYLE_CHANGED", FL.db.profile.frame.style)
end

function GuideFrame:SetStyle(name)
	if not STYLES[name] then return false end
	FL.db.profile.frame.style = name
	self:ApplyStyle()
	return true
end

-- Moves to the next style in STYLE_ORDER and returns its name.
function GuideFrame:CycleStyle()
	local current = FL.db.profile.frame.style
	local order = self.STYLE_ORDER
	local nextIndex = 1
	for i, name in ipairs(order) do
		if name == current then nextIndex = i % #order + 1 end
	end
	self:SetStyle(order[nextIndex])
	return order[nextIndex]
end

function GuideFrame:SetShown(shown)
	FL.db.profile.frame.shown = shown and true or false
	if frame then
		frame:SetShown(shown)
		if shown then self:Update() end
	end
end

function GuideFrame:Toggle()
	self:SetShown(not (frame and frame:IsShown()))
end

function GuideFrame:ApplySettings()
	if not frame then return end
	local saved = FL.db.profile.frame
	frame:SetScale(saved.scale or 1)
	frame:ClearAllPoints()
	frame:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
end

------------------------------------------------------------------------
-- Content
------------------------------------------------------------------------

local function GoalLines(step, route, player)
	local lines = {}
	for _, goal in ipairs((Engine.GetGoals(step, player))) do
		local color = goal.done and COLOR_DONE or COLOR_OPEN
		local mark = goal.done and "[x] " or "[  ] "
		if goal.kind == "level" then
			lines[#lines + 1] = color .. mark .. "Reach level " .. goal.level .. COLOR_DIM .. " (now " .. player.level .. ")|r"
		else
			lines[#lines + 1] = color .. mark .. GOAL_LABELS[goal.kind] .. ": " .. Quests.GetTitle(goal.questID, route) .. "|r"
			if goal.kind == "complete" and not goal.done then
				for _, objective in ipairs(Quests.GetObjectives(goal.questID)) do
					if objective.text and not FL.IsSecret(objective.text) then
						local objColor = objective.finished and COLOR_DONE or COLOR_DIM
						lines[#lines + 1] = "      " .. objColor .. objective.text .. "|r"
					end
				end
			end
		end
	end
	return lines
end

local function DungeonLine(step, player)
	if step.dungeon then
		local dungeon = FL:GetDungeon(step.dungeon)
		if dungeon then
			return string.format("Dungeon: %s (%d-%d) - %s", dungeon.name, dungeon.min, dungeon.max, dungeon.zone or "")
		end
	end
	if FL.db.profile.suggestDungeons then
		local names = {}
		for _, dungeon in ipairs(FL:GetDungeonSuggestions(player.level, player.faction)) do
			names[#names + 1] = string.format("%s (%d-%d)", dungeon.name, dungeon.min, dungeon.max)
			if #names == 2 then break end
		end
		if #names > 0 then
			return "Dungeons at your level: " .. table.concat(names, ", ")
		end
	end
	return nil
end

local function PartyLines()
	local lines = {}
	if not FL.db.profile.sync then return lines end
	for _, member in ipairs(FL.Sync:GetMembers()) do
		local state = member.state
		local counts = {}
		for _, quest in ipairs(state.quests) do
			counts[#counts + 1] = quest.done .. "/" .. quest.required
		end
		local sameRoute = Engine.route and state.routeId == Engine.route.id
		local where = sameRoute and string.format("step %d/%d", state.index, state.total) or ("other route")
		lines[#lines + 1] = string.format("|cff4fc3f7%s|r (%s) %s %s%s|r %s",
			member.name, tostring(state.level), where, COLOR_DIM, state.title or "", table.concat(counts, " "))
		if #lines == MAX_PARTY then break end
	end
	return lines
end

local function Stack(widget, anchor, gap)
	widget:ClearAllPoints()
	widget:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
	widget:Show()
	return widget
end

function GuideFrame:Update()
	if not frame or not frame:IsShown() then return end
	local route, step = Engine.route, Engine:GetCurrentStep()
	local player = FL.player

	for _, line in ipairs(frame.lines) do line:Hide() end
	for _, line in ipairs(frame.party) do line:Hide() end
	frame.note:Hide()
	frame.dungeon:Hide()

	frame.title:ClearAllPoints()
	frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -pad - 18)

	if not route or not step then
		frame.header:SetText(FL.BRAND)
		frame.reportButton:Hide()
		frame.counter:SetText("")
		frame.title:SetText("No route selected")
		frame.body:SetText("Type /pathwise routes to list installed routes, then /pathwise route <id>.")
		Stack(frame.body, frame.title, 6)
		frame:SetHeight(110)
		return
	end

	frame.header:SetText(FL.BRAND .. " - " .. route.title)
	frame.reportButton:Show()
	frame.counter:SetText(string.format("%d/%d", Engine.index, #route.steps))

	local state = Engine.GetStepState(step, player)
	local title = step.title
	if Engine.hold then title = title .. COLOR_DIM .. "  (viewing)|r" end
	if state == "done" then title = COLOR_DONE .. title .. "|r" end
	frame.title:SetText(title)

	local body = Engine.GetStepText(step, player)
	if step.x then
		body = body .. COLOR_DIM .. string.format("  (%.1f, %.1f%s)", step.x, step.y,
			(step.zone or route.zone) and (" " .. (step.zone or route.zone)) or "") .. "|r"
	end
	frame.body:SetText(body)
	local last = Stack(frame.body, frame.title, 4)

	local lines = GoalLines(step, route, player)
	for i = 1, math.min(#lines, MAX_LINES) do
		frame.lines[i]:SetText(lines[i])
		last = Stack(frame.lines[i], last, i == 1 and 8 or 2)
	end

	local notes = {}
	if step.note then notes[#notes + 1] = step.note end
	if state == "manual" then notes[#notes + 1] = "Press Next when done." end
	if Engine.hold then notes[#notes + 1] = "Auto-advance paused. Press Next to resume." end
	if not step.verified and not route.verified then
		notes[#notes + 1] = COLOR_WARN .. "Not yet verified on Forever.|r"
	end
	if #notes > 0 then
		frame.note:SetText(table.concat(notes, "\n"))
		last = Stack(frame.note, last, 8)
	end

	local dungeonText = DungeonLine(step, player)
	if dungeonText then
		frame.dungeon:SetText(dungeonText)
		last = Stack(frame.dungeon, last, 6)
	end

	local partyLines = PartyLines()
	for i, text in ipairs(partyLines) do
		frame.party[i]:SetText(text)
		last = Stack(frame.party[i], last, i == 1 and 8 or 2)
	end

	-- Height: everything stacked from the top plus the button row.
	local top = frame:GetTop()
	local bottom = last:GetBottom()
	local height = 180
	if top and bottom then
		height = (top - bottom) + pad + 32
	end
	frame:SetHeight(math.max(110, height))
end

FL:On("STEP_UPDATED", function() GuideFrame:Update() end)
FL:On("STEP_CHANGED", function() GuideFrame:Update() end)
FL:On("PARTY_UPDATED", function() GuideFrame:Update() end)

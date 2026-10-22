-- ForeverLevels: the movable step-by-step guide window.

local _, FL = ...

local GuideFrame = {}
FL.GuideFrame = GuideFrame

local Engine, Quests = FL.Engine, FL.Quests

local WIDTH = 320
local PAD = 10
local INNER = WIDTH - PAD * 2
local MAX_LINES = 16
local MAX_PARTY = 4

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
	text:SetWidth(INNER)
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
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0.04, 0.05, 0.07, 0.86)
	frame:SetBackdropBorderColor(0.31, 0.76, 0.97, 0.55)

	frame.header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.header:SetPoint("TOPLEFT", PAD, -PAD)
	frame.header:SetPoint("RIGHT", -70, 0)
	frame.header:SetJustifyH("LEFT")
	frame.header:SetWordWrap(false)

	frame.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.counter:SetPoint("TOPRIGHT", -28, -PAD)

	frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	frame.close:SetSize(22, 22)
	frame.close:SetPoint("TOPRIGHT", 2, 2)
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
	frame.prev:SetPoint("BOTTOMLEFT", PAD, PAD)
	frame.nextButton:SetPoint("BOTTOMRIGHT", -PAD, PAD)

	frame:SetShown(saved.shown)
	return frame
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
	frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD - 18)

	if not route or not step then
		frame.header:SetText("ForeverLevels")
		frame.counter:SetText("")
		frame.title:SetText("No route selected")
		frame.body:SetText("Type /fl routes to list installed routes, then /fl route <id>.")
		Stack(frame.body, frame.title, 6)
		frame:SetHeight(110)
		return
	end

	frame.header:SetText(route.title)
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
		height = (top - bottom) + PAD + 32
	end
	frame:SetHeight(math.max(110, height))
end

FL:On("STEP_UPDATED", function() GuideFrame:Update() end)
FL:On("STEP_CHANGED", function() GuideFrame:Update() end)
FL:On("PARTY_UPDATED", function() GuideFrame:Update() end)

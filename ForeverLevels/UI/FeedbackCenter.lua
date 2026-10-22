-- ForeverLevels: the Feedback Center window. The single place to prepare bug reports,
-- suggestions and guide step reports. Opened by /pathwise feedback, the options panel,
-- or the report button on the guide window (which fills in the current step).
-- Reports are prepared as text for the player to copy; nothing is sent.

local _, FL = ...

local Center = {}
FL.FeedbackCenter = Center

local Feedback = FL.Feedback

local WIDTH = 460
local DIM = "|cff888888"
local BAD = "|cffff6655"
local GOOD = "|cff55dd55"

-- Which optional fields each report type shows.
local FIELDS_FOR_TYPE = {
	step = { correctCoords = true, correctNpc = true, replacement = true, repro = true },
	bug = { repro = true },
	suggestion = {},
}

local frame

------------------------------------------------------------------------
-- Widget helpers
------------------------------------------------------------------------

local function Text(parent, font)
	local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
	text:SetJustifyH("LEFT")
	text:SetWordWrap(true)
	return text
end

local function Button(parent, width, label, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 22)
	button:SetText(label)
	button:SetScript("OnClick", onClick)
	return button
end

-- Single-line input that saves into the current draft as you type.
local function Input(parent, field, width)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(width, 20)
	box:SetAutoFocus(false)
	box:SetMaxLetters(400)
	box.field = field
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then Feedback.SetField(field, self:GetText()) end
	end)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	box.box = box   -- same shape as MultiLine: input.box is always the edit box
	return box
end

-- Multi-line box inside a scroll frame. Read-only boxes can be selected and copied
-- but any typing is undone.
local function MultiLine(parent, width, height, field, readOnly)
	local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
	scroll:SetSize(width - 26, height)
	local box = CreateFrame("EditBox", nil, scroll)
	box:SetMultiLine(true)
	box:SetAutoFocus(false)
	box:SetFontObject("GameFontHighlightSmall")
	box:SetWidth(width - 30)
	box:SetMaxLetters(readOnly and 0 or 2000)
	box.field = field
	box:SetScript("OnTextChanged", function(self, userInput)
		if not userInput then return end
		if readOnly then
			self:SetText(self.fixedText or "")
			self:HighlightText()
		elseif field then
			Feedback.SetField(field, self:GetText())
		end
	end)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	if readOnly then
		box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	end
	scroll:SetScrollChild(box)
	scroll.box = box
	box.fixedText = false
	return scroll
end

local function Cycle(list, current, skip)
	local index = 0
	for i, entry in ipairs(list) do
		if entry.key == current then index = i end
	end
	for step = 1, #list do
		local entry = list[(index + step - 1) % #list + 1]
		if not (skip and skip[entry.key]) then return entry.key end
	end
	return current
end

------------------------------------------------------------------------
-- Frame
------------------------------------------------------------------------

local function SavePosition()
	local point, _, relPoint, x, y = frame:GetPoint(1)
	local saved = FL.db.profile.feedbackFrame
	saved.point, saved.relPoint, saved.x, saved.y = point, relPoint, x, y
end

function Center:Create()
	if frame then return frame end
	local saved = FL.db.profile.feedbackFrame
	frame = CreateFrame("Frame", "ForeverLevelsFeedbackCenter", UIParent, "BackdropTemplate")
	frame:SetSize(WIDTH, 520)
	frame:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
	frame:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
		SavePosition()
	end)

	frame.header = Text(frame, "GameFontNormal")
	frame.header:SetText(FL.BRAND .. " Feedback")
	frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	frame.close:SetSize(22, 22)
	frame.close:SetScript("OnClick", function() Center:Hide() end)

	frame.typeButton = Button(frame, 200, "", function()
		local draft = Feedback.GetCurrentDraft()
		Feedback.SetField("type", Cycle(Feedback.TYPES, draft.type, not draft.context and { step = true } or nil))
		Center:Refresh()
	end)
	frame.categoryButton = Button(frame, WIDTH - 60, "", function()
		local draft = Feedback.GetCurrentDraft()
		Feedback.SetField("category", Cycle(Feedback.STEP_CATEGORIES, draft.category))
		Center:Refresh()
	end)
	frame.context = Text(frame)

	frame.labels, frame.inputs = {}, {}
	frame.labels.description = Text(frame, "GameFontNormalSmall")
	frame.labels.description:SetText("What happened? (required)")
	frame.inputs.description = MultiLine(frame, WIDTH - 40, 60, "description")

	local optional = {
		{ "correctCoords", "Correct coordinates (optional, e.g. 61.7, 52.0)" },
		{ "correctNpc", "Correct NPC name (optional)" },
		{ "replacement", "Suggested instructions (optional)" },
		{ "repro", "Steps to reproduce (optional)" },
	}
	for _, entry in ipairs(optional) do
		frame.labels[entry[1]] = Text(frame, "GameFontNormalSmall")
		frame.labels[entry[1]]:SetText(entry[2])
		frame.inputs[entry[1]] = Input(frame, entry[1], entry[1] == "correctCoords" and 190 or WIDTH - 50)
	end
	frame.positionButton = Button(frame, 130, "Use my position", function()
		local _, zone, x, y = FL.Recorder.GetPosition()
		if x then
			local value = string.format("%.1f, %.1f %s", x, y, zone or "")
			frame.inputs.correctCoords:SetText(value)
			Feedback.SetField("correctCoords", value)
		end
	end)

	frame.previewTitle = Text(frame, "GameFontNormalSmall")
	frame.previewTitle:SetText("Information in this report (read-only)")
	frame.preview = Text(frame, "GameFontDisableSmall")
	frame.characterButton = Button(frame, 205, "", function()
		local draft = Feedback.GetCurrentDraft()
		Feedback.SetField("includeCharacter", not draft.includeCharacter)
		Center:Refresh()
	end)
	frame.diagnosticsButton = Button(frame, 205, "", function()
		local draft = Feedback.GetCurrentDraft()
		Feedback.SetField("includeDiagnostics", not draft.includeDiagnostics)
		Center:Refresh()
	end)

	frame.prepareButton = Button(frame, 130, "Prepare report", function() Center:Prepare() end)
	frame.discardButton = Button(frame, 110, "Discard draft", function()
		Feedback.DiscardCurrent()
		Center:Hide()
		FL:Print("feedback draft discarded")
	end)
	frame.status = Text(frame)
	frame.output = MultiLine(frame, WIDTH - 40, 110, nil, true)

	frame:Hide()
	return frame
end

function Center:IsShown()
	return frame ~= nil and frame:IsShown()
end

function Center:Hide()
	if frame then frame:Hide() end
end

local function Place(widget, anchor, gap, x)
	widget:ClearAllPoints()
	widget:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, -gap)
	widget:Show()
	return widget
end

-- Re-lays out the window from the current draft.
function Center:Refresh()
	if not frame then return end
	local draft = Feedback.GetCurrentDraft()
	if not draft then return end
	local pad = FL.GuideFrame.ApplyBackdrop(frame)
	local inner = WIDTH - pad * 2

	frame.header:ClearAllPoints()
	frame.header:SetPoint("TOPLEFT", pad, -pad)
	frame.close:ClearAllPoints()
	frame.close:SetPoint("TOPRIGHT", -(pad - 12), -(pad - 12))

	frame.typeButton:SetText("Type: " .. (Feedback.Label(Feedback.TYPES, draft.type) or draft.type))
	local last = Place(frame.typeButton, frame.header, 8)

	local isStep = draft.type == "step"
	if isStep then
		frame.categoryButton:SetText("Problem: " .. (Feedback.Label(Feedback.STEP_CATEGORIES, draft.category) or "click to choose"))
		last = Place(frame.categoryButton, last, 4)
		local ctx = draft.context
		frame.context:SetWidth(inner)
		frame.context:SetText(ctx and string.format("Reporting step %d/%d: %s (%s)", ctx.stepIndex, ctx.stepCount, ctx.stepTitle, ctx.routeTitle)
			or (BAD .. "No guide step selected.|r"))
		last = Place(frame.context, last, 6)
	else
		frame.categoryButton:Hide()
		frame.context:Hide()
	end

	last = Place(frame.labels.description, last, 10)
	last = Place(frame.inputs.description, last, 4)
	local visible = FIELDS_FOR_TYPE[draft.type] or {}
	for _, field in ipairs({ "correctCoords", "correctNpc", "replacement", "repro" }) do
		if visible[field] then
			last = Place(frame.labels[field], last, 8)
			last = Place(frame.inputs[field], last, 2, 6)
			if field == "correctCoords" then
				frame.positionButton:ClearAllPoints()
				frame.positionButton:SetPoint("LEFT", frame.inputs.correctCoords, "RIGHT", 8, 0)
				frame.positionButton:Show()
			end
		else
			frame.labels[field]:Hide()
			frame.inputs[field]:Hide()
			if field == "correctCoords" then frame.positionButton:Hide() end
		end
	end

	last = Place(frame.previewTitle, last, 12, -6)
	frame.preview:SetWidth(inner)
	frame.preview:SetText(table.concat(Feedback.PreviewLines(draft), "\n"))
	last = Place(frame.preview, last, 4)
	frame.characterButton:SetText("Include character: " .. (draft.includeCharacter and "Yes" or "No"))
	frame.diagnosticsButton:SetText("Include diagnostics: " .. (draft.includeDiagnostics and "Yes" or "No"))
	last = Place(frame.characterButton, last, 6)
	frame.diagnosticsButton:ClearAllPoints()
	frame.diagnosticsButton:SetPoint("LEFT", frame.characterButton, "RIGHT", 8, 0)

	last = Place(frame.prepareButton, last, 12)
	frame.discardButton:ClearAllPoints()
	frame.discardButton:SetPoint("LEFT", frame.prepareButton, "RIGHT", 8, 0)
	frame.status:SetWidth(inner)
	last = Place(frame.status, last, 6)
	if frame.output.box.fixedText then
		last = Place(frame.output, last, 4)
	else
		frame.output:Hide()
	end

	local top, bottom = frame:GetTop(), last:GetBottom()
	local height = 520
	if top and bottom then height = (top - bottom) + pad end
	frame:SetHeight(math.max(240, height))
end

local function LoadDraft(draft)
	for field, input in pairs(frame.inputs) do
		input.box:SetText(draft[field] or "")
	end
	frame.output.box.fixedText = false
	frame.status:SetText("")
end

function Center:Open(context)
	self:Create()
	local draft = Feedback.OpenDraft(context)
	LoadDraft(draft)
	frame:Show()
	self:Refresh()
	if draft.prepared then self:Prepare() end
	return draft
end

-- Report button on the guide window. Only reads the current step.
function Center:OpenForStep()
	local context = Feedback.CollectStepContext()
	if not context then
		FL:Print("no guide step is selected. Opening a general report instead.")
		return self:Open(nil)
	end
	return self:Open(context)
end

function Center:Prepare()
	local text, problem = Feedback.Prepare()
	if not text then
		frame.status:SetText(BAD .. problem .. "|r")
		frame.output.box.fixedText = false
		self:Refresh()
		return nil
	end
	frame.output.box.fixedText = text
	frame.output.box:SetText(text)
	frame.status:SetText(GOOD .. "Report ready, not sent.|r Click the box below, press Ctrl+A then Ctrl+C to copy it, and email it to "
		.. Feedback.EMAIL .. ". " .. DIM .. "Pathwise cannot send email; your draft stays saved until you discard it.|r")
	self:Refresh()
	return text
end

FL:On("STYLE_CHANGED", function() if Center:IsShown() then Center:Refresh() end end)

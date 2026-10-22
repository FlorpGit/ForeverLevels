-- ForeverLevels: profession dashboard. Opens from the guide window's Professions
-- button, /pathwise prof, or the options panel. Uses the guide window's style.
-- Content is built as plain lines first (Dashboard.BuildLines) so it can be tested
-- without a game client.

local _, FL = ...

local Dashboard = {}
FL.Dashboard = Dashboard

local WIDTH = 380
local MAX_LINES = 60
local MAX_BUTTONS = 8

local GOLD = "|cffffd100"
local GOOD = "|cff55dd55"
local BAD = "|cffff6655"
local DIM = "|cff888888"
local WARN = "|cffffcc55"

Dashboard.BASIS_TEXT = {
	client = "chance from your client",
	thresholds = "chance from verified skill levels",
	["thresholds-unverified"] = "estimate from unverified skill levels",
	["client-stale"] = "rough: client reading from a lower skill",
	unknown = "skill-up chance unknown until you open the profession window",
}

Dashboard.ORIGIN_TEXT = {
	client = "reagents read from your client",
	source = "reagents checked on Wowhead (Forever)",
	unverified = "reagents not verified",
}

local frame

------------------------------------------------------------------------
-- Content
------------------------------------------------------------------------

local function Add(lines, text, kind)
	lines[#lines + 1] = { text = text, kind = kind or "line" }
end

local function MaterialLine(row, indent)
	local color = row.missing > 0 and BAD or GOOD
	local text = string.format("%s%s %d/%d", indent, row.name, row.owned, row.required)
	if row.missing > 0 then text = text .. string.format(" (missing %d)", row.missing) end
	return color .. text .. "|r"
end

local function Gathering(lines, rows, seen)
	for _, row in ipairs(rows) do
		if row.madeFrom then
			Gathering(lines, row.madeFrom.rows, seen)
		elseif row.missing > 0 and not seen[row.itemID] then
			seen[row.itemID] = true
			local info = FL:GetItemInfoData(row.itemID)
			local how = info and info.acquire or "Source not recorded yet."
			local unverified = info and info.verified and info.verified.acquire == false
			Add(lines, string.format("Collect %d %s: %s%s", row.missing, row.name, how,
				unverified and (DIM .. " (unverified)|r") or ""))
		end
	end
end

function Dashboard.BuildLines()
	local lines = {}
	local settings = FL.db.profile.professions
	local professions = FL.Professions:List(false)

	Add(lines, "Overview", "heading")
	if not settings.enabled then
		Add(lines, DIM .. "Profession tracking is off.|r")
	elseif #professions == 0 then
		Add(lines, DIM .. "No professions found. Learn one from a trainer to get started.|r")
	end
	local milestones = {}
	if settings.enabled then
		for _, info in ipairs(professions) do
			local tracked = FL.Professions.IsTracked(info.key)
			local text = string.format("%s%s|r  %d / %d", GOLD, info.name, info.rank, info.maxRank)
			if not tracked then text = text .. DIM .. "  (hidden)|r" end
			if not info.hasData then text = text .. DIM .. "  (no Pathwise data yet)|r" end
			Add(lines, text)
			if tracked and info.hasData then
				local m = FL.Planner.NextMilestone(info.key)
				if m then
					milestones[#milestones + 1] = { info = info, milestone = m }
					local when = m.ready and (GOOD .. "ready to train now|r")
						or string.format("at skill %d and level %d", m.rank.trainAt, m.rank.level or 0)
					Add(lines, string.format("  Next: %s %s%s", m.rank.name, when,
						m.verified and "" or (DIM .. " (unverified)|r")))
				end
			end
		end
	end

	Add(lines, "Crafting plan", "heading")
	local gathering, seen, anyPlan = {}, {}, false
	if settings.enabled then
		for _, info in ipairs(FL.Professions:List(true)) do
			if info.hasData then
				local plan = FL.Planner.Plan(info.key, 2)
				for i, step in ipairs(plan) do
					anyPlan = true
					local target = step.toSkill > step.skill and (" to " .. step.toSkill) or ""
					Add(lines, string.format("%s%s|r %s x%d%s", GOLD, i == 1 and info.name or "  then", step.recipe.name, step.crafts, target))
					Add(lines, string.format("  %s%s, %s|r", DIM, Dashboard.BASIS_TEXT[step.basis] or step.basis,
						Dashboard.ORIGIN_TEXT[step.materials[1] and step.materials[1].origin or "unverified"]))
					if step.recipe.kind == "enchant" then Add(lines, "  " .. WARN .. "Needs an item to put the enchant on.|r") end
					for _, row in ipairs(step.materials) do
						Add(lines, MaterialLine(row, "  "))
						if row.madeFrom then
							Add(lines, DIM .. "    make with " .. row.madeFrom.recipe.name .. ":|r")
							for _, sub in ipairs(row.madeFrom.rows) do Add(lines, MaterialLine(sub, "    ")) end
						end
					end
					Gathering(gathering, step.materials, seen)
				end
			end
		end
	end
	if not anyPlan then Add(lines, DIM .. "Nothing to plan yet.|r") end

	Add(lines, "Upcoming", "heading")
	local before = #lines
	for _, entry in ipairs(milestones) do
		local m, info = entry.milestone, entry.info
		if m.trainer then
			Add(lines, string.format("Trainer: %s %s from %s (%s)%s", m.rank.name, info.name, m.trainer.name,
				m.trainer.zone or "?", m.trainer.x and "" or (DIM .. ", position not verified|r")))
		end
		for _, recipe in ipairs(FL.Planner.LearnableRecipes(info.key)) do
			Add(lines, string.format("Learn: %s (%s)", recipe.name, info.name))
		end
	end
	local active, suggestion = FL.Detours:GetActive(), FL.Detours.suggestion
	if active then Add(lines, "Detour in progress: " .. active.title) end
	if suggestion then Add(lines, "Suggested: " .. suggestion.title) end
	for _, line in ipairs(gathering) do lines[#lines + 1] = line end
	if #lines == before then Add(lines, DIM .. "Nothing coming up.|r") end

	return lines
end

------------------------------------------------------------------------
-- Settings buttons
------------------------------------------------------------------------

local function SettingButtons()
	local settings = FL.db.profile.professions
	local list = {
		{ label = "Tracking", on = settings.enabled, click = function() FL.Options.SetProfession("enabled", not settings.enabled) end },
		{ label = "Detours", on = settings.detours, click = function() FL.Options.SetProfession("detours", not settings.detours) end },
		{ label = "Reminders", on = settings.reminders, click = function() FL.Options.SetProfession("reminders", not settings.reminders) end },
	}
	for _, info in ipairs(FL.Professions:List(false)) do
		local key = info.key
		list[#list + 1] = {
			label = info.name, on = settings.tracked[key] ~= false,
			click = function() FL.Options.SetTracked(key, settings.tracked[key] == false) end,
		}
	end
	return list
end
Dashboard.SettingButtons = SettingButtons

------------------------------------------------------------------------
-- Frame
------------------------------------------------------------------------

local function SavePosition()
	local point, _, relPoint, x, y = frame:GetPoint(1)
	local saved = FL.db.profile.dashboard
	saved.point, saved.relPoint, saved.x, saved.y = point, relPoint, x, y
end

function Dashboard:Create()
	if frame then return frame end
	local saved = FL.db.profile.dashboard
	frame = CreateFrame("Frame", "ForeverLevelsProfessionDashboard", UIParent, "BackdropTemplate")
	frame:SetSize(WIDTH, 300)
	frame:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
	frame:SetScale(saved.scale or 1)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(f)
		if not FL.db.profile.dashboard.locked then f:StartMoving() end
	end)
	frame:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
		SavePosition()
	end)

	frame.header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	frame.close:SetSize(22, 22)
	frame.close:SetScript("OnClick", function() Dashboard:SetShown(false) end)
	frame.lines = {}
	for i = 1, MAX_LINES do
		local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetJustifyH("LEFT")
		text:SetWordWrap(true)
		frame.lines[i] = text
	end
	frame.buttons = {}
	for i = 1, MAX_BUTTONS do
		local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		button:SetSize(110, 22)
		frame.buttons[i] = button
	end
	frame:SetShown(saved.shown)
	self:Update()
	return frame
end

function Dashboard:SetShown(shown)
	FL.db.profile.dashboard.shown = shown and true or false
	if not frame then self:Create() end
	frame:SetShown(shown)
	if shown then self:Update() end
end

function Dashboard:Toggle()
	self:SetShown(not (frame and frame:IsShown()))
end

function Dashboard:IsShown()
	return frame ~= nil and frame:IsShown()
end

function Dashboard:Update()
	if not frame or not frame:IsShown() then return end
	local pad = FL.GuideFrame.ApplyBackdrop(frame)
	local inner = WIDTH - pad * 2

	frame.header:ClearAllPoints()
	frame.header:SetPoint("TOPLEFT", pad, -pad)
	frame.header:SetText(FL.BRAND .. " Professions")
	frame.close:ClearAllPoints()
	frame.close:SetPoint("TOPRIGHT", -(pad - 12), -(pad - 12))

	local lines = Dashboard.BuildLines()
	local last = frame.header
	for i, text in ipairs(frame.lines) do
		local line = lines[i]
		if line then
			text:SetFontObject(line.kind == "heading" and "GameFontNormal" or "GameFontHighlightSmall")
			text:SetText(line.text)
			text:SetWidth(inner)
			text:ClearAllPoints()
			text:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, line.kind == "heading" and -10 or -2)
			text:Show()
			last = text
		else
			text:Hide()
		end
	end

	local settings = SettingButtons()
	local columns, buttonWidth = 3, math.floor((inner - 8) / 3)
	for i, button in ipairs(frame.buttons) do
		local entry = settings[i]
		if entry then
			button:SetWidth(buttonWidth)
			button:SetText(entry.label .. ": " .. (entry.on and "On" or "Off"))
			button:SetScript("OnClick", function()
				entry.click()
				Dashboard:Update()
			end)
			button:ClearAllPoints()
			local row, col = math.floor((i - 1) / columns), (i - 1) % columns
			button:SetPoint("TOPLEFT", last, "BOTTOMLEFT", col * (buttonWidth + 4), -12 - row * 26)
			button:Show()
		else
			button:Hide()
		end
	end

	local rows = math.ceil(math.min(#settings, MAX_BUTTONS) / columns)
	local top, bottom = frame:GetTop(), last:GetBottom()
	local height = 360
	if top and bottom then height = (top - bottom) + 12 + rows * 26 + pad end
	frame:SetHeight(math.max(160, height))
end

local function Refresh()
	Dashboard:Update()
end

FL:On("PROFESSIONS_CHANGED", Refresh)
FL:On("INVENTORY_CHANGED", Refresh)
FL:On("DETOUR_CHANGED", Refresh)
FL:On("STYLE_CHANGED", Refresh)

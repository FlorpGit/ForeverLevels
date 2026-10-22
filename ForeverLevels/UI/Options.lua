-- ForeverLevels: options panel in the game's Settings window (AddOns tab).
-- Uses Settings.RegisterCanvasLayoutCategory, present in Forever's Blizzard_Settings_Shared.
-- Every option is also reachable through /pathwise, so the panel is a convenience.

local _, FL = ...

local Options = {}
FL.Options = Options

Options.TOGGLES = {
	{ key = "autoAccept", label = "Auto-accept route quests" },
	{ key = "autoTurnIn", label = "Auto-turn-in route quests" },
	{ key = "autoGossip", label = "Auto-pick route quests in NPC dialogs" },
	{ key = "pauseWithShift", label = "Hold Shift to pause automation" },
	{ key = "arrow", label = "Show direction arrow" },
	{ key = "nativeWaypoint", label = "Place Blizzard map pin + in-world marker" },
	{ key = "suggestDungeons", label = "Suggest dungeons for your level" },
	{ key = "sync", label = "Share progress with party (addon messages)" },
	{ key = "autoSelectRoute", label = "Pick a route automatically" },
	{ key = "record", label = "Recorder: log quest positions (route authors)" },
	{ key = "debug", label = "Debug messages" },
}

function Options.Apply(key)
	if key == "arrow" or key == "nativeWaypoint" then
		FL.Waypoint:Update()
		FL.Arrow:Update()
	elseif key == "sync" then
		FL.Sync:Queue()
	end
	FL.GuideFrame:Update()
end

function Options.Set(key, value)
	FL.db.profile[key] = value
	Options.Apply(key)
	if Options.panel then Options.Refresh() end
end

-- Profession settings live under profile.professions.
Options.PROFESSION_TOGGLES = {
	{ key = "enabled", label = "Profession tracking" },
	{ key = "detours", label = "Profession detours next to the route" },
	{ key = "reminders", label = "Material reminders in chat" },
	{ key = "countBank", label = "Count bank items in material plans" },
}

function Options.SetProfession(key, value)
	local settings = FL.db.profile.professions
	if key == "detours" then
		FL.Detours:SetEnabled(value)
	else
		settings[key] = value
		if key == "enabled" and not value then FL.Detours:Evaluate() end
		FL.Professions:Refresh()
	end
	FL.Dashboard:Update()
	if Options.panel then Options.Refresh() end
end

function Options.SetTracked(professionKey, tracked)
	FL.db.profile.professions.tracked[professionKey] = tracked and true or false
	FL.Detours:Evaluate()
	FL.Dashboard:Update()
end

local function OnOff(on)
	return on and "|cff55dd55ON|r" or "|cffff5555OFF|r"
end

local function ButtonText(toggle)
	if toggle.profession then
		return toggle.label .. ": " .. OnOff(FL.db.profile.professions[toggle.key])
	end
	return toggle.label .. ": " .. OnOff(FL.db.profile[toggle.key])
end

function Options.Refresh()
	for _, button in ipairs(Options.panel.buttons) do
		button:SetText(ButtonText(button.toggle))
	end
	local style = FL.GuideFrame.STYLES[FL.db.profile.frame.style]
	Options.panel.styleButton:SetText("Window style: " .. (style and style.label or "Classic"))
end

function Options:Create()
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
		FL:Debug("Settings API unavailable; use /pathwise commands")
		return
	end

	local panel = CreateFrame("Frame")
	panel.name = FL.BRAND
	panel.buttons = {}

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(FL.BRAND .. " " .. FL.version)

	-- About
	local about = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	about:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	about:SetJustifyH("LEFT")
	about:SetText(FL.TAGLINE .. "\nBy " .. FL.CREATORS .. ". Code MIT, bundled guides CC BY-SA 4.0.")
	local compat = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	compat:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 0, -4)
	compat:SetJustifyH("LEFT")
	compat:SetText("Formerly ForeverLevels. /fl and ForeverLevels:RegisterRoute() still work.")
	panel.about = about

	local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", compat, "BOTTOMLEFT", 0, -10)
	hint:SetText("Click to toggle. All options are also available with /pathwise help.")

	local previous = hint
	for _, toggle in ipairs(self.TOGGLES) do
		local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		button:SetSize(380, 24)
		button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, previous == hint and -14 or -4)
		button.toggle = toggle
		button:SetScript("OnClick", function()
			Options.Set(toggle.key, not FL.db.profile[toggle.key])
		end)
		panel.buttons[#panel.buttons + 1] = button
		previous = button
	end

	local styleButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	styleButton:SetSize(380, 24)
	styleButton:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -14)
	styleButton:SetScript("OnClick", function()
		FL.GuideFrame:CycleStyle()
		Options.Refresh()
	end)
	panel.styleButton = styleButton
	previous = styleButton

	local professionTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	professionTitle:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -16)
	professionTitle:SetText("Professions")
	previous = professionTitle
	for _, entry in ipairs(self.PROFESSION_TOGGLES) do
		local toggle = { key = entry.key, label = entry.label, profession = true }
		local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		button:SetSize(380, 24)
		button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, previous == professionTitle and -8 or -4)
		button.toggle = toggle
		button:SetScript("OnClick", function()
			Options.SetProfession(toggle.key, not FL.db.profile.professions[toggle.key])
		end)
		panel.buttons[#panel.buttons + 1] = button
		previous = button
	end
	local dashboardButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	dashboardButton:SetSize(380, 24)
	dashboardButton:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -10)
	dashboardButton:SetText("Open profession dashboard")
	dashboardButton:SetScript("OnClick", function() FL.Dashboard:SetShown(true) end)

	panel:SetScript("OnShow", Options.Refresh)

	self.panel = panel
	self.category = Settings.RegisterCanvasLayoutCategory(panel, FL.BRAND)
	Settings.RegisterAddOnCategory(self.category)
end

function Options:Open()
	if self.category and Settings.OpenToCategory then
		Settings.OpenToCategory(self.category:GetID())
	else
		FL:Print("options panel unavailable; use /pathwise help")
	end
end

-- ForeverLevels: options panel in the game's Settings window (AddOns tab).
-- Uses Settings.RegisterCanvasLayoutCategory, present in Forever's Blizzard_Settings_Shared.
-- Every option is also reachable through /fl, so the panel is a convenience.

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

local function ButtonText(toggle)
	local on = FL.db.profile[toggle.key]
	return toggle.label .. ": " .. (on and "|cff55dd55ON|r" or "|cffff5555OFF|r")
end

function Options.Refresh()
	for _, button in ipairs(Options.panel.buttons) do
		button:SetText(ButtonText(button.toggle))
	end
end

function Options:Create()
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
		FL:Debug("Settings API unavailable; use /fl commands")
		return
	end

	local panel = CreateFrame("Frame")
	panel.name = "ForeverLevels"
	panel.buttons = {}

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("ForeverLevels " .. FL.version)

	local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	hint:SetText("Click to toggle. All options are also available with /fl help.")

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
	panel:SetScript("OnShow", Options.Refresh)

	self.panel = panel
	self.category = Settings.RegisterCanvasLayoutCategory(panel, "ForeverLevels")
	Settings.RegisterAddOnCategory(self.category)
end

function Options:Open()
	if self.category and Settings.OpenToCategory then
		Settings.OpenToCategory(self.category:GetID())
	else
		FL:Print("options panel unavailable; use /fl help")
	end
end

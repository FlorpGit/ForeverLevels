local T = ...

local function Text(lines)
	local parts = {}
	for _, line in ipairs(lines) do parts[#parts + 1] = (line.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
	return table.concat(parts, "\n")
end

local function DashboardFrame()
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, "lines") and rawget(frame, "buttons") and rawget(frame, "close") then return frame end
	end
end

local function Guide()
	for _, frame in ipairs(T.Stub.frames) do
		if rawget(frame, "nextButton") then return frame end
	end
end

T.Test("Dashboard: overview, crafting plan, upcoming activities and labels", function()
	local FL = T.BootCrafter()
	T.Stub.items[2589] = 3      -- some linen, no bolts, no thread
	local text = Text(FL.Dashboard.BuildLines())
	T.True(text:find("Tailoring  30 / 75", 1, true), "tailoring skill and cap")
	T.True(text:find("Enchanting  12 / 75", 1, true), "enchanting skill and cap")
	T.True(text:find("Next: Journeyman at skill 50 and level 10 (unverified)", 1, true), "trainer milestone, labeled")
	T.True(text:find("Crafting plan", 1, true), "plan section")
	T.True(text:find("estimate from unverified skill levels", 1, true), "tailoring chance basis shown")
	T.True(text:find("reagents checked on Wowhead (Forever)", 1, true), "reagent source shown")
	T.True(text:find("skill-up chance unknown until you open the profession window", 1, true), "enchanting uncertainty shown")
	T.True(text:find("(missing", 1, true), "missing materials shown")
	T.True(text:find("Collect ", 1, true), "gathering suggestion")
	T.True(text:find("Trainer: Journeyman Tailoring from Bowen Brisboise (Tirisfal Glades), position not verified", 1, true), "trainer visit")
end)

T.Test("Dashboard: enchant recipes say they need an item", function()
	local FL = T.BootCrafter()
	T.Stub.openProfession = { professionID = 333, professionName = "Enchanting" }
	T.Stub.recipeInfo[7457] = { learned = true, relativeDifficulty = 0 }
	for _, id in ipairs({ 1245320, 7421, 7418, 7420, 7443, 7426 }) do T.Stub.recipeInfo[id] = { learned = false } end
	T.Stub.FireEvent("TRADE_SKILL_SHOW"); T.Stub.Advance(0.5)
	local text = Text(FL.Dashboard.BuildLines())
	T.True(text:find("Enchant Bracer - Minor Stamina", 1, true), "learned enchant planned")
	T.True(text:find("Needs an item to put the enchant on.", 1, true), "enchant note")
	T.True(text:find("chance from your client", 1, true), "client basis")
end)

T.Test("Dashboard: opens from the guide button and /pathwise prof, and remembers it", function()
	local FL = T.BootCrafter()
	T.True(not FL.Dashboard:IsShown(), "closed by default")
	Guide().professionsButton.scripts.OnClick()
	T.True(FL.Dashboard:IsShown(), "opened from the guide window")
	T.Equal(FL.db.profile.dashboard.shown, true, "saved")
	FL.HandleSlash("prof")
	T.True(not FL.Dashboard:IsShown(), "toggled closed")
	_G.SlashCmdList.FOREVERLEVELS("prof")   -- the same handler serves /fl
	T.True(FL.Dashboard:IsShown(), "opened via the shared handler")
end)

T.Test("Dashboard: settings buttons toggle tracking, detours, reminders and professions", function()
	local FL = T.BootCrafter()
	FL.Dashboard:SetShown(true)
	local frame = DashboardFrame()
	local function Button(prefix)
		for _, button in ipairs(frame.buttons) do
			if button.shown and button.text and button.text:find("^" .. prefix) then return button end
		end
	end
	T.Equal(Button("Detours").text, "Detours: On", "detours on")
	Button("Detours").scripts.OnClick()
	T.Equal(FL.db.profile.professions.detours, false, "detours off")
	T.Equal(Button("Detours").text, "Detours: Off", "button updated")
	Button("Reminders").scripts.OnClick()
	T.Equal(FL.db.profile.professions.reminders, false, "reminders off")
	Button("Enchanting").scripts.OnClick()
	T.Equal(FL.db.profile.professions.tracked.enchanting, false, "enchanting hidden")
	T.True(Text(FL.Dashboard.BuildLines()):find("Enchanting  12 / 75  (hidden)", 1, true), "shown as hidden")
	Button("Tracking").scripts.OnClick()
	T.True(Text(FL.Dashboard.BuildLines()):find("Profession tracking is off.", 1, true), "tracking off")
end)

T.Test("Dashboard: follows the window style", function()
	local FL = T.BootCrafter()
	FL.Dashboard:SetShown(true)
	local frame = DashboardFrame()
	T.Equal(frame.backdrop.edgeFile, [[Interface\DialogFrame\UI-DialogBox-Border]], "classic")
	FL.HandleSlash("style tooltip")
	T.Equal(frame.backdrop.edgeFile, [[Interface\Tooltips\UI-Tooltip-Border]], "tooltip")
	FL.HandleSlash("style minimal")
	T.Equal(frame.backdrop.edgeFile, [[Interface\Buttons\WHITE8X8]], "minimal")
end)

T.Test("Commands: profession commands work through /pathwise and /fl", function()
	local FL = T.BootCrafter()
	FL.HandleSlash("track tailoring off")
	T.Equal(FL.db.profile.professions.tracked.tailoring, false, "tailoring hidden")
	_G.SlashCmdList.FOREVERLEVELS("track tailoring on")
	T.Equal(FL.db.profile.professions.tracked.tailoring, true, "tailoring shown")
	FL.HandleSlash("reminders off")
	T.Equal(FL.db.profile.professions.reminders, false, "reminders off")
	FL.HandleSlash("tracking off")
	T.Equal(FL.db.profile.professions.enabled, false, "tracking off")
	FL.HandleSlash("tracking on")
	for _, input in ipairs({ "track", "track nope", "detour", "detour go", "detour later", "detour skip", "detour done", "detour cancel", "dashboard", "professions" }) do
		FL.HandleSlash(input)
	end
	T.True(T.ChatContains("usage: /pathwise track"), "usage shown")
end)

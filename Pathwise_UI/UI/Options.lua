-- Pathwise in the game's own Settings window (Esc > Options > AddOns >
-- Pathwise): the name, the version, the look, and buttons into Pathwise's
-- Settings panel, the guide and feedback. Every setting lives in Pathwise's
-- own panel; this page is the way in for those who look here first.
--
-- APIs (Blizzard_Settings_Shared, SharedUIPanelTemplates.xml):
--   Settings.RegisterCanvasLayoutCategory, Settings.RegisterAddOnCategory,
--   Settings.OpenToCategory, UIPanelButtonTemplate.

local ADDON, ns = ...
local T = ns.Theme
local O = {}
ns.Options = O

local function button(parent, label, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(200, 24)
	local text = b.GetFontString and b:GetFontString() -- the template's ButtonText
	if not text then
		text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("CENTER")
	end
	text:SetText(label)
	b.pwText = text
	b:SetScript("OnClick", onClick)
	return b
end

function O.Build()
	if O.category or not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local panel = CreateFrame("Frame")
	panel.name = "Pathwise"
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Pathwise " .. tostring(ns.VERSION))
	local tag = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	tag:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	tag:SetText("Every quest. Every craft. Every level.  Created by leight_nn & florp.")
	local about = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	about:SetPoint("TOPLEFT", tag, "BOTTOMLEFT", 0, -10)
	about:SetWidth(520)
	about:SetJustifyH("LEFT")
	about:SetText("Pathwise's settings are in its own Settings panel: the gear on the guide window, a right-click on its minimap button, or /pw settings.")

	local open = button(panel, "Open Pathwise's settings", function() ns.Fire("SHOW_SETTINGS") end)
	open:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 0, -16)
	local guide = button(panel, "Show or hide the guide", function() ns.Fire("TOGGLE_GUIDE") end)
	guide:SetPoint("LEFT", open, "RIGHT", 8, 0)
	local feedback = button(panel, "Report a bug or an idea", function() ns.Fire("SHOW_FEEDBACK") end)
	feedback:SetPoint("TOPLEFT", open, "BOTTOMLEFT", 0, -8)

	local look = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	look:SetPoint("TOPLEFT", feedback, "BOTTOMLEFT", 0, -20)
	look:SetText("Look")
	local anchor, row = look, {}
	for i, key in ipairs(T.STYLE_ORDER) do
		local s = T.STYLES[key]
		local b = button(panel, s.label, function() T.Choose(key) end)
		b:SetWidth(120)
		if i == 1 then b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8) else b:SetPoint("LEFT", row[i - 1], "RIGHT", 8, 0) end
		row[i] = b
	end
	local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	note:SetPoint("TOPLEFT", row[1], "BOTTOMLEFT", 0, -8)
	note:SetText("A new look shows after a reload (/reload).")

	O.panel = panel
	O.category = Settings.RegisterCanvasLayoutCategory(panel, "Pathwise")
	Settings.RegisterAddOnCategory(O.category)
end

-- Opens this page in the game's Settings window.
function O.Open()
	if O.category and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(O.category:GetID())
		return true
	end
	return false
end

ns.On("READY", function()
	local ok, err = pcall(O.Build)
	if not ok then ns.Error("game settings page", err) end
end)

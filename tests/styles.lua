-- Tests for the looks (Theme/Signature.lua: Modern and Classic), the
-- selector in Settings, /pw style and the page in the game's Settings
-- window (UI/Options.lua). Loaded by tests/run.lua.
local h = ...
local test, eq, ok, fresh, lastPrint = h.test, h.eq, h.ok, h.fresh, h.lastPrint

local DIALOG = "Interface\\DialogFrame\\UI-DialogBox-Border"
local TOOLTIP = "Interface\\Tooltips\\UI-Tooltip-Border"
local GOLD = { 1, 0.82, 0 }

-- Logs in with the given look saved (and an Undead Mage in Deathknell).
local function login(style, setup)
	local stub, ns = fresh()
	PathwiseSettings = { schema = 1, ui = { style = style } }
	stub.player.level = 2
	stub.moveTo(1420, 30.2, 71.6)
	if setup then setup(stub) end
	stub.login()
	return stub, ns
end

local function near(c, want, msg)
	for i = 1, 3 do
		if math.abs((c[i] or -1) - want[i]) > 0.01 then error(("%s: expected %.2f %.2f %.2f, got %s %s %s"):format(msg or "colour",
			want[1], want[2], want[3], tostring(c[1]), tostring(c[2]), tostring(c[3])), 2) end
	end
end

-- Shown frames under `root` (or anywhere) made from `template`.
local function made(stub, template, root)
	local out = {}
	for _, f in ipairs(stub.frames) do
		if rawget(f, "template") == template and f.shown then
			local p, under = f, root == nil
			while p and not under do if p == root then under = true end p = rawget(p, "parent") end
			if under then out[#out + 1] = f end
		end
	end
	return out
end

local function fontOf(fs) return rawget(fs, "fontFile") end

test("looks: Modern by default, the Signature as it was", function()
	local stub, ns = fresh()
	stub.login()
	local T = ns.Theme
	eq(T.STYLE, "modern")
	eq(T.INSET, 0)
	eq(rawget(_G.PathwiseGuide, "backdrop"), nil, "flat ground, 1 px lines")
	eq(#made(stub, "UIPanelButtonTemplate"), 0, "Signature buttons")
	near(T.Color("accent"), T.Hex("#66D7FF"), "ice blue")
end)

test("looks: Classic draws the guide window with the game's dialog border, buttons and gold headings", function()
	local stub, ns = login("classic")
	local T, g = ns.Theme, _G.PathwiseGuide
	eq(T.STYLE, "classic")
	ok(T.IsClassic())
	eq(g.backdrop and g.backdrop.edgeFile, DIALOG, "the dialog border")
	ok(#made(stub, "UIPanelButtonTemplate", g) >= 3, "Back, Skip and Next are the game's buttons")
	ok(#made(stub, "UIPanelCloseButton", g) >= 1, "the game's close button")
	near(T.Color("accent"), GOLD, "the game's gold")
	local name
	for _, f in ipairs(stub.frames) do if f.kind == "FontString" and rawget(f, "text") == "Pathwise" then name = f end end
	near(name.textColor, GOLD, "the window's name in gold")
	ok(g.h > 0, "laid out")
	local view = ns.Guide.View()
	ok(view and view.title == "Undertaker Mordo", "the same guide")
end)

test("looks: Classic panels, the Feedback Center and a profession page work and look the part", function()
	local stub, ns = login("classic", function(s) s.skills[197] = { 1, 75 } s.items[2589] = 46 end)
	ns.Fire("SHOW_SETTINGS")
	local p = _G.PathwisePanel
	eq(p.backdrop and p.backdrop.edgeFile, DIALOG, "the panel too")
	ok(#made(stub, "InputBoxTemplate", p) >= 1, "the game's input box beside each slider")
	ns.Fire("REPORT_STEP")
	local F = ns.Feedback
	F.SetField("category", "other")
	F.SetField("description", "Testing in Classic.")
	ok(stub.clickLabel("Prepare report"), "the game's button, same label")
	local card
	for _, f in ipairs(stub.frames) do
		local t = rawget(f, "text")
		if type(t) == "string" and t:find("^PATHWISE %- ") and f.shown and rawget(f, "box") then card = f end
	end
	ok(card, "the report to copy")
	eq(card.backdrop and card.backdrop.edgeFile, TOOLTIP, "in a tooltip-bordered box")
	SlashCmdList.PATHWISE("prof")
	ok(stub.clickLabelText("Tailoring   1 / 75"), "the profession list")
end)

test("looks: Classic reaches Pathwise Bags and Pathwise Gear", function()
	local stub, ns = fresh()
	PathwiseSettings = { schema = 1, ui = { style = "classic" } }
	stub.player.level = 20
	local gear = stub.loadAddon(".", "Pathwise_Gear")
	local b = stub.loadAddon(".", "Pathwise_Bags")
	stub.moveTo(1420, 60, 52)
	stub.login()
	b.Window.Show()
	local w = _G.PathwiseBagsFrame
	ok(w and w.shown, "the bag window")
	eq(w.backdrop and w.backdrop.edgeFile, DIALOG)
	ok(#made(stub, "UIPanelCloseButton", w) == 1, "the game's close button")
	ns.Fire("SHOW_SETTINGS")
	ok(stub.clickLabelText("Pathwise Gear"), "Gear's panel from the suite list")
	eq(_G.PathwisePanel.backdrop.edgeFile, DIALOG)
end)

test("looks: the arrow and the minimap button take the look's colours", function()
	local stub, ns = login("classic")
	SlashCmdList.PATHWISE("way 50 40")
	stub.advance(0.2)
	local dart = stub.find("arrow$")
	near(dart.vertex, GOLD, "a gold arrow")
	local b = ns.MinimapButton.Buttons[""] -- Pathwise's own
	ok(b, "the minimap button")
	near(b.ring.vertex, ns.Theme.Color("border"), "its ring in the classic border colour")
end)

test("looks: choosing one in Settings saves it, and it shows after a reload", function()
	local stub, ns = fresh()
	stub.login()
	ns.Fire("SHOW_SETTINGS")
	ok(stub.clickLabel("Classic"), "Settings > Look")
	eq(ns.Get("ui.style"), "classic", "saved")
	eq(ns.Theme.STYLE, "modern", "this session keeps its look")
	ok(lastPrint(stub):find("after a reload"), lastPrint(stub))
	ok(stub.clickLabelText("Reload now"))
	eq(stub.reloaded, 1)
	SlashCmdList.PATHWISE("style modern")
	eq(ns.Get("ui.style"), "modern")
	SlashCmdList.PATHWISE("style nonsense")
	ok(lastPrint(stub):find("/pw style modern | classic", 1, true), lastPrint(stub))
	local saved = PathwiseSettings
	saved.ui = saved.ui or {}
	saved.ui.style = "classic"
	local stub2, ns2 = fresh()
	PathwiseSettings = saved
	stub2.login()
	eq(ns2.Theme.STYLE, "classic", "after the reload")
end)

test("looks: the accent is the look's own unless one is chosen", function()
	local _, ns = login("classic")
	near(ns.Theme.Color("accent"), GOLD)
	ns.Set("ui.accentMode", "custom")
	ns.Set("ui.accentColor", "#40C0A0")
	near(ns.Theme.Color("accent"), ns.Theme.Hex("#40C0A0"), "a chosen colour wins in either look")
end)

-- WCAG contrast, as the Modern palette's test in tests/run.lua.
local function lum(c)
	local function ch(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
	return 0.2126 * ch(c[1]) + 0.7152 * ch(c[2]) + 0.0722 * ch(c[3])
end
local function contrast(a, b)
	local la, lb = lum(a), lum(b)
	if la < lb then la, lb = lb, la end
	return (la + 0.05) / (lb + 0.05)
end

test("looks: Classic text is legible on every ground (7:1 primary, 4.5:1 the rest)", function()
	local _, ns = fresh()
	local C = ns.Theme.STYLES.classic.colors
	for _, ground in ipairs({ "bg", "bg2", "hover" }) do
		ok(contrast(C.text, C[ground]) >= 7, "text on " .. ground)
		for _, role in ipairs({ "text2", "accent", "success", "warning" }) do
			ok(contrast(C[role], C[ground]) >= 4.5, role .. " on " .. ground .. ": " .. contrast(C[role], C[ground]))
		end
	end
	ok(contrast(C.muted, C.bg) >= 4.5, "muted on bg")
	ok(contrast(C.muted, C.bg2) >= 4.5, "muted on bg2: " .. contrast(C.muted, C.bg2))
end)

test("looks: a page in the game's own Settings window leads into Pathwise", function()
	local stub, ns = fresh()
	local registered
	Settings = {
		RegisterCanvasLayoutCategory = function(panel, name) registered = { panel = panel, name = name, GetID = function() return 7 end } return registered end,
		RegisterAddOnCategory = function(c) c.addon = true end,
		OpenToCategory = function(id) stub.openedCategory = id end,
	}
	stub.login()
	ok(registered and registered.addon, "listed under AddOns")
	eq(registered.name, "Pathwise")
	ok(ns.Options.Open() and stub.openedCategory == 7, "opens to it")
	ok(stub.clickLabel("Open Pathwise's settings"))
	ok(_G.PathwisePanel.shown, "Pathwise's own Settings panel")
	ok(stub.clickLabel("Classic"))
	eq(ns.Get("ui.style"), "classic")
	Settings = nil
end)

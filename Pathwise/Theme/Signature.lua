-- Pathwise Signature: the theme every Pathwise window is drawn with.
-- Tokens (colours, type, spacing) and small builders (panel, text, button,
-- icon button, progress line) so every module looks and spaces the same.
-- Modules differ only by their accent (Theme.MODULES).
--
-- Construction notes for the WoW client:
--  * Solid fills and 1 px lines are textures with SetColorTexture; no
--    backdrop templates, no art files, nothing animated.
--  * Corners are square: the client has no rounded clipping, and 9-slice art
--    for a 6 px radius blurs at 70% UI scale. Documented limitation.
--  * Text is Inter (SIL OFL 1.1, Media/Fonts), sizes in UI units, so the
--    game's UI scale scales it.

local ADDON, ns = ...
local T = {}
ns.Theme = T
T.NAME = "Pathwise Signature"

local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
T.MEDIA = MEDIA

local function hex(h, a)
	h = h:gsub("#", "")
	return {
		tonumber(h:sub(1, 2), 16) / 255,
		tonumber(h:sub(3, 4), 16) / 255,
		tonumber(h:sub(5, 6), 16) / 255,
		a or 1,
	}
end
T.Hex = hex

T.COLORS = {
	bg = hex("#10161E"), -- window ground
	bg2 = hex("#17212C"), -- raised surface, buttons, cards
	hover = hex("#223241"),
	border = hex("#293B4B"), -- 1 px window border
	divider = hex("#1F2D3A"),
	text = hex("#F0F5FA"),
	text2 = hex("#9AAFC0"),
	muted = hex("#7A90A2"), -- 4.5:1 or more on every ground (tests)
	accent = hex("#66D7FF"),
	accentHover = hex("#90E4FF"),
	success = hex("#59D9B2"),
	warning = hex("#E4B96D"),
	error = hex("#E66B78"),
	silver = hex("#C9D6E2"),
}

-- One accent per module; the components are shared.
T.MODULES = {
	guide = hex("#66D7FF"),
	gear = hex("#E8C26A"),
	loot = hex("#B69CFF"),
	bags = hex("#7FD98F"),
	explorer = hex("#4FD1C5"),
	auction = hex("#E0956A"),
	encounters = hex("#F07A86"),
}

T.FONTS = {
	regular = MEDIA .. "Fonts\\Inter-Regular.ttf",
	medium = MEDIA .. "Fonts\\Inter-Medium.ttf",
	semibold = MEDIA .. "Fonts\\Inter-SemiBold.ttf",
}

-- The type ladder: role -> font, size, colour.
T.TYPE = {
	window = { "semibold", 13, "text" },
	quest = { "semibold", 16, "text" },
	body = { "regular", 13, "text" },
	meta = { "regular", 12, "text2" },
	small = { "regular", 11, "muted" },
	label = { "medium", 10, "text2" }, -- caps, tracked by spacing in the text
	number = { "semibold", 17, "text" },
	button = { "medium", 12, "text2" },
}

T.SPACE = { xs = 4, s = 8, m = 12, l = 16, xl = 24 }
T.HEADER_H = 36
T.PROGRESS_H = 2

ns.Defaults("ui", {
	opacity = 0.94, -- window ground alpha
	scale = 1, -- on top of the game's UI scale
})

function T.Color(name)
	return T.COLORS[name] or T.MODULES[name] or T.COLORS.text
end

local function setColor(tex, name, alpha)
	local c = type(name) == "table" and name or T.Color(name)
	tex:SetColorTexture(c[1], c[2], c[3], alpha or c[4])
end
T.SetColor = setColor

---------------------------------------------------------------------------
-- Builders
---------------------------------------------------------------------------

-- A window or card ground with a 1 px border. Returns the textures so the
-- caller can recolour them (opacity setting, hover).
function T.Panel(frame, ground, border)
	local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	bg:SetAllPoints()
	setColor(bg, ground or "bg", ground == nil and ns.Get("ui.opacity") or nil)
	frame.pwGround = bg
	if border ~= false then
		local edges = {}
		local function line(p1, p2, w, h)
			local t = frame:CreateTexture(nil, "BORDER")
			t:SetPoint(p1)
			t:SetPoint(p2)
			if w then t:SetWidth(w) else t:SetHeight(h) end
			setColor(t, border or "border")
			edges[#edges + 1] = t
		end
		line("TOPLEFT", "TOPRIGHT", nil, 1)
		line("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
		line("TOPLEFT", "BOTTOMLEFT", 1, nil)
		line("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
		frame.pwEdges = edges
	end
	return bg
end

-- A horizontal 1 px divider inside a panel.
function T.Divider(parent)
	local t = parent:CreateTexture(nil, "ARTWORK")
	t:SetHeight(1)
	setColor(t, "divider")
	return t
end

-- A font string in a type role. `upper` for small caps labels.
function T.Text(parent, role, color, layer)
	local r = T.TYPE[role] or T.TYPE.body
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	T.Font(fs, role)
	local c = T.Color(color or r[3])
	fs:SetTextColor(c[1], c[2], c[3], c[4])
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	fs:SetWordWrap(true)
	return fs
end

function T.Font(fs, role)
	local r = T.TYPE[role] or T.TYPE.body
	if not fs:SetFont(T.FONTS[r[1]], r[2], "") then
		-- The font file failed to load: fall back to the game's own.
		fs:SetFont("Fonts\\FRIZQT__.TTF", r[2], "")
	end
end

function T.TextColor(fs, name)
	local c = T.Color(name)
	fs:SetTextColor(c[1], c[2], c[3], c[4])
end

-- A low-profile text button: dark surface, 1 px outline.
-- kind "default" (Back) or "accent" (Next).
function T.Button(parent, label, kind, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(28)
	local accent = kind == "accent"
	T.Panel(b, "bg2", false)
	local edges = {}
	for _, spec in ipairs({ { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
		{ "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil } }) do
		local t = b:CreateTexture(nil, "BORDER")
		t:SetPoint(spec[1])
		t:SetPoint(spec[2])
		if spec[3] then t:SetWidth(spec[3]) else t:SetHeight(spec[4]) end
		edges[#edges + 1] = t
	end
	local text = T.Text(b, "button", accent and "accent" or "text2")
	text:SetPoint("CENTER")
	text:SetText(label)
	b.pwText = text
	local function paint(hover)
		for _, t in ipairs(edges) do
			if accent then setColor(t, hover and "accentHover" or "accent", hover and 1 or 0.4)
			else setColor(t, "border") end
		end
		setColor(b.pwGround, hover and not accent and "hover" or "bg2")
		T.TextColor(text, accent and (hover and "accentHover" or "accent") or (hover and "text" or "text2"))
	end
	paint(false)
	b:SetScript("OnEnter", function() paint(true) end)
	b:SetScript("OnLeave", function() paint(false) end)
	if onClick then b:SetScript("OnClick", onClick) end
	b:SetWidth(math.max(64, (text:GetStringWidth() or 30) + 28))
	return b
end

-- A small icon-only button: a white glyph texture (Media/glyph-<name>.tga,
-- drawn by tools/media.js) tinted secondary, primary on hover. `tip` is its
-- tooltip and its name.
function T.IconButton(parent, glyph, tip, onClick, size)
	local b = CreateFrame("Button", nil, parent)
	size = size or 22
	b:SetSize(size, size)
	local hover = b:CreateTexture(nil, "BACKGROUND")
	hover:SetAllPoints()
	setColor(hover, "hover")
	hover:Hide()
	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(MEDIA .. "glyph-" .. glyph)
	icon:SetSize(16, 16)
	icon:SetPoint("CENTER")
	local text = { -- tints the glyph like a font string would be tinted
		SetTextColor = function(_, r, g, b2, a) icon:SetVertexColor(r, g, b2, a) end,
	}
	T.TextColor(text, "text2")
	b.pwIcon = icon
	function b:SetGlyph(name) icon:SetTexture(MEDIA .. "glyph-" .. name) end
	b:SetScript("OnEnter", function(self)
		hover:Show()
		T.TextColor(text, "text")
		if tip and GameTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(tip, 1, 1, 1)
			GameTooltip:Show()
		end
	end)
	b:SetScript("OnLeave", function()
		hover:Hide()
		T.TextColor(text, "text2")
		if GameTooltip then GameTooltip:Hide() end
	end)
	if onClick then b:SetScript("OnClick", onClick) end
	return b
end

-- A thin progress line: track plus fill. line:SetProgress(0..1).
function T.ProgressLine(parent, color)
	local track = parent:CreateTexture(nil, "ARTWORK")
	track:SetHeight(T.PROGRESS_H)
	setColor(track, "bg2")
	local fill = parent:CreateTexture(nil, "ARTWORK", nil, 1)
	fill:SetHeight(T.PROGRESS_H)
	fill:SetPoint("TOPLEFT", track, "TOPLEFT")
	setColor(fill, color or "accent")
	local line = { track = track, fill = fill }
	function line:SetProgress(p)
		p = math.max(0, math.min(1, p or 0))
		local w = track:GetWidth() or 0
		if p <= 0 or w <= 0 then fill:Hide() return end
		fill:Show()
		fill:SetWidth(w * p)
	end
	return line
end

-- The small compass mark used in headers (Media/icon.tga).
function T.Icon(parent, size)
	local t = parent:CreateTexture(nil, "ARTWORK")
	t:SetTexture(MEDIA .. "icon")
	t:SetSize(size or 16, size or 16)
	return t
end

-- Re-tint every window ground when the opacity setting changes.
local grounds = setmetatable({}, { __mode = "k" })
function T.TrackGround(frame)
	grounds[frame] = true
end
ns.On("SETTING_CHANGED", function(path, value)
	if path ~= "ui.opacity" then return end
	for frame in pairs(grounds) do
		if frame.pwGround then setColor(frame.pwGround, "bg", value) end
	end
end)

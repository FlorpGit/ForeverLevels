-- Pathwise Signature: the theme every Pathwise window is drawn with.
-- Tokens (colours, type, spacing) and small builders (panel, text, button,
-- icon button, progress line) so every module looks and spaces the same.
-- Modules differ only by their accent (Theme.MODULES).
--
-- Looks (Settings > Look, /pw style): every window, panel, the arrow, the
-- minimap buttons, Pathwise Gear and Pathwise Bags draw through these
-- builders, so a look changes them all.
--   "modern"   the Signature look: flat dark grounds, 1 px lines, Inter, ice blue
--   "classic"  the game's own: the dark dialog border, Friz Quadrata, gold
--              headings, the game's red buttons and close button
-- A look is applied when the settings load (LOADED), before any window is
-- built; choosing another takes effect after a reload, as the game's
-- templates are chosen when a frame is made.
--
-- Construction notes for the WoW client:
--  * Modern: solid fills and 1 px lines are textures with SetColorTexture;
--    no backdrop templates, no art files, nothing animated.
--  * Classic: only art Forever's own UI source uses: BACKDROP_DIALOG_EDGE_32
--    (Interface\DialogFrame\UI-DialogBox-Border) and the tooltip border
--    (Interface\Tooltips\UI-Tooltip-Border, as in BACKDROP_TUTORIAL_16_16)
--    through BackdropTemplateMixin (Blizzard_SharedXML/Backdrop.lua), and
--    UIPanelButtonTemplate, UIPanelCloseButton and InputBoxTemplate
--    (SharedUIPanelTemplates.xml, InputBoxTemplates.xml).
--  * Corners are square in Modern: the client has no rounded clipping, and
--    9-slice art for a 6 px radius blurs at 70% UI scale. Documented limitation.
--  * Modern text is Inter (SIL OFL 1.1, Media/Fonts), Classic the game's
--    Friz Quadrata; sizes in UI units, so the game's UI scale scales them.

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
T.INSET = 0 -- extra room inside a window's edge (the classic border is wide)

ns.Defaults("ui", {
	opacity = 0.94, -- window ground alpha
	scale = 1, -- window size, 0.5-1.5, on top of the game's UI scale
	style = "modern", -- the look: "modern" | "classic"
})

---------------------------------------------------------------------------
-- Looks
---------------------------------------------------------------------------

local GAME_FONT = "Fonts\\FRIZQT__.TTF"

T.STYLES = {
	modern = {
		label = "Modern",
		about = "Flat and dark with thin lines, in Pathwise's ice blue.",
		accent = "#66D7FF",
		-- the Signature tokens above, as they are
	},
	classic = {
		label = "Classic",
		about = "The game's own dialogs: the stone border, gold headings and red buttons.",
		accent = "#FFD100",
		classic = true,
		inset = 6,
		colors = {
			bg = hex("#0C0B0A"), bg2 = hex("#1C1813"), hover = hex("#3A3018"),
			border = hex("#8C7444"), divider = hex("#5E4E2E"),
			text = hex("#FFFFFF"), text2 = hex("#D2CCC0"), muted = hex("#9A948A"),
			accent = hex("#FFD100"), accentHover = hex("#FFEE88"),
			success = hex("#33FF33"), warning = hex("#FF9933"), error = hex("#FF3333"), silver = hex("#D0D0D0"),
		},
		fonts = { regular = GAME_FONT, medium = GAME_FONT, semibold = GAME_FONT },
		sizes = { window = 14, quest = 15, body = 12, meta = 11, small = 10, label = 11, number = 16, button = 12 },
		-- Headings in the game's gold (GameFontNormal), whatever colour the caller asked for.
		roleColor = { window = "accent", quest = "accent", label = "accent" },
		-- Icon glyphs gold, brighter on hover.
		icon = { "accent", "accentHover" },
	},
}
T.STYLE_ORDER = { "modern", "classic" }

-- Modern keeps a copy of the Signature tokens, so it can be applied again.
do
	local m = T.STYLES.modern
	m.colors, m.fonts, m.sizes = {}, {}, {}
	for k, c in pairs(T.COLORS) do m.colors[k] = { c[1], c[2], c[3], c[4] } end
	for k, f in pairs(T.FONTS) do m.fonts[k] = f end
	for role, r in pairs(T.TYPE) do m.sizes[role] = r[2] end
end

-- Symbols each look's font can draw: Inter has "≈" and "›"; the game's
-- Friz Quadrata covers Latin-1 only.
T.STYLES.modern.symbols = { approx = "≈", next = "›" }
T.STYLES.classic.symbols = { approx = "~", next = ">" }
function T.Sym(name) return T.Style().symbols[name] or "" end

-- The look in use (fixed until the next reload) and its table.
T.STYLE = "modern"
function T.Style() return T.STYLES[T.STYLE] end
function T.IsClassic() return T.STYLES[T.STYLE].classic == true end

-- Chooses a look: saved now, shown after a reload. -> true when it is one
function T.Choose(name)
	if not T.STYLES[name] then return false end
	ns.Set("ui.style", name)
	if name == T.STYLE then
		ns.Print(("look: %s."):format(T.STYLES[name].label))
	else
		ns.Print(("look: %s after a reload (/reload, or Settings > Look > Reload now)."):format(T.STYLES[name].label))
	end
	ns.Fire("STYLE_CHOSEN", name)
	return true
end

-- Applies a look's tokens in place, so every lookup after this sees them.
function T.ApplyStyle(name)
	local style = T.STYLES[name] or T.STYLES.modern
	T.STYLE = T.STYLES[name] and name or "modern"
	for k, c in pairs(style.colors or {}) do
		for i = 1, 4 do T.COLORS[k][i] = c[i] end
	end
	for k, f in pairs(style.fonts or {}) do T.FONTS[k] = f end
	for role, size in pairs(style.sizes or {}) do T.TYPE[role][2] = size end
	T.INSET = style.inset or 0
	return style
end

function T.Color(name)
	-- "One colour for the whole suite": the suite addons' own colours give
	-- way to the accent too.
	if T.MODULES[name] and name ~= "guide" and ns.Get("ui.accentSuite") then return T.COLORS.accent end
	return T.COLORS[name] or T.MODULES[name] or T.COLORS.text
end

---------------------------------------------------------------------------
-- The accent: Pathwise blue, your class colour, or one you pick
---------------------------------------------------------------------------

ns.Defaults("ui", {
	accentMode = "pathwise", -- "pathwise" | "class" | "custom"
	accentColor = "#66D7FF", -- for "custom"
	accentSuite = false, -- the suite addons use the accent instead of their own colours
})

T.PATHWISE_ACCENT = hex("#66D7FF")

-- The player's class colour (Blizzard's C_ClassColor, else RAID_CLASS_COLORS).
function T.ClassColor(classFile)
	if not classFile then
		if not UnitClass then return nil end
		local _, c = UnitClass("player")
		classFile = ns.Compat and ns.Compat.Readable and ns.Compat.Readable(c) or c
	end
	if not classFile then return nil end
	local c
	if C_ClassColor and C_ClassColor.GetClassColor then
		local ok, col = pcall(C_ClassColor.GetClassColor, classFile)
		if ok and col then c = col end
	end
	c = c or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
	if not (c and c.r) then return nil end
	return { c.r, c.g, c.b, 1 }
end

-- A colour a little lighter, for hover.
local function lighten(c, by)
	return { c[1] + (1 - c[1]) * by, c[2] + (1 - c[2]) * by, c[3] + (1 - c[3]) * by, 1 }
end

-- The accent the settings ask for. -> { r, g, b, 1 }. "Pathwise" is the
-- look's own: ice blue in Modern, the game's gold in Classic.
function T.WantedAccent()
	local own = hex(T.Style().accent or "#66D7FF")
	local mode = ns.Get("ui.accentMode")
	if mode == "class" then return T.ClassColor() or own end
	if mode == "custom" then
		local h = ns.Get("ui.accentColor")
		if type(h) == "string" and h:match("^#?%x%x%x%x%x%x$") then return hex(h) end
	end
	return own
end

-- Sets the accent in place, so every colour lookup after this sees it.
function T.ApplyAccent()
	local c = T.WantedAccent()
	local hov = lighten(c, 0.3)
	for i = 1, 4 do T.COLORS.accent[i] = c[i] T.COLORS.accentHover[i] = hov[i] end
	T.MODULES.guide[1], T.MODULES.guide[2], T.MODULES.guide[3] = c[1], c[2], c[3]
	ns.Fire("ACCENT_CHANGED", c)
	return c
end

-- "#RRGGBB" of a colour, for the custom colour box.
function T.ToHex(c)
	return ("#%02X%02X%02X"):format(math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

ns.On("LOADED", function()
	T.ApplyStyle(ns.Get("ui.style"))
	T.ApplyAccent()
end)
ns.On("SETTING_CHANGED", function(path)
	if path == "ui.accentMode" or path == "ui.accentColor" or path == "ui.accentSuite" then T.ApplyAccent() end
end)

local function setColor(tex, name, alpha)
	local c = type(name) == "table" and name or T.Color(name)
	tex:SetColorTexture(c[1], c[2], c[3], alpha or c[4])
end
T.SetColor = setColor

---------------------------------------------------------------------------
-- Builders
---------------------------------------------------------------------------

-- Classic: a border of the game's art round `frame` (BackdropTemplateMixin
-- mixed into a frame made without the template, as Backdrop.lua allows).
-- -> true when it could
local DIALOG_EDGE = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tileEdge = true, edgeSize = 32 } -- BACKDROP_DIALOG_EDGE_32
local CARD_EDGE = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tileEdge = true, edgeSize = 16 }
local mixed = setmetatable({}, { __mode = "k" }) -- frames given the backdrop mixin
local function gameBorder(frame, info, color)
	if not (Mixin and BackdropTemplateMixin and frame.CreateTexture) then return false end
	if not mixed[frame] then
		Mixin(frame, BackdropTemplateMixin)
		if frame.HookScript then frame:HookScript("OnSizeChanged", frame.OnBackdropSizeChanged) end
		mixed[frame] = true
	end
	frame:SetBackdrop(BACKDROP_DIALOG_EDGE_32 and info == DIALOG_EDGE and BACKDROP_DIALOG_EDGE_32 or info)
	if color and frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1) end
	frame.pwBorderArt = info.edgeFile
	return true
end

-- A window or card ground with a 1 px border. Returns the textures so the
-- caller can recolour them (opacity setting, hover). Classic: a window
-- (no ground given) gets the game's dialog border, a bordered card the
-- tooltip border; borderless grounds are the same in both looks.
function T.Panel(frame, ground, border)
	local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	bg:SetAllPoints()
	setColor(bg, ground or "bg", ground == nil and ns.Get("ui.opacity") or nil)
	frame.pwGround = bg
	if border ~= false and T.IsClassic() then
		local window = ground == nil
		if gameBorder(frame, window and DIALOG_EDGE or CARD_EDGE, not window and T.Color("border") or nil) then
			-- The ground stays inside the border's rounded corners.
			local inset = window and 5 or 3
			bg:ClearAllPoints()
			bg:SetPoint("TOPLEFT", inset, -inset)
			bg:SetPoint("BOTTOMRIGHT", -inset, inset)
			return bg
		end
	end
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
	local own = T.Style().roleColor and T.Style().roleColor[role]
	if own and (color == nil or color == "text" or color == "text2") then color = own end
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

-- A soft 1 px shadow for text drawn straight on the game world (the arrow),
-- so it stays readable over snow, sand and bright skies. Windows have their
-- own ground and do not need it.
function T.Shadow(fs)
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 0.85)
end

function T.TextColor(fs, name)
	local c = T.Color(name)
	fs:SetTextColor(c[1], c[2], c[3], c[4])
end

-- Classic: the game's red panel button (UIPanelButtonTemplate), its own
-- gold text. An "accent" button (Next, and the chosen one of a row of
-- choices) keeps its highlight lit and white text, so the choice shows.
-- b.pwText is its label either way.
local function gameButton(parent, label, kind, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetHeight(22)
	local text = b.GetFontString and b:GetFontString() -- the template's ButtonText
	if not text then
		text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("CENTER")
	end
	text:SetText(label)
	b.pwText, b.pwTemplate = text, "UIPanelButtonTemplate"
	if kind == "accent" then
		if b.LockHighlight then b:LockHighlight() end
		text:SetTextColor(1, 1, 1)
		b.pwLit = true
	end
	if onClick then b:SetScript("OnClick", onClick) end
	b:SetWidth(math.max(64, (text:GetStringWidth() or 30) + 28))
	return b
end

-- A low-profile text button: dark surface, 1 px outline.
-- kind "default" (Back) or "accent" (Next). Classic: the game's button.
function T.Button(parent, label, kind, onClick)
	if T.IsClassic() then return gameButton(parent, label, kind, onClick) end
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
	size = size or 22
	local style = T.Style()
	-- Classic: the game's own close button.
	if glyph == "close" and style.classic then
		local b = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
		b:SetSize(size + 4, size + 4)
		b.pwTemplate = "UIPanelCloseButton"
		if onClick then b:SetScript("OnClick", onClick) end
		function b:SetGlyph() end
		b:SetScript("OnEnter", function(self)
			if tip and GameTooltip then
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:SetText(tip, 1, 1, 1)
				GameTooltip:Show()
			end
		end)
		b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
		return b
	end
	local normal, lit = (style.icon or {})[1] or "text2", (style.icon or {})[2] or "text"
	local b = CreateFrame("Button", nil, parent)
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
	T.TextColor(text, normal)
	b.pwIcon = icon
	function b:SetGlyph(name) icon:SetTexture(MEDIA .. "glyph-" .. name) end
	b:SetScript("OnEnter", function(self)
		hover:Show()
		T.TextColor(text, lit)
		if tip and GameTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(tip, 1, 1, 1)
			GameTooltip:Show()
		end
	end)
	b:SetScript("OnLeave", function()
		hover:Hide()
		T.TextColor(text, normal)
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

-- A slider: the game's Slider control drawn the Signature way, a 2 px track,
-- an accent fill up to the value and a round handle (Media/thumb.tga).
-- onChange(value) runs as it moves (rounded to `step`); the slider never
-- re-reads a setting itself, so the caller sets it with slider:SetValue().
function T.Slider(parent, width, min, max, step, onChange)
	local s = CreateFrame("Slider", nil, parent)
	s:SetOrientation("HORIZONTAL")
	s:SetSize(width, 18)
	s:SetMinMaxValues(min, max)
	s:SetValueStep(step)
	s:SetObeyStepOnDrag(true)
	s:EnableMouseWheel(true)
	local track = s:CreateTexture(nil, "BACKGROUND")
	track:SetHeight(T.PROGRESS_H)
	track:SetPoint("LEFT", s, "LEFT", 0, 0)
	track:SetPoint("RIGHT", s, "RIGHT", 0, 0)
	setColor(track, "border")
	local fill = s:CreateTexture(nil, "ARTWORK")
	fill:SetHeight(T.PROGRESS_H)
	fill:SetPoint("LEFT", track, "LEFT", 0, 0)
	setColor(fill, "accent")
	local thumb = s:CreateTexture(nil, "OVERLAY")
	thumb:SetTexture(MEDIA .. "thumb")
	thumb:SetSize(14, 14)
	local c = T.Color("text")
	thumb:SetVertexColor(c[1], c[2], c[3])
	s:SetThumbTexture(thumb)
	s.pwFill, s.pwMin, s.pwMax, s.pwStep, s.pwWidth = fill, min, max, step, width
	local function paintFill(v)
		local p = (v - min) / (max - min)
		p = p < 0 and 0 or (p > 1 and 1 or p)
		if p <= 0 then fill:Hide() else fill:Show() fill:SetWidth(width * p) end
	end
	local last -- the last value onChange was told, so a drag only reports real changes
	local function snap(v)
		v = min + math.floor((v - min) / step + 0.5) * step
		v = math.floor(v * 100 + 0.5) / 100
		return v < min and min or (v > max and max or v)
	end
	s:SetScript("OnValueChanged", function(self, v)
		v = snap(v)
		paintFill(v)
		if self.pwQuiet then last = v return end
		if v == last then return end
		last = v
		if onChange then onChange(v) end
	end)
	-- Dragging: the value follows the pointer along the bar, every frame,
	-- worked out from where the bar really is on screen. Smooth whatever
	-- the window's size, and it never jumps to an end.
	function s:ValueAt(cursorX)
		local left, w, scale = self:GetLeft(), self:GetWidth(), self:GetEffectiveScale()
		if not (left and w and w > 0 and scale and scale > 0) then return nil end
		local p = (cursorX / scale - left) / w
		p = p < 0 and 0 or (p > 1 and 1 or p)
		return snap(min + p * (max - min))
	end
	local function follow(self)
		local x = GetCursorPosition and GetCursorPosition()
		local v = x and self:ValueAt(x)
		if v and v ~= self:GetValue() then self:SetValue(v) end
	end
	s:SetScript("OnMouseDown", function(self, button)
		if button and button ~= "LeftButton" then return end
		self.pwDragging = true
		-- Whoever holds the slider (a panel) can hold still while it moves.
		if self.pwOnDragStart then self.pwOnDragStart(self) end
		follow(self)
		self:SetScript("OnUpdate", follow)
	end)
	local function stop(self)
		if not self.pwDragging then return end
		self.pwDragging = false
		self:SetScript("OnUpdate", nil)
		if self.pwOnDragStop then self.pwOnDragStop(self) end
	end
	s:SetScript("OnMouseUp", stop)
	s:SetScript("OnHide", stop)
	s:SetScript("OnMouseWheel", function(self, delta)
		self:SetValue(math.max(min, math.min(max, (self:GetValue() or min) + delta * step)))
	end)
	s:SetScript("OnEnter", function() thumb:SetVertexColor(T.Color("accentHover")[1], T.Color("accentHover")[2], T.Color("accentHover")[3]) end)
	s:SetScript("OnLeave", function() thumb:SetVertexColor(c[1], c[2], c[3]) end)
	-- Sets the value without calling onChange (opening a panel, a reset).
	function s:SetQuietly(v)
		self.pwQuiet = true
		self:SetValue(v)
		self.pwQuiet = false
		paintFill(v)
	end
	return s
end

-- A small number box: type a value, Enter (or clicking away) commits it,
-- Escape puts back the last value. onCommit(n) gets the typed number, or nil
-- when it is not one; the caller decides what the box then shows
-- (box:SetNumber). The 1 px border lights up in the accent while typing.
function T.NumberBox(parent, width, onCommit)
	local classic = T.IsClassic() -- the game's input box (InputBoxTemplate), else a Signature box
	local e = CreateFrame("EditBox", nil, parent, classic and "InputBoxTemplate" or nil)
	e:SetSize(width, 22)
	e:SetAutoFocus(false)
	e:SetMaxLetters(5)
	e:SetJustifyH("RIGHT")
	e:SetTextInsets(6, 6, 0, 0)
	if not e:SetFont(T.FONTS.regular, 12, "") then e:SetFont("Fonts\\FRIZQT__.TTF", 12, "") end
	local tc = T.Color("text")
	e:SetTextColor(tc[1], tc[2], tc[3])
	if not classic then T.Panel(e, "bg2") end
	local function edges(name)
		for _, t in ipairs(e.pwEdges or {}) do setColor(t, name) end
	end
	local shown = ""
	function e:SetNumber(n)
		shown = n and tostring(n) or ""
		self:SetText(shown)
	end
	local function commit(self)
		local text = (self:GetText() or ""):gsub("[%%%s]", ""):gsub(",", ".")
		onCommit(text:match("^%d+%.?%d*$") and tonumber(text) or nil)
	end
	e:SetScript("OnEditFocusGained", function(self) edges("accent") self:HighlightText() end)
	e:SetScript("OnEditFocusLost", function(self)
		edges("border")
		if self:GetText() ~= shown then commit(self) end
	end)
	e:SetScript("OnEnterPressed", function(self) commit(self) self:ClearFocus() end)
	e:SetScript("OnEscapePressed", function(self) self:SetText(shown) self:ClearFocus() end)
	return e
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
-- Windows that follow the "Window size" setting (ui.scale), on top of the
-- game's own UI scale.
local scaled = setmetatable({}, { __mode = "k" })
function T.TrackScale(frame)
	scaled[frame] = true
	frame:SetScale(ns.Get("ui.scale") or 1)
end

ns.On("SETTING_CHANGED", function(path, value)
	if path == "ui.opacity" then
		for frame in pairs(grounds) do
			if frame.pwGround then setColor(frame.pwGround, "bg", value) end
		end
	elseif path == "ui.scale" then
		for frame in pairs(scaled) do frame:SetScale(value or 1) end
	end
end)

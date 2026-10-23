-- A stand-in for the WoW client, enough to load Pathwise and drive it from
-- tests: frames that remember what was set on them, a fake map and player,
-- events and time. Nothing here claims how the real client behaves beyond
-- what Pathwise calls.

local stub = { events = {}, frames = {}, printed = {}, now = 0 }
_G.stub = stub

local function noop() end

-- Widgets: any method call is accepted; a few remember state.
local Widget = {}
Widget.__index = function(self, k)
	local v = rawget(Widget, k)
	if v ~= nil then return v end
	return noop
end

local function new(kind, name, parent)
	local w = setmetatable({ kind = kind, name = name, parent = parent, shown = true, w = 0, h = 0, scripts = {}, points = {} }, Widget)
	stub.frames[#stub.frames + 1] = w
	if name then _G[name] = w end
	return w
end

function Widget:CreateTexture() return new("Texture", nil, self) end
function Widget:CreateFontString() local f = new("FontString", nil, self) f.text = "" return f end
function Widget:SetScript(k, fn) self.scripts[k] = fn end
function Widget:GetScript(k) return self.scripts[k] end
function Widget:Show() self.shown = true end
function Widget:Hide() self.shown = false end
function Widget:SetShown(on) self.shown = on and true or false end
function Widget:IsShown() return self.shown end
function Widget:SetWidth(w) self.w = w end
function Widget:SetHeight(h) self.h = h end
function Widget:SetSize(w, h) self.w, self.h = w, h end
function Widget:GetWidth() return self.w end
function Widget:GetHeight() return self.h end
function Widget:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Widget:ClearAllPoints() self.points = {} end
function Widget:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function Widget:SetText(t) self.text = t end
function Widget:GetText() return self.text end
function Widget:GetStringWidth() return #(self.text or "") * 6 end
function Widget:GetStringHeight() return (self.text and self.text ~= "") and 14 or 0 end
function Widget:SetFont() return true end
function Widget:SetTexture(t) self.texture = t end
function Widget:SetRotation(r) self.rotation = r end
function Widget:SetColorTexture(r, g, b, a) self.color = { r, g, b, a } end
function Widget:SetVertexColor(r, g, b, a) self.vertex = { r, g, b, a } end
function Widget:SetTextColor(r, g, b, a) self.textColor = { r, g, b, a } end
function Widget:RegisterEvent(e) stub.events[e] = stub.events[e] or {} table.insert(stub.events[e], self) end
function Widget:SetScale(s) self.scale = s end

function CreateFrame(kind, name, parent) return new(kind, name, parent) end
UIParent = new("Frame", "UIParent")
GameTooltip = new("GameTooltip", "GameTooltip")
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) stub.printed[#stub.printed + 1] = m end }
SlashCmdList = {}
C_AddOns = { GetAddOnMetadata = function(_, f) if f == "Version" then return "0.1.0-test" end end }
function IsShiftKeyDown() return false end
function CreateVector2D(x, y) return { x = x, y = y, GetXY = function(v) return v.x, v.y end } end

-- The fake world: one map 0-100 maps to world yards linearly.
-- map 1420: north = 2000 - y*20, west = 3000 - x*30 (yards), instance 0.
stub.player = { map = 1420, x = 50, y = 50, facing = 0, instance = false, taxi = false }
stub.maps = {
	[1420] = { inst = 0, name = "Tirisfal Glades", n0 = 2000, ny = -20, w0 = 3000, wx = -30 },
	[1411] = { inst = 1, name = "Durotar", n0 = 0, ny = -20, w0 = 0, wx = -30 },
}
C_Map = {
	GetBestMapForUnit = function() return stub.player.map end,
	GetPlayerMapPosition = function() return CreateVector2D(stub.player.x / 100, stub.player.y / 100) end,
	GetWorldPosFromMapPos = function(map, v)
		local m = stub.maps[map]
		if not m then return nil end
		return m.inst, CreateVector2D(m.n0 + m.ny * v.y * 100, m.w0 + m.wx * v.x * 100)
	end,
	GetMapInfo = function(map) local m = stub.maps[map] return m and { name = m.name } end,
}
function GetPlayerFacing() return stub.player.facing end
function IsInInstance() return stub.player.instance end
function UnitOnTaxi() return stub.player.taxi end

function stub.fire(event, ...)
	for _, f in ipairs(stub.events[event] or {}) do
		local fn = f.scripts.OnEvent
		if fn then fn(f, event, ...) end
	end
end

-- Runs every shown frame's OnUpdate for `seconds`, in 1/60 s ticks.
function stub.advance(seconds)
	local dt = 1 / 60
	for _ = 1, math.floor(seconds / dt + 0.5) do
		for _, f in ipairs(stub.frames) do
			local fn = f.scripts.OnUpdate
			if fn and f.shown then fn(f, dt) end
		end
	end
end

-- Loads the addon's files in TOC order into a fresh namespace.
function stub.load(root)
	local ns = {}
	local toc = assert(io.open(root .. "/Pathwise/Pathwise.toc")):read("*a")
	local files = {}
	for line in toc:gmatch("[^\r\n]+") do
		if not line:match("^##") and line:match("%.lua$") then files[#files + 1] = line:gsub("\\", "/") end
	end
	for _, f in ipairs(files) do
		local chunk = assert(loadfile(root .. "/Pathwise/" .. f))
		chunk("Pathwise", ns)
	end
	stub.ns, stub.files = ns, files
	return ns
end

-- The texture whose file path matches `pattern`.
function stub.find(pattern)
	for _, f in ipairs(stub.frames) do
		local t = rawget(f, "texture")
		if type(t) == "string" and t:match(pattern) then return f end
	end
end

function stub.login()
	stub.fire("ADDON_LOADED", "Pathwise")
	stub.fire("PLAYER_LOGIN")
end

return stub

-- Pathwise compat: every read of the game's position and facing goes through
-- here, so the rest of the addon never touches a client API directly.
--
-- Forever (client 1.60, Interface 16001) uses retail-style protections: some
-- unit values can come back "secret" in combat, and comparing one throws.
-- Every value read here passes Readable() first. APIs used, all present in
-- Blizzard's Forever UI source (Gethe/wow-ui-source, forever branch):
--   C_Map.GetBestMapForUnit, C_Map.GetPlayerMapPosition,
--   C_Map.GetWorldPosFromMapPos, GetPlayerFacing, IsInInstance, UnitOnTaxi.
-- World positions: GetWorldPosFromMapPos returns (instance, vector) whose x
-- grows north and y grows west.

local ADDON, ns = ...
local C = {}
ns.Compat = C

local function isSecret(v)
	return v ~= nil and issecretvalue ~= nil and issecretvalue(v) and true or false
end
C.IsSecret = isSecret

function C.Readable(v)
	if isSecret(v) then return nil end
	return v
end
local readable = C.Readable

local function xy(v)
	if not v then return nil end
	if v.GetXY then return readable((v:GetXY())), readable((select(2, v:GetXY()))) end
	return readable(v.x), readable(v.y)
end

-- One reusable vector: the arrow converts positions often and should not
-- allocate each time.
local scratch
local function vec(x, y)
	if not scratch then scratch = CreateVector2D and CreateVector2D(0, 0) or {} end
	scratch.x, scratch.y = x, y
	return scratch
end

-- The player's map and position on it, 0-100. nil where the game gives none
-- (instances, loading screens).
function C.PlayerMapPosition()
	if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
	local map = readable(C_Map.GetBestMapForUnit("player"))
	if not map then return nil end
	local x, y = xy(C_Map.GetPlayerMapPosition(map, "player"))
	if not (x and y) or (x == 0 and y == 0) then return nil end
	return map, x * 100, y * 100
end

-- A map position (0-100) to world coordinates: instance, north, west.
function C.MapToWorld(map, x, y)
	if not (map and x and y and C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
	local ok, inst, pos = pcall(C_Map.GetWorldPosFromMapPos, map, vec(x / 100, y / 100))
	if not ok then return nil end
	local north, west = xy(pos)
	inst = readable(inst)
	if not (inst and north and west) then return nil end
	return inst, north, west
end

function C.PlayerWorldPosition()
	local map, x, y = C.PlayerMapPosition()
	if not map then return nil end
	return C.MapToWorld(map, x, y)
end

-- Radians, 0 = north, growing counter-clockwise; nil when unknown.
function C.PlayerFacing()
	return readable(GetPlayerFacing and GetPlayerFacing() or nil)
end

function C.InInstance()
	if not IsInInstance then return false end
	return readable((IsInInstance())) and true or false
end

function C.OnTaxi()
	return UnitOnTaxi and readable(UnitOnTaxi("player")) and true or false
end

function C.MapName(map)
	local info = map and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(map)
	return info and readable(info.name) or nil
end

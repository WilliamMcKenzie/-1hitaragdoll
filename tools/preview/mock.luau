--!nocheck
-- Minimal stand-in for the Roblox API, just enough to run the AssetKit builders
-- outside Studio and dump every visible part as JSON for tools/preview/render.html.
-- Shapes match what Studio builds; Random differs, so seeded details vary slightly.

local Vector3 = {}
Vector3.__index = Vector3
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
end
Vector3.new = v3
Vector3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vector3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vector3.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
Vector3.__mul = function(a, b)
	if type(a) == "number" then return v3(b.X * a, b.Y * a, b.Z * a) end
	if type(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
Vector3.__div = function(a, b) return v3(a.X / b, a.Y / b, a.Z / b) end

local Vector2 = {}
local function v2(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, Vector2)
end
Vector2.__index = function(t, k)
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y) end
	return Vector2[k]
end
Vector2.new = v2
Vector2.__add = function(a, b) return v2(a.X + b.X, a.Y + b.Y) end
Vector2.__sub = function(a, b) return v2(a.X - b.X, a.Y - b.Y) end
Vector2.__mul = function(a, b)
	if type(a) == "number" then return v2(b.X * a, b.Y * a) end
	if type(b) == "number" then return v2(a.X * b, a.Y * b) end
	return v2(a.X * b.X, a.Y * b.Y)
end

local CFrame = {}
CFrame.__index = function(t, k)
	if k == "Position" then return v3(t.p[1], t.p[2], t.p[3]) end
	return CFrame[k]
end
local function cf(p, r)
	return setmetatable({ p = p, r = r or { 1, 0, 0, 0, 1, 0, 0, 0, 1 } }, CFrame)
end
CFrame.new = function(x, y, z)
	if type(x) == "table" then return cf({ x.X, x.Y, x.Z }) end
	return cf({ x or 0, y or 0, z or 0 })
end
CFrame.Angles = function(rx, ry, rz)
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	-- R = Rx * Ry * Rz
	return cf({ 0, 0, 0 }, {
		cy * cz, -cy * sz, sy,
		cx * sz + sx * sy * cz, cx * cz - sx * sy * sz, -sx * cy,
		sx * sz - cx * sy * cz, sx * cz + cx * sy * sz, cx * cy,
	})
end
local function rotate(r, x, y, z)
	return r[1] * x + r[2] * y + r[3] * z, r[4] * x + r[5] * y + r[6] * z, r[7] * x + r[8] * y + r[9] * z
end
CFrame.__mul = function(a, b)
	if getmetatable(b) == Vector3 then
		local x, y, z = rotate(a.r, b.X, b.Y, b.Z)
		return v3(x + a.p[1], y + a.p[2], z + a.p[3])
	end
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			r[i * 3 + j + 1] = a.r[i * 3 + 1] * b.r[j + 1] + a.r[i * 3 + 2] * b.r[3 + j + 1] + a.r[i * 3 + 3] * b.r[6 + j + 1]
		end
	end
	local x, y, z = rotate(a.r, b.p[1], b.p[2], b.p[3])
	return cf({ x + a.p[1], y + a.p[2], z + a.p[3] }, r)
end
CFrame.Inverse = function(a)
	local r = a.r
	local t = { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
	local x, y, z = rotate(t, -a.p[1], -a.p[2], -a.p[3])
	return cf({ x, y, z }, t)
end

local Color3 = {}
Color3.__index = Color3
local function c3(r, g, b) return setmetatable({ R = r, G = g, B = b }, Color3) end
Color3.new = c3
Color3.fromRGB = function(r, g, b) return c3(r / 255, g / 255, b / 255) end
function Color3:Lerp(o, t)
	return c3(self.R + (o.R - self.R) * t, self.G + (o.G - self.G) * t, self.B + (o.B - self.B) * t)
end

local RandomMT = {}
RandomMT.__index = RandomMT
local Random = {}
Random.new = function(seed)
	return setmetatable({ s = (math.floor(seed or 1) % 2147483647) + 1 }, RandomMT)
end
function RandomMT:_next()
	self.s = (self.s * 48271) % 2147483647
	return self.s / 2147483647
end
function RandomMT:NextNumber(a, b)
	local x = self:_next()
	if a then return a + (b - a) * x end
	return x
end
function RandomMT:NextInteger(a, b)
	return math.min(b, a + math.floor(self:_next() * (b - a + 1)))
end

local Enum = setmetatable({}, {
	__index = function(_, cat)
		return setmetatable({}, { __index = function(_, item)
			return setmetatable({ Name = item, __enum = cat }, { __tostring = function() return cat .. "." .. item end })
		end })
	end,
})

local UDim2 = {
	fromOffset = function(x, y) return { __udim2 = { 0, x, 0, y } } end,
	fromScale = function(x, y) return { __udim2 = { x, 0, y, 0 } } end,
}

-- Instances -------------------------------------------------------------------
local PART_CLASSES = { Part = true, WedgePart = true, SpawnLocation = true }
local Inst = {}
local InstMT = {}
local function isPart(o) return PART_CLASSES[rawget(o, "ClassName")] == true end

InstMT.__index = function(o, k)
	local m = Inst[k]
	if m then return m end
	local props = rawget(o, "_props")
	if k == "Parent" then return rawget(o, "_parent") end
	if k == "CFrame" then return props.CFrame end
	if k == "Position" then return props.CFrame.Position end
	return props[k]
end
InstMT.__newindex = function(o, k, v)
	if k == "Parent" then
		local old = rawget(o, "_parent")
		if old then
			local ch = rawget(old, "_children")
			for i, c in ch do
				if c == o then table.remove(ch, i) break end
			end
		end
		rawset(o, "_parent", v)
		if v then table.insert(rawget(v, "_children"), o) end
		return
	end
	rawget(o, "_props")[k] = v
end

local function newInstance(class)
	local o = setmetatable({ ClassName = class, _props = { Name = class }, _children = {} }, InstMT)
	if isPart(o) then
		o._props.Transparency = 0
		o._props.CFrame = CFrame.new()
		o._props.Size = v3(4, 1, 2)
	end
	return o
end

function Inst.IsA(o, c)
	if c == "BasePart" then return isPart(o) end
	return o.ClassName == c
end
function Inst.GetChildren(o) return table.clone(rawget(o, "_children")) end
function Inst.GetDescendants(o)
	local out = {}
	local function walk(x)
		for _, c in rawget(x, "_children") do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(o)
	return out
end
function Inst.FindFirstChild(o, n)
	for _, c in rawget(o, "_children") do
		if c.Name == n then return c end
	end
end
function Inst.FindFirstChildOfClass(o, cl)
	for _, c in rawget(o, "_children") do
		if c.ClassName == cl then return c end
	end
end
function Inst.Destroy(o) o.Parent = nil end
function Inst.Clone(o)
	local n = newInstance(o.ClassName)
	for k, v in rawget(o, "_props") do rawget(n, "_props")[k] = v end
	for _, c in rawget(o, "_children") do Inst.Clone(c).Parent = n end
	return n
end
function Inst.GetBoundingBox(o)
	local lo, hi = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
	for _, p in Inst.GetDescendants(o) do
		if isPart(p) then
			local s = p.Size
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local w = p.CFrame * v3(sx * s.X / 2, sy * s.Y / 2, sz * s.Z / 2)
						lo = { math.min(lo[1], w.X), math.min(lo[2], w.Y), math.min(lo[3], w.Z) }
						hi = { math.max(hi[1], w.X), math.max(hi[2], w.Y), math.max(hi[3], w.Z) }
					end
				end
			end
		end
	end
	return CFrame.new((lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2, (lo[3] + hi[3]) / 2), v3(hi[1] - lo[1], hi[2] - lo[2], hi[3] - lo[3])
end
function Inst.PivotTo(o, target)
	local pivot = rawget(o, "_props").WorldPivot or CFrame.new()
	local delta = target * pivot:Inverse()
	for _, p in Inst.GetDescendants(o) do
		if isPart(p) then p.CFrame = delta * p.CFrame end
	end
	o.WorldPivot = target
end
function Inst.GetService(_, name)
	return SERVICES[name]
end
function Inst.SetWaypoint() end

local Instance = { new = function(class) return newInstance(class) end }

SERVICES = {}
for _, n in { "Workspace", "ServerStorage", "Lighting", "ChangeHistoryService" } do
	SERVICES[n] = newInstance(n)
	SERVICES[n].Name = n
end
local game = newInstance("DataModel")
local workspace = SERVICES.Workspace

-- Dump visible parts under Workspace as JSON.
local function num(x) return string.format("%.3f", x) end
local function dump()
	local rows = {}
	for _, p in workspace:GetDescendants() do
		if isPart(p) and (p.Transparency or 0) < 1 then
			local c, s, col = p.CFrame, p.Size, p.Color
			local tex = p:FindFirstChildOfClass("Texture")
			table.insert(rows, string.format(
				'{"c":"%s","s":[%s,%s,%s],"p":[%s,%s,%s],"r":[%s],"col":[%s,%s,%s],"top":"%s","side":"%s","mat":"%s","grid":%s}',
				p.ClassName, num(s.X), num(s.Y), num(s.Z), num(c.p[1]), num(c.p[2]), num(c.p[3]),
				table.concat((function() local t = {} for i = 1, 9 do t[i] = num(c.r[i]) end return t end)(), ","),
				num(col.R), num(col.G), num(col.B), tostring(p.TopSurface), tostring(p.FrontSurface), tostring(p.Material),
				if tex then tostring(tex.StudsPerTileU) else "0"
			))
		end
	end
	print("[" .. table.concat(rows, ",\n") .. "]")
end

-- The Baseplate template's own Baseplate + SpawnLocation, so the clone path runs.
do
	local bp = Instance.new("Part")
	bp.Name = "Baseplate"
	bp.Size = Vector3.new(2048, 16, 2048)
	bp.CFrame = CFrame.new(0, -8, 0)
	bp.Color = Color3.fromRGB(91, 91, 91)
	bp.TopSurface = "SurfaceType.Smooth"
	bp.FrontSurface = "SurfaceType.Smooth"
	bp.Material = "Material.Plastic"
	local t = Instance.new("Texture")
	t.StudsPerTileU = 8
	t.StudsPerTileV = 8
	t.Transparency = 0.8
	t.Texture = "rbxassetid://6372755229"
	t.Face = "NormalId.Top"
	t.Color3 = Color3.new(0, 0, 0)
	t.Parent = bp
	bp.Parent = workspace
	local sp = Instance.new("SpawnLocation")
	sp.Name = "SpawnLocation"
	sp.Size = Vector3.new(12, 1, 12)
	sp.CFrame = CFrame.new(0, 0.5, 0)
	sp.Color = Color3.fromRGB(163, 162, 165)
	sp.Parent = workspace
end

--[[
	Kit: palette-driven generators for the ground, walls and trees.

	Each generator takes (parent, origin, palette, opts) and returns a Model whose
	pivot is the origin, sitting on local y = 0. Generators with randomness take
	opts.seed so the same seed always gives the same shape.
]]

local Workspace = game:GetService("Workspace")

local Builder = require(script.Parent.Builder)
local Palette = require(script.Parent.Palette)

local Kit = {}

local V3 = Vector3.new
local block = Builder.block
local shade = Builder.shade

local function rngFor(opts): Random
	return Random.new(opts.seed or 1)
end

--------------------------------------------------------------------------------
-- Ground: a clone of the place's own default Baseplate (same part, same native
-- grid texture), with only its colour changed. Top face sits at local y = 0.
-- Falls back to building an identical part if the place has no Baseplate.
--------------------------------------------------------------------------------
function Kit.nativeBaseplate(): BasePart?
	local bp = Workspace:FindFirstChild("Baseplate")
	if bp and bp:IsA("BasePart") then
		return bp
	end
	return nil
end

function Kit.ground(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local settings = Palette.Baseplate
	local source = opts.source or Kit.nativeBaseplate()
	local nativeTex = source and source:FindFirstChildOfClass("Texture")
	if nativeTex then
		Builder.useGridFrom(nativeTex)
	end
	local p: BasePart
	if source then
		p = source:Clone()
		-- strip anything that is not the native look (scripts, welds, etc.)
		for _, child in p:GetChildren() do
			if not child:IsA("Texture") then
				child:Destroy()
			end
		end
	else
		p = Builder.part(Workspace, V3(512, settings.Thickness, 512), CFrame.new(), pal.Ground, "smooth")
		Builder.baseplateTexture(p, settings)
	end
	-- An earlier showcase script hid the template baseplate; make the copy visible.
	p.Transparency = 0
	p.CanCollide = true
	p.Anchored = true
	p.Locked = false
	p.Material = Enum.Material.Plastic
	p.Reflectance = 0
	for _, tex in p:GetChildren() do
		if tex:IsA("Texture") and tex.Transparency >= 1 then
			tex.Transparency = settings.TextureTransparency
		end
	end
	local thickness = p.Size.Y
	p.Size = V3(opts.sizeX or p.Size.X, thickness, opts.sizeZ or p.Size.Z)
	p.CFrame = origin * CFrame.new(0, -thickness / 2, 0)
	p.Color = opts.color or pal.Ground
	p.TopSurface = Enum.SurfaceType.Smooth -- the ground is the plain native baseplate: grid texture, no studs
	p.Name = opts.name or (pal.Name .. "Baseplate")
	p.Parent = parent
	return p
end

--------------------------------------------------------------------------------
-- Walls: one dirt slab and one grass cap per segment, with the native
-- baseplate grid and the L-stud texture on every face.
-- opts: length, height, cap (grass thickness), depth,
--       bands (a grass band every bandEvery studs, like the striped cliffs)
--------------------------------------------------------------------------------
local function wallSlab(m, origin: CFrame, pal, x: number, z: number, sx: number, sz: number, opts)
	local height = opts.height or 24
	local cap = opts.cap or 4
	local bandEvery = opts.bands and (opts.bandEvery or 12) or nil
	local y = 0
	while y < height - cap do
		local top = if bandEvery then math.min(y + bandEvery, height - cap) else height - cap
		local isBand = bandEvery ~= nil and top < height - cap
		local dirtTop = if isBand then top - cap else top
		block(m, origin, x, y, z, V3(sx, dirtTop - y, sz), pal.Dirt, "terrain")
		if isBand then
			block(m, origin, x, dirtTop, z, V3(sx, cap, sz), pal.Grass, "terrain")
		end
		y = top
	end
	block(m, origin, x, height - cap, z, V3(sx, cap, sz), pal.Grass, "terrain")
end

function Kit.wall(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local m = Builder.model(opts.name or "Wall", parent, origin)
	wallSlab(m, origin, pal, 0, 0, opts.length or 32, opts.depth or 4, opts)
	return m
end

-- L-shaped corner: one arm along +X, one along +Z, meeting at the origin.
function Kit.wallCorner(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local len = opts.length or 16
	local depth = opts.depth or 4
	local m = Builder.model(opts.name or "WallCorner", parent, origin)
	wallSlab(m, origin, pal, (len + depth) / 2 - depth / 2, 0, len + depth, depth, opts)
	wallSlab(m, origin, pal, 0, depth / 2 + len / 2, depth, len, opts)
	return m
end

--------------------------------------------------------------------------------
-- Cliff: one raised block of land, like the stepped plateaus in the reference.
-- Dirt body with a darker band at the foot and a grass cap, bottom at local y = 0.
-- opts: sizeX, sizeZ, height, cap, name
--------------------------------------------------------------------------------
function Kit.cliff(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local sx, sz = opts.sizeX or 24, opts.sizeZ or 24
	local height = opts.height or 12
	local cap = math.min(opts.cap or 4, height - 2)
	local m = Builder.model(opts.name or "Cliff", parent, origin)
	local foot = math.min(2, height - cap - 1)
	if foot > 0 then
		block(m, origin, 0, 0, 0, V3(sx, foot, sz), pal.Dirt, "terrain")
	end
	block(m, origin, 0, math.max(foot, 0), 0, V3(sx, height - cap - math.max(foot, 0), sz), pal.Dirt, "terrain")
	block(m, origin, 0, height - cap, 0, V3(sx, cap, sz), pal.Grass, "terrain")
	return m
end

-- Low leafy bush sitting on the ground.
function Kit.bush(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local m = Builder.model(opts.name or "Bush", parent, origin)
	local rng = rngFor(opts)
	local w = opts.width or 6
	local c = Builder.pick(pal.Leaves, rng)
	block(m, origin, 0, 0, 0, V3(w, 3, w), c, "studs")
	block(m, origin, (rng:NextNumber() - 0.5) * 2, 3, (rng:NextNumber() - 0.5) * 2, V3(math.max(2, w - 2) + 0.02, 2, math.max(2, w - 2) + 0.02), c, "studs")
	return m
end

--------------------------------------------------------------------------------
-- Leaf cluster: stacked, offset studded boxes. Bottom of the cluster at local y=0.
--------------------------------------------------------------------------------
function Kit.canopy(m, origin: CFrame, pal, rng: Random, width: number)
	local idx = 0
	local function leaf(cx, y0, cz, sx, sy, sz, c)
		idx += 1
		-- tiny per-box size offset keeps overlapping faces from z-fighting
		local e = idx * 0.02
		block(m, origin, cx, y0 - e / 2, cz, V3(math.max(1, math.floor(sx)) + e, sy + e, math.max(1, math.floor(sz)) + e), c, "studs")
	end
	local layers = {
		{ w = width, h = 4, y = 0 },
		{ w = width * 0.78, h = 4, y = 3 },
		{ w = width * 0.5, h = 3, y = 6 },
	}
	-- one flat colour per clump (no shade variation)
	local c = Builder.pick(pal.Leaves, rng)
	leaf(0, -1, 0, width * 0.62, 2, width * 0.62, c)
	for _, L in layers do
		local lz = L.w * (0.8 + 0.3 * rng:NextNumber())
		leaf((rng:NextNumber() - 0.5) * 2, L.y, (rng:NextNumber() - 0.5) * 2, L.w, L.h, lz, c)
		for _ = 1, rng:NextInteger(2, 3) do
			local ox = (rng:NextNumber() - 0.5) * L.w * 0.9
			local oz = (rng:NextNumber() - 0.5) * L.w * 0.9
			local lw = L.w * (0.4 + 0.2 * rng:NextNumber())
			leaf(ox, L.y + rng:NextInteger(-1, 1), oz, lw, L.h, lw, c)
		end
	end
end

--------------------------------------------------------------------------------
-- Tree, after QM's reference: one thick flat-colour trunk, a couple of chunky
-- branches made of two angled segments with a leaf clump on each end, and a
-- crown made of a cluster of rounded voxel blobs.
-- One leaf colour per tree. opts: height, trunk (width), canopy (crown width),
-- branches, seed
--------------------------------------------------------------------------------
-- rounded voxel blob: three crossed boxes give a cube with stepped, bevelled
-- edges (the look of the reference foliage). Centre at local (0, 0, 0).
local function blob(m, origin: CFrame, c: Color3, size: number, idx: number)
	local w = math.max(4, math.floor(size / 2) * 2)
	local step = if w >= 10 then 4 else 2
	local e = idx * 0.03 -- keeps coplanar faces of neighbouring blobs from z-fighting
	Builder.box(m, origin, V3(0, 0, 0), V3(w + e, w - step + e, w - step + e), c, "studs")
	Builder.box(m, origin, V3(0, 0, 0), V3(w - step + e + 0.01, w + e, w - step + e + 0.01), c, "studs")
	Builder.box(m, origin, V3(0, 0, 0), V3(w - step + e + 0.02, w - step + e + 0.02, w + e), c, "studs")
end

local function clump(m, origin: CFrame, c: Color3, rng: Random, w: number, idx: number)
	blob(m, origin * CFrame.new(0, w / 2, 0), c, w, idx * 3)
	if w >= 8 and rng:NextNumber() < 0.6 then
		local a = rng:NextNumber() * math.pi * 2
		blob(m, origin * CFrame.new(math.cos(a) * w * 0.4, w * 0.3, math.sin(a) * w * 0.4), c, w * 0.6, idx * 3 + 1)
	end
end

-- a straight segment from `start` (local space), heading `yaw` around Y and
-- tilted `tilt` radians off vertical; returns the far end
local function limb(m, origin: CFrame, start: Vector3, yaw: number, tilt: number, len: number, width: number, c: Color3): Vector3
	local d = V3(math.cos(yaw), 0, -math.sin(yaw))
	local axis = V3(0, math.cos(tilt), 0) + d * math.sin(tilt)
	local center = start + axis * (len / 2)
	local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, -tilt)
	Builder.part(m, V3(width, len + width * 0.5, width), origin * CFrame.new(center) * rot, c, "studs")
	return start + axis * len
end

function Kit.tree(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local H = opts.height or 28
	local tw = opts.trunk or math.max(4, math.floor(H / 5))
	local crown = opts.canopy or math.floor(H * 0.9)
	local leaf = Builder.pick(pal.Leaves, rng)
	local m = Builder.model(opts.name or "Tree", parent, origin)

	-- trunk: one thick block, a slightly wider foot
	block(m, origin, 0, 0, 0, V3(tw + 1, 1, tw + 1), pal.Trunk, "studs")
	block(m, origin, 0, 0, 0, V3(tw, H, tw), pal.Trunk, "studs")

	-- crown: a cluster of rounded blobs forming a dome over the trunk top
	local idx = 0
	local function puff(x, y, z, size)
		idx += 1
		blob(m, origin * CFrame.new(x, y, z), leaf, size, idx)
	end
	local top = H + crown * 0.15
	local core = crown * 0.62
	puff(0, top, 0, core)
	local n = rng:NextInteger(3, 4)
	local a0 = rng:NextNumber() * math.pi * 2
	for i = 1, n do
		local a = a0 + i * (math.pi * 2 / n) + (rng:NextNumber() - 0.5) * 0.5
		local r = crown * (0.3 + 0.06 * rng:NextNumber())
		puff(math.cos(a) * r, top - crown * 0.08 + rng:NextInteger(-1, 1) * 2, math.sin(a) * r, crown * (0.48 + 0.08 * rng:NextNumber()))
	end
	puff((rng:NextNumber() - 0.5) * crown * 0.2, top + core * 0.45, (rng:NextNumber() - 0.5) * crown * 0.2, crown * 0.4)

	-- branches: two angled segments each, ending in a clump below the crown edge
	local count = math.min(opts.branches or 2, 4)
	local bw = math.max(2, math.floor(tw * 0.6))
	local yaw0 = rng:NextNumber() * math.pi * 2
	for b = 1, count do
		local yaw = yaw0 + (b - 1) * (math.pi * 2 / count) + (rng:NextNumber() - 0.5) * 0.6
		local hb = H * (0.3 + 0.12 * rng:NextNumber())
		local d = V3(math.cos(yaw), 0, -math.sin(yaw))
		local start = V3(0, hb, 0) + d * (tw / 2 - bw / 2)
		local mid = limb(m, origin, start, yaw, math.rad(50 + rng:NextNumber() * 12), math.max(5, crown * 0.32), bw, pal.Trunk)
		local tip = limb(m, origin, mid, yaw, math.rad(12 + rng:NextNumber() * 12), 3 + rng:NextInteger(0, 1), bw, pal.Trunk)
		clump(m, origin * CFrame.new(tip.X, tip.Y - 3, tip.Z), leaf, rng, math.max(6, math.floor(crown * 0.32)), 20 + b)
	end
	return m
end

return Kit

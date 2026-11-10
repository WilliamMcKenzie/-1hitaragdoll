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
	for _, tex in p:GetChildren() do
		if tex:IsA("Texture") and tex.Transparency >= 1 then
			tex.Transparency = settings.TextureTransparency
		end
	end
	local thickness = p.Size.Y
	p.Size = V3(opts.sizeX or p.Size.X, thickness, opts.sizeZ or p.Size.Z)
	p.CFrame = origin * CFrame.new(0, -thickness / 2, 0)
	p.Color = opts.color or pal.Ground
	p.TopSurface = Enum.SurfaceType.Studs
	p.Name = opts.name or (pal.Name .. "Baseplate")
	p.Parent = parent
	return p
end

--------------------------------------------------------------------------------
-- Walls: one dirt slab and one grass cap per segment. The checkerboard comes
-- from the native baseplate grid on each face, with studs on top of it.
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
		block(m, origin, x, y, z, V3(sx, dirtTop - y, sz), pal.Dirt, "studs")
		if isBand then
			block(m, origin, x, dirtTop, z, V3(sx, cap, sz), pal.Grass, "studs")
		end
		y = top
	end
	block(m, origin, x, height - cap, z, V3(sx, cap, sz), pal.Grass, "studs")
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
	-- darker underside
	leaf(0, -1, 0, width * 0.62, 2, width * 0.62, shade(pal.Leaves[1], -0.14))
	for _, L in layers do
		local c = Builder.jitter(Builder.pick(pal.Leaves, rng), rng, 0.04)
		local lz = L.w * (0.8 + 0.3 * rng:NextNumber())
		leaf((rng:NextNumber() - 0.5) * 2, L.y, (rng:NextNumber() - 0.5) * 2, L.w, L.h, lz, c)
		for _ = 1, rng:NextInteger(2, 3) do
			local ox = (rng:NextNumber() - 0.5) * L.w * 0.9
			local oz = (rng:NextNumber() - 0.5) * L.w * 0.9
			local lw = L.w * (0.4 + 0.2 * rng:NextNumber())
			local lc = Builder.jitter(Builder.pick(pal.Leaves, rng), rng, 0.05)
			leaf(ox, L.y + rng:NextInteger(-1, 1), oz, lw, L.h, lw, lc)
		end
	end
end

--------------------------------------------------------------------------------
-- Voxel tree: straight stepped trunk with a root flare, branches that stair-step
-- out and up from the middle of the trunk and end in their own leaf clumps
-- (below and outside the crown), and a wide layered crown on top.
-- opts: height, trunk (width), canopy (crown width), branches, reach, seed
--------------------------------------------------------------------------------
function Kit.tree(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local H = opts.height or 26
	local tw = opts.trunk or 3
	local crown = opts.canopy or 16
	local m = Builder.model(opts.name or "Tree", parent, origin)

	-- root flare + trunk in 4-stud segments with alternating shade
	block(m, origin, 0, 0, 0, V3(tw + 2, 1, tw + 2), shade(pal.Trunk, -0.06), "studs")
	block(m, origin, 0, 1, 0, V3(tw + 1, 1, tw + 1), pal.Trunk, "studs")
	block(m, origin, 0, 2, 0, V3(tw, H - 2, tw), pal.Trunk, "studs")

	Kit.canopy(m, origin * CFrame.new(0, H - 1, 0), pal, rng, crown)

	-- branches: first one picks a random side, later ones go to the other sides
	local dirs = { V3(1, 0, 0), V3(0, 0, 1), V3(-1, 0, 0), V3(0, 0, -1) }
	local start = rng:NextInteger(0, 3)
	local count = math.min(opts.branches or 2, 4)
	local bw = tw
	local reach = opts.reach or (crown * 0.5 + 2) -- ends just outside the crown edge
	for b = 1, count do
		-- opposite sides first (0, 2), then the remaining two (1, 3)
		local order = { 0, 2, 1, 3 }
		local d = dirs[(start + order[b]) % 4 + 1]
		local by = math.floor(H * (0.38 + 0.14 * rng:NextNumber()) + (b - 1) * 2)
		local pos = V3(0, by, 0) + d * (tw / 2)
		local out = 0
		local thisReach = reach * (0.8 + 0.3 * rng:NextNumber())
		-- stair-step: two out, one up, until the branch clears the crown
		while out < thisReach do
			pos += d * 2 + V3(0, 1.5, 0)
			out += 2
			block(m, origin, pos.X, pos.Y - bw / 2, pos.Z, V3(bw, bw, bw), pal.Trunk, "studs")
		end
		-- short upward tip into the clump
		block(m, origin, pos.X, pos.Y - bw / 2, pos.Z, V3(bw, 4, bw), pal.Trunk, "studs")
		Kit.canopy(m, origin * CFrame.new(pos.X, pos.Y + 3, pos.Z), pal, rng, crown * 0.5)
	end
	return m
end

return Kit

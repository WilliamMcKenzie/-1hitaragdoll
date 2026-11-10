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
	p.Name = opts.name or (pal.Name .. "Baseplate")
	p.Parent = parent
	return p
end

--------------------------------------------------------------------------------
-- Walls: studded cliff segments built from 4x4 blocks in alternating shades,
-- a grass cap on top. Straight walls run along local X; corners turn 90 degrees.
-- opts: length, height, cap (grass thickness), depth, block, bands (grass band
--       every bandEvery studs, like the striped cliffs at spawn)
--------------------------------------------------------------------------------
local function wallColumn(m, origin: CFrame, pal, x: number, z: number, col: number, opts, sx: number, sz: number)
	local height = opts.height or 24
	local cap = opts.cap or 4
	local b = opts.block or 4
	local bandEvery = opts.bands and (opts.bandEvery or 12) or nil
	local y, row = 0, 0
	while y < height - cap do
		local h = math.min(b, height - cap - y)
		local even = (col + row) % 2 == 0
		local isBand = bandEvery ~= nil and (y + h) % bandEvery == 0 and y + h < height - cap
		local color
		if isBand then
			color = if even then pal.Grass else pal.GrassAlt
		else
			color = if even then pal.Dirt else pal.DirtAlt
		end
		block(m, origin, x, y, z, V3(sx, h, sz), color, "studs")
		y += h
		row += 1
	end
	local even = (col + row) % 2 == 0
	block(m, origin, x, y, z, V3(sx, cap, sz), if even then pal.Grass else pal.GrassAlt, "studs")
end

function Kit.wall(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local len = opts.length or 32
	local b = opts.block or 4
	local depth = opts.depth or 4
	local m = Builder.model(opts.name or "Wall", parent, origin)
	local n = math.floor(len / b)
	for i = 1, n do
		wallColumn(m, origin, pal, (i - n / 2 - 0.5) * b, 0, i, opts, b, depth)
	end
	return m
end

-- L-shaped corner: one arm along +X, one along +Z, meeting at the origin.
function Kit.wallCorner(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local len = opts.length or 16
	local b = opts.block or 4
	local depth = opts.depth or 4
	local m = Builder.model(opts.name or "WallCorner", parent, origin)
	local n = math.floor(len / b)
	wallColumn(m, origin, pal, 0, 0, 0, opts, depth, depth)
	for i = 1, n do
		local d = depth / 2 + (i - 0.5) * b
		wallColumn(m, origin, pal, d, 0, i, opts, b, depth)
		wallColumn(m, origin, pal, 0, d, i, opts, depth, b)
	end
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
	local y, k = 2, 0
	while y < H do
		local h = math.min(4, H - y)
		block(m, origin, 0, y, 0, V3(tw, h, tw), if k % 2 == 0 then pal.Trunk else shade(pal.Trunk, -0.07), "studs")
		y += h
		k += 1
	end

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

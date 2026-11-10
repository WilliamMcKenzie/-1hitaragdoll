--[[
	Kit: palette-driven generators for every asset type.

	Each generator takes (parent, origin, palette, opts) and returns a Model whose
	pivot is the origin, sitting on local y = 0. Generators with randomness take
	opts.seed so the same seed always gives the same shape.
]]

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
-- Ground: the native Roblox baseplate (plastic slab + baseplate grid texture),
-- recoloured per biome. Top face sits at local y = 0.
--------------------------------------------------------------------------------
function Kit.ground(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local bp = Palette.Baseplate
	local sx, sz = opts.sizeX or 512, opts.sizeZ or 512
	local m = Builder.model(opts.name or (pal.Name .. "Ground"), parent, origin)
	local p = Builder.box(m, origin, V3(0, -bp.Thickness / 2, 0), V3(sx, bp.Thickness, sz), opts.color or pal.Ground, "smooth", { name = "Baseplate" })
	Builder.baseplateTexture(p, bp)
	return m
end

--------------------------------------------------------------------------------
-- Terraced cliff: a blob-shaped stack of tiers built from studded cells.
-- opts: cellsX, cellsZ, tiers, cell (studs), tierHeight, cap (grass thickness),
--       bands (grass band on every tier face instead of only on the top), seed
--------------------------------------------------------------------------------
function Kit.terrace(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local cx, cz = opts.cellsX or 8, opts.cellsZ or 8
	local tiers = opts.tiers or 3
	local cell = opts.cell or 4
	local th = opts.tierHeight or 12
	local cap = opts.cap or 4
	local bands = opts.bands == true
	local m = Builder.model(opts.name or "TerraceCliff", parent, origin)

	-- Height map: each tier is a rectangle inset from the one below by 1-2 cells
	-- per side (random), with a couple of corner notches so it reads as a blob.
	local level = {}
	for i = 1, cx do
		level[i] = {}
		for j = 1, cz do
			level[i][j] = 0
		end
	end
	local l0, r0, b0, f0 = 0, 0, 0, 0
	for t = 1, tiers do
		if t > 1 then
			l0 += rng:NextInteger(1, 2)
			r0 += rng:NextInteger(1, 2)
			b0 += rng:NextInteger(1, 2)
			f0 += rng:NextInteger(1, 2)
		end
		local i1, i2, j1, j2 = 1 + l0, cx - r0, 1 + b0, cz - f0
		if i2 < i1 or j2 < j1 then
			break
		end
		local notch = math.max(1, math.floor(math.min(i2 - i1, j2 - j1) / 4))
		local cut = {}
		for _ = 1, 2 do
			cut[rng:NextInteger(1, 4)] = rng:NextInteger(1, notch)
		end
		for i = i1, i2 do
			for j = j1, j2 do
				local inCorner = false
				local corners = {
					{ i - i1, j - j1 },
					{ i2 - i, j - j1 },
					{ i - i1, j2 - j },
					{ i2 - i, j2 - j },
				}
				for c, d in corners do
					local n = cut[c]
					if n and d[1] < n and d[2] < n then
						inCorner = true
					end
				end
				if not inCorner then
					level[i][j] = t
				end
			end
		end
	end

	local function lv(i, j)
		if i < 1 or i > cx or j < 1 or j > cz then
			return 0
		end
		return level[i][j]
	end

	for i = 1, cx do
		for j = 1, cz do
			local L = level[i][j]
			local x = (i - cx / 2 - 0.5) * cell
			local z = (j - cz / 2 - 0.5) * cell
			local minNeighbour = math.min(lv(i - 1, j), lv(i + 1, j), lv(i, j - 1), lv(i, j + 1))
			for t = 1, L do
				local isTop = t == L
				local visibleSide = minNeighbour < t
				if isTop or visibleSide then
					local even = (i + j + t) % 2 == 0
					local y0 = (t - 1) * th
					local dirt = if even then pal.Dirt else pal.DirtAlt
					local grass = if even then pal.Grass else pal.GrassAlt
					if isTop or bands then
						block(m, origin, x, y0, z, V3(cell, th - cap, cell), dirt, "studs")
						block(m, origin, x, y0 + th - cap, z, V3(cell, cap, cell), grass, "studs")
					else
						block(m, origin, x, y0, z, V3(cell, th, cell), dirt, "studs")
					end
				end
			end
		end
	end
	return m
end

--------------------------------------------------------------------------------
-- Boundary wall: a straight studded cliff segment along local X.
--------------------------------------------------------------------------------
function Kit.wall(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local len = opts.length or 32
	local tiers = opts.tiers or 2
	local th = opts.tierHeight or 12
	local cap = opts.cap or 4
	local cell = opts.cell or 4
	local depth = opts.depth or 4
	local m = Builder.model(opts.name or "BoundaryWall", parent, origin)
	local n = math.floor(len / cell)
	for i = 1, n do
		local x = (i - n / 2 - 0.5) * cell
		for t = 1, tiers do
			local even = (i + t) % 2 == 0
			local y0 = (t - 1) * th
			local dirt = if even then pal.Dirt else pal.DirtAlt
			local grass = if even then pal.Grass else pal.GrassAlt
			if t == tiers or opts.bands then
				block(m, origin, x, y0, 0, V3(cell, th - cap, depth), dirt, "studs")
				block(m, origin, x, y0 + th - cap, 0, V3(cell, cap, depth), grass, "studs")
			else
				block(m, origin, x, y0, 0, V3(cell, th, depth), dirt, "studs")
			end
		end
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
-- Voxel tree: stepped trunk with root flare, diagonal branches ending in small
-- leaf clusters, and a big canopy on top.
-- opts: height, trunk (width), canopy (width), branches, seed
--------------------------------------------------------------------------------
function Kit.tree(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local H = opts.height or 26
	local tw = opts.trunk or 3
	local m = Builder.model(opts.name or "Tree", parent, origin)

	block(m, origin, 0, 0, 0, V3(tw + 2, 1, tw + 2), shade(pal.Trunk, -0.06), "studs")
	local y, k = 1, 0
	while y < H do
		local h = math.min(4, H - y)
		block(m, origin, 0, y, 0, V3(tw, h, tw), if k % 2 == 0 then pal.Trunk else shade(pal.Trunk, -0.07), "studs")
		y += h
		k += 1
	end

	Kit.canopy(m, origin * CFrame.new(0, H - 1, 0), pal, rng, opts.canopy or 16)

	local dirs = { V3(1, 0, 0), V3(-1, 0, 0), V3(0, 0, 1), V3(0, 0, -1) }
	for i = #dirs, 2, -1 do
		local j = rng:NextInteger(1, i)
		dirs[i], dirs[j] = dirs[j], dirs[i]
	end
	for b = 1, math.min(opts.branches or 2, 4) do
		local d = dirs[b]
		local by = math.floor(H * (0.3 + 0.15 * rng:NextNumber()))
		local pos = V3(0, by, 0) + d * (tw / 2)
		local bw = math.max(2, tw - 1)
		-- staircase of overlapping blocks: out one, up one, so the branch reads as solid
		for _ = 1, rng:NextInteger(3, 5) do
			pos += d * 1.5 + V3(0, 1.5, 0)
			block(m, origin, pos.X, pos.Y - bw / 2, pos.Z, V3(bw, bw, bw), pal.Trunk, "studs")
		end
		block(m, origin, pos.X, pos.Y, pos.Z, V3(bw, 3, bw), pal.Trunk, "studs")
		Kit.canopy(m, origin * CFrame.new(pos.X, pos.Y + 3, pos.Z), pal, rng, (opts.canopy or 16) * 0.55)
	end
	return m
end

--------------------------------------------------------------------------------
-- Small props
--------------------------------------------------------------------------------

-- Round bush: a low leaf cluster on the ground.
function Kit.bush(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local m = Builder.model(opts.name or "Bush", parent, origin)
	Kit.canopy(m, origin * CFrame.new(0, 1, 0), pal, rng, opts.width or 6)
	return m
end

-- Stepped bush: a little studded ziggurat.
function Kit.steppedBush(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local m = Builder.model(opts.name or "SteppedBush", parent, origin)
	local w = opts.width or 6
	local c = pal.Leaves
	block(m, origin, 0, 0, 0, V3(w, 2, w), shade(c[1], -0.05), "studs")
	block(m, origin, 0, 2, 0, V3(w - 2, 2, w - 2), c[1], "studs")
	block(m, origin, 0, 4, 0, V3(math.max(2, w - 4), 2, math.max(2, w - 4)), c[#c], "studs")
	return m
end

-- Grass tuft: three blades joined at the base.
function Kit.tuft(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local m = Builder.model(opts.name or "GrassTuft", parent, origin)
	local c = Builder.jitter(pal.Tuft, rng, 0.05)
	local s = opts.scale or 1
	block(m, origin, 0, 0, 0, V3(2.2 * s, 0.6 * s, 0.6 * s), c, "smooth")
	block(m, origin, -0.8 * s, 0.6 * s, 0, V3(0.6 * s, 1.2 * s, 0.6 * s), c, "smooth")
	block(m, origin, 0, 0.6 * s, 0, V3(0.6 * s, 2.0 * s, 0.6 * s), shade(c, 0.06), "smooth")
	block(m, origin, 0.8 * s, 0.6 * s, 0, V3(0.6 * s, 1.5 * s, 0.6 * s), c, "smooth")
	return m
end

-- Flower: a tuft with a coloured studded head.
function Kit.flower(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local m = Builder.model(opts.name or "Flower", parent, origin)
	local stem = shade(pal.Tuft, -0.1)
	local h = 1.5 + rng:NextInteger(0, 1)
	block(m, origin, 0, 0, 0, V3(0.5, h, 0.5), stem, "smooth")
	block(m, origin, 0.5, 0, 0, V3(0.9, 0.5, 0.5), stem, "smooth")
	local head = Builder.pick(pal.Flowers, rng)
	block(m, origin, 0, h, 0, V3(1.4, 1, 1.4), head, "studs")
	block(m, origin, 0, h + 1, 0, V3(0.6, 0.4, 0.6), pal.Flowers[3] or head, "smooth")
	return m
end

-- Flower patch: a scatter of flowers and tufts.
function Kit.flowerPatch(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local m = Builder.model(opts.name or "FlowerPatch", parent, origin)
	local r = opts.radius or 5
	for n = 1, opts.count or 7 do
		local cf = origin * CFrame.new((rng:NextNumber() - 0.5) * 2 * r, 0, (rng:NextNumber() - 0.5) * 2 * r) * CFrame.Angles(0, rng:NextInteger(0, 3) * math.pi / 2, 0)
		local child = if n % 3 == 0 then Kit.tuft(m, cf, pal, { seed = n }) else Kit.flower(m, cf, pal, { seed = rng:NextInteger(1, 1e6) })
		child.Name = child.Name .. n
	end
	return m
end

-- Rock: two or three stacked studded blocks.
function Kit.rock(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local rng = rngFor(opts)
	local s = opts.size or 6
	local m = Builder.model(opts.name or "Rock", parent, origin)
	block(m, origin, 0, 0, 0, V3(s, math.ceil(s * 0.5), s * 0.8), pal.Rock, "studs")
	block(m, origin, (rng:NextNumber() - 0.5) * 2, math.ceil(s * 0.5), (rng:NextNumber() - 0.5), V3(s * 0.66, math.ceil(s * 0.33), s * 0.55), pal.RockAlt, "studs")
	if s >= 6 then
		block(m, origin, s * 0.55, 0, s * 0.3, V3(s * 0.4, s * 0.3, s * 0.4), shade(pal.Rock, -0.06), "studs")
	end
	return m
end

--------------------------------------------------------------------------------
-- Base / gameplay structures
--------------------------------------------------------------------------------

-- Plaza: mauve inlet tiles framed by dark trim. opts.spawn adds a SpawnLocation.
function Kit.plaza(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local sx, sz = opts.sizeX or 48, opts.sizeZ or 48
	local h = opts.height or 1
	local tile = opts.tile or 8
	local trim = opts.trimWidth or 1
	local m = Builder.model(opts.name or "Plaza", parent, origin)
	local nx, nz = math.floor(sx / tile), math.floor(sz / tile)
	for i = 1, nx do
		for j = 1, nz do
			local c = if (i + j) % 2 == 0 then pal.Plaza else pal.PlazaAlt
			block(m, origin, (i - nx / 2 - 0.5) * tile, 0, (j - nz / 2 - 0.5) * tile, V3(tile, h, tile), c, "inlet")
		end
	end
	local th = h + 0.4
	local wx, wz = nx * tile, nz * tile
	block(m, origin, 0, 0, -(wz + trim) / 2, V3(wx + trim * 2, th, trim), pal.Trim, "smooth")
	block(m, origin, 0, 0, (wz + trim) / 2, V3(wx + trim * 2, th, trim), pal.Trim, "smooth")
	block(m, origin, -(wx + trim) / 2, 0, 0, V3(trim, th, wz), pal.Trim, "smooth")
	block(m, origin, (wx + trim) / 2, 0, 0, V3(trim, th, wz), pal.Trim, "smooth")
	if opts.spawn then
		local sp = block(m, origin, 0, h, 0, V3(8, 0.6, 8), pal.Trim, "inlet", { class = "SpawnLocation", name = "Spawn" })
		;(sp :: any).Neutral = true
		;(sp :: any).Duration = 0
	end
	return m
end

-- Ramp: an inlet wedge rising towards local -Z, with trim rails and a landing.
function Kit.ramp(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local w, h, len = opts.width or 12, opts.height or 8, opts.length or 20
	local landing = opts.landing or 8
	local m = Builder.model(opts.name or "Ramp", parent, origin)
	-- WedgePart slopes up towards its back (+Z local); rotate 180 so it rises to -Z.
	local wedgeCf = origin * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.pi, 0)
	Builder.part(m, V3(w, h, len), wedgeCf, pal.Plaza, "inlet", { class = "WedgePart", name = "Slope" })
	Builder.part(m, V3(1, h + 0.4, len), origin * CFrame.new(-(w + 1) / 2, h / 2 + 0.2, 0) * CFrame.Angles(0, math.pi, 0), pal.Trim, "smooth", { class = "WedgePart" })
	Builder.part(m, V3(1, h + 0.4, len), origin * CFrame.new((w + 1) / 2, h / 2 + 0.2, 0) * CFrame.Angles(0, math.pi, 0), pal.Trim, "smooth", { class = "WedgePart" })
	block(m, origin, 0, 0, -(len + landing) / 2, V3(w, h, landing), pal.PlazaAlt, "inlet", { name = "Landing" })
	block(m, origin, -(w + 1) / 2, 0, -(len + landing) / 2, V3(1, h + 0.4, landing), pal.Trim, "smooth")
	block(m, origin, (w + 1) / 2, 0, -(len + landing) / 2, V3(1, h + 0.4, landing), pal.Trim, "smooth")
	return m
end

-- Action pad: neon square in a dark frame, for egg / upgrade / rebirth stations.
function Kit.pad(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local s = opts.size or 12
	local color = opts.color or pal.PadEgg
	local m = Builder.model(opts.name or "ActionPad", parent, origin)
	block(m, origin, 0, 0, 0, V3(s + 2, 0.8, s + 2), pal.Trim, "smooth", { name = "Frame" })
	local glow = block(m, origin, 0, 0, 0, V3(s, 1, s), color, "smooth", { name = "Glow", material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = s
	light.Brightness = 1.5
	light.Parent = glow
	return m
end

-- Display stand: dark base with a mauve inlet top, for showing weapons.
function Kit.stand(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local m = Builder.model(opts.name or "DisplayStand", parent, origin)
	block(m, origin, 0, 0, 0, V3(6, 1, 6), pal.Trim, "smooth")
	block(m, origin, 0, 1, 0, V3(4, 3, 4), pal.PlazaAlt, "studs")
	block(m, origin, 0, 4, 0, V3(5, 0.6, 5), pal.Plaza, "inlet", { name = "Top" })
	return m
end

-- Crystal / boulder block: rounded-looking stacked lavender cubes.
function Kit.crystalBlock(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local m = Builder.model(opts.name or "CrystalBlock", parent, origin)
	local s = opts.size or 4
	block(m, origin, 0, 0, 0, V3(s, s * 0.6, s), pal.Rock, "studs")
	block(m, origin, 0, s * 0.6, 0, V3(s * 0.7, s * 0.25, s * 0.7), pal.RockAlt, "studs")
	return m
end

-- Biome gate: two studded pillars and a lintel with the biome name on it.
function Kit.gate(parent, origin: CFrame, pal, opts)
	opts = opts or {}
	local w = opts.width or 28
	local h = opts.height or 24
	local pw = 6
	local m = Builder.model(opts.name or "BiomeGate", parent, origin)
	for _, side in { -1, 1 } do
		local x = side * (w / 2 + pw / 2)
		block(m, origin, x, 0, 0, V3(pw + 2, 2, pw + 2), pal.Trim, "smooth")
		for t = 0, math.floor(h / 4) - 1 do
			block(m, origin, x, 2 + t * 4, 0, V3(pw, 4, pw), if t % 2 == 0 then pal.Dirt else pal.DirtAlt, "studs")
		end
		block(m, origin, x, 2 + h, 0, V3(pw, 3, pw), pal.Grass, "studs")
	end
	local beam = block(m, origin, 0, h - 4, 0, V3(w + pw * 2, 6, pw), pal.Trim, "studs", { name = "Lintel" })
	block(m, origin, 0, h + 2, 0, V3(w + pw * 2 + 2, 2, pw + 2), pal.Grass, "studs")
	if opts.text then
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local sg = Instance.new("SurfaceGui")
			sg.Face = face
			sg.PixelsPerStud = 25
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.fromScale(1, 1)
			tl.BackgroundTransparency = 1
			tl.Font = Enum.Font.FredokaOne
			tl.TextScaled = true
			tl.TextColor3 = Color3.new(1, 1, 1)
			tl.Text = opts.text
			tl.Parent = sg
			sg.Parent = beam
		end
	end
	return m
end

return Kit

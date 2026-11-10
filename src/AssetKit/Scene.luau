--[[
	Scene: a small forest area made only from the kit, like the reference shots.
	Flat native-baseplate ground, stepped cliffs around the edge (some with trees
	on top), a winding path through gaps in the cliffs, scattered trees and bushes.

	Scene.build(parent, center, palette, opts) -> Folder
	opts: size (plate size, default 256), seed
]]

local Builder = require(script.Parent.Builder)
local Kit = require(script.Parent.Kit)

local Scene = {}

local V3 = Vector3.new

-- path as axis-aligned legs in plate-local XZ, from the south edge to the north edge
local function pathLegs(half: number)
	return {
		{ a = Vector2.new(0, half), b = Vector2.new(0, 24) },
		{ a = Vector2.new(0, 24), b = Vector2.new(44, 24) },
		{ a = Vector2.new(44, 24), b = Vector2.new(44, -half) },
	}
end

local function distToLegs(legs, x: number, z: number): number
	local best = math.huge
	for _, l in legs do
		local minX, maxX = math.min(l.a.X, l.b.X), math.max(l.a.X, l.b.X)
		local minZ, maxZ = math.min(l.a.Y, l.b.Y), math.max(l.a.Y, l.b.Y)
		local dx = math.max(minX - x, 0, x - maxX)
		local dz = math.max(minZ - z, 0, z - maxZ)
		best = math.min(best, math.sqrt(dx * dx + dz * dz))
	end
	return best
end

local function buildPath(folder: Instance, center: CFrame, pal, legs, width: number)
	local m = Builder.model("Path", folder, center)
	for i, l in legs do
		local minX, maxX = math.min(l.a.X, l.b.X), math.max(l.a.X, l.b.X)
		local minZ, maxZ = math.min(l.a.Y, l.b.Y), math.max(l.a.Y, l.b.Y)
		local sx, sz = maxX - minX + width, maxZ - minZ + width
		local cx, cz = (minX + maxX) / 2, (minZ + maxZ) / 2
		local e = i * 0.01
		Builder.block(m, center, cx, 0, cz, V3(sx + 3 + e, 0.4 + e, sz + 3 + e), pal.PathTrim, "smooth", { name = "Trim" .. i })
		Builder.block(m, center, cx, 0, cz, V3(sx + e, 0.6 + e, sz + e), pal.Path, "smooth", { name = "Path" .. i })
	end
	return m
end

function Scene.build(parent: Instance, center: CFrame, pal, opts)
	opts = opts or {}
	local size = opts.size or 256
	local half = size / 2
	local rng = Random.new(opts.seed or 7)
	local folder = Instance.new("Folder")
	folder.Name = (opts.name or pal.Name) .. "Scene"
	folder.Parent = parent

	Kit.ground(folder, center, pal, { source = opts.source, sizeX = size, sizeZ = size, name = pal.Name .. "SceneGround" })

	local width = 12
	local legs = pathLegs(half)
	buildPath(folder, center, pal, legs, width)

	-- cliffs around the edge, leaving gaps where the path leaves the plate
	local cliffs = Builder.model("Cliffs", folder, center)
	local spots = {} -- flat cliff tops that can hold a tree: {x, y, z, w}
	local idx = 0
	local function cliffAt(x, z, sx, sz, h, name)
		idx += 1
		local e = idx * 0.02 -- tiny offsets keep overlapping tops from z-fighting
		Kit.cliff(cliffs, center * CFrame.new(x, 0, z), pal, { sizeX = sx + e, sizeZ = sz + e, height = h + e, name = name .. idx })
	end
	local sides = {
		-- origin of the edge, direction along it, inward normal
		{ o = Vector2.new(-half, half), along = Vector2.new(1, 0), inward = Vector2.new(0, -1) }, -- south
		{ o = Vector2.new(half, -half), along = Vector2.new(-1, 0), inward = Vector2.new(0, 1) }, -- north
		{ o = Vector2.new(-half, -half), along = Vector2.new(0, 1), inward = Vector2.new(1, 0) }, -- west
		{ o = Vector2.new(half, half), along = Vector2.new(0, -1), inward = Vector2.new(-1, 0) }, -- east
	}
	for _, side in sides do
		local t = 0
		while t < size do
			local len = rng:NextInteger(5, 11) * 4
			len = math.min(len, size - t)
			local mid = side.o + side.along * (t + len / 2)
			if distToLegs(legs, mid.X, mid.Y) > len / 2 + width then
				local depth = rng:NextInteger(5, 9) * 4
				local h1 = rng:NextInteger(2, 4) * 4
				local c1 = mid + side.inward * (depth / 2)
				local horiz = side.along.X ~= 0
				local function dims(l, d)
					if horiz then return l, d end
					return d, l
				end
				-- tall back wall right at the edge, so the area reads as a valley
				local backD = 8
				local cb = mid + side.inward * (backD / 2)
				local bx, bz = dims(len, backD)
				cliffAt(cb.X, cb.Y, bx, bz, rng:NextInteger(7, 11) * 4, "Back_")
				local sx, sz = dims(len, depth)
				cliffAt(c1.X, c1.Y, sx, sz, h1, "Tier1_")
				local topH, topDepth, topC, topLen = h1, depth, c1, len
				-- second step, set back towards the edge
				if rng:NextNumber() < 0.75 then
					local d2 = depth - rng:NextInteger(2, 3) * 4
					local l2 = math.max(12, len - rng:NextInteger(1, 3) * 4)
					local h2 = h1 + rng:NextInteger(2, 3) * 4
					local shift = (rng:NextNumber() - 0.5) * (len - l2)
					local c2 = side.o + side.along * (t + len / 2 + shift) + side.inward * (d2 / 2)
					local sx2, sz2 = dims(l2, d2)
					cliffAt(c2.X, c2.Y, sx2, sz2, h2, "Tier2_")
					topH, topDepth, topC, topLen = h2, d2, c2, l2
					-- occasional third step
					if d2 > 16 and rng:NextNumber() < 0.35 then
						local d3 = d2 - 8
						local l3 = math.max(12, l2 - 8)
						local h3 = h2 + 8
						local c3 = side.o + side.along * (t + len / 2 + shift) + side.inward * (d3 / 2)
						local sx3, sz3 = dims(l3, d3)
						cliffAt(c3.X, c3.Y, sx3, sz3, h3, "Tier3_")
						topH, topDepth, topC, topLen = h3, d3, c3, l3
					end
				end
				if topDepth >= 16 and topLen >= 16 and rng:NextNumber() < 0.55 then
					table.insert(spots, { x = topC.X, y = topH, z = topC.Y, w = math.min(topDepth, topLen) })
				end
				-- a bush in front of some cliffs
				if rng:NextNumber() < 0.4 then
					local b = mid + side.inward * (depth + 4) + side.along * ((rng:NextNumber() - 0.5) * len * 0.6)
					if distToLegs(legs, b.X, b.Y) > width then
						Kit.bush(folder, center * CFrame.new(b.X, 0, b.Y), pal, { width = rng:NextInteger(5, 8), seed = rng:NextInteger(1, 9999) })
					end
				end
			end
			t += len
		end
	end

	-- trees: on cliff tops, then scattered over the open ground
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = folder
	local function tree(x, y, z, scale)
		local h = rng:NextInteger(18, 32) * scale
		Kit.tree(trees, center * CFrame.new(x, y, z), pal, {
			name = "Tree",
			height = math.floor(h),
			canopy = math.floor(h * (0.8 + 0.2 * rng:NextNumber())),
			branches = rng:NextInteger(1, 2),
			seed = rng:NextInteger(1, 99999),
		})
	end
	for _, s in spots do
		tree(s.x, s.y, s.z, 0.8)
	end
	local placed = {}
	local inner = half - 44
	local tries = 0
	while #placed < (opts.trees or 14) and tries < 2000 do
		tries += 1
		local x = (rng:NextNumber() * 2 - 1) * inner
		local z = (rng:NextNumber() * 2 - 1) * inner
		local ok = distToLegs(legs, x, z) > width + 6
		if ok then
			for _, p in placed do
				if (p - Vector2.new(x, z)).Magnitude < 30 then
					ok = false
					break
				end
			end
		end
		if ok then
			table.insert(placed, Vector2.new(x, z))
			tree(x, 0, z, 1)
		end
	end
	return folder
end

return Scene

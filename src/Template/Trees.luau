--[[
	Trees: KISS block trees, a handful of variants per biome.

	One block per trunk or branch, foliage = one big block plus one slightly
	smaller block just above it. Every part is flat colour + QM's L-studs.
	Each builder takes (parent, origin CFrame on the ground, palette, rng)
	and returns a Model pivoted at the origin.
]]

local Builder = require(script.Parent.Builder)

local Trees = {}

local V3 = Vector3.new

local function box(m: Model, origin: CFrame, center: Vector3, size: Vector3, color: Color3, name: string)
	return Builder.box(m, origin, center, size, color, "studs", { name = name })
end

-- One block running from local point a to local point b (branches, leaning trunks).
local function beam(m: Model, origin: CFrame, a: Vector3, b: Vector3, thick: number, color: Color3, name: string)
	local dir = b - a
	local up = if math.abs(dir.Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	local cf = CFrame.lookAt((a + b) / 2, b, up)
	return Builder.part(m, V3(thick, thick, dir.Magnitude), origin * cf, color, "studs", { name = name })
end

-- big block with its bottom at y, small block on top: reads as a rounded crown
local function crown(m: Model, origin: CFrame, at: Vector3, w: number, h: number, color: Color3, name: string)
	box(m, origin, at + V3(0, h / 2, 0), V3(w, h, w), color, name .. "Big")
	local sw = w * 0.7
	box(m, origin, at + V3(0, h + h * 0.25, 0), V3(sw, h * 0.5, sw), color, name .. "Top")
end

--------------------------------------------------------------------------------
-- Forest: regular trees
--------------------------------------------------------------------------------
Trees.Forest = {}

-- 1 classic: trunk + crown
Trees.Forest[1] = function(m, o, pal, leaves)
	box(m, o, V3(0, 6, 0), V3(3, 12, 3), pal.Trunk, "Trunk")
	crown(m, o, V3(0, 11, 0), 14, 8, leaves, "Leaves")
end

-- 2 tall and narrow
Trees.Forest[2] = function(m, o, pal, leaves)
	box(m, o, V3(0, 10, 0), V3(3, 20, 3), pal.Trunk, "Trunk")
	crown(m, o, V3(0, 19, 0), 11, 9, leaves, "Leaves")
end

-- 3 with one side branch carrying a small crown
Trees.Forest[3] = function(m, o, pal, leaves)
	box(m, o, V3(0, 7, 0), V3(3, 14, 3), pal.Trunk, "Trunk")
	beam(m, o, V3(0, 7, 0), V3(7, 12, 0), 2, pal.Trunk, "Branch")
	crown(m, o, V3(7, 11.5, 0), 8, 4, leaves, "BranchLeaves")
	crown(m, o, V3(0, 13, 0), 13, 7, leaves, "Leaves")
end

-- 4 short and wide
Trees.Forest[4] = function(m, o, pal, leaves)
	box(m, o, V3(0, 4, 0), V3(4, 8, 4), pal.Trunk, "Trunk")
	crown(m, o, V3(0, 7, 0), 18, 7, leaves, "Leaves")
end

--------------------------------------------------------------------------------
-- Savanna: acacias. Leaning trunk block, one block per branch, a flat slab
-- canopy (big slab + smaller slab above) at the end of each branch.
--------------------------------------------------------------------------------
Trees.Savanna = {}

local function slabCanopy(m, o, at: Vector3, w: number, d: number, color: Color3, name: string)
	box(m, o, at + V3(0, 0.8, 0), V3(w, 1.6, d), color, name .. "Big")
	box(m, o, at + V3(0, 2.2, 0), V3(w * 0.68, 1.2, d * 0.68), color, name .. "Top")
end

local function acacia(m, o, pal, leaves, lean: number, height: number, branches)
	local top = V3(lean, height, 0)
	beam(m, o, V3(0, -1, 0), top, 2.6, pal.Trunk, "Trunk")
	for i, b in branches do
		local tip = top + b.to
		-- start a little below the trunk top so the joint is buried
		beam(m, o, top - V3(0, 1, 0), tip, 1.8, pal.Trunk, "Branch" .. i)
		slabCanopy(m, o, tip - V3(0, 0.6, 0), b.w, b.d, leaves, "Canopy" .. i)
	end
end

-- 1 two branches
Trees.Savanna[1] = function(m, o, pal, leaves)
	acacia(m, o, pal, leaves, 2, 10, {
		{ to = V3(-6, 7, 2), w = 15, d = 12 },
		{ to = V3(7, 5, -3), w = 13, d = 11 },
	})
end

-- 2 three branches, wide
Trees.Savanna[2] = function(m, o, pal, leaves)
	acacia(m, o, pal, leaves, -2, 11, {
		{ to = V3(-7, 6, -2), w = 13, d = 11 },
		{ to = V3(6, 7, 4), w = 14, d = 12 },
		{ to = V3(1, 9, -6), w = 11, d = 10 },
	})
end

-- 3 one tall branch, single big canopy
Trees.Savanna[3] = function(m, o, pal, leaves)
	acacia(m, o, pal, leaves, 3, 13, {
		{ to = V3(2, 6, 0), w = 20, d = 16 },
	})
end

-- 4 short and leaning hard
Trees.Savanna[4] = function(m, o, pal, leaves)
	acacia(m, o, pal, leaves, 5, 7, {
		{ to = V3(4, 4, 1), w = 16, d = 13 },
		{ to = V3(-3, 6, -2), w = 10, d = 9 },
	})
end

function Trees.build(kind: string, parent: Instance, origin: CFrame, pal, rng: Random, variant: number?)
	local list = Trees[kind]
	local i = variant or rng:NextInteger(1, #list)
	local leaves = pal.Leaves[rng:NextInteger(1, #pal.Leaves)]
	local m = Builder.model(kind .. "Tree" .. i, parent, origin)
	list[i](m, origin, pal, leaves)
	return m
end

return Trees

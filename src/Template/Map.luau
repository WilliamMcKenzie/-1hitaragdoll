--[[
	Map: the reusable map template.

	Layout (X is the throw direction, Y up):
	  - Spawn: a 3:1 rectangle of native baseplate ground, walled in with dirt.
	  - The long +X wall opens onto the world through a gap as wide as the
	    biome lane (QM). Through it: a glowing white line, then the hit zone, a
	    thin yellow strip with big "HIT ZONE" text. Past the strip the ground
	    steps down a few studs (Settings.Drop).
	  - The biomes run out one after another along +X, each Settings.BiomeLength
	    long, between terraced dirt walls (Settings.Terraces): blocky steps with
	    grass lips and trees on every step, then a tall back wall; bushes and
	    flowers line the lane edges (QM's reference, 2026-11-12).

	Map.build() makes Workspace.Map. Gameplay code can read:
	  Map.HitZone (part, attribute HitZone = true)
	  Map.Biomes.<Name>.Ground (attributes Biome, StartX, EndX)
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local Builder = require(script.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Colors = require(script.Parent.Colors)
local Trees = require(script.Parent.Trees)

local Map = {}

local V3 = Vector3.new

Map.Settings = {
	SpawnDepth = 80, -- short side (X)
	SpawnLength = 240, -- long side (Z), 3:1
	WallHeight = 14,
	WallThickness = 4,
	GrassCap = 2,
	GapWidth = 120, -- the opening in the long wall: as wide as the lane (QM)
	HitZoneDepth = 12, -- thin strip (QM)
	LineWidth = 1.5, -- glowing line just before the strip, on the spawn side
	Drop = 4, -- small step from the hit zone down to the biomes (QM: barely any)
	LaneWidth = 120, -- = GapWidth
	-- biome walls: terraces stepping up and away from the lane (QM's reference),
	-- each cut into segments whose height jitters a little for a blocky skyline,
	-- trees on every step, then a tall back wall
	Terraces = {
		{ Width = 16, Height = 8, Trees = 9 },
		{ Width = 16, Height = 18, Trees = 7 },
		{ Width = 16, Height = 30, Trees = 6 },
	},
	BackWallHeight = 44,
	TerraceSegment = 50,
	TerraceJitter = 3,
	GrassOverhang = 1, -- grass caps lip out over the step below
	Bushes = 26, -- per biome, along the lane edges
	Flowers = 40, -- per biome, tiny two-block flowers on the lane edges
	BiomeLength = 500,
	TreesPerBiome = 26,
	ClearPath = 20, -- no trees within this many studs of the centre line
	Biomes = { "Forest", "Savanna" },
	-- turns the HIT ZONE text so it reads from the spawn side
	TextRotation = 180,
}

-- Part from two corners (min, max) in world space.
local function slab(parent: Instance, name: string, a: Vector3, b: Vector3, color: Color3, style, opts)
	local lo = a:Min(b)
	local hi = a:Max(b)
	opts = opts or {}
	opts.name = name
	return Builder.part(parent, hi - lo, CFrame.new((lo + hi) / 2), color, style, opts)
end

-- Dirt wall with a grass cap, both in the terrain style (native grid + studs).
-- lip: the cap sticks out this far past z0 (negative) or z1 (positive)
local function wall(parent: Instance, name: string, x0, z0, x1, z1, yBottom: number, yTop: number, pal, lip: number?)
	local cap = Map.Settings.GrassCap
	local m = Builder.model(name, parent)
	slab(m, "Dirt", V3(x0, yBottom, z0), V3(x1, yTop - cap, z1), pal.Dirt, "terrain")
	local gz0, gz1 = z0, z1
	if lip and lip < 0 then
		gz0 += lip
	elseif lip and lip > 0 then
		gz1 += lip
	end
	slab(m, "Grass", V3(x0, yTop - cap, gz0), V3(x1, yTop, gz1), pal.Grass, "terrain")
	return m
end

-- KISS bush: a big leaf block with a smaller one on top
local function bush(parent: Instance, at: Vector3, w: number, color: Color3, rot: number)
	local m = Builder.model("Bush", parent)
	local cf = CFrame.new(at) * CFrame.Angles(0, rot, 0)
	local h = w * 0.55
	Builder.part(m, V3(w, h, w * 0.8), cf * CFrame.new(0, h / 2, 0), color, "studs", { name = "Big" })
	Builder.part(m, V3(w * 0.65, h * 0.5, w * 0.55), cf * CFrame.new(0, h * 1.25, 0), color, "studs", { name = "Top" })
	return m
end

-- KISS flower: one stem block, one head block
local function flower(parent: Instance, at: Vector3, stem: Color3, head: Color3)
	local m = Builder.model("Flower", parent)
	Builder.part(m, V3(0.4, 1.6, 0.4), CFrame.new(at + V3(0, 0.8, 0)), stem, "smooth", { name = "Stem", canCollide = false })
	Builder.part(m, V3(1.2, 0.8, 1.2), CFrame.new(at + V3(0, 1.9, 0)), head, "studs", { name = "Head", canCollide = false })
	return m
end

-- The place's own Baseplate is the template for every piece of ground (QM:
-- native baseplate, recoloured). It is kept in ServerStorage.TemplateSource.
local function baseplateSource(): BasePart?
	local store = ServerStorage:FindFirstChild("TemplateSource")
	local bp = store and store:FindFirstChild("Baseplate")
	if not bp then
		bp = Workspace:FindFirstChild("Baseplate")
	end
	return if bp and bp:IsA("BasePart") then bp else nil
end

local function ground(parent: Instance, name: string, x0, z0, x1, z1, topY: number, color: Color3)
	local src = baseplateSource()
	local p: BasePart
	if src then
		p = src:Clone()
		for _, c in p:GetChildren() do
			if not c:IsA("Texture") then
				c.Parent = nil
			end
		end
		local tex = p:FindFirstChildOfClass("Texture")
		if tex then
			Builder.useGridFrom(tex)
			if tex.Transparency >= 1 then
				tex.Transparency = Palette.Baseplate.TextureTransparency
			end
		end
	else
		p = Instance.new("Part")
		p.Size = V3(1, Palette.Baseplate.Thickness, 1)
		Builder.baseplateTexture(p, Palette.Baseplate)
	end
	local thick = p.Size.Y
	p.Size = V3(math.abs(x1 - x0), thick, math.abs(z1 - z0))
	p.CFrame = CFrame.new((x0 + x1) / 2, topY - thick / 2, (z0 + z1) / 2)
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Reflectance = 0
	p.Transparency = 0
	p.Anchored = true
	p.CanCollide = true
	p.Locked = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Name = name
	p.Parent = parent
	return p
end

local function text(parent: Instance, t: string, size: UDim2, order: number)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Font = Enum.Font.FredokaOne
	l.Text = t
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.LayoutOrder = order
	l.Parent = parent
	return l
end

-- "HIT ZONE" painted across the strip, as big as it fits
local function hitZoneText(hz: BasePart)
	local S = Map.Settings
	-- a flat carrier part, turned so the text reads from the spawn side
	-- a Top-face SurfaceGui runs its width along the part's local Z, so the
	-- long side goes on Z when the rotation is 0/180 and on X when it is 90/270
	local across, along = hz.Size.Z - 2, hz.Size.X - 1
	local size = if S.TextRotation % 180 == 0 then V3(along, 0.05, across) else V3(across, 0.05, along)
	local carrier = Builder.part(hz.Parent :: Instance, size,
		hz.CFrame * CFrame.new(0, hz.Size.Y / 2 + 0.03, 0) * CFrame.Angles(0, math.rad(S.TextRotation), 0),
		Color3.new(1, 1, 1), "smooth", { name = "HitZoneText", canCollide = false, castShadow = false, transparency = 1 })
	carrier.CanQuery = false
	carrier.CanTouch = false
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Text"
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 8 -- low on purpose: TextScaled tops out at 100 px, so this keeps the words big
	gui.LightInfluence = 1
	gui.Parent = carrier
	local word = text(gui, "HIT ZONE", UDim2.fromScale(0.97, 0.94), 1)
	word.AnchorPoint = Vector2.new(0.5, 0.5)
	word.Position = UDim2.fromScale(0.5, 0.5)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = word
	return carrier
end

local function sign(parent: Instance, name: string, at: Vector3, color: Color3)
	local anchor = Builder.part(parent, V3(1, 1, 1), CFrame.new(at), color, "smooth",
		{ name = name .. "Sign", canCollide = false, castShadow = false, transparency = 1 })
	anchor.CanQuery = false
	anchor.CanTouch = false
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(80, 20) -- studs, so it shrinks with distance
	gui.MaxDistance = 2000
	gui.LightInfluence = 0
	gui.Parent = anchor
	local l = text(gui, name, UDim2.fromScale(1, 1), 1)
	l.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = l
	return anchor
end

function Map.build(parent: Instance?)
	local S = Map.Settings
	parent = parent or Workspace
	local old = (parent :: Instance):FindFirstChild("Map")
	if old then
		old.Parent = nil
	end
	local root = Builder.model("Map", parent)
	local C = Colors.Map
	local wallPal = { Dirt = C.Dirt, Grass = C.Grass }

	local D, L, H, t = S.SpawnDepth, S.SpawnLength, S.WallHeight, S.WallThickness
	local G, HZ, Drop, W = S.GapWidth, S.HitZoneDepth, S.Drop, S.LaneWidth
	local terraceWidth = 0
	for _, tr in S.Terraces do
		terraceWidth += tr.Width
	end
	local outerZ = W / 2 + terraceWidth + t -- outer Z of the biome walls
	local edgeZ = math.max(L / 2 + t, outerZ) -- outer Z of the spawn and cliff

	----------------------------------------------------------------- spawn
	local spawnM = Builder.model("Spawn", root)
	ground(spawnM, "Ground", -D - t, -L / 2 - t, 0, L / 2 + t, 0, C.SpawnGround)
	wall(spawnM, "BackWall", -D - t, -L / 2 - t, -D, L / 2 + t, 0, H, wallPal)
	wall(spawnM, "SideWallLeft", -D, -L / 2 - t, 0, -L / 2, 0, H, wallPal)
	wall(spawnM, "SideWallRight", -D, L / 2, 0, L / 2 + t, 0, H, wallPal)
	wall(spawnM, "FrontWallLeft", 0, -L / 2 - t, t, -G / 2, 0, H, wallPal)
	wall(spawnM, "FrontWallRight", 0, G / 2, t, L / 2 + t, 0, H, wallPal)
	-- the place's SpawnLocation, made invisible and moved to the back of the spawn
	local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not sp then
		sp = Instance.new("SpawnLocation")
		sp.Parent = Workspace
	end
	sp.Anchored = true
	sp.Size = V3(12, 1, 12)
	-- players spawn facing +X, at the gap and the hit zone (a SpawnLocation's front is -Z)
	sp.CFrame = CFrame.new(-D + 14, -0.45, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	sp.Transparency = 1
	sp.CanCollide = false
	sp.Neutral = true
	for _, d in sp:GetChildren() do
		if d:IsA("Decal") then
			d.Transparency = 1
		end
	end

	--------------------------------------------------------------- hit zone
	local hzM = Builder.model("HitZone", root)
	-- gap floor (under the front wall), then the glowing line, then the strip
	local lx0, lx1 = t, t + S.LineWidth
	local x1 = lx1 + HZ
	ground(hzM, "GapFloor", 0, -G / 2, t, G / 2, 0, C.SpawnGround)
	local hz = slab(hzM, "Zone", V3(lx1, -1, -G / 2), V3(x1, 0, G / 2), C.HitZone, "terrain")
	hz:SetAttribute("HitZone", true)
	slab(hzM, "LineBed", V3(lx0, -1, -G / 2), V3(lx1, 0, G / 2), C.HitZone, "terrain")
	-- the small step down to the lane, and the walls either side of the opening
	slab(hzM, "StepFace", V3(0, -Drop, -G / 2), V3(x1, -1, G / 2), C.Dirt, "terrain")
	if edgeZ > G / 2 then
		wall(hzM, "CliffLeft", t, -edgeZ, x1, -G / 2, -Drop, H, wallPal)
		wall(hzM, "CliffRight", t, G / 2, x1, edgeZ, -Drop, H, wallPal)
		slab(hzM, "WallFootLeft", V3(0, -Drop, -edgeZ), V3(t, 0, -G / 2), C.Dirt, "terrain")
		slab(hzM, "WallFootRight", V3(0, -Drop, G / 2), V3(t, 0, edgeZ), C.Dirt, "terrain")
	end
	local line = slab(hzM, "GlowLine", V3(lx0, 0, -G / 2), V3(lx1, 0.2, G / 2), C.Line, "smooth",
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false })
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Top
	light.Color = C.Line
	light.Brightness = 2
	light.Range = 8
	light.Angle = 120
	light.Parent = line
	hitZoneText(hz)
	Map.HitZone = hz

	----------------------------------------------------------------- biomes
	local biomesM = Builder.model("Biomes", root)
	local laneStart = t + S.LineWidth + HZ
	local laneEnd = laneStart + #S.Biomes * S.BiomeLength
	Map.Biomes = {}
	for i, name in S.Biomes do
		local pal = Colors.Biomes[name]
		local bx0 = laneStart + (i - 1) * S.BiomeLength
		local bx1 = bx0 + S.BiomeLength
		local bm = Builder.model(name, biomesM)
		local g = ground(bm, "Ground", bx0, -outerZ, bx1, outerZ, -Drop, pal.Ground)
		g:SetAttribute("Biome", name)
		g:SetAttribute("StartX", bx0)
		g:SetAttribute("EndX", bx1)
		local wp = { Dirt = pal.Dirt, Grass = pal.Grass }
		local rng = Random.new(1000 + i)
		local decor = Builder.model("Trees", bm)
		local walls = Builder.model("Terraces", bm)
		sign(bm, name, V3(bx0 + 70, -Drop + 46, 0), pal.Sign)

		-- terraces: segments with jittered heights, trees on top of each
		for _, side in { -1, 1 } do
			local zIn = W / 2
			for ti, tr in S.Terraces do
				local zOut = zIn + tr.Width
				local x = bx0
				local seg = 0
				while x < bx1 - 0.01 do
					seg += 1
					local len = math.min(S.TerraceSegment + rng:NextInteger(-12, 12), bx1 - x)
					local top = -Drop + tr.Height + rng:NextInteger(-S.TerraceJitter, S.TerraceJitter)
					local a0, a1 = side * zIn, side * zOut
					wall(walls, ("T%d_%s_%d"):format(ti, if side < 0 then "L" else "R", seg),
						x, math.min(a0, a1), x + len, math.max(a0, a1), -Drop, top, wp,
						-side * S.GrassOverhang)
					x += len
				end
				for k = 1, tr.Trees do
					local tx = bx0 + (k - 0.5) * S.BiomeLength / tr.Trees + rng:NextNumber(-12, 12)
					local tz = side * (zIn + tr.Width / 2 + rng:NextNumber(-2, 2))
					-- stand it on whichever segment is under it
					local hit = workspace:Raycast(V3(tx, 200, tz), V3(0, -400, 0), (function()
						local rp = RaycastParams.new()
						rp.FilterType = Enum.RaycastFilterType.Include
						rp.FilterDescendantsInstances = { walls }
						return rp
					end)())
					local ty = if hit then hit.Position.Y else -Drop + tr.Height
					local cf = CFrame.new(tx, ty, tz) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
					Trees.build(name, decor, cf, pal, rng)
				end
				zIn = zOut
			end
			local zb = W / 2 + terraceWidth
			wall(walls, "Back" .. (if side < 0 then "L" else "R"), bx0, math.min(side * zb, side * outerZ), bx1,
				math.max(side * zb, side * outerZ), -Drop, -Drop + S.BackWallHeight, wp)
		end

		-- lane floor: trees near the walls, the centre clear for the ragdoll
		local n = S.TreesPerBiome
		for k = 1, n do
			local x = bx0 + 14 + (k - 0.5) * (S.BiomeLength - 28) / n + rng:NextNumber(-6, 6)
			local side = if k % 2 == 0 then 1 else -1
			local z = side * rng:NextNumber(S.ClearPath + 10, W / 2 - 8)
			local cf = CFrame.new(x, -Drop, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			Trees.build(name, decor, cf, pal, rng)
		end
		local deco = Builder.model("Decor", bm)
		for k = 1, S.Bushes do
			local x = bx0 + rng:NextNumber(6, S.BiomeLength - 6)
			local side = if k % 2 == 0 then 1 else -1
			local z = side * rng:NextNumber(S.ClearPath, W / 2 - 3)
			bush(deco, V3(x, -Drop, z), rng:NextNumber(4, 7), pal.Leaves[rng:NextInteger(1, #pal.Leaves)], rng:NextNumber(0, math.pi))
		end
		for k = 1, S.Flowers do
			local x = bx0 + rng:NextNumber(4, S.BiomeLength - 4)
			local side = if k % 2 == 0 then 1 else -1
			local z = side * rng:NextNumber(S.ClearPath - 6, W / 2 - 2)
			local heads = Colors.Flowers
			flower(deco, V3(x, -Drop, z), pal.Grass, heads[rng:NextInteger(1, #heads)])
		end
		Map.Biomes[name] = { Model = bm, Ground = g, StartX = bx0, EndX = bx1 }
	end
	wall(biomesM, "EndWall", laneEnd, -outerZ, laneEnd + t, outerZ, -Drop, -Drop + S.BackWallHeight, wallPal)

	Map.Model = root
	return root
end

return Map

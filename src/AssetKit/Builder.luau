--[[
	Builder: low-level helpers for the studded blocky style.

	All parts are anchored matte SmoothPlastic in one flat colour, with QM's stud
	texture on every face ("studs"), an Inlet top ("inlet"), or no detail ("smooth"). Positions are given in the local
	space of an origin CFrame, so every asset can be built at any spot and rotation.
]]

local Palette = require(script.Parent.Palette)

local Builder = {}

-- The grid texture laid over every studded face. It starts as the settings in
-- Palette.Baseplate and is replaced by the place's own Baseplate texture when
-- one exists (Builder.useGridFrom), so blocks get the same native checker grid.
Builder.Grid = {
	Texture = Palette.Baseplate.Texture,
	StudsPerTileU = Palette.Baseplate.StudsPerTile,
	StudsPerTileV = Palette.Baseplate.StudsPerTile,
	Transparency = Palette.Baseplate.TextureTransparency,
	Color3 = Palette.Baseplate.TextureColor,
}

function Builder.useGridFrom(tex: Texture)
	Builder.Grid = {
		Texture = tex.Texture,
		StudsPerTileU = tex.StudsPerTileU,
		StudsPerTileV = tex.StudsPerTileV,
		Transparency = if tex.Transparency >= 1 then Palette.Baseplate.TextureTransparency else tex.Transparency,
		Color3 = tex.Color3,
	}
end

-- QM's L-stud texture (Figma stud tile, same asset FightToStealAnEgg uses for
-- its HUD). Mostly transparent, so the part's own flat colour shows through.
-- One tile is 4x4 studs.
Builder.Studs = {
	Texture = "rbxassetid://100359261064701",
	StudsPerTile = 4,
	-- softens the L shadow so it reads like the reference instead of popping
	Transparency = 0.35,
}

local NORMALS = { Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Front, Enum.NormalId.Back }

function Builder.addGrid(p: BasePart)
	local g = Builder.Grid
	for _, face in NORMALS do
		local t = Instance.new("Texture")
		-- unique names: Rojo can drop siblings that share a name when it syncs
		t.Name = "Grid" .. face.Name
		t.Face = face
		t.Texture = g.Texture
		t.StudsPerTileU = g.StudsPerTileU
		t.StudsPerTileV = g.StudsPerTileV
		t.Transparency = g.Transparency
		t.Color3 = g.Color3
		t.Parent = p
	end
end

-- Light-reactive studs: a MaterialVariant whose normal map (assets/studs, made
-- by tools/make_stud_maps.py) gives bright rims in sun and flat studs in shadow.
-- Decals can't react to light. Fill in the uploaded ids to switch every studded
-- part over; until then the decal is used.
Builder.StudMaterial = {
	Name = "AssetKitStuds",
	ColorMap = "", -- rbxassetid of assets/studs/stud_color.png
	NormalMap = "", -- rbxassetid of assets/studs/stud_normal.png
	StudsPerTile = 4,
}

local function studVariant(): string?
	local m = Builder.StudMaterial
	if m.ColorMap == "" or m.NormalMap == "" then
		return nil
	end
	local ms = game:GetService("MaterialService")
	if not ms:FindFirstChild(m.Name) then
		local v = Instance.new("MaterialVariant")
		v.Name = m.Name
		v.BaseMaterial = Enum.Material.SmoothPlastic
		v.ColorMap = m.ColorMap
		v.NormalMap = m.NormalMap
		v.StudsPerTile = m.StudsPerTile
		v.Parent = ms
	end
	return m.Name
end

function Builder.addStuds(p: BasePart)
	local variant = studVariant()
	if variant then
		p.Material = Enum.Material.SmoothPlastic
		p.MaterialVariant = variant
		return
	end
	local st = Builder.Studs
	for _, face in NORMALS do
		local t = Instance.new("Texture")
		t.Name = "Studs" .. face.Name
		t.Face = face
		t.Texture = st.Texture
		t.StudsPerTileU = st.StudsPerTile
		t.StudsPerTileV = st.StudsPerTile
		t.Transparency = st.Transparency
		-- white keeps the tile's rim highlight (QM wants it in sunlight; the
		-- engine's lighting dims it in shadow). Transparency keeps it from glowing.
		t.Color3 = Color3.new(1, 1, 1)
		t.Parent = p
	end
end

local FACES = { "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface" }

-- "terrain": studs plus the native baseplate grid (walls, cliffs)
-- "studs": studs only, flat colour (trees, bushes, small obstacles)
export type Style = "terrain" | "studs" | "inlet" | "smooth"

-- f > 0 lightens towards white, f < 0 darkens towards black.
function Builder.shade(c: Color3, f: number): Color3
	if f >= 0 then
		return c:Lerp(Color3.new(1, 1, 1), f)
	end
	return c:Lerp(Color3.new(0, 0, 0), -f)
end

function Builder.jitter(c: Color3, rng: Random, amount: number): Color3
	return Builder.shade(c, (rng:NextNumber() * 2 - 1) * amount)
end

function Builder.pick(list: { any }, rng: Random): any
	return list[rng:NextInteger(1, #list)]
end

function Builder.model(name: string, parent: Instance?, pivot: CFrame?): Model
	local m = Instance.new("Model")
	m.Name = name
	if pivot then
		m.WorldPivot = pivot
	end
	m.Parent = parent
	return m
end

function Builder.applyStyle(p: BasePart, style: Style?)
	style = style or "studs"
	-- studs come from QM's stud texture, not Roblox's SurfaceType.Studs
	for _, face in FACES do
		(p :: any)[face] = Enum.SurfaceType.Smooth
	end
	if style == "inlet" then
		p.TopSurface = Enum.SurfaceType.Inlet
	end
	-- obstacles are flat colour with studs only (QM): no grid texture, no checker.
	if style == "studs" or style == "terrain" then
		Builder.addStuds(p)
	end
	if style == "terrain" then
		-- walls and cliffs also carry the native baseplate grid
		Builder.addGrid(p)
	end
end

export type PartOpts = {
	class: string?,
	name: string?,
	material: Enum.Material?,
	canCollide: boolean?,
	castShadow: boolean?,
	transparency: number?,
}

-- Raw part at a world CFrame.
function Builder.part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, style: Style?, opts: PartOpts?): BasePart
	local o: PartOpts = opts or {}
	local p = Instance.new(o.class or "Part") :: BasePart
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	-- matte everywhere: flat SmoothPlastic with no reflectance
	p.Material = o.material or Enum.Material.SmoothPlastic
	p.Reflectance = 0
	Builder.applyStyle(p, style)
	p.CanCollide = o.canCollide ~= false
	p.CastShadow = o.castShadow ~= false
	if o.transparency then
		p.Transparency = o.transparency
	end
	-- unique sibling names keep Rojo syncs reliable
	p.Name = o.name or ("Block" .. (#parent:GetChildren() + 1))
	p.Parent = parent
	return p
end

-- Part centred at a local position relative to origin.
function Builder.box(parent: Instance, origin: CFrame, center: Vector3, size: Vector3, color: Color3, style: Style?, opts: PartOpts?): BasePart
	return Builder.part(parent, size, origin * CFrame.new(center), color, style, opts)
end

-- Part whose bottom face sits at local y = bottom.
function Builder.block(parent: Instance, origin: CFrame, x: number, bottom: number, z: number, size: Vector3, color: Color3, style: Style?, opts: PartOpts?): BasePart
	return Builder.box(parent, origin, Vector3.new(x, bottom + size.Y / 2, z), size, color, style, opts)
end

-- The texture the default Studio baseplate uses, applied to the top face.
function Builder.baseplateTexture(p: BasePart, settings)
	local t = Instance.new("Texture")
	t.Name = "BaseplateGrid"
	t.Face = Enum.NormalId.Top
	t.Texture = settings.Texture
	t.StudsPerTileU = settings.StudsPerTile
	t.StudsPerTileV = settings.StudsPerTile
	t.Transparency = settings.TextureTransparency
	t.Color3 = settings.TextureColor
	t.Parent = p
	return t
end

-- Floating name tag used by the showcase.
function Builder.label(adornee: Instance, text: string, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ShowcaseLabel"
	gui.Size = UDim2.fromOffset(220, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 160
	gui.Adornee = adornee
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne
	tl.TextScaled = true
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0
	tl.Text = text
	tl.Parent = gui
	gui.Parent = adornee
	return gui
end

return Builder

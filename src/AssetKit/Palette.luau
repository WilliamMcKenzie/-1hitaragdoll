--[[
	Palette: one colour set per biome.

	Every generator in Kit reads colours from a palette table, so a new biome is
	mostly a new entry here plus a list of assets in its own module.
]]

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local Palette = {}

-- Fallback settings for the native baseplate look. Normally the ground is a
-- clone of the place's own Workspace.Baseplate, so these are not used.
Palette.Baseplate = {
	Texture = "rbxassetid://6372755229", -- only used if the place has no Baseplate to clone
	StudsPerTile = 8,
	TextureTransparency = 0.8,
	TextureColor = rgb(0, 0, 0),
	Thickness = 16,
}

-- Base / spawn area: olive yellow-green ground, yellow-green grass, purple-grey dirt.
Palette.Base = {
	Name = "Base",
	Ground = rgb(196, 201, 76),

	Grass = rgb(201, 207, 72),
	Dirt = rgb(124, 100, 110),

	Trunk = rgb(112, 92, 122),
	Leaves = { rgb(201, 207, 72), rgb(186, 196, 60), rgb(214, 219, 98), rgb(142, 212, 92) },

	Path = rgb(236, 196, 84),
	PathTrim = rgb(214, 206, 232),
}

-- Biome 1, Meadow: bright green grass, mauve-brown dirt cliffs, purple trunks.
Palette.Meadow = {
	Name = "Meadow",
	Ground = rgb(126, 204, 92),

	Grass = rgb(110, 196, 74),
	Dirt = rgb(144, 112, 118),

	Trunk = rgb(110, 88, 114),
	Leaves = { rgb(142, 212, 92), rgb(126, 200, 80), rgb(158, 220, 104) },

	Path = rgb(236, 196, 84),
	PathTrim = rgb(214, 206, 232),
}

return Palette

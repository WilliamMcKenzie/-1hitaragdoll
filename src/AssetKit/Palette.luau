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
	Ground = rgb(186, 189, 76),

	Grass = rgb(191, 195, 72),
	Dirt = rgb(126, 100, 110),

	Trunk = rgb(129, 105, 133),
	Leaves = { rgb(191, 195, 72), rgb(177, 184, 60), rgb(203, 206, 98), rgb(83, 148, 79) },

	Path = rgb(236, 196, 84),
	PathTrim = rgb(214, 206, 232),
}

-- Biome 1, Meadow: bright green grass, mauve-brown dirt cliffs, purple trunks.
Palette.Meadow = {
	Name = "Meadow",
	Ground = rgb(121, 183, 95),

	Grass = rgb(116, 178, 88),
	Dirt = rgb(132, 104, 115),

	Trunk = rgb(129, 105, 133),
	Leaves = { rgb(83, 148, 79), rgb(73, 140, 69), rgb(92, 154, 89) },

	Path = rgb(236, 196, 84),
	PathTrim = rgb(214, 206, 232),
}

return Palette

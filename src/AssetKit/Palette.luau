--[[
	Palette: one colour set per biome.

	Every generator in Kit reads colours from a palette table, so a new biome is
	mostly a new entry here plus a list of assets in its own module.
]]

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local Palette = {}

-- Settings for the native Roblox baseplate look used as ground in every biome.
Palette.Baseplate = {
	Texture = "rbxassetid://6372755229", -- the texture the default Studio baseplate uses
	StudsPerTile = 8,
	TextureTransparency = 0.8,
	TextureColor = rgb(0, 0, 0),
	Thickness = 16,
}

-- Base / spawn area: olive yellow-green ground, mauve inlet plaza, dark navy trim.
Palette.Base = {
	Name = "Base",
	Ground = rgb(196, 201, 76),

	Plaza = rgb(186, 156, 176),
	PlazaAlt = rgb(174, 144, 165),
	Trim = rgb(43, 45, 69),

	Grass = rgb(201, 207, 72),
	GrassAlt = rgb(186, 194, 60),
	Dirt = rgb(124, 100, 124),
	DirtAlt = rgb(110, 88, 112),

	Trunk = rgb(112, 92, 122),
	Leaves = { rgb(201, 207, 72), rgb(186, 196, 60), rgb(214, 219, 98) },

	Tuft = rgb(176, 200, 74),
	Rock = rgb(152, 140, 214), -- lavender blocks
	RockAlt = rgb(170, 160, 228),
	Flowers = { rgb(255, 120, 150), rgb(255, 255, 255), rgb(255, 214, 90) },

	PadEgg = rgb(255, 92, 112),
	PadUpgrade = rgb(255, 214, 64),
	PadRebirth = rgb(120, 200, 255),
}

-- Biome 1, Meadow: bright green grass, mauve-brown dirt cliffs, purple trunks.
Palette.Meadow = {
	Name = "Meadow",
	Ground = rgb(126, 204, 92),

	Plaza = rgb(160, 128, 132),
	PlazaAlt = rgb(148, 116, 122),
	Trim = rgb(48, 44, 64),

	Grass = rgb(110, 196, 74),
	GrassAlt = rgb(98, 184, 66),
	Dirt = rgb(144, 112, 118),
	DirtAlt = rgb(128, 98, 106),

	Trunk = rgb(110, 88, 114),
	Leaves = { rgb(142, 212, 92), rgb(126, 200, 80), rgb(158, 220, 104) },

	Tuft = rgb(104, 190, 70),
	Rock = rgb(150, 150, 166),
	RockAlt = rgb(170, 170, 184),
	Flowers = { rgb(255, 110, 130), rgb(255, 255, 255), rgb(255, 220, 80), rgb(170, 140, 255) },

	PadEgg = rgb(255, 92, 112),
	PadUpgrade = rgb(255, 214, 64),
	PadRebirth = rgb(120, 200, 255),
}

return Palette

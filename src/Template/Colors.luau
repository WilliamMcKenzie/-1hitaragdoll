--[[
	Colors: every colour in the template is fully saturated (QM: "top right of
	the colour picker square, only the hue changes").

	UI colours are hue(h): saturation 1, value 1.
	World colours keep saturation 1 and only lower the value where a material
	must read darker than its neighbours (dirt, trunks, leaves against grass).
	Change a value here to recolour the whole map.
]]

local Colors = {}

function Colors.hue(h: number, v: number?): Color3
	return Color3.fromHSV((h % 360) / 360, 1, v or 1)
end

local hue = Colors.hue

-- Spawn area and the walls shared by every biome
Colors.Map = {
	SpawnGround = hue(95, 0.85),
	Dirt = hue(22, 0.55),
	Grass = hue(100, 0.8),
	HitZone = hue(50, 1),
	Chevron = hue(50, 1),
	Line = Color3.new(1, 1, 1), -- the glowing edge of the hit zone
}

-- One entry per biome, in the order they run out from the hit zone.
Colors.Biomes = {
	Forest = {
		Ground = hue(115, 0.75),
		Dirt = hue(22, 0.5),
		Grass = hue(115, 0.65),
		Trunk = hue(20, 0.45),
		Leaves = { hue(125, 0.6), hue(110, 0.7), hue(135, 0.52) },
		Sign = hue(120, 1),
	},
	Savanna = {
		Ground = hue(45, 0.9),
		Dirt = hue(25, 0.6),
		Grass = hue(55, 0.85),
		Trunk = hue(22, 0.42),
		Leaves = { hue(85, 0.62), hue(75, 0.68), hue(95, 0.55) },
		Sign = hue(40, 1),
	},
}

return Colors

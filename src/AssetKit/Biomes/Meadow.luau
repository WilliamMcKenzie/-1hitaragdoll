--[[
	Biome 1: Meadow asset set.
	Each entry: name, footprint (studs, for the showcase layout), build(parent, cf).
]]

local Kit = require(script.Parent.Parent.Kit)
local Palette = require(script.Parent.Parent.Palette)

local P = Palette.Meadow

return {
	palette = P,
	gateText = "MEADOW",
	assets = {
		{ name = "BiomeGate", footprint = 44, placeAtBorder = true, build = function(parent, cf)
			return Kit.gate(parent, cf, P, { name = "BiomeGate", text = "MEADOW" })
		end },
		{ name = "TerraceCliffSmall", footprint = 30, build = function(parent, cf)
			return Kit.terrace(parent, cf, P, { name = "TerraceCliffSmall", cellsX = 7, cellsZ = 6, tiers = 2, seed = 31 })
		end },
		{ name = "TerraceCliffMedium", footprint = 42, build = function(parent, cf)
			return Kit.terrace(parent, cf, P, { name = "TerraceCliffMedium", cellsX = 10, cellsZ = 9, tiers = 3, seed = 32 })
		end },
		{ name = "TerraceCliffLarge", footprint = 58, build = function(parent, cf)
			return Kit.terrace(parent, cf, P, { name = "TerraceCliffLarge", cellsX = 15, cellsZ = 13, tiers = 4, seed = 33 })
		end },
		{ name = "BoundaryWall", footprint = 34, build = function(parent, cf)
			return Kit.wall(parent, cf, P, { name = "BoundaryWall", length = 32, tiers = 3 })
		end },
		{ name = "TreeTall", footprint = 32, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeTall", height = 32, trunk = 3, canopy = 22, branches = 3, seed = 41 })
		end },
		{ name = "TreeRound", footprint = 26, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeRound", height = 20, trunk = 3, canopy = 18, branches = 2, seed = 42 })
		end },
		{ name = "TreeSmall", footprint = 16, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeSmall", height = 12, trunk = 2, canopy = 11, branches = 1, seed = 43 })
		end },
		{ name = "Bush", footprint = 10, build = function(parent, cf)
			return Kit.bush(parent, cf, P, { name = "Bush", width = 7, seed = 51 })
		end },
		{ name = "Rock", footprint = 10, build = function(parent, cf)
			return Kit.rock(parent, cf, P, { name = "Rock", size = 6, seed = 61 })
		end },
		{ name = "RockSmall", footprint = 6, build = function(parent, cf)
			return Kit.rock(parent, cf, P, { name = "RockSmall", size = 3, seed = 62 })
		end },
		{ name = "FlowerPatch", footprint = 12, build = function(parent, cf)
			return Kit.flowerPatch(parent, cf, P, { name = "FlowerPatch", seed = 71 })
		end },
		{ name = "GrassTuft", footprint = 6, build = function(parent, cf)
			return Kit.tuft(parent, cf, P, { name = "GrassTuft", seed = 4 })
		end },
	},
}

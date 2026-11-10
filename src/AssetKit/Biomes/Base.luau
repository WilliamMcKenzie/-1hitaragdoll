--[[
	Base / spawn area asset set.
	Each entry: name, footprint (studs, for the showcase layout), build(parent, cf).
]]

local Kit = require(script.Parent.Parent.Kit)
local Palette = require(script.Parent.Parent.Palette)

local P = Palette.Base

return {
	palette = P,
	gateText = "SPAWN",
	assets = {
		{ name = "SpawnPlaza", footprint = 50, build = function(parent, cf)
			return Kit.plaza(parent, cf, P, { name = "SpawnPlaza", sizeX = 48, sizeZ = 48, spawn = true })
		end },
		{ name = "Ramp", footprint = 30, build = function(parent, cf)
			return Kit.ramp(parent, cf, P, { name = "Ramp" })
		end },
		{ name = "EggPad", footprint = 16, build = function(parent, cf)
			return Kit.pad(parent, cf, P, { name = "EggPad", color = P.PadEgg })
		end },
		{ name = "UpgradePad", footprint = 16, build = function(parent, cf)
			return Kit.pad(parent, cf, P, { name = "UpgradePad", color = P.PadUpgrade })
		end },
		{ name = "RebirthPad", footprint = 16, build = function(parent, cf)
			return Kit.pad(parent, cf, P, { name = "RebirthPad", color = P.PadRebirth })
		end },
		{ name = "DisplayStand", footprint = 10, build = function(parent, cf)
			return Kit.stand(parent, cf, P, { name = "DisplayStand" })
		end },
		{ name = "TerraceCliffSmall", footprint = 26, build = function(parent, cf)
			return Kit.terrace(parent, cf, P, { name = "TerraceCliffSmall", cellsX = 6, cellsZ = 6, tiers = 2, tierHeight = 8, cap = 4, bands = true, seed = 11 })
		end },
		{ name = "TerraceCliffLarge", footprint = 44, build = function(parent, cf)
			return Kit.terrace(parent, cf, P, { name = "TerraceCliffLarge", cellsX = 10, cellsZ = 10, tiers = 4, tierHeight = 8, cap = 4, bands = true, seed = 12 })
		end },
		{ name = "BoundaryWall", footprint = 34, build = function(parent, cf)
			return Kit.wall(parent, cf, P, { name = "BoundaryWall", length = 32, tiers = 3, tierHeight = 8, bands = true })
		end },
		{ name = "Tree", footprint = 26, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "Tree", height = 24, canopy = 18, branches = 2, seed = 21 })
		end },
		{ name = "TreeSmall", footprint = 16, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeSmall", height = 14, trunk = 2, canopy = 11, branches = 1, seed = 22 })
		end },
		{ name = "SteppedBush", footprint = 10, build = function(parent, cf)
			return Kit.steppedBush(parent, cf, P, { name = "SteppedBush" })
		end },
		{ name = "GrassTuft", footprint = 6, build = function(parent, cf)
			return Kit.tuft(parent, cf, P, { name = "GrassTuft", seed = 3 })
		end },
		{ name = "CrystalBlock", footprint = 8, build = function(parent, cf)
			return Kit.crystalBlock(parent, cf, P, { name = "CrystalBlock" })
		end },
	},
}

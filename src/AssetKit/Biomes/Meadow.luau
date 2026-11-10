--[[
	Biome 1, Meadow: ground colour, trees and walls.
	Each entry: name, footprint (studs, for the showcase layout), build(parent, cf).
]]

local Kit = require(script.Parent.Parent.Kit)
local Palette = require(script.Parent.Parent.Palette)

local P = Palette.Meadow

return {
	palette = P,
	assets = {
		{ name = "TreeTall", footprint = 40, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeTall", height = 34, canopy = 30, branches = 2, seed = 41 })
		end },
		{ name = "TreeRound", footprint = 34, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeRound", height = 24, canopy = 24, branches = 2, seed = 42 })
		end },
		{ name = "TreeSmall", footprint = 22, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeSmall", height = 14, canopy = 16, branches = 1, seed = 43 })
		end },
		{ name = "Wall", footprint = 34, build = function(parent, cf)
			return Kit.wall(parent, cf, P, { name = "Wall", length = 32, height = 16 })
		end },
		{ name = "WallTall", footprint = 34, build = function(parent, cf)
			return Kit.wall(parent, cf, P, { name = "WallTall", length = 32, height = 36 })
		end },
		{ name = "WallCorner", footprint = 22, build = function(parent, cf)
			return Kit.wallCorner(parent, cf, P, { name = "WallCorner", length = 16, height = 24 })
		end },
	},
}

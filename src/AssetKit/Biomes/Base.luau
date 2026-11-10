--[[
	Base / spawn area: ground colour, trees and walls.
	Each entry: name, footprint (studs, for the showcase layout), build(parent, cf).
]]

local Kit = require(script.Parent.Parent.Kit)
local Palette = require(script.Parent.Parent.Palette)

local P = Palette.Base

return {
	palette = P,
	assets = {
		{ name = "Tree", footprint = 34, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "Tree", height = 26, canopy = 18, branches = 2, seed = 21 })
		end },
		{ name = "TreeTall", footprint = 38, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeTall", height = 34, canopy = 20, branches = 3, seed = 23 })
		end },
		{ name = "TreeSmall", footprint = 22, build = function(parent, cf)
			return Kit.tree(parent, cf, P, { name = "TreeSmall", height = 15, trunk = 2, canopy = 11, branches = 1, seed = 22 })
		end },
		{ name = "Wall", footprint = 34, build = function(parent, cf)
			return Kit.wall(parent, cf, P, { name = "Wall", length = 32, height = 16 })
		end },
		{ name = "WallStriped", footprint = 34, build = function(parent, cf)
			return Kit.wall(parent, cf, P, { name = "WallStriped", length = 32, height = 36, bands = true, bandEvery = 12 })
		end },
		{ name = "WallCorner", footprint = 22, build = function(parent, cf)
			return Kit.wallCorner(parent, cf, P, { name = "WallCorner", length = 16, height = 24, bands = true, bandEvery = 12 })
		end },
	},
}

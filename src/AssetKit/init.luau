--[[
	AssetKit: native-baseplate ground, studded walls and voxel trees for +1 Hit a Ragdoll.

	    local AssetKit = require(game.ServerStorage.AssetKit)
	    AssetKit.buildShowcase()                -- every biome, for review
	    AssetKit.Kit.tree(workspace, CFrame.new(0, 0, 0), AssetKit.Palette.Meadow, { seed = 5 })
]]

local AssetKit = {}

AssetKit.Palette = require(script.Palette)
AssetKit.Builder = require(script.Builder)
AssetKit.Kit = require(script.Kit)
AssetKit.Showcase = require(script.Showcase)
AssetKit.Biomes = {
	require(script.Biomes.Base),
	require(script.Biomes.Meadow),
}

function AssetKit.buildShowcase()
	return AssetKit.Showcase.build(AssetKit.Biomes)
end

return AssetKit

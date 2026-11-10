# +1 Hit a Ragdoll

## AssetKit (studded blocky art kit)

`src/AssetKit` generates every environment asset in code, so a new biome is a new
palette plus an asset list.

- Ground: the native Roblox baseplate (plastic slab + the default baseplate grid
  texture), recoloured per biome.
- Everything else: anchored Plastic parts with Studs on every face (Inlet tops on
  plazas and pads), with alternating shades per block.

| File | What it holds |
| --- | --- |
| `Palette.luau` | Colours per biome, baseplate texture settings |
| `Builder.luau` | Part / block / label helpers |
| `Kit.luau` | Generators: ground, terrace cliff, wall, tree, bush, tuft, flower, rock, plaza, ramp, pad, stand, crystal block, biome gate |
| `Biomes/Base.luau`, `Biomes/Meadow.luau` | The asset list for each biome |
| `Showcase.luau` | Lays every biome out in Workspace for review |

### See it in Studio

1. Open any Baseplate place.
2. Open View > Command Bar, paste all of `build/BuildAssetShowcase.lua`, press Enter.
3. Press Play. You spawn on the Base plaza; the Meadow is through the gate to the north.

The showcase lands in `Workspace.AssetShowcase` with a label over each asset, and a
clean template of every asset goes to `ServerStorage.AssetKitModels/<Biome>`.
Running it again replaces both. Ctrl+Z undoes it.

With Rojo, `default.project.json` syncs the kit to `ServerStorage.AssetKit`; then
`require(game.ServerStorage.AssetKit).buildShowcase()` in the command bar does the same.

### Rebuild the paste script / preview offline

```
python3 tools/bundle.py                      # src -> build/BuildAssetShowcase.lua
# optional rough render without Studio (needs the luau CLI, node and playwright):
(cat tools/preview/mock.luau; grep -v '^print("\[AssetKit\]' build/BuildAssetShowcase.lua; echo 'dump()') > /tmp/run.luau
luau /tmp/run.luau > /tmp/parts.json
node tools/preview/shoot.js /tmp/parts.json /tmp
```

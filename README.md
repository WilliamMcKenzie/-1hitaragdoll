# +1 Hit a Ragdoll

## AssetKit (ground, walls, trees)

`src/AssetKit` builds the environment in code, so a new biome is a new palette
plus an asset list.

- Ground: a clone of the place's own default `Workspace.Baseplate` (same part,
  same native texture) with only its colour changed per biome.
- Walls and trees: anchored Plastic parts with Studs on every face, in
  alternating shades per 4-stud block.

| File | What it holds |
| --- | --- |
| `Palette.luau` | Colours per biome |
| `Builder.luau` | Part / block / label helpers |
| `Kit.luau` | Generators: ground, wall, wall corner, tree |
| `Biomes/Base.luau`, `Biomes/Meadow.luau` | The trees and walls for each biome |
| `Showcase.luau` | Lays every biome out in Workspace for review |

### See it in Studio

1. Open any Baseplate place.
2. Open View > Command Bar, paste all of `build/BuildAssetShowcase.lua`, press Enter.
3. Press Play. You spawn on the Base plate; the Meadow plate is next to it to the north.

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

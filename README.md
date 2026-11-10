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

Rojo (live sync):

1. Open a fresh Baseplate place in Studio.
2. In the repo run `rojo serve`, then press Connect in the Rojo plugin.

`default.project.json` recolours the place's own `Workspace.Baseplate` for the
Base biome and syncs `Workspace.AssetShowcase` plus `ServerStorage.AssetKit` /
`ServerStorage.AssetKitModels`. Anything else in the place is left alone.

No Rojo: open `build/AssetShowcase.rbxl` (built from `place.project.json`), or
paste `build/BuildAssetShowcase.lua` into the command bar of a Baseplate place.

After changing `src/AssetKit`, regenerate the synced models and place file:

```
python3 tools/rojo/export.py      # needs the luau CLI; writes rojo/*.model.json
rojo build place.project.json -o build/AssetShowcase.rbxl
```

### Rebuild the paste script / preview offline

```
python3 tools/bundle.py                      # src -> build/BuildAssetShowcase.lua
# optional rough render without Studio (needs the luau CLI, node and playwright):
(cat tools/preview/mock.luau; grep -v '^print("\[AssetKit\]' build/BuildAssetShowcase.lua; echo 'dump()') > /tmp/run.luau
luau /tmp/run.luau > /tmp/parts.json
node tools/preview/shoot.js /tmp/parts.json /tmp
```

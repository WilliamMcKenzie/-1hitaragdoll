--[[
	Showcase: lays every biome out in Workspace for review, and stores a clean
	template copy of each asset in ServerStorage.AssetKitModels/<Biome>.

	Each biome sits on its own copy of the place's default Baseplate, recoloured.
	The Base plate is centred on the origin (where the default SpawnLocation is),
	and each next biome follows along -Z. Running it again replaces the showcase.
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local Builder = require(script.Parent.Builder)
local Kit = require(script.Parent.Kit)
local Scene = require(script.Parent.Scene)

local Showcase = {}

Showcase.PlateSize = 256
Showcase.Margin = 24
Showcase.Spacing = 12
Showcase.SceneGap = 64

local function labelAnchor(parent: Instance, model: Model, text: string)
	local cf, size = model:GetBoundingBox()
	local anchor = Builder.part(parent, Vector3.new(1, 1, 1), CFrame.new(cf.Position.X, cf.Position.Y + size.Y / 2 + 3, cf.Position.Z), Color3.new(1, 1, 1), "smooth", {
		name = text .. "Label",
		canCollide = false,
		castShadow = false,
		transparency = 1,
	})
	anchor.CanQuery = false
	anchor.CanTouch = false
	Builder.label(anchor, text, 0)
end

local function layoutBiome(biome, plateCenter: CFrame, showFolder: Instance, storeFolder: Instance, labels: Instance)
	local half = Showcase.PlateSize / 2 - Showcase.Margin
	-- Base plate: keep the middle (spawn) clear by starting rows past it.
	local x, z = -half, -16
	local rowDepth = 0
	for _, asset in biome.assets do
		local fp = asset.footprint
		if x + fp > half then
			x = -half
			z -= rowDepth + Showcase.Spacing
			rowDepth = 0
		end
		local cf = plateCenter * CFrame.new(x + fp / 2, 0, z - fp / 2)
		x += fp + Showcase.Spacing
		rowDepth = math.max(rowDepth, fp)

		local model = asset.build(showFolder, cf)
		labelAnchor(labels, model, asset.name)

		local template = model:Clone()
		template:PivotTo(CFrame.new())
		template.Parent = storeFolder
	end
end

-- An earlier version of this script hid the template's Baseplate and SpawnLocation.
local function restoreTemplate()
	local spawn = Workspace:FindFirstChild("SpawnLocation")
	if spawn and spawn:IsA("SpawnLocation") then
		spawn.Enabled = true
		spawn.Transparency = 0
		spawn.CanCollide = true
		local decal = spawn:FindFirstChildOfClass("Decal")
		if decal then
			decal.Transparency = 0
		end
	end
end

function Showcase.build(biomes)
	local oldShow = Workspace:FindFirstChild("AssetShowcase")
	if oldShow then
		oldShow:Destroy()
	end
	local oldStore = ServerStorage:FindFirstChild("AssetKitModels")
	if oldStore then
		oldStore:Destroy()
	end
	restoreTemplate()

	-- Clone the place's own Baseplate before hiding it, so every biome's ground
	-- is the genuine article (same part, same texture), only recoloured.
	local native = Kit.nativeBaseplate()
	local source = native and native:Clone()
	if native then
		native.Transparency = 1
		native.CanCollide = false
		for _, tex in native:GetChildren() do
			if tex:IsA("Texture") then
				tex.Transparency = 1
			end
		end
	end

	local root = Instance.new("Folder")
	root.Name = "AssetShowcase"
	local store = Instance.new("Folder")
	store.Name = "AssetKitModels"

	for index, biome in biomes do
		local name = biome.palette.Name
		local center = CFrame.new(0, 0, -(index - 1) * Showcase.PlateSize)

		local biomeFolder = Instance.new("Folder")
		biomeFolder.Name = name
		biomeFolder.Parent = root
		local labels = Instance.new("Folder")
		labels.Name = "Labels"
		labels.Parent = biomeFolder
		local storeFolder = Instance.new("Folder")
		storeFolder.Name = name
		storeFolder.Parent = store

		Kit.ground(biomeFolder, center, biome.palette, { source = source, sizeX = Showcase.PlateSize, sizeZ = Showcase.PlateSize })
		Kit.ground(storeFolder, CFrame.new(), biome.palette, { source = source, name = "Baseplate" })

		layoutBiome(biome, center, biomeFolder, storeFolder, labels)

		-- a finished-looking area built only from this biome's kit, east of the showcase
		local sceneCenter = CFrame.new(Showcase.PlateSize + Showcase.SceneGap, 0, -(index - 1) * (Showcase.PlateSize + Showcase.SceneGap))
		Scene.build(biomeFolder, sceneCenter, biome.palette, { source = source, size = Showcase.PlateSize, seed = index * 11 })
	end

	root.Parent = Workspace
	store.Parent = ServerStorage
	return root
end

return Showcase

--[[
	Showcase: builds every biome's asset set in Workspace for review, and stores a
	clean template copy of each asset in ServerStorage.AssetKitModels/<Biome>.

	Biomes are laid out along -Z from the spawn: each sits on its own recoloured
	baseplate, and the next biome's gate stands on the border between them.
	Running it again replaces the previous showcase.
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local Builder = require(script.Parent.Builder)
local Kit = require(script.Parent.Kit)

local Showcase = {}

Showcase.PlateSize = 320
Showcase.Gap = 0
Showcase.Margin = 16
Showcase.Spacing = 10
Showcase.BorderReserve = 30 -- keeps the first row clear of the biome gate

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
	local x, z = -half, half - Showcase.BorderReserve -- rows start near the +Z edge, behind the gate
	local rowDepth = 0
	for _, asset in biome.assets do
		local fp = asset.footprint
		local cf
		if asset.placeAtBorder then
			cf = plateCenter * CFrame.new(0, 0, Showcase.PlateSize / 2)
		else
			if x + fp > half then
				x = -half
				z -= rowDepth + Showcase.Spacing
				rowDepth = 0
			end
			cf = plateCenter * CFrame.new(x + fp / 2, 0, z - fp / 2)
			x += fp + Showcase.Spacing
			rowDepth = math.max(rowDepth, fp)
		end
		local model = asset.build(showFolder, cf)
		labelAnchor(labels, model, asset.name)

		local template = model:Clone()
		template:PivotTo(CFrame.new())
		template.Parent = storeFolder
	end
end

function Showcase.build(biomes)
	local old = Workspace:FindFirstChild("AssetShowcase")
	if old then
		old:Destroy()
	end
	local oldStore = ServerStorage:FindFirstChild("AssetKitModels")
	if oldStore then
		oldStore:Destroy()
	end

	-- Our recoloured baseplates replace the template's grey one.
	local defaultBase = Workspace:FindFirstChild("Baseplate")
	if defaultBase and defaultBase:IsA("BasePart") then
		defaultBase.Transparency = 1
		defaultBase.CanCollide = false
		local tex = defaultBase:FindFirstChildOfClass("Texture")
		if tex then
			tex.Transparency = 1
		end
	end
	local defaultSpawn = Workspace:FindFirstChild("SpawnLocation")
	if defaultSpawn and defaultSpawn:IsA("SpawnLocation") then
		defaultSpawn.Enabled = false
		defaultSpawn.Transparency = 1
		defaultSpawn.CanCollide = false
		local decal = defaultSpawn:FindFirstChildOfClass("Decal")
		if decal then
			decal.Transparency = 1
		end
	end

	local root = Instance.new("Folder")
	root.Name = "AssetShowcase"
	local store = Instance.new("Folder")
	store.Name = "AssetKitModels"

	for index, biome in biomes do
		local name = biome.palette.Name
		local center = CFrame.new(0, 0, -(index - 1) * (Showcase.PlateSize + Showcase.Gap))

		local biomeFolder = Instance.new("Folder")
		biomeFolder.Name = name
		biomeFolder.Parent = root
		local labels = Instance.new("Folder")
		labels.Name = "Labels"
		labels.Parent = biomeFolder
		local storeFolder = Instance.new("Folder")
		storeFolder.Name = name
		storeFolder.Parent = store

		Kit.ground(biomeFolder, center, biome.palette, { sizeX = Showcase.PlateSize, sizeZ = Showcase.PlateSize })
		local groundTemplate = Kit.ground(storeFolder, CFrame.new(), biome.palette, { name = "Ground" })
		groundTemplate.Name = "Ground"

		layoutBiome(biome, center, biomeFolder, storeFolder, labels)
	end

	root.Parent = Workspace
	store.Parent = ServerStorage
	return root
end

return Showcase

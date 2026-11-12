--[[
	Sky: puts the free "Cartoon Sky" skybox (asset 10594688909) from the Creator Store into Lighting.

	Only the Sky instance is taken from the model, so no scripts come along.
	Sky.AssetId pins a specific asset; left nil, the first free model whose name
	has both "cartoon" and "sky" is used (the id is printed so it can be pinned).
]]

local InsertService = game:GetService("InsertService")
local LightingService = game:GetService("Lighting")

local Sky = {}

Sky.AssetId = 10594688909 :: number? -- "Cartoon Sky" (QM picked it, 2026-11-12)
Sky.Query = "Cartoon Sky"

function Sky.find(): (number?, string?)
	if Sky.AssetId then
		return Sky.AssetId, "pinned"
	end
	local ok, pages = pcall(function()
		return InsertService:GetFreeModels(Sky.Query, 0)
	end)
	if not ok or not pages or not pages[1] then
		return nil, nil
	end
	for _, r in pages[1].Results do
		local n = string.lower(r.Name)
		if string.find(n, "cartoon") and string.find(n, "sky") then
			return r.AssetId, r.Name .. " by " .. tostring(r.CreatorName)
		end
	end
	return nil, nil
end

function Sky.apply(): Sky?
	local id, label = Sky.find()
	if not id then
		warn("[Template] Cartoon Sky not found in the Creator Store; sky left as it was")
		return nil
	end
	local ok, objs = pcall(function()
		return game:GetObjects("rbxassetid://" .. id)
	end)
	if not ok or not objs then
		warn("[Template] could not load Cartoon Sky " .. tostring(id))
		return nil
	end
	local sky: Sky? = nil
	for _, o in objs do
		sky = if o:IsA("Sky") then o else o:FindFirstChildWhichIsA("Sky", true)
		if sky then
			break
		end
	end
	if not sky then
		warn("[Template] asset " .. tostring(id) .. " has no Sky in it")
		return nil
	end
	for _, old in LightingService:GetChildren() do
		if old:IsA("Sky") then
			old.Parent = nil
		end
	end
	sky.Name = "CartoonSky"
	sky.Parent = LightingService
	print(("[Template] sky: CartoonSky asset %d (%s)"):format(id, tostring(label)))
	return sky
end

return Sky

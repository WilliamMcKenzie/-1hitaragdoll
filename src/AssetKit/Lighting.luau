--[[
	Lighting: the bright, flat, low-contrast daylight look from the reference
	(crisp light shadows, no haze, no bloom, matte surfaces).
	Lighting.apply() sets the Lighting service and its post effects in place.
]]

local LightingService = game:GetService("Lighting")

local Lighting = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Tuned in Studio against docs/reference (Nov 10): neutral grey ambient, equal
-- indoor and outdoor (trunks under a crown use Ambient), no sky tint on surfaces
-- (EnvironmentDiffuseScale 0), exposure 0 so the flat sky reads as in the reference.
-- Shadowed ground comes out about 77% of the lit ground, as there.
Lighting.Settings = {
	Technology = Enum.Technology.ShadowMap,
	Brightness = 1.4,
	ClockTime = 13,
	GeographicLatitude = 41.7,
	Ambient = rgb(225, 225, 225),
	OutdoorAmbient = rgb(225, 225, 225),
	ColorShift_Top = rgb(0, 0, 0),
	ColorShift_Bottom = rgb(0, 0, 0),
	GlobalShadows = true,
	ShadowSoftness = 0.2,
	EnvironmentDiffuseScale = 0,
	EnvironmentSpecularScale = 0, -- matte: no environment reflections
	ExposureCompensation = 0,
	FogStart = 100000,
	FogEnd = 100000,
}

Lighting.ColorCorrection = { Brightness = 0, Contrast = 0.05, Saturation = 0, TintColor = rgb(255, 255, 255) }

-- Realistic Sky (Creator Store 4607457995), loaded at build time; the flat
-- sky colour is the fallback if the insert fails (e.g. no permission).
Lighting.SkyAsset = 4607457995
Lighting.SkyTexture = "rbxassetid://81588505365795"

local function loadRealisticSky(): Sky?
	local ok, objs = pcall(function()
		return game:GetObjects("rbxassetid://" .. Lighting.SkyAsset)
	end)
	if not ok or not objs then
		return nil
	end
	for _, o in objs do
		local s = if o:IsA("Sky") then o else o:FindFirstChildWhichIsA("Sky", true)
		if s then
			return s :: Sky
		end
	end
	return nil
end

local function child(className: string, name: string): Instance
	local c = LightingService:FindFirstChildOfClass(className)
	if not c then
		c = Instance.new(className)
		c.Name = name
		c.Parent = LightingService
	end
	return c
end

function Lighting.apply()
	for k, v in Lighting.Settings do
		pcall(function()
			(LightingService :: any)[k] = v
		end)
	end
	-- no haze, glow, god rays or blur: the reference reads clean and flat
	for _, c in LightingService:GetChildren() do
		if c:IsA("BloomEffect") or c:IsA("SunRaysEffect") or c:IsA("DepthOfFieldEffect") or c:IsA("BlurEffect") then
			c.Enabled = false
		elseif c:IsA("Atmosphere") then
			c.Density = 0
			c.Haze = 0
			c.Glare = 0
		end
	end
	local realistic = loadRealisticSky()
	if realistic then
		for _, old in LightingService:GetChildren() do
			if old:IsA("Sky") then
				old:Destroy()
			end
		end
		realistic.Name = "RealisticSky"
		realistic.Parent = LightingService
	else
		local sky = child("Sky", "Sky") :: Sky
		for _, face in { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" } do
			(sky :: any)[face] = Lighting.SkyTexture
		end
		sky.CelestialBodiesShown = false
		sky.StarCount = 0
	end
	local cc = child("ColorCorrectionEffect", "AssetKitColor") :: ColorCorrectionEffect
	for k, v in Lighting.ColorCorrection do
		(cc :: any)[k] = v
	end
	cc.Enabled = true
end

return Lighting

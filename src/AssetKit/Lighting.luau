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

-- House style from QM's other games (ShadowMap, flat sky, exposure 0.5,
-- contrast 0.05 / saturation 0.25), with shadows on because the reference has them.
Lighting.Settings = {
	Technology = Enum.Technology.ShadowMap,
	Brightness = 1,
	ClockTime = 13,
	GeographicLatitude = 41.7,
	Ambient = rgb(70, 70, 80),
	OutdoorAmbient = rgb(161, 163, 163),
	ColorShift_Top = rgb(0, 0, 0),
	ColorShift_Bottom = rgb(0, 0, 0),
	GlobalShadows = true,
	ShadowSoftness = 0.2,
	EnvironmentDiffuseScale = 0.4,
	EnvironmentSpecularScale = 0, -- matte: no environment reflections
	ExposureCompensation = 0.5,
	FogStart = 100000,
	FogEnd = 100000,
}

Lighting.ColorCorrection = { Brightness = 0, Contrast = 0.05, Saturation = 0.25, TintColor = rgb(255, 255, 255) }

-- one flat sky colour, no sun, moon or stars
Lighting.SkyTexture = "rbxassetid://81588505365795"

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
	local sky = child("Sky", "Sky") :: Sky
	for _, face in { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" } do
		(sky :: any)[face] = Lighting.SkyTexture
	end
	sky.CelestialBodiesShown = false
	sky.StarCount = 0
	local cc = child("ColorCorrectionEffect", "AssetKitColor") :: ColorCorrectionEffect
	for k, v in Lighting.ColorCorrection do
		(cc :: any)[k] = v
	end
	cc.Enabled = true
end

return Lighting

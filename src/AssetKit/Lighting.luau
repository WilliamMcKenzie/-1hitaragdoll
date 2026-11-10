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

Lighting.Settings = {
	Technology = Enum.Technology.ShadowMap,
	Brightness = 2.5,
	ClockTime = 14.5,
	GeographicLatitude = 20,
	Ambient = rgb(110, 110, 110),
	OutdoorAmbient = rgb(150, 150, 150),
	ColorShift_Top = rgb(0, 0, 0),
	ColorShift_Bottom = rgb(0, 0, 0),
	GlobalShadows = true,
	ShadowSoftness = 0.15,
	EnvironmentDiffuseScale = 0,
	EnvironmentSpecularScale = 0,
	ExposureCompensation = 0,
	FogEnd = 100000,
}

Lighting.ColorCorrection = { Brightness = 0, Contrast = 0.05, Saturation = 0.15, TintColor = rgb(255, 255, 255) }

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
	local cc = child("ColorCorrectionEffect", "AssetKitColor") :: ColorCorrectionEffect
	for k, v in Lighting.ColorCorrection do
		(cc :: any)[k] = v
	end
	cc.Enabled = true
end

return Lighting

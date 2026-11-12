--[[
	Template: the reusable map + HUD template.

	    Template.build()  -- lighting + Anime Sky, Workspace.Map, StarterGui.HUD,
	                      -- ReplicatedStorage.UITemplates and ReplicatedStorage.UIKit

	Map.Settings and Colors hold every size and colour; Trees holds the
	per-biome tree variants; UI holds the HUD element builders.
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Template = {}

Template.Colors = require(script.Colors)
Template.Trees = require(script.Trees)
Template.Map = require(script.Map)
Template.UI = require(script.UI)
Template.Sky = require(script.Sky)
Template.Lighting = require(script.Parent.Lighting)

-- Old showcase content and the original Baseplate move to ServerStorage so the
-- map has the place to itself (nothing is deleted).
local function tidy()
	local store = ServerStorage:FindFirstChild("TemplateSource")
	if not store then
		store = Instance.new("Folder")
		store.Name = "TemplateSource"
		store.Parent = ServerStorage
	end
	local bp = Workspace:FindFirstChild("Baseplate")
	if bp and not store:FindFirstChild("Baseplate") then
		bp.Parent = store
	end
	local show = Workspace:FindFirstChild("AssetShowcase")
	if show then
		show.Parent = store
	end
end

-- uiSource: the UI module's own source, so it can also live in the place as a
-- ModuleScript (the bundled command-bar script passes it in)
function Template.build(uiSource: string?)
	local L = Template.Lighting
	L.SkyAsset = nil
	L.ColorCorrection.Saturation = 0 -- colours are already fully saturated
	L.apply()
	Template.Sky.apply()

	Template.Map.build(Workspace)
	tidy()

	Template.UI.buildHUD(StarterGui)
	Template.UI.buildTemplates(ReplicatedStorage)
	if uiSource then
		local old = ReplicatedStorage:FindFirstChild("UIKit")
		if old then
			old.Parent = nil
		end
		local mod = Instance.new("ModuleScript")
		mod.Name = "UIKit"
		;(mod :: any).Source = uiSource
		mod.Parent = ReplicatedStorage
	end
end

return Template

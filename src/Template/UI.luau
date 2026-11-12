--[[
	UI: HUD element templates copied from QM's Figma ("UI Templating" page,
	file BWrUjODdJ2oWVUYsdkZxyt). Sizes below are the Figma pixel sizes; the
	HUD's AutoScale shrinks everything to the screen.

	Face style (every coloured element): flat fill, 12px corners, 3px outline
	black at 50%, a shade gradient over the bottom, the stud texture tiled on
	top. Text is FredokaOne, white, with a dark outline.

	    local UIKit = require(game.ReplicatedStorage.UIKit)
	    UIKit.rectButton({ Text = "Shop", Icon = UIKit.Assets.Shop, Color = UIKit.Colors.Red })
	    UIKit.squareButton({ Icon = UIKit.Assets.Aura, Color = UIKit.Colors.Purple })
	    UIKit.counter({ Icon = UIKit.Assets.Trophy, Text = "5K", TextColor = UIKit.Colors.Gold })
	    local bar = UIKit.progress({ Level = 80, Value = "1.2k/3.05k", Fill = 0.4 })
	    UIKit.buyButton({ Text = "+10M", Color = UIKit.Colors.Yellow, Shade = UIKit.Colors.ShadeRed })
	    local modal, content = UIKit.modal({ Title = "Shop" })

	Buttons with an "Opens" attribute toggle the modal of that name (see the
	HUD's controller script); every modal's "Close" button hides it.
]]

local UI = {}

UI.Font = Enum.Font.FredokaOne
UI.TextOutline = Color3.fromRGB(26, 16, 48)
-- Roblox draws FredokaOne about 20% smaller than Figma at the same size, so
-- every Figma text size is multiplied by this (measured against docs/figma)
UI.TextScale = 1.2

-- Uploaded from the Figma file (rbxassetid). Empty = not uploaded yet.
UI.Assets = {
	Studs = "rbxassetid://115518459266095", -- stud tile used by rect / progress / buy buttons (89.4px tile, 40%)
	StudsSquare = "rbxassetid://135739892997443", -- stud texture on the square buttons (230px tile, 20%)
	Shop = "rbxassetid://105128988344580", -- basket
	Aura = "rbxassetid://87628923496008",
	Pet = "rbxassetid://75080514724176",
	Skill = "rbxassetid://89389357448559", -- small flexed arm
	Trophy = "rbxassetid://121674502856865",
	Rebirth = "rbxassetid://91294314164136",
	Muscle = "rbxassetid://89389357448559", -- big flexed arm on the buy buttons
}
UI.FallbackStuds = "rbxassetid://100359261064701"

local rgb = Color3.fromRGB
UI.Colors = {
	Red = rgb(255, 0, 49), -- Shop
	Purple = rgb(238, 0, 255), -- Auras square
	Orange = rgb(255, 72, 0), -- Pets square
	Blue = rgb(0, 212, 255), -- level bar
	Yellow = rgb(255, 251, 0), -- +10M
	BuyRed = rgb(255, 0, 0), -- +100M
	Magenta = rgb(246, 0, 255), -- +1B
	-- shade overlays (colour, opacity at the bottom)
	ShadeBlack = rgb(0, 0, 0),
	ShadeRed = rgb(255, 0, 0),
	ShadeIndigo = rgb(64, 0, 255),
	ShadeBlue = rgb(0, 30, 255),
	-- text
	Gold = rgb(255, 226, 143), -- trophy counter
	Ice = rgb(220, 247, 255), -- rebirth counter
	Cream = rgb(255, 223, 160), -- skill row
	Track = rgb(255, 255, 255),
}

local function new(class: string, props: { [string]: any }?): any
	local o = Instance.new(class)
	local parent = nil
	for k, v in props or {} do
		if k == "Parent" then
			parent = v
		else
			(o :: any)[k] = v
		end
	end
	o.Parent = parent
	return o
end

local function corner(parent: Instance, px: number?)
	return new("UICorner", { CornerRadius = UDim.new(0, px or 12), Parent = parent })
end

-- White FredokaOne text with a dark outline. TextSize is the Figma size.
function UI.text(props: { [string]: any })
	local size = (props.TextSize or 36) * UI.TextScale
	local t = new("TextLabel", {
		Name = props.Name or "Label",
		BackgroundTransparency = 1,
		Font = UI.Font,
		Text = props.Text or "",
		TextColor3 = props.TextColor3 or Color3.new(1, 1, 1),
		TextSize = size,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 5,
		Parent = props.Parent,
	})
	new("UIStroke", {
		Thickness = props.Stroke or math.max(2, size / 15),
		Color = UI.TextOutline,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = t,
	})
	return t
end

function UI.image(image: string?, props: { [string]: any })
	return new("ImageLabel", {
		Name = props.Name or "Icon",
		BackgroundTransparency = 1,
		Image = image or "",
		ScaleType = Enum.ScaleType.Fit,
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 4,
		Parent = props.Parent,
	})
end

--[[ The Figma face: fill + shade + studs + outline, on any GuiObject.
	style: Color, Shade (colour), ShadeFrom (0..1, where the shade starts),
	ShadeAlpha (opacity at the bottom), Studs (image), StudTile (px), StudAlpha ]]
function UI.face(f: GuiObject, style)
	f.BackgroundColor3 = style.Color
	f.BackgroundTransparency = 0
	f.BorderSizePixel = 0
	corner(f)
	new("UIStroke", {
		Thickness = 3,
		Color = Color3.new(0, 0, 0),
		Transparency = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = f,
	})
	-- Figma draws the outline inside the frame
	pcall(function()
		(f:FindFirstChildOfClass("UIStroke") :: any).BorderStrokePosition = Enum.BorderStrokePosition.Inner
	end)
	local shade = new("Frame", {
		Name = "Shade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = style.Shade or UI.Colors.ShadeBlack,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = f,
	})
	corner(shade)
	local from = style.ShadeFrom or 0.5
	local alpha = style.ShadeAlpha or 0.2
	local points = { NumberSequenceKeypoint.new(0, 1) }
	if from > 0 then
		table.insert(points, NumberSequenceKeypoint.new(from, 1))
	end
	table.insert(points, NumberSequenceKeypoint.new(1, 1 - alpha))
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(points), Parent = shade })
	local studs = style.Studs
	if studs == nil or studs == "" then
		studs = UI.FallbackStuds
	end
	local tile = style.StudTile or 89.4
	local s = new("ImageLabel", {
		Name = "Studs",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = studs,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(tile, tile),
		ImageTransparency = 1 - (style.StudAlpha or 0.4),
		ZIndex = 3,
		Parent = f,
	})
	corner(s)
	return f
end

local function button(name: string, w: number, h: number, style)
	local b = new("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(w, h),
		ZIndex = 1,
	})
	UI.face(b, style)
	new("UIScale", { Name = "PressScale", Parent = b })
	return b
end

local function finish(b: GuiObject, opts)
	if opts.Opens then
		b:SetAttribute("Opens", opts.Opens)
	end
	if opts.LayoutOrder then
		b.LayoutOrder = opts.LayoutOrder
	end
	b.Parent = opts.Parent
	return b
end

--[[ Rectangle button (Figma RectangleButton, 284x96): icon + label.
	opts: Name, Text, Icon, Color, Width, Parent, Opens ]]
function UI.rectButton(opts)
	local w = opts.Width or 284
	local b = button(opts.Name or "RectangleButton", w, 96, { Color = opts.Color or UI.Colors.Red, Studs = UI.Assets.Studs })
	-- icon 78px and label overlap by 12px; the pair is centred on the button
	local content = new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w - 40, 78),
		ZIndex = 4,
		Parent = b,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, -12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
	local icon = UI.image(opts.Icon, { Parent = content, Size = UDim2.fromOffset(78, 78) })
	icon.LayoutOrder = 1
	local label = UI.text({ Name = "Label", Parent = content, Text = opts.Text or "Shop", TextSize = 36, Size = UDim2.fromOffset(0, 44) })
	label.AutomaticSize = Enum.AutomaticSize.X
	label.LayoutOrder = 2
	return finish(b, opts)
end

--[[ Square button (Figma SquareButton, 128x128): one 96px icon, optional label.
	opts: Name, Icon, Color, Text, Parent, Opens ]]
function UI.squareButton(opts)
	local b = button(opts.Name or "SquareButton", 128, 128, {
		Color = opts.Color or UI.Colors.Purple,
		Studs = UI.Assets.StudsSquare,
		StudTile = 230,
		StudAlpha = 0.2,
	})
	UI.image(opts.Icon, {
		Parent = b,
		Size = UDim2.fromOffset(96, 96),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
	if opts.Text and opts.Text ~= "" then
		UI.text({
			Parent = b,
			Text = opts.Text,
			TextSize = 30,
			Size = UDim2.new(1, 0, 0, 36),
			Position = UDim2.new(0.5, 0, 1, 2),
			AnchorPoint = Vector2.new(0.5, 1),
		})
	end
	return finish(b, opts)
end

--[[ Counter (Figma Counter): 61px icon + 36px amount, no background.
	opts: Name, Icon, Text, TextColor, Parent. Update counter.Amount.Text. ]]
function UI.counter(opts)
	local f = new("Frame", {
		Name = opts.Name or "Counter",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 61),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = f,
	})
	local icon = UI.image(opts.Icon, { Parent = f, Size = UDim2.fromOffset(61, 61) })
	icon.LayoutOrder = 1
	local amount = UI.text({
		Name = "Amount",
		Parent = f,
		Text = opts.Text or "0",
		TextSize = opts.TextSize or 36,
		TextColor3 = opts.TextColor or UI.Colors.Gold,
		Size = UDim2.fromOffset(0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	amount.AutomaticSize = Enum.AutomaticSize.X
	amount.LayoutOrder = 2
	return finish(f, opts)
end

--[[ Level progress (Figma Progress, 576 wide): skill row on top, bar below.
	opts: Name, Skill, Multiplier, Level, Value, Fill (0..1), Parent.
	Children to update: SkillRow.SkillLabel, SkillRow.Multi, Bar.Level, Bar.Value,
	Bar.Fill (Size.X.Scale = progress). ]]
function UI.progress(opts)
	local f = new("Frame", {
		Name = opts.Name or "Progress",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(576, 155),
	})
	local row = new("Frame", { Name = "SkillRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Parent = f })
	UI.image(UI.Assets.Skill, { Parent = row, Size = UDim2.fromOffset(48, 48) })
	UI.text({
		Name = "SkillLabel",
		Parent = row,
		Text = (opts.Skill or "1.2M") .. "  SKILL",
		TextSize = 32,
		TextColor3 = UI.Colors.Cream,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(54, 9),
		Size = UDim2.new(0.5, 0, 0, 39),
	})
	UI.text({
		Name = "Multi",
		Parent = row,
		Text = (opts.Multiplier or "7x") .. " Multiplier",
		TextSize = 32,
		TextColor3 = UI.Colors.Cream,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 9),
		Size = UDim2.new(0.5, 0, 0, 39),
	})
	-- the bar: a white studded track with the blue Figma face as the fill
	local bar = new("Frame", { Name = "Bar", Position = UDim2.fromOffset(0, 59), Size = UDim2.new(1, 0, 0, 96), Parent = f })
	UI.face(bar, { Color = UI.Colors.Track, Shade = UI.Colors.ShadeBlack, ShadeFrom = 0.5, ShadeAlpha = 0.15, Studs = UI.Assets.Studs })
	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(math.clamp(opts.Fill or 1, 0, 1), 1),
		ZIndex = 4,
		Parent = bar,
	})
	UI.face(fill, { Color = UI.Colors.Blue, Shade = UI.Colors.ShadeBlue, ShadeFrom = 0, ShadeAlpha = 0.4, Studs = UI.Assets.Studs })
	UI.text({
		Name = "Level",
		Parent = bar,
		Text = "Level " .. tostring(opts.Level or 80),
		TextSize = 48,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(22, 16),
		Size = UDim2.new(0.5, -22, 0, 58),
		ZIndex = 6,
	})
	UI.text({
		Name = "Value",
		Parent = bar,
		Text = opts.Value or "1.2k/3.05k",
		TextSize = 48,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -15, 0, 16),
		Size = UDim2.new(0.5, -15, 0, 58),
		ZIndex = 6,
	})
	return finish(f, opts)
end

--[[ Buy button (Figma BuyProgress, 181x96): arm icon popping out the top, big label.
	opts: Name, Text, Color, Shade, Price, Width, Parent ]]
function UI.buyButton(opts)
	local w = opts.Width or 181.33
	local b = button(opts.Name or "BuyButton", w, 96, {
		Color = opts.Color or UI.Colors.Yellow,
		Shade = opts.Shade or UI.Colors.ShadeRed,
		ShadeFrom = 0,
		ShadeAlpha = 0.4,
		Studs = UI.Assets.Studs,
	})
	UI.image(UI.Assets.Muscle, {
		Parent = b,
		Size = UDim2.fromOffset(96, 96),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -15),
	})
	UI.text({
		Name = "Label",
		Parent = b,
		Text = opts.Text or "+10M",
		TextSize = 48,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 38),
		Size = UDim2.new(1, 0, 0, 58),
	})
	if opts.Price then
		UI.text({
			Name = "Price",
			Parent = b,
			Text = opts.Price,
			TextSize = 22,
			TextColor3 = rgb(140, 255, 120),
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -8, 1, -2),
			Size = UDim2.fromOffset(60, 26),
		})
	end
	return finish(b, opts)
end

--[[ Modal: a general popup (shop, inventory, rebirth...) in the same face style.
	opts: Name, Title, Color, Visible, Parent. Returns the modal and its Content
	scrolling frame (a UIGridLayout is inside). ]]
function UI.modal(opts)
	local m = new("Frame", {
		Name = opts.Name or "Modal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		-- fits two rows of five 128px cards; Content scrolls past that
		Size = UDim2.fromOffset(860, 452),
		Visible = opts.Visible ~= false,
		ZIndex = 10,
	})
	UI.face(m, { Color = opts.Color or UI.Colors.Blue, Shade = UI.Colors.ShadeBlue, ShadeFrom = 0, ShadeAlpha = 0.4, Studs = UI.Assets.Studs })
	UI.text({
		Name = "Title",
		Parent = m,
		Text = opts.Title or "Shop",
		TextSize = 64,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(28, 4),
		Size = UDim2.fromOffset(480, 80),
	})
	local close = button("Close", 72, 72, { Color = UI.Colors.Red, Studs = UI.Assets.Studs })
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Position = UDim2.new(1, -14, 0, 14)
	UI.text({ Name = "X", Parent = close, Text = "X", TextSize = 48 })
	close.Parent = m
	local body = new("Frame", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.new(1, -48, 1, -96),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.75,
		ZIndex = 4,
		Parent = m,
	})
	corner(body)
	local content = new("ScrollingFrame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Color3.new(1, 1, 1),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 5,
		Parent = body,
	})
	new("UIPadding", {
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 20),
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		Parent = content,
	})
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(128, 128),
		CellPadding = UDim2.fromOffset(28, 28),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
	m.Parent = opts.Parent
	return m, content
end

-- LocalScript placed in the demo HUD: scales the HUD to the screen, animates
-- every button, and wires Opens / Close.
UI.ControllerSource = [[
local TweenService = game:GetService("TweenService")
local gui = script.Parent
local camera = workspace.CurrentCamera

-- the layout is drawn at Figma size for a 1000px-tall screen (sized so the
-- HUD takes about the share of the screen it does in QM's layout reference)
local autoScale = gui:FindFirstChild("AutoScale")
local function rescale()
	if autoScale then
		autoScale.Scale = math.clamp(camera.ViewportSize.Y / 1000, 0.4, 1.4)
	end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
rescale()

local function hook(b)
	if not b:IsA("GuiButton") then
		return
	end
	local s = b:FindFirstChild("PressScale")
	if s then
		local function to(v)
			TweenService:Create(s, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Scale = v }):Play()
		end
		b.MouseEnter:Connect(function() to(1.06) end)
		b.MouseLeave:Connect(function() to(1) end)
		b.MouseButton1Down:Connect(function() to(0.92) end)
		b.MouseButton1Up:Connect(function() to(1.06) end)
	end
	local opens = b:GetAttribute("Opens")
	if opens then
		b.Activated:Connect(function()
			local m = gui:FindFirstChild(opens, true)
			if m then
				m.Visible = not m.Visible
			end
		end)
	end
	if b.Name == "Close" and b.Parent and b.Parent:IsA("GuiObject") then
		b.Activated:Connect(function()
			b.Parent.Visible = false
		end)
	end
end

for _, d in gui:GetDescendants() do
	hook(d)
end
gui.DescendantAdded:Connect(hook)
]]

-- The HUD, laid out like QM's reference: Shop + square grid at the left,
-- counters bottom-left, skill/level bar with the three buy buttons bottom-centre.
function UI.buildHUD(parent: Instance, modalVisible: boolean?)
	local A, C = UI.Assets, UI.Colors
	local old = parent:FindFirstChild("HUD")
	if old then
		old.Parent = nil
	end
	local gui = new("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	new("UIScale", { Name = "AutoScale", Parent = gui })

	-- left: Shop over a 2-wide grid of square buttons (same 284 width)
	local left = new("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 28, 0.42, 0),
		Size = UDim2.fromOffset(284, 96 + 28 + 128),
		Parent = gui,
	})
	new("UIListLayout", { Padding = UDim.new(0, 28), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
	UI.rectButton({ Name = "Shop", Text = "Shop", Icon = A.Shop, Color = C.Red, Opens = "ShopModal", LayoutOrder = 1, Parent = left })
	local grid = new("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.fromOffset(284, 128), LayoutOrder = 2, Parent = left })
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(128, 128),
		CellPadding = UDim2.fromOffset(28, 28),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	UI.squareButton({ Name = "Auras", Icon = A.Aura, Color = C.Purple, LayoutOrder = 1, Parent = grid })
	UI.squareButton({ Name = "Pets", Icon = A.Pet, Color = C.Orange, LayoutOrder = 2, Parent = grid })

	-- bottom-left: counters
	local counters = new("Frame", {
		Name = "Counters",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 28, 1, -28),
		Size = UDim2.fromOffset(284, 61 * 2 + 26),
		Parent = gui,
	})
	new("UIListLayout", { Padding = UDim.new(0, 26), SortOrder = Enum.SortOrder.LayoutOrder, Parent = counters })
	UI.counter({ Name = "Rebirths", Icon = A.Rebirth, Text = "2", TextColor = C.Ice, LayoutOrder = 1, Parent = counters })
	UI.counter({ Name = "Wins", Icon = A.Trophy, Text = "5K", TextColor = C.Gold, LayoutOrder = 2, Parent = counters })

	-- bottom-centre: skill + level bar, buy buttons under it
	local bottom = new("Frame", {
		Name = "Bottom",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(577, 155 + 22 + 96),
		Parent = gui,
	})
	UI.progress({ Name = "Progress", Skill = "1.2M", Multiplier = "7x", Level = 80, Value = "1.2k/3.05k", Fill = 0.39, Parent = bottom })
	local buys = new("Frame", {
		Name = "Buy",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 96),
		Parent = bottom,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = buys,
	})
	UI.buyButton({ Name = "Buy10M", Text = "+10M", Color = C.Yellow, Shade = C.ShadeRed, LayoutOrder = 1, Parent = buys })
	UI.buyButton({ Name = "Buy100M", Text = "+100M", Color = C.BuyRed, Shade = C.ShadeIndigo, LayoutOrder = 2, Parent = buys })
	UI.buyButton({ Name = "Buy1B", Text = "+1B", Color = C.Magenta, Shade = C.ShadeIndigo, LayoutOrder = 3, Parent = buys })

	-- the general modal, here as the shop
	local _, content = UI.modal({ Name = "ShopModal", Title = "Shop", Visible = modalVisible == true, Parent = gui })
	local items = {
		{ "Auras", A.Aura, C.Purple },
		{ "Pets", A.Pet, C.Orange },
		{ "Wins", A.Trophy, C.Yellow },
		{ "Rebirth", A.Rebirth, C.Blue },
		{ "Skill", A.Muscle, C.Magenta },
		{ "Basket", A.Shop, C.Red },
		{ "Mega Pet", A.Pet, C.Purple },
		{ "x2 Wins", A.Trophy, C.Orange },
		{ "Power", A.Muscle, C.BuyRed },
		{ "Aura+", A.Aura, C.Blue },
	}
	for i, it in items do
		UI.squareButton({ Name = it[1], Icon = it[2], Color = it[3], Text = it[1], LayoutOrder = i, Parent = content })
	end

	local controller = Instance.new("LocalScript")
	controller.Name = "HUDController"
	;(controller :: any).Source = UI.ControllerSource
	controller.Parent = gui

	gui.Parent = parent
	return gui
end

-- Bare templates to :Clone() from code (ReplicatedStorage.UITemplates).
function UI.buildTemplates(parent: Instance)
	local A, C = UI.Assets, UI.Colors
	local old = parent:FindFirstChild("UITemplates")
	if old then
		old.Parent = nil
	end
	local folder = new("Folder", { Name = "UITemplates" })
	UI.rectButton({ Name = "RectangleButton", Text = "Shop", Icon = A.Shop, Color = C.Red, Parent = folder })
	UI.squareButton({ Name = "SquareButton", Icon = A.Aura, Color = C.Purple, Parent = folder })
	UI.counter({ Name = "Counter", Icon = A.Trophy, Text = "5K", Parent = folder })
	UI.progress({ Name = "Progress", Parent = folder })
	UI.buyButton({ Name = "BuyButton", Text = "+10M", Parent = folder })
	UI.modal({ Name = "Modal", Title = "Title", Parent = folder })
	folder.Parent = parent
	return folder
end

return UI

--[[
	UI: HUD element templates in the house style.

	FredokaOne everywhere, fully saturated colours (only the hue changes), a
	black outline, QM's L-stud tile over every coloured face, white text with a
	black stroke. Self-contained, so it also works at runtime as
	ReplicatedStorage.UIKit:

	    local UIKit = require(game.ReplicatedStorage.UIKit)
	    UIKit.squareButton({ Text = "Shop", Icon = "🛒", Hue = 0, Parent = frame })
	    UIKit.rectButton({ Text = "x2 Wins", SubText = "⏣ 99", Icon = "🏆", Hue = 50 })
	    UIKit.counter({ Icon = "🏆", Text = "14.09K" })
	    local modal, content = UIKit.modal({ Title = "Shop", Hue = 200 })

	Icon is an emoji or an "rbxassetid://" image. Hue is 0..360.
	Buttons with an "Opens" attribute toggle the modal of that name (see the
	HUD's controller script); every modal's "Close" button hides it.
]]

local UI = {}

UI.Font = Enum.Font.FredokaOne
UI.StudImage = "rbxassetid://100359261064701"
UI.StudTile = 26
UI.StudTransparency = 0.55
UI.Outline = Color3.new(0, 0, 0)

function UI.hue(h: number): Color3
	return Color3.fromHSV((h % 360) / 360, 1, 1)
end

local function new(class: string, props: { [string]: any }?, children: { Instance }?): any
	local o = Instance.new(class)
	local parent = nil
	for k, v in props or {} do
		if k == "Parent" then
			parent = v
		else
			(o :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = o
	end
	o.Parent = parent
	return o
end

local function corner(r: UDim?)
	return new("UICorner", { CornerRadius = r or UDim.new(0.2, 0) })
end

local function stroke(thickness: number, border: boolean?)
	return new("UIStroke", {
		Thickness = thickness,
		Color = UI.Outline,
		LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = if border then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual,
	})
end

-- White FredokaOne text with a black stroke
function UI.text(props: { [string]: any })
	local t = new("TextLabel", {
		Name = props.Name or "Label",
		BackgroundTransparency = 1,
		Font = UI.Font,
		Text = props.Text or "",
		TextColor3 = props.TextColor3 or Color3.new(1, 1, 1),
		TextScaled = true,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 3,
		Parent = props.Parent,
	})
	stroke(props.Stroke or 2.5).Parent = t
	return t
end

-- Emoji or image icon
function UI.icon(icon: string?, props: { [string]: any })
	local common = {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		ZIndex = 3,
		Parent = props.Parent,
	}
	if icon and string.sub(icon, 1, 3) == "rbx" then
		common.Image = icon
		common.ScaleType = Enum.ScaleType.Fit
		return new("ImageLabel", common)
	end
	common.Text = icon or ""
	common.TextScaled = true
	common.Font = UI.Font
	common.TextColor3 = Color3.new(1, 1, 1)
	return new("TextLabel", common)
end

-- Coloured face: hue fill, soft top-to-bottom shade, black outline, L-studs
function UI.face(f: GuiObject, color: Color3, radius: UDim?, outline: number?)
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 0
	f.BorderSizePixel = 0
	corner(radius).Parent = f
	stroke(outline or 3, true).Parent = f
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)),
	}).Parent = f
	local studs = new("ImageLabel", {
		Name = "Studs",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = UI.StudImage,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(UI.StudTile, UI.StudTile),
		ImageTransparency = UI.StudTransparency,
		ZIndex = 2,
	})
	corner(radius).Parent = studs
	studs.Parent = f
	return f
end

local function button(name: string, size: UDim2, hue: number, radius: UDim?)
	local b = new("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		Size = size,
		ZIndex = 1,
	})
	UI.face(b, UI.hue(hue), radius)
	-- the HUD controller tweens this for hover / press
	new("UIScale", { Name = "PressScale" }).Parent = b
	return b
end

--[[ Square button: icon on top, label across the bottom edge.
	opts: Name, Text, Icon, Hue, Size (px, default 96), Parent, Opens ]]
function UI.squareButton(opts)
	local s = opts.Size or 96
	local b = button(opts.Name or "SquareButton", UDim2.fromOffset(s, s), opts.Hue or 0)
	UI.icon(opts.Icon, { Parent = b, Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.42) })
	if opts.Text and opts.Text ~= "" then
		UI.text({
			Parent = b,
			Text = opts.Text,
			Size = UDim2.fromScale(1.05, 0.3),
			Position = UDim2.fromScale(0.5, 0.98),
			AnchorPoint = Vector2.new(0.5, 1),
		})
	end
	if opts.Opens then
		b:SetAttribute("Opens", opts.Opens)
	end
	b.Parent = opts.Parent
	return b
end

--[[ Rectangle button: icon on the left, title (and optional subtitle) on the right.
	opts: Name, Text, SubText, Icon, Hue, Size (UDim2, default 240x80), Parent, Opens ]]
function UI.rectButton(opts)
	local b = button(opts.Name or "RectButton", opts.Size or UDim2.fromOffset(240, 80), opts.Hue or 200, UDim.new(0.22, 0))
	UI.icon(opts.Icon, { Parent = b, Size = UDim2.fromScale(0.3, 1.05), Position = UDim2.fromScale(0.17, 0.5) })
	local hasSub = opts.SubText ~= nil and opts.SubText ~= ""
	UI.text({
		Name = "Title",
		Parent = b,
		Text = opts.Text or "Button",
		Size = UDim2.fromScale(0.64, if hasSub then 0.5 else 0.62),
		Position = UDim2.fromScale(0.33, if hasSub then 0.08 else 0.19),
	})
	if hasSub then
		UI.text({
			Name = "SubText",
			Parent = b,
			Text = opts.SubText,
			Size = UDim2.fromScale(0.64, 0.34),
			Position = UDim2.fromScale(0.33, 0.58),
			TextColor3 = UI.hue(opts.SubHue or 120),
		})
	end
	if opts.Opens then
		b:SetAttribute("Opens", opts.Opens)
	end
	b.Parent = opts.Parent
	return b
end

--[[ Counter: icon + value on a dark pill.
	opts: Name, Icon, Text, Size (UDim2, default 200x54), Parent
	Set counter.Value.Text to update it. ]]
function UI.counter(opts)
	local f = new("Frame", {
		Name = opts.Name or "Counter",
		Size = opts.Size or UDim2.fromOffset(200, 54),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
	})
	corner(UDim.new(0.5, 0)).Parent = f
	UI.icon(opts.Icon, { Parent = f, Size = UDim2.fromScale(0.3, 1.2), Position = UDim2.fromScale(0.14, 0.5) })
	UI.text({
		Name = "Value",
		Parent = f,
		Text = opts.Text or "0",
		Size = UDim2.fromScale(0.66, 0.72),
		Position = UDim2.fromScale(0.3, 0.14),
		TextXAlignment = Enum.TextXAlignment.Left,
		Stroke = 3,
	})
	f.Parent = opts.Parent
	return f
end

--[[ Modal: a general popup (shop, inventory, rebirth...).
	opts: Name, Title, Hue, Visible, Parent
	Returns the modal frame and its Content scrolling frame (a UIGridLayout is
	inside; drop cards in, or swap the layout). ]]
function UI.modal(opts)
	local m = new("Frame", {
		Name = opts.Name or "Modal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(760, 500),
		Visible = opts.Visible ~= false,
		ZIndex = 10,
	})
	UI.face(m, UI.hue(opts.Hue or 200), UDim.new(0, 22), 4)
	UI.text({
		Name = "Title",
		Parent = m,
		Text = opts.Title or "Shop",
		Size = UDim2.fromOffset(420, 70),
		Position = UDim2.fromOffset(24, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		TextXAlignment = Enum.TextXAlignment.Left,
		Stroke = 5,
	})
	local close = UI.squareButton({ Name = "Close", Icon = "✖", Hue = 0, Size = 64, Parent = m })
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Position = UDim2.new(1, -12, 0, 10)
	local body = new("Frame", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -22),
		Size = UDim2.new(1, -44, 1, -86),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.72,
		ZIndex = 3,
		Parent = m,
	})
	corner(UDim.new(0, 16)).Parent = body
	local content = new("ScrollingFrame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Color3.new(1, 1, 1),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 4,
		Parent = body,
	})
	new("UIPadding", {
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = content,
	})
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(150, 150),
		CellPadding = UDim2.fromOffset(16, 16),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
	m.Parent = opts.Parent
	return m, content
end

--[[ Shop / inventory card for a modal: square button with a price under the label.
	opts: Name, Text, Icon, Hue, Price, Parent ]]
function UI.card(opts)
	local c = UI.squareButton({ Name = opts.Name or "Card", Text = opts.Text, Icon = opts.Icon, Hue = opts.Hue, Size = 150 })
	local icon = c:FindFirstChild("Icon")
	if icon then
		icon.Size = UDim2.fromScale(0.56, 0.56)
		icon.Position = UDim2.fromScale(0.5, 0.36)
	end
	local label = c:FindFirstChild("Label")
	if label then
		label.Size = UDim2.fromScale(0.95, 0.2)
		label.Position = UDim2.fromScale(0.5, 0.82)
	end
	if opts.Price then
		UI.text({
			Name = "Price",
			Parent = c,
			Text = opts.Price,
			Size = UDim2.fromScale(0.9, 0.18),
			Position = UDim2.fromScale(0.5, 0.99),
			AnchorPoint = Vector2.new(0.5, 1),
			TextColor3 = UI.hue(120),
		})
	end
	c.Parent = opts.Parent
	return c
end

-- LocalScript placed in the demo HUD: scales the HUD to the screen, animates
-- every button, and wires Opens / Close.
UI.ControllerSource = [[
local TweenService = game:GetService("TweenService")
local gui = script.Parent
local camera = workspace.CurrentCamera

local autoScale = gui:FindFirstChild("AutoScale")
local function rescale()
	if autoScale then
		autoScale.Scale = math.clamp(camera.ViewportSize.Y / 820, 0.55, 1.3)
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

-- A HUD laid out with every template, as a starting point for each game.
function UI.buildHUD(parent: Instance, modalVisible: boolean?)
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

	-- left: counters over a 2-wide grid of square buttons
	local left = new("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 20, 0.5, 0),
		Size = UDim2.fromOffset(212, 470),
		Parent = gui,
	})
	new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
	local c1 = UI.counter({ Name = "Rebirths", Icon = "🔁", Text = "2", Parent = left })
	c1.LayoutOrder = 1
	local c2 = UI.counter({ Name = "Wins", Icon = "🏆", Text = "14.09K", Parent = left })
	c2.LayoutOrder = 2
	local grid = new("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(212, 330),
		LayoutOrder = 3,
		Parent = left,
	})
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(96, 96),
		CellPadding = UDim2.fromOffset(14, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	local squares = {
		{ "Shop", "🛒", 0, "ShopModal" },
		{ "Rebirth", "🔁", 200 },
		{ "Pets", "🐾", 30 },
		{ "Auras", "✨", 285 },
		{ "Trails", "💫", 260 },
		{ "Gifts", "🎁", 330 },
	}
	for i, s in squares do
		local b = UI.squareButton({ Name = s[1], Text = s[1], Icon = s[2], Hue = s[3], Opens = s[4], Parent = grid })
		b.LayoutOrder = i
	end

	-- right: rectangle buttons
	local right = new("Frame", {
		Name = "Right",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.fromOffset(240, 280),
		Parent = gui,
	})
	new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right })
	local rects = {
		{ "x1.5 Skill", "⏣ 1", "⚡", 30 },
		{ "x2 Wins", "⏣ 99", "🏆", 50 },
		{ "Auto Throw", "⏣ 79", "🎯", 200 },
	}
	for i, r in rects do
		local b = UI.rectButton({ Name = r[1], Text = r[1], SubText = r[2], Icon = r[3], Hue = r[4], Parent = right })
		b.LayoutOrder = i
	end

	-- bottom centre: skill counter
	local skill = UI.counter({ Name = "Skill", Icon = "⚡", Text = "1.23K", Parent = gui })
	skill.AnchorPoint = Vector2.new(0.5, 1)
	skill.Position = UDim2.new(0.5, 0, 1, -24)

	-- the general modal, here as a shop
	local modal, content = UI.modal({ Name = "ShopModal", Title = "Shop", Hue = 200, Visible = modalVisible == true, Parent = gui })
	local items = {
		{ "Sword", "🗡️", 0, "⏣ 50" },
		{ "Bat", "🏏", 30, "⏣ 120" },
		{ "Hammer", "🔨", 55, "⏣ 300" },
		{ "Rocket", "🚀", 200, "⏣ 900" },
		{ "Magnet", "🧲", 285, "⏣ 2K" },
		{ "Bomb", "💣", 330, "⏣ 5K" },
		{ "Star", "⭐", 50, "⏣ 10K" },
		{ "Crown", "👑", 45, "⏣ 50K" },
	}
	for i, it in items do
		local c = UI.card({ Name = it[1], Text = it[1], Icon = it[2], Hue = it[3], Price = it[4], Parent = content })
		c.LayoutOrder = i
	end
	modal.ZIndex = 10

	local controller = Instance.new("LocalScript")
	controller.Name = "HUDController"
	;(controller :: any).Source = UI.ControllerSource
	controller.Parent = gui

	gui.Parent = parent
	return gui
end

-- Bare templates to :Clone() from code (ReplicatedStorage.UITemplates).
function UI.buildTemplates(parent: Instance)
	local old = parent:FindFirstChild("UITemplates")
	if old then
		old.Parent = nil
	end
	local folder = new("Folder", { Name = "UITemplates" })
	UI.squareButton({ Name = "SquareButton", Text = "Button", Icon = "⭐", Hue = 0, Parent = folder })
	UI.rectButton({ Name = "RectButton", Text = "Button", SubText = "⏣ 99", Icon = "⭐", Hue = 200, Parent = folder })
	UI.counter({ Name = "Counter", Icon = "🏆", Text = "0", Parent = folder })
	UI.modal({ Name = "Modal", Title = "Title", Hue = 200, Parent = folder })
	UI.card({ Name = "Card", Text = "Item", Icon = "⭐", Hue = 50, Price = "⏣ 10", Parent = folder })
	folder.Parent = parent
	return folder
end

return UI

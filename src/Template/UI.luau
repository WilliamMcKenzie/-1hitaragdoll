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

	Popups: UI.popup (generic), UI.shopPopup, UI.rebirthPopup; UI.notification
	puts the red "!" dot on a button.
	Buttons with an "Opens" attribute toggle the popup/modal of that name (see the
	HUD's controller script); every modal's "Close" button hides it.
	Each button is a fixed slot with a centred "Visual" child that holds the
	face and content; hover/press scale only the Visual, so nothing moves.
	squareButton with no Color is the see-through Figma square.
]]

local UI = {}

UI.Font = Enum.Font.FredokaOne
UI.TextOutline = Color3.fromRGB(26, 16, 48)
-- Roblox draws FredokaOne about 20% smaller than Figma at the same size, so
-- every Figma text size is multiplied by this (measured against docs/figma)
UI.TextScale = 1.2
-- level bar width: 96px tall at 8:1 (QM); the buy buttons split the same width
UI.BarWidth = 768
-- In-game sizing, matched to QM's reference screenshot (docs/figma/layout_inspo.png,
-- 1994x1488): the HUD is drawn at Figma px for a screen RefHeight px tall, and
-- the bottom cluster / counters get their own extra scale so their on-screen
-- size matches the reference too.
UI.RefHeight = 1300
UI.BottomScale = 0.945 -- bar 830 px wide on a 1488 px screen
UI.PopupScale = 1.15 -- popups ~57% of the screen height, as in QM's references
UI.CounterScale = 1.25 -- counter icons ~100 px on a 1488 px screen

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
-- Figma v2 (QM, Nov 12): new icons, uploaded at 512px (originals 1254px)
UI.Assets.Shop = "rbxassetid://94629817402467" -- basket v2
UI.Assets.Aura = "rbxassetid://122473751099925" -- blue flame aura
UI.Assets.Rebirth = "rbxassetid://140126511628363" -- square button and counter share it
UI.Assets.Pet = "rbxassetid://100296903679383"
UI.Assets.Trails = "rbxassetid://85706725966362"
UI.Assets.Inventory = "rbxassetid://81964370370028"
UI.Assets.Gifts = "rbxassetid://138549431513959"
UI.Assets.Trophy = "rbxassetid://92367166837958"
UI.Assets.Muscle = "rbxassetid://71232057538317" -- skill row and buy buttons share it
UI.Assets.Skill = UI.Assets.Muscle
UI.FallbackStuds = "rbxassetid://100359261064701"

local rgb = Color3.fromRGB
UI.Colors = {
	Red = rgb(255, 0, 49),
	ShopGold = rgb(255, 194, 0), -- Shop (Figma v3)
	CloseRed = rgb(249, 3, 96), -- popup close button, rebirth warning
	Green = rgb(77, 255, 0), -- REBIRTH
	Violet = rgb(170, 0, 255), -- SKIP
	ShadeSky = rgb(0, 119, 255),
	ShadeViolet = rgb(43, 0, 255),
	OfferGrey = rgb(217, 217, 217),
	Notify = rgb(255, 0, 0),
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
		Color = props.StrokeColor or UI.TextOutline,
		Transparency = props.StrokeTransparency or 0,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = t,
	})
	-- Shadow: Figma's drop shadow (black, 4px down) as a black copy behind
	if props.Shadow then
		local sh = new("TextLabel", {
			Name = "Shadow",
			BackgroundTransparency = 1,
			Font = UI.Font,
			Text = t.Text,
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = size,
			TextXAlignment = t.TextXAlignment,
			TextYAlignment = t.TextYAlignment,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(0, 4),
			ZIndex = t.ZIndex - 1,
			Parent = t,
		})
		new("UIStroke", {
			Thickness = props.Stroke or math.max(2, size / 15),
			Color = Color3.new(0, 0, 0),
			LineJoinMode = Enum.LineJoinMode.Round,
			Parent = sh,
		})
		t:GetPropertyChangedSignal("Text"):Connect(function()
			sh.Text = t.Text
		end)
	end
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
	ShadeAlpha (opacity at the bottom), Studs (image), StudTile (px), StudAlpha,
	Alpha (fill opacity, default 1; the square buttons are black at 0.2) ]]
function UI.face(f: GuiObject, style)
	f.BackgroundColor3 = style.Color
	f.BackgroundTransparency = 1 - (style.Alpha or 1)
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

-- A button is an invisible fixed-size slot (what layouts see and what takes the
-- clicks) holding a centred Visual with the face, content and PressScale. Hover
-- and press scale only the Visual, so it grows from its centre and never moves
-- its neighbours (like position: absolute). Put content in the returned Visual.
local function button(name: string, w: number, h: number, style)
	local b = new("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(w, h),
		ZIndex = 1,
	})
	local v = new("Frame", {
		Name = "Visual",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = b,
	})
	UI.face(v, style)
	new("UIScale", { Name = "PressScale", Parent = v })
	return b, v
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

--[[ Rectangle button (Figma RectangleButton v2, 264x96): icon + label.
	opts: Name, Text, Icon, Color, Width, Parent, Opens ]]
function UI.rectButton(opts)
	local w = opts.Width or 264
	local b, v = button(opts.Name or "RectangleButton", w, 96, { Color = opts.Color or UI.Colors.Yellow, Studs = UI.Assets.Studs })
	-- icon 78px and label overlap by 12px; the pair is centred on the button
	local content = new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w - 40, 78),
		ZIndex = 4,
		Parent = v,
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
	opts: Name, Icon, Color, Text, Badge (text over the top edge),
	Notify (true or text: the red notification dot), Parent, Opens ]]
function UI.squareButton(opts)
	-- no Color: the Figma SquareButton (v3), a see-through face: black fill at
	-- 50%, black shade 0 -> 50% over the bottom half, pattern at 20%, 50% black outline
	local b, v = button(opts.Name or "SquareButton", 128, 128, {
		Color = opts.Color or Color3.new(0, 0, 0),
		Alpha = if opts.Color then 1 else 0.5,
		ShadeFrom = 0.5,
		ShadeAlpha = if opts.Color then 0.2 else 0.5,
		Studs = UI.Assets.StudsSquare,
		StudTile = 230,
		StudAlpha = 0.2,
	})
	UI.image(opts.Icon, {
		Parent = v,
		Size = UDim2.fromOffset(96, 96),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
	if opts.Text and opts.Text ~= "" then
		UI.text({
			Parent = v,
			Text = opts.Text,
			TextSize = 30,
			Size = UDim2.new(1, 0, 0, 36),
			Position = UDim2.new(0.5, 0, 1, 2),
			AnchorPoint = Vector2.new(0.5, 1),
		})
	end
	if opts.Notify then
		UI.notification(v, if type(opts.Notify) == "string" then opts.Notify else "!")
	end
	-- Badge: Figma v3 "97%" on Rebirth, 36px, its box top 10px above the square
	if opts.Badge then
		UI.text({
			Name = "Badge",
			Parent = v,
			Text = opts.Badge,
			TextSize = 36,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 4, 0, -10),
			Size = UDim2.new(1, 0, 0, 44),
			ZIndex = 6,
		})
	end
	return finish(b, opts)
end

--[[ Counter (Figma Counter v2): 70px icon + 36px amount at x=75, no background.
	opts: Name, Icon, Text, TextColor, Parent. Update counter.Amount.Text. ]]
function UI.counter(opts)
	local f = new("Frame", {
		Name = opts.Name or "Counter",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 70),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = f,
	})
	local icon = UI.image(opts.Icon, { Parent = f, Size = UDim2.fromOffset(70, 70) })
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

--[[ Level progress (Figma Progress; QM widened it to 768 so the bar is 8:1): skill row on top, bar below.
	opts: Name, Skill, Multiplier, Level, Value, Fill (0..1), Parent.
	Children to update: SkillRow.SkillLabel, SkillRow.Multi, Bar.Level, Bar.Value,
	Bar.Fill (Size.X.Scale = progress). ]]
function UI.progress(opts)
	local f = new("Frame", {
		Name = opts.Name or "Progress",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(opts.Width or UI.BarWidth, 161),
	})
	-- v2: 54px row, 54px icon, labels at y=12
	local row = new("Frame", { Name = "SkillRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54), Parent = f })
	UI.image(UI.Assets.Skill, { Parent = row, Size = UDim2.fromOffset(54, 54) })
	UI.text({
		Name = "SkillLabel",
		Parent = row,
		Text = (opts.Skill or "1.2M") .. "  SKILL",
		TextSize = 32,
		TextColor3 = UI.Colors.Cream,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(60, 12),
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
		Position = UDim2.new(1, 0, 0, 12),
		Size = UDim2.new(0.5, 0, 0, 39),
	})
	-- the bar: a white studded track with the blue Figma face as the fill
	local bar = new("Frame", { Name = "Bar", Position = UDim2.fromOffset(0, 65), Size = UDim2.new(1, 0, 0, 96), Parent = f })
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

--[[ Buy button (Figma BuyProgress, 181x74): arm icon popping out the top, big label.
	opts: Name, Text, Color, Shade, Price, Width, Parent ]]
function UI.buyButton(opts)
	local w = opts.Width or (UI.BarWidth - 2 * 16) / 3
	local b, v = button(opts.Name or "BuyButton", w, 74, {
		Color = opts.Color or UI.Colors.Yellow,
		Shade = opts.Shade or UI.Colors.ShadeRed,
		ShadeFrom = 0,
		ShadeAlpha = 0.4,
		Studs = UI.Assets.Studs,
	})
	UI.image(UI.Assets.Muscle, {
		Parent = v,
		-- Figma: 96px arm, top 22px above the top edge. Our upload keeps the
		-- image's soft transparent margin (the arm is only ~73% of the frame),
		-- which Figma's render crops, so the frame is 116px and starts 26px up
		-- to give the same visible arm (about 1.13x the button's height)
		Size = UDim2.fromOffset(116, 116),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -26),
	})
	UI.text({
		Name = "Label",
		Parent = v,
		Text = opts.Text or "+10M",
		TextSize = 36,
		-- label hangs ~13px below the bottom edge, as in Figma (box at 37, not
		-- 43: Roblox sets FredokaOne lower in its box than Figma does)
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 37),
		Size = UDim2.new(1, 0, 0, 44),
	})
	if opts.Price then
		UI.text({
			Name = "Price",
			Parent = v,
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
	local close, closeVisual = button("Close", 72, 72, { Color = UI.Colors.Red, Studs = UI.Assets.Studs })
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Position = UDim2.new(1, -14, 0, 14)
	UI.text({ Name = "X", Parent = closeVisual, Text = "X", TextSize = 48 })
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

--[[ Notification dot (Figma Gifts > Notification): 48px red circle, 50% black
	outline, white "!" (or a count), its top-left 31px in from the right edge and
	6px above the top. Parent it to a button's Visual so it scales with hover.
	Set dot.Visible / dot.Label.Text from code. ]]
function UI.notification(parent: GuiObject, text: string?)
	local dot = new("Frame", {
		Name = "Notification",
		BackgroundColor3 = UI.Colors.Notify,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -31, 0, -6),
		Size = UDim2.fromOffset(48, 48),
		ZIndex = 7,
		Parent = parent,
	})
	corner(dot, 24)
	local st = new("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 0.5, Parent = dot })
	pcall(function()
		(st :: any).BorderStrokePosition = Enum.BorderStrokePosition.Inner
	end)
	UI.text({
		Name = "Label",
		Parent = dot,
		Text = text or "!",
		TextSize = 36,
		StrokeColor = Color3.new(0, 0, 0),
		StrokeTransparency = 0.5,
		Stroke = 3,
		ZIndex = 8,
	})
	return dot
end

-- the see-through face of the popups and square buttons (Figma v3 BG)
local GLASS = {
	Color = Color3.new(0, 0, 0),
	Alpha = 0.5,
	ShadeFrom = 0.5,
	ShadeAlpha = 0.5,
	StudAlpha = 0.2,
	StudTile = 230,
}

--[[ Popup (Figma "Popup" frames): see-through dark panel, 80px title over the
	top edge, a 192px icon breaking out of the top-left corner, and the red
	88px close button over the top-right corner. Hidden by default; a button
	with Opens = <Name> shows it (the controller closes other popups and blurs
	the world behind it). opts: Name, Title, Icon, Width, Height, IconOffset
	(Vector2, icon top-left relative to the panel), Visible, Parent.
	Returns the popup; put content straight into it (panel px coordinates). ]]
function UI.popup(opts)
	local w, h = opts.Width or 846, opts.Height or 621
	local p = new("Frame", {
		Name = opts.Name or "Popup",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w, h),
		Visible = opts.Visible == true,
		ZIndex = 20,
	})
	p:SetAttribute("Popup", true)
	UI.face(p, table.clone(GLASS))
	;(p:FindFirstChild("Studs") :: any).Image = UI.Assets.StudsSquare
	-- reference screenshots: the panel is ~57% of the screen height
	new("UIScale", { Name = "PopupScale", Scale = UI.PopupScale, Parent = p })
	local io = opts.IconOffset or Vector2.new(-57, -60)
	UI.image(opts.Icon, { Name = "Icon", Parent = p, Size = UDim2.fromOffset(192, 192), Position = UDim2.fromOffset(io.X, io.Y), ZIndex = 8 })
	UI.text({
		Name = "Title",
		Parent = p,
		Text = opts.Title or "Title",
		TextSize = 80,
		Shadow = true,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -55),
		Size = UDim2.new(1, -400, 0, 97),
		ZIndex = 9,
	})
	-- close: flat red, 20px corners, 50% black outline, white "x"
	local close, cv = button("Close", 88, 88, { Color = UI.Colors.CloseRed, ShadeAlpha = 0, StudAlpha = 0 })
	cv:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 20)
	for _, c in cv:GetChildren() do
		if c:IsA("GuiObject") then
			c.Visible = false -- no shade or studs on the close button
		end
	end
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, 30, 0, -29)
	close.ZIndex = 9
	UI.text({
		Name = "X",
		Parent = cv,
		Text = "x",
		TextSize = 64,
		StrokeColor = Color3.new(0, 0, 0),
		StrokeTransparency = 0.5,
		Stroke = 3,
		Position = UDim2.fromOffset(0, -6),
		ZIndex = 10,
	})
	close.Parent = p
	p.Parent = opts.Parent
	return p
end

-- a coloured face block (no button) at panel coordinates
local function block(parent, name, x, y, w, h, style)
	local f = new("Frame", { Name = name, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ZIndex = 4, Parent = parent })
	UI.face(f, style)
	return f
end

--[[ Shop offer placeholder (Figma Offer): light grey card, 3px black outline,
	white glow inside the edge. opts: Name, Height, LayoutOrder, Parent ]]
function UI.offer(opts)
	local f = new("Frame", {
		Name = opts.Name or "Offer",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, opts.Height or 229),
		LayoutOrder = opts.LayoutOrder or 0,
		ZIndex = 4,
		Parent = opts.Parent,
	})
	local st = new("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0), Parent = f })
	pcall(function()
		(st :: any).BorderStrokePosition = Enum.BorderStrokePosition.Inner
	end)
	-- Figma: inner shadow white, blur 16, spread 16 -> grey inset with a soft edge
	local fill = new("Frame", {
		Name = "Fill",
		BackgroundColor3 = UI.Colors.OfferGrey,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -40, 1, -40),
		ZIndex = 4,
		Parent = f,
	})
	corner(fill, 10)
	new("UIStroke", { Thickness = 6, Color = rgb(236, 236, 236), Parent = fill })
	return f
end

--[[ Shop popup (Figma 8:141): panel 1028x621, "~Section~" header and offer
	cards in a scrolling list. Returns popup, list (add more sections/offers). ]]
function UI.shopPopup(opts)
	local p = UI.popup({
		Name = opts.Name or "ShopPopup",
		Title = opts.Title or "Shop",
		Icon = UI.Assets.Shop,
		Width = 1028,
		Height = 621,
		IconOffset = Vector2.new(-41, -73),
		Visible = opts.Visible,
		Parent = opts.Parent,
	})
	local list = new("ScrollingFrame", {
		Name = "List",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 103),
		Size = UDim2.new(1, -32, 1, -106),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.new(1, 1, 1),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 4,
		Parent = p,
	})
	new("UIListLayout", { Padding = UDim.new(0, 18), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local sections = opts.Sections or { { Title = "~Section~", Offers = { 229, 195 } } }
	local order = 0
	for si, sec in sections do
		order += 1
		UI.text({
			Name = "Section" .. si,
			Parent = list,
			Text = sec.Title,
			TextSize = 48,
			Shadow = true,
			Size = UDim2.new(1, 0, 0, 58),
			ZIndex = 6,
		}).LayoutOrder = order
		for oi, oh in sec.Offers do
			order += 1
			UI.offer({ Name = ("Offer%d_%d"):format(si, oi), Height = oh, LayoutOrder = order, Parent = list })
		end
	end
	return p, list
end

--[[ Rebirth popup (Figma 8:165): panel 846x621. Before/After skill boxes, the
	reset warning, a level bar and REBIRTH / SKIP buttons. Update from code:
	Before.Amount, After.Amount, Level.Label (TextLabels), Rebirth / Skip
	(buttons, connect .Activated). opts: Name, Title, Icon, Before, After,
	Level, Visible, Parent ]]
function UI.rebirthPopup(opts)
	local C, A = UI.Colors, UI.Assets
	local p = UI.popup({
		Name = opts.Name or "RebirthPopup",
		Title = opts.Title or "Rebirth",
		Icon = opts.Icon or A.Rebirth,
		Width = 846,
		Height = 621,
		Visible = opts.Visible,
		Parent = opts.Parent,
	})
	local yellow = { Color = C.Yellow, Shade = C.ShadeRed, ShadeFrom = 0, ShadeAlpha = 0.4, Studs = A.Studs }
	for i, side in { { "Before", 96, opts.Before or "x6 SKILL" }, { "After", 481, opts.After or "x7 SKILL" } } do
		UI.text({
			Name = side[1] .. "Title",
			Parent = p,
			Text = side[1],
			TextSize = 48,
			Shadow = true,
			Position = UDim2.fromOffset(side[2], 105),
			Size = UDim2.fromOffset(278, 58),
			ZIndex = 6,
		})
		local box = block(p, side[1], side[2], 183, 278, 121, yellow)
		UI.image(A.Muscle, { Parent = box, Size = UDim2.fromOffset(96, 96), Position = UDim2.fromOffset(12, 13), ZIndex = 5 })
		UI.text({
			Name = "Amount",
			Parent = box,
			Text = side[3],
			TextSize = 36,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(108, 39),
			Size = UDim2.fromOffset(160, 44),
			ZIndex = 6,
		})
	end
	UI.text({ Name = "Arrow", Parent = p, Text = ">", TextSize = 48, Shadow = true, Position = UDim2.fromOffset(412, 215), Size = UDim2.fromOffset(31, 58), ZIndex = 6 })
	UI.text({
		Name = "ResetWarn",
		Parent = p,
		Text = "Resets LEVEL and SKILL",
		TextSize = 48,
		TextColor3 = C.CloseRed,
		Shadow = true,
		Position = UDim2.fromOffset(77, 326),
		Size = UDim2.fromOffset(682, 58),
		ZIndex = 6,
	})
	local lvl = block(p, "Level", 77, 394, 682, 96, { Color = C.Blue, Shade = C.ShadeBlue, ShadeFrom = 0, ShadeAlpha = 0.4, Studs = A.Studs })
	UI.text({ Name = "Label", Parent = lvl, Text = opts.Level or "Level 80 / Level 125", TextSize = 48, ZIndex = 6 })
	for _, bt in {
		{ "Rebirth", "REBIRTH", 77, C.Green, C.ShadeSky },
		{ "Skip", "SKIP", 426, C.Violet, C.ShadeViolet },
	} do
		local b, v = button(bt[1], 333, 74, { Color = bt[4], Shade = bt[5], ShadeFrom = 0, ShadeAlpha = 0.4, Studs = A.Studs })
		b.Position = UDim2.fromOffset(bt[3], 500)
		b.ZIndex = 4
		UI.text({ Name = "Label", Parent = v, Text = bt[2], TextSize = 36, ZIndex = 6 })
		b.Parent = p
	end
	return p
end

-- LocalScript placed in the demo HUD: scales the HUD to the screen, animates
-- every button, wires Opens / Close, and runs the popup transitions.
UI.ControllerSource = [[
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local gui = script.Parent
local camera = workspace.CurrentCamera

-- the layout is drawn at Figma size for a screen RefHeight px tall (sized so
-- the HUD takes the share of the screen it does in QM's layout reference)
local autoScale = gui:FindFirstChild("AutoScale")
local refHeight = gui:GetAttribute("RefHeight") or 1300
local function rescale()
	if autoScale then
		autoScale.Scale = math.clamp(camera.ViewportSize.Y / refHeight, 0.3, 1.6)
	end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
rescale()

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

--------------------------------------------------------------------------------
-- Popups: glass background (blur + light tint), the HUD slides out to its
-- nearest edge (groups with a Slide attribute: Left / Right / Down) and the
-- popup pops in from its centre. Closing plays it backwards.
--------------------------------------------------------------------------------
local blur = Lighting:FindFirstChild("PopupBlur") or Instance.new("BlurEffect")
blur.Name = "PopupBlur"
blur.Size = 0
blur.Parent = Lighting

local glassGui = Instance.new("ScreenGui")
glassGui.Name = "PopupGlass"
glassGui.IgnoreGuiInset = true
glassGui.ResetOnSpawn = false
glassGui.DisplayOrder = gui.DisplayOrder - 1
local glass = Instance.new("Frame")
glass.Name = "Glass"
glass.Size = UDim2.fromScale(1, 1)
glass.BackgroundColor3 = Color3.fromRGB(235, 245, 255)
glass.BackgroundTransparency = 1
glass.BorderSizePixel = 0
glass.Parent = glassGui
glassGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local slides = {}
for _, g in gui:GetDescendants() do
	local dir = g:GetAttribute("Slide")
	if dir and g:IsA("GuiObject") then
		local home = g.Position
		local away = if dir == "Left" then home - UDim2.fromScale(0.6, 0)
			elseif dir == "Right" then home + UDim2.fromScale(0.6, 0)
			else home + UDim2.fromScale(0, 0.6)
		table.insert(slides, { g = g, home = home, away = away })
	end
end

local popups = {}
for _, d in gui:GetDescendants() do
	if d:IsA("GuiObject") and d:GetAttribute("Popup") then
		local s = d:FindFirstChild("PopupScale")
		popups[d] = { scale = s, base = s and s.Scale or 1, open = d.Visible }
	end
end

local hudHidden = nil
local function refresh()
	local open = false
	for _, st in popups do
		open = open or st.open
	end
	if open == hudHidden then
		return
	end
	hudHidden = open
	tween(blur, 0.25, { Size = if open then 18 else 0 })
	tween(glass, 0.25, { BackgroundTransparency = if open then 0.8 else 1 })
	for _, sl in slides do
		if open then
			tween(sl.g, 0.3, { Position = sl.away }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		else
			tween(sl.g, 0.35, { Position = sl.home }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end
end

local closePopup
local function openPopup(p)
	local st = popups[p]
	for o, other in popups do
		if o ~= p and other.open then
			closePopup(o)
		end
	end
	st.open = true
	p.Visible = true
	if st.scale then
		st.scale.Scale = st.base * 0.2
		tween(st.scale, 0.35, { Scale = st.base }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	refresh()
end
function closePopup(p)
	local st = popups[p]
	if not st.open then
		return
	end
	st.open = false
	if st.scale then
		local tw = tween(st.scale, 0.2, { Scale = st.base * 0.2 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tw.Completed:Connect(function()
			if not st.open then
				p.Visible = false
			end
		end)
	else
		p.Visible = false
	end
	refresh()
end

-- buttons: hover/press scale only the inner Visual (from its centre, nothing
-- else moves); Opens toggles a popup (or any frame); Close closes its parent
local function hook(b)
	if not b:IsA("GuiButton") then
		return
	end
	local visual = b:FindFirstChild("Visual")
	local s = visual and visual:FindFirstChild("PressScale")
	if s then
		local function to(v)
			tween(s, 0.08, { Scale = v })
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
			if m and popups[m] then
				if popups[m].open then
					closePopup(m)
				else
					openPopup(m)
				end
			elseif m then
				m.Visible = not m.Visible
			end
		end)
	end
	if b.Name == "Close" and b.Parent and b.Parent:IsA("GuiObject") then
		b.Activated:Connect(function()
			if popups[b.Parent] then
				closePopup(b.Parent)
			else
				b.Parent.Visible = false
			end
		end)
	end
end

for _, d in gui:GetDescendants() do
	hook(d)
end
gui.DescendantAdded:Connect(hook)
refresh()
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

	gui:SetAttribute("RefHeight", UI.RefHeight)

	-- left: Shop over a 2x3 grid of see-through square buttons, 8px gaps. Positions
	-- are fractions of the screen taken from QM's reference screenshot.
	local left = new("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 24, 0.306, 0), -- Shop top at 30.6% of the screen height
		Size = UDim2.fromOffset(264, 96 + 8 + 128 * 3 + 8 * 2),
		Parent = gui,
	})
	left:SetAttribute("Slide", "Left") -- slides off this way while a popup is open
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
	UI.rectButton({ Name = "Shop", Text = "Shop", Icon = A.Shop, Color = C.ShopGold, Opens = "ShopPopup", LayoutOrder = 1, Parent = left })
	local grid = new("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.fromOffset(264, 128 * 3 + 8 * 2), LayoutOrder = 2, ZIndex = 2, Parent = left })
	-- ZIndex 2: the Rebirth badge pokes up over the Shop button's bottom edge
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(128, 128),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	local squares = {
		{ "Auras", A.Aura },
		{ "Rebirth", A.Rebirth, "97%", "RebirthPopup" },
		{ "Pets", A.Pet },
		{ "Trails", A.Trails },
		{ "Inventory", A.Inventory },
		{ "Gifts", A.Gifts, nil, nil, true },
	}
	for i, sq in squares do
		UI.squareButton({ Name = sq[1], Icon = sq[2], Badge = sq[3], Opens = sq[4], Notify = sq[5], LayoutOrder = i, Parent = grid })
	end

	-- bottom-left: counters, trophy first (Figma v2), 8px apart
	local counters = new("Frame", {
		Name = "Counters",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -86), -- trophy bottom ~98 px above a 1488 px screen's edge
		Size = UDim2.fromOffset(240, 70 * 2 + 8),
		Parent = gui,
	})
	counters:SetAttribute("Slide", "Left") -- slides off this way while a popup is open
	new("UIScale", { Name = "GroupScale", Scale = UI.CounterScale, Parent = counters })
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = counters,
	})
	UI.counter({ Name = "Wins", Icon = A.Trophy, Text = "5K", TextColor = C.Gold, LayoutOrder = 1, Parent = counters })
	UI.counter({ Name = "Rebirths", Icon = A.Rebirth, Text = "2", TextColor = C.Ice, LayoutOrder = 2, Parent = counters })

	-- bottom-centre: skill + level bar, buy buttons under it (bottom ~48 px
	-- above the edge of a 1488 px screen, labels hanging into that margin)
	local bottom = new("Frame", {
		Name = "Bottom",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -22), -- QM: closer to the bottom
		Size = UDim2.fromOffset(UI.BarWidth, 161 + 12 + 74),
		Parent = gui,
	})
	bottom:SetAttribute("Slide", "Down") -- slides off this way while a popup is open
	new("UIScale", { Name = "GroupScale", Scale = UI.BottomScale, Parent = bottom })
	UI.progress({ Name = "Progress", Skill = "1.2M", Multiplier = "7x", Level = 80, Value = "1.2k/3.05k", Fill = 0.39, Parent = bottom })
	local buys = new("Frame", {
		Name = "Buy",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 74),
		ZIndex = 2,
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

	-- popups (Figma v3): Shop opens ShopPopup, the Rebirth square RebirthPopup
	UI.shopPopup({ Visible = modalVisible == true, Parent = gui })
	UI.rebirthPopup({ Parent = gui })

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
	UI.rectButton({ Name = "RectangleButton", Text = "Shop", Icon = A.Shop, Color = C.Yellow, Parent = folder })
	UI.squareButton({ Name = "SquareButton", Icon = A.Aura, Parent = folder })
	UI.counter({ Name = "Counter", Icon = A.Trophy, Text = "5K", Parent = folder })
	UI.progress({ Name = "Progress", Parent = folder })
	UI.buyButton({ Name = "BuyButton", Text = "+10M", Parent = folder })
	UI.modal({ Name = "Modal", Title = "Title", Parent = folder })
	UI.popup({ Name = "Popup", Title = "Title", Icon = A.Shop, Parent = folder })
	UI.shopPopup({ Name = "ShopPopup", Parent = folder })
	UI.rebirthPopup({ Name = "RebirthPopup", Parent = folder })
	local n = new("Frame", { Name = "NotificationHolder", BackgroundTransparency = 1, Size = UDim2.fromOffset(128, 128), Parent = folder })
	UI.notification(n)
	folder.Parent = parent
	return folder
end

return UI

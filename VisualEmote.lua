local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local VisualEmote = Instance.new("ScreenGui")
VisualEmote.Name = "VisualEmote"
VisualEmote.ResetOnSpawn = false
VisualEmote.IgnoreGuiInset = true
VisualEmote.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
VisualEmote.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
VisualEmote.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.50, 0.50)
MainFrame.Size = UDim2.new(0.20, 0.00, 0.15, 0.00)
MainFrame.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
MainFrame.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
MainFrame.BorderSizePixel = 0
MainFrame.BackgroundColor3 = Color3.new(0.10, 0.10, 0.10)
MainFrame.Parent = VisualEmote

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.10, 0.00)
UICorner.Parent = MainFrame

local TopContainer = Instance.new("Frame")
TopContainer.Name = "TopContainer"
TopContainer.AnchorPoint = Vector2.new(0.50, 0.00)
TopContainer.Size = UDim2.new(1.00, 0.00, 0.20, 0.00)
TopContainer.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
TopContainer.Position = UDim2.new(0.50, 0.00, 0.00, 0.00)
TopContainer.BorderSizePixel = 0
TopContainer.BackgroundTransparency = 1
TopContainer.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
TopContainer.Parent = MainFrame

local DragUIButton = Instance.new("ImageButton")
DragUIButton.Name = "DragUIButton"
DragUIButton.BorderSizePixel = 0
DragUIButton.BackgroundColor3 = Color3.new(0.39, 0.39, 0.39)
DragUIButton.AnchorPoint = Vector2.new(0.50, 0.50)
DragUIButton.Size = UDim2.new(0.95, 0.00, 0.60, 0.00)
DragUIButton.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
DragUIButton.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
DragUIButton.Parent = TopContainer

local UICorner_1 = Instance.new("UICorner")
UICorner_1.CornerRadius = UDim.new(0.40, 0.00)
UICorner_1.Parent = DragUIButton

local Frame = Instance.new("Frame")
Frame.AnchorPoint = Vector2.new(0.50, 0.50)
Frame.Size = UDim2.new(0.40, 0.00, 0.20, 0.00)
Frame.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
Frame.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
Frame.BorderSizePixel = 0
Frame.BackgroundColor3 = Color3.new(0.49, 0.49, 0.49)
Frame.Parent = DragUIButton

local UICorner_2 = Instance.new("UICorner")
UICorner_2.CornerRadius = UDim.new(1.00, 0.00)
UICorner_2.Parent = Frame

local BottomContainer = Instance.new("Frame")
BottomContainer.Name = "BottomContainer"
BottomContainer.AnchorPoint = Vector2.new(0.50, 1.00)
BottomContainer.Size = UDim2.new(1.00, 0.00, 0.80, 0.00)
BottomContainer.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
BottomContainer.Position = UDim2.new(0.50, 0.00, 1.00, 0.00)
BottomContainer.BorderSizePixel = 0
BottomContainer.BackgroundTransparency = 1
BottomContainer.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
BottomContainer.Parent = MainFrame

local Object1 = Instance.new("Frame")
Object1.Name = "Object1"
Object1.AnchorPoint = Vector2.new(0.50, 0.00)
Object1.Size = UDim2.new(1.00, 0.00, 0.33, 0.00)
Object1.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
Object1.Position = UDim2.new(0.50, 0.00, 0.00, 0.00)
Object1.BorderSizePixel = 0
Object1.BackgroundTransparency = 1
Object1.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
Object1.Parent = BottomContainer

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.AnchorPoint = Vector2.new(0.50, 0.50)
Container.Size = UDim2.new(0.95, 0.00, 0.80, 0.00)
Container.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
Container.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
Container.BorderSizePixel = 0
Container.BackgroundColor3 = Color3.new(0.20, 0.20, 0.20)
Container.Parent = Object1

local UICorner_3 = Instance.new("UICorner")
UICorner_3.CornerRadius = UDim.new(0.20, 0.00)
UICorner_3.Parent = Container

local TextBox = Instance.new("TextBox")
TextBox.TextWrapped = true
TextBox.BorderSizePixel = 0
TextBox.TextScaled = true
TextBox.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
TextBox.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
TextBox.AnchorPoint = Vector2.new(0.50, 0.50)
TextBox.TextSize = 14
TextBox.Size = UDim2.new(1.00, 0.00, 0.60, 0.00)
TextBox.TextColor3 = Color3.new(1.00, 1.00, 1.00)
TextBox.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
TextBox.Text = ""
TextBox.PlaceholderText = "Target 1"
TextBox.BackgroundTransparency = 1
TextBox.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
TextBox.Parent = Container

local Object2 = Instance.new("Frame")
Object2.Name = "Object2"
Object2.AnchorPoint = Vector2.new(0.50, 0.50)
Object2.Size = UDim2.new(1.00, 0.00, 0.33, 0.00)
Object2.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
Object2.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
Object2.BorderSizePixel = 0
Object2.BackgroundTransparency = 1
Object2.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
Object2.Parent = BottomContainer

local Container_1 = Instance.new("Frame")
Container_1.Name = "Container"
Container_1.AnchorPoint = Vector2.new(0.50, 0.50)
Container_1.Size = UDim2.new(0.95, 0.00, 0.80, 0.00)
Container_1.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
Container_1.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
Container_1.BorderSizePixel = 0
Container_1.BackgroundColor3 = Color3.new(0.20, 0.20, 0.20)
Container_1.Parent = Object2

local UICorner_4 = Instance.new("UICorner")
UICorner_4.CornerRadius = UDim.new(0.20, 0.00)
UICorner_4.Parent = Container_1

local TextBox_1 = Instance.new("TextBox")
TextBox_1.TextWrapped = true
TextBox_1.BorderSizePixel = 0
TextBox_1.TextScaled = true
TextBox_1.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
TextBox_1.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
TextBox_1.AnchorPoint = Vector2.new(0.50, 0.50)
TextBox_1.TextSize = 14
TextBox_1.Size = UDim2.new(1.00, 0.00, 0.60, 0.00)
TextBox_1.TextColor3 = Color3.new(1.00, 1.00, 1.00)
TextBox_1.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
TextBox_1.Text = "" 
TextBox_1.PlaceholderText = "Target 2"
TextBox_1.BackgroundTransparency = 1
TextBox_1.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
TextBox_1.Parent = Container_1

local ButtonFrame = Instance.new("Frame")
ButtonFrame.Name = "ButtonFrame"
ButtonFrame.AnchorPoint = Vector2.new(0.50, 1.00)
ButtonFrame.Size = UDim2.new(1.00, 0.00, 0.33, 0.00)
ButtonFrame.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
ButtonFrame.Position = UDim2.new(0.50, 0.00, 1.00, 0.00)
ButtonFrame.BorderSizePixel = 0
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
ButtonFrame.Parent = BottomContainer

local ExecuteButton = Instance.new("ImageButton")
ExecuteButton.Name = "ExecuteButton"
ExecuteButton.BorderSizePixel = 0
ExecuteButton.BackgroundColor3 = Color3.new(0.00, 0.59, 0.00)
ExecuteButton.AnchorPoint = Vector2.new(0.50, 0.50)
ExecuteButton.Size = UDim2.new(0.95, 0.00, 0.60, 0.00)
ExecuteButton.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
ExecuteButton.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
ExecuteButton.Parent = ButtonFrame

local UICorner_5 = Instance.new("UICorner")
UICorner_5.CornerRadius = UDim.new(0.40, 0.00)
UICorner_5.Parent = ExecuteButton

local ExecuteText = Instance.new("TextLabel")
ExecuteText.Name = "ExecuteText"
ExecuteText.TextWrapped = true
ExecuteText.BorderSizePixel = 0
ExecuteText.TextScaled = true
ExecuteText.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
ExecuteText.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
ExecuteText.AnchorPoint = Vector2.new(0.50, 0.50)
ExecuteText.TextSize = 14
ExecuteText.Size = UDim2.new(1.00, 0.00, 0.75, 0.00)
ExecuteText.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
ExecuteText.Text = "Execute"
ExecuteText.TextColor3 = Color3.new(1.00, 1.00, 1.00)
ExecuteText.BackgroundTransparency = 1
ExecuteText.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
ExecuteText.Parent = ExecuteButton 

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
	local delta = input.Position - dragStart
	MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

DragUIButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

DragUIButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

local DaftarPath = {
	-- Shop
	"ReplicatedStorage.Items.BaseItems.Emotes.Addendum",
	"ReplicatedStorage.Items.BaseItems.Emotes.Aerobics",
	"ReplicatedStorage.Items.BaseItems.Emotes.Beg",
	"ReplicatedStorage.Items.BaseItems.Emotes.BoldMarch",
	"ReplicatedStorage.Items.BaseItems.Emotes.Breakdown",
	"ReplicatedStorage.Items.BaseItems.Emotes.BumperKart",
	"ReplicatedStorage.Items.BaseItems.Emotes.California",
	"ReplicatedStorage.Items.BaseItems.Emotes.Caramelldansen",
	"ReplicatedStorage.Items.BaseItems.Emotes.Carlton",
	"ReplicatedStorage.Items.BaseItems.Emotes.Catdown",
	"ReplicatedStorage.Items.BaseItems.Emotes.Clap",
	"ReplicatedStorage.Items.BaseItems.Emotes.ClubDance",
	"ReplicatedStorage.Items.BaseItems.Emotes.Conga",
	"ReplicatedStorage.Items.BaseItems.Emotes.Crabby",
	"ReplicatedStorage.Items.BaseItems.Emotes.CrounchDance",
	"ReplicatedStorage.Items.BaseItems.Emotes.Distraction",
	"ReplicatedStorage.Items.BaseItems.Emotes.Epicaricacy",
	"ReplicatedStorage.Items.BaseItems.Emotes.Facepalm",
	"ReplicatedStorage.Items.BaseItems.Emotes.Flexing",
	"ReplicatedStorage.Items.BaseItems.Emotes.Freestyle",
	"ReplicatedStorage.Items.BaseItems.Emotes.Gmod",
	"ReplicatedStorage.Items.BaseItems.Emotes.GoofyStride",
	"ReplicatedStorage.Items.BaseItems.Emotes.Gyrating",
	"ReplicatedStorage.Items.BaseItems.Emotes.Heaventaker",
	"ReplicatedStorage.Items.BaseItems.Emotes.Hired",
	"ReplicatedStorage.Items.BaseItems.Emotes.Infectious",
	"ReplicatedStorage.Items.BaseItems.Emotes.LittleJiggy",
	"ReplicatedStorage.Items.BaseItems.Emotes.Nostalgia",
	"ReplicatedStorage.Items.BaseItems.Emotes.PBJT",
	"ReplicatedStorage.Items.BaseItems.Emotes.PonPon",
	"ReplicatedStorage.Items.BaseItems.Emotes.Rambunctious",
	"ReplicatedStorage.Items.BaseItems.Emotes.RussianDance",
	"ReplicatedStorage.Items.BaseItems.Emotes.Sit",
	"ReplicatedStorage.Items.BaseItems.Emotes.Sleep",
	"ReplicatedStorage.Items.BaseItems.Emotes.Smug",
	"ReplicatedStorage.Items.BaseItems.Emotes.Stride",
	"ReplicatedStorage.Items.BaseItems.Emotes.SwagWalk",
	"ReplicatedStorage.Items.BaseItems.Emotes.TexasStyle",
	"ReplicatedStorage.Items.BaseItems.Emotes.ZenSerenity",

	-- Daily Shop
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.APose",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.BoogieDown",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.BringItAround",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Catjam",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.CompanyMan",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Fazbore",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.FlashingLights",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Kickback",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.LineDance",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.LunarParty",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.MaracaTime",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Mashle",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Moonwalk",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Nizmoo",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.ParkerPride",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.PawsClaws",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Popipopi",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Robot",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.RushinAround",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.SeeTinh",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.SeriousMarch",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.Smile",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.SpookyTime",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.StarPower",
	"ReplicatedStorage.Items.ItemPacks.Base.DailyShop.Emotes.TPose",

	-- Level Shop
	"ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Banger",
	"ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.GalacticBound",
	"ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.GamingTime",
	"ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.HeliosChariot",
	"ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Outlaw",
	"ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.StealthyBox",
	"ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.TouchGrass",
	"ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Writhing",

	-- New Shop
	"ReplicatedStorage.Items.ItemPacks.Base.NewShop.Emotes.Popular",
	"ReplicatedStorage.Items.ItemPacks.Base.NewShop.Emotes.SightlessDance",

	-- Special
	"ReplicatedStorage.Items.ItemPacks.Base.Special.Emotes.Bhop",

	-- Collab ST
	"ReplicatedStorage.Items.ItemPacks.Collab.ST.Emotes.WinterOf85",

	-- Halloween 2022
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Broom",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.FrightFunk",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.PumpItUp",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Reanimated",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.RockinStride",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Thriller",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.WerewolfHowl",

	-- Halloween 2024
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.CyberBroom",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.DeadBoneStride",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.GhastlyGrimoire",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.GhoulishGalleon",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.HeadlessBaller",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.Xylobone",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.ZombieStride",

	-- Halloween 2025
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.CuerdasDelAlma",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.GraveRider",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.HeadlessHorseman",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.MariachiBand",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.ScorchedEarth",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.SpiritedAway",

    -- Xmas 2022
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.CampfireDoze",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.ChristmasBoogie",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.FlyingSleigh",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.Marching",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.Nutcracker",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.SnowmobileCruise",
	"ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.WindupDance",

	-- Xmas 2024
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.BobointheBox",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.IceFishing",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.RudolphMount",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SantaMech",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SledDrifting",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SnowmanConstruction",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.ToyTrainRide",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.WindUpPose",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.WinterRide",

	-- Xmas 2025
	"ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.CozyChair",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.FrostDrake",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.RockingHorse",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.SkiSpree",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.WinterMelody",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.DailyShop.SnowAngel",

	-- St Patricks 2024
	"ReplicatedStorage.Items.ItemPacks.Events.2024.StPatricks2024.Emotes.AvariceLounge",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.StPatricks2024.Emotes.IrishJig",

	-- St Patricks 2025
	"ReplicatedStorage.Items.ItemPacks.Events.2025.StPatricks2025.Emotes.AprilShower",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.StPatricks2025.Emotes.GoldRitual",

	-- St Patricks 2026
	"ReplicatedStorage.Items.ItemPacks.Events.2026.StPatricks2026.Emotes.AuspiciousWell",

	-- Valentines 2024
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Valentines2024.Emotes.AngelicWings",
	"ReplicatedStorage.Items.ItemPacks.Events.2024.Valentines2024.Emotes.HarpRecital",

	-- Valentines 2025
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Valentines2025.Emotes.SerenePerch",

	-- Valentines 2026
	"ReplicatedStorage.Items.ItemPacks.Events.2026.Valentines2026.Emotes.DreamyCloud",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.Valentines2026.Emotes.ValentineComputer",

	-- Summer 2025
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.BeachChairLounge",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.CasualSurfing",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.LemonadeStand",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.ManyFans",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.PoolTime",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.RowBoat",
	"ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.SummerDays",

	-- Summer 2025
	"ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.AquaticDaydreamer",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.AstralMantaRay",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.ClamClamor",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.EncapsulatedBubble",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.FrutigerFloatie",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.LeapingDolphin",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.SubmarineRide",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.SummerLowrider",

	-- Spring 2026
	"ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.CoccoonRebirth",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.HoneyPool",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.LadybugFlight",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.LotusSwing",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.MegaflyJet",
	"ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.SnailMail",

	-- Lunar New Year
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.LunarNewYear.Emotes.DynastyDrumming",

	-- New Years 2024
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.NewYears2024.Emotes.FireworkBlast",

	-- Old Roblox
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicDance",
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicJeep",
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicStride",
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.FastFoodDelight",
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.PotionMash",
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.RainingTacos",
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.SkateboardStroll",

	-- Thanks Giving 2025
	"ReplicatedStorage.Items.ItemPacks.EventsDailyShop.Thanksgiving2025.Emotes.TurkeyJockey",

	-- Bee Set
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.QueensAppearance",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.RegalWalk",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.WingedRoyalSit",

	-- Posseidon Set
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.MountedSeahorse",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.NeptunesThrone",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.ShellHermit",

	-- Relic Emotes New
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.AstroSlide",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.BananaDance",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.CrabRave",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.CuddleBearSit",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.HitTheJackpot",

	-- Military 
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.Military.Emotes.Rocket",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.Military.Emotes.Tank",

	-- St Patricks 2023
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.StPatricks2023.Emotes.MarchShowcase",

	-- Animals
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.DuckyMarch",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.Sleepybara",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.TurtleHobble",

	-- Cats
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Cats.Emotes.CatParty",

	-- Dog Set
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.DogSet.Emotes.DogParty",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.DogSet.Emotes.FreshFlop",

	-- Eclipse Set
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarBike",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarConqueror",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarSlayer",

	-- Emote Pack
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Boneless",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Gangnam",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Griddy",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.LDance",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Macarena",

	-- Gems
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Gems.Emotes.HoveringCrystal",

	-- Lunar New Year Set
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.LunarNewYearSet.Emotes.FlyingFish",

	-- Music Emote Pack 1
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Caffeinated",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.CatDance",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Frolic",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.OiiaOiia",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Wess",

	-- Relic Emotes Vaulted
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.Bumblebee",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.RockefellerStreet",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.ShubaDance",
	"ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.Twist",

	-- Megan
	"ReplicatedStorage.Items.ItemPacks.Integration.M3GAN.Emotes.M3GANDance",
	"ReplicatedStorage.Items.ItemPacks.Integration.M3GAN.Emotes.RobotM3GAN",
}

local mapObject = {} 
local historyParent = {} 
local activeSwaps = {} 

for _, pathString in ipairs(DaftarPath) do
	local parts = string.split(pathString, ".")
	local lastName = parts[#parts]
	mapObject[string.lower(lastName)] = pathString
end

local function getObject(pathString)
	local parts = string.split(pathString, ".")
	local current = game
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then return nil end
	end
	return current
end

local function getPairKey(val1, val2)
	if val1 < val2 then
		return val1 .. "|" .. val2
	else
		return val2 .. "|" .. val1
	end
end

local function updateButtonState()
	local t1 = string.lower(TextBox.Text)
	local t2 = string.lower(TextBox_1.Text)
	
	if t1 ~= "" and t2 ~= "" and t1 ~= t2 then
		local pairKey = getPairKey(t1, t2)
		if activeSwaps[pairKey] then
			ExecuteText.Text = "Recover"
			ExecuteButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		else
			ExecuteText.Text = "Execute"
			ExecuteButton.BackgroundColor3 = Color3.new(0.00, 0.59, 0.00)
		end
	else
		ExecuteText.Text = "Execute"
		ExecuteButton.BackgroundColor3 = Color3.new(0.00, 0.59, 0.00)
	end
end

TextBox:GetPropertyChangedSignal("Text"):Connect(updateButtonState)
TextBox_1:GetPropertyChangedSignal("Text"):Connect(updateButtonState)

ExecuteButton.MouseButton1Click:Connect(function()
	local t1 = string.lower(TextBox.Text)
	local t2 = string.lower(TextBox_1.Text)
	
	if t1 == "" or t2 == "" or t1 == t2 then return end
	
	local path1 = mapObject[t1]
	local path2 = mapObject[t2]
	
	if not path1 or not path2 then
		warn("Object ga ada di DaftarPath bre!")
		return
	end
	
	local folder1 = getObject(path1)
	local folder2 = getObject(path2)
	
	if not folder1 or not folder2 then
		warn("Object ga ketemu di dalam game!")
		return
	end
	
	local pairKey = getPairKey(t1, t2)
	
	if activeSwaps[pairKey] then
		for _, child in ipairs(folder1:GetChildren()) do
			if historyParent[child] then
				child.Parent = historyParent[child]
			end
		end
		for _, child in ipairs(folder2:GetChildren()) do
			if historyParent[child] then
				child.Parent = historyParent[child]
			end
		end
		
		activeSwaps[pairKey] = nil
		print("Berhasil di-Recover: " .. t1 .. " & " .. t2)
	else
		-- SWAP
		for _, child in ipairs(folder1:GetChildren()) do
			if not historyParent[child] then historyParent[child] = folder1 end
			child.Parent = folder2
		end
		for _, child in ipairs(folder2:GetChildren()) do
			if not historyParent[child] then historyParent[child] = folder2 end
			child.Parent = folder1
		end
		
		activeSwaps[pairKey] = true
		print("Berhasil di-Swap: " .. t1 .. " & " .. t2)
	end
	
	TextBox.Text = ""
	TextBox_1.Text = ""
end)

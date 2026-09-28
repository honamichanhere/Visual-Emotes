local TARGET_PLACE_ID = 9872472334

if game.PlaceId ~= TARGET_PLACE_ID then
	warn("[Visual Emotes] Access denied. This script only for Evade!")
	return
end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local function ErrorHandler(errorMessage)
	warn("====================================")
	warn("[Visual Emotes] Error!")
	warn("Message: " .. tostring(errorMessage))
	warn(debug.traceback())
	warn("====================================")
end

-- ==========================================================
-- VisualEmotes
-- ==========================================================
local VisualEmotes = Instance.new("ScreenGui")
VisualEmotes.Name = "VisualEmotes"
VisualEmotes.IgnoreGuiInset = true
VisualEmotes.ResetOnSpawn = false
VisualEmotes.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local localPlayer = Players.LocalPlayer
if localPlayer then
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	VisualEmotes.Parent = playerGui
end

local onLoadingFinished = Instance.new("BindableEvent")
local triggerNotif = Instance.new("BindableEvent")

local success, result = xpcall(function()
	-- ==========================================================
	-- GLOBAL VARIABLES
	-- ==========================================================
	local UI_MainFrame 
	local UI_Template_Base
	local UI_Template_Target
	local UI_BaseScrolling
	local UI_TargetScrolling
	
	local UI_DragButton
	local UI_MinimizeButton
	local UI_CloseButton
	local UI_OpenButton
	local UI_BottomFrame
	local UI_UIStroke1
	local UI_UICornerMinimize
	local UI_MainUIScale
	local UI_OpenUIScale
	
	local SelectedBaseEmote = nil
	local SelectedTargetEmote = nil


	-- ==========================================================
	-- SCOPE 1: LOADING INTRO
	-- ==========================================================
	do
		local Loading = Instance.new("CanvasGroup")
		Loading.Name = "Loading"
		Loading.BorderSizePixel = 1
		Loading.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Loading.AnchorPoint = Vector2.new(0.50, 0.50)
		Loading.Size = UDim2.new(0.22, 0.00, 0.24, 0.00)
		Loading.BorderColor3 = Color3.new(0.40, 0.40, 0.40)
		Loading.BackgroundTransparency = 0
		Loading.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
		Loading.Visible = false
		Loading.Parent = VisualEmotes

		local LoadingGradient = Instance.new("UIGradient")
		LoadingGradient.Name = "LoadingGradient"
		LoadingGradient.Enabled = false
		LoadingGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 0.00, 0.00),
			NumberSequenceKeypoint.new(0.30, 0.00, 0.00),
			NumberSequenceKeypoint.new(0.60, 1.00, 0.00),
			NumberSequenceKeypoint.new(1.00, 1.00, 0.00)
		})
		LoadingGradient.Offset = Vector2.new(-1.00, 0.00)
		LoadingGradient.Rotation = 45
		LoadingGradient.Parent = Loading

		local IntroMainFrame = Instance.new("Frame")
		IntroMainFrame.Name = "IntroMainFrame"
		IntroMainFrame.AnchorPoint = Vector2.new(0.50, 0.50)
		IntroMainFrame.Size = UDim2.new(1.00, 0.00, 1.00, 0.00)
		IntroMainFrame.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		IntroMainFrame.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
		IntroMainFrame.BorderSizePixel = 0
		IntroMainFrame.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		IntroMainFrame.Parent = Loading

		local UIGradient1 = Instance.new("UIGradient")
		UIGradient1.Name = "UIGradient1"
		UIGradient1.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.new(0.10, 0.10, 0.10)), 
			ColorSequenceKeypoint.new(1.00, Color3.new(0.29, 0.29, 0.29))
		})
		UIGradient1.Rotation = -90
		UIGradient1.Parent = IntroMainFrame

		local Title = Instance.new("Frame")
		Title.Name = "Title"
		Title.ClipsDescendants = true
		Title.AnchorPoint = Vector2.new(0.0, 0.00)
		Title.Size = UDim2.new(1.00, 0.00, 0.27, 0.00)
		Title.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Title.Position = UDim2.new(0.0, 0.00, 0.15, 0.00)
		Title.BorderSizePixel = 0
		Title.ZIndex = 2
		Title.BackgroundTransparency = 1
		Title.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Title.Parent = IntroMainFrame

		local Title_1 = Instance.new("TextLabel")
		Title_1.Name = "Title"
		Title_1.TextWrapped = true
		Title_1.BorderSizePixel = 0
		Title_1.TextScaled = true
		Title_1.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Title_1.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		Title_1.AnchorPoint = Vector2.new(0.00, 0.00)
		Title_1.TextSize = 14
		Title_1.Size = UDim2.new(1.00, 0.00, 0.80, 0.00)
		Title_1.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Title_1.Text = "Visual Emotes"
		Title_1.TextColor3 = Color3.new(1.00, 1.00, 1.00)
		Title_1.BackgroundTransparency = 1
		Title_1.Position = UDim2.new(0.00, 0.00, 0.00, 0.00)
		Title_1.Parent = Title

		local Desc = Instance.new("TextLabel")
		Desc.Name = "Desc"
		Desc.TextWrapped = true
		Desc.BorderSizePixel = 0
		Desc.TextScaled = true
		Desc.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Desc.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		Desc.AnchorPoint = Vector2.new(0.00, 1.00)
		Desc.TextSize = 14
		Desc.Size = UDim2.new(1.00, 0.00, 0.30, 0.00)
		Desc.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Desc.Text = "- Swap your emote visually -"
		Desc.TextColor3 = Color3.new(1.00, 1.00, 1.00)
		Desc.BackgroundTransparency = 1
		Desc.Position = UDim2.new(0.00, 0.00, 1.00, 0.00)
		Desc.Parent = Title

		local LoadingBar = Instance.new("Frame")
		LoadingBar.Name = "LoadingBar"
		LoadingBar.AnchorPoint = Vector2.new(0.00, 0.50)
		LoadingBar.Size = UDim2.new(1.00, 0.00, 0.10, 0.00)
		LoadingBar.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		LoadingBar.Position = UDim2.new(0.00, 0.00, 0.65, 0.00)
		LoadingBar.BorderSizePixel = 0
		LoadingBar.ZIndex = 2
		LoadingBar.BackgroundTransparency = 1
		LoadingBar.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		LoadingBar.Parent = IntroMainFrame

		local LoadingText = Instance.new("TextLabel")
		LoadingText.Name = "LoadingText"
		LoadingText.TextWrapped = true
		LoadingText.BorderSizePixel = 0
		LoadingText.TextScaled = true
		LoadingText.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		LoadingText.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		LoadingText.AnchorPoint = Vector2.new(0.50, 0.00)
		LoadingText.TextXAlignment = Enum.TextXAlignment.Left
		LoadingText.TextSize = 14
		LoadingText.Size = UDim2.new(0.64, 0.00, 0.67, 0.00)
		LoadingText.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		LoadingText.Text = "Loading..."
		LoadingText.TextColor3 = Color3.new(1.00, 1.00, 1.00)
		LoadingText.BackgroundTransparency = 1
		LoadingText.Position = UDim2.new(0.50, 0.00, 0.00, 0.00)
		LoadingText.Parent = LoadingBar

		local Line = Instance.new("CanvasGroup")
		Line.Name = "Line"
		Line.BorderSizePixel = 0
		Line.BackgroundColor3 = Color3.new(0.29, 0.29, 0.29)
		Line.AnchorPoint = Vector2.new(0.50, 1.00)
		Line.Size = UDim2.new(0.66, 0.00, 0.20, 0.00)
		Line.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Line.Position = UDim2.new(0.50, 0.00, 1.00, 0.00)
		Line.Parent = LoadingBar

		local UICorner = Instance.new("UICorner")
		UICorner.CornerRadius = UDim.new(1.00, 0.00)
		UICorner.Parent = Line

		local Fill = Instance.new("Frame")
		Fill.Name = "Fill"
		Fill.AnchorPoint = Vector2.new(0.00, 0.50)
		Fill.Size = UDim2.new(0.50, 0.00, 1.00, 0.00)
		Fill.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Fill.Position = UDim2.new(0.00, 0.00, 0.50, 0.00)
		Fill.BorderSizePixel = 0
		Fill.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Fill.Parent = Line

		local UIGradient2 = Instance.new("UIGradient")
		UIGradient2.Name = "UIGradient2"
		UIGradient2.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.new(0.00, 0.00, 1.00)), 
			ColorSequenceKeypoint.new(1.00, Color3.new(0.00, 1.00, 1.00))
		})
		UIGradient2.Parent = Fill

		local Credit = Instance.new("Frame")
		Credit.Name = "Credit"
		Credit.AnchorPoint = Vector2.new(0.50, 1.00)
		Credit.Size = UDim2.new(0.92, 0.00, 0.13, 0.00)
		Credit.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Credit.Position = UDim2.new(0.50, 0.00, 0.95, 0.00)
		Credit.BorderSizePixel = 0
		Credit.ZIndex = 2
		Credit.BackgroundTransparency = 1
		Credit.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Credit.Parent = IntroMainFrame

		local Credit_1 = Instance.new("TextLabel")
		Credit_1.Name = "Credit"
		Credit_1.TextWrapped = true
		Credit_1.BorderSizePixel = 0
		Credit_1.TextScaled = true
		Credit_1.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Credit_1.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		Credit_1.AnchorPoint = Vector2.new(1.00, 1.00)
		Credit_1.TextXAlignment = Enum.TextXAlignment.Right
		Credit_1.TextSize = 14
		Credit_1.Size = UDim2.new(0.65, 0.00, 0.50, 0.00)
		Credit_1.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Credit_1.Text = "Developed by Honami"
		Credit_1.TextColor3 = Color3.new(1.00, 1.00, 1.00)
		Credit_1.BackgroundTransparency = 1
		Credit_1.Position = UDim2.new(1.00, 0.00, 1.00, 0.00)
		Credit_1.Parent = Credit

		local Version = Instance.new("TextLabel")
		Version.Name = "Version"
		Version.TextWrapped = true
		Version.BorderSizePixel = 0
		Version.TextScaled = true
		Version.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Version.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		Version.AnchorPoint = Vector2.new(1.00, 0.00)
		Version.TextXAlignment = Enum.TextXAlignment.Right
		Version.TextSize = 14
		Version.Size = UDim2.new(0.65, 0.00, 0.50, 0.00)
		Version.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Version.Text = "Version 1.0"
		Version.TextColor3 = Color3.new(1.00, 1.00, 1.00)
		Version.BackgroundTransparency = 1
		Version.Position = UDim2.new(1.00, 0.00, 0.00, 0.00)
		Version.Parent = Credit

		local Gradient = Instance.new("Frame")
		Gradient.Name = "Gradient"
		Gradient.AnchorPoint = Vector2.new(0.50, 0.50)
		Gradient.Size = UDim2.new(1.00, 0.00, 1.00, 0.00)
		Gradient.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
		Gradient.Position = UDim2.new(0.50, 0.00, 0.50, 0.00)
		Gradient.BorderSizePixel = 0
		Gradient.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
		Gradient.Parent = IntroMainFrame

		local UIGradient3 = Instance.new("UIGradient")
		UIGradient3.Name = "UIGradient3"
		UIGradient3.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.00, 0.00), 
			NumberSequenceKeypoint.new(0.50, 1.00, 0.00), 
			NumberSequenceKeypoint.new(0.50, 0.00, 0.00), 
			NumberSequenceKeypoint.new(1.00, 0.00, 0.00)
		})
		UIGradient3.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.new(0.00, 0.00, 0.00)), 
			ColorSequenceKeypoint.new(1.00, Color3.new(0.20, 0.20, 0.20))
		})
		UIGradient3.Rotation = 60
		UIGradient3.Parent = Gradient

		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		UIAspectRatioConstraint.AspectRatio = 1.7000000476837158
		UIAspectRatioConstraint.Parent = Loading

		LoadingGradient.Enabled = true
		LoadingGradient.Offset = Vector2.new(-1, 0)
		LoadingGradient.Rotation = 45 

		UIGradient3.Offset = Vector2.new(1, 0) 
		Title.AnchorPoint = Vector2.new(1, 0) 
		Desc.AnchorPoint = Vector2.new(1, 1)
		LoadingBar.AnchorPoint = Vector2.new(1, 0.5)
		Version.AnchorPoint = Vector2.new(0, 0)
		Credit_1.AnchorPoint = Vector2.new(0, 1)
		Fill.Size = UDim2.new(0, 0, 1, 0)

		task.spawn(function()
			local function tween(obj, time, props)
				local tw = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
				tw:Play()
				return tw
			end

			task.wait(1.0) 
			Loading.Visible = true

			tween(LoadingGradient, 1.0, {Offset = Vector2.new(1, 0)})
			tween(UIGradient3, 1.0, {Offset = Vector2.new(0, 0)}) 
			tween(Title, 1.0, {AnchorPoint = Vector2.new(0, 0)})
			task.wait(0.2) 
			tween(Desc, 1.0, {AnchorPoint = Vector2.new(0, 1)})
			task.wait(0.2) 
			LoadingGradient.Enabled = false
			LoadingGradient.Offset = Vector2.new(1, 0)
			tween(LoadingBar, 1.0, {AnchorPoint = Vector2.new(0, 0.5)})
			task.wait(0.2) 
			tween(Version, 1.0, {AnchorPoint = Vector2.new(1, 0)})
			task.wait(0.2) 
			tween(Credit_1, 1.0, {AnchorPoint = Vector2.new(1, 1)})
			task.wait(0.5) 

			local function stutterLoading()
				tween(Fill, 0.8, {Size = UDim2.new(0.3, 0, 1, 0)})
				task.wait(1.0) 
				tween(Fill, 0.6, {Size = UDim2.new(0.65, 0, 1, 0)})
				task.wait(0.8) 
				tween(Fill, 0.4, {Size = UDim2.new(0.9, 0, 1, 0)})
				task.wait(0.5) 
				tween(Fill, 0.4, {Size = UDim2.new(1, 0, 1, 0)})
			end
			stutterLoading()

			task.wait(0.5)
			LoadingText.Text = "Complete"
			task.wait(0.5)
			LoadingGradient.Enabled = true
			tween(LoadingGradient, 1.0, {Offset = Vector2.new(-1, 0)}) 
			task.wait(1.0)
			Loading:Destroy()
			onLoadingFinished:Fire()
		end)
	end


	-- ==========================================================
	-- SCOPE 2: GENERATE MAIN UI (Visual Emotes)
	-- ==========================================================
	do
		local MainFrame = Instance.new("CanvasGroup")
		MainFrame.Name = "MainFrame"
		MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		MainFrame.BackgroundTransparency = 1
		MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		MainFrame.BorderSizePixel = 0
		MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		MainFrame.Size = UDim2.new(0.34, 0, 0.44, 0)
		MainFrame.Visible = false 
		MainFrame.ClipsDescendants = true 
		MainFrame.Parent = VisualEmotes 
		UI_MainFrame = MainFrame

		local UIScale = Instance.new("UIScale")
		UIScale.Parent = MainFrame
		UI_MainUIScale = UIScale

		local TopFrame = Instance.new("Frame")
		TopFrame.Name = "TopFrame"
		TopFrame.AnchorPoint = Vector2.new(0.5, 0)
		TopFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TopFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TopFrame.BorderSizePixel = 0
		TopFrame.Position = UDim2.new(0.5, 0, 0, 0)
		TopFrame.Size = UDim2.new(1, 0, 0.125, 0)
        TopFrame.ZIndex = 2
		TopFrame.Parent = MainFrame

		local UICornerMinimize = Instance.new("UICorner")
		UICornerMinimize.Name = "UICornerMinimize"
		UICornerMinimize.CornerRadius = UDim.new(0, 0)
		UICornerMinimize.Parent = TopFrame
		UI_UICornerMinimize = UICornerMinimize

		local UICorner1 = Instance.new("UICorner")
		UICorner1.Name = "UICorner1"
		UICorner1.CornerRadius = UDim.new(0.03, 0)
		UICorner1.BottomLeftRadius = UDim.new(0.03, 0)
		UICorner1.BottomRightRadius = UDim.new(0.03, 0)
		UICorner1.TopLeftRadius = UDim.new(0.03, 0)
		UICorner1.TopRightRadius = UDim.new(0.03, 0)
		UICorner1.Parent = MainFrame

		local BottomFrame = Instance.new("Frame")
		BottomFrame.Name = "BottomFrame"
		BottomFrame.AnchorPoint = Vector2.new(0.5, 1)
		BottomFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BottomFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BottomFrame.BorderSizePixel = 0
		BottomFrame.Position = UDim2.new(0.5, 0, 1, 0)
		BottomFrame.Size = UDim2.new(1, 0, 0.875, 0)
		BottomFrame.Parent = MainFrame
		UI_BottomFrame = BottomFrame

		local UIStroke1 = Instance.new("UIStroke")
		UIStroke1.Name = "UIStroke1"
		UIStroke1.Color = Color3.fromRGB(150, 150, 150)
		UIStroke1.Transparency = 0.5
		UIStroke1.Thickness = 0.003
		UIStroke1.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke1.Parent = MainFrame
		UI_UIStroke1 = UIStroke1

		local UIAspectRatioConstraint1 = Instance.new("UIAspectRatioConstraint")
		UIAspectRatioConstraint1.Name = "UIAspectRatioConstraint1"
		UIAspectRatioConstraint1.AspectRatio = 1.15
		UIAspectRatioConstraint1.Parent = MainFrame

		local UIGradient = Instance.new("UIGradient")
		UIGradient.Rotation = 90
		UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 75, 75)), ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))})
		UIGradient.Parent = TopFrame

		local DragButton = Instance.new("ImageButton")
		DragButton.Name = "DragButton"
		DragButton.AnchorPoint = Vector2.new(0.5, 0.5)
		DragButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		DragButton.BackgroundTransparency = 1
		DragButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DragButton.BorderSizePixel = 0
		DragButton.Position = UDim2.new(0.5, 0, 0.5, 0)
		DragButton.Size = UDim2.new(1, 0, 1, 0)
		DragButton.Parent = TopFrame
		UI_DragButton = DragButton

		local IconContainer = Instance.new("Frame")
		IconContainer.Name = "IconContainer"
		IconContainer.AnchorPoint = Vector2.new(0, 0.5)
		IconContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		IconContainer.BackgroundTransparency = 1
		IconContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		IconContainer.BorderSizePixel = 0
		IconContainer.Position = UDim2.new(0, 0, 0.5, 0)
		IconContainer.Size = UDim2.new(0.1075, 0, 0.989, 0)
		IconContainer.Parent = TopFrame

		local MinimizeClose = Instance.new("Frame")
		MinimizeClose.Name = "MinimizeClose"
		MinimizeClose.AnchorPoint = Vector2.new(1, 0.5)
		MinimizeClose.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		MinimizeClose.BackgroundTransparency = 1
		MinimizeClose.BorderColor3 = Color3.fromRGB(0, 0, 0)
		MinimizeClose.BorderSizePixel = 0
		MinimizeClose.Position = UDim2.new(1, 0, 0.5, 0)
		MinimizeClose.Size = UDim2.new(0.215365, 0, 0.990678, 0)
		MinimizeClose.Parent = TopFrame

		local UIGradient_2 = Instance.new("UIGradient")
		UIGradient_2.Rotation = 90
		UIGradient_2.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 35, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))})
		UIGradient_2.Parent = BottomFrame

		local LeftContainer = Instance.new("Frame")
		LeftContainer.Name = "LeftContainer"
		LeftContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		LeftContainer.BackgroundTransparency = 1
		LeftContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		LeftContainer.BorderSizePixel = 0
		LeftContainer.Size = UDim2.new(0.485, 0, 0.85, 0)
		LeftContainer.Parent = BottomFrame

		local RightContainer = Instance.new("Frame")
		RightContainer.Name = "RightContainer"
		RightContainer.AnchorPoint = Vector2.new(1, 0)
		RightContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		RightContainer.BackgroundTransparency = 1
		RightContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RightContainer.BorderSizePixel = 0
		RightContainer.Position = UDim2.new(1, 0, 0, 0)
		RightContainer.Size = UDim2.new(0.485, 0, 0.85, 0)
		RightContainer.Parent = BottomFrame

		local Frame = Instance.new("Frame")
		Frame.AnchorPoint = Vector2.new(0.5, 1)
		Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Frame.BackgroundTransparency = 1
		Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Frame.BorderSizePixel = 0
		Frame.Position = UDim2.new(0.5, 0, 1, 0)
		Frame.Size = UDim2.new(1, 0, 0.15, 0)
		Frame.Parent = BottomFrame

		local ImageLabel = Instance.new("ImageLabel")
		ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageLabel.BackgroundTransparency = 1
		ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageLabel.BorderSizePixel = 0
		ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		ImageLabel.Size = UDim2.new(0.581395, 0, 0.581395, 0)
		ImageLabel.Image = "rbxassetid://81135873326242"
		ImageLabel.ImageColor3 = Color3.fromRGB(230, 230, 255)
		ImageLabel.Parent = IconContainer

		local TitleDesc = Instance.new("Frame")
		TitleDesc.Name = "TitleDesc"
		TitleDesc.AnchorPoint = Vector2.new(0, 0.5)
		TitleDesc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TitleDesc.BackgroundTransparency = 1
		TitleDesc.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleDesc.BorderSizePixel = 0
		TitleDesc.Position = UDim2.new(1, 0, 0.5, 0)
		TitleDesc.Size = UDim2.new(5.813953, 0, 0.697674, 0)
		TitleDesc.Parent = IconContainer

		local CloseContainer = Instance.new("Frame")
		CloseContainer.Name = "CloseContainer"
		CloseContainer.AnchorPoint = Vector2.new(1, 0.5)
		CloseContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		CloseContainer.BackgroundTransparency = 1
		CloseContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		CloseContainer.BorderSizePixel = 0
		CloseContainer.Position = UDim2.new(1, 0, 0.5, 0)
		CloseContainer.Size = UDim2.new(0.5, 0, 1, 0)
		CloseContainer.Parent = MinimizeClose

		local MinimizeContainer = Instance.new("Frame")
		MinimizeContainer.Name = "MinimizeContainer"
		MinimizeContainer.AnchorPoint = Vector2.new(0, 0.5)
		MinimizeContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		MinimizeContainer.BackgroundTransparency = 1
		MinimizeContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		MinimizeContainer.BorderSizePixel = 0
		MinimizeContainer.Position = UDim2.new(0, 0, 0.5, 0)
		MinimizeContainer.Size = UDim2.new(0.5, 0, 1, 0)
		MinimizeContainer.Parent = MinimizeClose

		local BaseEmote = Instance.new("CanvasGroup")
		BaseEmote.Name = "BaseEmote"
		BaseEmote.AnchorPoint = Vector2.new(1, 0.5)
		BaseEmote.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		BaseEmote.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BaseEmote.BorderSizePixel = 0
		BaseEmote.Position = UDim2.new(1, 0, 0.5, 0)
		BaseEmote.Size = UDim2.new(0.94, 0, 0.92, 0)
		BaseEmote.Parent = LeftContainer

		local TargetEmote = Instance.new("CanvasGroup")
		TargetEmote.Name = "TargetEmote"
		TargetEmote.AnchorPoint = Vector2.new(0, 0.5)
		TargetEmote.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		TargetEmote.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TargetEmote.BorderSizePixel = 0
		TargetEmote.Position = UDim2.new(0, 0, 0.5, 0)
		TargetEmote.Size = UDim2.new(0.94, 0, 0.92, 0)
		TargetEmote.Parent = RightContainer

		local SwapButton = Instance.new("ImageButton")
		SwapButton.Name = "SwapButton"
		SwapButton.AnchorPoint = Vector2.new(0.5, 0)
		SwapButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SwapButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SwapButton.BorderSizePixel = 0
		SwapButton.Position = UDim2.new(0.5, 0, 0, 0)
		SwapButton.Size = UDim2.new(0.375, 0, 0.766667, 0)
		SwapButton.Parent = Frame

		local TitleText = Instance.new("TextLabel")
		TitleText.Name = "TitleText"
		TitleText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TitleText.BackgroundTransparency = 1
		TitleText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleText.BorderSizePixel = 0
		TitleText.Size = UDim2.new(1, 0, 0.75, 0)
		TitleText.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		TitleText.Text = "Visual Emotes"
		TitleText.TextColor3 = Color3.fromRGB(230, 230, 255)
		TitleText.TextScaled = true
		TitleText.TextSize = 14
		TitleText.TextWrapped = true
		TitleText.TextXAlignment = Enum.TextXAlignment.Left
		TitleText.Parent = TitleDesc

		local DescText = Instance.new("TextLabel")
		DescText.Name = "DescText"
		DescText.AnchorPoint = Vector2.new(0, 1)
		DescText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		DescText.BackgroundTransparency = 1
		DescText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DescText.BorderSizePixel = 0
		DescText.Position = UDim2.new(0, 0, 1, 0)
		DescText.Size = UDim2.new(1, 0, 0.4, 0)
		DescText.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		DescText.Text = "Swap your emotes visually - Developed by Honami."
		DescText.TextColor3 = Color3.fromRGB(230, 230, 255)
		DescText.TextScaled = true
		DescText.TextSize = 14
		DescText.TextWrapped = true
		DescText.TextXAlignment = Enum.TextXAlignment.Left
		DescText.Parent = TitleDesc

		local CloseButton = Instance.new("ImageButton")
		CloseButton.Name = "CloseButton"
		CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
		CloseButton.BackgroundColor3 = Color3.fromRGB(175, 0, 0)
		CloseButton.BackgroundTransparency = 0.5
		CloseButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		CloseButton.BorderSizePixel = 0
		CloseButton.Position = UDim2.new(0.5, 0, 0.5, 0)
		CloseButton.Size = UDim2.new(0.697674, 0, 0.697674, 0)
		CloseButton.Parent = CloseContainer
		UI_CloseButton = CloseButton

		local MinimizeButton = Instance.new("ImageButton")
		MinimizeButton.Name = "MinimizeButton"
		MinimizeButton.AnchorPoint = Vector2.new(0.5, 0.5)
		MinimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		MinimizeButton.BackgroundTransparency = 0.5
		MinimizeButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		MinimizeButton.BorderSizePixel = 0
		MinimizeButton.Position = UDim2.new(0.5, 0, 0.5, 0)
		MinimizeButton.Size = UDim2.new(0.697674, 0, 0.697674, 0)
		MinimizeButton.Parent = MinimizeContainer
		UI_MinimizeButton = MinimizeButton

		local UICorner = Instance.new("UICorner")
		UICorner.CornerRadius = UDim.new(0.03, 0)
		UICorner.BottomLeftRadius = UDim.new(0.03, 0)
		UICorner.BottomRightRadius = UDim.new(0.03, 0)
		UICorner.TopLeftRadius = UDim.new(0.03, 0)
		UICorner.TopRightRadius = UDim.new(0.03, 0)
		UICorner.Parent = BaseEmote

		local UIStroke = Instance.new("UIStroke")
		UIStroke.Color = Color3.fromRGB(100, 100, 100)
		UIStroke.Transparency = 0.5
		UIStroke.Thickness = 0.0075
		UIStroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke.Parent = BaseEmote

		local SearchTitle = Instance.new("Frame")
		SearchTitle.Name = "SearchTitle"
		SearchTitle.AnchorPoint = Vector2.new(0.5, 0)
		SearchTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SearchTitle.BackgroundTransparency = 1
		SearchTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SearchTitle.BorderSizePixel = 0
		SearchTitle.Position = UDim2.new(0.5, 0, 0, 0)
		SearchTitle.Size = UDim2.new(1, 0, 0.25, 0)
		SearchTitle.ZIndex = 2
		SearchTitle.Parent = BaseEmote

		local Gradient = Instance.new("Frame")
		Gradient.Name = "Gradient"
		Gradient.AnchorPoint = Vector2.new(0.5, 0.5)
		Gradient.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Gradient.BackgroundTransparency = 0.9
		Gradient.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Gradient.BorderSizePixel = 0
		Gradient.Position = UDim2.new(0.5, 0, 0.5, 0)
		Gradient.Size = UDim2.new(1, 0, 1, 0)
		Gradient.Parent = BaseEmote

		local BottomContainer = Instance.new("Frame")
		BottomContainer.Name = "BottomContainer"
		BottomContainer.AnchorPoint = Vector2.new(0.5, 1)
		BottomContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BottomContainer.BackgroundTransparency = 1
		BottomContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BottomContainer.BorderSizePixel = 0
		BottomContainer.Position = UDim2.new(0.5, 0, 1, 0)
		BottomContainer.Size = UDim2.new(1, 0, 0.75, 0)
		BottomContainer.ZIndex = 2
		BottomContainer.Parent = BaseEmote

		local UICorner_2 = Instance.new("UICorner")
		UICorner_2.CornerRadius = UDim.new(0.03, 0)
		UICorner_2.BottomLeftRadius = UDim.new(0.03, 0)
		UICorner_2.BottomRightRadius = UDim.new(0.03, 0)
		UICorner_2.TopLeftRadius = UDim.new(0.03, 0)
		UICorner_2.TopRightRadius = UDim.new(0.03, 0)
		UICorner_2.Parent = TargetEmote

		local UIStroke_2 = Instance.new("UIStroke")
		UIStroke_2.Color = Color3.fromRGB(100, 100, 100)
		UIStroke_2.Transparency = 0.5
		UIStroke_2.Thickness = 0.0075
		UIStroke_2.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_2.Parent = TargetEmote

		local SearchTitle_2 = Instance.new("Frame")
		SearchTitle_2.Name = "SearchTitle"
		SearchTitle_2.AnchorPoint = Vector2.new(0.5, 0)
		SearchTitle_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SearchTitle_2.BackgroundTransparency = 1
		SearchTitle_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SearchTitle_2.BorderSizePixel = 0
		SearchTitle_2.Position = UDim2.new(0.5, 0, 0, 0)
		SearchTitle_2.Size = UDim2.new(1, 0, 0.25, 0)
		SearchTitle_2.ZIndex = 2
		SearchTitle_2.Parent = TargetEmote

		local Gradient_2 = Instance.new("Frame")
		Gradient_2.Name = "Gradient"
		Gradient_2.AnchorPoint = Vector2.new(0.5, 0.5)
		Gradient_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Gradient_2.BackgroundTransparency = 0.9
		Gradient_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Gradient_2.BorderSizePixel = 0
		Gradient_2.Position = UDim2.new(0.5, 0, 0.5, 0)
		Gradient_2.Size = UDim2.new(1, 0, 1, 0)
		Gradient_2.Parent = TargetEmote

		local BottomContainer_2 = Instance.new("Frame")
		BottomContainer_2.Name = "BottomContainer"
		BottomContainer_2.AnchorPoint = Vector2.new(0.5, 1)
		BottomContainer_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BottomContainer_2.BackgroundTransparency = 1
		BottomContainer_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BottomContainer_2.BorderSizePixel = 0
		BottomContainer_2.Position = UDim2.new(0.5, 0, 1, 0)
		BottomContainer_2.Size = UDim2.new(1, 0, 0.75, 0)
		BottomContainer_2.ZIndex = 2
		BottomContainer_2.Parent = TargetEmote

		local UICorner_3 = Instance.new("UICorner")
		UICorner_3.CornerRadius = UDim.new(0.2, 0)
		UICorner_3.BottomLeftRadius = UDim.new(0.2, 0)
		UICorner_3.BottomRightRadius = UDim.new(0.2, 0)
		UICorner_3.TopLeftRadius = UDim.new(0.2, 0)
		UICorner_3.TopRightRadius = UDim.new(0.2, 0)
		UICorner_3.Parent = SwapButton

		local UIStroke_3 = Instance.new("UIStroke")
		UIStroke_3.Color = Color3.fromRGB(175, 175, 255)
		UIStroke_3.Thickness = 0.02
		UIStroke_3.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_3.Parent = SwapButton

		local UIGradient_3 = Instance.new("UIGradient")
		UIGradient_3.Rotation = 90
		UIGradient_3.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 65, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 45, 85)), ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 65, 120))})
		UIGradient_3.Parent = SwapButton

		local SwapText = Instance.new("TextLabel")
		SwapText.Name = "SwapText"
		SwapText.AnchorPoint = Vector2.new(0.5, 0.5)
		SwapText.AutomaticSize = Enum.AutomaticSize.X
		SwapText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SwapText.BackgroundTransparency = 1
		SwapText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SwapText.BorderSizePixel = 0
		SwapText.LayoutOrder = 1
		SwapText.Position = UDim2.new(0.5, 0, 0.5, 0)
		SwapText.Size = UDim2.new(0.313333, 0, 0.7, 0)
		SwapText.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		SwapText.Text = "Swap"
		SwapText.TextColor3 = Color3.fromRGB(230, 230, 255)
		SwapText.TextScaled = true
		SwapText.TextSize = 14
		SwapText.TextWrapped = true
		SwapText.Parent = SwapButton

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		UIListLayout.Padding = UDim.new(0.05, 0)
		UIListLayout.Parent = SwapButton

		local SwapIconContainer = Instance.new("Frame")
		SwapIconContainer.Name = "SwapIconContainer"
		SwapIconContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SwapIconContainer.BackgroundTransparency = 1
		SwapIconContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SwapIconContainer.BorderSizePixel = 0
		SwapIconContainer.Size = UDim2.new(0.153333, 0, 0.657143, 0)
		SwapIconContainer.Parent = SwapButton

		local UICorner_4 = Instance.new("UICorner")
		UICorner_4.CornerRadius = UDim.new(0.2, 0)
		UICorner_4.BottomLeftRadius = UDim.new(0.2, 0)
		UICorner_4.BottomRightRadius = UDim.new(0.2, 0)
		UICorner_4.TopLeftRadius = UDim.new(0.2, 0)
		UICorner_4.TopRightRadius = UDim.new(0.2, 0)
		UICorner_4.Parent = CloseButton

		local UIStroke_4 = Instance.new("UIStroke")
		UIStroke_4.Color = Color3.fromRGB(255, 0, 0)
		UIStroke_4.Transparency = 0.5
		UIStroke_4.Thickness = 0.04
		UIStroke_4.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_4.Parent = CloseButton

		local CloseIcon = Instance.new("ImageLabel")
		CloseIcon.Name = "CloseIcon"
		CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		CloseIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		CloseIcon.BackgroundTransparency = 1
		CloseIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
		CloseIcon.BorderSizePixel = 0
		CloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		CloseIcon.Size = UDim2.new(0.75, 0, 0.75, 0)
		CloseIcon.Image = "rbxassetid://71237377585683"
		CloseIcon.ImageColor3 = Color3.fromRGB(230, 230, 255)
		CloseIcon.ImageTransparency = 0.5
		CloseIcon.Parent = CloseButton

		local UICorner_5 = Instance.new("UICorner")
		UICorner_5.CornerRadius = UDim.new(0.2, 0)
		UICorner_5.BottomLeftRadius = UDim.new(0.2, 0)
		UICorner_5.BottomRightRadius = UDim.new(0.2, 0)
		UICorner_5.TopLeftRadius = UDim.new(0.2, 0)
		UICorner_5.TopRightRadius = UDim.new(0.2, 0)
		UICorner_5.Parent = MinimizeButton

		local UIStroke_5 = Instance.new("UIStroke")
		UIStroke_5.Color = Color3.fromRGB(150, 150, 150)
		UIStroke_5.Transparency = 0.5
		UIStroke_5.Thickness = 0.04
		UIStroke_5.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_5.Parent = MinimizeButton

		local MinimizeIcon = Instance.new("ImageLabel")
		MinimizeIcon.Name = "MinimizeIcon"
		MinimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		MinimizeIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		MinimizeIcon.BackgroundTransparency = 1
		MinimizeIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
		MinimizeIcon.BorderSizePixel = 0
		MinimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		MinimizeIcon.Size = UDim2.new(0.75, 0, 0.75, 0)
		MinimizeIcon.Image = "rbxassetid://100624819703287"
		MinimizeIcon.ImageColor3 = Color3.fromRGB(230, 230, 255)
		MinimizeIcon.ImageTransparency = 0.5
		MinimizeIcon.Parent = MinimizeButton

		local BaseEmoteTitle = Instance.new("TextLabel")
		BaseEmoteTitle.Name = "BaseEmoteTitle"
		BaseEmoteTitle.AnchorPoint = Vector2.new(1, 0)
		BaseEmoteTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BaseEmoteTitle.BackgroundTransparency = 1
		BaseEmoteTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BaseEmoteTitle.BorderSizePixel = 0
		BaseEmoteTitle.Position = UDim2.new(1, 0, 0.15, 0)
		BaseEmoteTitle.Size = UDim2.new(0.925, 0, 0.3, 0)
		BaseEmoteTitle.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		BaseEmoteTitle.Text = "Base Emote"
		BaseEmoteTitle.TextColor3 = Color3.fromRGB(230, 230, 255)
		BaseEmoteTitle.TextScaled = true
		BaseEmoteTitle.TextSize = 14
		BaseEmoteTitle.TextWrapped = true
		BaseEmoteTitle.TextXAlignment = Enum.TextXAlignment.Left
		BaseEmoteTitle.Parent = SearchTitle

		local SearchContainer = Instance.new("Frame")
		SearchContainer.Name = "SearchContainer"
		SearchContainer.AnchorPoint = Vector2.new(0.5, 1)
		SearchContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		SearchContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SearchContainer.BorderSizePixel = 0
		SearchContainer.Position = UDim2.new(0.5, 0, 1, 0)
		SearchContainer.Size = UDim2.new(0.9, 0, 0.5, 0)
		SearchContainer.Parent = SearchTitle

		local UIGradient_4 = Instance.new("UIGradient")
		UIGradient_4.Rotation = -90
		UIGradient_4.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)})
		UIGradient_4.Parent = Gradient

		local BaseEmoteList = Instance.new("CanvasGroup")
		BaseEmoteList.Name = "BaseEmoteList"
		BaseEmoteList.AnchorPoint = Vector2.new(0.5, 0.5)
		BaseEmoteList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		BaseEmoteList.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BaseEmoteList.BorderSizePixel = 0
		BaseEmoteList.Position = UDim2.new(0.5, 0, 0.5, 0)
		BaseEmoteList.Size = UDim2.new(0.9, 0, 0.9, 0)
		BaseEmoteList.Parent = BottomContainer

		local TargetEmoteTitle = Instance.new("TextLabel")
		TargetEmoteTitle.Name = "TargetEmoteTitle"
		TargetEmoteTitle.AnchorPoint = Vector2.new(1, 0)
		TargetEmoteTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TargetEmoteTitle.BackgroundTransparency = 1
		TargetEmoteTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TargetEmoteTitle.BorderSizePixel = 0
		TargetEmoteTitle.Position = UDim2.new(1, 0, 0.15, 0)
		TargetEmoteTitle.Size = UDim2.new(0.925, 0, 0.3, 0)
		TargetEmoteTitle.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		TargetEmoteTitle.Text = "Target Emote"
		TargetEmoteTitle.TextColor3 = Color3.fromRGB(230, 230, 255)
		TargetEmoteTitle.TextScaled = true
		TargetEmoteTitle.TextSize = 14
		TargetEmoteTitle.TextWrapped = true
		TargetEmoteTitle.TextXAlignment = Enum.TextXAlignment.Left
		TargetEmoteTitle.Parent = SearchTitle_2

		local SearchContainer_2 = Instance.new("Frame")
		SearchContainer_2.Name = "SearchContainer"
		SearchContainer_2.AnchorPoint = Vector2.new(0.5, 1)
		SearchContainer_2.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		SearchContainer_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SearchContainer_2.BorderSizePixel = 0
		SearchContainer_2.Position = UDim2.new(0.5, 0, 1, 0)
		SearchContainer_2.Size = UDim2.new(0.9, 0, 0.5, 0)
		SearchContainer_2.Parent = SearchTitle_2

		local UIGradient_5 = Instance.new("UIGradient")
		UIGradient_5.Rotation = -90
		UIGradient_5.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)})
		UIGradient_5.Parent = Gradient_2

		local TargetEmoteList = Instance.new("CanvasGroup")
		TargetEmoteList.Name = "TargetEmoteList"
		TargetEmoteList.AnchorPoint = Vector2.new(0.5, 0.5)
		TargetEmoteList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		TargetEmoteList.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TargetEmoteList.BorderSizePixel = 0
		TargetEmoteList.Position = UDim2.new(0.5, 0, 0.5, 0)
		TargetEmoteList.Size = UDim2.new(0.9, 0, 0.9, 0)
		TargetEmoteList.Parent = BottomContainer_2

		local SwapIcon = Instance.new("ImageLabel")
		SwapIcon.Name = "SwapIcon"
		SwapIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		SwapIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SwapIcon.BackgroundTransparency = 1
		SwapIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SwapIcon.BorderSizePixel = 0
		SwapIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		SwapIcon.Rotation = 90
		SwapIcon.Size = UDim2.new(1, 0, 1, 0)
		SwapIcon.Image = "rbxassetid://134845388499915"
		SwapIcon.Parent = SwapIconContainer

		local UIStroke_6 = Instance.new("UIStroke")
		UIStroke_6.Color = Color3.fromRGB(100, 100, 100)
		UIStroke_6.Transparency = 0.5
		UIStroke_6.Thickness = 0.04
		UIStroke_6.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_6.Parent = SearchContainer

		local UICorner_6 = Instance.new("UICorner")
		UICorner_6.CornerRadius = UDim.new(0.2, 0)
		UICorner_6.BottomLeftRadius = UDim.new(0.2, 0)
		UICorner_6.BottomRightRadius = UDim.new(0.2, 0)
		UICorner_6.TopLeftRadius = UDim.new(0.2, 0)
		UICorner_6.TopRightRadius = UDim.new(0.2, 0)
		UICorner_6.Parent = SearchContainer

		local SearchEmote = Instance.new("TextBox")
		SearchEmote.Name = "SearchEmote"
		SearchEmote.AnchorPoint = Vector2.new(0.5, 0.5)
		SearchEmote.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SearchEmote.BackgroundTransparency = 1
		SearchEmote.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SearchEmote.BorderSizePixel = 0
		SearchEmote.Position = UDim2.new(0.5, 0, 0.5, 0)
		SearchEmote.Size = UDim2.new(0.85, 0, 0.6, 0)
		SearchEmote.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		SearchEmote.Text = ""
		SearchEmote.TextColor3 = Color3.fromRGB(255, 255, 255)
		SearchEmote.TextScaled = true
		SearchEmote.TextSize = 14
		SearchEmote.TextWrapped = true
		SearchEmote.TextXAlignment = Enum.TextXAlignment.Left
		SearchEmote.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
		SearchEmote.PlaceholderText = "Search emote..."
		SearchEmote.Parent = SearchContainer

		local UICorner_7 = Instance.new("UICorner")
		UICorner_7.CornerRadius = UDim.new(0.04, 0)
		UICorner_7.BottomLeftRadius = UDim.new(0.04, 0)
		UICorner_7.BottomRightRadius = UDim.new(0.04, 0)
		UICorner_7.TopLeftRadius = UDim.new(0.04, 0)
		UICorner_7.TopRightRadius = UDim.new(0.04, 0)
		UICorner_7.Parent = BaseEmoteList

		local UIStroke_7 = Instance.new("UIStroke")
		UIStroke_7.Color = Color3.fromRGB(100, 100, 100)
		UIStroke_7.Transparency = 0.5
		UIStroke_7.Thickness = 0.007
		UIStroke_7.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_7.Parent = BaseEmoteList

		local BaseEmoteScrolling = Instance.new("ScrollingFrame")
		BaseEmoteScrolling.Name = "BaseEmoteScrolling"
		BaseEmoteScrolling.AnchorPoint = Vector2.new(0.5, 0.5)
		BaseEmoteScrolling.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BaseEmoteScrolling.BackgroundTransparency = 1
		BaseEmoteScrolling.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BaseEmoteScrolling.BorderSizePixel = 0
		BaseEmoteScrolling.Position = UDim2.new(0.5, 0, 0.5, 0)
		BaseEmoteScrolling.Size = UDim2.new(1, 0, 1, 0)
		BaseEmoteScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
		BaseEmoteScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
		BaseEmoteScrolling.ScrollBarThickness = 2
		BaseEmoteScrolling.Parent = BaseEmoteList
		UI_BaseScrolling = BaseEmoteScrolling

		local UIStroke_8 = Instance.new("UIStroke")
		UIStroke_8.Color = Color3.fromRGB(100, 100, 100)
		UIStroke_8.Transparency = 0.5
		UIStroke_8.Thickness = 0.04
		UIStroke_8.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_8.Parent = SearchContainer_2

		local UICorner_8 = Instance.new("UICorner")
		UICorner_8.CornerRadius = UDim.new(0.2, 0)
		UICorner_8.BottomLeftRadius = UDim.new(0.2, 0)
		UICorner_8.BottomRightRadius = UDim.new(0.2, 0)
		UICorner_8.TopLeftRadius = UDim.new(0.2, 0)
		UICorner_8.TopRightRadius = UDim.new(0.2, 0)
		UICorner_8.Parent = SearchContainer_2

		local SearchEmote_2 = Instance.new("TextBox")
		SearchEmote_2.Name = "SearchEmote"
		SearchEmote_2.AnchorPoint = Vector2.new(0.5, 0.5)
		SearchEmote_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SearchEmote_2.BackgroundTransparency = 1
		SearchEmote_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SearchEmote_2.BorderSizePixel = 0
		SearchEmote_2.Position = UDim2.new(0.5, 0, 0.5, 0)
		SearchEmote_2.Size = UDim2.new(0.85, 0, 0.6, 0)
		SearchEmote_2.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		SearchEmote_2.Text = ""
		SearchEmote_2.TextColor3 = Color3.fromRGB(255, 255, 255)
		SearchEmote_2.TextScaled = true
		SearchEmote_2.TextSize = 14
		SearchEmote_2.TextWrapped = true
		SearchEmote_2.TextXAlignment = Enum.TextXAlignment.Left
		SearchEmote_2.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
		SearchEmote_2.PlaceholderText = "Search emote..."
		SearchEmote_2.Parent = SearchContainer_2

		local UICorner_9 = Instance.new("UICorner")
		UICorner_9.CornerRadius = UDim.new(0.04, 0)
		UICorner_9.BottomLeftRadius = UDim.new(0.04, 0)
		UICorner_9.BottomRightRadius = UDim.new(0.04, 0)
		UICorner_9.TopLeftRadius = UDim.new(0.04, 0)
		UICorner_9.TopRightRadius = UDim.new(0.04, 0)
		UICorner_9.Parent = TargetEmoteList

		local UIStroke_9 = Instance.new("UIStroke")
		UIStroke_9.Color = Color3.fromRGB(100, 100, 100)
		UIStroke_9.Transparency = 0.5
		UIStroke_9.Thickness = 0.007
		UIStroke_9.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_9.Parent = TargetEmoteList

		local TargetEmoteScrolling = Instance.new("ScrollingFrame")
		TargetEmoteScrolling.Name = "TargetEmoteScrolling"
		TargetEmoteScrolling.AnchorPoint = Vector2.new(0.5, 0.5)
		TargetEmoteScrolling.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TargetEmoteScrolling.BackgroundTransparency = 1
		TargetEmoteScrolling.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TargetEmoteScrolling.BorderSizePixel = 0
		TargetEmoteScrolling.Position = UDim2.new(0.5, 0, 0.5, 0)
		TargetEmoteScrolling.Size = UDim2.new(1, 0, 1, 0)
		TargetEmoteScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
		TargetEmoteScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
		TargetEmoteScrolling.ScrollBarThickness = 2
		TargetEmoteScrolling.Parent = TargetEmoteList
		UI_TargetScrolling = TargetEmoteScrolling

		local UIListLayout_2 = Instance.new("UIListLayout")
		UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout_2.Parent = BaseEmoteScrolling

		local PlaceorderTop = Instance.new("Frame")
		PlaceorderTop.Name = "PlaceorderTop"
		PlaceorderTop.AnchorPoint = Vector2.new(0.5, 0.5)
		PlaceorderTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		PlaceorderTop.BackgroundTransparency = 1
		PlaceorderTop.BorderColor3 = Color3.fromRGB(0, 0, 0)
		PlaceorderTop.BorderSizePixel = 0
		PlaceorderTop.Position = UDim2.new(0.5, 0, 0.5, 0)
		PlaceorderTop.Size = UDim2.new(1, 0, 0.02, 0)
		PlaceorderTop.Parent = BaseEmoteScrolling

		local PlaceorderBottom = Instance.new("Frame")
		PlaceorderBottom.Name = "PlaceorderBottom"
		PlaceorderBottom.AnchorPoint = Vector2.new(0.5, 0.5)
		PlaceorderBottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		PlaceorderBottom.BackgroundTransparency = 1
		PlaceorderBottom.BorderColor3 = Color3.fromRGB(0, 0, 0)
		PlaceorderBottom.BorderSizePixel = 0
		PlaceorderBottom.LayoutOrder = 99999
		PlaceorderBottom.Position = UDim2.new(0.5, 0, 0.5, 0)
		PlaceorderBottom.Size = UDim2.new(1, 0, 0.02, 0)
		PlaceorderBottom.Parent = BaseEmoteScrolling

		local Template = Instance.new("Frame")
		Template.Name = "Template"
		Template.AnchorPoint = Vector2.new(0.5, 0.5)
		Template.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Template.BackgroundTransparency = 1
		Template.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Template.BorderSizePixel = 0
		Template.LayoutOrder = 1
		Template.Position = UDim2.new(0.5, 0, 0.5, 0)
		Template.Size = UDim2.new(1, 0, 0.2, 0)
        Template.Visible = false
		Template.Parent = BaseEmoteScrolling
		UI_Template_Base = Template

		local UIListLayout_3 = Instance.new("UIListLayout")
		UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout_3.Parent = TargetEmoteScrolling

		local PlaceorderTop_2 = Instance.new("Frame")
		PlaceorderTop_2.Name = "PlaceorderTop"
		PlaceorderTop_2.AnchorPoint = Vector2.new(0.5, 0.5)
		PlaceorderTop_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		PlaceorderTop_2.BackgroundTransparency = 1
		PlaceorderTop_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		PlaceorderTop_2.BorderSizePixel = 0
		PlaceorderTop_2.Position = UDim2.new(0.5, 0, 0.5, 0)
		PlaceorderTop_2.Size = UDim2.new(1, 0, 0.02, 0)
		PlaceorderTop_2.Parent = TargetEmoteScrolling

		local PlaceorderBottom_2 = Instance.new("Frame")
		PlaceorderBottom_2.Name = "PlaceorderBottom"
		PlaceorderBottom_2.AnchorPoint = Vector2.new(0.5, 0.5)
		PlaceorderBottom_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		PlaceorderBottom_2.BackgroundTransparency = 1
		PlaceorderBottom_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		PlaceorderBottom_2.BorderSizePixel = 0
		PlaceorderBottom_2.LayoutOrder = 99999
		PlaceorderBottom_2.Position = UDim2.new(0.5, 0, 0.5, 0)
		PlaceorderBottom_2.Size = UDim2.new(1, 0, 0.02, 0)
		PlaceorderBottom_2.Parent = TargetEmoteScrolling

		local Template_2 = Instance.new("Frame")
		Template_2.Name = "Template"
		Template_2.AnchorPoint = Vector2.new(0.5, 0.5)
		Template_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Template_2.BackgroundTransparency = 1
		Template_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Template_2.BorderSizePixel = 0
		Template_2.LayoutOrder = 1
		Template_2.Position = UDim2.new(0.5, 0, 0.5, 0)
		Template_2.Size = UDim2.new(1, 0, 0.2, 0)
        Template_2.Visible = false
		Template_2.Parent = TargetEmoteScrolling
		UI_Template_Target = Template_2

		local EmoteButton = Instance.new("ImageButton")
		EmoteButton.Name = "EmoteButton"
		EmoteButton.AnchorPoint = Vector2.new(0.5, 0.5)
		EmoteButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		EmoteButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		EmoteButton.BorderSizePixel = 0
		EmoteButton.Position = UDim2.new(0.5, 0, 0.5, 0)
		EmoteButton.Size = UDim2.new(0.9, 0, 0.75, 0)
		EmoteButton.Parent = Template

		local EmoteButton_2 = Instance.new("ImageButton")
		EmoteButton_2.Name = "EmoteButton"
		EmoteButton_2.AnchorPoint = Vector2.new(0.5, 0.5)
		EmoteButton_2.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		EmoteButton_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		EmoteButton_2.BorderSizePixel = 0
		EmoteButton_2.Position = UDim2.new(0.5, 0, 0.5, 0)
		EmoteButton_2.Size = UDim2.new(0.9, 0, 0.75, 0)
		EmoteButton_2.Parent = Template_2

		local UICorner_10 = Instance.new("UICorner")
		UICorner_10.CornerRadius = UDim.new(0.2, 0)
		UICorner_10.BottomLeftRadius = UDim.new(0.2, 0)
		UICorner_10.BottomRightRadius = UDim.new(0.2, 0)
		UICorner_10.TopLeftRadius = UDim.new(0.2, 0)
		UICorner_10.TopRightRadius = UDim.new(0.2, 0)
		UICorner_10.Parent = EmoteButton

		local UIStroke_10 = Instance.new("UIStroke")
		UIStroke_10.Color = Color3.fromRGB(100, 100, 100)
		UIStroke_10.Transparency = 0.5
		UIStroke_10.Thickness = 0.05
		UIStroke_10.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_10.Parent = EmoteButton

		local EmoteName = Instance.new("TextLabel")
		EmoteName.Name = "EmoteName"
		EmoteName.AnchorPoint = Vector2.new(0.5, 0.5)
		EmoteName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		EmoteName.BackgroundTransparency = 1
		EmoteName.BorderColor3 = Color3.fromRGB(0, 0, 0)
		EmoteName.BorderSizePixel = 0
		EmoteName.Position = UDim2.new(0.5, 0, 0.5, 0)
		EmoteName.Size = UDim2.new(0.9, 0, 0.7, 0)
		EmoteName.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		EmoteName.Text = "Kickback"
		EmoteName.TextColor3 = Color3.fromRGB(255, 255, 255)
		EmoteName.TextScaled = true
		EmoteName.TextSize = 14
		EmoteName.TextWrapped = true
		EmoteName.TextXAlignment = Enum.TextXAlignment.Left
		EmoteName.Parent = EmoteButton

		local UICorner_11 = Instance.new("UICorner")
		UICorner_11.CornerRadius = UDim.new(0.2, 0)
		UICorner_11.BottomLeftRadius = UDim.new(0.2, 0)
		UICorner_11.BottomRightRadius = UDim.new(0.2, 0)
		UICorner_11.TopLeftRadius = UDim.new(0.2, 0)
		UICorner_11.TopRightRadius = UDim.new(0.2, 0)
		UICorner_11.Parent = EmoteButton_2

		local UIStroke_11 = Instance.new("UIStroke")
		UIStroke_11.Color = Color3.fromRGB(100, 100, 100)
		UIStroke_11.Transparency = 0.5
		UIStroke_11.Thickness = 0.05
		UIStroke_11.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		UIStroke_11.Parent = EmoteButton_2

		local EmoteName_2 = Instance.new("TextLabel")
		EmoteName_2.Name = "EmoteName"
		EmoteName_2.AnchorPoint = Vector2.new(0.5, 0.5)
		EmoteName_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		EmoteName_2.BackgroundTransparency = 1
		EmoteName_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		EmoteName_2.BorderSizePixel = 0
		EmoteName_2.Position = UDim2.new(0.5, 0, 0.5, 0)
		EmoteName_2.Size = UDim2.new(0.9, 0, 0.7, 0)
		EmoteName_2.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		EmoteName_2.Text = "Kickback"
		EmoteName_2.TextColor3 = Color3.fromRGB(255, 255, 255)
		EmoteName_2.TextScaled = true
		EmoteName_2.TextSize = 14
		EmoteName_2.TextWrapped = true
		EmoteName_2.TextXAlignment = Enum.TextXAlignment.Left
		EmoteName_2.Parent = EmoteButton_2
		
		local OpenButton = Instance.new("ImageButton")
		OpenButton.Name = "OpenButton"
		OpenButton.AnchorPoint = Vector2.new(1, 0)
		OpenButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		OpenButton.BackgroundTransparency = 0.5
		OpenButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		OpenButton.BorderSizePixel = 0
		OpenButton.Position = UDim2.new(1, -10, 0, 10)
		OpenButton.Size = UDim2.new(0.025445, 0, 0.037831, 0)
		OpenButton.Visible = false 
		OpenButton.Parent = VisualEmotes
		UI_OpenButton = OpenButton

		local OpenUICorner = Instance.new("UICorner")
		OpenUICorner.Name = "OpenUICorner"
		OpenUICorner.CornerRadius = UDim.new(0.35, 0)
		OpenUICorner.Parent = OpenButton

		local OpenUIStroke = Instance.new("UIStroke")
		OpenUIStroke.Name = "OpenUIStroke"
		OpenUIStroke.Color = Color3.fromRGB(150, 150, 150)
		OpenUIStroke.Transparency = 0.5
		OpenUIStroke.Thickness = 0.02
		OpenUIStroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		OpenUIStroke.Parent = OpenButton

		local OpenImage = Instance.new("ImageLabel")
		OpenImage.Name = "OpenImage"
		OpenImage.AnchorPoint = Vector2.new(0.5, 0.5)
		OpenImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		OpenImage.BackgroundTransparency = 1
		OpenImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
		OpenImage.BorderSizePixel = 0
		OpenImage.Position = UDim2.new(0.5, 0, 0.5, 0)
		OpenImage.Size = UDim2.new(0.75, 0, 0.75, 0)
		OpenImage.Image = "rbxassetid://81135873326242"
		OpenImage.Parent = OpenButton

		local OpenUIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		OpenUIAspectRatioConstraint.Name = "OpenUIAspectRatioConstraint"
		OpenUIAspectRatioConstraint.Parent = OpenButton

		local OpenUIScale = Instance.new("UIScale")
		OpenUIScale.Name = "OpenUIScale"
		OpenUIScale.Parent = OpenButton
		UI_OpenUIScale = OpenUIScale
	end

    -- ==========================================================
	-- SCOPE 3: GENERATE EMOTE LIST & HELPER
	-- ==========================================================
	do
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

			-- Summer 2026
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
			"ReplicatedStorage.Items.ItemPacks.Integration.M3GAN.Emotes.RobotM3GAN"
		}

		table.sort(DaftarPath, function(a, b)
			local splitA = string.split(a, ".")
			local nameA = splitA[#splitA]
			
			local splitB = string.split(b, ".")
			local nameB = splitB[#splitB]
			
			return string.lower(nameA) < string.lower(nameB)
		end)

		local function GetInstanceFromPath(pathStr)
			local pathTable = string.split(pathStr, ".")
			local currentObject = game
			
			for _, name in ipairs(pathTable) do
				if name == "ReplicatedStorage" then
					currentObject = game:GetService("ReplicatedStorage")
				else
					currentObject = currentObject:FindFirstChild(name)
				end
				
				if not currentObject then
					warn("Path ga ketemu bre, stuck di: " .. name .. " (Full path: " .. pathStr .. ")")
					return nil
				end
			end
			
			return currentObject
		end

		local function formatSpacedName(name)
			return name:gsub("(%l)(%u)", "%1 %2")
		end

		if UI_Template_Base and UI_Template_Target then
			UI_Template_Base.Visible = false
			UI_Template_Target.Visible = false

			for index, path in ipairs(DaftarPath) do
				local splitPath = string.split(path, ".")
				local emoteName = splitPath[#splitPath] 
				local formattedName = formatSpacedName(emoteName)
				local emoteInstance = GetInstanceFromPath(path)
				
				if emoteInstance then
					local cloneBase = UI_Template_Base:Clone()
					cloneBase.Name = emoteName
					cloneBase.EmoteButton.EmoteName.Text = formattedName 
					cloneBase.LayoutOrder = index
					cloneBase.Visible = true
					cloneBase.Parent = UI_BaseScrolling
					
					local baseVal = Instance.new("ObjectValue")
					baseVal.Name = "EmoteRef"
					baseVal.Value = emoteInstance
					baseVal.Parent = cloneBase
					
					local cloneTarget = UI_Template_Target:Clone()
					cloneTarget.Name = emoteName
					cloneTarget.EmoteButton.EmoteName.Text = formattedName 
					cloneTarget.LayoutOrder = index
					cloneTarget.Visible = true
					cloneTarget.Parent = UI_TargetScrolling
					
					local targetVal = Instance.new("ObjectValue")
					targetVal.Name = "EmoteRef"
					targetVal.Value = emoteInstance
					targetVal.Parent = cloneTarget
				end
			end
		end
	end

	-- ==========================================================
	-- SCOPE 4: NOTIFIKASI & TRANSISI (Tunggu Intro Kelar)
	-- ==========================================================
	do
		task.spawn(function()
			onLoadingFinished.Event:Wait()
			
			if UI_MainFrame and UI_MainUIScale then
				UI_MainFrame.Visible = true
				UI_MainUIScale.Scale = 0
				
				TweenService:Create(UI_MainUIScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			end
			
			local NotifContainer = Instance.new("Frame")
			NotifContainer.Name = "NotifContainer"
			NotifContainer.Size = UDim2.new(0.175, 0, 0.03, 0)
			NotifContainer.AnchorPoint = Vector2.new(0.5, 0)
			NotifContainer.Position = UDim2.new(0.5, 0, -0.1, 0)
			NotifContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			NotifContainer.BackgroundTransparency = 1
			NotifContainer.Parent = VisualEmotes
			Instance.new("UICorner", NotifContainer).CornerRadius = UDim.new(1, 0)

			local NotifText = Instance.new("TextLabel")
			NotifText.Size = UDim2.new(1, 0, 0.75, 0)
			NotifText.AnchorPoint = Vector2.new(0.5, 0.5)
			NotifText.Position = UDim2.new(0.5, 0, 0.5, 0)
			NotifText.BackgroundTransparency = 1
			NotifText.Font = Enum.Font.Gotham
			NotifText.TextScaled = true
			NotifText.TextSize = 14
			NotifText.RichText = true
			NotifText.TextTransparency = 1
			NotifText.Parent = NotifContainer
			
			local notifDebounce = false

			triggerNotif.Event:Connect(function(msg, isError)
				if notifDebounce then return end
				notifDebounce = true
				
				NotifText.Text = msg
				if isError then
					NotifText.TextColor3 = Color3.fromRGB(255, 80, 80)
				else
					NotifText.TextColor3 = Color3.fromRGB(80, 255, 100)
				end

				TweenService:Create(NotifContainer, TweenInfo.new(0.3), {Position = UDim2.new(0.5, 0, 0, 20), BackgroundTransparency = 0.2}):Play()
				TweenService:Create(NotifText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

				task.wait(2.5)

				TweenService:Create(NotifContainer, TweenInfo.new(0.3), {Position = UDim2.new(0.5, 0, -0.1, 0), BackgroundTransparency = 1}):Play()
				TweenService:Create(NotifText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
				
				task.wait(0.3)
				notifDebounce = false
			end)
		end)
	end


	-- ==========================================================
	-- SCOPE 5: WINDOW MANAGEMENT (DRAG, MINIMIZE, CLOSE/OPEN)
	-- ==========================================================
	do
		local dragging = false
		local dragInput, mousePos, framePos

		if UI_DragButton then
			UI_DragButton.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					mousePos = input.Position
					framePos = UI_MainFrame.Position

					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
						end
					end)
				end
			end)

			UI_DragButton.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					dragInput = input
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if input == dragInput and dragging then
					local delta = input.Position - mousePos
					UI_MainFrame.Position = UDim2.new(
						framePos.X.Scale, framePos.X.Offset + delta.X, 
						framePos.Y.Scale, framePos.Y.Offset + delta.Y
					)
				end
			end)
		end

		local isMinimized = false
		if UI_MinimizeButton then
			UI_MinimizeButton.MouseButton1Click:Connect(function()
				isMinimized = not isMinimized
				local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				if isMinimized then
					TweenService:Create(UI_BottomFrame, tweenInfo, {Position = UDim2.new(0.5, 0, 0, 0)}):Play()
					TweenService:Create(UI_UIStroke1, tweenInfo, {Transparency = 1}):Play()
					TweenService:Create(UI_UICornerMinimize, tweenInfo, {CornerRadius = UDim.new(0.2, 0)}):Play()
				else
					TweenService:Create(UI_BottomFrame, tweenInfo, {Position = UDim2.new(0.5, 0, 1, 0)}):Play()
					TweenService:Create(UI_UIStroke1, tweenInfo, {Transparency = 0.5}):Play()
					TweenService:Create(UI_UICornerMinimize, tweenInfo, {CornerRadius = UDim.new(0, 0)}):Play()
				end
			end)
		end

		local isTransitioning = false
		local twIn = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local twOut = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		
		if UI_CloseButton and UI_OpenButton then
			UI_CloseButton.MouseButton1Click:Connect(function()
				if isTransitioning then return end
				isTransitioning = true
				
				local twClose = TweenService:Create(UI_MainUIScale, twOut, {Scale = 0})
				twClose:Play()
				twClose.Completed:Wait() 
				
				UI_MainFrame.Visible = false
				UI_OpenButton.Visible = true
				UI_OpenUIScale.Scale = 0 
				TweenService:Create(UI_OpenUIScale, twIn, {Scale = 1}):Play()
				
				isTransitioning = false
			end)
			
			UI_OpenButton.MouseButton1Click:Connect(function()
				if isTransitioning then return end
				isTransitioning = true
				
				local twOpen = TweenService:Create(UI_OpenUIScale, twOut, {Scale = 0})
				twOpen:Play()
				twOpen.Completed:Wait()
				
				UI_OpenButton.Visible = false
				UI_MainFrame.Visible = true
				UI_MainUIScale.Scale = 0
				TweenService:Create(UI_MainUIScale, twIn, {Scale = 1}):Play()
				
				isTransitioning = false
			end)
		end
	end

    -- ==========================================================
	-- DATABASE & CONFIG (SCOPE 6 & 7)
	-- ==========================================================
	local WhitelistConfig = {
		["RockinStride"] = "Kickback",
		["Kickback"] = "RockinStride",
		["ZombieStride"] = "ClassicDance",
        ["ClassicDance"] = "ZombieStride"
	}
	
	local SwappedData = {}       
	local OriginalContents = {}  

	local ActiveBaseButtonUI = nil
	local ActiveTargetButtonUI = nil
	
	local hasNotifiedWhitelist = false 

	local function getSpacedName(name)
		return name:gsub("(%l)(%u)", "%1 %2")
	end

	-- ==========================================================
	-- SCOPE 6: REALTIME SEARCH, SELECTION & WHITELIST
	-- ==========================================================
	do
		local BaseSearchBox = UI_MainFrame.BottomFrame.LeftContainer.BaseEmote.SearchTitle.SearchContainer.SearchEmote
		local TargetSearchBox = UI_MainFrame.BottomFrame.RightContainer.TargetEmote.SearchTitle.SearchContainer.SearchEmote

		local function resetStroke(buttonFrame)
			if not buttonFrame then return end
			local btn = buttonFrame:FindFirstChild("EmoteButton")
			local stroke = btn and btn:FindFirstChild("UIStroke")
			local ref = buttonFrame:FindFirstChild("EmoteRef")
			
			if not (btn and stroke and ref) then return end
			
			if SwappedData[ref.Value] then
				btn.BackgroundColor3 = Color3.fromRGB(25, 100, 25)
				stroke.Transparency = 0
				stroke.Color = Color3.fromRGB(0, 255, 0)
			else
				btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				stroke.Transparency = 0.5
				stroke.Color = Color3.fromRGB(100, 100, 100)
			end
		end

		local function setStrokeActive(buttonFrame)
			if not buttonFrame then return end
			local stroke = buttonFrame.EmoteButton:FindFirstChild("UIStroke")
			if stroke then
				stroke.Transparency = 0
				stroke.Color = Color3.fromRGB(255, 255, 255)
			end
		end

		local function FilterLists()
			local baseSearchText = string.lower(BaseSearchBox.Text)
			local targetSearchText = string.lower(TargetSearchBox.Text)
			
			local targetWhitelistTarget = SelectedBaseEmote and WhitelistConfig[SelectedBaseEmote.Name] or nil
			local baseWhitelistTarget = SelectedTargetEmote and WhitelistConfig[SelectedTargetEmote.Name] or nil

			if SelectedTargetEmote then
				local isHiddenByWhitelist = targetWhitelistTarget and SelectedTargetEmote.Name ~= targetWhitelistTarget
				local isSameAsBase = SelectedBaseEmote and SelectedTargetEmote.Name == SelectedBaseEmote.Name
				
				if isHiddenByWhitelist or isSameAsBase then
					if ActiveTargetButtonUI then resetStroke(ActiveTargetButtonUI) end
					ActiveTargetButtonUI = nil
					SelectedTargetEmote = nil
				end
			end
			
			if SelectedBaseEmote then
				local isHiddenByWhitelist = baseWhitelistTarget and SelectedBaseEmote.Name ~= baseWhitelistTarget
				local isSameAsTarget = SelectedTargetEmote and SelectedBaseEmote.Name == SelectedTargetEmote.Name
				
				if isHiddenByWhitelist or isSameAsTarget then
					if ActiveBaseButtonUI then resetStroke(ActiveBaseButtonUI) end
					ActiveBaseButtonUI = nil
					SelectedBaseEmote = nil
				end
			end

			for _, child in ipairs(UI_BaseScrolling:GetChildren()) do
				if child:IsA("Frame") and child.Name ~= "Template" and child.Name ~= "PlaceorderTop" and child.Name ~= "PlaceorderBottom" and child:FindFirstChild("EmoteButton") then
					local eNameOri = child.Name
					local eTextSpaced = string.lower(getSpacedName(eNameOri))
					
					local passSearch = (baseSearchText == "" or string.find(eTextSpaced, baseSearchText, 1, true) or string.find(string.lower(eNameOri), baseSearchText, 1, true))
					local passWhitelist = (not baseWhitelistTarget) or (eNameOri == baseWhitelistTarget)
					local passSelfLock = not (SelectedTargetEmote and eNameOri == SelectedTargetEmote.Name)
					
					child.Visible = (passSearch and passWhitelist and passSelfLock)
				end
			end

			for _, child in ipairs(UI_TargetScrolling:GetChildren()) do
				if child:IsA("Frame") and child.Name ~= "Template" and child.Name ~= "PlaceorderTop" and child.Name ~= "PlaceorderBottom" and child:FindFirstChild("EmoteButton") then
					local eNameOri = child.Name
					local eTextSpaced = string.lower(getSpacedName(eNameOri))
					
					local passSearch = (targetSearchText == "" or string.find(eTextSpaced, targetSearchText, 1, true) or string.find(string.lower(eNameOri), targetSearchText, 1, true))
					local passWhitelist = (not targetWhitelistTarget) or (eNameOri == targetWhitelistTarget)
					local passSelfLock = not (SelectedBaseEmote and eNameOri == SelectedBaseEmote.Name)
					
					child.Visible = (passSearch and passWhitelist and passSelfLock)
				end
			end
		end

		BaseSearchBox:GetPropertyChangedSignal("Text"):Connect(FilterLists)
		TargetSearchBox:GetPropertyChangedSignal("Text"):Connect(FilterLists)

		for _, child in ipairs(UI_BaseScrolling:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "Template" and child:FindFirstChild("EmoteButton") then
				child.EmoteButton.MouseButton1Click:Connect(function()
					local ref = child:FindFirstChild("EmoteRef")
					
					if ActiveBaseButtonUI == child then
						resetStroke(child)
						ActiveBaseButtonUI = nil
						SelectedBaseEmote = nil
						hasNotifiedWhitelist = false
					else
						if ActiveBaseButtonUI then resetStroke(ActiveBaseButtonUI) end
						ActiveBaseButtonUI = child
						setStrokeActive(child)
						SelectedBaseEmote = ref.Value
						
						if WhitelistConfig[SelectedBaseEmote.Name] and not hasNotifiedWhitelist then
							triggerNotif:Fire("Whitelist applied! This emote is restricted to a specific pair.", true)
							hasNotifiedWhitelist = true
						end
					end
					
					FilterLists() 
					if _G.UpdateSwapButtonState then _G.UpdateSwapButtonState() end
				end)
			end
		end

		for _, child in ipairs(UI_TargetScrolling:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "Template" and child:FindFirstChild("EmoteButton") then
				child.EmoteButton.MouseButton1Click:Connect(function()
					local ref = child:FindFirstChild("EmoteRef")
					
					if ActiveTargetButtonUI == child then
						resetStroke(child)
						ActiveTargetButtonUI = nil
						SelectedTargetEmote = nil
						hasNotifiedWhitelist = false
					else
						if ActiveTargetButtonUI then resetStroke(ActiveTargetButtonUI) end
						ActiveTargetButtonUI = child
						setStrokeActive(child)
						SelectedTargetEmote = ref.Value
						
						if WhitelistConfig[SelectedTargetEmote.Name] and not hasNotifiedWhitelist then
							triggerNotif:Fire("Whitelist applied! This emote is restricted to a specific pair.", true)
							hasNotifiedWhitelist = true
						end
					end
					
					FilterLists()
					if _G.UpdateSwapButtonState then _G.UpdateSwapButtonState() end
				end)
			end
		end

		_G.UpdateListVisuals = function()
			for _, child in ipairs(UI_BaseScrolling:GetChildren()) do
				if child:IsA("Frame") and child.Name ~= "Template" and child.Name ~= "PlaceorderTop" and child.Name ~= "PlaceorderBottom" and child:FindFirstChild("EmoteButton") then
					if child ~= ActiveBaseButtonUI then resetStroke(child) end
				end
			end
			for _, child in ipairs(UI_TargetScrolling:GetChildren()) do
				if child:IsA("Frame") and child.Name ~= "Template" and child.Name ~= "PlaceorderTop" and child.Name ~= "PlaceorderBottom" and child:FindFirstChild("EmoteButton") then
					if child ~= ActiveTargetButtonUI then resetStroke(child) end
				end
			end
		end
	end


	-- ==========================================================
	-- SCOPE 7: SWAP BUTTON LOGIC & SWAP CHILDREN
	-- ==========================================================
	do
		local SwapButton = UI_MainFrame.BottomFrame.Frame.SwapButton
		local SwapStroke = SwapButton:FindFirstChild("UIStroke")
		local SwapGradient = SwapButton:FindFirstChild("UIGradient")
		local SwapTextLabel = SwapButton:FindFirstChild("SwapText")
		
		local currentSwapState = 1 
		
		_G.UpdateSwapButtonState = function()
			if not SwapStroke or not SwapGradient then return end
			
			if not SelectedBaseEmote or not SelectedTargetEmote then
				currentSwapState = 1 
			else
				if SwappedData[SelectedBaseEmote] == SelectedTargetEmote then
					currentSwapState = 3
				elseif SwappedData[SelectedBaseEmote] ~= nil or SwappedData[SelectedTargetEmote] ~= nil then
					currentSwapState = 1
				else
					currentSwapState = 2
				end
			end
			
			if currentSwapState == 1 then
				SwapStroke.Color = Color3.fromRGB(150, 150, 150)
				SwapGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)), 
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(85, 85, 85)), 
					ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120))
				})
				SwapTextLabel.Text = "Swap"
				
			elseif currentSwapState == 2 then
				SwapStroke.Color = Color3.fromRGB(175, 175, 255)
				SwapGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 65, 120)), 
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 45, 85)), 
					ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 65, 120))
				})
				SwapTextLabel.Text = "Swap"
				
			elseif currentSwapState == 3 then
				SwapStroke.Color = Color3.fromRGB(255, 175, 175)
				SwapGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 65, 65)), 
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 25, 25)), 
					ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 65, 65))
				})
				SwapTextLabel.Text = "Revert"
			end
		end
		
		_G.UpdateSwapButtonState() 

		local function CacheOriginal(emote)
			if not OriginalContents[emote] then
				OriginalContents[emote] = {}
				for _, child in ipairs(emote:GetChildren()) do
					table.insert(OriginalContents[emote], child:Clone())
				end
			end
		end

		local function InjectContents(targetEmote, sourceEmote)
			for _, child in ipairs(targetEmote:GetChildren()) do
				child:Destroy()
			end
			for _, child in ipairs(OriginalContents[sourceEmote]) do
				child:Clone().Parent = targetEmote
			end
		end
		
		local function SetUIName(emoteInstance, targetInstance)
			local newText = ""
			if targetInstance then
				newText = getSpacedName(emoteInstance.Name) .. " (" .. getSpacedName(targetInstance.Name) .. ")"
			else
				newText = getSpacedName(emoteInstance.Name)
			end
			
			for _, child in ipairs(UI_BaseScrolling:GetChildren()) do
				if child:IsA("Frame") then
					local ref = child:FindFirstChild("EmoteRef")
					if ref and ref.Value == emoteInstance then
						child.EmoteButton.EmoteName.Text = newText
					end
				end
			end
			for _, child in ipairs(UI_TargetScrolling:GetChildren()) do
				if child:IsA("Frame") then
					local ref = child:FindFirstChild("EmoteRef")
					if ref and ref.Value == emoteInstance then
						child.EmoteButton.EmoteName.Text = newText
					end
				end
			end
		end

		SwapButton.MouseButton1Click:Connect(function()
			if currentSwapState == 1 then
				triggerNotif:Fire("Swap unavailable! Please ensure you have selected a valid Base and Target emote.", true)
				return
			end
			
			local B_Emote = SelectedBaseEmote
			local T_Emote = SelectedTargetEmote
			
			if currentSwapState == 2 then
				CacheOriginal(B_Emote)
				CacheOriginal(T_Emote)
				
				InjectContents(B_Emote, T_Emote)
				InjectContents(T_Emote, B_Emote)
				
				SwappedData[B_Emote] = T_Emote
				SwappedData[T_Emote] = B_Emote
				
				SetUIName(B_Emote, T_Emote)
				SetUIName(T_Emote, B_Emote)
				
				triggerNotif:Fire("<b>Swap Successful!</b><br />" .. getSpacedName(B_Emote.Name) .. " ⇌ " .. getSpacedName(T_Emote.Name), false)
				
			elseif currentSwapState == 3 then
				InjectContents(B_Emote, B_Emote)
				InjectContents(T_Emote, T_Emote)
				
				SwappedData[B_Emote] = nil
				SwappedData[T_Emote] = nil
				
				SetUIName(B_Emote, nil)
				SetUIName(T_Emote, nil)
				
				triggerNotif:Fire("<b>Revert Successful!</b><br />" .. getSpacedName(B_Emote.Name) .. " and " .. getSpacedName(T_Emote.Name) .. " have been restored.", false)
			end
			
			ActiveBaseButtonUI = nil
			ActiveTargetButtonUI = nil
			SelectedBaseEmote = nil
			SelectedTargetEmote = nil
			hasNotifiedWhitelist = false
			
			if _G.UpdateListVisuals then _G.UpdateListVisuals() end
			if _G.UpdateSwapButtonState then _G.UpdateSwapButtonState() end
		end)
	end


end, ErrorHandler)

if not success then
	warn("Gagal mengeksekusi script UI utama.")
end

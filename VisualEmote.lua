-- Visual Emotes (standalone) - by Honami
-- UI is built in this file (styled after Mugiwara UI); swap and preview logic ported from Mugiwara HUB's
-- Games/Evade/VisualSwap.lua, EmotePreview.lua and VisualGridUI.lua. Runs together with Visual Carry and
-- Visual Unusual in one shared window when they are executed too (see "Shared shell").

local SCRIPT_NAME = "Visual Emotes"

-- ==========================================================
-- Shared shell (identical in Visual Emotes, Visual Carry and Visual Unusual)
-- A script adds its own page to the shell. If another Visual script is already running, the page joins
-- the same window (sidebar with one tab per script, like the hub); alone, a script gets the plain window.
-- ==========================================================

-- Only runs in Evade (same place ids as Mugiwara HUB); in any other game nothing is loaded.
local EVADE_PLACE_IDS = { [9872472334] = true, [99214917572799] = true, [10668472534] = true }
if not EVADE_PLACE_IDS[game.PlaceId] then
    warn("[" .. SCRIPT_NAME .. "] This script only works in Evade.")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = SCRIPT_NAME, Text = "This script only works in Evade.", Duration = 6 })
    end)
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- Mugiwara UI, Gear 5 theme
local THEME = {
    Background = rgb(12, 13, 21), BackgroundAlpha = 0.12,
    Sidebar = rgb(0, 0, 0), SidebarAlpha = 0.5,
    Card = rgb(255, 255, 255), CardAlpha = 0.91,
    Stroke = rgb(255, 255, 255), StrokeAlpha = 0.84,
    Field = rgb(0, 0, 0), FieldAlpha = 0.45,
    Popup = rgb(14, 14, 20), PopupAlpha = 0.08,
    Text = rgb(252, 252, 255), SubText = rgb(200, 204, 220), Muted = rgb(142, 146, 164),
    Accent = rgb(255, 255, 255), OnAccent = rgb(16, 18, 30),
    Success = rgb(80, 230, 150), Danger = rgb(255, 72, 92),
    Swapped = rgb(255, 200, 62),
}
local GRADIENT_STOPS = { rgb(255, 255, 255), rgb(224, 234, 255), rgb(255, 247, 226), rgb(255, 224, 160) }

local function Linear(stops)
    local points = {}
    for index, color in ipairs(stops) do
        points[index] = ColorSequenceKeypoint.new((index - 1) / (#stops - 1), color)
    end
    return ColorSequence.new(points)
end
local GRADIENT = Linear(GRADIENT_STOPS)
local CYCLE = (function()
    local mirrored = table.clone(GRADIENT_STOPS)
    for index = #GRADIENT_STOPS - 1, 1, -1 do table.insert(mirrored, GRADIENT_STOPS[index]) end
    return Linear(mirrored)
end)()

local FONT_TITLE, FONT_LABEL, FONT_BODY = Enum.Font.GothamBold, Enum.Font.GothamSemibold, Enum.Font.GothamMedium

local function New(class, props, parent)
    local instance = Instance.new(class)
    for key, value in pairs(props) do instance[key] = value end
    instance.Parent = parent
    return instance
end

local function Round(instance, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius) }, instance)
end

local function Stroke(instance, transparency, thickness, color)
    return New("UIStroke", {
        Color = color or THEME.Stroke,
        Transparency = transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, instance)
end

local function Gradient(parent, rotation, sequence)
    return New("UIGradient", { Rotation = rotation or 0, Color = sequence or GRADIENT }, parent)
end

local function Label(parent, props)
    local merged = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = FONT_BODY,
        TextColor3 = THEME.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }
    for key, value in pairs(props) do merged[key] = value end
    return New("TextLabel", merged, parent)
end

local function Tween(instance, props, duration, style)
    TweenService:Create(instance, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- Icons drawn from rotated bars, like Mugiwara UI draws its own glyphs.
local function Glyph(parent, size)
    return New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
    }, parent)
end

local function Bar(root, length, thickness, rotation, x, y, color)
    local bar = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(x, y),
        Size = UDim2.fromOffset(length, thickness),
        Rotation = rotation,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, root)
    Round(bar, thickness)
    return bar
end

local function ChevronGlyph(parent, size, color)
    local root = Glyph(parent, size)
    local length = size * 0.56
    return root, { Bar(root, length, 2, 45, 0.31, 0.5, color), Bar(root, length, 2, -45, 0.69, 0.5, color) }
end

local function CheckGlyph(parent, size, color)
    local root = Glyph(parent, size)
    Bar(root, size * 0.34, 2, 42, 0.3, 0.63, color)
    Bar(root, size * 0.64, 2, -48, 0.63, 0.51, color)
    return root
end

local function CloseGlyph(parent, size, color)
    local root = Glyph(parent, size)
    return { Bar(root, size * 0.78, 2, 45, 0.5, 0.5, color), Bar(root, size * 0.78, 2, -45, 0.5, 0.5, color) }
end

local function MinusGlyph(parent, size, color)
    local root = Glyph(parent, size)
    return { Bar(root, size * 0.7, 2, 0, 0.5, 0.5, color) }
end

-- A pill button: gradient fill (primary) or a white translucent card (secondary).
local function MakeButton(parent, text, primary, width)
    local pill = New("Frame", {
        Size = UDim2.fromOffset(width, 32),
        BackgroundColor3 = primary and Color3.new(1, 1, 1) or THEME.Card,
        BackgroundTransparency = primary and 0 or THEME.CardAlpha,
        BorderSizePixel = 0,
    }, parent)
    Round(pill, 9)
    if primary then Gradient(pill, 0) else Stroke(pill, THEME.StrokeAlpha) end
    local label = Label(pill, {
        Text = text,
        Font = FONT_TITLE,
        TextColor3 = primary and THEME.OnAccent or THEME.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
    })
    local hit = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3 }, pill)
    local button = { Frame = pill, Label = label, Hit = hit, Primary = primary, Width = width }
    hit.MouseButton1Down:Connect(function()
        Tween(pill, { Size = UDim2.fromOffset(width - 6, 28) }, 0.08)
    end)
    hit.MouseButton1Up:Connect(function()
        Tween(pill, { Size = UDim2.fromOffset(width, 32) }, 0.3, Enum.EasingStyle.Back)
    end)
    hit.MouseLeave:Connect(function()
        Tween(pill, { Size = UDim2.fromOffset(width, 32) }, 0.2)
    end)
    if not primary then
        hit.MouseEnter:Connect(function() Tween(pill, { BackgroundTransparency = 0.84 }, 0.15) end)
        hit.MouseLeave:Connect(function() Tween(pill, { BackgroundTransparency = THEME.CardAlpha }, 0.2) end)
    end
    return button
end

local function SetEnabled(button, enabled)
    button.Frame.BackgroundTransparency = enabled and (button.Primary and 0 or THEME.CardAlpha) or 0.6
    button.Label.TextTransparency = enabled and 0 or 0.45
end

-- A grid whose number of columns follows the width of its scroll frame: as many columns as fit with every cell at
-- least minCell wide (never fewer than 2). Resizing the window adds or removes columns. onChange (optional) runs
-- shortly after the columns changed, for grids that load content for the visible cells only.
local function ResponsiveGrid(scroll, gap, cellHeight, minCell, onChange)
    local layout = New("UIGridLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellSize = UDim2.new(1 / 3, -math.ceil(gap * 2 / 3), 0, cellHeight),
        CellPadding = UDim2.fromOffset(gap, gap),
    }, scroll)

    local columns, token = 3, 0
    local function Update()
        local width = scroll.AbsoluteWindowSize.X - 9 -- the scroll frame's own side padding
        if width <= 0 then return end
        local count = math.max(2, math.floor((width + gap) / (minCell + gap)))
        if count == columns then return end
        columns = count
        layout.CellSize = UDim2.new(1 / count, -math.ceil(gap * (count - 1) / count), 0, cellHeight)
        if onChange then
            token = token + 1
            local mine = token
            task.delay(0.15, function()
                if mine == token then onChange() end
            end)
        end
    end
    scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(Update)
    Update()
    return layout
end

-- The usual page layout: a row of panes (PaneHolder) above a bottom bar with a status line.
-- The script adds its own buttons to the bottom bar.
local BAR_H = 56
local function BuildPageLayout(frame)
    local paneHolder = New("Frame", { Name = "Panes", Size = UDim2.new(1, 0, 1, -BAR_H), BackgroundTransparency = 1 }, frame)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8),
    }, paneHolder)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    }, paneHolder)

    local bottomBar = New("Frame", {
        Name = "BottomBar",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, BAR_H),
        BackgroundTransparency = 1,
    }, frame)
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = THEME.Stroke,
        BackgroundTransparency = THEME.StrokeAlpha,
        BorderSizePixel = 0,
    }, bottomBar)

    local statusLabel = Label(bottomBar, {
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -290, 1, 0),
        TextColor3 = THEME.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    return { PaneHolder = paneHolder, BottomBar = bottomBar, StatusLabel = statusLabel }
end

-- ----------------------------------------------------------
-- The shell itself
-- ----------------------------------------------------------
local TOPBAR, SIDEBAR = 54, 150
local MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT = 340, 340, 1200, 760

local function CreateShell()
    local Shell = { ApiVersion = 1, Alive = true, Pages = {}, Active = nil }
    local connections, tweens = {}, {}
    local opened = true

    local function Spin(gradient, seconds)
        local tween = TweenService:Create(gradient, TweenInfo.new(seconds, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = gradient.Rotation + 360 })
        tween:Play()
        table.insert(tweens, tween)
    end

    local guiParent
    pcall(function() guiParent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not guiParent then guiParent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    local Gui = New("ScreenGui", {
        Name = "VisualSuite",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 10000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent)
    Shell.Gui = Gui

    local Main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(680, 470),
        BackgroundTransparency = 1,
    }, Gui)
    local MainScale = New("UIScale", { Scale = 1 }, Main)

    local Pop = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, Main)
    local PopScale = New("UIScale", { Scale = 0.9 }, Pop)

    -- neon glow rings behind the window
    local glowRings = {}
    for _, layer in ipairs({ { 0, 3, 0.5 }, { 3, 7, 0.8 }, { 10, 14, 0.92 } }) do
        local pad, thickness, transparency = layer[1], layer[2], layer[3]
        local ring = New("Frame", {
            Name = "Glow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, pad * 2, 1, pad * 2),
            BackgroundTransparency = 1,
        }, Pop)
        Round(ring, 16 + pad)
        local stroke = Stroke(ring, 1, thickness)
        Spin(Gradient(stroke, 0, CYCLE), 9)
        table.insert(glowRings, { Stroke = stroke, Base = transparency })
    end

    local Win = New("CanvasGroup", {
        Name = "Window",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = THEME.Background,
        BackgroundTransparency = THEME.BackgroundAlpha,
        GroupTransparency = 1,
        BorderSizePixel = 0,
    }, Pop)
    Round(Win, 16)

    -- glass wash + sheen
    local wash = New("Frame", { Name = "Wash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, Win)
    Gradient(wash, 35).Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0.9),
    })
    local sheen = New("Frame", { Name = "Sheen", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, Win)
    New("UIGradient", {
        Rotation = 20,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.92), NumberSequenceKeypoint.new(0.35, 1), NumberSequenceKeypoint.new(1, 0.97),
        }),
    }, sheen)

    -- spinning neon border above the window
    local border = New("Frame", { Name = "Border", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 }, Pop)
    Round(border, 16)
    local borderStroke = Stroke(border, 1, 1.5)
    Spin(Gradient(borderStroke, 0, CYCLE), 9)
    table.insert(glowRings, { Stroke = borderStroke, Base = 0.3 })

    -- topbar
    local TopBar = New("Frame", { Name = "Topbar", Size = UDim2.new(1, 0, 0, TOPBAR), BackgroundTransparency = 1 }, Win)

    local brand = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 16, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, TopBar)
    Round(brand, 9)
    Gradient(brand, 45)
    Label(brand, {
        Text = "V",
        Font = Enum.Font.GothamBlack,
        TextSize = 17,
        TextColor3 = THEME.OnAccent,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
    })

    local titleRow = New("Frame", {
        Position = UDim2.fromOffset(56, 8),
        Size = UDim2.new(1, -200, 0, 22),
        BackgroundTransparency = 1,
    }, TopBar)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
    }, titleRow)
    local titleLabel = Label(titleRow, {
        Text = "Visual",
        Font = FONT_TITLE,
        TextSize = 16,
        TextColor3 = Color3.new(1, 1, 1),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 20),
        LayoutOrder = 1,
    })
    Gradient(titleLabel, 0)

    local versionPill = New("Frame", {
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, titleRow)
    Round(versionPill, 8)
    New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, versionPill)
    Gradient(versionPill, 0)
    local versionLabel = Label(versionPill, {
        Text = "v2.0",
        Font = FONT_TITLE,
        TextSize = 11,
        TextColor3 = THEME.OnAccent,
        TextXAlignment = Enum.TextXAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 16),
    })

    Label(TopBar, {
        Text = "by Honami  ·  K to hide or show",
        TextSize = 12,
        TextColor3 = THEME.SubText,
        Position = UDim2.fromOffset(56, 30),
        Size = UDim2.new(1, -200, 0, 14),
    })

    local function ControlButton(offset, makeGlyph, hoverColor)
        local button = New("TextButton", {
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, offset, 0.5, 0),
            Size = UDim2.fromOffset(34, 34),
        }, TopBar)
        Round(button, 9)
        local bars = makeGlyph(button, 20, THEME.SubText)
        button.MouseEnter:Connect(function()
            Tween(button, { BackgroundTransparency = 0.88 }, 0.15)
            for _, bar in ipairs(bars) do Tween(bar, { BackgroundColor3 = hoverColor or THEME.Text }, 0.15) end
        end)
        button.MouseLeave:Connect(function()
            Tween(button, { BackgroundTransparency = 1 }, 0.2)
            for _, bar in ipairs(bars) do Tween(bar, { BackgroundColor3 = THEME.SubText }, 0.2) end
        end)
        return button
    end

    local CloseButton = ControlButton(-12, CloseGlyph, THEME.Danger)
    local MinimizeButton = ControlButton(-50, MinusGlyph)

    local topLine = New("Frame", {
        Position = UDim2.fromOffset(0, TOPBAR),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, Win)
    Gradient(topLine, 0).Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0.9),
    })

    local Body = New("Frame", {
        Name = "Body",
        Position = UDim2.fromOffset(0, TOPBAR + 1),
        Size = UDim2.new(1, 0, 1, -(TOPBAR + 1)),
        BackgroundTransparency = 1,
    }, Win)

    -- sidebar (only shown when two or more scripts share the window)
    local Sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, SIDEBAR, 1, 0),
        BackgroundColor3 = THEME.Sidebar,
        BackgroundTransparency = THEME.SidebarAlpha,
        BorderSizePixel = 0,
        Visible = false,
    }, Body)
    New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = THEME.Stroke,
        BackgroundTransparency = THEME.StrokeAlpha,
        BorderSizePixel = 0,
    }, Sidebar)
    local TabList = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, Sidebar)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 9),
    }, TabList)
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, TabList)

    local PageArea = New("Frame", { Name = "Pages", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, Body)

    -- ---------- layout ----------
    local function ViewportSize()
        local camera = workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(1280, 720)
    end

    local function PaintTab(page)
        local tab = page.Tab
        if not tab then return end
        local on = Shell.Active == page
        tab.Button.BackgroundTransparency = on and 0.78 or 1
        tab.Stroke.Color = on and THEME.Accent or THEME.Stroke
        tab.Stroke.Transparency = on and 0.45 or THEME.StrokeAlpha
        tab.Label.TextColor3 = on and THEME.Text or THEME.SubText
    end

    local function MakeTab(page)
        local button = New("TextButton", {
            Name = page.Id,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            LayoutOrder = page.Order,
            Size = UDim2.new(1, 0, 0, 38),
        }, TabList)
        Round(button, 10)
        Gradient(button, 0)
        local stroke = Stroke(button, THEME.StrokeAlpha)

        local badge = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 8, 0.5, 0),
            Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        }, button)
        Round(badge, 7)
        Gradient(badge, 45)
        Label(badge, {
            Text = page.Letter,
            Font = Enum.Font.GothamBlack,
            TextSize = 13,
            TextColor3 = THEME.OnAccent,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
        })
        local label = Label(button, {
            Text = page.TabTitle,
            Font = FONT_LABEL,
            Position = UDim2.fromOffset(38, 0),
            Size = UDim2.new(1, -44, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })

        page.Tab = { Button = button, Stroke = stroke, Label = label }
        button.MouseEnter:Connect(function()
            if Shell.Active ~= page then Tween(button, { BackgroundTransparency = 0.92 }, 0.12) end
        end)
        button.MouseLeave:Connect(function()
            if Shell.Active ~= page then Tween(button, { BackgroundTransparency = 1 }, 0.15) end
        end)
        button.MouseButton1Click:Connect(function() Shell:SelectPage(page) end)
    end

    function Shell:SelectPage(page)
        self.Active = page
        for _, other in ipairs(self.Pages) do
            other.Frame.Visible = other == page
            PaintTab(other)
        end
        if page.OnShow then task.defer(page.OnShow) end
    end

    local function Relayout()
        local count = #Shell.Pages
        if count == 0 then return end
        local combined = count >= 2

        Sidebar.Visible = combined
        PageArea.Position = UDim2.fromOffset(combined and SIDEBAR or 0, 0)
        PageArea.Size = UDim2.new(1, combined and -SIDEBAR or 0, 1, 0)

        local width, height = MIN_WIDTH, MIN_HEIGHT
        for _, page in ipairs(Shell.Pages) do
            width = math.max(width, page.Width)
            height = math.max(height, page.Height)
            if combined and not page.Tab then MakeTab(page) end
            if not combined and page.Tab then
                page.Tab.Button:Destroy()
                page.Tab = nil
            end
        end
        width = width + (combined and SIDEBAR or 0)

        if combined then
            titleLabel.Text = "Visual Suite"
        else
            titleLabel.Text = Shell.Pages[1].Title
        end

        -- small screens (phones) shrink the whole window so it fits
        local screen = ViewportSize()
        local scale = math.clamp(math.min(1, (screen.X - 24) / width, (screen.Y - 24) / height), 0.45, 1)
        MainScale.Scale = scale
        Tween(Main, { Size = UDim2.fromOffset(width, height) }, 0.3, Enum.EasingStyle.Quint)

        for _, page in ipairs(Shell.Pages) do PaintTab(page) end
    end

    -- A script adds its page here. spec: Id, Title (window title when alone), TabTitle, Letter, Order,
    -- Width, Height (preferred size of its content), Cleanup (called when the window is closed), OnShow.
    function Shell:AddPage(spec)
        local page = {
            Id = spec.Id,
            Title = spec.Title,
            TabTitle = spec.TabTitle or spec.Title,
            Letter = spec.Letter or string.sub(spec.Title, 1, 1),
            Order = spec.Order or 99,
            Width = spec.Width or 680,
            Height = spec.Height or 470,
            Cleanup = spec.Cleanup,
            OnShow = spec.OnShow,
        }
        page.Frame = New("Frame", { Name = page.Id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, PageArea)

        table.insert(self.Pages, page)
        table.sort(self.Pages, function(a, b) return a.Order < b.Order end)
        Relayout()
        self:SelectPage(page)
        if not opened then self:SetOpen(true) end
        return page
    end

    function Shell:RemovePage(id)
        for index, page in ipairs(self.Pages) do
            if page.Id == id then
                table.remove(self.Pages, index)
                if page.Tab then page.Tab.Button:Destroy() end
                page.Frame:Destroy()
                if self.Active == page then self.Active = nil end
                break
            end
        end
        if #self.Pages == 0 then
            self:Destroy()
            return
        end
        Relayout()
        if not self.Active then self:SelectPage(self.Pages[1]) end
    end

    function Shell:Destroy()
        if not self.Alive then return end
        self.Alive = false
        for _, tween in ipairs(tweens) do pcall(function() tween:Cancel() end) end
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        pcall(function() Gui:Destroy() end)
        if getgenv().VisualSuiteShell == self then getgenv().VisualSuiteShell = nil end
    end

    -- Every page puts its swaps / effects back, then the window goes away.
    function Shell:CloseAll()
        for _, page in ipairs(table.clone(self.Pages)) do
            if page.Cleanup then pcall(page.Cleanup) end
        end
        self:Destroy()
    end

    -- ---------- drag, resize ----------
    local dragging, dragStart, startPosition = false, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPosition = true, input.Position, Main.Position
        end
    end)

    local grip = New("TextButton", {
        Name = "ResizeGrip",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -4, 1, -4),
        Size = UDim2.fromOffset(22, 22),
        ZIndex = 8,
    }, Pop)
    Bar(grip, 14, 2, -45, 0.58, 0.58, THEME.Muted)
    Bar(grip, 7, 2, -45, 0.78, 0.78, THEME.Muted)

    local resizing, resizeStart, startSize, resizeOrigin = false, nil, nil, nil
    grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing, resizeStart, startSize, resizeOrigin = true, input.Position, Main.Size, Main.Position
        end
    end)

    -- Mouse buttons reuse one InputObject, so releases are caught once, here, instead of connecting
    -- to every press (those connections would pile up and fire on every later release).
    local pressed, moved, pressStart, pressPosition = false, false, nil, nil

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        local isMove = input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
        if not isMove then return end
        local scale = MainScale.Scale

        if dragging then
            local delta = (input.Position - dragStart) / scale
            Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end

        if resizing then
            local screen = ViewportSize()
            local delta = (input.Position - resizeStart) / scale
            local maxWidth = math.max(MIN_WIDTH, math.min(MAX_WIDTH, (screen.X - 24) / scale))
            local maxHeight = math.max(MIN_HEIGHT, math.min(MAX_HEIGHT, (screen.Y - 24) / scale))
            local width = math.clamp(startSize.X.Offset + delta.X, MIN_WIDTH, maxWidth)
            local height = math.clamp(startSize.Y.Offset + delta.Y, MIN_HEIGHT, maxHeight)
            Main.Size = UDim2.fromOffset(width, height)
            Main.Position = UDim2.new(
                resizeOrigin.X.Scale, resizeOrigin.X.Offset + (width - startSize.X.Offset) / 2,
                resizeOrigin.Y.Scale, resizeOrigin.Y.Offset + (height - startSize.Y.Offset) / 2
            )
        end

        if pressed then
            local delta = (input.Position - pressStart) / scale
            if delta.Magnitude * scale > 6 then moved = true end
            if moved then
                Shell.OpenButton.Position = UDim2.new(pressPosition.X.Scale, pressPosition.X.Offset + delta.X, pressPosition.Y.Scale, pressPosition.Y.Offset + delta.Y)
            end
        end
    end))

    -- ---------- minimize / open button ----------
    local OpenButton = New("TextButton", {
        Name = "OpenButton",
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 36, 0.5, 0),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = THEME.Popup,
        BackgroundTransparency = THEME.PopupAlpha,
        Visible = false,
    }, Gui)
    Shell.OpenButton = OpenButton
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, OpenButton)
    local OpenScale = New("UIScale", { Scale = 1 }, OpenButton)
    Spin(Gradient(Stroke(OpenButton, 0.15, 2), 0, CYCLE), 6)
    Spin(Gradient(Stroke(OpenButton, 0.7, 6), 0, CYCLE), 6)
    local openMark = Label(OpenButton, {
        Text = "V",
        Font = Enum.Font.GothamBlack,
        TextSize = 22,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
    })
    Gradient(openMark, 45)

    function Shell:SetOpen(state)
        if state == opened or not self.Alive then return end
        opened = state
        OpenScale.Scale = MainScale.Scale
        if state then
            Main.Visible = true
            PopScale.Scale = 0.9
            Tween(PopScale, { Scale = 1 }, 0.5, Enum.EasingStyle.Quint)
            Tween(Win, { GroupTransparency = 0 }, 0.3)
            for _, ring in ipairs(glowRings) do Tween(ring.Stroke, { Transparency = ring.Base }, 0.4) end
            Tween(OpenButton, { Size = UDim2.fromOffset(0, 0) }, 0.18)
            task.delay(0.18, function()
                if opened then OpenButton.Visible = false end
            end)
            if self.Active and self.Active.OnShow then task.defer(self.Active.OnShow) end
        else
            Tween(PopScale, { Scale = 0.92 }, 0.3, Enum.EasingStyle.Quint)
            Tween(Win, { GroupTransparency = 1 }, 0.24)
            for _, ring in ipairs(glowRings) do Tween(ring.Stroke, { Transparency = 1 }, 0.2) end
            task.delay(0.3, function()
                if not opened then Main.Visible = false end
            end)
            OpenButton.Visible = true
            Tween(OpenButton, { Size = UDim2.fromOffset(52, 52) }, 0.5, Enum.EasingStyle.Back)
        end
    end

    OpenButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pressed, moved, pressStart, pressPosition = true, false, input.Position, OpenButton.Position
        end
    end)

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging, resizing = false, false
        if pressed then
            pressed = false
            -- a tap (no drag) on the open button opens the window again
            if not moved then Shell:SetOpen(true) end
        end
    end))

    MinimizeButton.MouseButton1Click:Connect(function() Shell:SetOpen(false) end)

    table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.K then Shell:SetOpen(not opened) end
    end))

    -- ---------- close confirmation ----------
    local dialogOpen = false
    local function ConfirmClose()
        if dialogOpen then return end
        dialogOpen = true

        local overlay = New("TextButton", {
            Name = "Dialog",
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 50,
        }, Win)
        Tween(overlay, { BackgroundTransparency = 0.42 }, 0.25)

        local card = New("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0, 330, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = THEME.Popup,
            BackgroundTransparency = THEME.PopupAlpha,
            GroupTransparency = 1,
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 51,
        }, overlay)
        Round(card, 14)
        local outline = Stroke(card, 1, 1.4, Color3.new(1, 1, 1))
        Spin(Gradient(outline, 45, CYCLE), 8)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18),
            PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18),
        }, card)
        New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }, card)
        local cardScale = New("UIScale", { Scale = 0.9 }, card)
        Tween(cardScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Quint)
        Tween(card, { GroupTransparency = 0 }, 0.25)
        Tween(outline, { Transparency = 0.3 }, 0.25)

        local title = Label(card, {
            Text = "Close " .. titleLabel.Text .. "?",
            Font = FONT_TITLE,
            TextSize = 16,
            TextColor3 = Color3.new(1, 1, 1),
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            LayoutOrder = 1,
        })
        Gradient(title, 0)
        Label(card, {
            Text = "The interface will be closed and everything you swapped or applied will be put back to normal. Run the script again to reopen it.",
            TextSize = 14,
            TextColor3 = THEME.SubText,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            LayoutOrder = 2,
        })

        local row = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = 3 }, card)
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        }, row)

        local function CloseDialog()
            Tween(cardScale, { Scale = 0.93 }, 0.2)
            Tween(card, { GroupTransparency = 1 }, 0.2)
            Tween(outline, { Transparency = 1 }, 0.2)
            Tween(overlay, { BackgroundTransparency = 1 }, 0.2)
            task.delay(0.22, function()
                overlay:Destroy()
                dialogOpen = false
            end)
        end

        local function DialogButton(text, danger, order, callback)
            local button = New("TextButton", {
                Text = text,
                Font = FONT_TITLE,
                TextSize = 13,
                TextColor3 = danger and THEME.OnAccent or THEME.Text,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 36),
                BackgroundColor3 = danger and THEME.Danger or THEME.Card,
                BackgroundTransparency = danger and 0 or 0.84,
                LayoutOrder = order,
            }, row)
            Round(button, 9)
            New("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, button)
            button.MouseButton1Click:Connect(callback)
        end

        DialogButton("Cancel", false, 1, CloseDialog)
        DialogButton("Close", true, 2, function() Shell:CloseAll() end)
    end
    CloseButton.MouseButton1Click:Connect(ConfirmClose)

    -- open animation: pop in and fade the glow up
    Tween(PopScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
    Tween(Win, { GroupTransparency = 0 }, 0.35)
    for _, ring in ipairs(glowRings) do Tween(ring.Stroke, { Transparency = ring.Base }, 0.45) end

    return Shell
end

-- The shell shared by every Visual script that is running; the first one to start creates it.
local function GetShell()
    local existing = getgenv().VisualSuiteShell
    if existing and existing.Alive and existing.Gui and existing.Gui.Parent then return existing end
    local shell = CreateShell()
    getgenv().VisualSuiteShell = shell
    return shell
end


-- ==========================================================
-- This script
-- ==========================================================
local FOLDER = "VisualEmotes"
if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end

local cleanupFns = {}
local function RegisterCleanup(fn)
    table.insert(cleanupFns, fn)
end

local Shell, Page
local function ModuleCleanup()
    local fns = cleanupFns
    cleanupFns = {}
    for _, fn in ipairs(fns) do pcall(fn) end
    if Shell and Page then Shell:RemovePage(Page.Id) end
end

-- Run again while an older copy is still open: that copy puts everything back first.
local env = getgenv()
if env.VisualEmotesCleanup then pcall(env.VisualEmotesCleanup) end
env.VisualEmotesCleanup = ModuleCleanup

-- ==========================================================
-- Swap engine (ported from Games/Evade/VisualSwap.lua)
-- ==========================================================
local function NewSwap(config)
    local Swap = {}

    local CATEGORY = config.Category
    local PATHS = config.Paths or {}
    local WHITELIST = config.Whitelist or {}
    local NOUN = config.Noun or "item"

    local entries = {}
    local byInstance = {}
    local swapped = {}
    local originals = {}

    local function SpacedName(name)
        return (name:gsub("(%l)(%u)", "%1 %2"))
    end

    local function ResolvePath(path)
        local current = game
        for _, name in ipairs(string.split(path, ".")) do
            if name == "ReplicatedStorage" then
                current = ReplicatedStorage
            else
                current = current:FindFirstChild(name)
            end
            if not current then return nil end
        end
        return current
    end

    local loaded = false
    local source = "none"

    local function AddEntry(instance, id)
        if byInstance[instance] then return end

        local info
        local ok, result = pcall(require, instance)
        if ok and type(result) == "table" then info = result end
        local display = info and info.AppearanceInfo and info.AppearanceInfo.Name
        local header = info and info.UIInfo and info.UIInfo.Header

        local entry = {
            Name = instance.Name,
            Display = type(display) == "string" and display or SpacedName(instance.Name),
            Header = type(header) == "string" and header or "Other",
            Id = id,
            Instance = instance,
        }
        table.insert(entries, entry)
        byInstance[instance] = entry
    end

    local function LoadFromRegistry()
        local items = ReplicatedStorage:FindFirstChild("Items")
        local registryModule = items and items:FindFirstChild("Registry")
        if not registryModule then return false end

        local ok, Registry = pcall(require, registryModule)
        if not ok or type(Registry) ~= "table" or type(Registry.GetByCategory) ~= "function" then return false end

        local okList, list = pcall(Registry.GetByCategory, CATEGORY)
        if not okList or type(list) ~= "table" then return false end

        for id, record in pairs(list) do
            local module = type(record) == "table" and record.Module
            if typeof(module) == "Instance" then AddEntry(module, id) end
        end
        return #entries > 0
    end

    local function LoadFromPaths()
        for _, path in ipairs(PATHS) do
            local instance = ResolvePath(path)
            if instance then AddEntry(instance) end
        end
    end

    local function LoadFromScan()
        local items = ReplicatedStorage:FindFirstChild("Items")
        if not items then return end
        for _, descendant in ipairs(items:GetDescendants()) do
            if descendant:IsA("ModuleScript") then
                local inCategory = false
                local parent = descendant.Parent
                while parent and parent ~= items do
                    if parent:IsA("Folder") and parent.Name == CATEGORY then
                        inCategory = true
                        break
                    end
                    parent = parent.Parent
                end
                if inCategory then AddEntry(descendant) end
            end
        end
    end

    function Swap.Load()
        if loaded then return #entries end
        loaded = true

        if not ReplicatedStorage:FindFirstChild("Items") then
            pcall(function() ReplicatedStorage:WaitForChild("Items", 8) end)
        end

        if LoadFromRegistry() then
            source = "registry"
        else
            table.clear(entries)
            table.clear(byInstance)
            LoadFromPaths()
            source = "paths"
            if #entries == 0 then
                LoadFromScan()
                source = "scan"
            end
        end

        table.sort(entries, function(a, b)
            return string.lower(a.Display) < string.lower(b.Display)
        end)
        return #entries
    end

    function Swap.GetSource()
        return source
    end

    function Swap.GetEntries()
        return entries
    end

    function Swap.GetWhitelist(entry)
        return entry and WHITELIST[entry.Name] or nil
    end

    function Swap.GetPartner(entry)
        local partner = entry and swapped[entry.Instance]
        return partner and byInstance[partner] or nil
    end

    -- 1 = belum bisa, 2 = bisa ditukar, 3 = pasangan yang sudah tertukar (tombol jadi Revert)
    function Swap.GetState(base, target)
        if not base or not target or base == target then return 1 end
        if swapped[base.Instance] == target.Instance then return 3 end
        if swapped[base.Instance] ~= nil or swapped[target.Instance] ~= nil then return 1 end
        return 2
    end

    local function CacheOriginal(item)
        if not originals[item] then
            originals[item] = {}
            for _, child in ipairs(item:GetChildren()) do
                table.insert(originals[item], child:Clone())
            end
        end
    end

    local function InjectContents(targetItem, sourceItem)
        for _, child in ipairs(targetItem:GetChildren()) do
            child:Destroy()
        end
        for _, child in ipairs(originals[sourceItem]) do
            child:Clone().Parent = targetItem
        end
    end

    function Swap.Swap(base, target)
        if Swap.GetState(base, target) ~= 2 then
            return false, "Please make sure you picked a valid Base and Target " .. NOUN .. "."
        end

        local ok, err = pcall(function()
            CacheOriginal(base.Instance)
            CacheOriginal(target.Instance)
            InjectContents(base.Instance, target.Instance)
            InjectContents(target.Instance, base.Instance)
        end)
        if not ok then return false, "The swap failed: " .. tostring(err) end

        swapped[base.Instance] = target.Instance
        swapped[target.Instance] = base.Instance
        return true, base.Display .. " ⇌ " .. target.Display
    end

    function Swap.Revert(base, target)
        if Swap.GetState(base, target) ~= 3 then
            return false, "These two " .. NOUN .. "s are not swapped."
        end

        local ok, err = pcall(function()
            InjectContents(base.Instance, base.Instance)
            InjectContents(target.Instance, target.Instance)
        end)
        if not ok then return false, "The revert failed: " .. tostring(err) end

        swapped[base.Instance] = nil
        swapped[target.Instance] = nil
        return true, base.Display .. " and " .. target.Display .. " were restored."
    end

    function Swap.RevertAll()
        local restored, touched = 0, {}
        for instance, partner in pairs(table.clone(swapped)) do
            if swapped[instance] == partner then
                local entry, other = byInstance[instance], byInstance[partner]
                if entry and other and Swap.Revert(entry, other) then
                    restored = restored + 1
                    table.insert(touched, entry)
                    table.insert(touched, other)
                end
            end
        end
        return restored, touched
    end

    RegisterCleanup(function()
        pcall(Swap.RevertAll)
    end)

    return Swap
end

-- ==========================================================
-- Preview: frozen-pose viewport models for the emote grid
-- (ported from Games/Evade/EmotePreview.lua; the Carry/mannequin branch is dropped - this
-- script only ever renders emotes)
-- ==========================================================
local Preview = {}
do
    local TRACK_TIMEOUT = 5
    local SETTLE_FRAMES = 2
    local POSE_TIME = 0.5
    local MAX_HOSTS = 3
    local COLLECT_GAP = 0.12

    local POSE_FILE = FOLDER .. "/EmotePoses.json"
    local POSE_VERSION = 1

    local alive = true
    local hostGui = nil
    local hosts = {}
    local cache = {}
    local inflight = {}
    local inflightPose = {}
    local poses = nil
    local poseToken = 0

    local function HeartbeatWait(frames)
        for _ = 1, frames or 1 do RunService.Heartbeat:Wait() end
    end

    local function IsR15()
        local ok, rigType = pcall(function() return Players.LocalPlayer:GetAttribute("RigType") end)
        if ok and rigType ~= nil then return rigType == "R15" end
        return true
    end

    local function AssetItem(name)
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        local items = assets and assets:FindFirstChild("Items")
        return items and items:FindFirstChild(name)
    end

    local function RigTemplate(r15)
        return AssetItem(r15 and "VisualRigR15Emote" or "VisualRigClassic")
    end

    function Preview.Available()
        return RigTemplate(IsR15()) ~= nil
    end

    local function LoadPoses()
        if poses then return poses end
        poses = {}
        if readfile and isfile and isfile(POSE_FILE) then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(POSE_FILE)) end)
            if ok and type(decoded) == "table" and decoded.Version == POSE_VERSION and type(decoded.Poses) == "table" then
                poses = decoded.Poses
            end
        end
        return poses
    end

    local function FlushPoses()
        poseToken = poseToken + 1
        if not (poses and writefile) then return end
        pcall(function()
            if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end
            writefile(POSE_FILE, HttpService:JSONEncode({ Version = POSE_VERSION, Poses = poses }))
        end)
    end

    local function SavePosesSoon()
        poseToken = poseToken + 1
        local mine = poseToken
        task.delay(3, function()
            if mine == poseToken then FlushPoses() end
        end)
    end

    local function JointPath(rig, joint)
        local names = {}
        local node = joint
        while node and node ~= rig do
            table.insert(names, 1, node.Name)
            node = node.Parent
        end
        return table.concat(names, "/")
    end

    local IDENTITY = { 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }

    local function IsIdentity(components)
        for index, value in ipairs(IDENTITY) do
            if math.abs((components[index] or 0) - value) > 0.0001 then return false end
        end
        return true
    end

    local function CapturePose(rig)
        local pose = {}
        for _, descendant in ipairs(rig:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                local components = { descendant.Transform:GetComponents() }
                if not IsIdentity(components) then pose[JointPath(rig, descendant)] = components end
            end
        end
        return pose
    end

    local function HasMotion(rig)
        for _, descendant in ipairs(rig:GetDescendants()) do
            if descendant:IsA("Motor6D") and not IsIdentity({ descendant.Transform:GetComponents() }) then return true end
        end
        return false
    end

    local function ApplyPose(rig, pose)
        for _, descendant in ipairs(rig:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                local components = pose[JointPath(rig, descendant)]
                descendant.Transform = components and CFrame.new(table.unpack(components)) or CFrame.new()
            end
        end
    end

    local function EnsureGui()
        if hostGui and hostGui.Parent then return hostGui end

        local parent
        pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not parent then parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

        hostGui = Instance.new("ScreenGui")
        hostGui.Name = "VisualEmotesPreview"
        hostGui.ResetOnSpawn = false
        hostGui.DisplayOrder = -10
        hostGui.IgnoreGuiInset = true
        hostGui.Parent = parent
        table.clear(hosts)
        return hostGui
    end

    local function AcquireHost()
        while alive do
            local gui = EnsureGui()
            for _, entry in ipairs(hosts) do
                if not entry.InUse and entry.Frame.Parent then
                    entry.InUse = true
                    return entry
                end
            end
            if #hosts < MAX_HOSTS then
                local frame = Instance.new("ViewportFrame")
                frame.Name = "Host" .. (#hosts + 1)
                frame.Size = UDim2.fromOffset(8, 8)
                frame.Position = UDim2.fromOffset(0, 0)
                frame.BackgroundTransparency = 1
                frame.ImageTransparency = 0.98
                frame.Parent = gui
                local entry = { Frame = frame, InUse = true }
                table.insert(hosts, entry)
                return entry
            end
            task.wait(0.03)
        end
        return nil
    end

    local function Variant(item)
        local selection = item:FindFirstChild("Selection")
        if selection then return selection:GetChildren()[1] or item end
        return item
    end

    local function FindEmoteAnimation(item, r15)
        if item:FindFirstChild("Animations") or item:FindFirstChild("Selection") then
            local container = item:FindFirstChild("Selection") and Variant(item) or item
            local animations = container:FindFirstChild("Animations")
            local folder = animations and animations:FindFirstChild(r15 and "R15" or "R6")
            local animation = folder and folder:FindFirstChild("Animation")
            if animation and animation.AnimationId ~= "" then return animation end
            return nil
        end
        return item:FindFirstChild(r15 and "Animation" or "AnimationClassic")
    end

    local function PoseJobs(entry, r15)
        local jobs = {}
        local animation = FindEmoteAnimation(entry.Instance, r15)
        if animation then table.insert(jobs, { Name = "Rig", Animation = animation, Prefix = r15 and "R15:" or "R6:", Template = RigTemplate(r15) }) end
        return jobs
    end

    local function PoseKey(job)
        return job.Prefix .. tostring(job.Animation.AnimationId)
    end

    local function RootOffset(model)
        local root = model:FindFirstChild("HumanoidRootPart")
        if not (root and root:IsA("BasePart")) then return 0 end

        local lowest = math.huge
        for _, name in ipairs({ "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }) do
            local part = model:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                local half = part.Size / 2
                for _, sx in ipairs({ -1, 1 }) do
                    for _, sy in ipairs({ -1, 1 }) do
                        for _, sz in ipairs({ -1, 1 }) do
                            lowest = math.min(lowest, (part.CFrame * Vector3.new(sx * half.X, sy * half.Y, sz * half.Z)).Y)
                        end
                    end
                end
            end
        end
        if lowest == math.huge then return 0 end
        return root.Position.Y - lowest - 2.75
    end

    local function AttachProps(rig, item, r15)
        local template = Variant(item):FindFirstChild(r15 and "Character" or "CharacterClassic")
        if not template then return end

        local ok, copy = pcall(function() return template:Clone() end)
        if not ok or not copy then return end

        local emoteModel = copy:FindFirstChild("EmoteModel")
        if not emoteModel then
            copy:Destroy()
            return
        end

        local primary = rig:FindFirstChild("HumanoidRootPart", true) or rig.PrimaryPart
        local target = rig:FindFirstChild("R15Visual") or rig
        local offset = CFrame.new(0, RootOffset(copy), 0)

        emoteModel.Parent = target
        for _, child in ipairs(emoteModel:GetChildren()) do
            if (child:IsA("Motor6D") or child:IsA("Weld")) and child.Part0 and child.Part0.Parent == copy then
                if child.Part0.Name == "HumanoidRootPart" then
                    child.Part0 = primary
                    child.C0 = offset * child.C0
                else
                    child.Part0 = target:FindFirstChild(child.Part0.Name)
                end
            end
        end
        copy:Destroy()
    end

    local function GetAnimator(rig)
        local controller = rig:FindFirstChildWhichIsA("AnimationController", true) or rig:FindFirstChildWhichIsA("Humanoid", true)
        if not controller then return nil end
        return controller:FindFirstChildOfClass("Animator") or (function()
            local animator = Instance.new("Animator")
            animator.Parent = controller
            return animator
        end)()
    end

    local function SolveJoints(container, solved)
        if not solved then
            local root = container:FindFirstChild("HumanoidRootPart", true) or container.PrimaryPart
            if not root then return false end
            solved = { [root] = true }
        end

        local joints = {}
        for _, descendant in ipairs(container:GetDescendants()) do
            if descendant:IsA("Motor6D") or descendant:IsA("Weld") then
                if descendant.Part0 and descendant.Part1 then table.insert(joints, descendant) end
            end
        end

        local progress = true
        while progress do
            progress = false
            for _, joint in ipairs(joints) do
                local part0, part1 = joint.Part0, joint.Part1
                local transform = joint:IsA("Motor6D") and joint.Transform or CFrame.new()
                if solved[part0] and not solved[part1] then
                    part1.CFrame = part0.CFrame * joint.C0 * transform * joint.C1:Inverse()
                    solved[part1] = true
                    progress = true
                elseif solved[part1] and not solved[part0] then
                    part0.CFrame = part1.CFrame * joint.C1 * transform:Inverse() * joint.C0:Inverse()
                    solved[part0] = true
                    progress = true
                end
            end
        end
        return true
    end

    local function Orient(model)
        local primary = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart", true)
        if not primary then return end

        local inverse = primary.CFrame:Inverse()
        local base = CFrame.new(primary.Position)
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then descendant.CFrame = base * (inverse * descendant.CFrame) end
        end
    end

    local STRIP_CLASSES = {
        "Motor6D", "Weld", "ManualWeld", "WeldConstraint", "Snap", "Constraint",
        "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Explosion", "Highlight", "ForceField",
        "PointLight", "SpotLight", "SurfaceLight", "WrapTarget", "WrapLayer",
        "AnimationController", "Humanoid", "Animator", "LuaSourceContainer", "Sound",
    }

    local function ShouldStrip(instance)
        for _, class in ipairs(STRIP_CLASSES) do
            if instance:IsA(class) then return true end
        end
        return instance:IsA("Attachment") and not instance:IsA("Bone")
    end

    local function Freeze(source, name)
        local copy = source:Clone()
        copy.Name = name
        for _, descendant in ipairs(copy:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Anchored = true
                descendant.CastShadow = false
                descendant.CanCollide = false
                descendant.CanQuery = false
                descendant.CanTouch = false
            end
        end
        for _, descendant in ipairs(copy:GetDescendants()) do
            if ShouldStrip(descendant) then pcall(function() descendant:Destroy() end) end
        end
        Orient(copy)
        return copy
    end

    local function BuildEmoteModel(entry, r15, poseOf)
        local template = RigTemplate(r15)
        if not template then return nil, "the game's preview rig was not found" end

        local rig = template:Clone()
        AttachProps(rig, entry.Instance, r15)
        if poseOf.Rig then ApplyPose(rig, poseOf.Rig) end
        SolveJoints(rig)
        local model = Freeze(rig, entry.Display)
        pcall(function() rig:Destroy() end)
        return model
    end

    local function EnsurePose(job)
        local key = PoseKey(job)
        local store = LoadPoses()
        if store[key] then return store[key] end

        while inflightPose[key] do
            task.wait(0.03)
            if not alive then return nil, "unloaded" end
        end
        if store[key] then return store[key] end
        inflightPose[key] = true

        local hostEntry = AcquireHost()
        if not hostEntry then
            inflightPose[key] = nil
            return nil, "unloaded"
        end

        local pose, failure
        local world
        local ok, err = pcall(function()
            world = Instance.new("WorldModel")
            world.Parent = hostEntry.Frame

            local rig = job.Template:Clone()
            rig.Parent = world

            local animator = GetAnimator(rig)
            if not animator then
                failure = "the preview rig has no animator"
                return
            end

            local track = animator:LoadAnimation(job.Animation)
            track.Priority = Enum.AnimationPriority.Action3
            track:Play(0)
            track:AdjustSpeed(0)

            local limit = os.clock() + TRACK_TIMEOUT
            while alive and os.clock() < limit and track.Length <= 0 and not HasMotion(rig) do HeartbeatWait(1) end
            if track.Length <= 0 and not HasMotion(rig) then
                failure = "the animation did not load (" .. tostring(job.Animation.AnimationId) .. ")"
                return
            end

            track.TimePosition = math.min(POSE_TIME, track.Length)
            HeartbeatWait(SETTLE_FRAMES)
            pose = CapturePose(rig)
        end)

        if world then pcall(function() world:Destroy() end) end
        hostEntry.InUse = false
        inflightPose[key] = nil

        if not ok then return nil, tostring(err) end
        if not pose then return nil, failure or "preview failed" end

        store[key] = pose
        SavePosesSoon()
        return pose
    end

    function Preview.Get(entry)
        return entry and cache[entry.Instance] or nil
    end

    function Preview.PoseKnown(entry)
        local store = LoadPoses()
        for _, job in ipairs(PoseJobs(entry, IsR15())) do
            if not store[PoseKey(job)] then return false end
        end
        return true
    end

    function Preview.Invalidate(entry)
        local model = entry and cache[entry.Instance]
        if model then
            cache[entry.Instance] = nil
            pcall(function() model:Destroy() end)
        end
    end

    function Preview.Preload(entries)
        local r15 = IsR15()
        local store = LoadPoses()
        local list = {}
        for _, entry in ipairs(entries) do
            for _, job in ipairs(PoseJobs(entry, r15)) do
                if not store[PoseKey(job)] then table.insert(list, job.Animation) end
            end
        end
        if #list == 0 then return end
        task.spawn(function()
            pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
        end)
    end

    function Preview.Bake(entry)
        if not alive then return nil, "unloaded" end
        local cached = cache[entry.Instance]
        if cached then return cached end

        local r15 = IsR15()

        while inflight[entry.Instance] do
            task.wait(0.03)
            if not alive then return nil, "unloaded" end
        end
        cached = cache[entry.Instance]
        if cached then return cached end
        inflight[entry.Instance] = true

        local model, failure
        local ok, err = pcall(function()
            local poseOf = {}
            for _, job in ipairs(PoseJobs(entry, r15)) do
                local pose, reason = EnsurePose(job)
                if not pose then
                    failure = reason
                    return
                end
                poseOf[job.Name] = pose
            end
            model, failure = BuildEmoteModel(entry, r15, poseOf)
        end)
        inflight[entry.Instance] = nil

        if not ok then return nil, tostring(err) end
        if not model then return nil, failure or "preview failed" end
        if not alive then
            model:Destroy()
            return nil, "unloaded"
        end

        cache[entry.Instance] = model
        return model
    end

    function Preview.Collect(entries)
        local r15 = IsR15()
        local store = LoadPoses()
        local collected = 0
        for _, entry in ipairs(entries) do
            if not alive then break end
            for _, job in ipairs(PoseJobs(entry, r15)) do
                if not store[PoseKey(job)] then
                    if EnsurePose(job) then collected = collected + 1 end
                    task.wait(COLLECT_GAP)
                end
            end
        end
        return collected
    end

    RegisterCleanup(function()
        alive = false
        FlushPoses()
        for instance, model in pairs(cache) do pcall(function() model:Destroy() end) cache[instance] = nil end
        if hostGui then pcall(function() hostGui:Destroy() end) hostGui = nil end
        table.clear(hosts)
    end)
end

-- ==========================================================
-- Fallback path list (same as Mugiwara HUB, in case the game's own Registry can't be found)
-- ==========================================================
local DaftarPath = {
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

    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Banger",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.GalacticBound",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.GamingTime",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.HeliosChariot",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Outlaw",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.StealthyBox",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.TouchGrass",
    "ReplicatedStorage.Items.ItemPacks.Base.LevelShop.Emotes.Writhing",

    "ReplicatedStorage.Items.ItemPacks.Base.NewShop.Emotes.Popular",
    "ReplicatedStorage.Items.ItemPacks.Base.NewShop.Emotes.SightlessDance",

    "ReplicatedStorage.Items.ItemPacks.Base.Special.Emotes.Bhop",

    "ReplicatedStorage.Items.ItemPacks.Collab.ST.Emotes.WinterOf85",

    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Broom",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.FrightFunk",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.PumpItUp",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Reanimated",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.RockinStride",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.Thriller",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Halloween2022.Emotes.WerewolfHowl",

    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.CyberBroom",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.DeadBoneStride",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.GhastlyGrimoire",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.GhoulishGalleon",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.HeadlessBaller",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.Xylobone",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Halloween2024.Emotes.ZombieStride",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.CuerdasDelAlma",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.GraveRider",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.HeadlessHorseman",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.MariachiBand",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.ScorchedEarth",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Hlwn2025.Emotes.SpiritedAway",

    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.CampfireDoze",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.ChristmasBoogie",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.FlyingSleigh",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.Marching",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.Nutcracker",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.SnowmobileCruise",
    "ReplicatedStorage.Items.ItemPacks.Events.2022.Xmas2022.Emotes.WindupDance",

    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.BobointheBox",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.IceFishing",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.RudolphMount",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SantaMech",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SledDrifting",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.SnowmanConstruction",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.ToyTrainRide",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.WindUpPose",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Xmas2024.Emotes.WinterRide",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.CozyChair",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.FrostDrake",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.RockingHorse",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.SkiSpree",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.Battlepass.WinterMelody",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.XMAS25.Emotes.DailyShop.SnowAngel",

    "ReplicatedStorage.Items.ItemPacks.Events.2024.StPatricks2024.Emotes.AvariceLounge",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.StPatricks2024.Emotes.IrishJig",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.StPatricks2025.Emotes.AprilShower",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.StPatricks2025.Emotes.GoldRitual",

    "ReplicatedStorage.Items.ItemPacks.Events.2026.StPatricks2026.Emotes.AuspiciousWell",

    "ReplicatedStorage.Items.ItemPacks.Events.2024.Valentines2024.Emotes.AngelicWings",
    "ReplicatedStorage.Items.ItemPacks.Events.2024.Valentines2024.Emotes.HarpRecital",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.Valentines2025.Emotes.SerenePerch",

    "ReplicatedStorage.Items.ItemPacks.Events.2026.Valentines2026.Emotes.DreamyCloud",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Valentines2026.Emotes.ValentineComputer",

    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.BeachChairLounge",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.CasualSurfing",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.LemonadeStand",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.ManyFans",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.PoolTime",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.RowBoat",
    "ReplicatedStorage.Items.ItemPacks.Events.2025.Summer2025.Emotes.SummerDays",

    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.AquaticDaydreamer",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.AstralMantaRay",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.ClamClamor",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.EncapsulatedBubble",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.FrutigerFloatie",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.LeapingDolphin",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.SubmarineRide",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.SUMMER26.Emotes.SummerLowrider",

    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.CoccoonRebirth",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.HoneyPool",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.LadybugFlight",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.LotusSwing",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.MegaflyJet",
    "ReplicatedStorage.Items.ItemPacks.Events.2026.Spring2026.Emotes.SnailMail",

    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.LunarNewYear.Emotes.DynastyDrumming",

    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.NewYears2024.Emotes.FireworkBlast",

    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicDance",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicJeep",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.ClassicStride",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.FastFoodDelight",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.PotionMash",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.RainingTacos",
    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.OldRoblox.Emotes.SkateboardStroll",

    "ReplicatedStorage.Items.ItemPacks.EventsDailyShop.Thanksgiving2025.Emotes.TurkeyJockey",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.QueensAppearance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.RegalWalk",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.BeeSet.Emotes.WingedRoyalSit",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.MountedSeahorse",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.NeptunesThrone",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.PoseidonSet.Emotes.ShellHermit",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.AstroSlide",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.BananaDance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.CrabRave",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.CuddleBearSit",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.2026.RelicEmotesNew.Emotes.HitTheJackpot",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.Military.Emotes.Rocket",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.Military.Emotes.Tank",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Legacy.StPatricks2023.Emotes.MarchShowcase",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.DuckyMarch",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.Sleepybara",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Animals.Emotes.TurtleHobble",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Cats.Emotes.CatParty",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.DogSet.Emotes.DogParty",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.DogSet.Emotes.FreshFlop",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarBike",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarConqueror",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EclipseSet.Emotes.SolarSlayer",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Boneless",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Gangnam",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Griddy",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.LDance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.EmotePack.Emotes.Macarena",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.Gems.Emotes.HoveringCrystal",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.LunarNewYearSet.Emotes.FlyingFish",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Caffeinated",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.CatDance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Frolic",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.OiiaOiia",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.MusicEmotesPack1.Emotes.Wess",

    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.Bumblebee",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.RockefellerStreet",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.ShubaDance",
    "ReplicatedStorage.Items.ItemPacks.Gamepass.Unorganized.RelicEmotesVaulted.Emotes.Twist",

    "ReplicatedStorage.Items.ItemPacks.Integration.M3GAN.Emotes.M3GANDance",
    "ReplicatedStorage.Items.ItemPacks.Integration.M3GAN.Emotes.RobotM3GAN",
}


-- ==========================================================
-- Page in the shared window
-- ==========================================================
Shell = GetShell()
Page = Shell:AddPage({
    Id = "Emotes",
    Title = "Visual Emotes",
    TabTitle = "Emotes",
    Letter = "E",
    Order = 1,
    Width = 680,
    Height = 470,
    Cleanup = ModuleCleanup,
})
local PageLayout = BuildPageLayout(Page.Frame)
local PaneHolder, StatusLabel = PageLayout.PaneHolder, PageLayout.StatusLabel
local RevertAllButton = MakeButton(PageLayout.BottomBar, "Revert All", false, 104)
RevertAllButton.Frame.AnchorPoint = Vector2.new(1, 0.5)
RevertAllButton.Frame.Position = UDim2.new(1, -12, 0.5, 0)
local SwapButton = MakeButton(PageLayout.BottomBar, "Swap", true, 140)
SwapButton.Frame.AnchorPoint = Vector2.new(1, 0.5)
SwapButton.Frame.Position = UDim2.new(1, -128, 0.5, 0)

-- ==========================================================
-- Emote grid logic (ported from Games/Evade/VisualGridUI.lua, rebuilt on the UI above)
-- ==========================================================
local HEADER_ORDER = { "Normal", "Gamepasses", "Halloween", "Winter Holidays", "Summer", "Spring", "Valentines", "Event", "Special" }

local function BuildGroups(entries)
    local byHeader = {}
    for _, entry in ipairs(entries) do
        byHeader[entry.Header] = byHeader[entry.Header] or {}
        table.insert(byHeader[entry.Header], entry)
    end

    local order, seen = {}, {}
    for _, header in ipairs(HEADER_ORDER) do
        if byHeader[header] then
            table.insert(order, header)
            seen[header] = true
        end
    end
    local rest = {}
    for header in pairs(byHeader) do
        if not seen[header] then table.insert(rest, header) end
    end
    table.sort(rest)
    for _, header in ipairs(rest) do table.insert(order, header) end

    local groups = {}
    for _, header in ipairs(order) do
        table.insert(groups, { Title = header, Entries = byHeader[header] })
    end
    return groups
end

-- Same camera as the game's emote menu: in front, a little to the right and above.
local LOOK_DIRECTION = Vector3.new(4.25, 1.7, -8.5).Unit
local CELL_HEIGHT, TITLE_HEIGHT, GAP = 108, 20, 6

local function BuildEmoteUI(Swap)
    if Swap.Load() == 0 then
        Label(PaneHolder, {
            Text = "No emotes were found in this game. The game may have changed its item folders.",
            TextWrapped = true,
            TextColor3 = THEME.SubText,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
        })
        SwapButton.Frame.Visible = false
        RevertAllButton.Frame.Visible = false
        return
    end

    local groups = BuildGroups(Swap.GetEntries())
    local byName = {}
    for _, entry in ipairs(Swap.GetEntries()) do byName[entry.Name] = entry end
    local sides = {}
    local failedPreview = {}
    local previewState = nil
    local statusToken = 0
    local Refresh, RefreshVisible

    local function TitleOf(entry)
        local partner = Swap.GetPartner(entry)
        return partner and (entry.Display .. " (" .. partner.Display .. ")") or entry.Display
    end

    local function ShowHint()
        local base, target = sides.Base.Selected, sides.Target.Selected
        local state = Swap.GetState(base, target)
        if state == 3 then
            StatusLabel.Text = base.Display .. " looks like " .. target.Display .. " (swapped)"
        elseif state == 2 then
            StatusLabel.Text = "Ready: " .. base.Display .. " will look like " .. target.Display
        else
            StatusLabel.Text = "Pick a Base and a Target emote."
        end
        StatusLabel.TextColor3 = THEME.SubText
    end

    local function SetStatus(text, color)
        statusToken = statusToken + 1
        local mine = statusToken
        StatusLabel.Text = text
        StatusLabel.TextColor3 = color or THEME.SubText
        task.delay(3.5, function()
            if mine == statusToken then ShowHint() end
        end)
    end

    local function PreviewsOn()
        if previewState == nil then
            previewState = Preview.Available() and true or false
            if not previewState then SetStatus("Previews are not available in this game version.", THEME.Danger) end
        end
        return previewState
    end

    -- ---------- cells ----------
    local function AttachView(tile)
        if tile.View then return end
        local model = Preview.Get(tile.Entry)
        if not model then return end

        local view = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Ambient = Color3.fromRGB(190, 190, 190),
            LightColor = Color3.fromRGB(255, 255, 255),
        }, tile.Thumb)
        local clone = model:Clone()
        clone.Parent = view

        local cf, size = clone:GetBoundingBox()
        local radius = math.max(size.X, size.Y, size.Z) / 2
        local distance = radius / math.tan(math.rad(15)) * 1.1
        local viewCamera = New("Camera", { FieldOfView = 30 }, view)
        viewCamera.CFrame = CFrame.lookAt(cf.Position + LOOK_DIRECTION * distance, cf.Position)
        view.CurrentCamera = viewCamera

        tile.View = view
        tile.Placeholder.Visible = false
    end

    local function DetachView(tile)
        if tile.View then
            tile.View:Destroy()
            tile.View = nil
        end
        tile.Placeholder.Visible = true
    end

    local function PaintTile(side, tile, hovered)
        local on = side.Selected == tile.Entry
        -- already swapped: the whole cell is tinted gold so it stands out in the list
        local swapped = Swap.GetPartner(tile.Entry) ~= nil
        tile.Button.BackgroundColor3 = swapped and THEME.Swapped or Color3.new(1, 1, 1)
        tile.Button.BackgroundTransparency = swapped and (on and 0.68 or (hovered and 0.74 or 0.8)) or (on and 0.82 or (hovered and 0.9 or 0.95))
        tile.Badge.Visible = on
        tile.Stroke.Color = on and THEME.Accent or (swapped and THEME.Swapped or THEME.Stroke)
        tile.Stroke.Transparency = on and 0.2 or (swapped and 0.35 or (hovered and 0.7 or THEME.StrokeAlpha))
        tile.Stroke.Thickness = (on or swapped) and 1.5 or 1
    end

    local function Pick(side, entry)
        side.Selected = (side.Selected ~= entry) and entry or nil
        Refresh()
        if side.Selected and Swap.GetWhitelist(side.Selected) then
            SetStatus("Whitelist applied! This emote is restricted to a specific pair.", THEME.Swapped)
        end
    end

    local function MakeTile(side, entry)
        local button = New("TextButton", {
            Name = entry.Name,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.95,
        }, side.Scroll)
        Round(button, 10)
        local stroke = Stroke(button, THEME.StrokeAlpha)

        local thumb = New("Frame", {
            Name = "Thumb",
            Position = UDim2.fromOffset(5, 5),
            Size = UDim2.new(1, -10, 0, CELL_HEIGHT - 10 - TITLE_HEIGHT),
            BackgroundColor3 = THEME.Field,
            BackgroundTransparency = THEME.FieldAlpha,
            ClipsDescendants = true,
            BorderSizePixel = 0,
        }, button)
        Round(thumb, 7)
        local placeholder = Label(thumb, {
            Text = "…",
            TextSize = 18,
            TextColor3 = THEME.Muted,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
        })
        local name = Label(button, {
            Text = TitleOf(entry),
            Font = FONT_LABEL,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 6, 0, CELL_HEIGHT - TITLE_HEIGHT - 2),
            Size = UDim2.new(1, -12, 0, TITLE_HEIGHT),
        })

        local badge = New("Frame", {
            Name = "Badge",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -9, 0, 9),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = THEME.Accent,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 3,
        }, button)
        Round(badge, 9)
        CheckGlyph(badge, 12, THEME.OnAccent)

        local tile = { Entry = entry, Button = button, Stroke = stroke, Thumb = thumb, Placeholder = placeholder, Name = name, Badge = badge }
        button.MouseEnter:Connect(function() PaintTile(side, tile, true) end)
        button.MouseLeave:Connect(function() PaintTile(side, tile, false) end)
        button.MouseButton1Click:Connect(function() Pick(side, entry) end)
        return tile
    end

    local function DestroyTile(tile)
        DetachView(tile)
        tile.Button:Destroy()
    end

    -- Only cells near the visible part of the list hold a viewport; each one is a separate render
    -- surface that is redrawn every frame.
    local function IsNear(side, tile)
        local scroll = side.Scroll
        local top = scroll.CanvasPosition.Y
        local bottom = top + scroll.AbsoluteWindowSize.Y
        local y = tile.Button.AbsolutePosition.Y - scroll.AbsolutePosition.Y + top
        local margin = 120
        return y + tile.Button.AbsoluteSize.Y >= top - margin and y <= bottom + margin
    end

    local function UpdateVisible(side)
        for _, tile in ipairs(side.TileList) do
            if IsNear(side, tile) then AttachView(tile) elseif tile.View then DetachView(tile) end
        end
    end

    local function OnBaked(entry)
        for _, side in pairs(sides) do
            local tile = side.TileByEntry[entry]
            if tile and IsNear(side, tile) then AttachView(tile) end
        end
    end

    local WORKERS = 3
    local function Bake(side)
        if not PreviewsOn() then return end
        side.BakeToken = side.BakeToken + 1
        local mine = side.BakeToken

        local pending = {}
        for _, tile in ipairs(side.TileList) do
            if IsNear(side, tile) and not Preview.Get(tile.Entry) and not failedPreview[tile.Entry] then
                table.insert(pending, tile.Entry)
            end
        end
        if #pending == 0 then return end
        Preview.Preload(pending)

        local nextIndex = 1
        local function Worker()
            while mine == side.BakeToken and nextIndex <= #pending do
                local entry = pending[nextIndex]
                nextIndex = nextIndex + 1

                local model, reason = Preview.Bake(entry)
                if model then
                    OnBaked(entry)
                else
                    failedPreview[entry] = true
                    if reason ~= "unloaded" then warn("[Visual Emotes] Preview failed for " .. entry.Name .. ": " .. tostring(reason)) end
                end
            end
        end
        for _ = 1, math.min(WORKERS, #pending) do task.spawn(Worker) end
    end

    RefreshVisible = function(side)
        UpdateVisible(side)
        Bake(side)
    end

    -- ---------- one side (Base / Target) ----------
    local function RenderSide(side)
        local other = side == sides.Base and sides.Target or sides.Base
        local query = string.lower(side.Query)

        -- an emote with a required partner (whitelist) only lets that partner show on the other side
        local onlyName = other.Selected and Swap.GetWhitelist(other.Selected) or nil

        local entries = {}
        if onlyName then
            local partner = byName[onlyName]
            if partner then entries[1] = partner end
        else
            for _, entry in ipairs(groups[side.Group].Entries) do
                if entry ~= other.Selected and (query == "" or string.find(string.lower(entry.Display), query, 1, true)) then
                    table.insert(entries, entry)
                end
            end
        end

        local list, map = {}, {}
        for index, entry in ipairs(entries) do
            local tile = side.TileByEntry[entry] or MakeTile(side, entry)
            tile.Button.LayoutOrder = index
            tile.Name.Text = TitleOf(entry)
            list[index] = tile
            map[entry] = tile
        end
        for entry, tile in pairs(side.TileByEntry) do
            if not map[entry] then DestroyTile(tile) end
        end
        side.TileList, side.TileByEntry = list, map

        for _, tile in ipairs(list) do PaintTile(side, tile, false) end

        local selected = side.Selected
        side.SelectedLabel.Text = selected and TitleOf(selected) or "None selected"
        side.SelectedLabel.TextColor3 = selected and THEME.Text or THEME.Muted
    end

    local function UpdateButton()
        local state = Swap.GetState(sides.Base.Selected, sides.Target.Selected)
        SwapButton.Label.Text = state == 3 and "Revert" or "Swap"
        SetEnabled(SwapButton, state ~= 1)
    end

    Refresh = function()
        -- selections that no longer fit a whitelist pair (or are the same emote) are dropped
        local base, target = sides.Base.Selected, sides.Target.Selected
        local targetOnly = base and Swap.GetWhitelist(base) or nil
        local baseOnly = target and Swap.GetWhitelist(target) or nil
        if target and ((targetOnly and target.Name ~= targetOnly) or target == base) then sides.Target.Selected = nil end
        if base and ((baseOnly and base.Name ~= baseOnly) or base == target) then sides.Base.Selected = nil end

        RenderSide(sides.Base)
        RenderSide(sides.Target)
        UpdateButton()
        ShowHint()
        for _, side in pairs(sides) do
            task.defer(function() RefreshVisible(side) end)
        end
    end

    -- dark inset field (Base.Field in Mugiwara UI)
    local function Field(parent, position, size, class, props)
        local merged = {
            BorderSizePixel = 0,
            BackgroundColor3 = THEME.Field,
            BackgroundTransparency = THEME.FieldAlpha,
            Position = position,
            Size = size,
        }
        for key, value in pairs(props or {}) do merged[key] = value end
        local field = New(class, merged, parent)
        Round(field, 8)
        Stroke(field, 0.9)
        return field
    end

    local function NewSide(sideName, titleText)
        local side = {
            Name = sideName, Group = 1, Query = "", Selected = nil,
            TileList = {}, TileByEntry = {}, BakeToken = 0,
        }
        sides[sideName] = side

        local frame = New("Frame", {
            Name = sideName,
            LayoutOrder = sideName == "Base" and 1 or 2,
            Size = UDim2.new(0.5, -5, 1, 0),
            BackgroundColor3 = THEME.Card,
            BackgroundTransparency = THEME.CardAlpha,
            BorderSizePixel = 0,
        }, PaneHolder)
        Round(frame, 10)
        Stroke(frame, 0.9)

        local inner = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, frame)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        }, inner)

        Label(inner, { Text = titleText, Font = FONT_TITLE, TextSize = 15, Size = UDim2.new(0.5, 0, 0, 20) })
        side.SelectedLabel = Label(inner, {
            Text = "None selected",
            TextSize = 12,
            TextColor3 = THEME.Muted,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0.5, 0, 0, 20),
        })

        -- category dropdown
        local categoryButton = Field(inner, UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 32), "TextButton", { Text = "", AutoButtonColor = false })
        local categoryLabel = Label(categoryButton, {
            Text = groups[1].Title,
            Font = FONT_LABEL,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -36, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local chevronHolder = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
        }, categoryButton)
        ChevronGlyph(chevronHolder, 14, THEME.SubText)

        -- search
        local search = Field(inner, UDim2.fromOffset(0, 64), UDim2.new(1, 0, 0, 32), "TextBox", {
            Text = "",
            PlaceholderText = "Search emote...",
            PlaceholderColor3 = THEME.Muted,
            TextColor3 = THEME.Text,
            Font = FONT_BODY,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        })
        New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, search)

        -- grid, open from the start
        side.Scroll = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 104),
            Size = UDim2.new(1, 0, 1, -104),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Muted,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
        }, inner)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 6),
        }, side.Scroll)
        ResponsiveGrid(side.Scroll, GAP, CELL_HEIGHT, 88, function() RefreshVisible(side) end)

        -- category drawer: opens under the field and pushes the search box and the grid down,
        -- like the Mugiwara UI dropdown (dark inset list, rows with gradient / check when chosen)
        local DRAWER_Y = 62
        local drawerHeight = math.min(#groups * 36 + 10, 150)
        local drawer = Field(inner, UDim2.fromOffset(0, DRAWER_Y), UDim2.new(1, 0, 0, drawerHeight), "Frame", { ClipsDescendants = true })
        drawer.Visible = false
        local list = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Muted,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
        }, drawer)
        New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, list)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 8),
        }, list)

        local rows = {}
        local function PaintRow(index, hovered)
            local row = rows[index]
            local on = index == side.Group
            row.Button.BackgroundTransparency = on and 0.78 or (hovered and 0.92 or 1)
            row.Check.Visible = on
            row.Stroke.Color = on and THEME.Accent or THEME.Stroke
            row.Stroke.Transparency = on and 0.45 or (hovered and 0.78 or THEME.StrokeAlpha)
        end

        local drawerOpen = false
        local function Layout(open)
            drawerOpen = open
            drawer.Visible = open
            Tween(chevronHolder, { Rotation = open and 180 or 0 }, 0.2)
            local searchY = open and (DRAWER_Y + drawerHeight + 6) or 64
            local gridY = searchY + 40
            Tween(search, { Position = UDim2.fromOffset(0, searchY) }, 0.2)
            Tween(side.Scroll, { Position = UDim2.fromOffset(0, gridY), Size = UDim2.new(1, 0, 1, -gridY) }, 0.2)
            task.delay(0.25, function() RefreshVisible(side) end)
        end

        for index, group in ipairs(groups) do
            local button = New("TextButton", {
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 1,
                LayoutOrder = index,
                Size = UDim2.new(1, 0, 0, 32),
            }, list)
            Round(button, 8)
            Gradient(button, 0)
            local stroke = Stroke(button, THEME.StrokeAlpha)
            Label(button, {
                Text = group.Title,
                Font = FONT_LABEL,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -80, 1, 0),
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            Label(button, {
                Text = tostring(#group.Entries),
                TextSize = 12,
                TextColor3 = THEME.Muted,
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -34, 0, 0),
                Size = UDim2.new(0, 36, 1, 0),
            })
            local checkSlot = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundTransparency = 1,
                Visible = false,
            }, button)
            CheckGlyph(checkSlot, 14, THEME.Accent)
            rows[index] = { Button = button, Stroke = stroke, Check = checkSlot }

            button.MouseEnter:Connect(function() PaintRow(index, true) end)
            button.MouseLeave:Connect(function() PaintRow(index, false) end)
            button.MouseButton1Click:Connect(function()
                side.Group = index
                categoryLabel.Text = group.Title
                for rowIndex in ipairs(rows) do PaintRow(rowIndex, false) end
                side.Scroll.CanvasPosition = Vector2.zero
                for entry in pairs(failedPreview) do failedPreview[entry] = nil end
                Layout(false)
                Refresh()
            end)
        end
        for rowIndex in ipairs(rows) do PaintRow(rowIndex, false) end

        categoryButton.MouseButton1Click:Connect(function() Layout(not drawerOpen) end)

        search:GetPropertyChangedSignal("Text"):Connect(function()
            side.Query = search.Text
            side.Scroll.CanvasPosition = Vector2.zero
            Refresh()
        end)

        local scrollToken = 0
        side.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            scrollToken = scrollToken + 1
            local mine = scrollToken
            task.delay(0.08, function()
                if mine == scrollToken then RefreshVisible(side) end
            end)
        end)
    end

    NewSide("Base", "Base Emote")
    NewSide("Target", "Target Emote")

    -- Swaps drop the old preview models (the items changed) and rebuild them.
    local function Forget(entries)
        for _, entry in ipairs(entries) do
            Preview.Invalidate(entry)
            failedPreview[entry] = nil
            for _, side in pairs(sides) do
                local tile = side.TileByEntry[entry]
                if tile then DetachView(tile) end
            end
        end
    end

    SwapButton.Hit.MouseButton1Click:Connect(function()
        local base, target = sides.Base.Selected, sides.Target.Selected
        local state = Swap.GetState(base, target)
        if state == 1 then
            SetStatus("Pick a valid Base and Target emote first.", THEME.Danger)
            return
        end

        local pair = { base, target }
        local ok, message
        if state == 2 then
            ok, message = Swap.Swap(base, target)
            SetStatus(ok and (base.Display .. " now looks like " .. target.Display) or message, ok and THEME.Success or THEME.Danger)
        else
            ok, message = Swap.Revert(base, target)
            SetStatus(ok and "Restored to normal." or message, ok and THEME.Success or THEME.Danger)
        end

        if ok then Forget(pair) end
        sides.Base.Selected, sides.Target.Selected = nil, nil
        Refresh()
    end)

    RevertAllButton.Hit.MouseButton1Click:Connect(function()
        local restored, touched = Swap.RevertAll()
        Forget(touched)
        sides.Base.Selected, sides.Target.Selected = nil, nil
        Refresh()
        SetStatus(restored > 0 and ("Restored " .. restored .. " swapped pair(s).") or "Nothing is swapped.", restored > 0 and THEME.Success or THEME.SubText)
    end)

    Refresh()
    Page.OnShow = function()
        for _, side in pairs(sides) do RefreshVisible(side) end
    end

    -- Poses of every emote are gathered quietly in the background (once; saved to a file), so
    -- opening any category later is instant.
    task.spawn(function()
        if not PreviewsOn() then return end
        local list, missing = {}, 0
        for _, group in ipairs(groups) do
            for _, entry in ipairs(group.Entries) do
                table.insert(list, entry)
                if not Preview.PoseKnown(entry) then missing = missing + 1 end
            end
        end
        if missing == 0 then return end
        if missing > 20 then SetStatus("Preparing " .. missing .. " emote previews in the background (one time only)...") end
        Preview.Collect(list)
    end)
end

-- These emotes can only be swapped with their partner (and the other way round).
local WHITELIST = {
    RockinStride = "Kickback",
    Kickback = "RockinStride",
    ZombieStride = "ClassicDance",
    ClassicDance = "ZombieStride",
}

local Swap = NewSwap({ Category = "Emotes", Paths = DaftarPath, Whitelist = WHITELIST, Noun = "emote" })
BuildEmoteUI(Swap)

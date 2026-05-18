local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local ViewportSize = workspace.CurrentCamera.ViewportSize

local CFG = {
    MainColor = Color3.fromRGB(14, 14, 14),
    SecondaryColor = Color3.fromRGB(26, 26, 26),
    AccentColor = Color3.fromRGB(0, 0, 139),
    TextColor = Color3.fromRGB(220, 220, 220),
    TextDark = Color3.fromRGB(140, 140, 140),
    StrokeColor = Color3.fromRGB(40, 40, 40),
    Font = Enum.Font.GothamSemibold,
    BaseSize = Vector2.new(640, 480)
}

local Library = { Flags = {}, Connections = {}, Unloaded = false }
local ConfigFolder = nil

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props or {}) do inst[i] = v end
    for _, child in pairs(children or {}) do child.Parent = inst end
    return inst
end

local function Tween(obj, props, time, style, dir)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local function GetTextSize(text, size, font)
    return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
end

local function DetectMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local ScreenGui = Create("ScreenGui", {
    Name = "apex.lua",
    Parent = CoreGui,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    IgnoreGuiInset = true
})

local UIScale = Create("UIScale", { Parent = ScreenGui })

local function UpdateScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local widthRatio = (vp.X - 40) / CFG.BaseSize.X
    local heightRatio = (vp.Y - 40) / CFG.BaseSize.Y
    local scale = math.min(widthRatio, heightRatio, 1)
    UIScale.Scale = math.max(scale, 0.6)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
UpdateScale()

local Watermark = Create("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 0, 0, 24),
    Position = UDim2.new(0, 15, 1, -15),
    AnchorPoint = Vector2.new(0, 1),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, {
    Create("UIStroke", { Color = CFG.AccentColor, Thickness = 1, Transparency = 0.6 }),
    Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
    Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
    Create("TextLabel", {
        Text = "apex.lua | addon",
        TextColor3 = CFG.TextColor,
        TextSize = 13,
        Font = CFG.Font,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center
    })
})
Tween(Watermark, {Size = UDim2.new(0, GetTextSize("apex.lua | addon", 13, CFG.Font).X + 20, 0, 24)}, 0.3)

local NotificationContainer = Create("Frame", {
    Parent = ScreenGui,
    Position = UDim2.new(1, -20, 0, 20),
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.new(0, 300, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 100
})

local UIListNotif = Create("UIListLayout", {
    Parent = NotificationContainer,
    Padding = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top
})

function Library:Notify(msg, type)
    local color = (type == "success" and Color3.fromRGB(100, 255, 100)) or (type == "warning" and Color3.fromRGB(255, 100, 100)) or CFG.AccentColor
    local Frame = Create("Frame", {
        Parent = NotificationContainer,
        Size = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, {
        Create("UIStroke", { Color = CFG.AccentColor, Thickness = 1, Transparency = 0.5 }),
        Create("Frame", { Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = color }),
        Create("TextLabel", {
            Text = msg,
            TextColor3 = CFG.TextColor,
            Font = CFG.Font,
            TextSize = 13,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })
    Tween(Frame, { Size = UDim2.new(0, 250, 0, 35) }, 0.5, Enum.EasingStyle.Back)
    task.delay(3, function()
        Tween(Frame, { Size = UDim2.new(0, 250, 0, 0), BackgroundTransparency = 1 }, 0.5)
        task.wait(0.5)
        Frame:Destroy()
    end)
end

local TooltipLabel = Create("TextLabel", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 0, 0, 20),
    BackgroundColor3 = CFG.SecondaryColor,
    TextColor3 = CFG.TextColor,
    TextSize = 12,
    Font = CFG.Font,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 200
}, {
    Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
    Create("UIStroke", { Color = CFG.StrokeColor })
})

local function AddTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        TooltipLabel.Text = text
        TooltipLabel.Size = UDim2.fromOffset(GetTextSize(text, 12, CFG.Font).X + 12, 20)
        TooltipLabel.Visible = true
    end)
    obj.MouseLeave:Connect(function()
        TooltipLabel.Visible = false
    end)
end

RunService.RenderStepped:Connect(function()
    if TooltipLabel.Visible then
        local m = UserInputService:GetMouseLocation()
        TooltipLabel.Position = UDim2.fromOffset(m.X + 15, m.Y + 15)
    end
end)

local MainFrame = Create("Frame", {
    Name = "MainFrame",
    Parent = ScreenGui,
    Size = UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
    Position = UDim2.new(0.5, -320, 0.5, -240),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0
}, {
    Create("UIStroke", { Color = CFG.StrokeColor }),
    Create("UICorner", { CornerRadius = UDim.new(0, 3) })
})

local Dragging, DragInput, DragStart, StartPos = false, nil, nil, nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local delta = input.Position - DragStart
        Tween(MainFrame, { Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y) }, 0.05)
    end
end)

if DetectMobile() then
    local ToggleBtn = Create("TextButton", {
        Parent = ScreenGui,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -20, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = CFG.MainColor,
        Text = "▲",
        TextSize = 20,
        TextColor3 = CFG.AccentColor,
        Font = CFG.Font,
        BorderSizePixel = 0,
        ZIndex = 150
    }, {
        Create("UIStroke", { Color = CFG.AccentColor, Thickness = 1 }),
        Create("UICorner", { CornerRadius = UDim.new(1, 0) })
    })
    local visible = true
    ToggleBtn.MouseButton1Click:Connect(function()
        visible = not visible
        MainFrame.Visible = visible
        ToggleBtn.Text = visible and "▲" or "▼"
    end)
end

local TopBar = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0
}, {
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CFG.StrokeColor
    })
})

local TitleLabel = Create("TextLabel", {
    Parent = TopBar,
    Text = "apex.lua | addon",
    TextColor3 = CFG.TextDark,
    TextSize = 14,
    Font = CFG.Font,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    RichText = true
})

task.spawn(function()
    local textList = {
        '', 'a', 'ap', 'ape', 'apex', 'apex.', 'apex.l', 'apex.lu',
        'apex.lua', 'apex.lua |', 'apex.lua | a', 'apex.lua | ad',
        'apex.lua | add', 'apex.lua | addo', 'apex.lua | addon',
        'apex.lua | addo', 'apex.lua | add', 'apex.lua | ad',
        'apex.lua | a', 'apex.lua |', 'apex.lua', 'apex.lu', 'apex.l',
        'apex.', 'apex', 'apex', 'apex', 'apex', 'apex'
    }
    while not Library.Unloaded do
        for _, text in ipairs(textList) do
            if Library.Unloaded then break end
            local display = text
            if string.find(text, "addon") then
                display = string.gsub(text, "addon", 'addon')
            elseif string.find(text, "lua") then
                display = string.gsub(text, "lua", 'lua')
            end
            TitleLabel.Text = display
            task.wait(0.2)
        end
    end
end)

local ContentContainer = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 1, -32),
    Position = UDim2.new(0, 0, 0, 32),
    BackgroundTransparency = 1
})

local Sidebar = Create("Frame", {
    Parent = ContentContainer,
    Size = UDim2.new(0, 65, 1, 0),
    BackgroundColor3 = Color3.fromRGB(17, 17, 17),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0)
}, {
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = CFG.StrokeColor
    }),
    Create("UIListLayout", {
        Padding = UDim.new(0, 12),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }),
    Create("UIPadding", { PaddingTop = UDim.new(0, 15) })
})

local PagesContainer = Create("Frame", {
    Parent = ContentContainer,
    Size = UDim2.new(1, -65, 1, 0),
    Position = UDim2.new(0, 65, 0, 0),
    BackgroundTransparency = 1
})

local Tabs = {}
local CurrentTab = nil

function Library:Tab(name, icon)
    local TabButton = Create("TextButton", {
        Parent = Sidebar,
        Size = UDim2.new(0, 44, 0, 44),
        BackgroundColor3 = CFG.MainColor,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) })
    })

    if icon then
        local IconLabel = Create("ImageLabel", {
            Parent = TabButton,
            Name = "Icon",
            Size = UDim2.new(0.6, 0, 0.6, 0),
            Position = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. icon,
            ImageColor3 = CFG.TextDark
        })
        TabButton.Icon = IconLabel
    else
        local TabText = Create("TextLabel", {
            Parent = TabButton,
            Name = "TabText",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = CFG.TextDark,
            Font = CFG.Font,
            TextSize = 14,
            TextScaled = true
        })
        TabButton.TabText = TabText
    end

    local PageFrame = Create("Frame", {
        Parent = PagesContainer,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false
    })

    local LeftCol = Create("Frame", {
        Parent = PageFrame,
        Size = UDim2.new(0.48, 0, 1, 0),
        BackgroundTransparency = 1
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    })

    local RightCol = Create("Frame", {
        Parent = PageFrame,
        Size = UDim2.new(0.48, 0, 1, 0),
        Position = UDim2.new(0.52, 0, 0, 0),
        BackgroundTransparency = 1
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    })

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            Tween(t.Btn, { BackgroundColor3 = CFG.MainColor }, 0.2)
            if t.Btn:FindFirstChild("Icon") then
                t.Btn.Icon.ImageColor3 = CFG.TextDark
            elseif t.Btn:FindFirstChild("TabText") then
                t.Btn.TabText.TextColor3 = CFG.TextDark
            end
            t.Page.Visible = false
        end
        Tween(TabButton, { BackgroundColor3 = CFG.SecondaryColor }, 0.2)
        if TabButton:FindFirstChild("Icon") then
            TabButton.Icon.ImageColor3 = CFG.AccentColor
        elseif TabButton:FindFirstChild("TabText") then
            TabButton.TabText.TextColor3 = CFG.AccentColor
        end
        PageFrame.Visible = true
        CurrentTab = PageFrame
    end)

    table.insert(Tabs, { Btn = TabButton, Page = PageFrame })
    if #Tabs == 1 then
        TabButton.BackgroundColor3 = CFG.SecondaryColor
        if TabButton:FindFirstChild("Icon") then
            TabButton.Icon.ImageColor3 = CFG.AccentColor
        elseif TabButton:FindFirstChild("TabText") then
            TabButton.TabText.TextColor3 = CFG.AccentColor
        end
        PageFrame.Visible = true
    end

    local GroupFunctions = {}
    local LeftSide = true

    function GroupFunctions:Group(title)
        local ParentCol = LeftSide and LeftCol or RightCol
        LeftSide = not LeftSide
        local GroupFrame = Create("Frame", {
            Parent = ParentCol,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(17, 17, 17),
            BorderSizePixel = 0
        }, {
            Create("UIStroke", { Color = CFG.StrokeColor }),
            Create("UICorner", { CornerRadius = UDim.new(0, 2) })
        })

        Create("Frame", {
            Parent = GroupFrame,
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel = 0
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            Create("Frame", {
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }),
            Create("TextLabel", {
                Text = title,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = CFG.TextColor,
                Font = CFG.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            Create("Frame", {
                Size = UDim2.new(0, 4, 0, 4),
                Position = UDim2.new(1, -10, 0.5, -2),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel = 0
            }, {
                Create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
        })

        local Content = Create("Frame", {
            Parent = GroupFrame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 25),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }),
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            })
        })

        local ItemFuncs = {}

        local function RegisterFlag(name, value, setter, getter)
            table.insert(Library.Flags, {Name = name, Value = value, Set = setter, Get = getter})
        end

        function ItemFuncs:Toggle(cfg)
            local Enabled = false
            local Frame = Create("TextButton", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Text = ""
            })
            local Box = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 0, 0.5, -7),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) })
            })
            local Check = Create("Frame", {
                Parent = Box,
                Size = UDim2.new(1, -4, 1, -4),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = CFG.AccentColor,
                BackgroundTransparency = 1
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 2) })
            })
            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark,
                TextSize = 13,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 20, 0, 0),
                Size = UDim2.new(1, -20, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end

            local function Update(val)
                if val == nil then val = not Enabled end
                Enabled = val
                Tween(Check, { BackgroundTransparency = Enabled and 0 or 1 }, 0.1)
                Tween(Label, { TextColor3 = Enabled and CFG.TextColor or (cfg.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark) }, 0.1)
                if cfg.Callback then cfg.Callback(Enabled) end
                if cfg.Flag then
                    cfg.Flag.Value = Enabled
                    Library:SaveFlag(cfg.Flag.Name, Enabled)
                end
            end

            if cfg.Flag then
                RegisterFlag(cfg.Flag.Name, Enabled, Update, function() return Enabled end)
            end

            Frame.MouseButton1Click:Connect(function() Update() end)
            return { Set = function(v) if v ~= Enabled then Update(v) end end }
        end

        function ItemFuncs:Slider(cfg)
            local Value = cfg.Default or cfg.Min
            local DraggingSlider = false
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1
            })
            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 13,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local ValueLabel = Create("TextLabel", {
                Parent = Frame,
                Text = Value .. (cfg.Unit or ""),
                TextColor3 = CFG.TextDark,
                TextSize = 13,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Right
            })
            local SliderBG = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 8),
                Position = UDim2.new(0, 0, 0, 22),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
            local Fill = Create("Frame", {
                Parent = SliderBG,
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = CFG.AccentColor
            }, {
                Create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local function UpdateVal(val)
                Value = math.clamp(val or Value, cfg.Min, cfg.Max)
                local percent = (Value - cfg.Min) / (cfg.Max - cfg.Min)
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                ValueLabel.Text = Value .. (cfg.Unit or "")
                if cfg.Callback then cfg.Callback(Value) end
                if cfg.Flag then
                    cfg.Flag.Value = Value
                    Library:SaveFlag(cfg.Flag.Name, Value)
                end
            end

            local function Update(input)
                local SizeX = SliderBG.AbsoluteSize.X
                local PosX = SliderBG.AbsolutePosition.X
                local InputX = input.Position.X
                local Percent = math.clamp((InputX - PosX) / SizeX, 0, 1)
                UpdateVal(math.floor(cfg.Min + (cfg.Max - cfg.Min) * Percent))
            end

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = true
                    Update(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if DraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = false
                end
            end)

            UpdateVal(cfg.Default)

            if cfg.Flag then
                RegisterFlag(cfg.Flag.Name, Value, UpdateVal, function() return Value end)
            end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Dropdown(cfg)
            local Expanded = false
            local Current = cfg.Default or cfg.Options[1]
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundTransparency = 1,
                ZIndex = 20
            })
            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 13,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local MainBox = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 22),
                Position = UDim2.new(0, 0, 0, 18),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                Create("TextLabel", {
                    Name = "Val",
                    Text = Current,
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = CFG.TextColor,
                    TextSize = 13,
                    Font = CFG.Font,
                    TextXAlignment = Enum.TextXAlignment.Left
                }),
                Create("TextLabel", {
                    Text = "▼",
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = CFG.TextDark,
                    TextSize = 12
                })
            })
            local ListFrame = Create("ScrollingFrame", {
                Parent = MainBox,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 2),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 50,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) })
            })

            local function UpdateSelection(opt)
                Current = opt
                MainBox.Val.Text = opt
                for _, btn in ipairs(ListFrame:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.TextColor3 = (btn.Text == opt) and CFG.AccentColor or CFG.TextDark
                    end
                end
                if cfg.Callback then cfg.Callback(opt) end
                if cfg.Flag then
                    cfg.Flag.Value = opt
                    Library:SaveFlag(cfg.Flag.Name, opt)
                end
            end

            for _, opt in pairs(cfg.Options) do
                local Btn = Create("TextButton", {
                    Parent = ListFrame,
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Text = opt,
                    TextColor3 = (opt == Current) and CFG.AccentColor or CFG.TextDark,
                    TextSize = 13,
                    Font = CFG.Font
                })
                Btn.MouseButton1Click:Connect(function()
                    UpdateSelection(opt)
                    Expanded = false
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end)
            end

            MainBox.MouseButton1Click:Connect(function()
                Expanded = not Expanded
                if Expanded then
                    ListFrame.Visible = true
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, math.min(#cfg.Options * 22, 120)) }, 0.1)
                else
                    Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end
            end)

            if cfg.Flag then
                RegisterFlag(cfg.Flag.Name, Current, UpdateSelection, function() return Current end)
            end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:ColorPicker(cfg)
            local Color = cfg.Default or Color3.fromRGB(255, 255, 255)
            local Opened = false
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                ZIndex = 15
            })
            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 13,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local Preview = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(0, 34, 0, 16),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundColor3 = Color,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) })
            })
            local PickerFrame = Create("Frame", {
                Parent = Preview,
                Size = UDim2.new(0, 180, 0, 0),
                Position = UDim2.new(1, 0, 1, 5),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = CFG.MainColor,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 60
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) })
            })
            local SatValPanel = Create("TextButton", {
                Parent = PickerFrame,
                Size = UDim2.new(1, -20, 0, 100),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4801885019"
                }),
                Create("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4801885019",
                    ImageColor3 = Color3.new(0, 0, 0),
                    Rotation = 90
                })
            })
            local Cursor = Create("Frame", {
                Parent = SatValPanel,
                Size = UDim2.new(0, 5, 0, 5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                AnchorPoint = Vector2.new(0.5, 0.5)
            }, {
                Create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
            local HueSlider = Create("TextButton", {
                Parent = PickerFrame,
                Size = UDim2.new(1, -20, 0, 12),
                Position = UDim2.new(0, 10, 0, 120),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
                    })
                }),
                Create("UICorner", { CornerRadius = UDim.new(0, 2) })
            })

            local H, S, V = 0, 1, 1
            local DraggingHSV, DraggingHue = false, false

            local function UpdateColor()
                Color = Color3.fromHSV(H, S, V)
                Preview.BackgroundColor3 = Color
                SatValPanel.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                Cursor.Position = UDim2.new(S, 0, 1 - V, 0)
                if cfg.Callback then cfg.Callback(Color) end
                if cfg.Flag then
                    cfg.Flag.Value = {H, S, V}
                    Library:SaveFlag(cfg.Flag.Name, {H, S, V})
                end
            end

            local function SetColorFromHSV(h, s, v)
                H, S, V = h, s, v
                UpdateColor()
            end

            SatValPanel.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = true
                end
            end)
            HueSlider.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHue = true
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = false
                    DraggingHue = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    if DraggingHSV then
                        local size = SatValPanel.AbsoluteSize
                        local pos = SatValPanel.AbsolutePosition
                        local x = math.clamp((inp.Position.X - pos.X) / size.X, 0, 1)
                        local y = math.clamp((inp.Position.Y - pos.Y) / size.Y, 0, 1)
                        S = x
                        V = 1 - y
                        UpdateColor()
                    elseif DraggingHue then
                        local size = HueSlider.AbsoluteSize
                        local pos = HueSlider.AbsolutePosition
                        local x = math.clamp((inp.Position.X - pos.X) / size.X, 0, 1)
                        H = x
                        UpdateColor()
                    end
                end
            end)

            Preview.MouseButton1Click:Connect(function()
                Opened = not Opened
                if Opened then
                    Tween(PickerFrame, { Size = UDim2.new(0, 180, 0, 170) }, 0.2)
                else
                    Tween(PickerFrame, { Size = UDim2.new(0, 180, 0, 0) }, 0.2)
                end
            end)

            if cfg.Flag then
                RegisterFlag(cfg.Flag.Name, {H, S, V}, function(val) SetColorFromHSV(val[1], val[2], val[3]) end, function() return {H, S, V} end)
            end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Textbox(cfg)
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundTransparency = 1
            })
            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 13,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local Box = Create("TextBox", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 22),
                Position = UDim2.new(0, 0, 0, 16),
                BackgroundColor3 = CFG.SecondaryColor,
                TextColor3 = CFG.TextColor,
                PlaceholderText = cfg.Placeholder or "...",
                Text = cfg.Default or "",
                Font = CFG.Font,
                TextSize = 13,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                Create("UIPadding", { PaddingLeft = UDim.new(0, 5) })
            })
            Box.FocusLost:Connect(function()
                if cfg.Callback then cfg.Callback(Box.Text) end
                if cfg.Flag then
                    cfg.Flag.Value = Box.Text
                    Library:SaveFlag(cfg.Flag.Name, Box.Text)
                end
            end)
            if cfg.Flag then
                RegisterFlag(cfg.Flag.Name, Box.Text, function(val) Box.Text = val end, function() return Box.Text end)
            end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        function ItemFuncs:Keybind(cfg)
            local Key = cfg.Default or Enum.KeyCode.Insert
            local Waiting = false
            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1
            })
            Create("TextLabel", {
                Parent = Frame,
                Text = cfg.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 13,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local KeyLabel = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(0, 64, 0, 16),
                Position = UDim2.new(1, 0, 0.5, -8),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = CFG.SecondaryColor,
                Text = tostring(Key):gsub("Enum.KeyCode.", ""),
                TextColor3 = CFG.TextColor,
                TextSize = 12,
                Font = CFG.Font,
                BorderSizePixel = 0,
                AutoButtonColor = false
            }, {
                Create("UIStroke", { Color = CFG.StrokeColor }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) })
            })

            local function SetKey(k)
                Key = k
                KeyLabel.Text = tostring(Key):gsub("Enum.KeyCode.", "")
                if cfg.Callback then cfg.Callback(Key) end
                if cfg.Flag then
                    cfg.Flag.Value = tostring(Key)
                    Library:SaveFlag(cfg.Flag.Name, tostring(Key))
                end
            end

            KeyLabel.MouseButton1Click:Connect(function()
                if Waiting then return end
                Waiting = true
                local oldText = KeyLabel.Text
                KeyLabel.Text = "..."
                KeyLabel.AutoButtonColor = true
                local connection
                connection = UserInputService.InputBegan:Connect(function(inp, gpe)
                    if gpe then return end
                    if inp.KeyCode ~= Enum.KeyCode.Unknown then
                        SetKey(inp.KeyCode)
                        connection:Disconnect()
                        KeyLabel.AutoButtonColor = false
                        Waiting = false
                    elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        connection:Disconnect()
                        KeyLabel.Text = oldText
                        KeyLabel.AutoButtonColor = false
                        Waiting = false
                    end
                end)
            end)

            if cfg.Flag then
                RegisterFlag(cfg.Flag.Name, tostring(Key), function(val) SetKey(Enum.KeyCode[val]) end, function() return tostring(Key) end)
            end
            if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        end

        return ItemFuncs
    end

    function GroupFunctions:Button(cfg)
        local Frame = Create("TextButton", {
            Parent = Content,
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = ""
        })
        local Label = Create("TextLabel", {
            Parent = Frame,
            Text = cfg.Name,
            TextColor3 = CFG.TextColor,
            TextSize = 13,
            Font = CFG.Font,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
        Frame.MouseButton1Click:Connect(function()
            if cfg.Callback then cfg.Callback() end
        end)
    end

    function GroupFunctions:Label(cfg)
        local Frame = Create("Frame", {
            Parent = Content,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1
        })
        Create("TextLabel", {
            Parent = Frame,
            Text = cfg.Name,
            TextColor3 = cfg.Color or CFG.TextColor,
            TextSize = 13,
            Font = CFG.Font,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        if cfg.Tooltip then AddTooltip(Frame, cfg.Tooltip) end
    end

    return GroupFunctions
end

function Library:InitConfig()
    local success, result = pcall(function()
        if not Player:FindFirstChild("apex_config") then
            local folder = Instance.new("Folder")
            folder.Name = "apex_config"
            folder.Parent = Player
            ConfigFolder = folder
        else
            ConfigFolder = Player:FindFirstChild("apex_config")
        end
    end)
    if not success then
        warn("Config init failed: " .. tostring(result))
    end
end

function Library:SaveFlag(name, value)
    if not ConfigFolder then return end
    local encoded = HttpService:JSONEncode(value)
    local found = ConfigFolder:FindFirstChild(name)
    if found and found:IsA("StringValue") then
        found.Value = encoded
    else
        local sv = Instance.new("StringValue")
        sv.Name = name
        sv.Value = encoded
        sv.Parent = ConfigFolder
    end
end

function Library:LoadConfig()
    if not ConfigFolder then return end
    for _, flag in ipairs(Library.Flags) do
        local saved = ConfigFolder:FindFirstChild(flag.Name)
        if saved and saved:IsA("StringValue") then
            local success, decoded = pcall(HttpService.JSONDecode, HttpService, saved.Value)
            if success then
                if type(decoded) == "table" and flag.Set then
                    flag.Set(decoded)
                elseif flag.Set then
                    flag.Set(decoded)
                end
            end
        end
    end
end

Library:InitConfig()
Library:LoadConfig()

return Library

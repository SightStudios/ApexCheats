local Linoria = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/LinoriaLib/refs/heads/main/Library.lua"))()
local Window = Linoria:CreateWindow("apex lua")

local CombatTab = Window:AddTab("Combat")
local VisualsTab = Window:AddTab("Visuals")

local TriggerbotSettings = {
    Enabled = false,
    Delay = 0,
    Teamcheck = false,
    TriggerPart = "Any"  -- Any, Head, Torso/HumanoidRootPart
}

local ESPSettings = {
    Enabled = false,
    ShowBox = false,
    BoxType = "Normal",
    ShowFilledBox = false,
    ShowName = false,
    ShowHealth = false,
    ShowDistance = false,
    ShowTracer = false,
    TracerPosition = "Bottom",
    BoxColor = Color3.new(1, 1, 1),
    BoxOutlineColor = Color3.new(0, 0, 0),
    FilledBoxColor = Color3.new(1, 1, 1),
    NameColor = Color3.new(1, 1, 1),
    HealthColor = Color3.new(1, 1, 1),
    HealthHighColor = Color3.new(0, 1, 0),
    HealthLowColor = Color3.new(1, 0, 0),
    HealthOutlineColor = Color3.new(0, 0, 0),
    DistanceColor = Color3.new(1, 1, 1),
    TracerColor = Color3.new(1, 1, 1),
    Teamcheck = false,
    WallCheck = false,
    TracerThickness = 1
}

local function createUI()
    -- Combat Tab (Triggerbot only)
    local triggerSection = CombatTab:AddLeftGroupbox("Triggerbot")
    triggerSection:AddToggle("Trigger Enabled", {Text = "Enabled", Default = false, Callback = function(v) TriggerbotSettings.Enabled = v end})
    triggerSection:AddSlider("Trigger Delay", {Text = "Delay (ms)", Min = 0, Max = 300, Default = 0, Rounding = 0, Callback = function(v) TriggerbotSettings.Delay = v end})
    triggerSection:AddDropdown("Trigger Part", {Text = "Trigger Part", Values = {"Any", "Head", "Torso"}, Default = "Any", Callback = function(v) TriggerbotSettings.TriggerPart = v end})
    triggerSection:AddToggle("Team Check", {Text = "Team Check", Default = false, Callback = function(v) TriggerbotSettings.Teamcheck = v end})

    -- Visuals Tab (ESP)
    local espSection = VisualsTab:AddLeftGroupbox("ESP")
    espSection:AddToggle("ESP Enabled", {Text = "Enabled", Default = false, Callback = function(v) ESPSettings.Enabled = v end})
    espSection:AddToggle("Show Box", {Text = "Show Box", Default = false, Callback = function(v) ESPSettings.ShowBox = v end})
    espSection:AddDropdown("Box Type", {Text = "Box Type", Values = {"Normal", "Corner"}, Default = "Normal", Callback = function(v) ESPSettings.BoxType = v end})
    espSection:AddToggle("Filled Box", {Text = "Filled Box", Default = false, Callback = function(v) ESPSettings.ShowFilledBox = v end})
    espSection:AddToggle("Show Name", {Text = "Show Name", Default = false, Callback = function(v) ESPSettings.ShowName = v end})
    espSection:AddToggle("Show Health", {Text = "Show Health", Default = false, Callback = function(v) ESPSettings.ShowHealth = v end})
    espSection:AddToggle("Show Distance", {Text = "Show Distance", Default = false, Callback = function(v) ESPSettings.ShowDistance = v end})
    espSection:AddToggle("Show Tracer", {Text = "Show Tracer", Default = false, Callback = function(v) ESPSettings.ShowTracer = v end})
    espSection:AddDropdown("Tracer Position", {Text = "Tracer Position", Values = {"Top", "Middle", "Bottom"}, Default = "Bottom", Callback = function(v) ESPSettings.TracerPosition = v end})
    espSection:AddToggle("Team Check", {Text = "Team Check", Default = false, Callback = function(v) ESPSettings.Teamcheck = v end})
    espSection:AddToggle("Wall Check", {Text = "Wall Check", Default = false, Callback = function(v) ESPSettings.WallCheck = v end})
    espSection:AddSlider("Tracer Thickness", {Text = "Tracer Thickness", Min = 1, Max = 5, Default = 1, Rounding = 0, Callback = function(v) ESPSettings.TracerThickness = v end})
    
    espSection:AddColorPicker("Box Color", {Text = "Box Color", Default = Color3.new(1, 1, 1), Callback = function(v) ESPSettings.BoxColor = v end})
    espSection:AddColorPicker("Name Color", {Text = "Name Color", Default = Color3.new(1, 1, 1), Callback = function(v) ESPSettings.NameColor = v end})
    espSection:AddColorPicker("Health Color", {Text = "Health Color", Default = Color3.new(1, 1, 1), Callback = function(v) ESPSettings.HealthColor = v end})
    espSection:AddColorPicker("Distance Color", {Text = "Distance Color", Default = Color3.new(1, 1, 1), Callback = function(v) ESPSettings.DistanceColor = v end})
    espSection:AddColorPicker("Tracer Color", {Text = "Tracer Color", Default = Color3.new(1, 1, 1), Callback = function(v) ESPSettings.TracerColor = v end})
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cache = {}

local function create(className, properties)
    local drawing = Drawing.new(className)
    for prop, val in pairs(properties) do
        drawing[prop] = val
    end
    return drawing
end

local function createEsp(player)
    local esp = {
        tracer = create("Line", { Thickness = ESPSettings.TracerThickness, Color = ESPSettings.TracerColor, Transparency = 1 }),
        boxOutline = create("Square", { Color = ESPSettings.BoxOutlineColor, Thickness = 3, Filled = false }),
        box = create("Square", { Color = ESPSettings.BoxColor, Thickness = 1, Filled = false }),
        filledBox = create("Square", { Color = ESPSettings.BoxColor, Thickness = 1, Transparency = 0.3, Filled = true }),
        nameTag = create("Text", { Color = ESPSettings.NameColor, Outline = true, Center = true, Size = 13 }),
        healthOutline = create("Line", { Thickness = 3, Color = ESPSettings.HealthOutlineColor }),
        healthBar = create("Line", { Thickness = 1 }),
        distanceText = create("Text", { Color = Color3.new(1, 1, 1), Size = 12, Outline = true, Center = true }),
        boxLines = {},
        currentHealth = 100
    }
    cache[player] = esp
end

local function removeEsp(player)
    local esp = cache[player]
    if not esp then return end
    for _, drawing in pairs(esp) do
        if type(drawing) == "table" and drawing.Remove then drawing:Remove() end
    end
    for _, line in ipairs(esp.boxLines) do line:Remove() end
    cache[player] = nil
end

local function isPlayerBehindWall(player)
    local character = player.Character
    if not character then return false end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local ray = Ray.new(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position).Unit * (rootPart.Position - camera.CFrame.Position).Magnitude)
    local hit, _ = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, character})
    return hit and hit:IsA("Part")
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function updateEsp()
    for player, esp in pairs(cache) do
        local character, team = player.Character, player.Team
        if character and (not ESPSettings.Teamcheck or (team and team ~= localPlayer.Team)) then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChild("Humanoid")
            local isBehindWall = ESPSettings.WallCheck and isPlayerBehindWall(player)
            local shouldShow = not isBehindWall and ESPSettings.Enabled

            if rootPart and head and humanoid and shouldShow then
                local hrp2D, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local charHeight = (camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.6, 0)).Y) / 2
                    local boxSize = Vector2.new(math.floor(charHeight * 1.4), math.floor(charHeight * 1.9))
                    local boxPosition = Vector2.new(math.floor(hrp2D.X - charHeight * 1.4 / 2), math.floor(hrp2D.Y - charHeight * 1.6 / 2))

                    if ESPSettings.ShowName then
                        esp.nameTag.Visible = true
                        esp.nameTag.Text = string.lower(player.Name)
                        esp.nameTag.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y - 16)
                        esp.nameTag.Color = ESPSettings.NameColor
                    else
                        esp.nameTag.Visible = false
                    end

                    if ESPSettings.ShowFilledBox then
                        esp.filledBox.Position = boxPosition
                        esp.filledBox.Size = boxSize
                        esp.filledBox.Color = ESPSettings.FilledBoxColor
                        esp.filledBox.Visible = true
                    else
                        esp.filledBox.Visible = false
                    end

                    if ESPSettings.ShowBox then
                        if ESPSettings.BoxType == "Normal" then
                            esp.boxOutline.Size = boxSize
                            esp.boxOutline.Position = boxPosition
                            esp.box.Size = boxSize
                            esp.box.Position = boxPosition
                            esp.box.Color = ESPSettings.BoxColor
                            esp.box.Visible = true
                            esp.boxOutline.Visible = true
                            for _, line in ipairs(esp.boxLines) do line:Remove() end
                            esp.boxLines = {}
                        elseif ESPSettings.BoxType == "Corner" then
                            local lineW = boxSize.X / 3
                            local lineH = boxSize.Y / 3
                            if #esp.boxLines == 0 then
                                for i = 1, 16 do
                                    esp.boxLines[i] = create("Line", {Thickness = 1, Color = ESPSettings.BoxColor, Transparency = 1})
                                end
                            end
                            local boxLines = esp.boxLines
                            for i = 1, 8 do
                                boxLines[i].Thickness = 2
                                boxLines[i].Color = ESPSettings.BoxOutlineColor
                            end
                            -- Corner ESP logic
                            boxLines[1].From = Vector2.new(boxPosition.X, boxPosition.Y)
                            boxLines[1].To = Vector2.new(boxPosition.X, boxPosition.Y + lineH)
                            boxLines[2].From = Vector2.new(boxPosition.X, boxPosition.Y)
                            boxLines[2].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y)
                            boxLines[3].From = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y)
                            boxLines[3].To = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y)
                            boxLines[4].From = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y)
                            boxLines[4].To = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y + lineH)
                            boxLines[5].From = Vector2.new(boxPosition.X, boxPosition.Y + boxSize.Y - lineH)
                            boxLines[5].To = Vector2.new(boxPosition.X, boxPosition.Y + boxSize.Y)
                            boxLines[6].From = Vector2.new(boxPosition.X, boxPosition.Y + boxSize.Y)
                            boxLines[6].To = Vector2.new(boxPosition.X + lineW, boxPosition.Y + boxSize.Y)
                            boxLines[7].From = Vector2.new(boxPosition.X + boxSize.X - lineW, boxPosition.Y + boxSize.Y)
                            boxLines[7].To = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y + boxSize.Y)
                            boxLines[8].From = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y + boxSize.Y - lineH)
                            boxLines[8].To = Vector2.new(boxPosition.X + boxSize.X, boxPosition.Y + boxSize.Y)

                            for i = 9, 16 do
                                boxLines[i].From = boxLines[i-8].From
                                boxLines[i].To = boxLines[i-8].To
                                boxLines[i].Color = ESPSettings.BoxColor
                            end
                            for _, line in ipairs(boxLines) do line.Visible = true end
                            esp.box.Visible = false
                            esp.boxOutline.Visible = false
                        end
                    else
                        esp.box.Visible = false
                        esp.boxOutline.Visible = false
                        for _, line in ipairs(esp.boxLines) do line:Remove() end
                        esp.boxLines = {}
                    end

                    if ESPSettings.ShowHealth then
                        esp.healthOutline.Visible = true
                        esp.healthBar.Visible = true
                        esp.currentHealth = lerp(esp.currentHealth, humanoid.Health, 0.3)
                        local healthPercentage = esp.currentHealth / humanoid.MaxHealth
                        local healthBarHeight = healthPercentage * boxSize.Y
                        esp.healthOutline.From = Vector2.new(boxPosition.X - 6, boxPosition.Y + boxSize.Y)
                        esp.healthOutline.To = Vector2.new(boxPosition.X - 6, boxPosition.Y - 1)
                        esp.healthBar.From = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y)
                        esp.healthBar.To = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y - healthBarHeight)
                        esp.healthBar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), healthPercentage)
                    else
                        esp.healthOutline.Visible = false
                        esp.healthBar.Visible = false
                    end

                    if ESPSettings.ShowDistance then
                        local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local distance = myRoot and (myRoot.Position - rootPart.Position).Magnitude or 0
                        esp.distanceText.Text = string.format("%.1f studs", distance)
                        esp.distanceText.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 5)
                        esp.distanceText.Color = ESPSettings.DistanceColor
                        esp.distanceText.Visible = true
                    else
                        esp.distanceText.Visible = false
                    end

                    if ESPSettings.ShowTracer then
                        local tracerY = camera.ViewportSize.Y
                        if ESPSettings.TracerPosition == "Top" then tracerY = 0
                        elseif ESPSettings.TracerPosition == "Middle" then tracerY = camera.ViewportSize.Y / 2 end
                        esp.tracer.Visible = true
                        esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, tracerY)
                        esp.tracer.To = Vector2.new(hrp2D.X, hrp2D.Y)
                        esp.tracer.Color = ESPSettings.TracerColor
                        esp.tracer.Thickness = ESPSettings.TracerThickness
                    else
                        esp.tracer.Visible = false
                    end
                else
                    for _, obj in pairs(esp) do
                        if typeof(obj) == "table" and obj.Visible ~= nil then obj.Visible = false end
                    end
                end
            else
                for _, obj in pairs(esp) do
                    if typeof(obj) == "table" and obj.Visible ~= nil then obj.Visible = false end
                end
            end
        else
            for _, obj in pairs(esp) do
                if typeof(obj) == "table" and obj.Visible ~= nil then obj.Visible = false end
            end
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then createEsp(player) end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then createEsp(player) end
end)
Players.PlayerRemoving:Connect(removeEsp)

local lastTrigger = 0
local function checkTriggerbot()
    if not TriggerbotSettings.Enabled then return end
    local currentTime = tick()
    if currentTime - lastTrigger < TriggerbotSettings.Delay / 1000 then return end

    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    if not result or not result.Instance then return end

    local model = result.Instance:FindFirstAncestorWhichIsA("Model")
    if not model then return end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local player = Players:GetPlayerFromCharacter(model)
    if player == localPlayer then return end

   
    if TriggerbotSettings.Teamcheck and player and player.Team == localPlayer.Team then return end

    -- Part Filter
    local hitPart = result.Instance
    if TriggerbotSettings.TriggerPart == "Head" then
        if hitPart.Name ~= "Head" then return end
    elseif TriggerbotSettings.TriggerPart == "Torso" then
        if hitPart.Name ~= "HumanoidRootPart" and hitPart.Name ~= "UpperTorso" and hitPart.Name ~= "LowerTorso" and hitPart.Name ~= "Torso" then return end
    end

    -- Fire
    mouse1click()
    lastTrigger = currentTime
end

local function onRenderStep()
    checkTriggerbot()
end

RunService.RenderStepped:Connect(onRenderStep)
RunService.RenderStepped:Connect(updateEsp)
createUI()

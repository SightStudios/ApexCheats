local Linoria = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/LinoriaLib/refs/heads/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/LinoriaLib/refs/heads/main/addons/SaveManager.lua"))()

local Window = Linoria:CreateWindow("apex lua")
local CombatTab = Window:AddTab("Combat")
local VisualsTab = Window:AddTab("Visuals")
local SettingsTab = Window:AddTab("Settings")

local TriggerbotSettings = {
    Enabled = false,
    Delay = 0,
    Teamcheck = false,
    TriggerPart = "Any",
    MaxDistance = 5000,
    DistanceCheck = false,
    NPCs = false
}

local AimlockSettings = {
    Enabled = false,
    Mode = "Camera",
    Smoothness = 0.8,
    DistanceCheck = false,
    MaxDistance = 5000,
    Teamcheck = false,
    TargetPart = "Head",
    NPCs = false
}

local ESPSettings = {
    Enabled = false,
    ShowBox = false,
    ShowName = false,
    ShowHealth = false,
    ShowDistance = false,
    ShowTracer = false,
    Teamcheck = false,
    NPCs = false
}

local function createUI()
    local triggerSection = CombatTab:AddLeftGroupbox("Triggerbot")
    triggerSection:AddToggle("TriggerEnabled", {Text = "Enabled", Default = false, Callback = function(v) TriggerbotSettings.Enabled = v end})
    triggerSection:AddToggle("TriggerNPCs", {Text = "Include NPCs", Default = false, Callback = function(v) TriggerbotSettings.NPCs = v end})
    triggerSection:AddSlider("TriggerDelay", {Text = "Delay (ms)", Min = 0, Max = 300, Default = 0, Rounding = 0, Callback = function(v) TriggerbotSettings.Delay = v end})
    triggerSection:AddDropdown("TriggerPart", {Text = "Trigger Part", Values = {"Any", "Head", "Torso"}, Default = "Any", Callback = function(v) TriggerbotSettings.TriggerPart = v end})
    triggerSection:AddToggle("TriggerTeam", {Text = "Team Check", Default = false, Callback = function(v) TriggerbotSettings.Teamcheck = v end})
    triggerSection:AddToggle("TriggerDistCheck", {Text = "Distance Check", Default = false, Callback = function(v) TriggerbotSettings.DistanceCheck = v end})
    triggerSection:AddSlider("TriggerMaxDist", {Text = "Max Distance", Min = 50, Max = 5000, Default = 1000, Rounding = 0, Callback = function(v) TriggerbotSettings.MaxDistance = v end})

    local aimlockSection = CombatTab:AddRightGroupbox("Aimlock")
    aimlockSection:AddToggle("AimlockEnabled", {Text = "Enabled", Default = false, Callback = function(v) AimlockSettings.Enabled = v end})
    aimlockSection:AddToggle("AimlockNPCs", {Text = "Include NPCs", Default = false, Callback = function(v) AimlockSettings.NPCs = v end})
    aimlockSection:AddLabel("Aimlock Key"):AddKeyPicker("AimlockKey", {Default = "E", Mode = "Hold", Text = "Aimlock Key"})
    aimlockSection:AddDropdown("AimlockMode", {Text = "Aimlock Mode", Values = {"Camera", "Mouse"}, Default = "Camera", Callback = function(v) AimlockSettings.Mode = v end})
    aimlockSection:AddSlider("AimlockSmoothness", {Text = "Speed/Sensitivity", Min = 1, Max = 100, Default = 80, Rounding = 0, Callback = function(v) AimlockSettings.Smoothness = v / 100 end})
    aimlockSection:AddDropdown("AimlockPart", {Text = "Target Part", Values = {"Head", "HumanoidRootPart"}, Default = "Head", Callback = function(v) AimlockSettings.TargetPart = v end})
    aimlockSection:AddToggle("AimlockTeam", {Text = "Team Check", Default = false, Callback = function(v) AimlockSettings.Teamcheck = v end})
    aimlockSection:AddToggle("AimlockDistCheck", {Text = "Distance Check", Default = false, Callback = function(v) AimlockSettings.DistanceCheck = v end})
    aimlockSection:AddSlider("AimlockMaxDist", {Text = "Max Distance", Min = 50, Max = 5000, Default = 1000, Rounding = 0, Callback = function(v) AimlockSettings.MaxDistance = v end})

    local espSection = VisualsTab:AddLeftGroupbox("ESP")
    espSection:AddToggle("ESPEnabled", {Text = "Enabled", Default = false, Callback = function(v) ESPSettings.Enabled = v end})
    espSection:AddToggle("ESPNPCs", {Text = "Include NPCs", Default = false, Callback = function(v) ESPSettings.NPCs = v end})
    espSection:AddToggle("ESPBox", {Text = "Show Box", Default = false, Callback = function(v) ESPSettings.ShowBox = v end})
    espSection:AddToggle("ESPName", {Text = "Show Name", Default = false, Callback = function(v) ESPSettings.ShowName = v end})
    espSection:AddToggle("ESPHealth", {Text = "Show Health", Default = false, Callback = function(v) ESPSettings.ShowHealth = v end})
    espSection:AddToggle("ESPDistance", {Text = "Show Distance", Default = false, Callback = function(v) ESPSettings.ShowDistance = v end})
    espSection:AddToggle("ESPTracer", {Text = "Show Tracer", Default = false, Callback = function(v) ESPSettings.ShowTracer = v end})
    espSection:AddToggle("ESPTeam", {Text = "Team Check", Default = false, Callback = function(v) ESPSettings.Teamcheck = v end})

    SaveManager:SetLibrary(Linoria)
    SaveManager:SetFolder("ApexLua")
    SaveManager:IgnoreThemeSettings()
    SaveManager:BuildConfigSection(SettingsTab)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local entityCache = {}

local function create(className, properties)
    local drawing = Drawing.new(className)
    for prop, val in pairs(properties) do drawing[prop] = val end
    return drawing
end

local function getEntities()
    local entities = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local char = player.Character
            if char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                table.insert(entities, {Char = char, Player = player, IsNPC = false, Name = player.Name})
            end
        end
    end
    for _, desc in ipairs(workspace:GetChildren()) do
        if desc:IsA("Model") and desc ~= localPlayer.Character and not Players:GetPlayerFromCharacter(desc) then
            local hum = desc:FindFirstChildOfClass("Humanoid")
            local root = desc:FindFirstChild("HumanoidRootPart")
            local head = desc:FindFirstChild("Head")
            if hum and root and head and hum.Health > 0 then
                table.insert(entities, {Char = desc, Player = nil, IsNPC = true, Name = desc.Name})
            end
        end
    end
    return entities
end

local function getDrawings(char)
    if not entityCache[char] then
        entityCache[char] = {
            box = create("Square", {Color = Color3.new(1,1,1), Thickness = 1, Filled = false, Visible = false}),
            nameTag = create("Text", {Color = Color3.new(1,1,1), Outline = true, Center = true, Size = 13, Visible = false}),
            tracer = create("Line", {Thickness = 1, Color = Color3.new(1,1,1), Visible = false}),
            health = create("Line", {Thickness = 2, Color = Color3.new(0,1,0), Visible = false})
        }
    end
    return entityCache[char]
end

local function cleanCache(currentEntities)
    local currentChars = {}
    for _, ent in ipairs(currentEntities) do
        currentChars[ent.Char] = true
    end
    for char, drawings in pairs(entityCache) do
        if not currentChars[char] then
            for _, d in pairs(drawings) do d:Remove() end
            entityCache[char] = nil
        end
    end
end

local function getClosestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local center = camera.ViewportSize / 2
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local entities = getEntities()
    for _, ent in ipairs(entities) do
        if ent.IsNPC and not AimlockSettings.NPCs then continue end
        if AimlockSettings.Teamcheck and not ent.IsNPC and ent.Player and ent.Player.Team == localPlayer.Team then continue end
        
        local part = ent.Char:FindFirstChild(AimlockSettings.TargetPart)
        if not part then part = ent.Char:FindFirstChild("Head") or ent.Char:FindFirstChild("HumanoidRootPart") end
        
        if part then
            local mag = (myRoot.Position - part.Position).Magnitude
            if AimlockSettings.DistanceCheck and mag > AimlockSettings.MaxDistance then continue end
            
            local pos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local screenDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if screenDist < shortestDistance then
                    shortestDistance = screenDist
                    closestTarget = ent
                end
            end
        end
    end
    return closestTarget
end

local lastTrigger = 0
local lastTargetUpdate = 0
local currentTarget = nil

RunService.RenderStepped:Connect(function()
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local entities = getEntities()

    if TriggerbotSettings.Enabled and myRoot and (tick() - lastTrigger >= TriggerbotSettings.Delay / 1000) then
        local center = camera.ViewportSize / 2
        local ray = camera:ViewportPointToRay(center.X, center.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {myChar}
        params.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorWhichIsA("Model")
            if model and model ~= myChar then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local player = Players:GetPlayerFromCharacter(model)
                    local isNPC = (player == nil)
                    local allowed = true
                    
                    if isNPC and not TriggerbotSettings.NPCs then allowed = false end
                    if TriggerbotSettings.Teamcheck and not isNPC and player.Team == localPlayer.Team then allowed = false end
                    if TriggerbotSettings.DistanceCheck and (myRoot.Position - result.Instance.Position).Magnitude > TriggerbotSettings.MaxDistance then allowed = false end
                    
                    if allowed then
                        local hitName = result.Instance.Name
                        if TriggerbotSettings.TriggerPart == "Head" and hitName ~= "Head" then allowed = false end
                        if TriggerbotSettings.TriggerPart == "Torso" and not (hitName:find("Torso") or hitName == "HumanoidRootPart") then allowed = false end
                        
                        if allowed then
                            mouse1click()
                            lastTrigger = tick()
                        end
                    end
                end
            end
        end
    end

    if AimlockSettings.Enabled and Linoria.Options.AimlockKey and Linoria.Options.AimlockKey:GetState() then
        if tick() - lastTargetUpdate >= 0.1 or not currentTarget or not currentTarget.Char or not currentTarget.Char.Parent or not currentTarget.Char:FindFirstChild("Humanoid") or currentTarget.Char.Humanoid.Health <= 0 then
            lastTargetUpdate = tick()
            currentTarget = getClosestTarget()
        end

        if currentTarget and currentTarget.Char then
            local part = currentTarget.Char:FindFirstChild(AimlockSettings.TargetPart)
            if not part then part = currentTarget.Char:FindFirstChild("Head") or currentTarget.Char:FindFirstChild("HumanoidRootPart") end
            
            if part then
                if AimlockSettings.Mode == "Camera" then
                    local lookAt = CFrame.new(camera.CFrame.Position, part.Position)
                    camera.CFrame = camera.CFrame:Lerp(lookAt, AimlockSettings.Smoothness)
                elseif AimlockSettings.Mode == "Mouse" then
                    local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mouseLocation = UserInputService:GetMouseLocation()
                        local deltaX = (pos.X - mouseLocation.X) * AimlockSettings.Smoothness
                        local deltaY = (pos.Y - mouseLocation.Y) * AimlockSettings.Smoothness
                        if mousemoverel then
                            mousemoverel(deltaX, deltaY)
                        end
                    end
                end
            end
        end
    else
        currentTarget = nil
    end

    cleanCache(entities)

    for _, ent in ipairs(entities) do
        local drawings = getDrawings(ent.Char)
        local visible = false
        
        if ESPSettings.Enabled and myRoot then
            if ent.IsNPC and not ESPSettings.NPCs then 
                for _, d in pairs(drawings) do d.Visible = false end
                continue 
            end
            
            local root = ent.Char:FindFirstChild("HumanoidRootPart")
            local head = ent.Char:FindFirstChild("Head")
            local hum = ent.Char:FindFirstChild("Humanoid")
            
            if root and head and hum then
                local isTeam = not ent.IsNPC and ent.Player and ent.Player.Team == localPlayer.Team
                if not (ESPSettings.Teamcheck and isTeam) then
                    local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        visible = true
                        local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                        local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                        
                        local height = math.abs(headPos.Y - legPos.Y)
                        local width = height / 1.5
                        
                        drawings.box.Visible = ESPSettings.ShowBox
                        drawings.box.Size = Vector2.new(width, height)
                        drawings.box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                        
                        drawings.nameTag.Visible = ESPSettings.ShowName
                        local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                        drawings.nameTag.Text = ent.Name .. (ESPSettings.ShowDistance and " [" .. dist .. "m]" or "")
                        drawings.nameTag.Position = Vector2.new(rootPos.X, rootPos.Y - height / 2 - 15)
                        
                        drawings.health.Visible = ESPSettings.ShowHealth
                        drawings.health.From = Vector2.new(rootPos.X - width / 2 - 5, rootPos.Y + height / 2)
                        drawings.health.To = Vector2.new(rootPos.X - width / 2 - 5, rootPos.Y + height / 2 - (height * (hum.Health / hum.MaxHealth)))
                        
                        drawings.tracer.Visible = ESPSettings.ShowTracer
                        drawings.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                        drawings.tracer.To = Vector2.new(rootPos.X, rootPos.Y + height / 2)
                    end
                end
            end
        end
        
        if not visible then
            for _, d in pairs(drawings) do d.Visible = false end
        end
    end
end)

createUI()

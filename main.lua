--[[
    HUD TÁTICO PERSONALIZADO - PEPETER EDITION (DAMAGE UPDATE)
    - ESP: Barra de Vida, Nome, Distância e INDICADOR DE DANO (-HP)
    - AFK: Anti-Disconnect + Envio automático de "!p"
    - Combate: Aimbot (MB2) e Toggle (T)
    - Menu Inicial: Estilo Neon Restaurado
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configurações
local ESP_KEY = Enum.UserInputType.MouseButton3
local AIM_KEY = Enum.UserInputType.MouseButton2
local TOGGLE_AIM_KEY = Enum.KeyCode.T
local FOV_RADIUS = 400
local BGM_ID = "97708834121472" 
local START_TIME = 15 

local espEnabled = false
local aimbotEnabled = false
local aimbotMasterSwitch = true
local aimTarget = nil
local tickStart = tick()
local antiAfkActive = false

-- --- FUNÇÃO DE CHAT AUTOMÁTICO ---
local function sendAutoChat(message)
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
        chatEvents.SayMessageRequest:FireServer(message, "All")
    else
        local textChatService = game:GetService("TextChatService")
        if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = textChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then channel:SendAsync(message) end
        end
    end
end

-- --- SISTEMA ANTI-AFK ---
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if antiAfkActive then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- --- INTERFACE AFK ---
local function createAFKModule()
    local afkGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    afkGui.Name = "PepeterAFK"; afkGui.ResetOnSpawn = false

    local container = Instance.new("Frame", afkGui)
    container.Size = UDim2.new(0, 200, 0, 60); container.Position = UDim2.new(0, 10, 1, -70); container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, 0, 0, 30); label.Text = "AFK, clique aqui quando quiser ficar AFK, e pode ir dar aquela sua cagada em paz"
    label.TextColor3 = Color3.new(1, 1, 1); label.TextWrapped = true; label.Font = Enum.Font.GothamMedium; label.TextSize = 10; label.BackgroundTransparency = 1

    local afkBtn = Instance.new("TextButton", container)
    afkBtn.Size = UDim2.new(0, 100, 0, 25); afkBtn.Position = UDim2.new(0.5, -50, 0.6, 0)
    afkBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); afkBtn.Text = "ATIVAR AFK"; afkBtn.TextColor3 = Color3.new(1, 1, 1)
    afkBtn.Font = Enum.Font.GothamBold; afkBtn.TextSize = 12; Instance.new("UICorner", afkBtn)

    afkBtn.MouseButton1Click:Connect(function()
        antiAfkActive = not antiAfkActive
        if antiAfkActive then
            sendAutoChat("!p")
            afkBtn.Text = "MODO PASSIVO"; afkBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        else
            afkBtn.Text = "ATIVAR AFK"; afkBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end)
end

-- --- ESP COM BARRA DE VIDA E INDICADOR DE DANO ---
local function createESP(player)
    local function setup(character)
        if not character or player == LocalPlayer then return end
        local head = character:WaitForChild("Head", 5)
        local humanoid = character:WaitForChild("Humanoid", 5)
        local lastHealth = humanoid.Health
        
        local highlight = Instance.new("Highlight", character)
        highlight.FillTransparency = 0.5; highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local billboard = Instance.new("BillboardGui", head)
        billboard.Size = UDim2.new(0, 200, 0, 100); billboard.AlwaysOnTop = true; billboard.ExtentsOffset = Vector3.new(0, 3, 0)

        -- Barra de Vida
        local healthBack = Instance.new("Frame", billboard)
        healthBack.Size = UDim2.new(0, 5, 0.5, 0); healthBack.Position = UDim2.new(0.2, -10, 0.2, 0)
        healthBack.BackgroundColor3 = Color3.new(0, 0, 0); healthBack.BorderSizePixel = 1
        
        local healthBar = Instance.new("Frame", healthBack)
        healthBar.Size = UDim2.new(1, 0, 1, 0); healthBar.BorderSizePixel = 0
        healthBar.AnchorPoint = Vector2.new(0, 1); healthBar.Position = UDim2.new(0, 0, 1, 0)
        
        -- Info Label
        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(0.8, 0, 0.5, 0); label.Position = UDim2.new(0.25, 0, 0.2, 0)
        label.BackgroundTransparency = 1; label.Font = Enum.Font.RobotoMono; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.TextStrokeTransparency = 0

        -- Função para mostrar o dano subindo
        local function showDamage(amount)
            local dmgLabel = Instance.new("TextLabel", billboard)
            dmgLabel.Size = UDim2.new(0, 50, 0, 20)
            dmgLabel.Position = UDim2.new(0.1, -25, 0.4, 0)
            dmgLabel.BackgroundTransparency = 1
            dmgLabel.Text = "-" .. math.floor(amount) .. " HP"
            dmgLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            dmgLabel.Font = Enum.Font.GothamBold; dmgLabel.TextSize = 14; dmgLabel.TextStrokeTransparency = 0
            
            local tween = TweenService:Create(dmgLabel, TweenInfo.new(1), {
                Position = UDim2.new(0.1, -25, 0.1, 0),
                TextTransparency = 1
            })
            tween:Play()
            tween.Completed:Connect(function() dmgLabel:Destroy() end)
        end

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not espEnabled or not character.Parent or not humanoid then 
                billboard:Destroy(); highlight:Destroy(); conn:Disconnect(); return 
            end
            
            -- Detectar Dano
            if humanoid.Health < lastHealth then
                showDamage(lastHealth - humanoid.Health)
                lastHealth = humanoid.Health
            elseif humanoid.Health > lastHealth then
                lastHealth = humanoid.Health
            end

            local isPassive = character:FindFirstChildOfClass("ForceField") ~= nil
            local mainColor = isPassive and Color3.fromRGB(0, 255, 255) or Color3.new(1, 1, 1)
            
            highlight.FillColor = isPassive and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
            label.TextColor3 = mainColor
            
            local dist = math.floor((Camera.CFrame.Position - head.Position).Magnitude)
            local tool = character:FindFirstChildOfClass("Tool")
            label.Text = string.format("%s\n%dM\n[%s]", player.Name:upper(), dist, tool and tool.Name or "---")
            
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            healthBar.Size = UDim2.new(1, 0, healthPercent, 0)
            healthBar.BackgroundColor3 = isPassive and Color3.fromRGB(0, 255, 255) or Color3.fromHSV(healthPercent * 0.33, 1, 1)
        end)
    end
    setup(player.Character); player.CharacterAdded:Connect(setup)
end

-- --- AIMBOT / TIMER / WELCOME (RESTANTE) ---
local function createTimer()
    local timerGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    timerGui.Name = "SessionTimer"; timerGui.ResetOnSpawn = false
    local timerLabel = Instance.new("TextLabel", timerGui)
    timerLabel.Size = UDim2.new(0, 150, 0, 30); timerLabel.Position = UDim2.new(1, -160, 0, 10)
    timerLabel.BackgroundTransparency = 0.5; timerLabel.BackgroundColor3 = Color3.new(0,0,0)
    timerLabel.TextColor3 = Color3.new(1,1,1); timerLabel.Font = Enum.Font.Code; timerLabel.TextSize = 16; Instance.new("UICorner", timerLabel)
    RunService.RenderStepped:Connect(function()
        local diff = math.floor(tick() - tickStart)
        timerLabel.Text = string.format("SESSÃO: %02d:%02d:%02d", math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
    end)
end

local function getClosestPlayer()
    if not aimbotMasterSwitch then return nil end
    local target = nil; local shortestDist = math.huge; local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortestDist and dist < FOV_RADIUS then target = p; shortestDist = dist end
                end
            end
        end
    end
    return target
end

UserInputService.InputBegan:Connect(function(input, proc)
    if proc then return end
    if input.KeyCode == TOGGLE_AIM_KEY then
        aimbotMasterSwitch = not aimbotMasterSwitch
        StarterGui:SetCore("SendNotification", {Title = "AIMBOT", Text = aimbotMasterSwitch and "ATIVADO" or "DESATIVADO", Duration = 2})
    elseif input.UserInputType == ESP_KEY then
        espEnabled = not espEnabled
        if espEnabled then for _, p in pairs(Players:GetPlayers()) do createESP(p) end end
    elseif input.UserInputType == AIM_KEY and aimbotMasterSwitch then
        aimbotEnabled = true; aimTarget = getClosestPlayer()
    end
end)

UserInputService.InputEnded:Connect(function(i) if i.UserInputType == AIM_KEY then aimbotEnabled = false; aimTarget = nil end end)

RunService:BindToRenderStep("AimbotUpdate", 201, function()
    if aimbotMasterSwitch and aimbotEnabled and aimTarget and aimTarget.Character and aimTarget.Character:FindFirstChild("Head") then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimTarget.Character.Head.Position)
    end
end)

local function createWelcomeGui()
    local screenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    screenGui.Name = "PepeterWelcome"; screenGui.ResetOnSpawn = false
    local bgm = Instance.new("Sound", screenGui)
    bgm.SoundId = "rbxassetid://" .. BGM_ID; bgm.Volume = 1; bgm.Looped = true; bgm.TimePosition = START_TIME; bgm:Play()
    local main = Instance.new("Frame", screenGui)
    main.Size = UDim2.new(0, 350, 0, 180); main.Position = UDim2.new(0.5, -175, 0.4, 0); main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12); local stroke = Instance.new("UIStroke", main); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(255, 0, 100) 
    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 60); title.Text = "CREATE BY PEPETER, não tem como bb"; title.TextColor3 = Color3.new(1, 1, 1); title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.BackgroundTransparency = 1
    local subTitle = Instance.new("TextLabel", main)
    subTitle.Position = UDim2.new(0, 0, 0.35, 0); subTitle.Size = UDim2.new(1, 0, 0, 40); subTitle.Text = "clique T pra desativar o aimbot, bobinho"; subTitle.TextColor3 = Color3.fromRGB(200, 200, 200); subTitle.Font = Enum.Font.GothamMedium; subTitle.TextSize = 14; subTitle.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0, 160, 0, 45); btn.Position = UDim2.new(0.5, -80, 0.7, 0); btn.BackgroundColor3 = Color3.fromRGB(255, 0, 100); btn.Text = "ta bom, peter!"; btn.TextColor3 = Color3.new(1, 1, 1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function() bgm:Stop(); screenGui:Destroy() end)
end

-- Iniciar
createAFKModule(); createTimer(); createWelcomeGui()
Players.PlayerAdded:Connect(createESP)

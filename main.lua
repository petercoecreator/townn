--[[
    HUD TÁTICO PERSONALIZADO - PEPETER EDITION (DAMAGE UPDATE)
    - ESP: Barra de Vida, Nome, Distância e INDICADOR DE DANO (-HP)
    - Combate: Aimbot (MB2) e Toggle (T)
    - Menu Inicial: Estilo Neon Restaurado
]]

local Players = game:GetService("Players")
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

        local healthBack = Instance.new("Frame", billboard)
        healthBack.Size = UDim2.new(0, 5, 0.5, 0); healthBack.Position = UDim2.new(0.2, -10, 0.2, 0)
        healthBack.BackgroundColor3 = Color3.new(0, 0, 0); healthBack.BorderSizePixel = 1
        
        local healthBar = Instance.new("Frame", healthBack)
        healthBar.Size = UDim2.new(1, 0, 1, 0); healthBar.BorderSizePixel = 0
        healthBar.AnchorPoint = Vector2.new(0, 1); healthBar.Position = UDim2.new(0, 0, 1, 0)
        
        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(0.8, 0, 0.5, 0); label.Position = UDim2.new(0.25, 0, 0.2, 0)
        label.BackgroundTransparency = 1; label.Font = Enum.Font.RobotoMono; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.TextStrokeTransparency = 0

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

-- --- TIMER ---
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

-- --- AIMBOT ---
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

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == AIM_KEY then
        aimbotEnabled = false; aimTarget = nil
    end
end)

RunService:BindToRenderStep("AimbotUpdate", 201, function()
    if aimbotMasterSwitch and aimbotEnabled and aimTarget and aimTarget.Character and aimTarget.Character:FindFirstChild("Head") then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimTarget.Character.Head.Position)
    end
end)

-- --- WELCOME ---
local function createWelcomeGui()
    local screenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    screenGui.Name = "PepeterWelcome"; screenGui.ResetOnSpawn = false
    local bgm = Instance.new("Sound", screenGui)
    bgm.SoundId = "rbxassetid://" .. BGM_ID; bgm.Volume = 1; bgm.Looped = true; bgm.TimePosition = START_TIME; bgm:Play()
    local main = Instance.new("Frame", screenGui)
    main.Size = UDim2.new(0, 350, 0, 180); main.Position = UDim2.new(0.5, -175, 0.4, 0); main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", main); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(255, 0, 100) 
    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 60); title.Text = "CREATE BY PEPETER, não tem como bb"; title.TextColor3 = Color3.new(1, 1, 1); title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.BackgroundTransparency = 1
    local subTitle = Instance.new("TextLabel", main)
    subTitle.Position = UDim2.new(0, 0, 0.35, 0); subTitle.Size = UDim2.new(1, 0, 0, 40); subTitle.Text = "clique T pra desativar o aimbot, bobinho"; subTitle.TextColor3 = Color3.fromRGB(200, 200, 200); subTitle.Font = Enum.Font.GothamMedium; subTitle.TextSize = 14; subTitle.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0, 160, 0, 45); btn.Position = UDim2.new(0.5, -80, 0.7, 0); btn.BackgroundColor3 = Color3.fromRGB(255, 0, 100); btn.Text = "ta bom, peter!"; btn.TextColor3 = Color3.new(1, 1, 1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function() bgm:Stop(); screenGui:Destroy() end)
end

-- Iniciar
createTimer()
createWelcomeGui()
Players.PlayerAdded:Connect(createESP)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local playerName = LocalPlayer.Name 

local tickStart = tick()
local antiAfkActive = false

-- --- FUNÇÃO DE CHAT (ENVIAR !P) ---
local function sendChat(message)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            channel:SendAsync(message)
        end
    else
        local sayMessage = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if sayMessage and sayMessage:FindFirstChild("SayMessageRequest") then
            sayMessage.SayMessageRequest:FireServer(message, "All")
        end
    end
end

-- --- LÓGICA ANTI-AFK ---
LocalPlayer.Idled:Connect(function()
    if antiAfkActive then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- --- GUI PRINCIPAL ---
local gui = Instance.new("ScreenGui")
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- INDICADOR ANTI-AFK (CANTO DIREITO)
local afkStatusLabel = Instance.new("TextLabel")
afkStatusLabel.Size = UDim2.new(0, 150, 0, 30)
afkStatusLabel.Position = UDim2.new(1, -160, 1, -40)
afkStatusLabel.BackgroundColor3 = Color3.new(0,0,0)
afkStatusLabel.BackgroundTransparency = 0.5
afkStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
afkStatusLabel.Text = "ANTIAFK DISABLE"
afkStatusLabel.Font = Enum.Font.GothamBold
afkStatusLabel.TextSize = 13
afkStatusLabel.Parent = gui
Instance.new("UICorner", afkStatusLabel)

-- BOTÃO AFK PRINCIPAL
local button = Instance.new("TextButton")
button.Size = UDim2.new(0,120,0,40)
button.Position = UDim2.new(0,10,1,-50)
button.Text = "AFK"
button.BackgroundColor3 = Color3.fromRGB(20,20,20)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.GothamBold
button.Parent = gui
Instance.new("UICorner", button)

local cooldownActive = false

-- TERMINAL CMD
local cmd = Instance.new("Frame")
cmd.Size = UDim2.new(0.6,0,0.5,0)
cmd.Position = UDim2.new(0.2,0,0.25,0)
cmd.BackgroundColor3 = Color3.fromRGB(0,0,0)
cmd.Visible = false
cmd.Parent = gui

-- TEXTO TERMINAL
local text = Instance.new("TextLabel")
text.Size = UDim2.new(1,-20,1,-20)
text.Position = UDim2.new(0,10,0,10)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.fromRGB(200,200,200)
text.Font = Enum.Font.Code
text.TextSize = 16
text.TextXAlignment = Enum.TextXAlignment.Left
text.TextYAlignment = Enum.TextYAlignment.Top
text.TextWrapped = true
text.Text = ""
text.Parent = cmd

-- INPUT INVISÍVEL
local input = Instance.new("TextBox")
input.Size = UDim2.new(0,300,0,20)
input.BackgroundTransparency = 1
input.BorderSizePixel = 0
input.TextTransparency = 1 
input.ClearTextOnFocus = false
input.Text = ""
input.Parent = cmd

-- MENSAGEM FINAL (CENTRAL)
local final = Instance.new("TextLabel")
final.Size = UDim2.new(0,350,0,60)
final.Position = UDim2.new(0.5,-175,0.7,0)
final.BackgroundColor3 = Color3.fromRGB(0,0,0)
final.BackgroundTransparency = 0.4
final.TextColor3 = Color3.fromRGB(0,255,120)
final.Font = Enum.Font.GothamBold
final.TextScaled = true
final.Visible = false
final.Parent = gui
Instance.new("UICorner", final)

-- TIMER DE SESSÃO
local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 150, 0, 30)
timerLabel.Position = UDim2.new(0.5, -75, 0.65, 0)
timerLabel.BackgroundColor3 = Color3.new(0,0,0)
timerLabel.BackgroundTransparency = 0.6
timerLabel.TextColor3 = Color3.new(1,1,1)
timerLabel.Font = Enum.Font.Code
timerLabel.TextSize = 18
timerLabel.Visible = false
timerLabel.Parent = gui
Instance.new("UICorner", timerLabel)

-- BOTÃO VOLTEI
local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.new(0,180,0,45)
backBtn.Position = UDim2.new(0.5,-90,0.85,0)
backBtn.Text = "voltei"
backBtn.BackgroundColor3 = Color3.fromRGB(0,255,120)
backBtn.TextColor3 = Color3.new(0,0,0)
backBtn.Font = Enum.Font.GothamBold
backBtn.TextScaled = true
backBtn.Visible = false
backBtn.Parent = gui
Instance.new("UICorner", backBtn)

-- --- LÓGICA DO TERMINAL ---

local function updateInputPosition()
	task.wait()
	local lastLine = text.Text:match("[^\n]*$")
	local lineCount = select(2, text.Text:gsub("\n","\n")) + 1
	input.Position = UDim2.new(0, 10 + (#lastLine * 8), 0, 8 + (lineCount - 1) * 18)
end

local function typeText(full)
	text.Text = ""
	for i = 1, #full do
		text.Text = string.sub(full, 1, i)
		task.wait(0.01)
	end
    updateInputPosition()
end

RunService.RenderStepped:Connect(function()
    if timerLabel.Visible then
        local diff = math.floor(tick() - tickStart)
        timerLabel.Text = string.format("%02d:%02d:%02d", math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
    end
end)

input:GetPropertyChangedSignal("Text"):Connect(function()
	local baseLine = text.Text:match(".*> ") or text.Text
	text.Text = baseLine .. input.Text
	updateInputPosition()
end)

-- --- SEQUÊNCIA DE CARREGAMENTO ---
local function runSequence()
	local fullTerminalText = string.format([[
> iniciando protocolo...
> verificando integridade do sistema...
> estabelecendo conexão segura...
> proteção tática ativada...
> monitorando arredores em tempo real...
> firewall %s v3.0 ativo...
> acesso concedido com sucesso...
> o jogador %s entrou no modo proteção...
]], playerName, playerName)

	typeText(fullTerminalText)
	task.wait(1)

	cmd.Visible = false
	final.Text = "você está protegido"
	final.Visible = true
	backBtn.Visible = true
    
    tickStart = tick()
    timerLabel.Visible = true
    antiAfkActive = true
    afkStatusLabel.Text = "ANTIAFK ENABLE"
    afkStatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
    
    sendChat("!p")
end

-- CLIQUE AFK (ABRIR TERMINAL)
button.MouseButton1Click:Connect(function()
	if cooldownActive then return end
	cmd.Visible = true
    
    -- AVISO ABAIXO DOS DIREITOS AUTORAIS
	local header = "Microsoft Windows [versão 10.0.19045]\n(c) Roblox Corp. Todos os direitos reservados.\nUtilize o comando afk.load para entrar no modo afk\n\nC:\\Users\\"..playerName.."> "
	
    typeText(header)
	input:CaptureFocus()
end)

-- CLIQUE VOLTEI
backBtn.MouseButton1Click:Connect(function()
	final.Visible = false
	backBtn.Visible = false
    timerLabel.Visible = false
    antiAfkActive = false
    afkStatusLabel.Text = "ANTIAFK DISABLE"
    afkStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    
    sendChat("!p") 
    
    -- Cooldown de 120s no Botão AFK
    cooldownActive = true
    task.spawn(function()
        for i = 120, 1, -1 do
            button.Text = "AFK ("..i.."s)"
            button.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
            task.wait(1)
        end
        button.Text = "AFK"
        button.BackgroundColor3 = Color3.fromRGB(20,20,20)
        cooldownActive = false
    end)
end)

-- GESTÃO DE INPUT
input.FocusLost:Connect(function(enter)
	if enter then
		local cmdText = input.Text
		text.Text = text.Text .. cmdText .. "\n"
		input.Text = ""

		if cmdText:lower() == "afk.load" then
			runSequence()
		else
			text.Text = text.Text .. "'" .. cmdText .. "' não reconhecido.\nC:\\Users\\"..playerName.."> "
			updateInputPosition()
			input:CaptureFocus()
		end
	end
end)
--aviso sobre o cooldown--
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AFKWarningGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 120)
frame.Position = UDim2.new(0, 20, 1, -140)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Texto principal (ATUALIZADO)
local text = Instance.new("TextLabel")
text.Size = UDim2.new(1, -20, 0, 70)
text.Position = UDim2.new(0, 10, 0, 10)
text.BackgroundTransparency = 1
text.Text = "Aviso: Depois de usar o botão AFK, espere um tempo de 2 minutos antes de usar novamente. O jogo possui um cooldown."
text.TextColor3 = Color3.fromRGB(255, 255, 255)
text.TextScaled = true
text.Font = Enum.Font.Gotham
text.Parent = frame

-- Texto menor
local smallText = Instance.new("TextLabel")
smallText.Size = UDim2.new(1, -20, 0, 20)
smallText.Position = UDim2.new(0, 10, 0, 85)
smallText.BackgroundTransparency = 1
smallText.Text = "Esse GUI vai se destruir daqui a 10 segundos"
smallText.TextColor3 = Color3.fromRGB(180, 180, 180)
smallText.TextSize = 12
smallText.Font = Enum.Font.Gotham
smallText.Parent = frame

-- Função de fechar com animação
local function closeGui()
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local fade = TweenService:Create(frame, tweenInfo, {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 300, 0, 110)
	})

	for _, v in pairs(frame:GetDescendants()) do
		if v:IsA("TextLabel") then
			TweenService:Create(v, tweenInfo, {
				TextTransparency = 1
			}):Play()
		end
	end

	fade:Play()
	fade.Completed:Wait()

	gui:Destroy()
end

-- Auto fechar em 10 segundos
task.delay(10, function()
	if gui then
		closeGui()
	end
end)
--tempo L--
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- Salvar configurações originais do jogo
local original = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ExposureCompensation = Lighting.ExposureCompensation
}

local isDay = false

local function setDay()
	Lighting.Brightness = 3
	Lighting.ClockTime = 14 -- meio-dia
	Lighting.FogEnd = 100000
	Lighting.ExposureCompensation = 0.5

	Lighting.Ambient = Color3.fromRGB(255, 255, 255)
	Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
end

local function restore()
	Lighting.Brightness = original.Brightness
	Lighting.ClockTime = original.ClockTime
	Lighting.FogEnd = original.FogEnd
	Lighting.Ambient = original.Ambient
	Lighting.OutdoorAmbient = original.OutdoorAmbient
	Lighting.ExposureCompensation = original.ExposureCompensation
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.L then
		isDay = not isDay

		if isDay then
			setDay()
		else
			restore()
		end
	end
end)
--diz oque cada tecla faz--
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HelpGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Frame principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 160)
frame.Position = UDim2.new(0, 10, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Ícone minimizado
local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(1, 0, 1, 0)
icon.BackgroundTransparency = 1
icon.Text = "≡"
icon.TextColor3 = Color3.fromRGB(255, 255, 255)
icon.Font = Enum.Font.GothamBold
icon.TextSize = 24
icon.Visible = false
icon.Parent = frame

-- Texto principal (AGORA CORRIGIDO)
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -16, 1, -16)
label.Position = UDim2.new(0, 8, 0, 8)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.Gotham
label.TextSize = 13
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true -- 🔥 ESSA LINHA CORRIGE O PROBLEMA

label.Text =
"1 - Aperte T para desativar/ativar o aimbot;\n" ..
"2 - aperte o scroll do mouse para ativar o ESP;\n" ..
"3 - aperte L para ativar/desativar a visão noturna;\n" ..
"4 - aperte TAB para minimizar esse gui;\n" ..
"5 - segure o botão esquerdo do mouse para usar o aimbot;"

label.Parent = frame

-- estado
local minimized = false

local function minimize()
	minimized = true
	label.Visible = false
	icon.Visible = true

	frame:TweenSize(UDim2.new(0, 30, 0, 30), "Out", "Quad", 0.25, true)
end

local function maximize()
	minimized = false
	icon.Visible = false

	frame:TweenSize(UDim2.new(0, 260, 0, 160), "Out", "Quad", 0.25, true)

	task.wait(0.25)
	label.Visible = true
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Enum.KeyCode.Tab then
		if minimized then
			maximize()
		else
			minimize()
		end
	end
end)

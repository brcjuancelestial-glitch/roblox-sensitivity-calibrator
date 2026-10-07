--[[
    ROBLOX SENSITIVITY CALIBRATOR
    LocalScript
    Coloque em: StarterPlayer > StarterPlayerScripts

    COMO USAR:
    1. Pressione F6 para fazer uma medição
    2. Mova o mouse suavemente por 2 segundos
    3. Veja o resultado da medição
    4. Anote o valor de "Resposta"
    5. Vá para outro jogo e repita
    6. Compare os valores manualmente
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CALIBRATION_TIME = 2.0
local MIN_MOUSE_DISTANCE = 30
local DEBUG = false

local state = {
    measuring = false,
    mouseDistance = 0,
    cameraDegrees = 0,
    previousYaw = nil,
    previousPitch = nil,
    
    measurement = nil,
}

local gui = nil
local info = nil

------------------------------------------------------------
-- UTILITÁRIOS
------------------------------------------------------------

local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Sensitivity Meter",
            Text = text,
            Duration = 3,
        })
    end)
end

local function toSignedAngleDiff(a, b)
    local diff = a - b

    while diff > 180 do
        diff -= 360
    end

    while diff < -180 do
        diff += 360
    end

    return diff
end

local function getCameraAngles()
    local cam = workspace.CurrentCamera
    if not cam then
        return 0, 0
    end

    local look = cam.CFrame.LookVector

    local yaw = math.deg(math.atan2(-look.X, -look.Z))
    local pitch = math.deg(math.asin(math.clamp(look.Y, -1, 1)))

    return yaw, pitch
end

local function updateDisplay()
    if not info then return end
    
    if state.measurement then
        info.Text = string.format(
            "Mouse:       %.0f px\nCâmera:      %.1f°\nResposta:    %.6f °/px\n\nF6 = nova medição\nF8 = limpar\n\nAnote e compare com outros jogos.",
            state.measurement.mouseDistance,
            state.measurement.cameraDegrees,
            state.measurement.response
        )
    else
        info.Text = "Aguardando medição...\n\nF6 = iniciar medição\n\nMova o mouse suavemente\npor 2 segundos."
    end
end

------------------------------------------------------------
-- CRIAR GUI
------------------------------------------------------------

local function createGui()
    if gui then return end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "SensitivityCalibrator"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.fromOffset(380, 240)
    frame.Position = UDim2.new(0, 20, 0.5, -120)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 36)
    title.Position = UDim2.fromOffset(10, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "SENSITIVITY METER"
    title.Parent = frame

    info = Instance.new("TextLabel")
    info.Name = "Info"
    info.Size = UDim2.new(1, -20, 1, -60)
    info.Position = UDim2.fromOffset(10, 50)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.GothamMono
    info.TextSize = 13
    info.TextColor3 = Color3.fromRGB(220, 220, 225)
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.TextWrapped = true
    info.Parent = frame
    
    updateDisplay()
end

------------------------------------------------------------
-- INPUT DO MOUSE
------------------------------------------------------------

UserInputService.InputChanged:Connect(function(input)
    if not state.measuring then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        state.mouseDistance += math.sqrt(
            input.Delta.X * input.Delta.X +
            input.Delta.Y * input.Delta.Y
        )
    end
end)

------------------------------------------------------------
-- RENDER STEP
------------------------------------------------------------

RunService.RenderStepped:Connect(function()
    if not state.measuring then
        return
    end

    local yaw, pitch = getCameraAngles()

    if state.previousYaw ~= nil then
        local yawDelta = math.abs(toSignedAngleDiff(yaw, state.previousYaw))
        local pitchDelta = math.abs(pitch - state.previousPitch)

        state.cameraDegrees += math.sqrt(
            yawDelta * yawDelta +
            pitchDelta * pitchDelta
        )
    end

    state.previousYaw = yaw
    state.previousPitch = pitch
end)

------------------------------------------------------------
-- MEDIÇÃO
------------------------------------------------------------

local function measure()
    if state.measuring then
        return
    end

    camera = workspace.CurrentCamera
    if not camera then
        notify("Câmera não encontrada.")
        return
    end

    state.measuring = true
    state.mouseDistance = 0
    state.cameraDegrees = 0
    state.previousYaw, state.previousPitch = getCameraAngles()

    if info then
        info.Text = "MEDINDO...\n\nMova o mouse suavemente\npor 2 segundos..."
    end

    notify("Medição iniciada.")

    local start = os.clock()
    while state.measuring and (os.clock() - start) < CALIBRATION_TIME do
        RunService.RenderStepped:Wait()
    end

    if not state.measuring then
        return
    end

    state.measuring = false

    if state.mouseDistance < MIN_MOUSE_DISTANCE then
        if info then
            info.Text = "FALHOU: Movimento insuficiente!\n\nMova o mouse mais durante\na medição.\n\nF6 para tentar novamente."
        end
        notify("Movimento insuficiente.")
        return
    end

    local response = state.cameraDegrees / state.mouseDistance

    state.measurement = {
        mouseDistance = state.mouseDistance,
        cameraDegrees = state.cameraDegrees,
        response = response,
    }

    updateDisplay()

    if DEBUG then
        print("mouseDistance =", state.mouseDistance)
        print("cameraDegrees =", state.cameraDegrees)
        print("response =", response)
    end

    notify("Medição concluída!")
end

------------------------------------------------------------
-- LIMPAR RESULTADOS
------------------------------------------------------------

local function clearResults()
    state.measurement = nil
    updateDisplay()
    notify("Medição apagada.")
end

------------------------------------------------------------
-- TECLAS
------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F6 then
        measure()
    elseif input.KeyCode == Enum.KeyCode.F8 then
        clearResults()
    end
end)

------------------------------------------------------------
-- INICIALIZAÇÃO
------------------------------------------------------------

task.wait(0.1)
createGui()

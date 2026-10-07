-- Roblox Sensitivity Calibration Prototype
-- Coloque em StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Calibration = {
    active = false,
    autoMode = false,
    started = false,
    startYaw = 0,
    lastYaw = 0,
    totalYaw = 0,
    targetYaw = math.rad(360),
    referenceCounts = 10000,
    measuredCounts = 15000,
    correctionFactor = 1,
    residual = 0,
    lastMouseX = 0,
    rotationSpeedDeg = 120,
}

local function normalizeAngle(angle)
    while angle > math.pi do
        angle = angle - (math.pi * 2)
    end
    while angle < -math.pi do
        angle = angle + (math.pi * 2)
    end
    return angle
end

local function getCameraYaw()
    if camera and camera.CFrame then
        local _, yaw = camera.CFrame:ToEulerAnglesYXZ()
        return yaw
    end
    return 0
end

local function calculateCorrectionFactor(reference, gameValue)
    if not gameValue or gameValue <= 0 then
        return 1
    end
    return reference / gameValue
end

local function finishCalibration()
    if not Calibration.started then
        return
    end

    Calibration.started = false
    Calibration.active = false

    if Calibration.measuredCounts and Calibration.measuredCounts > 0 then
        Calibration.correctionFactor = calculateCorrectionFactor(
            Calibration.referenceCounts,
            Calibration.measuredCounts
        )
    else
        Calibration.correctionFactor = 1
    end

    print("[Sensitivity] Calibracao finalizada.")
    print("[Sensitivity] Fator de correcao:", Calibration.correctionFactor)
end

local function startCalibration()
    Calibration.started = true
    Calibration.active = true
    Calibration.startYaw = getCameraYaw()
    Calibration.lastYaw = Calibration.startYaw
    Calibration.totalYaw = 0
    Calibration.residual = 0
    Calibration.lastMouseX = 0

    print("[Sensitivity] Calibracao iniciada. Gire 360 graus.")
end

local function startAuto360Test()
    Calibration.startYaw = getCameraYaw()
    Calibration.lastYaw = Calibration.startYaw
    Calibration.totalYaw = 0
    Calibration.started = true
    Calibration.active = true
    Calibration.autoMode = true

    print("[Sensitivity] Auto 360 iniciando...")
end

local function applyCorrection(rawDelta)
    if not Calibration.active then
        return rawDelta
    end

    Calibration.residual = Calibration.residual + (rawDelta * Calibration.correctionFactor)

    local integerPart = math.floor(Calibration.residual)
    Calibration.residual = Calibration.residual - integerPart

    return integerPart
end

local function rotateCamera(deltaYaw)
    if not camera then
        return
    end

    camera.CFrame = camera.CFrame * CFrame.Angles(0, deltaYaw, 0)
end

local function check360Calibration()
    if not Calibration.started then
        return
    end

    local currentYaw = getCameraYaw()
    local deltaYaw = normalizeAngle(currentYaw - Calibration.lastYaw)
    Calibration.totalYaw = Calibration.totalYaw + deltaYaw
    Calibration.lastYaw = currentYaw

    if math.abs(Calibration.totalYaw) >= Calibration.targetYaw then
        print("[Sensitivity] 360 graus detectados.")
        finishCalibration()
    end
end

local function handleMouseMovement(input, processed)
    if processed then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    local delta = input.Delta
    local rawX = delta.X

    if Calibration.active then
        local corrected = applyCorrection(rawX)

        if corrected ~= 0 then
            rotateCamera(math.rad(corrected * 0.02))
        end
    end
end

local function autoRotate360Step()
    if not Calibration.autoMode then
        return
    end

    local currentYaw = getCameraYaw()
    local wrappedDelta = normalizeAngle(currentYaw - Calibration.lastYaw)
    Calibration.totalYaw = Calibration.totalYaw + wrappedDelta
    Calibration.lastYaw = currentYaw

    local stepYaw = math.rad(Calibration.rotationSpeedDeg / 60)
    rotateCamera(stepYaw)

    if math.abs(Calibration.totalYaw) >= Calibration.targetYaw then
        print("[Sensitivity] Auto 360 concluido.")
        Calibration.autoMode = false
        Calibration.active = false
        Calibration.started = false
        Calibration.measuredCounts = 15000
        Calibration.correctionFactor = calculateCorrectionFactor(
            Calibration.referenceCounts,
            Calibration.measuredCounts
        )
        print("[Sensitivity] Fator calculado:", Calibration.correctionFactor)
    end
end

UserInputService.InputChanged:Connect(handleMouseMovement)
RunService.RenderStepped:Connect(function()
    if Calibration.started and not Calibration.autoMode then
        check360Calibration()
    end

    if Calibration.autoMode then
        autoRotate360Step()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.C then
        startCalibration()
    elseif input.KeyCode == Enum.KeyCode.V then
        finishCalibration()
    elseif input.KeyCode == Enum.KeyCode.B then
        startAuto360Test()
    end
end)

print("[Sensitivity] Prototype loaded.")
print("[Sensitivity] Teclas: C = calibrar | V = finalizar | B = auto 360")

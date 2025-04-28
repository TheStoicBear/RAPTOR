-- NUI UI toggle for ESP icon
local isESPUIActive = false
local function ShowESPUI(status)
    -- debug print
    print("[ESP] ShowESPUI called, status=", status)
    if isESPUIActive == status then return end
    isESPUIActive = status
    SendNUIMessage({ type = "esp", status = status })
end

-- ESP enable flag
local ESPEnabled = true
RegisterCommand('+toggleESP', function()
    ESPEnabled = not ESPEnabled
    print(('ESP %s'):format(ESPEnabled and 'ENABLED' or 'DISABLED'))
    if not ESPEnabled then
        ShowESPUI(false)
    end
end, false)
RegisterKeyMapping('+toggleESP', 'Toggle ESP', 'keyboard', 'F7')

-- Pulse braking toggle (optional)
local PulseBrakeEnabled = true

-- Intervention parameters
local lowSpeed     = 20.0    -- m/s below which torque cut prioritized
local highSpeed    = 40.0    -- m/s above which braking prioritized
local slipThresh   = 2.0     -- degrees to start intervention
local maxSlip      = 45.0    -- degrees for full intervention
local maxTorqueCut = 0.5     -- max fraction of torque removed

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local ped = PlayerPedId()
        if not ESPEnabled or not IsPedInAnyVehicle(ped, false) then
            -- ensure UI hidden and reset
            if isESPUIActive then ShowESPUI(false) end
            -- reset any modified values
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                SetVehicleEngineTorqueMultiplier(veh, 1.0)
                for i = 0, GetVehicleNumberOfWheels(veh) - 1 do
                    SetVehicleWheelBrakePressure(veh, i, 0.0)
                end
            end
            goto continue
        end

        local veh = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(veh, -1) ~= ped then
            goto continue
        end

        local speed = GetEntitySpeed(veh)
        if speed < 5.0 then
            if isESPUIActive then ShowESPUI(false) end
            goto continue
        end

        -- compute slip angle safely
        local vel = GetEntityVelocity(veh)
        local heading = math.rad(GetEntityHeading(veh))
        local fwdX, fwdY = math.sin(heading), math.cos(heading)
        local rightX, rightY = fwdY, -fwdX
        local fwdSpeed = vel.x * fwdX + vel.y * fwdY
        local latSpeed = vel.x * rightX + vel.y * rightY
        local slipAng = math.deg(math.atan2(latSpeed, fwdSpeed))
        local absSlip = math.abs(slipAng)

        if absSlip <= slipThresh then
            if isESPUIActive then ShowESPUI(false) end
            -- restore torque/brakes
            SetVehicleEngineTorqueMultiplier(veh, 1.0)
            for i = 0, GetVehicleNumberOfWheels(veh) - 1 do
                SetVehicleWheelBrakePressure(veh, i, 0.0)
            end
            goto continue
        end

        -- slip beyond threshold: intervene
        local severity = math.min(absSlip / maxSlip, 1.0)
        -- weight brake vs torque by speed
        local brakeW = math.min(math.max((speed - lowSpeed) / (highSpeed - lowSpeed), 0.0), 1.0)
        local torqueW = 1.0 - brakeW
        -- apply torque reduction
        local torqueMul = 1.0 - (severity * torqueW * maxTorqueCut)
        SetVehicleEngineTorqueMultiplier(veh, torqueMul)

        -- choose wheel to brake
        local steer = GetVehicleSteeringAngle(veh)
        local w
        if steer > 0.1 or (math.abs(steer) < 0.1 and slipAng > 0) then
            w = (slipAng > 0) and 3 or 0
        else
            w = (slipAng > 0) and 1 or 2
        end

        -- brake pressure
        local targetBrake = severity * brakeW
        if PulseBrakeEnabled then
            local period = (1.0 - severity) * 600 + 200
            local t = GetGameTimer() % period
            if t < period / 2 then
                SetVehicleWheelBrakePressure(veh, w, targetBrake)
            else
                SetVehicleWheelBrakePressure(veh, w, 0.0)
            end
        else
            SetVehicleWheelBrakePressure(veh, w, targetBrake)
        end

        -- show UI
        ShowESPUI(true)

        ::continue::
    end
end)
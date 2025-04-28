-- Hyper-Aggressive TCS v2.1 (Fixed for FiveM natives)
-- Torque + power + optional wheel brake (removed unsupported traction curve calls)

-- NUI UI toggle (define up top!)
local displayTCS = false
function ShowTCSUI(show)
    displayTCS = show
    -- debug -- print to verify UI calls
    -- print(("[NUI] TCS → %s"):format(show and "ON" or "OFF"))
    SendNUIMessage({ type = "tcs", status = show })
end

local isTCSActive  = false
local isTCSEnabled = true

-- TCS parameters
local slipThreshold   = 0.05    -- 5% slip
local slipCutoff      = 0.20    -- max intensity at 20%
local minTorqueMult   = 0.00    -- allow 0% torque
local minPowerPercent = 0       -- allow 0% engine power

-- Toggle command
RegisterCommand('tsc', function()
    isTCSEnabled = not isTCSEnabled
    if not isTCSEnabled then
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped) then
            local veh = GetVehiclePedIsIn(ped, false)
            SetVehicleEngineTorqueMultiplier(veh, 1.0)
            SetVehicleEnginePowerMultiplier(veh, 100.0)
        end
        isTCSActive = false
        ShowTCSUI(false)
    end
    ---- print(("TCS %s"):format(isTCSEnabled and "ENABLED" or "DISABLED"))
end, false)

-- Main loop
CreateThread(function()
    while true do
        Wait(0)
        if not isTCSEnabled then goto cont end

        local ped = PlayerPedId()
        if not (IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped) then
            if displayTCS then ShowTCSUI(false) end
            isTCSActive = false
            goto cont
        end

        local veh   = GetVehiclePedIsIn(ped, false)
        local speed = GetEntitySpeed(veh) * 3.6  -- km/h

        -- avg wheel speed & slip
        local totalWS = 0.0
        for i=0,3 do totalWS = totalWS + GetVehicleWheelSpeed(veh, i) end
        local avgWS = (totalWS / 4) * 3.6
        local slip  = (avgWS - speed) / math.max(speed, 1.0)

        if slip > slipThreshold then
            if not isTCSActive then
                isTCSActive = true
                ShowTCSUI(true)
            end

            -- scale intensity
            local intensity  = math.min(1, (slip - slipThreshold) / (slipCutoff - slipThreshold))
            local torqueMult = math.max(minTorqueMult, 1 - intensity)
            local powerMult  = math.max(minPowerPercent, (1 - intensity) * 100)

            SetVehicleEngineTorqueMultiplier(veh, torqueMult)
            SetVehicleEnginePowerMultiplier(veh, powerMult)

            -- emergency brake on extreme spin
            for i=0,3 do
                local ws = GetVehicleWheelSpeed(veh, i) * 3.6
                if (ws - speed) / math.max(speed,1.0) > slipCutoff then
                    SetVehicleBrake(veh, true)
                    break
                end
            end
        else
            if isTCSActive then
                isTCSActive = false
                SetVehicleEngineTorqueMultiplier(veh, 1.0)
                SetVehicleEnginePowerMultiplier(veh, 100.0)
                ShowTCSUI(false)
            end
        end

        ::cont::
    end
end)
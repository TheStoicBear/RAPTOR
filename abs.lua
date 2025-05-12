-- ABS v3.0 — Per-Wheel Pulsing & Rear-Bias
local ABSSystemEnabled    = true      -- overall on/off switch
local isABSActive         = false
local pulseInterval       = 50        -- ms between on/off pulses (~20 Hz)
local nextToggle          = 0
local lockThreshold       = 0.15      -- slip ratio threshold
local brakeInputThreshold = 0.5       -- when brake is “hard”
local rearPressureRatio   = 0.7       -- rear wheels get 70% of front pressure
local debug               = false

local function debugPrint(msg)
    if debug then
        print(("[ABS] %s"):format(msg))
    end
end

-- Register /toggleABS command
RegisterCommand('toggleABS', function()
    ABSSystemEnabled = not ABSSystemEnabled
    print(('ABS System %s'):format(ABSSystemEnabled and 'ENABLED' or 'DISABLED'))

    -- If disabling mid‐drive, restore full brake pressure & UI
    if not ABSSystemEnabled and isABSActive then
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        for w = 0, GetVehicleNumberOfWheels(veh)-1 do
            SetVehicleWheelBrakePressure(veh, w, 1.0)
        end
        SendNUIMessage({ type = "abs", status = false })
        isABSActive = false
    end
end, false)

CreateThread(function()
    while true do
        Wait(0)  -- continuous loop

        if not ABSSystemEnabled then
            -- ABS is globally off → do nothing
            goto cont
        end

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            if isABSActive then
                -- restore full pressure on exit
                local veh = GetVehiclePedIsIn(ped, false)
                for w = 0, GetVehicleNumberOfWheels(veh)-1 do
                    SetVehicleWheelBrakePressure(veh, w, 1.0)
                end
                SendNUIMessage({ type = "abs", status = false })
                isABSActive = false
            end
            goto cont
        end

        local veh = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(veh, -1) ~= ped then goto cont end

        local speed = GetEntitySpeed(veh) * 3.6
        if speed < 5 then goto cont end  -- too slow for ABS

        local brakeInput = GetControlNormal(0, 72)
        local ebrakeInput = IsControlPressed(0, 44)

        -- compute slip
        local totalWS = 0.0
        for i = 0, 3 do totalWS = totalWS + GetVehicleWheelSpeed(veh, i) end
        local avgWS = (totalWS / 4) * 3.6
        local slip = (speed - avgWS) / math.max(speed, 1.0)

        debugPrint(("Speed: %.1f km/h | Slip: %.3f"):format(speed, slip))

        if (brakeInput >= brakeInputThreshold or ebrakeInput) and slip > lockThreshold then
            -- engage ABS
            if not isABSActive then
                isABSActive = true
                nextToggle = GetGameTimer()
                SendNUIMessage({ type = "abs", status = true })
                debugPrint(">> ABS ENGAGED")
            end

            -- pulse on/off each interval
            local now = GetGameTimer()
            if now >= nextToggle then
                local brakeOn = ((now // pulseInterval) % 2) == 0
                for w = 0, GetVehicleNumberOfWheels(veh)-1 do
                    local target = brakeOn and 1.0 or 0.0
                    if w >= 2 then
                        target = brakeOn and rearPressureRatio or 0.0
                    end
                    SetVehicleWheelBrakePressure(veh, w, target)
                end
                nextToggle = now + pulseInterval
                debugPrint(("Brake %s"):format(brakeOn and "APPLY" or "RELEASE"))
            end
        else
            -- disengage ABS
            if isABSActive then
                isABSActive = false
                for w = 0, GetVehicleNumberOfWheels(veh)-1 do
                    SetVehicleWheelBrakePressure(veh, w, 1.0)
                end
                SendNUIMessage({ type = "abs", status = false })
                debugPrint("<< ABS DISENGAGED")
            end
        end

        ::cont::
    end
end)

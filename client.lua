-- police_missions/client.lua
local QBCore = exports['qb-core']:GetCoreObject()
local missionPeds = {}
local missionVehicle = nil
local missionBlip = nil

-- Safe model request function
local function RequestModelSync(model)
    local modelHash = type(model) == 'string' and GetHashKey(model) or model
    
    if not IsModelValid(modelHash) then
        print("^1ERROR: Model is not valid: " .. tostring(model) .. "^0")
        return false
    end
    
    RequestModel(modelHash)
    
    local timeout = 5000
    local startTime = GetGameTimer()
    
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() - startTime > timeout then
            print("^1ERROR: Timeout loading model: " .. tostring(model) .. "^0")
            return false
        end
        Wait(10)
    end
    
    return true
end

-- Function to spawn criminals
local function SpawnCriminals(criminals)
    local criminalModel = "g_m_y_ballaeast_01"
    
    if not RequestModelSync(criminalModel) then
        print("^1ERROR: Failed to load criminal model^0")
        return
    end

    for i, criminal in ipairs(criminals) do
        local ped = CreatePed(0, GetHashKey(criminalModel), criminal.coords.x, criminal.coords.y, criminal.coords.z, criminal.coords.w, true, true)
        if DoesEntityExist(ped) then
            missionPeds[#missionPeds + 1] = ped
            
            GiveWeaponToPed(ped, `WEAPON_ASSAULTRIFLE`, 999, false, true)
            SetPedAsEnemy(ped, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 46, true)
            SetPedCombatAbility(ped, 100)
            SetPedCombatMovement(ped, 2)
            SetPedCombatRange(ped, 2)
            SetPedKeepTask(ped, true)
            SetPedDropsWeaponsWhenDead(ped, false)
            
            -- Set ped as aggressive towards players
            SetPedRelationshipGroupHash(ped, `HATES_PLAYER`)
            SetPedAccuracy(ped, 60)
            SetPedSeeingRange(ped, 100.0)
            SetPedHearingRange(ped, 100.0)
        else
            print("^1ERROR: Failed to create criminal ped at index " .. i .. "^0")
        end
    end
    
    SetModelAsNoLongerNeeded(GetHashKey(criminalModel))
end

-- Function to spawn hostages
local function SpawnHostages(hostages)
    local hostageModel = "a_f_y_business_01"
    
    if not RequestModelSync(hostageModel) then
        print("^1ERROR: Failed to load hostage model^0")
        return
    end

    for i, hostage in ipairs(hostages) do
        local ped = CreatePed(0, GetHashKey(hostageModel), hostage.coords.x, hostage.coords.y, hostage.coords.z, hostage.coords.w, true, true)
        if DoesEntityExist(ped) then
            missionPeds[#missionPeds + 1] = ped
            
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 46, true)
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_BUM_STANDING", 0, true)
            
            -- Add qb-target option to free hostage
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        type = "client",
                        event = "police_missions:freeHostage",
                        icon = "fas fa-user-check",
                        label = "Free Hostage",
                        ped = ped
                    }
                },
                distance = 2.5
            })
        else
            print("^1ERROR: Failed to create hostage ped at index " .. i .. "^0")
        end
    end
    
    SetModelAsNoLongerNeeded(GetHashKey(hostageModel))
end

-- Function to spawn vehicle for weapon deal
local function SpawnMissionVehicle(vehicleData)
    if not RequestModelSync(vehicleData.model) then
        print("^1ERROR: Failed to load vehicle model: " .. vehicleData.model .. "^0")
        return
    end

    local vehicle = CreateVehicle(GetHashKey(vehicleData.model), vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z, vehicleData.coords.w, true, true)
    if DoesEntityExist(vehicle) then
        missionVehicle = vehicle
        
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleDoorsLocked(vehicle, 1) -- Lock vehicle but can be broken into
        
        -- Add qb-target option to deliver vehicle
        exports['qb-target']:AddTargetEntity(vehicle, {
            options = {
                {
                    type = "client",
                    event = "police_missions:deliverVehicle",
                    icon = "fas fa-car",
                    label = "Deliver Car",
                    vehicle = vehicle
                }
            },
            distance = 4.0
        })
    else
        print("^1ERROR: Failed to create mission vehicle^0")
    end
    
    SetModelAsNoLongerNeeded(GetHashKey(vehicleData.model))
end

-- Function to create mission blip
local function CreateMissionBlip(coords, missionName)
    missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(missionBlip, 161)
    SetBlipDisplay(missionBlip, 4)
    SetBlipScale(missionBlip, 1.0)
    SetBlipColour(missionBlip, 1)
    SetBlipAsShortRange(missionBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(missionName)
    EndTextCommandSetBlipName(missionBlip)
end

-- Client event for starting mission
RegisterNetEvent('police_missions:startMission', function(mission)
    -- Cleanup any existing mission first
    CleanupClientMission()
    
    -- Spawn mission elements
    SpawnCriminals(mission.criminals)
    
    if mission.type == "hostage" and mission.hostages then
        SpawnHostages(mission.hostages)
    elseif mission.type == "vehicle" and mission.vehicle then
        SpawnMissionVehicle(mission.vehicle)
    end
    
    -- Create blip
    CreateMissionBlip(mission.blipCoords, mission.name)
end)

-- Client event for cleaning up mission
RegisterNetEvent('police_missions:cleanupMission', function()
    CleanupClientMission()
end)

-- Function to cleanup client mission elements
function CleanupClientMission()
    -- Remove peds
    for _, ped in ipairs(missionPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    missionPeds = {}
    
    -- Remove vehicle
    if missionVehicle and DoesEntityExist(missionVehicle) then
        DeleteEntity(missionVehicle)
        missionVehicle = nil
    end
    
    -- Remove blip
    if missionBlip then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
    
    -- Remove target options
    -- These are automatically cleaned up when entities are deleted
end

-- Client event for freeing hostages
RegisterNetEvent('police_missions:freeHostage', function(data)
    local ped = data.ped
    if ped and DoesEntityExist(ped) then
        -- Play animation
        local playerPed = PlayerPedId()
        
        QBCore.Functions.Progressbar("free_hostage", "Freeing Hostage...", 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = "amb@code_human_police_investigate@idle_b",
            anim = "idle_f",
            flags = 16,
        }, {}, {}, function()
            -- Success
            ClearPedTasks(playerPed)
            
            -- Remove from qb-target
            exports['qb-target']:RemoveTargetEntity(ped, "Free Hostage")
            
            -- Delete the hostage ped
            DeleteEntity(ped)
            
            -- Notify server
            TriggerServerEvent('police_missions:hostageFreed')
            
            -- Notify player
            QBCore.Functions.Notify("Hostage freed!", "success", 3000)
        end, function()
            -- Cancel
            ClearPedTasks(playerPed)
            QBCore.Functions.Notify("Cancelled", "error")
        end)
    end
end)

-- Client event for delivering vehicle
RegisterNetEvent('police_missions:deliverVehicle', function(data)
    local vehicle = data.vehicle
    if vehicle and DoesEntityExist(vehicle) then
        -- Check if player is in the vehicle
        local playerPed = PlayerPedId()
            -- Play animation or show progress bar
            QBCore.Functions.Progressbar("deliver_vehicle", "Delivering Vehicle...", 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                -- Success
                
                -- Remove from qb-target
                exports['qb-target']:RemoveTargetEntity(vehicle, "Deliver Car")
                
                -- Delete the vehicle
                DeleteEntity(vehicle)
                missionVehicle = nil
                
                -- Notify server
                TriggerServerEvent('police_missions:vehicleDelivered')
                
                -- Notify player
                QBCore.Functions.Notify("Vehicle delivered! Mission completed.", "success", 5000)
            end, function()
                -- Cancel
                QBCore.Functions.Notify("Cancelled", "error")
            end)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupClientMission()
    end
end)
-- police_missions/server.lua

local QBCore = exports['qb-core']:GetCoreObject()
local missionActive = false
local currentMission = nil
local spawnedPeds = {}
local spawnedVehicle = nil
local missionBlip = nil

-- Mission configurations
local Missions = {
    [1] = {
        name = "Fleeca Robbery",
        notification = "Fleeca robbery in progress! Criminals are armed!",
        criminals = {
            {coords = vector4(-350.6895, -50.0491, 49.0426, 341.2437)},
            {coords = vector4(-352.0112, -48.3465, 49.0365, 38.6638)},
            {coords = vector4(-353.4995, -47.0878, 49.0364, 331.6519)}
        },
        hostages = {
            {coords = vector4(-354.1242, -54.1249, 49.0462, 48.1943)}
        },
        blipCoords = vector3(-352.0, -49.0, 49.0),
        type = "hostage"
    },
    [2] = {
        name = "Stab City Raid",
        notification = "Criminals raided Stab City! They are armed and holding hostages!",
        criminals = {
            {coords = vector4(93.0714, 3751.0552, 40.7701, 356.2523)},
            {coords = vector4(91.1320, 3748.0420, 40.7719, 145.9915)},
            {coords = vector4(92.4878, 3751.6948, 40.7718, 316.5842)},
            {coords = vector4(95.7390, 3750.1470, 40.7188, 249.8533)}
        },
        hostages = {
            {coords = vector4(93.5865, 3756.7273, 40.7678, 339.0158)},
            {coords = vector4(92.3308, 3757.0042, 40.7756, 36.9995)}
        },
        blipCoords = vector3(93.0, 3752.0, 40.8),
        type = "hostage"
    },
    [3] = {
        name = "Weapon Deal",
        notification = "Large weapons deal in progress! Be careful, they are armed!",
        criminals = {
            {coords = vector4(1358.0787, 1158.6515, 113.7591, 71.9047)},
            {coords = vector4(1353.3730, 1154.2235, 113.7591, 119.0101)},
            {coords = vector4(1350.1516, 1145.0775, 113.7591, 160.3036)},
            {coords = vector4(1355.7471, 1139.8579, 113.7592, 225.7852)},
            {coords = vector4(1362.8441, 1138.0472, 113.7604, 266.8267)},
            {coords = vector4(1371.4464, 1125.3567, 114.0629, 83.0152)},
            {coords = vector4(1368.5330, 1122.1759, 114.0201, 123.5485)}
        },
        vehicle = {
            coords = vector4(1368.4858, 1136.6797, 113.7590, 226.3585),
            model = "baller"
        },
        blipCoords = vector3(1360.0, 1145.0, 113.8),
        type = "vehicle"
    },
    [4] = {
        name = "Paleto Bank Robbery",
        notification = "Paleto Bank robbery in progress! Criminals are armed!",
        criminals = {
            {coords = vector4(-109.8664, 6464.0762, 31.6267, 138.9248)},
            {coords = vector4(-111.7962, 6467.3818, 31.6267, 28.1071)},
            {coords = vector4(-102.7433, 6464.6084, 31.6267, 55.4623)},
            {coords = vector4(-103.9592, 6467.6538, 31.6267, 115.8512)},
            {coords = vector4(-106.0124, 6470.9902, 31.6267, 133.8457)},
            {coords = vector4(-127.4429, 6445.8789, 31.5368, 136.4698)},
            {coords = vector4(-140.1156, 6449.5327, 31.5289, 95.9283)}
        },
        hostages = {
            {coords = vector4(-111.7656, 6470.6675, 31.6267, 98.5626)}
        },
        blipCoords = vector3(-111.7656, 6470.6675, 31.6267),
        type = "hostage"
    },
    [5] = {
        name = "Prison Break",
        notification = "Criminals are breaking into the prison ! Criminals are armed!",
        criminals = {
            {coords = vector4(1660.9725, 2522.8569, 45.5649, 155.0232)},
            {coords = vector4(1654.1990, 2518.0718, 45.5649, 113.5398)},
            {coords = vector4(1646.1973, 2512.8208, 45.5649, 130.6795)},
            {coords = vector4(1639.9452, 2508.3704, 45.5649, 102.9471)},
            {coords = vector4(1645.2166, 2504.4958, 45.5649, 246.7646)},
            {coords = vector4(1655.4430, 2505.1948, 45.5649, 281.0957)},
            {coords = vector4(1664.7714, 2506.1724, 45.5650, 271.4703)}
        },
        hostages = {
            {coords = vector4(1680.4353, 2510.1609, 45.5649, 288.7578)}
        },
        blipCoords = vector3(1680.4353, 2510.1609, 45.5649),
        type = "hostage"
    }
}

-- Function to count on-duty police officers
local function GetOnDutyPoliceCount()
    local count = 0
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end

-- Function to start a specific mission
local function StartSpecificMission(missionId)
    if missionActive then 
        return false, "A mission is already active!"
    end
    
    local mission = Missions[missionId]
    if not mission then 
        return false, "Invalid mission ID!"
    end
    
    missionActive = true
    currentMission = mission
    
    -- Notify police and trigger client-side spawning
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
            TriggerClientEvent('QBCore:Notify', player.PlayerData.source, mission.notification, 'error', 10000)
            TriggerClientEvent('police_missions:startMission', player.PlayerData.source, mission)
        end
    end
    
    print(string.format("^2Police Mission Started: %s^0", mission.name))
    return true, string.format("Started mission: %s", mission.name)
end

-- Function to start a random mission
local function StartRandomMission()
    if missionActive then 
        return false, "A mission is already active!"
    end
    
    local policeCount = GetOnDutyPoliceCount()
    if policeCount < 1 then
        return false, "Not enough police officers on duty (minimum 2 required)"
    end
    
    local randomMission = math.random(1, #Missions)
    return StartSpecificMission(randomMission)
end

-- Function to cleanup mission
local function CleanupMission()
    -- Trigger cleanup on all clients
    TriggerClientEvent('police_missions:cleanupMission', -1)
    
    missionActive = false
    currentMission = nil
    
    print("^2Police Mission Cleaned Up^0")
end

-- Function to complete mission
local function CompleteMission()
    -- Notify police of completion
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
            TriggerClientEvent('QBCore:Notify', player.PlayerData.source, "Mission completed! Good work officer.", 'success', 5000)
        end
    end
    
    print("^2Police Mission Completed^0")
    CleanupMission()
end

-- Server event for hostage freed
RegisterNetEvent('police_missions:hostageFreed', function()
    if missionActive and currentMission and currentMission.type == "hostage" then
        -- For now, complete mission when any hostage is freed
        -- You can modify this to track individual hostages
        CompleteMission()
    end
end)

-- Server event for vehicle delivered
RegisterNetEvent('police_missions:vehicleDelivered', function()
    if missionActive and currentMission and currentMission.type == "vehicle" then
        CompleteMission()
    end
end)

-- Main mission check loop
Citizen.CreateThread(function()
    while true do
        Wait(60 * 60 * 1000) -- Wait 30 minutes
        
        if not missionActive then
            local policeCount = GetOnDutyPoliceCount()
            if policeCount >= 2 then
                StartRandomMission()
            else
                print("^3Not enough police officers on duty for mission. Required: 2, Current: " .. policeCount .. "^0")
            end
        else
            print("^3Mission already active, skipping new mission generation^0")
        end
    end
end)

-- Command to start a random mission
QBCore.Commands.Add("startmission", "Start a random police mission", {}, false, function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
        local success, message = StartRandomMission()
        if success then
            TriggerClientEvent('QBCore:Notify', src, message, 'success', 5000)
        else
            TriggerClientEvent('QBCore:Notify', src, message, 'error', 5000)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You must be on duty as police to use this command.", 'error', 5000)
    end
end, "user")

-- Command to start a specific mission
QBCore.Commands.Add("startmissionid", "Start a specific police mission by ID (1-3)", {
    {name = "id", help = "Mission ID (1-3)"}
}, false, function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
        local missionId = tonumber(args[1])
        if missionId and missionId >= 1 and missionId <= 3 then
            local success, message = StartSpecificMission(missionId)
            if success then
                TriggerClientEvent('QBCore:Notify', src, message, 'success', 5000)
            else
                TriggerClientEvent('QBCore:Notify', src, message, 'error', 5000)
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "Invalid mission ID! Use 1, 2, or 3.", 'error', 5000)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You must be on duty as police to use this command.", 'error', 5000)
    end
end, "user")

-- Command to list available missions
QBCore.Commands.Add("listmissions", "List all available police missions", {}, false, function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if player.PlayerData.job.name == "police" then
        local missionList = "Available Missions:\n"
        for id, mission in pairs(Missions) do
            missionList = missionList .. string.format("%d. %s - %s\n", id, mission.name, mission.type)
        end
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 255, 0},
            multiline = true,
            args = {"Mission System", missionList}
        })
    else
        TriggerClientEvent('QBCore:Notify', src, "You must be police to use this command.", 'error', 5000)
    end
end, "user")

-- Admin command to force start any mission
QBCore.Commands.Add("adminstartmission", "Admin: Start any police mission", {
    {name = "id", help = "Mission ID (1-3) or 'random'"}
}, true, function(source, args)
    local src = source
    
    if not args[1] then
        TriggerClientEvent('QBCore:Notify', src, "Usage: /adminstartmission [id] or /adminstartmission random", 'error', 5000)
        return
    end
    
    if args[1]:lower() == "random" then
        local success, message = StartRandomMission()
        if success then
            TriggerClientEvent('QBCore:Notify', src, "Admin: " .. message, 'success', 5000)
        else
            TriggerClientEvent('QBCore:Notify', src, "Admin: " .. message, 'error', 5000)
        end
    else
        local missionId = tonumber(args[1])
        if missionId and missionId >= 1 and missionId <= 5 then
            local success, message = StartSpecificMission(missionId)
            if success then
                TriggerClientEvent('QBCore:Notify', src, "Admin: " .. message, 'success', 5000)
            else
                TriggerClientEvent('QBCore:Notify', src, "Admin: " .. message, 'error', 5000)
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "Invalid mission ID! Use 1, 2, 3, or 'random'.", 'error', 5000)
        end
    end
end, "admin")

-- Emergency cleanup command
QBCore.Commands.Add("clearmission", "Clear active police mission", {}, false, function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if player.PlayerData.job.name == "police" or QBCore.Functions.HasPermission(src, "admin") then
        CleanupMission()
        TriggerClientEvent('QBCore:Notify', src, "Mission cleared.", 'success', 3000)
    else
        TriggerClientEvent('QBCore:Notify', src, "No permission.", 'error', 3000)
    end
end, "admin")

-- Command to check mission status
QBCore.Commands.Add("missionstatus", "Check current mission status", {}, false, function(source, args)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if player.PlayerData.job.name == "police" then
        if missionActive and currentMission then
            TriggerClientEvent('QBCore:Notify', src, string.format("Active Mission: %s (%s)", currentMission.name, currentMission.type), 'primary', 5000)
        else
            TriggerClientEvent('QBCore:Notify', src, "No active missions.", 'inform', 5000)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You must be police to use this command.", 'error', 5000)
    end
end, "user")
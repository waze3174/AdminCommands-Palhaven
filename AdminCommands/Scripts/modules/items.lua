local utils = require("libs/utils")
local logger = require("libs/logger")
local itemdata = require("enums/itemdata")
local commands = {}

local function isServerSide()
    local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    return palUtility and palUtility:IsValid() and palUtility:IsDedicatedServer(palUtility)
end

function commands.spawnItem(playerState, item)
    if not playerState or not playerState:IsValid() then return false, "Invalid player state" end
    if not item or item == "" then return false, "No item specified" end

    local quantity = 1
    if string.find(item, ":") then
        item, quantity = string.match(item, "(.*):(.*)")
        quantity = tonumber(quantity) or 1
    end

    if not itemdata[item] then
        return false, "Item '" .. item .. "' not found"
    end

    local inventory = playerState:GetInventoryData()
    if not inventory then return false, "Could not get inventory" end

    if isServerSide() then
        inventory:AddItem_ServerInternal(FName(item), quantity, false, 0.0, true)
    else
        inventory:RequestAddItem(FName(item), quantity, false)
    end
    return true, itemdata[item], quantity
end

function commands.handleGive(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !give <name> item:amount item2:amount")
        return
    end

    local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    local world = FindFirstOf("World")
    local playerList = palUtility:GetPlayerListDisplayMessages(world)
    local targetController = nil
    local targetName = nil
    local remaining = nil

    if playerList then
        for i = 1, #playerList do
            local info = playerList[i]:get():ToString()
            local name = info:match("^(.-),")
            if name and rest:sub(1, #name) == name and rest:sub(#name + 1, #name + 1) == " " then
                targetName = name
                remaining = rest:sub(#name + 2)
                local playerChar = palUtility:GetPlayerCharacterByPlayerIndex(world, i - 1)
                if playerChar and playerChar:IsValid() then
                    targetController = playerChar:GetPalPlayerController()
                end
                break
            end
        end
    end

    if (not targetController or not remaining) and rest:find("%S+:%d+") then
        targetController = pc
        targetName = "you"
        remaining = rest
    end

    if not targetController or not remaining then
        utils.sendPersonalAnnounce(pc, "Player not found.")
        return
    end

    local targetState = targetController.PlayerState
    for item in remaining:gmatch("%S+") do
        local success, itemName, qty = commands.spawnItem(targetState, item)
        if success then
            utils.sendPersonalAnnounce(pc, string.format("Gave %d x %s to %s", qty, itemName, targetName))
        else
            utils.sendPersonalAnnounce(pc, itemName)
        end
    end
end

function commands.handlePersonalGive(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !give item:amount item2:amount")
        return
    end

    for item in rest:gmatch("%S+") do
        local success, itemName, qty = commands.spawnItem(state, item)
        if success then
            utils.sendPersonalAnnounce(pc, string.format("Spawned %d x %s", qty, itemName))
        else
            utils.sendPersonalAnnounce(pc, itemName)
        end
    end
end

return commands

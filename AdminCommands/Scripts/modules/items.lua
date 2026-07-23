local utils = require("libs/utils")
local logger = require("libs/logger")
local itemdata = require("enums/itemdata")
local commands = {}

local function isServerSide()
    local palUtility = utils.getPalUtilities()
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

    local palUtility = utils.getPalUtilities()
    local world = FindFirstOf("World")
    if not palUtility or not palUtility:IsValid() or not world or not world:IsValid() then
        utils.sendPersonalAnnounce(pc, "PalUtility not ready yet.")
        return
    end
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

function commands.giveExperience(playerState, quantity)
    if not playerState or not playerState:IsValid() then return end
    if not quantity or quantity <= 0 then return end

    local PlayerController = playerState:GetPlayerController()
    if not PlayerController or not PlayerController:IsValid() then return end

    local PlayerCharacter = PlayerController.Pawn
    if not PlayerCharacter or not PlayerCharacter:IsValid() then return end

    local WorldContext = PlayerCharacter:GetWorld()
    if not WorldContext or not WorldContext:IsValid() then return end

    local Location = PlayerCharacter:K2_GetActorLocation()
    if not Location then return end

    local ExpRadius = 1000.0

    local PalUtility = utils.getPalUtilities()
    if not PalUtility or not PalUtility:IsValid() then return end

    PalUtility:GiveExpToAroundPlayerCharacter(WorldContext, Location, ExpRadius, quantity, true)
end

function commands.handleExpCommand(state, rest)
    local pc = state:GetPlayerController()
    if not pc or not pc:IsValid() then return end

    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !exp <name> <amount>")
        return
    end

    local palUtility = utils.getPalUtilities()
    local world = FindFirstOf("World")
    if not palUtility or not palUtility:IsValid() or not world or not world:IsValid() then return end

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

    if not targetController or not remaining then
        utils.sendPersonalAnnounce(pc, "Player not found.")
        return
    end

    local amount = tonumber(remaining)
    if not amount then
        utils.sendPersonalAnnounce(pc, "Invalid amount.")
        return
    end

    local targetState = targetController.PlayerState
    if not targetState or not targetState:IsValid() then return end

    commands.giveExperience(targetState, amount)
    utils.sendPersonalAnnounce(pc, string.format("Granted %d EXP to %s", amount, targetName))
end

function commands.handlePersonalExp(state, rest)
    local pc = state:GetPlayerController()
    local amount = tonumber(rest)
    if not amount then
        utils.sendPersonalAnnounce(pc, "Usage: !giveexp <amount>")
        return
    end
    commands.giveExperience(state, amount)
    utils.sendPersonalAnnounce(pc, string.format("Granted %d EXP to your party.", amount))
end

return commands

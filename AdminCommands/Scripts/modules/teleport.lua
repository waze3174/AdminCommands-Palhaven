local utils = require("libs/utils")
local logger = require("libs/logger")
local commands = {}

function commands.handleGoto(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !goto <x> <y> <z> or !goto <player>")
        return
    end

    local x, y, z = rest:match("^([%-%.%d]+)[,%s]+([%-%.%d]+)[,%s]+([%-%.%d]+)$")
    if x then
        local char = pc.Pawn
        if not (char and char:IsValid()) then
            utils.sendPersonalAnnounce(pc, "Could not find your character.")
            return
        end

        local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
        if palUtility and palUtility:IsValid() then
            local vec = {X = tonumber(x), Y = tonumber(y), Z = tonumber(z) + 500}
            local quat = {X = 0, Y = 0, Z = 0, W = 0}
            palUtility:TeleportAroundLoccation(char, vec, quat)
            
            local playerName = utils.GetPlayerName(state)
            local playerUID = utils.GetPlayerId(state)
            logger.logTeleport(playerName, playerUID, string.format("%.0f, %.0f, %.0f", tonumber(x), tonumber(y), tonumber(z)))
            
            utils.sendPersonalAnnounce(pc, "Teleported.")
        end
        return
    end

    local targetName = rest:match("^%s*(.-)%s*$")
    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local name = utils.GetPlayerName(targetState)
            if name:lower() == targetName:lower() then
                local targetPC = targetState:GetPlayerController()
                local targetChar = targetPC and targetPC.Pawn
                local char = pc.Pawn
                
                if targetChar and targetChar:IsValid() and char and char:IsValid() then
                    local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
                    if palUtility and palUtility:IsValid() then
                        local loc = {X = 0, Y = 0, Z = 0}
                        local ok = palUtility:TryGetHeadWorldPosition(targetChar, loc)
                        if ok then
                            loc.Z = loc.Z + 500
                            local quat = {X = 0, Y = 0, Z = 0, W = 0}
                            palUtility:TeleportAroundLoccation(char, loc, quat)
                            
                            local playerName = utils.GetPlayerName(state)
                            local playerUID = utils.GetPlayerId(state)
                            logger.logTeleport(playerName, playerUID, "Player: " .. name)
                            
                            utils.sendPersonalAnnounce(pc, "Teleported to " .. name)
                        end
                    end
                end
                return
            end
        end
    end

    utils.sendPersonalAnnounce(pc, "Player not found.")
end

function commands.handleGetPos(state)
    local pc = state:GetPlayerController()
    local char = pc.Pawn
    if not (char and char:IsValid()) then
        utils.sendPersonalAnnounce(pc, "Could not find your character.")
        return
    end
    
    local loc = char:K2_GetActorLocation()
    local msg = string.format("Your position: %.0f, %.0f, %.0f", loc.X, loc.Y, loc.Z)
    utils.sendPersonalAnnounce(pc, msg)
end

function commands.handlePlayerGetPos(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !getpos <PlayerName>")
        return
    end
    
    local targetName = rest:match("^%s*(.-)%s*$")
    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local name = utils.GetPlayerName(targetState)
            if name:lower() == targetName:lower() then
                local targetPC = targetState:GetPlayerController()
                local targetChar = targetPC and targetPC.Pawn
                
                if targetChar and targetChar:IsValid() then
                    local loc = targetChar:K2_GetActorLocation()
                    local msg = string.format("%s's position: %.0f, %.0f, %.0f", name, loc.X, loc.Y, loc.Z)
                    utils.sendPersonalAnnounce(pc, msg)
                end
                return
            end
        end
    end
    
    utils.sendPersonalAnnounce(pc, "Player not found.")
end

function commands.handleBring(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !bring <player>")
        return
    end

    local targetName = rest:match("^%s*(.-)%s*$")
    local adminChar = pc.Pawn
    if not (adminChar and adminChar:IsValid()) then
        utils.sendPersonalAnnounce(pc, "Could not find your character.")
        return
    end

    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local name = utils.GetPlayerName(targetState)
            if name:lower() == targetName:lower() then
                local targetPC = targetState:GetPlayerController()
                local targetChar = targetPC and targetPC.Pawn
                
                if targetChar and targetChar:IsValid() then
                    local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
                    if palUtility and palUtility:IsValid() then
                        local loc = {X = 0, Y = 0, Z = 0}
                        local ok = palUtility:TryGetHeadWorldPosition(adminChar, loc)
                        if ok then
                            loc.Z = loc.Z + 500
                            local quat = {X = 0, Y = 0, Z = 0, W = 0}
                            palUtility:TeleportAroundLoccation(targetChar, loc, quat)
                            utils.sendPersonalAnnounce(pc, "Brought " .. name .. " to you.")
                            utils.sendPersonalAnnounce(targetPC, "You have been brought to " .. utils.GetPlayerName(state))
                        end
                    end
                end
                return
            end
        end
    end

    utils.sendPersonalAnnounce(pc, "Player not found.")
end

function commands.handleBringAll(state, rest)
    local pc = state:GetPlayerController()
    local adminChar = pc.Pawn
    if not (adminChar and adminChar:IsValid()) then
        utils.sendPersonalAnnounce(pc, "Could not find your character.")
        return
    end

    local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    if not palUtility or not palUtility:IsValid() then
        utils.sendPersonalAnnounce(pc, "PalUtility not ready yet.")
        return
    end

    local loc = {X = 0, Y = 0, Z = 0}
    local ok = palUtility:TryGetHeadWorldPosition(adminChar, loc)
    if not ok then
        utils.sendPersonalAnnounce(pc, "Unable to get your position.")
        return
    end
    loc.Z = loc.Z + 500
    local quat = {X = 0, Y = 0, Z = 0, W = 0}
    local count = 0

    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local targetPC = targetState:GetPlayerController()
            if targetPC and targetPC:IsValid() and targetPC ~= pc then
                local targetChar = targetPC.Pawn
                if targetChar and targetChar:IsValid() then
                    palUtility:TeleportAroundLoccation(targetChar, loc, quat)
                    count = count + 1
                end
            end
        end
    end

    utils.sendPersonalAnnounce(pc, "Brought " .. count .. " players to you.")
end

function commands.handleUnstuck(state)
    local pc = state:GetPlayerController()
    if pc and pc:IsValid() then
        pc:TeleportToSafePoint_ToServer(true)
        utils.sendPersonalAnnounce(pc, "You have been teleported to a safe point!")
    end
end

return commands

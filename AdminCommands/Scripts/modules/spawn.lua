-- The spawn and catch commands are extremely experimental and need work.
-- Feel free to make a pull request if you want to fix it up.

local utils = require("libs/utils")
local logger = require("libs/logger")
local commands = {}

function commands.handleSpawn(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !spawn <PalName> <level> [shiny]")
        return
    end

    local asset, level_str, shiny_str = rest:match("^(%S+)%s+(%d+)%s*(%S*)$")
    
    if not asset or not level_str then
        utils.sendPersonalAnnounce(pc, "Usage: !spawn <PalName> <level> [shiny]")
        return
    end

    local level = tonumber(level_str)
    if not level or level < 1 or level > 100 then
        utils.sendPersonalAnnounce(pc, "Level must be between 1 and 100")
        return
    end

    local shiny = shiny_str ~= "" and shiny_str:lower() == "true" or false

    local palUtil = utils.getPalUtilities()
    if not palUtil or not palUtil:IsValid() then
        utils.sendPersonalAnnounce(pc, "PalUtility not ready yet.")
        return
    end

    local playerChar = pc.Pawn
    if not (playerChar and playerChar:IsValid()) then
        utils.sendPersonalAnnounce(pc, "Could not find your character.")
        return
    end

    local npc_manager = palUtil:GetNPCManager(pc)
    if not npc_manager or not npc_manager:IsValid() then
        utils.sendPersonalAnnounce(pc, "NPC manager unavailable.")
        return
    end

    local controller_class = npc_manager.NPCAIControllerBaseClass
    if not controller_class or not controller_class:IsValid() then
        utils.sendPersonalAnnounce(pc, "AI controller class unavailable.")
        return
    end

    local location = playerChar:K2_GetActorLocation()
    local spawn_info = {
        ControllerClass = controller_class,
        CharacterID = FName(asset),
        Level = level,
        Location = { X = location.X + 300, Y = location.Y, Z = location.Z + 100 },
        Yaw = 0.0,
        Squad = nil,
    }

    local handle = npc_manager:SpawnNPCForServer(spawn_info, nil)
    if not handle or not handle:IsValid() then
        utils.sendPersonalAnnounce(pc, "Spawn failed.")
        return
    end

    ExecuteWithDelay(500, function()
        local parameter = handle:TryGetIndividualParameter()
        if parameter and parameter:IsValid() then
            if shiny then
                parameter.SaveParameter.IsRarePal = true
                parameter.SaveParameterMirror.IsRarePal = true
            end
            
            parameter:OnRep_SaveParameter()
            
            local actor = handle:TryGetIndividualActor()
            if actor and actor:IsValid() then
                local static_param = actor.StaticCharacterParameterComponent
                if static_param and static_param:IsValid() and shiny then
                    static_param:SetSpawnedCharacterType(1)
                end
                
                if shiny then
                    actor:SetActorScale3D({ X = 1.5, Y = 1.5, Z = 1.5 })
                    
                    local status = actor.StatusComponent
                    if status and status:IsValid() then
                        status:AddStatus(32)
                    end
                end
            end
        end
    end)

    local playerName = utils.GetPlayerName(state)
    local playerUID = utils.GetPlayerId(state)
    logger.logSpawn(playerName, playerUID, asset, level, shiny)

    local label = (shiny and "shiny " or "") .. asset
    utils.sendPersonalAnnounce(pc, string.format("Spawned %s (Lv %d).", label, level))
end

function commands.handleCatch(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !catch <PalName> <level> [shiny]")
        return
    end

    local asset, level_str, shiny_str = rest:match("^(%S+)%s+(%d+)%s*(%S*)$")
    
    if not asset or not level_str then
        utils.sendPersonalAnnounce(pc, "Usage: !catch <PalName> <level> [shiny]")
        return
    end

    local level = tonumber(level_str)
    if not level or level < 1 or level > 100 then
        utils.sendPersonalAnnounce(pc, "Level must be between 1 and 100")
        return
    end

    local shiny = shiny_str ~= "" and shiny_str:lower() == "true" or false

    local palUtil = utils.getPalUtilities()
    if not palUtil or not palUtil:IsValid() then
        utils.sendPersonalAnnounce(pc, "PalUtility not ready yet.")
        return
    end

    local playerChar = pc.Pawn
    if not (playerChar and playerChar:IsValid()) then
        utils.sendPersonalAnnounce(pc, "Could not find your character.")
        return
    end

    local npc_manager = palUtil:GetNPCManager(pc)
    if not npc_manager or not npc_manager:IsValid() then
        utils.sendPersonalAnnounce(pc, "NPC manager unavailable.")
        return
    end

    local controller_class = npc_manager.NPCAIControllerBaseClass
    if not controller_class or not controller_class:IsValid() then
        utils.sendPersonalAnnounce(pc, "AI controller class unavailable.")
        return
    end

    local location = playerChar:K2_GetActorLocation()
    local spawn_info = {
        ControllerClass = controller_class,
        CharacterID = FName(asset),
        Level = level,
        Location = { X = location.X + 300, Y = location.Y, Z = location.Z + 100 },
        Yaw = 0.0,
        Squad = nil,
    }

    local handle = npc_manager:SpawnNPCForServer(spawn_info, nil)
    if not handle or not handle:IsValid() then
        utils.sendPersonalAnnounce(pc, "Spawn failed.")
        return
    end

    ExecuteWithDelay(500, function()
        local parameter = handle:TryGetIndividualParameter()
        if parameter and parameter:IsValid() then
            parameter.bIsUncapturable = false
            parameter.bIsForceCapturable = true
            
            if shiny then
                parameter.SaveParameter.IsRarePal = true
                parameter.SaveParameterMirror.IsRarePal = true
            end
            
            parameter:OnRep_SaveParameter()
            
            local actor = handle:TryGetIndividualActor()
            if actor and actor:IsValid() then
                local static_param = actor.StaticCharacterParameterComponent
                if static_param and static_param:IsValid() then
                    static_param.IsUncapturable = false
                    if shiny then
                        static_param:SetSpawnedCharacterType(1)
                    end
                end
                
                if shiny then
                    actor:SetActorScale3D({ X = 1.5, Y = 1.5, Z = 1.5 })
                    
                    local status = actor.StatusComponent
                    if status and status:IsValid() then
                        status:AddStatus(32)
                    end
                end
            end
        end
    end)

    local captured = 0
    local attempts = 0
    local function try_capture()
        if captured >= 1 or attempts >= 30 then return end
        attempts = attempts + 1
        
        local spawned = handle:TryGetIndividualActor()
        if spawned and spawned:IsValid() then
            if palUtil and palUtil:IsValid() then
                palUtil:PalCaptureSuccess(playerChar, spawned)
                captured = 1
                return
            end
        end
        
        ExecuteWithDelay(100, try_capture)
    end
    ExecuteWithDelay(150, try_capture)

    local playerName = utils.GetPlayerName(state)
    local playerUID = utils.GetPlayerId(state)
    logger.logSpawn(playerName, playerUID, asset, level, shiny)

    local label = (shiny and "shiny " or "") .. asset
    utils.sendPersonalAnnounce(pc, string.format("Spawned %s (Lv %d) and captured.", label, level))
end

return commands

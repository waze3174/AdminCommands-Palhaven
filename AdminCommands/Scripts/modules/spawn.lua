-- The spawn and catch commands are extremely experimental and need work.
-- Feel free to make a pull request if you want to fix it up.

local utils = require("libs/utils")
local logger = require("libs/logger")
local commands = {}

local pendingShinyHandles = {}
local pendingShinyInits = 0

local function configureSpawnedPal(handle, shiny, attempt)
    if not handle or not handle:IsValid() then return end

    local parameter = handle:TryGetIndividualParameter()
    local actor = handle:TryGetIndividualActor()
    local param_ok = parameter and parameter:IsValid()
    local actor_ok = actor and actor:IsValid()

    if (not param_ok or not actor_ok) and attempt < 5 then
        ExecuteWithDelay(250, function()
            configureSpawnedPal(handle, shiny, attempt + 1)
        end)
        return
    end

    if param_ok then
        pcall(function()
            parameter.bIsUncapturable = false
            parameter.bIsForceCapturable = true
            if shiny then
                parameter.SaveParameter.IsRarePal = true
                parameter.SaveParameterMirror.IsRarePal = true

                local list_ok, passive_list = pcall(function() return parameter:GetPassiveSkillList() end)
                local has_rare = false
                if list_ok and type(passive_list) == "table" then
                    for _, passive_id in ipairs(passive_list) do
                        if tostring(passive_id) == "Rare" then has_rare = true end
                    end
                end
                if not has_rare then
                    pcall(function()
                        parameter:AddPassiveSkill(FName("Rare"), FName("None"))
                    end)
                end

                parameter:OnRep_SaveParameter()
            end
        end)
    end

    if actor_ok then
        pcall(function()
            local static_param = actor.StaticCharacterParameterComponent
            if static_param and static_param:IsValid() then
                static_param.IsUncapturable = false
                static_param:SetSpawnedCharacterType(shiny and 1 or 0)
            end

            if shiny then
                local base_scale = actor:GetActorScale3D()
                actor:SetActorScale3D({
                    X = base_scale.X * 1.5,
                    Y = base_scale.Y * 1.5,
                    Z = base_scale.Z * 1.5,
                })
                ExecuteWithDelay(1000, function()
                    if actor and actor:IsValid() then
                        actor:SetActorScale3D({ X = 1.5, Y = 1.5, Z = 1.5 })
                    end
                end)
                local status = actor.StatusComponent
                if status and status:IsValid() then
                    status:AddStatus(32)
                end
            end
        end)
    end
end

function commands.handleSpawn(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !spawn <PalName> <level> [shiny] [x,y,z]")
        return
    end

    local asset, level_str, shiny_str, coords_str = rest:match("^(%S+)%s+(%d+)%s*(%S*)%s*(.*)$")
    
    if not asset or not level_str then
        utils.sendPersonalAnnounce(pc, "Usage: !spawn <PalName> <level> [shiny] [x,y,z]")
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

    local spawnLocation
    if coords_str and coords_str ~= "" then
        local x, y, z = coords_str:match("^([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+)$")
        if x and y and z then
            spawnLocation = { X = tonumber(x), Y = tonumber(y), Z = tonumber(z) }
        else
            utils.sendPersonalAnnounce(pc, "Invalid coordinates. Use format: x,y,z")
            return
        end
    else
        local location = playerChar:K2_GetActorLocation()
        spawnLocation = { X = location.X + 300, Y = location.Y, Z = location.Z + 100 }
    end

    local spawn_info = {
        ControllerClass = controller_class,
        CharacterID = FName(asset),
        Level = level,
        Location = spawnLocation,
        Yaw = 0.0,
        Squad = nil,
    }

    if shiny then pendingShinyInits = pendingShinyInits + 1 end

    local handle = npc_manager:SpawnNPCForServer(spawn_info, nil)
    if not handle or not handle:IsValid() then
        utils.sendPersonalAnnounce(pc, "Spawn failed.")
        return
    end

    if shiny then
        table.insert(pendingShinyHandles, handle)
        ExecuteWithDelay(500, function() pendingShinyInits = 0 end)
    end

    ExecuteWithDelay(500, function()
        configureSpawnedPal(handle, shiny, 1)
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
        utils.sendPersonalAnnounce(pc, "Usage: !catch <PalName> <level> [shiny] [x,y,z]")
        return
    end

    local asset, level_str, shiny_str, coords_str = rest:match("^(%S+)%s+(%d+)%s*(%S*)%s*(.*)$")
    
    if not asset or not level_str then
        utils.sendPersonalAnnounce(pc, "Usage: !catch <PalName> <level> [shiny] [x,y,z]")
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

    local spawnLocation
    if coords_str and coords_str ~= "" then
        local x, y, z = coords_str:match("^([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+)$")
        if x and y and z then
            spawnLocation = { X = tonumber(x), Y = tonumber(y), Z = tonumber(z) }
        else
            utils.sendPersonalAnnounce(pc, "Invalid coordinates. Use format: x,y,z")
            return
        end
    else
        local location = playerChar:K2_GetActorLocation()
        spawnLocation = { X = location.X + 300, Y = location.Y, Z = location.Z + 100 }
    end

    local spawn_info = {
        ControllerClass = controller_class,
        CharacterID = FName(asset),
        Level = level,
        Location = spawnLocation,
        Yaw = 0.0,
        Squad = nil,
    }

    if shiny then pendingShinyInits = pendingShinyInits + 1 end

    local handle = npc_manager:SpawnNPCForServer(spawn_info, nil)
    if not handle or not handle:IsValid() then
        utils.sendPersonalAnnounce(pc, "Spawn failed.")
        return
    end

    if shiny then
        table.insert(pendingShinyHandles, handle)
        ExecuteWithDelay(500, function() pendingShinyInits = 0 end)
    end

    ExecuteWithDelay(500, function()
        configureSpawnedPal(handle, shiny, 1)
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

function commands.onNpcSpawnCallback()
    for i = #pendingShinyHandles, 1, -1 do
        local handle = pendingShinyHandles[i]
        if not handle or not handle:IsValid() then
            table.remove(pendingShinyHandles, i)
        else
            local parameter = handle:TryGetIndividualParameter()
            if parameter and parameter:IsValid() then
                pcall(function()
                    parameter.bIsUncapturable = false
                    parameter.bIsForceCapturable = true
                    parameter.SaveParameter.IsRarePal = true
                    parameter.SaveParameterMirror.IsRarePal = true
                    parameter:OnRep_SaveParameter()
                end)
                table.remove(pendingShinyHandles, i)
            end
        end
    end
end

function commands.onCharacterParamInit(componentParam)
    if pendingShinyInits < 1 then return end
    if not componentParam or not componentParam:IsValid() then return end
    local parameter = componentParam.IndividualParameter
    if not parameter or not parameter:IsValid() then return end
    pendingShinyInits = pendingShinyInits - 1
    pcall(function()
        parameter.SaveParameter.IsRarePal = true
        parameter.SaveParameterMirror.IsRarePal = true
        parameter:OnRep_SaveParameter()
    end)
end

return commands

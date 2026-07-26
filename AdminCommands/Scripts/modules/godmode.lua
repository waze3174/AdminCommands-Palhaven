local utils = require("libs/utils")
local logger = require("libs/logger")
local commands = {}

local godModeEnabled = {}

local function applyGodMode(pawn, enabled)
    if not pawn or not pawn:IsValid() then return end
    local paramComp = pawn.CharacterParameterComponent
    if paramComp and paramComp:IsValid() then
        paramComp:SetMuteki(FName("AdminGodMode"), enabled)
    end
end

function commands.handleGodMode(state, rest)
    local pc = state:GetPlayerController()
    local uid = utils.GetPlayerId(state)
    if not uid then return end

    local pawn = pc.Pawn
    if not pawn or not pawn:IsValid() then
        utils.sendPersonalAnnounce(pc, "God Mode: No character found.")
        return
    end

    local paramComp = pawn.CharacterParameterComponent
    if not paramComp or not paramComp:IsValid() then
        utils.sendPersonalAnnounce(pc, "God Mode: Character parameter component not found.")
        return
    end

    local enable = nil
    if rest and rest:lower() == "on" then
        enable = true
    elseif rest and rest:lower() == "off" then
        enable = false
    elseif not rest or rest == "" then
        enable = not godModeEnabled[uid]
    else
        utils.sendPersonalAnnounce(pc, "Usage: !god on/off")
        return
    end

    if enable then
        godModeEnabled[uid] = true
        paramComp:SetMuteki(FName("AdminGodMode"), true)
        utils.sendPersonalAnnounce(pc, "God Mode enabled! You are invincible.")
    else
        godModeEnabled[uid] = nil
        paramComp:SetMuteki(FName("AdminGodMode"), false)
        utils.sendPersonalAnnounce(pc, "God Mode disabled! You are mortal again.")
    end

    local playerName = utils.GetPlayerName(state)
    local playerUID = utils.GetPlayerId(state)
    logger.logCommand(playerName, playerUID, "god", enable and "on" or "off")
end

return commands

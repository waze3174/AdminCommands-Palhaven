local FGuid = require("libs/Fguid")
local config = require("config/config")
local utils = {}

local PalUtilities

ExecuteWithDelay(10000, function()
    PalUtilities = StaticFindObject("/Script/Pal.Default__PalUtility")
end)

function utils.sendPersonalAnnounce(PalPlayerController, Message)
    ExecuteWithDelay(350, function()
        local world = FindFirstOf("World")
        local playerState = PalPlayerController.PlayerState
        if not (PalUtilities and PalUtilities:IsValid() and world and world:IsValid() and playerState and playerState:IsValid()) then
            return
        end

        local guidArray = { FGuid.translate(playerState.PlayerUId) }
        PalUtilities:SendSystemToPlayerChat(world, Message, guidArray)
    end)
end

function utils.sendServerAnnounce(message)
    local gameStateInstance = FindFirstOf("PalGameStateInGame")
    if gameStateInstance and gameStateInstance:IsValid() then
        gameStateInstance:BroadcastServerNotice(message)
    end
end

function utils.GetPlayerId(ps)
	if ps and ps:IsValid() and ps.PlayerUId then
		return FGuid.toString(ps.PlayerUId)
	end
	return "UnknownID"
end

function utils.GetPlayerName(ps)
	if ps and ps:IsValid() and ps.PlayerNamePrivate then
		return ps.PlayerNamePrivate:ToString()
	end
	return "Unknown"
end

function utils.IsPlayerAdmin(state)
    if not (state and state:IsValid()) then
        return false
    end

    local pc = state:GetPlayerController()
    if pc and pc:IsValid() and pc.bAdmin then
        return true
    end

    local uid = utils.GetPlayerId(state)
    local uidNoDashes = uid:gsub("-", "")
    for _, adminUID in ipairs(config.adminUIDs) do
        if uidNoDashes == adminUID then
            return true
        end
    end

    return false
end

function utils.getPalUtilities()
    return PalUtilities
end

return utils

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
    local world = FindFirstOf("World")
    if PalUtilities and PalUtilities:IsValid() and world and world:IsValid() then
        PalUtilities:SendSystemAnnounce(world, message)
    end
end

function utils.BroadcastServerMessage(message)
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

-- FIX 2026-08-21: FindAllOf("PalPlayerState") is confirmed non-functional on
-- this Linux port (returns bare nil, see gameservers.md bug class 3 from the
-- destroybase investigation) -- every command that looped it to find a
-- connected player by name was silently matching nobody, every time. This
-- uses the same enumeration mechanism items.lua's by-name !give/!exp already
-- rely on successfully in production: GetPlayerListDisplayMessages +
-- GetPlayerCharacterByPlayerIndex, not a global class search.
function utils.GetAllPlayers()
    local players = {}
    local palUtility = utils.getPalUtilities()
    local world = FindFirstOf("World")
    if not palUtility or not palUtility:IsValid() or not world or not world:IsValid() then
        return players
    end

    local playerList = palUtility:GetPlayerListDisplayMessages(world)
    if not playerList then return players end

    for i = 1, #playerList do
        local info = playerList[i]:get():ToString()
        local name = info:match("^(.-),")
        if name then
            local playerChar = palUtility:GetPlayerCharacterByPlayerIndex(world, i - 1)
            if playerChar and playerChar:IsValid() then
                local pc = playerChar:GetPalPlayerController()
                if pc and pc:IsValid() then
                    table.insert(players, { name = name, pc = pc, state = pc.PlayerState })
                end
            end
        end
    end

    return players
end

-- Returns targetPC, targetState, actualName (as displayed) or nil if no
-- connected player matches (case-insensitive, exact match).
function utils.FindPlayerByName(targetName)
    if not targetName or targetName == "" then return nil end
    local lowerTarget = targetName:lower()
    for _, player in ipairs(utils.GetAllPlayers()) do
        if player.name:lower() == lowerTarget then
            return player.pc, player.state, player.name
        end
    end
    return nil
end

return utils

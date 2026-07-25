-- Kick and Ban use `ClientTravelInternal` to remove a player from the server.
-- Better to use Palworld's built in `KickPlayer` and `BanPlayer`. This is just a backup.
-- Original method provided by Mathayus.

local bans = require("libs/bans")
local utils = require("libs/utils")
local logger = require("libs/logger")
local commands = {}

function commands.handleBan(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !ban <player> [reason]")
        return
    end

    local targetName, reason = rest:match("^(%S+)%s*(.*)$")
    if not targetName then
        utils.sendPersonalAnnounce(pc, "Usage: !ban <player> [reason]")
        return
    end

    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local name = utils.GetPlayerName(targetState)
            if name:lower() == targetName:lower() then
                local targetUID = utils.GetPlayerId(targetState)
                local adminName = utils.GetPlayerName(state)
                local adminUID = utils.GetPlayerId(state)
                
                bans.banUid(targetUID, name, reason)
                logger.logBan(adminName, adminUID, name, targetUID, reason)
                
                local targetPC = targetState:GetPlayerController()
                if targetPC and targetPC:IsValid() then
                    targetPC:ClientTravelInternal("Void", 0, false, nil)
                end
                
                utils.sendPersonalAnnounce(pc, "Banned " .. name .. " [" .. targetUID .. "]")
                utils.sendServerAnnounce(name .. " has been banned.")
                return
            end
        end
    end

    utils.sendPersonalAnnounce(pc, "Player not found.")
end

function commands.handleUnban(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !unban <UID>")
        return
    end

    local uid = rest:match("^(%S+)")
    if bans.unbanUid(uid) then
        utils.sendPersonalAnnounce(pc, "Unbanned UID: " .. uid)
    else
        utils.sendPersonalAnnounce(pc, "UID not found in ban list.")
    end
end

function commands.handleKick(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !kick <player> [reason]")
        return
    end

    local targetName, reason = rest:match("^(%S+)%s*(.*)$")
    if not targetName then
        utils.sendPersonalAnnounce(pc, "Usage: !kick <player> [reason]")
        return
    end

    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local name = utils.GetPlayerName(targetState)
            if name:lower() == targetName:lower() then
                local targetUID = utils.GetPlayerId(targetState)
                local adminName = utils.GetPlayerName(state)
                local adminUID = utils.GetPlayerId(state)
                
                logger.logKick(adminName, adminUID, name, targetUID, reason)
                
                local targetPC = targetState:GetPlayerController()
                if targetPC and targetPC:IsValid() then
                    targetPC:ClientTravelInternal("Void", 0, false, nil)
                end
                
                utils.sendPersonalAnnounce(pc, "Kicked " .. name)
                utils.sendServerAnnounce(name .. " has been kicked.")
                return
            end
        end
    end

    utils.sendPersonalAnnounce(pc, "Player not found.")
end

function commands.handleSlay(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !slay <player>")
        return
    end

    local targetName = rest:lower()
    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local name = utils.GetPlayerName(targetState)
            if name:lower() == targetName then
                local controller = targetState:GetPlayerController()
                if controller and controller:IsValid() then
                    controller:SelfKillPlayer()
                    utils.sendPersonalAnnounce(pc, rest .. " has been killed.")
                else
                    utils.sendPersonalAnnounce(pc, "Could not find valid controller.")
                end
                return
            end
        end
    end

    utils.sendPersonalAnnounce(pc, "Player not found.")
end

return commands

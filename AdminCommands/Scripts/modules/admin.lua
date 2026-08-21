-- Kick and Ban use `ClientTravelInternal` to remove a player from the server.
-- Better to use Palworld's built in `KickPlayer` and `BanPlayer`. This is just a backup.
-- Original method provided by Mathayus.
--
-- FIX 2026-08-21: ban/kick/slay all previously looped FindAllOf("PalPlayerState")
-- to find the target player, which is confirmed non-functional on this Linux
-- port -- they were silently reporting "Player not found" for every real
-- player, every time. Replaced with utils.FindPlayerByName, which uses the
-- same working enumeration mechanism as items.lua's by-name !give/!exp.

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

    local targetPC, targetState, name = utils.FindPlayerByName(targetName)
    if not targetPC then
        utils.sendPersonalAnnounce(pc, "Player not found.")
        return
    end

    local targetUID = utils.GetPlayerId(targetState)
    local adminName = utils.GetPlayerName(state)
    local adminUID = utils.GetPlayerId(state)

    bans.banUid(targetUID, name, reason)
    logger.logBan(adminName, adminUID, name, targetUID, reason)

    if targetPC:IsValid() then
        targetPC:ClientTravelInternal("Void", 0, false, nil)
    end

    utils.sendPersonalAnnounce(pc, "Banned " .. name .. " [" .. targetUID .. "]")
    utils.sendServerAnnounce(name .. " has been banned.")
end

function commands.handleUnban(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !unban <player name or UID>")
        return
    end

    local input = rest:match("^%s*(.-)%s*$")

    -- Try as a UID first -- unambiguous, matches prior behavior exactly.
    if bans.unbanUid(input) then
        utils.sendPersonalAnnounce(pc, "Unbanned UID: " .. input)
        return
    end

    -- Not a UID (or not currently banned under that exact UID) -- fall back
    -- to the name recorded at ban time. A banned player isn't connected, so
    -- this can't reuse utils.FindPlayerByName; it searches the ban list
    -- itself instead (see bans.findByName).
    local matches = bans.findByName(input)
    if #matches == 0 then
        utils.sendPersonalAnnounce(pc, "No ban found matching '" .. input .. "' (checked UID and name).")
        return
    end

    if #matches > 1 then
        local list = {}
        for _, m in ipairs(matches) do
            table.insert(list, m.name .. " [" .. m.uid .. "]")
        end
        utils.sendPersonalAnnounce(pc, "Multiple bans match '" .. input .. "': " .. table.concat(list, ", ") .. ". Use !unban <UID> to pick one.")
        return
    end

    local entry = matches[1]
    bans.unbanUid(entry.uid)
    utils.sendPersonalAnnounce(pc, "Unbanned " .. entry.name .. " [" .. entry.uid .. "]")
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

    local targetPC, targetState, name = utils.FindPlayerByName(targetName)
    if not targetPC then
        utils.sendPersonalAnnounce(pc, "Player not found.")
        return
    end

    local targetUID = utils.GetPlayerId(targetState)
    local adminName = utils.GetPlayerName(state)
    local adminUID = utils.GetPlayerId(state)

    logger.logKick(adminName, adminUID, name, targetUID, reason)

    if targetPC:IsValid() then
        targetPC:ClientTravelInternal("Void", 0, false, nil)
    end

    utils.sendPersonalAnnounce(pc, "Kicked " .. name)
    utils.sendServerAnnounce(name .. " has been kicked.")
end

function commands.handleSlay(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !slay <player>")
        return
    end

    local targetPC, _, name = utils.FindPlayerByName(rest)
    if not targetPC then
        utils.sendPersonalAnnounce(pc, "Player not found.")
        return
    end

    if targetPC:IsValid() then
        targetPC:SelfKillPlayer()
        utils.sendPersonalAnnounce(pc, name .. " has been killed.")
    else
        utils.sendPersonalAnnounce(pc, "Could not find valid controller.")
    end
end

return commands

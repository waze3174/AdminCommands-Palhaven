local utils = require("libs/utils")
local logger = require("libs/logger")
local config = require("config/config")
local commands = {}

function commands.handleSetTime(state, rest)
    local pc = state and state:GetPlayerController() or nil
    if not rest or rest == "" then
        if pc then utils.sendPersonalAnnounce(pc, "Usage: !settime <hour>") end
        return
    end

    local hour = tonumber(rest)
    if not hour or hour < 0 or hour > 23 then
        if pc then utils.sendPersonalAnnounce(pc, "Invalid hour. Must be between 0 and 23.") end
        return
    end

    local timeManager = FindFirstOf("PalTimeManager")
    if not timeManager or not timeManager:IsValid() then
        if pc then utils.sendPersonalAnnounce(pc, "PalTimeManager not found.") end
        return
    end

    timeManager:SetGameTime_FixDay(hour)
    local timeStr = timeManager:GetDebugTimeString():ToString()
    if pc then
        utils.sendPersonalAnnounce(pc, "Game time set. Current time: " .. timeStr)
    else
        logger.info("[console] Game time set to hour " .. hour .. ". Current time: " .. timeStr)
    end
end

function commands.handleCurrentTime(state)
    local pc = state:GetPlayerController()
    local timeManager = FindFirstOf("PalTimeManager")
    if not timeManager or not timeManager:IsValid() then
        utils.sendPersonalAnnounce(pc, "PalTimeManager not found.")
        return
    end

    local timeStr = timeManager:GetDebugTimeString():ToString()
    utils.sendPersonalAnnounce(pc, "Current Game Time: " .. timeStr)
end

function commands.handleAnnounce(state, rest)
    local pc = state and state:GetPlayerController() or nil
    if not rest or rest == "" then
        if pc then utils.sendPersonalAnnounce(pc, "Usage: !announce <message>") end
        return
    end

    utils.BroadcastServerMessage(rest)
    if pc then
        utils.sendPersonalAnnounce(pc, "Announced server wide message.")
    else
        logger.info("[console] Announced: " .. rest)
    end
end

if config.broadcastEnabled then
    local function autoBroadcast()
        if not config.broadcastMessage or config.broadcastMessage == "" then
            return
        end

        if config.broadcastType == "system" then
            utils.sendServerAnnounce(config.broadcastMessage)
        elseif config.broadcastType == "notice" then
            utils.BroadcastServerMessage(config.broadcastMessage)
        end

        ExecuteWithDelay(config.broadcastIntervalMinutes * 60 * 1000, autoBroadcast)
    end

    ExecuteWithDelay(config.broadcastIntervalMinutes * 60 * 1000, autoBroadcast)
end

return commands

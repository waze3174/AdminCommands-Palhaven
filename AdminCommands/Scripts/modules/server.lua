local utils = require("libs/utils")
local commands = {}

function commands.handleSetTime(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !settime <hour>")
        return
    end

    local hour = tonumber(rest)
    if not hour or hour < 0 or hour > 23 then
        utils.sendPersonalAnnounce(pc, "Invalid hour. Must be between 0 and 23.")
        return
    end

    local timeManager = FindFirstOf("PalTimeManager")
    if not timeManager or not timeManager:IsValid() then
        utils.sendPersonalAnnounce(pc, "PalTimeManager not found.")
        return
    end

    timeManager:SetGameTime_FixDay(hour)
    local timeStr = timeManager:GetDebugTimeString():ToString()
    utils.sendPersonalAnnounce(pc, "Game time set. Current time: " .. timeStr)
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
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !announce <message>")
        return
    end

    utils.sendServerAnnounce(rest)
    utils.sendPersonalAnnounce(pc, "Announced server wide message.")
end

return commands

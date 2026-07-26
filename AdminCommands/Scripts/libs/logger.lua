local constants = require("libs/constants")
local logger = {}

local ModDirectory = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]]):match("^(.+[/\\])[^/\\]+[/\\]$")
local log_folder = ModDirectory .. "logs"
local server_log_folder = log_folder .. "/serverlogs"
os.execute("mkdir \"" .. log_folder .. "\"")
os.execute("mkdir \"" .. server_log_folder .. "\"")

local function GetCurrentTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function logger.logToFile(filename, line)
    local fileHandler = io.open(log_folder .. "/" .. filename, "a")
    if fileHandler then
        fileHandler:write(string.format("[%s] %s\n", GetCurrentTimestamp(), line))
        fileHandler:close()
    end
end

function logger.logToServerFile(filename, line)
    local fileHandler = io.open(server_log_folder .. "/" .. filename, "a")
    if fileHandler then
        fileHandler:write(string.format("[%s] %s\n", GetCurrentTimestamp(), line))
        fileHandler:close()
    end
end

function logger.logChat(playerName, playerUID, category, message)
    local logLine = string.format("[%s] %s [%s]: %s", category, playerName, playerUID, message)
    logger.logToServerFile("chat.txt", logLine)
end

function logger.logDeath(victimName, victimUID, attackerName, attackerUID)
    local logLine
    if attackerName then
        logLine = string.format("%s [%s] was killed by %s [%s]", victimName, victimUID or "UnknownID", attackerName, attackerUID or "UnknownID")
    else
        logLine = string.format("%s [%s] died", victimName, victimUID or "UnknownID")
    end
    logger.logToServerFile("deaths.txt", logLine)
end

function logger.logConnect(playerName, playerUID)
    local logLine = string.format("%s [%s] has connected.", playerName, playerUID)
    logger.logToServerFile("connections.txt", logLine)
end

function logger.logDisconnect(playerName, playerUID)
    local logLine = string.format("%s [%s] has disconnected.", playerName, playerUID)
    logger.logToServerFile("connections.txt", logLine)
end

function logger.logCapture(playerName, playerUID, palName)
    local logLine = string.format("%s [%s] captured %s.", playerName, playerUID, palName)
    logger.logToServerFile("captures.txt", logLine)
end

function logger.logCommand(playerName, playerUID, command, args)
    local logLine = string.format("%s [%s] executed: %s %s", playerName, playerUID, command, args or "")
    logger.logToFile("commands.txt", logLine)
end

function logger.logBan(adminName, adminUID, targetName, targetUID, reason)
    local logLine = string.format("%s [%s] banned %s [%s] - Reason: %s", 
        adminName, adminUID, targetName, targetUID, reason or "No reason")
    logger.logToFile("bans.txt", logLine)
end

function logger.logKick(adminName, adminUID, targetName, targetUID, reason)
    local logLine = string.format("%s [%s] kicked %s [%s] - Reason: %s", 
        adminName, adminUID, targetName, targetUID, reason or "No reason")
    logger.logToFile("kicks.txt", logLine)
end

function logger.logTeleport(playerName, playerUID, destination)
    local logLine = string.format("%s [%s] teleported to: %s", playerName, playerUID, destination)
    logger.logToFile("teleports.txt", logLine)
end

function logger.logSpawn(playerName, playerUID, palName, level, shiny)
    local shinyText = shiny and " (SHINY)" or ""
    local logLine = string.format("%s [%s] spawned: %s Lv%d%s", 
        playerName, playerUID, palName, level, shinyText)
    logger.logToFile("spawns.txt", logLine)
end

function logger.info(message)
    local msg = constants.MOD_PREFIX .. " " .. message
    print(msg .. "\n")
    logger.logToFile("log.txt", msg)
end

function logger.error(message)
    local msg = constants.MOD_PREFIX_ERROR .. " " .. message
    io.stderr:write(msg .. "\n")
    logger.logToFile("log.txt", msg)
end

return logger

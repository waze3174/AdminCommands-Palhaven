local constants = require("libs/constants")
local logger = {}

local ModDirectory = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]]):match("^(.+[/\\])[^/\\]+[/\\]$")
local log_folder = ModDirectory .. "logs"
os.execute("mkdir \"" .. log_folder .. "\"")

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

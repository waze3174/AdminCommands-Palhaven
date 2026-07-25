local config = {}

-- Prefix for commands. Set to "/" to hide from chat.
config.commandPrefix = "!"

-- Message of the Day (MOTD) Settings.  
config.motdEnabled = false
config.motdMessage = "Welcome %s! Enjoy your stay on the server."

-- Broadcast Settings
-- Broadcasts are messages that are sent to all players at regular intervals.
-- "system" message are sent to chat, "notice" messages are sent as giant popups
config.broadcastEnabled = false
config.broadcastType = "system"
config.broadcastIntervalMinutes = 5
config.broadcastMessage = "Visit our discord at discord.gg/example for updates and support!"

-- Permissions
-- Add player UIDs to grant admin privileges without logging in.
config.adminUIDs = {
    "12345678000000000000000000000000"
}

return config

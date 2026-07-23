local commandHandlers = require("libs/handler")
local bans = require("libs/bans")
local utils = require("libs/utils")
local logger = require("libs/logger")
local config = require("config/config")
local logic = {}

for k in pairs(commandHandlers) do
    print("[AdminCommands] Registered command: " .. k .. "\n")
end

function logic.chatHook(ctx, Message, Category)
    local text = Message:get():ToString()
    local pc = ctx:get()
    local state = pc.PlayerState

    local prefixPattern = config.commandPrefix:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local cmd, rest = text:match("^" .. prefixPattern .. "(%S+)%s*(.*)$")
    if not cmd then
        return
    end

    cmd = cmd:lower()

    local entry = commandHandlers[cmd]
    if not entry then
        return
    end

    if entry.admin and not utils.IsPlayerAdmin(state) then
        utils.sendPersonalAnnounce(pc, "You do not have permission.")
        return
    end

    local playerName = utils.GetPlayerName(state)
    local playerUID = utils.GetPlayerId(state)
    logger.logCommand(playerName, playerUID, cmd, rest)

    entry.func(state, rest)
end

function logic.onCharacterInit(ctx)
    local character = ctx and ctx:get()
    if not (character and character:IsValid()) then return end
    local ps = character.PlayerState
    if not (ps and ps:IsValid()) then
        return ExecuteWithDelay(50, function() logic.onCharacterInit(ctx) end)
    end
    local uid = utils.GetPlayerId(ps)
    if bans.isUidBanned(uid) then
        local pc = ps:GetPlayerController()
        if pc and pc:IsValid() then
            pc:ClientTravelInternal("Void", 0, false, nil)
        end
    end
end

return logic

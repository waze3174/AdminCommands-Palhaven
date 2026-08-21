local commandHandlers = require("libs/handler")
local bans = require("libs/bans")
local utils = require("libs/utils")
local logger = require("libs/logger")
local config = require("config/config")
local serverlogs = require("libs/serverlogs")
local logic = {}

for k in pairs(commandHandlers) do
    print("[AdminCommands] Registered command: " .. k .. "\n")
end

function logic.chatHook(ctx, Message, Category)
    local text = Message:get():ToString()
    local pc = ctx:get()
    local state = pc.PlayerState

    serverlogs.ChatLog(state, text, Category:get())

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

    serverlogs.ConnectLog(character)

    local uid = utils.GetPlayerId(ps)
    if bans.isUidBanned(uid) then
        local pc = ps:GetPlayerController()
        if pc and pc:IsValid() then
            pc:ClientTravelInternal("Void", 0, false, nil)
        end
    end
    if config.motdEnabled then
        local pc = ps:GetPlayerController()
        if pc and pc:IsValid() then
            local name = ps.PlayerNamePrivate and ps.PlayerNamePrivate:ToString() or "Player"
            local msg = string.format(config.motdMessage, name)
            utils.sendPersonalAnnounce(pc, msg)
        end
    end
end

-- Console/RCON dispatch, ATTEMPT 1, REMOVED 2026-08-21: originally hooked
-- ProcessConsoleExec via RegisterHook. Confirmed dead -- ProcessConsoleExec
-- is not a reflected UFunction on this build, RegisterHook can never attach
-- to it regardless of class path. Superseded by attempt 2 below
-- (RegisterConsoleCommandHandler), a genuinely different mechanism.

-- Console/RCON dispatch, ATTEMPT 2 (2026-08-21): the first attempt
-- (hooking ProcessConsoleExec via RegisterHook) failed hard -- confirmed
-- not a reflected UFunction on this build, see above. This uses
-- a genuinely different mechanism: RegisterConsoleCommandHandler, a
-- dedicated UE4SS Lua API for custom console commands (already used
-- successfully by ConsoleCommandsMod, sitting in this server's own Mods
-- folder). Backed by UE4SS's own internal raw-address hook on
-- UObject::ProcessConsoleExec (confirmed in boot log), not tied to a
-- GameViewport the way ConsoleEnablerMod's approach is (that one is
-- confirmed dead on a dedicated server -- "GameViewport... is invalid").
-- NOT YET LIVE-TESTED against actual RCON-delivered text -- plausible, not
-- proven, until confirmed with a real command sent through the Pterodactyl
-- console/Scheduler.
--
-- Note for usage: registered under the plain command name, no "!" prefix
-- (that prefix is specific to the chat dispatch path) -- e.g. "announce
-- hello" as the RCON/Scheduler payload, not "!announce hello".
function logic.registerConsoleCommands()
    for name, entry in pairs(commandHandlers) do
        if entry.consoleSafe then
            RegisterConsoleCommandHandler(name, function(FullCommand, Parameters, Ar)
                local rest = table.concat(Parameters, " ")
                logger.logCommand("[RCON]", "console", name, rest)
                local ok, err = pcall(entry.func, nil, rest)
                if not ok then
                    logger.info("[console] command '" .. name .. "' errored: " .. tostring(err))
                end
                return true
            end)
        end
    end
end

return logic

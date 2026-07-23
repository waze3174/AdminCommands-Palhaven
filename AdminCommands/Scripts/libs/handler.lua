local admin = require("modules/admin")
local fly = require("modules/fly")
local teleport = require("modules/teleport")
local spawn = require("modules/spawn")
local freeze = require("modules/freeze")
local server = require("modules/server")
local items = require("modules/items")

local commandHandlers = {
    ban = { admin = true, func = admin.handleBan },
    unban = { admin = true, func = admin.handleUnban },
    kick = { admin = true, func = admin.handleKick },
    fly = { admin = true, func = fly.handleFly },
    ["goto"] = { admin = true, func = teleport.handleGoto },
    getpos = {
        admin = true,
        func = function(state, rest)
            if not rest or rest == "" then
                teleport.handleGetPos(state)
            else
                teleport.handlePlayerGetPos(state, rest)
            end
        end
    },
    bring = { admin = true, func = teleport.handleBring },
    bringall = { admin = true, func = teleport.handleBringAll },
    spawn = { admin = true, func = spawn.handleSpawn },
    catch = { admin = true, func = spawn.handleCatch },
    give = {
        admin = true,
        func = function(state, rest)
            if not rest or rest == "" or not rest:find(" ") then
                items.handlePersonalGive(state, rest)
            else
                items.handleGive(state, rest)
            end
        end
    },
    giveme = { admin = true, func = items.handlePersonalGive },
    freeze = { admin = true, func = freeze.handleFreeze },
    unfreeze = { admin = true, func = freeze.handleUnfreeze },
    settime = { admin = true, func = server.handleSetTime },
    announce = { admin = true, func = server.handleAnnounce },
    unstuck = { admin = false, func = teleport.handleUnstuck },
    time = { admin = false, func = server.handleCurrentTime },
}

return commandHandlers

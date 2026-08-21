local admin = require("modules/admin")
local fly = require("modules/fly")
local teleport = require("modules/teleport")
local spawn = require("modules/spawn")
local freeze = require("modules/freeze")
local server = require("modules/server")
local items = require("modules/items")
local basecamp = require("modules/basecamp")
local utils = require("libs/utils")

local commandHandlers = {
    ban = { admin = true, func = admin.handleBan },
    unban = { admin = true, func = admin.handleUnban },
    kick = { admin = true, func = admin.handleKick },
    slay = { admin = true, func = admin.handleSlay },
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
        consoleSafe = true,
        func = function(state, rest)
            if not rest or rest == "" or not rest:find(" ") then
                items.handlePersonalGive(state, rest)
            else
                items.handleGive(state, rest)
            end
        end
    },
    giveme = { admin = true, func = items.handlePersonalGive },
    exp = {
        admin = true,
        consoleSafe = true,
        func = function(state, rest)
            if not rest or rest == "" or not rest:find(" ") then
                items.handlePersonalExp(state, rest)
            else
                items.handleExpCommand(state, rest)
            end
        end
    },
    giveexp = { admin = true, func = items.handlePersonalExp },
    freeze = { admin = true, func = freeze.handleFreeze },
    unfreeze = { admin = true, func = freeze.handleUnfreeze },
    settime = { admin = true, consoleSafe = true, func = server.handleSetTime },
    announce = { admin = true, consoleSafe = true, func = server.handleAnnounce },
    unstuck = { admin = false, func = teleport.handleUnstuck },
    destroybase = { admin = true, func = basecamp.handleDestroyBase },
    destroynearestbase = { admin = true, func = basecamp.handleDestroyNearestBase },
    -- admingun REMOVED 2026-08-18: depends on the OnHit hook, which is
    -- permanently disabled (confirmed crash risk hooking Blueprint-
    -- overridden natives -- see main.lua). Left wired up, it would have
    -- silently confirmed "Admin Gun: ON" while never actually doing
    -- anything on a shot, which is worse than an honest "Unknown command."
    -- Replaced in practice by destroyatcrosshair below.
    destroyatcrosshair = { admin = true, func = basecamp.handleDestroyAtCrosshair },
    time = { admin = false, func = server.handleCurrentTime },
    help = {
        admin = false,
        func = function(state)
            local pc = state:GetPlayerController()
            utils.sendPersonalAnnounce(pc,
                "!give Player item:amount | !giveme item:amount | !catch Pal Level [shiny] | !spawn Pal Level [shiny] | " ..
                "!fly enable/disable | !freeze Player | !unfreeze Player | !announce msg | !settime 0-23 | " ..
                "!goto x,y,z | !goto Player | !getpos [Player] | !time | !unstuck | " ..
                "!ban Player reason | !unban Player-or-UID | !kick Player | !slay Player | !bring Player | !bringall | " ..
                "!destroybase x,y,z | !destroynearestbase | !destroyatcrosshair"
            )
        end
    },
}

return commandHandlers

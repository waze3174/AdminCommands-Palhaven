-- DIAGNOSTIC + LIKELY FIX 2026-08-21: native StartFlyToServer/EndFlyToServer
-- report success (we get here, no error) but produce no visible in-game
-- effect. Logging MovementMode before/after the native call so we can see
-- objectively whether it's changing anything at all. If it isn't, we force
-- it directly via GetPalCharacterMovementComponent()/SetMovementMode(),
-- the same accessor freeze.lua already uses successfully in production.

local utils = require("libs/utils")
local commands = {}

local MOVE_WALKING = 1
local MOVE_FLYING = 5

function commands.handleFly(state, rest)
    local pc = state:GetPlayerController()
    local option = rest and rest:lower() or ""
    if option ~= "enable" and option ~= "disable" then
        utils.sendPersonalAnnounce(pc, "Usage: !fly enable or !fly disable")
        return
    end

    local char = pc.Pawn
    if not (char and char:IsValid()) then
        utils.sendPersonalAnnounce(pc, "Could not find your character.")
        return
    end

    local movement = char:GetPalCharacterMovementComponent()
    if not (movement and movement:IsValid()) then
        utils.sendPersonalAnnounce(pc, "Could not access movement component.")
        return
    end

    local before = movement.MovementMode

    if option == "enable" then
        pc:StartFlyToServer()
    else
        pc:EndFlyToServer()
    end

    local after = movement.MovementMode
    utils.sendPersonalAnnounce(pc, string.format("[fly debug] MovementMode before=%s after=%s", tostring(before), tostring(after)))

    if option == "enable" then
        if after == before or after ~= MOVE_FLYING then
            movement:SetMovementMode(MOVE_FLYING, 0)
            utils.sendPersonalAnnounce(pc, "Fly mode enabled (forced -- native call had no effect).")
        else
            utils.sendPersonalAnnounce(pc, "Fly mode enabled.")
        end
    else
        if movement.MovementMode == MOVE_FLYING then
            movement:SetMovementMode(MOVE_WALKING, 0)
            utils.sendPersonalAnnounce(pc, "Fly mode disabled (forced).")
        else
            utils.sendPersonalAnnounce(pc, "Fly mode disabled.")
        end
    end
end

return commands

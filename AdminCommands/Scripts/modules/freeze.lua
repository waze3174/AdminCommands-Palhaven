-- FIX 2026-08-21: freeze/unfreeze previously looped FindAllOf("PalPlayerState"),
-- confirmed non-functional on this Linux port -- silently reporting
-- "Player not found" every time. Replaced with utils.FindPlayerByName (same
-- mechanism as items.lua's by-name !give/!exp). Bonus fix alongside
-- ban/kick/slay/goto/getpos/bring since it's the identical root cause and a
-- mechanical swap -- not a request to un-deprecate these commands if they've
-- been intentionally excluded elsewhere.

local utils = require("libs/utils")
local commands = {}

local FROZEN = FROZEN or {}

function commands.handleFreeze(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !freeze <player>")
        return
    end

    local targetName = rest:match("^%s*(.-)%s*$")
    local targetPC, targetState, name = utils.FindPlayerByName(targetName)
    if not targetPC then
        utils.sendPersonalAnnounce(pc, "Player not found.")
        return
    end

    local targetChar = targetPC.Pawn
    if targetChar and targetChar:IsValid() then
        local movement = targetChar:GetPalCharacterMovementComponent()
        if movement and movement:IsValid() then
            local targetUID = utils.GetPlayerId(targetState)
            FROZEN[targetUID] = true

            movement:StopMovementImmediately()
            movement.bIsDisableInput = true
            movement.bIsDisableMovement = true
            movement.bIsDisableJump = true
            targetPC:SetIgnoreMoveInput(true)

            utils.sendPersonalAnnounce(pc, "Froze " .. name)
        end
    end
end

function commands.handleUnfreeze(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !unfreeze <player>")
        return
    end

    local targetName = rest:match("^%s*(.-)%s*$")
    local targetPC, targetState, name = utils.FindPlayerByName(targetName)
    if not targetPC then
        utils.sendPersonalAnnounce(pc, "Player not found.")
        return
    end

    local targetChar = targetPC.Pawn
    if targetChar and targetChar:IsValid() then
        local movement = targetChar:GetPalCharacterMovementComponent()
        if movement and movement:IsValid() then
            local targetUID = utils.GetPlayerId(targetState)
            FROZEN[targetUID] = nil

            movement.bIsDisableInput = false
            movement.bIsDisableMovement = false
            movement.bIsDisableJump = false
            movement:SetMovementMode(1, 0)
            targetPC:ResetIgnoreMoveInput()

            utils.sendPersonalAnnounce(pc, "Unfroze " .. name)
        end
    end
end

return commands

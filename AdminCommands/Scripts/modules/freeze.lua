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
    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local name = utils.GetPlayerName(targetState)
            if name:lower() == targetName:lower() then
                local targetPC = targetState:GetPlayerController()
                local targetChar = targetPC and targetPC.Pawn
                
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
                return
            end
        end
    end

    utils.sendPersonalAnnounce(pc, "Player not found.")
end

function commands.handleUnfreeze(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !unfreeze <player>")
        return
    end

    local targetName = rest:match("^%s*(.-)%s*$")
    for _, targetState in ipairs(FindAllOf("PalPlayerState") or {}) do
        if targetState and targetState:IsValid() then
            local name = utils.GetPlayerName(targetState)
            if name:lower() == targetName:lower() then
                local targetPC = targetState:GetPlayerController()
                local targetChar = targetPC and targetPC.Pawn
                
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
                return
            end
        end
    end

    utils.sendPersonalAnnounce(pc, "Player not found.")
end

return commands

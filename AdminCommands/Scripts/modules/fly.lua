local utils = require("libs/utils")
local commands = {}

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

    if option == "enable" then
        pc:StartFlyToServer()
        utils.sendPersonalAnnounce(pc, "Fly mode enabled.")
    else
        pc:EndFlyToServer()
        utils.sendPersonalAnnounce(pc, "Fly mode disabled.")
    end
end

return commands

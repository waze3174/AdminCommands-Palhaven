-- A lot of work went into this admin mod.
-- If you decide to use code please give credit

local logic = require("libs/logic")
local logger = require("libs/logger")

ExecuteWithDelay(3000, function()
    RegisterHook("/Script/Pal.PalPlayerController:EnterChat_Receive", logic.chatHook)
    RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", logic.onCharacterInit)
    logger.info("Hooks registered")
end)

logger.info("AdminCommands has been loaded successfully!")
io.stderr:write("[AdminCommands] has been loaded successfully!\n")

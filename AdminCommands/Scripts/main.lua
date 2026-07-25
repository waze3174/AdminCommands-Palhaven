-- A lot of work went into this admin mod.
-- If you decide to use code please give credit

local logic = require("libs/logic")
local logger = require("libs/logger")
local spawn = require("modules/spawn")

ExecuteWithDelay(3000, function()
    RegisterHook("/Script/Pal.PalPlayerController:EnterChat_Receive", logic.chatHook)
    RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", logic.onCharacterInit)
    RegisterHook("/Script/Pal.PalNPCManager:SpawNPCCallback", spawn.onNpcSpawnCallback)
    RegisterHook("/Script/Pal.PalCharacterParameterComponent:OnInitialize_AfterSetIndividualParameter", spawn.onCharacterParamInit)
    logger.info("Hooks registered")
end)

logger.info("AdminCommands has been loaded successfully!")
io.stderr:write("[AdminCommands] has been loaded successfully!\n")

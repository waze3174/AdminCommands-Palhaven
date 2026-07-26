-- A lot of work went into this admin mod.
-- If you decide to use code please give credit

local logic = require("libs/logic")
local logger = require("libs/logger")
local spawn = require("modules/spawn")
local serverlogs = require("libs/serverlogs")

local function SafeRegisterHook(hookPath, handler, retryDelayMs)
    local ok = pcall(function()
        RegisterHook(hookPath, handler)
    end)
    if not ok then
        ExecuteWithDelay(retryDelayMs or 2000, function()
            SafeRegisterHook(hookPath, handler, retryDelayMs)
        end)
    end
end

ExecuteWithDelay(1000, function()
    RegisterHook("/Script/Pal.PalPlayerController:EnterChat_Receive", logic.chatHook)
    RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", logic.onCharacterInit)
    RegisterHook("/Script/Pal.PalNPCManager:SpawNPCCallback", spawn.onNpcSpawnCallback)
    RegisterHook("/Script/Pal.PalCharacterParameterComponent:OnInitialize_AfterSetIndividualParameter", spawn.onCharacterParamInit)
    SafeRegisterHook("/Script/Pal.PalCharacter:OnDeadCharacter", serverlogs.onDeadCharacter)
    SafeRegisterHook("/Game/Pal/Blueprint/Character/Player/Female/BP_Player_Female.BP_Player_Female_C:ReceiveEndPlay", serverlogs.onPlayerEndPlay)
    SafeRegisterHook("/Game/Pal/Blueprint/Weapon/Other/NewPalSphere/BP_PalSphere_Body.BP_PalSphere_Body_C:CaptureSuccessEvent", serverlogs.onCaptureSuccess)
end)

logger.info("AdminCommands has been loaded successfully!")
io.stderr:write("[AdminCommands] has been loaded successfully!\n")

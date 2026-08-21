-- A lot of work went into this admin mod.
-- If you decide to use code please give credit

local logic = require("libs/logic")
local logger = require("libs/logger")
local spawn = require("modules/spawn")
local serverlogs = require("libs/serverlogs")
local basecamp = require("modules/basecamp")

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

-- TARGETED HOOK SET 2026-08-12: this Linux UE4SS port hangs (pthread_mutex_lock
-- deadlock inside TDetourInstance::InvokeCallbacks) once enough hooks are
-- registered and firing concurrently. Confirmed via 3 separate crash dumps that
-- it's total hook count/contention, not any single hook at fault.
--
-- Confirmed stable at 2 hooks (EnterChat_Receive + OnHit). 2026-08-12: adding
-- SpawNPCCallback + OnInitialize_AfterSetIndividualParameter (4 hooks total)
-- to restore the shiny flag on !spawn/!catch. NOT YET CONFIRMED STABLE AT
-- THIS COUNT -- test idle + real usage before trusting on live server.
--
-- Kept, mapped against the actual command list wanted:
--   EnterChat_Receive               - required for ALL chat command dispatch (logic.chatHook)
--   OnHit                           - required for !admingun only (basecamp.onBulletHit)
--   SpawNPCCallback                 - shiny flag on !spawn/!catch (spawn.onNpcSpawnCallback)
--   OnInitialize_AfterSetIndividualParameter - shiny flag on !spawn/!catch (spawn.onCharacterParamInit)
--
-- Everything else covers commands that are either redundant with Palworld's
-- own native RCON commands (kick/ban/unban/teleport all exist natively) or
-- explicitly not wanted (getpos, freeze/unfreeze, slay).
--
-- Disabled, and why:
--   onCharacterInit        - not needed; loses on-join ban-kick + MOTD (kick/ban still work manually via chat command or native Palworld RCON)
--   onDeadCharacter         - not needed; loses death logging only; also previously crash-implicated
--   onPlayerEndPlay          - not needed; loses disconnect logging only
--   onCaptureSuccess         - not needed; also flagged unstable in mod's own docs ("capture logs will cause server crashes")

-- REMOVED 2026-08-18: OnHit is not needed anymore. Confirmed twice that
-- hooking it (for !admingun) carries a real crash risk -- capture-sphere
-- throws corrupt BP_ThrowObjectBase_C's execution, and the second test
-- proved it's the act of hooking itself that's the problem, not anything
-- in basecamp.lua's own logic (crashed on a Lamball hit that barely ran
-- our code at all). Base cleanup is now handled by
-- handleDestroyAtCrosshair in basecamp.lua -- a direct line trace from the
-- calling admin's crosshair, no OnHit hook, no FindAllOf (confirmed
-- non-functional on this port for any class). !admingun itself stays
-- permanently unavailable; !destroyatcrosshair replaces its practical use
-- case (removing a specific stuck palbox) without the risk.

ExecuteWithDelay(1000, function()
    RegisterHook("/Script/Pal.PalPlayerController:EnterChat_Receive", logic.chatHook)
    RegisterHook("/Script/Pal.PalNPCManager:SpawNPCCallback", spawn.onNpcSpawnCallback)
    RegisterHook("/Script/Pal.PalCharacterParameterComponent:OnInitialize_AfterSetIndividualParameter", spawn.onCharacterParamInit)

    -- RegisterHook("/Script/Pal.PalBullet:OnHit", basecamp.onBulletHit)  -- permanently off, see note above
    -- RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", logic.onCharacterInit)
    -- RegisterHook("/Script/Pal.PalCharacter:OnDeadCharacter", serverlogs.onDeadCharacter)
    -- SafeRegisterHook("/Game/Pal/Blueprint/Character/Player/Female/BP_Player_Female.BP_Player_Female_C:ReceiveEndPlay", serverlogs.onPlayerEndPlay)
    -- SafeRegisterHook("/Game/Pal/Blueprint/Weapon/Other/NewPalSphere/BP_PalSphere_Body.BP_PalSphere_Body_C:CaptureSuccessEvent", serverlogs.onCaptureSuccess)

    logger.info("Hooks registered")
end)

logger.info("AdminCommands has been loaded successfully!")
io.stderr:write("[AdminCommands] has been loaded successfully!\n")

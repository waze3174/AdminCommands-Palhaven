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
-- Confirmed stable at 3 hooks as of the 2026-08-21 test pass (EnterChat_Receive
-- + SpawNPCCallback + OnInitialize_AfterSetIndividualParameter; OnHit has
-- since been permanently removed, see below).
--
-- 2026-08-21: attempted adding ProcessConsoleExec on PlayerController for
-- RCON/console dispatch. REMOVED same day -- confirmed via a live
-- RegisterHook error that "/Script/Engine.PlayerController:ProcessConsoleExec"
-- is not a reflected UFunction on this build at all ("no UFunction with the
-- specified name was found"). Also exposed a real fragility: RegisterHook
-- throws a hard Lua error on a missing target rather than failing
-- gracefully, which silently aborted registration of every hook listed
-- after it in this same block (SpawNPCCallback and
-- OnInitialize_AfterSetIndividualParameter never registered that session).
-- Fixed below by wrapping every call in TryRegisterHook so one bad/unverified
-- hook name can never again take out the ones after it. Console/RCON
-- dispatch is on hold until the actual correct hook target is confirmed via
-- real data (an SDK/reflection dump), not another guess.
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

-- Single-attempt safe wrapper: logs and moves on if the target UFunction
-- doesn't exist on this build, rather than throwing a hard error that
-- silently aborts every RegisterHook call after it in the same block.
-- Distinct from SafeRegisterHook above, which retries forever -- appropriate
-- for a hook that might not exist YET (e.g. an async-loaded Blueprint
-- class), not for one we already know is simply wrong.
local function TryRegisterHook(hookPath, handler)
    local ok, err = pcall(function()
        RegisterHook(hookPath, handler)
    end)
    if not ok then
        logger.info("[main] Failed to register hook '" .. hookPath .. "': " .. tostring(err))
    end
    return ok
end

ExecuteWithDelay(1000, function()
    TryRegisterHook("/Script/Pal.PalPlayerController:EnterChat_Receive", logic.chatHook)
    TryRegisterHook("/Script/Pal.PalNPCManager:SpawNPCCallback", spawn.onNpcSpawnCallback)
    TryRegisterHook("/Script/Pal.PalCharacterParameterComponent:OnInitialize_AfterSetIndividualParameter", spawn.onCharacterParamInit)

    -- RegisterHook("/Script/Pal.PalBullet:OnHit", basecamp.onBulletHit)  -- permanently off, see note above
    -- RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", logic.onCharacterInit)
    -- RegisterHook("/Script/Pal.PalCharacter:OnDeadCharacter", serverlogs.onDeadCharacter)
    -- SafeRegisterHook("/Game/Pal/Blueprint/Character/Player/Female/BP_Player_Female.BP_Player_Female_C:ReceiveEndPlay", serverlogs.onPlayerEndPlay)
    -- SafeRegisterHook("/Game/Pal/Blueprint/Weapon/Other/NewPalSphere/BP_PalSphere_Body.BP_PalSphere_Body_C:CaptureSuccessEvent", serverlogs.onCaptureSuccess)

    logger.info("Hooks registered")

    -- Console/RCON dispatch, attempt 2 -- see logic.lua for the full
    -- history of why attempt 1 (RegisterHook on ProcessConsoleExec) failed.
    -- Uses RegisterConsoleCommandHandler instead, which isn't tied to a
    -- reflected UFunction and shouldn't carry the same "no UFunction found"
    -- failure mode -- but this is genuinely not yet confirmed against real
    -- RCON-delivered text, so wrapped defensively regardless.
    local consoleOk, consoleErr = pcall(logic.registerConsoleCommands)
    if not consoleOk then
        logger.info("[main] Failed to register console commands: " .. tostring(consoleErr))
    else
        logger.info("Console commands registered (announce/give/exp/settime)")
    end
end)

logger.info("AdminCommands has been loaded successfully!")
io.stderr:write("[AdminCommands] has been loaded successfully!\n")

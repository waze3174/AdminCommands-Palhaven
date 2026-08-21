local utils = require("libs/utils")
local logger = require("libs/logger")
local config = require("config/config")
local commands = {}

local DEFAULT_MARGIN = 2000.0

local function getBaseCampManager()
    local manager = FindFirstOf("PalBaseCampManager")
    if manager and manager:IsValid() then return manager end
    return nil
end

local function guidToString(g)
    if not g then return "nil" end
    local okA, a = pcall(function() return g.A end)
    local okB, b = pcall(function() return g.B end)
    local okC, c = pcall(function() return g.C end)
    local okD, d = pcall(function() return g.D end)
    if not (okA and okB and okC and okD) then
        return string.format("<unreadable A/B/C/D: okA=%s okB=%s okC=%s okD=%s>", tostring(okA), tostring(okB), tostring(okC), tostring(okD))
    end
    return string.format("%s-%s-%s-%s", tostring(a), tostring(b), tostring(c), tostring(d))
end

-- NEW APPROACH 2026-08-18: FindAllOf/FindFirstOf confirmed non-functional on
-- this port for ANY class (native or Blueprint, including the trivial class
-- 'Class' itself). Re-enabling OnHit for admingun confirmed a real crash
-- risk from hooking Blueprint-overridden natives. This avoids BOTH: a
-- direct line trace from the calling player's crosshair gets a real actor
-- reference synchronously, with zero FindAllOf and zero OnHit hook
-- involvement at all. Uses UEHelpers (bundled in Mods/shared/ with this
-- port) for KismetSystemLibrary access -- a standard, well-precedented
-- UE4SS pattern for other games, untested on this specific port until now.
local UEHelpers = require("UEHelpers")

local function traceForPalboxAtCrosshair(pc)
    local ksl = UEHelpers.GetKismetSystemLibrary()
    if not ksl or not ksl:IsValid() then
        logger.info("DESTROYBASE_DEBUG traceForPalbox: KismetSystemLibrary not valid")
        return nil
    end

    local camManager = pc.PlayerCameraManager
    if not camManager or not camManager:IsValid() then
        logger.info("DESTROYBASE_DEBUG traceForPalbox: PlayerCameraManager not valid")
        return nil
    end

    local camLocOk, camLoc = pcall(function() return camManager:GetCameraLocation() end)
    local camRotOk, camRot = pcall(function() return camManager:GetCameraRotation() end)
    if not camLocOk or not camRotOk then
        logger.info(string.format("DESTROYBASE_DEBUG traceForPalbox: camera loc/rot read failed (locOk=%s rotOk=%s)", tostring(camLocOk), tostring(camRotOk)))
        return nil
    end

    local TRACE_DISTANCE = 1500.0
    local yaw = math.rad(camRot.Yaw)
    local pitch = math.rad(camRot.Pitch)
    local forward = {
        X = math.cos(pitch) * math.cos(yaw),
        Y = math.cos(pitch) * math.sin(yaw),
        Z = math.sin(pitch),
    }
    local endPoint = {
        X = camLoc.X + forward.X * TRACE_DISTANCE,
        Y = camLoc.Y + forward.Y * TRACE_DISTANCE,
        Z = camLoc.Z + forward.Z * TRACE_DISTANCE,
    }

    -- TraceChannel 1 = ECC_Visibility (standard default); DrawDebugType 0 = none
    -- UE4SS Lua convention: 'Out' reference parameters (OutHit here) must be
    -- passed as a pre-existing table for the engine to write into -- passing
    -- nil (as the first attempt did) errors with "no table was on the
    -- stack". Declared outside the pcall so we can read it back afterward
    -- (Lua tables are references, so the engine's writes are visible here).
    local hitResult = {}
    local traceOk, didHit = pcall(function()
        return ksl:LineTraceSingle(pc, camLoc, endPoint, 1, false, {}, 0, hitResult, false,
            { R = 1, G = 0, B = 0, A = 1 }, { R = 0, G = 1, B = 0, A = 1 }, 0)
    end)
    if not traceOk then
        logger.info(string.format("DESTROYBASE_DEBUG traceForPalbox: LineTraceSingle errored: %s", tostring(didHit)))
        return nil
    end
    if not didHit then
        logger.info("DESTROYBASE_DEBUG traceForPalbox: trace found nothing in range")
        return nil
    end

    -- Palworld runs UE 5.1 -- HitResult.HitObjectHandle.Actor:Get() per the
    -- UE4SS version-branch convention (5.4+ uses ReferenceObject instead).
    local actorOk, actor = pcall(function() return hitResult.HitObjectHandle.Actor:Get() end)
    if not actorOk or not actor or not actor:IsValid() then
        logger.info(string.format("DESTROYBASE_DEBUG traceForPalbox: actor extraction failed ok=%s", tostring(actorOk)))
        return nil
    end

    local classOk, className = pcall(function() return actor:GetClass():GetFullName() end)
    logger.info(string.format("DESTROYBASE_DEBUG traceForPalbox: hit actor class = %s", tostring(classOk and className or "<unresolved>")))

    return actor
end

function commands.handleDestroyAtCrosshair(state)
    local pc = state:GetPlayerController()
    local actor = traceForPalboxAtCrosshair(pc)
    if not actor then
        utils.sendPersonalAnnounce(pc, "Nothing found at crosshair.")
        return
    end

    local isPalbox = false
    pcall(function() isPalbox = actor:IsA("/Script/Pal.PalBuildObjectBaseCampPoint") end)
    if not isPalbox then
        utils.sendPersonalAnnounce(pc, "That's not a palbox.")
        return
    end

    local campIdOk, campId = pcall(function() return actor:GetBaseCampIdBelongTo() end)
    if not campIdOk or not campId then
        utils.sendPersonalAnnounce(pc, "Could not resolve base camp ID from that palbox.")
        return
    end

    local disposeOk = pcall(function() actor:DisposeSelf_ServerInternal() end)
    local manager = getBaseCampManager()
    local dismantleOk = false
    if manager and manager:IsValid() then
        dismantleOk = pcall(function() manager:RequestDismantalDistanceBaseCamp(campId) end)
    end

    logger.info(string.format("DESTROYBASE_DEBUG traceForPalbox: disposeOk=%s dismantleOk=%s", tostring(disposeOk), tostring(dismantleOk)))

    if disposeOk then
        utils.sendPersonalAnnounce(pc, "Palbox destroyed via crosshair trace.")
        local playerName = utils.GetPlayerName(state)
        local playerUID = utils.GetPlayerId(state)
        logger.logCommand(playerName, playerUID, "destroyatcrosshair", "")
    else
        utils.sendPersonalAnnounce(pc, "Found the palbox but failed to destroy it.")
    end
end



local function destroyBaseCamp(pc, model)
    local manager = getBaseCampManager()
    if not manager then
        utils.sendPersonalAnnounce(pc, "BaseCampManager not found.")
        return false
    end

    local nameOk, campName = pcall(function() return model:GetBaseCampName():ToString() end)
    logger.info(string.format("DESTROYBASE_DEBUG campName ok=%s len=%s value=%q", tostring(nameOk), tostring(campName and #campName or "n/a"), tostring(campName)))
    local idOk, campId = pcall(function() return model:GetId() end)
    if not idOk or not campId then
        utils.sendPersonalAnnounce(pc, "Could not resolve base camp ID.")
        return false
    end

    -- FindAllOf-based physical lookup removed 2026-08-18 -- confirmed
    -- non-functional on this port for any class name tried. This function
    -- now only does what actually works: the manager-level dismantle.
    -- Physical removal is handled separately by handleDestroyAtCrosshair
    -- (line trace, no FindAllOf/OnHit involved).
    local destroyOk = pcall(function()
        manager:RequestDismantalDistanceBaseCamp(campId)
    end)

    if not destroyOk then
        utils.sendPersonalAnnounce(pc, "Failed to destroy base camp.")
        return false
    end

    local msg = "Destroyed base: " .. (nameOk and campName or "Unknown") .. " (aim at the palbox and use !destroyatcrosshair to remove the physical structure)"
    utils.sendPersonalAnnounce(pc, msg)
    return true
end

function commands.handleDestroyBase(state, rest)
    local pc = state:GetPlayerController()
    if not rest or rest == "" then
        utils.sendPersonalAnnounce(pc, "Usage: !destroybase <x,y,z>")
        return
    end

    local x, y, z = rest:match("^([%-%.%d]+)[,%s]+([%-%.%d]+)[,%s]+([%-%.%d]+)$")
    if not x then
        utils.sendPersonalAnnounce(pc, "Usage: !destroybase <x,y,z>")
        return
    end

    local manager = getBaseCampManager()
    if not manager then
        utils.sendPersonalAnnounce(pc, "BaseCampManager not found.")
        return
    end

    local location = { X = tonumber(x), Y = tonumber(y), Z = tonumber(z) }
    local ok, model = pcall(function() return manager:GetInRangedBaseCamp(location, DEFAULT_MARGIN) end)
    if not ok or not model or not model:IsValid() then
        utils.sendPersonalAnnounce(pc, "No base camp found near that location.")
        return
    end

    if destroyBaseCamp(pc, model) then
        local playerName = utils.GetPlayerName(state)
        local playerUID = utils.GetPlayerId(state)
        logger.logCommand(playerName, playerUID, "destroybase", rest)
    end
end

function commands.handleDestroyNearestBase(state)
    local pc = state:GetPlayerController()
    local char = pc.Pawn
    if not (char and char:IsValid()) then
        utils.sendPersonalAnnounce(pc, "Could not find your character.")
        return
    end

    local manager = getBaseCampManager()
    if not manager then
        utils.sendPersonalAnnounce(pc, "BaseCampManager not found.")
        return
    end

    local location = char:K2_GetActorLocation()
    local ok, model = pcall(function() return manager:GetNearestBaseCamp(location) end)
    if not ok or not model or not model:IsValid() then
        utils.sendPersonalAnnounce(pc, "No base camp found.")
        return
    end

    if destroyBaseCamp(pc, model) then
        local playerName = utils.GetPlayerName(state)
        local playerUID = utils.GetPlayerId(state)
        logger.logCommand(playerName, playerUID, "destroynearestbase", "")
    end
end

local adminGunEnabled = {}

function commands.handleAdminGun(state, rest)
    local pc = state:GetPlayerController()
    local uid = utils.GetPlayerId(state)
    if not uid then return end

    if rest and rest:lower() == "on" then
        adminGunEnabled[uid] = true
        utils.sendPersonalAnnounce(pc, "Admin Gun: ON - Shoot any Palbox to destroy it.")
    elseif rest and rest:lower() == "off" then
        adminGunEnabled[uid] = nil
        utils.sendPersonalAnnounce(pc, "Admin Gun: OFF")
    else
        if adminGunEnabled[uid] then
            adminGunEnabled[uid] = nil
            utils.sendPersonalAnnounce(pc, "Admin Gun: OFF")
        else
            adminGunEnabled[uid] = true
            utils.sendPersonalAnnounce(pc, "Admin Gun: ON - Shoot any Palbox to destroy it.")
        end
    end
end

function commands.onBulletHit(ctx, hitComp, otherActor, otherComp, hit)
    local bullet = ctx:get()
    if not bullet or not bullet:IsValid() then return end

    local hitActor = nil
    if otherActor then
        hitActor = otherActor:get()
    end
    if not hitActor or not hitActor:IsValid() then return end

    local isPalbox = false
    pcall(function() isPalbox = hitActor:IsA("/Script/Pal.PalBuildObjectBaseCampPoint") end)
    if not isPalbox then return end

    local controller = nil
    pcall(function() controller = bullet:GetInstigatorController() end)
    if not controller or not controller:IsValid() then
        local instigator = nil
        pcall(function() instigator = bullet:GetInstigator() end)
        if instigator and instigator:IsValid() then
            if instigator:IsA("/Script/Engine.PlayerController") then
                controller = instigator
            elseif instigator:IsA("/Script/Engine.Pawn") then
                pcall(function() controller = instigator:GetController() end)
            end
        end
    end
    if not controller or not controller:IsValid() then
        local owner = nil
        pcall(function() owner = bullet:GetOwner() end)
        if owner and owner:IsValid() then
            if owner:IsA("/Script/Engine.PlayerController") then
                controller = owner
            elseif owner:IsA("/Script/Engine.Pawn") then
                pcall(function() controller = owner:GetController() end)
            else
                pcall(function()
                    local ownerOwner = owner:GetOwner()
                    if ownerOwner and ownerOwner:IsValid() then
                        if ownerOwner:IsA("/Script/Engine.PlayerController") then
                            controller = ownerOwner
                        elseif ownerOwner:IsA("/Script/Engine.Pawn") then
                            controller = ownerOwner:GetController()
                        end
                    end
                end)
            end
        end
    end
    if not controller or not controller:IsValid() then return end

    local playerState = controller.PlayerState
    if not playerState or not playerState:IsValid() then return end

    local uid = utils.GetPlayerId(playerState)
    if not utils.IsPlayerAdmin(playerState) then return end
    if not adminGunEnabled[uid] then return end

    local campIdOk, campId = pcall(function() return hitActor:GetBaseCampIdBelongTo() end)
    if campIdOk and campId then
        pcall(function() hitActor:DisposeSelf_ServerInternal() end)

        local manager = getBaseCampManager()
        if manager and manager:IsValid() then
            pcall(function() manager:RequestDismantalDistanceBaseCamp(campId) end)
        end

        local playerName = utils.GetPlayerName(playerState)
        local playerUID = utils.GetPlayerId(playerState)
        logger.logCommand(playerName, playerUID, "admingun", "destroyed palbox")

        utils.sendPersonalAnnounce(controller, "Palbox destroyed via Admin Gun.")
    end
end

return commands

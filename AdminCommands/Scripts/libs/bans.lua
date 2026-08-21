local Json = require("libs/Json")
local bans = {}

local ModDirectory = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]]):match("^(.+[/\\])[^/\\]+[/\\]$")
local BansFile = ModDirectory .. "config/bans.json"
local BANS = BANS or {}

local function loadBans()
	local f = io.open(BansFile, "r")
	if f then
		local s = f:read("*a") or ""
		f:close()
		local ok, data = pcall(Json.decode, s)
		if ok and type(data) == "table" then
			BANS = data
		end
	end
end

local function saveBans()
	local f = io.open(BansFile, "w")
	if f then
		f:write(Json.encode(BANS))
		f:close()
	end
end

loadBans()

function bans.isUidBanned(uid)
	return uid and BANS[uid] ~= nil
end

function bans.banUid(uid, name, reason)
	if not uid or uid == "" then return false end
	BANS[uid] = { name = name or uid, uid = uid, reason = reason or "" }
	saveBans()
	return true
end

function bans.unbanUid(uid)
	if not uid or uid == "" then return false end
	if not BANS[uid] then return false end
	BANS[uid] = nil
	saveBans()
	return true
end

function bans.getBans()
	return BANS
end

-- Returns a list of {uid=, name=, reason=} entries whose recorded name
-- matches (case-insensitive). Ban records already store name alongside UID
-- (see banUid above), so this needs no extra data -- just search what's
-- already persisted. Supports !unban <name> as an alternative to
-- !unban <UID>, since a banned player can't be looked up live (they're not
-- connected), UID is the only thing that's ever unambiguous.
function bans.findByName(name)
	if not name or name == "" then return {} end
	local lowerName = name:lower()
	local matches = {}
	for uid, entry in pairs(BANS) do
		if entry.name and entry.name:lower() == lowerName then
			table.insert(matches, entry)
		end
	end
	return matches
end

return bans

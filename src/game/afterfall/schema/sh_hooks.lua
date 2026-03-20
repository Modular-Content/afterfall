--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

function Schema:GetFemaleCitizenModels() end
function Schema:GetMaleCitizenModels() end

do
	---@class Weapon
	local weaponMeta = FindMetaTable 'Weapon'
	_SetNextPrimaryFire = _SetNextPrimaryFire or weaponMeta.SetNextPrimaryFire
	_GetNextPrimaryFire = _GetNextPrimaryFire or weaponMeta.GetNextPrimaryFire
	local customFireDelay = {}
	function weaponMeta:SetNextPrimaryFire(t)
		_SetNextPrimaryFire(self, t)
		if self:GetClass() ~= 'weapon_pistol' then return end
		customFireDelay[self] = t
	end
	function weaponMeta:GetNextPrimaryFire()
		local base = _GetNextPrimaryFire(self)
		if self:GetClass() ~= 'weapon_pistol' then return base end
		local stored = customFireDelay[self]
		if stored then return math.max(base, stored) end
		return base
	end
	hook.Add('EntityRemoved', 'Afterfall.CleanupFireDelay', function(ent) if customFireDelay[ent] then customFireDelay[ent] = nil end end)
	local cwPlayer = ClockworkLite.player
	function ClockworkLite:StartCommand(ply, cmd)
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) then return end
		if wep:GetClass() ~= 'weapon_pistol' then return end
		local now = CurTime()
		local nextShootTime = SERVER and ply.cwNextShootTime or ply:GetNetVar('NextShootTime', 0)
		if nextShootTime and now < nextShootTime then cmd:RemoveKey(IN_ATTACK) return end
		local nextFire = customFireDelay[wep]
		if nextFire and now < nextFire then cmd:RemoveKey(IN_ATTACK) return end
		if not cwPlayer:GetWeaponRaised(ply, true) then cmd:RemoveKey(IN_ATTACK) return end
	end
end
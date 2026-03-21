--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

---@class preCL
preCL = preCL or {}
function preCL:AddStunEffect(s)
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	ply.stunned, ply.stun, ply.stunNow = true, math.max(s, 2), s + CurTime()
end

function preCL:AddStunEffect(s)
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	ply.stunned, ply.stun, ply.stunNow = true, math.max(s, 2), s + CurTime()
end

local playerMeta = FindMetaTable 'Player'

function playerMeta:AddStunEffect(s) preCL:AddStunEffect(s) end

timer.Simple(0, function()
	netstream.Hook('preload.Stun', function(s)
		preCL:AddStunEffect(s)
	end)

	netstream.Hook('preload.ClearImpact', function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		ply.stunned, ply.stun, ply.stunNow = nil, nil, nil
	end)
end)
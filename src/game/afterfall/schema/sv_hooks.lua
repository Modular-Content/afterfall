--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

function Schema:PlayerTakeDamage(ply)
	if ply:Armor() <= 0 then netstream.Start(ply, 'preload.Stun', ply:Health() > 50 and 0.5 or 1) end
end
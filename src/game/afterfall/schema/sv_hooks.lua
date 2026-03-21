--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

function Schema:PlayerTakeDamage(ply)
	if ply:Armor() <= 0 then netstream.Start(ply, 'preload.Stun', ply:Health() > 50 and 0.5 or 1) end
end

CFG.marksTemplates = {}
local templateCombine = '<:: %s ::>'

function Schema:AddSpeakerMarks(ply, text, class)
	if CFG.marksTemplates[class] then text = CFG.marksTemplates[class]:format(text) end
	if ply:IsCombine() and ply:IsMasked() then text = templateCombine:format(text) end
	return text
end
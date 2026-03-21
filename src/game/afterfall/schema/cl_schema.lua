--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

Schema.combineOverlay = Material('effects/combine_binocoverlay')

local ClockworkLite = ClockworkLite
local cwlConfig = ClockworkLite.config

cwlConfig:AddToSystem('Big intro text', 'intro_text_big', 'The big text displayed for the introduction.')
cwlConfig:AddToSystem('Small intro text', 'intro_text_small', 'The small text displayed for the introduction. (Supports %d for the current year.)')

function Schema:PlayerIsCombine(ply, humanOnly)
    if not IsValid(ply) then return end
    local faction = ply:GetFaction()
    if not self:IsCombineFaction(faction) then return end
    if humanOnly == nil then return true end
    local isMPF = faction == FACTION_MPF
    if humanOnly then return isMPF else return not isMPF end
end
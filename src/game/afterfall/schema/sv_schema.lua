--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlConfig = ClockworkLite.config

cwlConfig:Add('intro_text_big', 'Индустриальный сектор Сити 17', true)
cwlConfig:Add('intro_text_small', '%d-й год, до событий Half-Life 2', true)

function Schema:PlayerIsCombine(ply, humanOnly)
    if not (IsValid(ply) and ply:GetCharacter()) then return end
    local faction = ply:GetFaction()
    if not self:IsCombineFaction(faction) then return end
    if humanOnly == nil then return true end
    local isMPF = faction == FACTION_MPF
    if humanOnly then return isMPF else return not isMPF end
end
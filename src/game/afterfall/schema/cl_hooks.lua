--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlConfig = ClockworkLite.config

function Schema:GetCinematicIntroInfo()
	local smallText = cwlConfig:Get('intro_text_small'):Get()
	if smallText:find '%%d' then smallText = smallText:format(os.date('%Y')) end
	return {credits = 'Разработчики сервера: Modular Content', title = cwlConfig:Get('intro_text_big'):Get(), text = smallText}
end
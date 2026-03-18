--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

function Schema:GetCinematicIntroInfo()
	return {
		credits = 'Разработчики сервера: Modular Content',
		title = Clockwork.config:Get('intro_text_big'):Get(),
		text = Clockwork.config:Get('intro_text_small'):Get(),
	}
end
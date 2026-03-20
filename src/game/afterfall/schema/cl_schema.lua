--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlConfig = ClockworkLite.config

cwlConfig:AddToSystem('Big intro text', 'intro_text_big', 'The big text displayed for the introduction.')
cwlConfig:AddToSystem('Small intro text', 'intro_text_small', 'The small text displayed for the introduction. (Supports %d for the current year.)')
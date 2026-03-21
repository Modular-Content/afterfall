--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlClass = ClockworkLite.class
local Color = Color

local CLASS = cwlClass:New('Секретный агент')
CLASS.color = Color(255, 0, 0)
CLASS.ownFaction = FACTION_INCOG
CLASS.isDefault = true
CLASS.description = 'Никто не знает, кто эти люди и откуда они взялись. Они появляются из ниоткуда, выполняют свои задачи и так же бесследно исчезают.'
CLASS_INCOG = CLASS:Register()
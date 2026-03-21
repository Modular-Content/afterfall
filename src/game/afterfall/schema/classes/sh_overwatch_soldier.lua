--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlClass = ClockworkLite.class
local Color = Color

local CLASS = cwlClass:New('Overwatch Soldier')
CLASS.color = Color(150, 50, 50)
CLASS.wages = 35
CLASS.ownFaction = FACTION_OTA
CLASS.isDefault = true
CLASS.wagesName = 'Денежное довольствие'
CLASS.description = 'Обычный солдат Overwatch, выполняющий приказы Альянса и поддерживающий порядок в гражданских или запретных секторах.'
CLASS_OWS = CLASS:Register()
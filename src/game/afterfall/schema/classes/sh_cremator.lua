--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlClass = ClockworkLite.class
local Color = Color

local CLASS = cwlClass:New('Крематор')
CLASS.color = Color(150, 125, 100)
CLASS.ownFaction = FACTION_CREMATOR
CLASS.isDefault = true
CLASS.description = 'Синтет созданный для выполнения задач по уничтожению тел и биологических отходов.'
CLASS_CREMATOR = CLASS:Register()
--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlClass = ClockworkLite.class
local Color = Color

local CLASS = cwlClass:New('Metropolice Recruit')
CLASS.color = Color(50, 100, 150)
CLASS.wages = 25
CLASS.ownFaction = FACTION_MPF
CLASS.wagesName = 'Денежное довольствие'
CLASS.description = 'Рекрут Гражданской Обороны, который только что закончил обучение и готов приступить к службе.'
CLASS_MPR = CLASS:Register()
--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlClass = ClockworkLite.class
local Color = Color

local CLASS = cwlClass:New('Metropolice Unit')
CLASS.color = Color(50, 100, 150)
CLASS.wages = 35
CLASS.ownFaction = FACTION_MPF
CLASS.isDefault = true
CLASS.wagesName = 'Денежное довольствие'
CLASS.description = 'Стандартный юнит Гражданской Обороны, который выполняет патрулирование и поддержание порядка в городах Альянса.'
CLASS_MPU = CLASS:Register()
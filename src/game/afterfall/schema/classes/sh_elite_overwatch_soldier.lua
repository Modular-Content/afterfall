--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlClass = ClockworkLite.class
local Color = Color

local CLASS = cwlClass:New('Elite Overwatch Soldier')
CLASS.color = Color(150, 50, 50)
CLASS.wages = 50
CLASS.ownFaction = FACTION_OTA
CLASS.wagesName = 'Денежное довольствие'
CLASS.description = 'Элитный солдат Overwatch, который прошел через множество боевых операций и доказал свою преданность Альянсу. Они выполняют самые опасные и важные задания, требующие максимальной эффективности и профессионализма.'
CLASS_EOW = CLASS:Register()
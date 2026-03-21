--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlClass = ClockworkLite.class
local Color = Color

local CLASS = cwlClass:New('Гражданин')
CLASS.color = Color(150, 125, 100)
CLASS.ownFaction = FACTION_CITIZEN
CLASS.isDefault = true
CLASS.description = 'Обычный гражданин, живущий по правилам и законам Альянса.'
CLASS_CITIZEN = CLASS:Register()
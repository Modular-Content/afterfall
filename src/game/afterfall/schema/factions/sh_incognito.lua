--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlFaction = ClockworkLite.faction

local FACTION = cwlFaction:New(FACTION_OTA)
FACTION.useFullName = false
FACTION.maximumAttributePoints = 700
FACTION.whitelist = true
FACTION.material = ''
FACTION.team = 2
FACTION.color = Color(255, 0, 0)
FACTION:Register()
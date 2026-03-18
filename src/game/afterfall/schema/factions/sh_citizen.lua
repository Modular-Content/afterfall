--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local Clockwork = Clockwork
local cwFaction = Clockwork.faction

local FACTION = cwFaction:New(FACTION_CITIZEN)
FACTION.useFullName = false
FACTION.material = ''
FACTION.team = 1
FACTION:Register()
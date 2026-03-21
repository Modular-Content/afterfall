--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlFaction = ClockworkLite.faction
local cwlKernel = ClockworkLite.kernel

local FACTION = cwlFaction:New(FACTION_CREMATOR)
FACTION.whitelist = true
FACTION.singleGender = 'male'
FACTION.maximumAttributePoints = 130
FACTION.material = ''
-- FACTION.models = {
-- 	female = {'models/afterfall/cremator.mdl'},
-- 	male = {'models/afterfall/cremator.mdl'},
-- }
FACTION.voPreview = function() return 'npc/metropolice/vo/pickupthecan' .. math.random(1, 3).. '.wav' end
FACTION.team = 2
FACTION.color = Color(150, 125, 100)
function FACTION:GetName() return 'C17.SYNTH.CREMATOR:' .. cwlKernel:ZeroNumberToDigits(math.random(1, 99999), 5) end
FACTION:Register()
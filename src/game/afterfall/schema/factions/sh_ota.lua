--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

local ClockworkLite = ClockworkLite
local cwlFaction = ClockworkLite.faction
local cwlKernel = ClockworkLite.kernel

local FACTION = cwlFaction:New(FACTION_OTA)
FACTION.whitelist = true
FACTION.singleGender = 'male'
FACTION.maximumAttributePoints = 80
FACTION.material = ''
FACTION.models = {
	female = {'models/combine_soldier.mdl'},
	male = {'models/combine_soldier.mdl'},
}
FACTION.voPreview = function() return 'npc/metropolice/vo/pickupthecan' .. math.random(1, 3).. '.wav' end
FACTION.team = 2
FACTION.color = Color(150, 50, 50)
function FACTION:GetName() return 'C17.OTA.ECHO.OWS:' .. cwlKernel:ZeroNumberToDigits(math.random(1, 99999), 5) end
function FACTION:TransferData(_, n, g)
    local pool = self.models[g]
    local chosenModel = pool[math.random(#pool)]
    local hasTag = string.match(n or '', 'C17%..+:(%w+)')
    if hasTag then return {model = chosenModel} end
    return {name = self:GetName(), model = chosenModel}
end
FACTION:Register()
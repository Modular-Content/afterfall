--[[
	© 2026 Modular Content do not share, re-distribute or modify
	without permission of its author (admin@modularcontent.dev).
--]]

hook.Add('CanArmDupe', 'ClockworkLite', function() return false end)

---@class Player
local playerMeta = FindMetaTable 'Player'

function playerMeta:IsFemale() return self:GetGender() == GENDER_FEMALE end
function playerMeta:IsMale() return self:GetGender() == GENDER_MALE end
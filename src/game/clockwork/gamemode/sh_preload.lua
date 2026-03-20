hook.Add('CanArmDupe', 'ClockworkLite', function()
	return false
end)

---@class Player
local playerMeta = FindMetaTable 'Player'
function playerMeta:IsFemale() return self:GetGender() == GENDER_FEMALE end
function playerMeta:IsMale() return self:GetGender() == GENDER_MALE end
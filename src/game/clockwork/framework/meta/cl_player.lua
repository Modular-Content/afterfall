local cwFaction = Clockwork.faction
local cwPly = Clockwork.player

---@class Player
local playerMeta = FindMetaTable("Player")
_Nick = _Nick or playerMeta.Nick
_SetDSP = _SetDSP or playerMeta.SetDSP

local DSP = 0
function playerMeta:SetDSP(dsp, fastReset)
	DSP = dsp
	_SetDSP(self, dsp, fastReset)
end

function playerMeta:GetDSP()
	return DSP
end

local nickCache = {}
function playerMeta:SteamName()
	local nick = _Nick(self)
	local safeNick = nickCache[nick]
	if not safeNick then
		safeNick = utf8.fixUTF8(nick)
		nickCache[nick] = safeNick
	end
	return safeNick
end

-- A function to get a player's name.
function playerMeta:Name()
	local name = self:GetNetVar("Name")

	if not name or name == "" then
		return self:SteamName()
	else
		return name
	end
end

-- A function to get a player's playback rate.
function playerMeta:GetPlaybackRate()
	return self.cwPlaybackRate or 1
end

-- A function to get whether a player is noclipping.
function playerMeta:IsNoClipping()
	return cwPly:IsNoClipping(self)
end

-- A function to get whether a player is running.
function playerMeta:IsRunning(bNoWalkSpeed)
	if self:Alive() and not self:IsRagdolled() and not self:InVehicle() and not self:Crouching() and self:GetNetVar("IsRunMode") then
		if self:GetVelocity():Length() >= self:GetWalkSpeed() or bNoWalkSpeed then return true end
	end

	return false
end

-- A function to get a player's forced animation.
function playerMeta:GetForcedAnimation()
	local forcedAnimation = self:GetNetVar("ForceAnim")

	if forcedAnimation ~= 0 then
		return {
			animation = forcedAnimation,
		}
	end
end

netstream.Hook("ForcedAnimResetCycle", function(data)
	if not (IsValid(data.player) and data.player:IsPlayer()) then return end
	data.player:SetCycle(0)
end)

-- A function to get whether a player is ragdolled.
function playerMeta:IsRagdolled(exception, entityless)
	return cwPly:IsRagdolled(self, exception, entityless)
end

-- A function to get whether a player has a trait.
function playerMeta:HasTrait(uniqueID)
	return self.cwTraits and table.HasValue(self.cwTraits, uniqueID)
end

-- A function to get whether a player has initialized.
function playerMeta:HasInitialized()
	if IsValid(self) then return self:GetNetVar("Initialized") end
end

-- A function to get a player's gender.
function playerMeta:GetGender()
	local genderEnum = self:GetNetVar("Gender")

	if genderEnum == 1 then
		return GENDER_FEMALE
	elseif genderEnum == 2 then
		return GENDER_MALE
	else
		return GENDER_NONE
	end
end

function playerMeta:GetPronouns()
	local gender = self:GetGender()
	local pronoun = "It"
	local thirdperson = "It"

	if gender == GENDER_FEMALE then
		pronoun = "She"
		thirdperson = "Her"
	elseif gender == GENDER_MALE then
		pronoun = "He"
		thirdperson = "Him"
	end

	return pronoun, thirdperson
end

-- A function to get a player's faction.
function playerMeta:GetFaction()
	local index = self:GetNetVar("Faction")

	if cwFaction:FindByID(index) then
		return cwFaction:FindByID(index).name
	else
		return "Unknown"
	end
end

-- A function to get a player's wages name.
function playerMeta:GetWagesName()
	return cwPly:GetWagesName(self)
end

-- A function to get a player's data.
function playerMeta:GetData(key, default)
	local playerData = cwPly.playerData[key]
	if playerData and (not playerData.playerOnly or self == Clockwork.Client) then return self:GetNetVar(key) end

	return default
end

-- A function to get a player's character data.
function playerMeta:GetCharacterData(key, default)
	local characterData = cwPly.characterData[key]
	if characterData and (not characterData.playerOnly or self == Clockwork.Client) then return self:GetNetVar(key) end

	return default
end

-- A function to get a player's maximum armor.
function playerMeta:GetMaxArmor(armor)
	local maxArmor = self:GetNetVar("MaxAP", 0)

	if maxArmor > 0 then
		return maxArmor
	else
		return 100
	end
end

-- A function to get a player's maximum health.
function playerMeta:GetMaxHealth(health)
	local maxHealth = self:GetNetVar("MaxHP", 0)

	if maxHealth > 0 then
		return maxHealth
	else
		return 100
	end
end

-- A function to get a player's ragdoll state.
function playerMeta:GetRagdollState()
	return cwPly:GetRagdollState(self)
end

-- A function to get a player's ragdoll entity.
function playerMeta:GetRagdollEntity()
	return cwPly:GetRagdollEntity(self)
end

-- A function to get a player's rank within their faction.
function playerMeta:GetFactionRank(character)
	return cwPly:GetFactionRank(self, character)
end

-- A function to get a player's chat icon.
function playerMeta:GetChatIcon()
	return cwPly:GetChatIcon(self)
end

playerMeta.GetName = playerMeta.Name
playerMeta.Nick = playerMeta.Name

function playerMeta:GetTeamClass()
	local class = self:GetNetVar('TeamClass', CLASS_CITIZEN)
	return Clockwork.class:FindByID(class)
end
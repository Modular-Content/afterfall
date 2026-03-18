
-- Called when the top text is needed.
function cwPickupObjects:GetScreenTextInfo()
	local blackFadeAlpha = Clockwork.kernel:GetBlackFadeAlpha()
	local ply = Clockwork.Client
	local beingDragged = ply:GetNetVar('IsDragged')
	if ply:IsRagdolled() and beingDragged then
		return {
			alpha = 255 - blackFadeAlpha,
			title = "ВАС ТАЩАТ..."
		}
	end
end

-- Called when the local player attempts to get up.
function cwPickupObjects:PlayerCanGetUp()
	local ply = Clockwork.Client
	local beingDragged = ply:GetNetVar('IsDragged')
	if beingDragged then return false end
end

-- Called when a Scripted Weapon (SWEP) is about to be registered.
function cwPickupObjects:PreRegisterSWEP(swep, class)
	if class == 'cw_hands' then
		swep.Instructions = 'Reload: Drop\n' .. swep.Instructions
		swep.Instructions = Clockwork.kernel:Replace(swep.Instructions, 'Knock.', 'Knock/Pickup.')
		swep.Instructions = Clockwork.kernel:Replace(swep.Instructions, 'Punch.', 'Punch/Throw.')
	end
end
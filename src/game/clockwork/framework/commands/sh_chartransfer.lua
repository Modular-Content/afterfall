local COMMAND = Clockwork.command:New("CharTransfer")

COMMAND.tip = "CmdCharTransfer"
COMMAND.text = "CmdCharTransferDesc"
COMMAND.access = "o"
COMMAND.arguments = 2
COMMAND.optionalArguments = 1

-- Called when the command has been run.
function COMMAND:OnRun(player, arguments)
	local target = Clockwork.player:FindByID(arguments[1])

	if target then
		local faction = arguments[2]
		local name = target:Name()

		if not Clockwork.faction.stored[faction] then
			Clockwork.player:Notify(player, {"FactionIsNotValid", faction})

			return
		end

		if not Clockwork.faction.stored[faction].whitelist or Clockwork.player:IsWhitelisted(target, faction) then
			local targetFaction = target:GetFaction()

			if targetFaction == faction then
				Clockwork.player:Notify(player, {"PlayerAlreadyIsFaction", target:Name(), faction})

				return
			end

			if not Clockwork.faction:IsGenderValid(faction, target:GetGender()) then
				Clockwork.player:Notify(player, {"PlayerNotCorrectGenderForFaction", target:Name(), faction})

				return
			end

			local wasSuccess, fault
			if not Clockwork.faction.stored[faction].OnTransferred then
				if Clockwork.faction.stored[faction].TransferData then
					local gender = target:GetGender()
					local res = Clockwork.faction.stored[faction]:TransferData(faction, name, gender)
					if res then
						ClockworkLite.player:SetName(target, res.name)
						target:SetCharacterData('model', res.model, true)
						target:SetModel(res.model)
					end
					wasSuccess, fault = true, nil
					goto transferDone
				end
				Clockwork.player:Notify(player, {"PlayerCannotTransferToFaction", target:Name(), faction})

				return
			end

			if not wasSuccess then
				wasSuccess, fault = Clockwork.faction.stored[faction]:OnTransferred(target, Clockwork.faction.stored[targetFaction], arguments[3])
			end

			::transferDone::
			if wasSuccess ~= false then
				target:SetCharacterData("Faction", faction, true)
				Clockwork.player:LoadCharacter(target, Clockwork.player:GetCharacterID(target))

				Clockwork.player:NotifyAll({"PlayerTransferredPlayer", player:Name(), name, faction})
			else
				Clockwork.player:Notify(player, fault or {"PlayerCouldNotBeTransferred", target:Name(), faction})
			end
		else
			Clockwork.player:Notify(player, {"PlayerNotOnFactionWhitelist", target:Name(), faction})
		end
	else
		Clockwork.player:Notify(player, {"NotValidPlayer", arguments[1]})
	end
end

COMMAND:Register()

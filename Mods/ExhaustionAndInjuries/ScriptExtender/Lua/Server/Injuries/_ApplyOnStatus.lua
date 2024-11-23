Ext.Vars.RegisterUserVariable("Injuries_ApplyOnStatus", {
	Server = true,
	Client = true,
	SyncToClient = true,
	SyncOnWrite = true -- if this is false, the injuryReport lags by 1 calculation
})

local function processInjuries(character, statusConfig, numberOfRounds)
	local eligibleGroups = ConfigManager.ConfigCopy.injuries.universal.who_can_receive_injuries
	if (eligibleGroups["Allies"] and Osi.IsAlly(Osi.GetHostCharacter(), character) == 1)
		or (eligibleGroups["Party Members"] and Osi.IsPartyMember(character, 1) == 1)
		or (eligibleGroups["Enemies"] and Osi.IsEnemy(Osi.GetHostCharacter(), character) == 1)
	then
		for injury, injuryStatusConfig in pairs(statusConfig) do
			if Osi.HasActiveStatus(character, injury) == 0 then
				if injuryStatusConfig["number_of_rounds"] == numberOfRounds then
					Osi.ApplyStatus(character, injury, -1)
				end
			end
		end
	end
end

EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
	local statusConfig = ConfigManager.Injuries.ApplyOnStatus[status]
	if statusConfig then
		local entity = Ext.Entity.Get(character)

		local statusVar = entity.Vars.Injuries_ApplyOnStatus or {}
		statusVar[status] = 1

		processInjuries(character, statusConfig, statusVar[status])

		if ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset ~= "Attack/Tick" then
			entity.Vars.Injuries_ApplyOnStatus = statusVar
			if ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Round" and Osi.IsInCombat(character) == 0 then
				Ext.Timer.WaitFor(6000, function()
					entity.Vars.Injuries_ApplyOnStatus = nil
				end)
			end
		else
			entity.Vars.Injuries_ApplyOnStatus = nil
		end
	end
end)

EventCoordinator:RegisterEventProcessor("CombatRoundStarted", function(combatGuid, round)
	for _, combatParticipant in pairs(Osi.DB_Is_InCombat:Get(nil, combatGuid)) do
		local entity = Ext.Entity.Get(combatParticipant[1])
		if entity.Vars.Injuries_ApplyOnStatus then
			if ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Round" then
				entity.Vars.Injuries_ApplyOnStatus = nil
			else
				for status, numberOfRounds in pairs(entity.Vars.Injuries_ApplyOnStatus) do
					if Osi.HasActiveStatus(combatParticipant[1], status) == 1 then
						numberOfRounds = numberOfRounds + 1
						entity.Vars.Injuries_ApplyOnStatus[status] = numberOfRounds

						processInjuries(combatParticipant[1], ConfigManager.Injuries.ApplyOnStatus[status], numberOfRounds)
					end
				end
			end
		end
	end
end)

EventCoordinator:RegisterEventProcessor("LeftCombat", function(char, guid)
	if Ext.Entity.Get(char).Vars.Injuries_ApplyOnStatus and ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Combat" then
		Ext.Entity.Get(char).Vars.Injuries_ApplyOnStatus = nil
	end
end)

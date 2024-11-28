EventCoordinator:RegisterEventProcessor("StatusApplied", function (character, status, causee, storyActionID)
	local characterEntity = Ext.Entity.Get(character)

	local statusConfig = ConfigManager.Injuries.RemoveOnStatus[status]
	if statusConfig then
		---@type {[InjuryName] : InjuryRemoveOnStatus}
		local injuriesToRemove = {}
		for injury, injuryConfig in pairs(statusConfig) do
			if Osi.HasActiveStatus(character, injury) == 1 then
				injuriesToRemove[injury] = injuryConfig
			end
		end

		if ConfigManager.ConfigCopy.injuries.universal.how_many_injuries_can_be_removed_at_once == "All" then
			for injuryToRemove, injuryConfig in pairs(injuriesToRemove) do
				if injuryConfig["ability"] == "No Save" or injuryConfig["ability"] == "None" then
					Osi.RemoveStatus(character, injuryToRemove)
				else

				end
			end
		end
	end
end)

local function clearInjuryVar(character, injuryName)
	local entity, injuryVar = InjuryConfigHelper:GetUserVar(character)

	for _, injuryTable in pairs(injuryVar["damage"]) do
		injuryTable[injuryName] = nil
	end

	for _, injuryTable in pairs(injuryVar["applyOnStatus"]) do
		injuryTable[injuryName] = nil
	end

	InjuryConfigHelper:UpdateUserVar(entity, injuryVar)
end

---@param character GUIDSTRING
---@param injury InjuryName
---@param injuryConfig InjuryRemoveOnStatus
local function removeInjury(character, injury, injuryConfig)
	if injuryConfig["ability"] == "No Save" or injuryConfig["ability"] == "None" then
		Osi.RemoveStatus(character, injury)
		clearInjuryVar(character, injury)
	else
		Osi.RequestPassiveRoll(character,
			character,
			"SavingThrowRoll",
			injuryConfig["ability"],
			DifficultyClassMap[injuryConfig["difficulty_class"]],
			0,
			"Goon_Injuries_Remove_Injury_" .. injury)
	end
end

EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
	local statusConfig = ConfigManager.Injuries.RemoveOnStatus[status]
	if statusConfig then
		---@type {[InjuryName] : InjuryRemoveOnStatus}
		local injuriesToRemove = {}
		for injury, injuryConfig in pairs(statusConfig) do
			if Osi.HasActiveStatus(character, injury) == 1 then
				injuriesToRemove[injury] = injuryConfig
			end
		end

		local numInjuriesToRemove = ConfigManager.ConfigCopy.injuries.universal.how_many_injuries_can_be_removed_at_once
		if numInjuriesToRemove == "All" then
			for injuryToRemove, injuryConfig in pairs(injuriesToRemove) do
				removeInjury(character, injuryToRemove, injuryConfig)
			end
		elseif numInjuriesToRemove == "One" then
			local indexedTable = {}

			local injuryRemovalStrat = ConfigManager.ConfigCopy.injuries.universal.injury_removal_severity_priority
			if injuryRemovalStrat == "Random" then
				for injury, _ in pairs(injuriesToRemove) do
					table.insert(indexedTable, injury)
				end
			elseif injuryRemovalStrat == "Most Severe" then
				indexedTable = {}

				---@type severity?
				local highestSeverity

				for injury, _ in pairs(injuriesToRemove) do
					local severity = ConfigManager.ConfigCopy.injuries.injury_specific[injury].severity
					if not highestSeverity then
						highestSeverity = severity
						table.insert(indexedTable, injury)
					else
						if severity == highestSeverity then
							table.insert(indexedTable, injury)
						else
							if severity == "High" or (severity == "Medium" and highestSeverity == "Low") then
								indexedTable = { injury }
								highestSeverity = severity
							end
						end
					end
				end
			end
			local injuryToRemove = indexedTable[Osi.Random(#indexedTable) + 1]

			removeInjury(character, injuryToRemove, injuriesToRemove[injuryToRemove])
		end
	end
end)

EventCoordinator:RegisterEventProcessor("RollResult", function(eventName, roller, rollSubject, resultType, isActiveRoll, criticality)
	if string.find(eventName, "Goon_Injuries_Remove_Injury_") then
		local injuryName = string.sub(eventName, string.len("Goon_Injuries_Remove_Injury_"))

		if resultType == 1 then
			Osi.RemoveStatus(roller, injuryName)

			clearInjuryVar(roller, injuryName)
		end
	end
end)

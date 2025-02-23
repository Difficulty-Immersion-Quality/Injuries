---@param character GUIDSTRING
---@param injury InjuryName
---@param injuryConfig InjuryRemoveOnStatus
---@param statusCausingRemoval string
local function removeInjury(character, injury, injuryConfig, statusCausingRemoval)
	if injuryConfig["ability"] == "No Save" or injuryConfig["ability"] == "None" then
		local entity, injuryVar = InjuryConfigHelper:GetUserVar(character)
		injuryVar["removedDueTo"] = injuryVar["removedDueTo"] or {}
		injuryVar["removedDueTo"][injury] = statusCausingRemoval
		InjuryConfigHelper:UpdateUserVar(entity, injuryVar)

		Osi.RemoveStatus(character, injury)
	else
		Osi.RequestPassiveRoll(character,
			character,
			"SavingThrowRoll",
			injuryConfig["ability"],
			DifficultyClassMap[injuryConfig["difficulty_class"]],
			0,
			"Goon_Injuries_Remove_Injury_" .. injury .. "|" .. statusCausingRemoval)
	end
end

EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
	if status == "LONG_REST" and ConfigManager.ConfigCopy.injuries.universal.remove_all_on_long_rest then
		InjuryConfigHelper:RemoveAllInjuries(character)
		return
	end

	local statusConfig = ConfigManager.Injuries.RemoveOnStatus[status]
	if not statusConfig then
		---@type StatusData
		local statusData = Ext.Stats.Get(status)
		if not statusData then
			Logger:BasicWarning("Status %s does not exist in the game?", status)
		else
			if statusData.StatusGroups and next(statusData.StatusGroups) then
				for _, statusGroup in ipairs(statusData.StatusGroups) do
					if ConfigManager.Injuries.RemoveOnStatus[statusGroup] then
						statusConfig = ConfigManager.Injuries.RemoveOnStatus[statusGroup]
						break
					end
				end
			end
		end
	end
	if statusConfig then
		---@type {[InjuryName] : InjuryRemoveOnStatus}
		local injuriesToRemove = {}
		for injury, injuryConfig in pairs(statusConfig) do
			if not injuryConfig["excluded_statuses"] or not TableUtils:ListContains(injuryConfig["excluded_statuses"], status) then
				if Osi.HasActiveStatus(character, injury) == 1 then
					injuriesToRemove[injury] = injuryConfig
				end
			end
		end

		if not next(injuriesToRemove) then
			return
		end

		local numInjuriesToRemove = ConfigManager.ConfigCopy.injuries.universal.how_many_injuries_can_be_removed_at_once
		if numInjuriesToRemove == "All" then
			for injuryToRemove, injuryConfig in pairs(injuriesToRemove) do
				removeInjury(character, injuryToRemove, injuryConfig, status)
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

			removeInjury(character, injuryToRemove, injuriesToRemove[injuryToRemove], status)
		end
	end
end)

EventCoordinator:RegisterEventProcessor("RollResult", function(eventName, roller, rollSubject, resultType, isActiveRoll, criticality)
	if string.find(eventName, "Goon_Injuries_Remove_Injury_") then
		local injuryNameAndStatus = string.sub(eventName, string.len("Goon_Injuries_Remove_Injury_"))
		local injuryName, statusCausingRemoval = string.match(injuryNameAndStatus, "([^|]+)|([^|]+)")
		if resultType == 1 then
			local entity, injuryVar = InjuryConfigHelper:GetUserVar(character)
			injuryVar["removedDueTo"] = injuryVar["removedDueTo"] or {}
			injuryVar["removedDueTo"][injuryName] = statusCausingRemoval
			InjuryConfigHelper:UpdateUserVar(entity, injuryVar)

			Osi.RemoveStatus(roller, injuryName, statusCausingRemoval)
		end
	end
end)

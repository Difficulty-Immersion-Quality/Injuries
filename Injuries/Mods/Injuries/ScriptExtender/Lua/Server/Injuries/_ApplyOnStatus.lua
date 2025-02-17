---@param entity EntityHandle
---@param status StatusName
---@param statusConfig {[StatusName] : InjuryApplyOnStatusModifierClass }
---@param injuryVar InjuryVar
local function processInjuries(entity, status, statusConfig, injuryVar)
	local statusVar = injuryVar["applyOnStatus"]
	local character = entity.Uuid.EntityUuid

	local npcMultiplier = InjuryConfigHelper:CalculateNpcMultiplier(entity)

	for injury, injuryStatusConfig in pairs(statusConfig) do
		local nextStackInjury = InjuryConfigHelper:GetNextInjuryInStackIfApplicable(character, injury)
		if nextStackInjury and Osi.HasActiveStatus(character, nextStackInjury) == 0 then
			local injuryConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury]

			if not statusVar[status] then
				statusVar[status] = { [injury] = 0 }
			end
			statusVar[status][injury] = (statusVar[status][injury] or 0) + 1

			if injury ~= nextStackInjury then
				statusVar[status][nextStackInjury] = (statusVar[status][nextStackInjury] or 0) + 1
			end

			local roundsWithMultiplier = (statusVar[status][injury] * injuryStatusConfig["multiplier"])

			for otherStatus, otherStatusConfig in pairs(injuryConfig.apply_on_status["applicable_statuses"]) do
				local injuryOtherExistingStatus = statusVar[otherStatus]
				if otherStatus ~= status and (injuryOtherExistingStatus and injuryOtherExistingStatus[injury]) then
					roundsWithMultiplier = roundsWithMultiplier + ((injuryOtherExistingStatus[injury] * otherStatusConfig["multiplier"]))
				end
			end

			local characterMultiplier = InjuryConfigHelper:CalculateCharacterMultipliers(entity, injuryConfig)
			roundsWithMultiplier = roundsWithMultiplier * characterMultiplier * npcMultiplier

			if roundsWithMultiplier >= injuryConfig.apply_on_status["number_of_rounds"] and InjuryConfigHelper:RollForApplication(nextStackInjury, injuryVar, status) then
				Osi.ApplyStatus(character, nextStackInjury, -1)
				injuryVar["injuryAppliedReason"][nextStackInjury] = "Status"

				if injury ~= nextStackInjury then
					injuryVar["injuryAppliedReason"][nextStackInjury] = string.format("Status (Stacked on top of %s)",
						Ext.Loca.GetTranslatedString(Ext.Stats.Get(injury).DisplayName, injury))
				end
			end
		end
	end
	InjuryConfigHelper:UpdateUserVar(entity, injuryVar)
end

local function CheckStatusOnTickOrApplication(status, character)
	local statusConfig = ConfigManager.Injuries.ApplyOnStatus[status]
	if statusConfig then
		local entity, injuryVar = InjuryConfigHelper:GetUserVar(character)
		if entity and injuryVar then
			processInjuries(entity, status, statusConfig, injuryVar)

			--if Osi.IsInCombat(character) == 0 and Osi.IsInForceTurnBasedMode(character) == 0 then
				-- 5.7 seconds since if we do 6 seconds, we trigger after the status is removed and we don't increment the count
				-- TODO: Figure out how to get this to continue going if there's a reset or reload while it's ticking
				--Ext.Timer.WaitFor(5700, function()
					--if Osi.HasActiveStatus(character, status) == 1 and Osi.IsInCombat(character) == 0 and Osi.IsInForceTurnBasedMode(character) == 0 then
						-- Make sure we're tracking ticks when not in combat, since there's no event for that
						-- TODO: Check to see if there's any injuries left to apply for this status, so this isn't running unnecessarily
						--CheckStatusOnTickOrApplication(status, character)
					--end
				--end)
			--end
		end
	end
end

EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
	if InjuryConfigHelper:IsEligible(character) then
		CheckStatusOnTickOrApplication(status, character)
	end
end)

--EventCoordinator:RegisterEventProcessor("CombatRoundStarted", function(combatGuid, round)
	--if ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset ~= "Round" then
		--for _, combatParticipant in pairs(Osi.DB_Is_InCombat:Get(nil, combatGuid)) do
			--if InjuryConfigHelper:IsEligible(combatParticipant[1]) then
				--local entity, injuryVar = InjuryConfigHelper:GetUserVar(combatParticipant[1])

				--if entity and injuryVar then
					-- InjuryConfigHelper handles resetting vars each round
					--local applyOnStatus = injuryVar["applyOnStatus"]
					--if applyOnStatus then
						--for status, _ in pairs(applyOnStatus) do
							--if Osi.HasActiveStatus(combatParticipant[1], status) == 1 then
								--processInjuries(entity, status, ConfigManager.Injuries.ApplyOnStatus[status], applyOnStatus)
							--end
						--end
					--end
				--end
			--end
		--end
	--end
--end)

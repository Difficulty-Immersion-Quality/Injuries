---@param entity EntityHandle
---@param status StatusName
---@param statusConfig {[StatusName] : InjuryApplyOnStatusModifierClass }
---@param injuryVar InjuryVar
local function processInjuries(entity, status, statusConfig, injuryVar)
	local statusVar = injuryVar["applyOnStatus"]
	local character = entity.Uuid.EntityUuid

	for injury, injuryStatusConfig in pairs(statusConfig) do
		if Osi.HasActiveStatus(character, injury) == 0 then
			local mainInjuryConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury].apply_on_status

			if not statusVar[status] then
				statusVar[status] = { [injury] = 0 }
			end
			statusVar[status][injury] = (statusVar[status][injury] or 0) + 1

			local roundsWithMultiplier = statusVar[status][injury] * injuryStatusConfig["multiplier"]

			for otherStatus, otherStatusConfig in pairs(mainInjuryConfig["applicable_statuses"]) do
				local injuryOtherExistingStatus = statusVar[otherStatus]
				if otherStatus ~= status and (injuryOtherExistingStatus and injuryOtherExistingStatus[injury]) then
					roundsWithMultiplier = roundsWithMultiplier + (injuryOtherExistingStatus * otherStatusConfig["multiplier"])
				end
			end

			if mainInjuryConfig["number_of_rounds"] <= roundsWithMultiplier then
				Osi.ApplyStatus(character, injury, -1)
				injuryVar["injuryAppliedReason"][injury] = "Status"
			end
		end
	end
	InjuryConfigHelper:UpdateUserVar(entity, injuryVar)
end

local function CheckStatusOnTickOrApplication(status, character)
	local statusConfig = ConfigManager.Injuries.ApplyOnStatus[status]
	if statusConfig then
		local entity, injuryVar = InjuryConfigHelper:GetUserVar(character)

		processInjuries(entity, status, statusConfig, injuryVar)

		if Osi.IsInCombat(character) == 0 and Osi.IsInForceTurnBasedMode(character) == 0 then
			-- 5.9 seconds since if we do 6 seconds, we trigger after the status is removed and we don't increment the count
			-- TODO: Figure out how to get this to continue going if there's a reset or reload while it's ticking
			Ext.Timer.WaitFor(5900, function()
				if Osi.HasActiveStatus(character, status) == 1 and Osi.IsInCombat(character) == 0 and Osi.IsInForceTurnBasedMode(character) == 0 then
					-- Make sure we're tracking ticks when not in combat, since there's no event for that
					-- TODO: Check to see if there's any injuries left to apply for this status, so this isn't running unnecessarily
					CheckStatusOnTickOrApplication(status, character)
				end
			end)
		end
	end
end

EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
	if InjuryConfigHelper:IsEligible(character) then
		CheckStatusOnTickOrApplication(status, character)
	end
end)

EventCoordinator:RegisterEventProcessor("CombatRoundStarted", function(combatGuid, round)
	if ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset ~= "Round" then
		for _, combatParticipant in pairs(Osi.DB_Is_InCombat:Get(nil, combatGuid)) do
			if InjuryConfigHelper:IsEligible(combatParticipant[1]) then
				local entity, injuryVar = InjuryConfigHelper:GetUserVar(combatParticipant[1])

				-- InjuryConfigHelper handles resetting vars each round
				local applyOnStatus = injuryVar["applyOnStatus"]
				for status, _ in pairs(applyOnStatus) do
					if Osi.HasActiveStatus(combatParticipant[1], status) == 1 then
						processInjuries(entity, status, ConfigManager.Injuries.ApplyOnStatus[status], applyOnStatus)
					end
				end
			end
		end
	end
end)

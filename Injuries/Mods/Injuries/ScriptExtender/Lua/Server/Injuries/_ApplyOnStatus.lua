---@param entity EntityHandle
---@param status StatusName
---@param statusConfig {[StatusName] : InjuryApplyOnStatusModifierClass }
---@param injuryVar InjuryVar
---@param statusGroup string?
---@param eventType "onApplication"|"onRemoval"
local function processInjuries(entity, status, statusConfig, injuryVar, statusGroup, eventType)
	local statusVar = injuryVar["applyOnStatus"]
	local character = entity.Uuid.EntityUuid

	local npcMultiplier = InjuryCommonLogic:CalculateNpcMultiplier(entity)

	---@type StatusData
	local statusData = Ext.Stats.Get(status)
	for injury, injuryStatusConfig in pairs(statusConfig) do
		local injuryConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury]
		if injuryConfig.severity == "Disabled" then
			goto continue
		end

		local nextStackInjury = InjuryCommonLogic:GetNextInjuryInStackIfApplicable(character, injury)
		Logger:BasicDebug("Status %s will apply %s (possibly upgraded from %s) to %s", status, nextStackInjury, injury, character)
		if nextStackInjury and Osi.HasActiveStatus(character, nextStackInjury) == 0 then
			if statusGroup and statusData.StatusGroups and TableUtils:ListContains(statusData.StatusGroups, statusGroup) then
				if injuryStatusConfig["excluded_statuses"] and TableUtils:ListContains(injuryStatusConfig["excluded_statuses"], status) then
					Logger:BasicDebug("%s belongs to status group %s but is excluded, so skipping", nextStackInjury, statusGroup)
					goto continue
				end
			end

			if not injuryStatusConfig[eventType] then
				Logger:BasicDebug("%s triggered on %s, which is disabled in %s's config", status, eventType, nextStackInjury)
				goto continue
			end

			local roundCount = 0

			if injury ~= nextStackInjury then
				if not injuryVar["stack_reapply_status"] then
					injuryVar["stack_reapply_status"] = {}
				end
				if not injuryVar["stack_reapply_status"][status] then
					injuryVar["stack_reapply_status"][status] = {}
				end

				injuryVar["stack_reapply_status"][status][injury] = (injuryVar["stack_reapply_status"][status][injury] or 0) + 1
				roundCount = injuryVar["stack_reapply_status"][status][injury]
			else
				if not statusVar[status] then
					statusVar[status] = { [injury] = 0 }
				end
				statusVar[status][injury] = (statusVar[status][injury] or 0) + 1
				roundCount = statusVar[status][injury]
			end

			local roundsWithMultiplier = (roundCount * injuryStatusConfig["multiplier"])

			for otherStatus, otherStatusConfig in pairs(injuryConfig.apply_on_status["applicable_statuses"]) do
				local injuryOtherExistingStatus = statusVar[otherStatus]
				if otherStatus ~= status and (injuryOtherExistingStatus and injuryOtherExistingStatus[injury]) then
					roundsWithMultiplier = roundsWithMultiplier + ((injuryOtherExistingStatus[injury] * otherStatusConfig["multiplier"]))
				end
			end
			Logger:BasicDebug("roundsWithMultiplier is %s for %s", roundsWithMultiplier, nextStackInjury)

			local characterMultiplier = InjuryCommonLogic:CalculateCharacterMultipliers(entity, injuryConfig)
			roundsWithMultiplier = roundsWithMultiplier * characterMultiplier * npcMultiplier

			if roundsWithMultiplier >= injuryConfig.apply_on_status["number_of_rounds"] and InjuryCommonLogic:RollForApplication(nextStackInjury, injuryVar, statusGroup or status, character) then
				Logger:BasicDebug("%s was successfully applied on %s", nextStackInjury, character)
				Osi.ApplyStatus(character, nextStackInjury, -1)
				injuryVar["injuryAppliedReason"][nextStackInjury] = "Status"

				if injury ~= nextStackInjury then
					for status, entry in pairs(injuryVar["applyOnStatus"]) do
						entry[nextStackInjury] = entry[injury]
						entry[injury] = nil

						if injuryVar["stack_reapply_status"][status] then
							injuryVar["stack_reapply_status"][status][injury] = nil
						end
					end
					injuryVar["injuryAppliedReason"][nextStackInjury] = string.format("Status (Stacked on top of %s)",
						Ext.Loca.GetTranslatedString(Ext.Stats.Get(injury).DisplayName, injury))
				end
			end
		end
		::continue::
	end
	InjuryCommonLogic:UpdateUserVar(entity, injuryVar)
end

---@param status string
---@param character CHARACTER
---@param eventType "onApplication"|"onRemoval"
local function CheckStatusOnTickOrApplication(status, character, eventType)
	local statusConfig = TableUtils:DeeplyCopyTable(ConfigManager.Injuries.ApplyOnStatus[status])
	local statusSG
	---@type StatusData
	local statusData = Ext.Stats.Get(status)
	if statusData and statusData.StatusGroups and next(statusData.StatusGroups) then
		for _, statusGroup in ipairs(statusData.StatusGroups) do
			if ConfigManager.Injuries.ApplyOnStatus[statusGroup] then
				statusSG = statusGroup
				if statusConfig then
					for injury, config in pairs(ConfigManager.Injuries.ApplyOnStatus[statusGroup]) do
						statusConfig[injury] = config
					end
				else
					statusConfig = ConfigManager.Injuries.ApplyOnStatus[statusGroup]
				end
				break
			end
		end
	end
	if statusConfig then
		local entity, injuryVar = InjuryCommonLogic:GetUserVar(character)
		if entity and injuryVar then
			processInjuries(entity, status, statusConfig, injuryVar, statusSG, eventType)

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
	if InjuryCommonLogic:IsEligible(character) then
		CheckStatusOnTickOrApplication(status, character, "onApplication")
	end
end)

EventCoordinator:RegisterEventProcessor("StatusRemoved", function(character, status, causee, applyStoryActionID)
	if InjuryCommonLogic:IsEligible(character) then
		CheckStatusOnTickOrApplication(status, character, "onRemoval")
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

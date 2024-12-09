Ext.Vars.RegisterUserVariable("Injury_Downed_Tracker", {
	Server = true,
})

local function ChooseRandomSeverity()
	---@type severity
	local severityToChoose
	local randomRollResult = Osi.Random(100) + 1
	local weights = ConfigManager.ConfigCopy.injuries.universal.random_injury_severity_weights
	if randomRollResult <= weights["Low"] then
		severityToChoose = "Low"
	elseif randomRollResult <= weights["Medium"] + weights["Low"] then
		severityToChoose = "Medium"
	else
		severityToChoose = "High"
	end

	return severityToChoose
end

RandomInjuryOnConditionProcessor = {}

---@param event EsvLuaBeforeDealDamageEvent
---@param defender CHARACTER
---@param tempHpReductionTable { [DamageType] : integer }
---@return {[InjuryName] : boolean}
function RandomInjuryOnConditionProcessor:ProcessDamageEvent(event, defender, tempHpReductionTable)
	local appliedInjuries = {}

	if ConfigManager.ConfigCopy.injuries.universal.random_injury_conditional["Suffered a Critical Hit"] then
		local severityToChoose = ChooseRandomSeverity()

		local alreadySelectedInjuries = {}
		local eligibleInjuries = {}
		for damageType, damageRolls in pairs(event.Hit.Damage.DamageRolls) do
			for _, damageRoll in pairs(damageRolls) do
				if damageRoll.Result.Critical == "Success" and ConfigManager.Injuries.Damage[damageType] then
					for injury, _ in pairs(ConfigManager.Injuries.Damage[damageType]) do
						if Osi.HasActiveStatus(defender, injury) == 0
							and severityToChoose == ConfigManager.ConfigCopy.injuries.injury_specific[injury].severity
							and not alreadySelectedInjuries[injury]
						then
							table.insert(eligibleInjuries, injury)
							alreadySelectedInjuries[injury] = true
						end
					end
				end
			end
		end

		if #eligibleInjuries > 0 then
			Logger:BasicDebug("Randomly applying one of %s %s severity injuries for Critial Hit",
				#eligibleInjuries,
				severityToChoose)

			local chosenInjury = eligibleInjuries[Osi.Random(#eligibleInjuries) + 1]
			Osi.ApplyStatus(defender, chosenInjury, -1)
			local _, injuryVar = InjuryConfigHelper:GetUserVar(defender)
			injuryVar["injuryAppliedReason"][chosenInjury] = "Critical Hit"

			appliedInjuries[chosenInjury] = true
		end
	end

	-- Downed events don't tell you which DamageType caused the status, and thanks to things like DeathWard we can't just rely
	-- on damage calculations
	if ConfigManager.ConfigCopy.injuries.universal.random_injury_conditional["Downed"] then
		local hp = Ext.Entity.Get(defender).Health.Hp

		-- DamageList contains the damageTypes in the order they're applied it looks like - whereas FinalDamagePerType is arbitrarily ordered
		for _, damagePair in pairs(event.Hit.DamageList) do
			local finalDamageAmount = event.Hit.Damage.FinalDamagePerType[damagePair.DamageType]

			if tempHpReductionTable[damagePair.DamageType] then
				finalDamageAmount = damagePair.DamageType - tempHpReductionTable[damagePair.DamageType]
			end

			hp = hp - finalDamageAmount
			if hp <= 0 then
				Ext.Entity.Get(defender).Vars.Injury_Downed_Tracker = tostring(damagePair.DamageType)
				Ext.Timer.WaitFor(500, function()
					Ext.Entity.Get(defender).Vars.Injury_Downed_Tracker = nil
				end)

				break
			end
		end
	end
	return appliedInjuries
end

EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
	if status == "DOWNED" then
		local entity, injuryVar = InjuryConfigHelper:GetUserVar(character)

		if entity.Vars.Injury_Downed_Tracker then
			local damageType = entity.Vars.Injury_Downed_Tracker

			local severityToChoose = ChooseRandomSeverity()

			local alreadySelectedInjuries = {}
			local eligibleInjuries = {}
			for injury, _ in pairs(ConfigManager.Injuries.Damage[damageType]) do
				if Osi.HasActiveStatus(character, injury) == 0
					and severityToChoose == ConfigManager.ConfigCopy.injuries.injury_specific[injury].severity
					and not alreadySelectedInjuries[injury]
				then
					table.insert(eligibleInjuries, injury)
					alreadySelectedInjuries[injury] = true
				end
			end

			if #eligibleInjuries > 0 then
				Logger:BasicDebug("Randomly applying one of %s %s severity injuries for Downed",
					#eligibleInjuries,
					severityToChoose)

				local chosenInjury = eligibleInjuries[Osi.Random(#eligibleInjuries) + 1]
				Osi.ApplyStatus(character, chosenInjury, -1)
				injuryVar["injuryAppliedReason"][chosenInjury] = "Downed"
				InjuryConfigHelper:UpdateUserVar(entity, injuryVar)
			end

			entity.Vars.Injury_Downed_Tracker = nil
		end
	end
end)

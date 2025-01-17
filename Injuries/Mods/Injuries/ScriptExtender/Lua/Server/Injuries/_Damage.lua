local defender

---@param event EsvLuaBeforeDealDamageEvent
local function ProcessDamageEvent(event)
	local defenderEntity, injuryVar = InjuryConfigHelper:GetUserVar(defender)

	-- Damage numbers don't account for TempHp - need to recreate that reduction
	--- @type { [DamageType] : integer }
	local tempHpReductionTable = {}
	if defenderEntity.Health.TemporaryHp > 0 then
		local tempHp = defenderEntity.Health.TemporaryHp
		-- DamageList contains the damageTypes in the order they're applied it looks like - whereas FinalDamagePerType is arbitrarily ordered
		for _, damagePair in pairs(event.Hit.DamageList) do
			local finalDamageAmount = event.Hit.Damage.FinalDamagePerType[damagePair.DamageType]

			if finalDamageAmount == tempHp then
				tempHpReductionTable[damagePair.DamageType] = finalDamageAmount
				break
			elseif finalDamageAmount > tempHp then
				tempHpReductionTable[damagePair.DamageType] = finalDamageAmount - tempHp
				break
			elseif finalDamageAmount < tempHp then
				tempHp = tempHp - finalDamageAmount
				tempHpReductionTable[damagePair.DamageType] = finalDamageAmount
			end
		end
		Logger:BasicTrace("Reduced the following damagePairs as %s has %d tempHp:\n%s",
			defender,
			defenderEntity.Health.TemporaryHp,
			Ext.Json.Stringify(tempHpReductionTable)
		)
	end

	RandomInjuryOnConditionProcessor:ProcessDamageEvent(event, defender, tempHpReductionTable)

	local npcMultiplier = InjuryConfigHelper:CalculateNpcMultiplier(defenderEntity)

	-- Total damage is the sum of damage pre-resistance/invulnerability checks - FinalDamage is post
	for damageType, finalDamageAmount in pairs(event.Hit.Damage.FinalDamagePerType) do
		local damageConfig = ConfigManager.Injuries.Damage[damageType]
		if damageConfig then
			if tempHpReductionTable[damageType] then
				finalDamageAmount = finalDamageAmount - tempHpReductionTable[damageType]
				Logger:BasicTrace("Reduced %s final damage to %d due to tempHp math", damageType, finalDamageAmount)
			end

			if finalDamageAmount > 0 then
				for injury, injuryDamageConfig in pairs(damageConfig) do
					injury = InjuryConfigHelper:GetNextInjuryInStackIfApplicable(defender, injury)
					
					if Osi.HasActiveStatus(defender, injury) == 0
						and not injuryVar["injuryAppliedReason"][injury]
					then
						local finalDamageWithPreviousDamage = finalDamageAmount

						if not injuryVar["damage"][damageType] then
							injuryVar["damage"][damageType] = { [injury] = 0 }
						end
						local preexistingDamage = injuryVar["damage"][damageType]

						if preexistingDamage[injury] then
							finalDamageWithPreviousDamage = finalDamageAmount + preexistingDamage[injury]
						end

						preexistingDamage[injury] = finalDamageWithPreviousDamage

						local finalDamageWithInjuryMultiplier = finalDamageWithPreviousDamage * injuryDamageConfig["multiplier"]

						local injuryConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury]
						for otherDamageType, otherDamageConfig in pairs(injuryConfig.damage["damage_types"]) do
							local existingDamageForOtherDamageType = injuryVar["damage"][otherDamageType]
							if damageType ~= otherDamageType and (existingDamageForOtherDamageType and existingDamageForOtherDamageType[injury]) then
								local existingInjuryDamage = existingDamageForOtherDamageType[injury] * otherDamageConfig["multiplier"]

								finalDamageWithInjuryMultiplier = finalDamageWithInjuryMultiplier + existingInjuryDamage
							end
						end

						local characterMultiplier = InjuryConfigHelper:CalculateCharacterMultipliers(defenderEntity, injuryConfig)
						finalDamageWithInjuryMultiplier = finalDamageWithInjuryMultiplier * characterMultiplier * npcMultiplier

						local totalHpPercentageRemoved = (finalDamageWithInjuryMultiplier / defenderEntity.Health.MaxHp) * 100

						if totalHpPercentageRemoved >= injuryConfig.damage["threshold"] then
							Osi.ApplyStatus(defender, injury, -1)
							injuryVar["injuryAppliedReason"][injury] = "Damage"
						end
					end
				end
			end
		else
			Logger:BasicDebug("No Injuries are configured to trigger on damageType %s - skipping this entry", damageType)
		end
	end

	InjuryConfigHelper:UpdateUserVar(defenderEntity, injuryVar)
end

--- Event sequence is DealDamage -> BeforeDealDamage (presumably "We're going to deal damage" -> "The damage we're dealing before it's applied" ?)
--- DealDamage doesn't contain any damage or damageType information - just who's attacking and being attacked
--- BeforeDealDamage contains damage and damageType information and who's attacking, but not who's being attacked
---@param event EsvLuaDealDamageEvent
Ext.Events.DealDamage:Subscribe(function(event)
	-- Candles constantly taking burn damage lol
	if MCM.Get("enabled") and not event.Target.IsItem then
		defender = event.Target.Uuid.EntityUuid

		if InjuryConfigHelper:IsEligible(defender) then
			Ext.Events.BeforeDealDamage:Subscribe(ProcessDamageEvent, { Once = true })
		end
	end
end)

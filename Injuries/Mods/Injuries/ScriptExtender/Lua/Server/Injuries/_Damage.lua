local defender

---@param event EsvLuaBeforeDealDamageEvent
local function ProcessDamageEvent(event)
	local defenderEntity, injuryVar = InjuryCommonLogic:GetUserVar(defender)

	if not defenderEntity or not injuryVar then
		return
	end

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

	---@type InjuryApplicationChanceModifiers[]
	local modifiers = {}
	for _, statsRoll in pairs(event.Hit.Damage.DamageRolls) do
		for _, damageRoll in pairs(statsRoll) do
			if damageRoll.Result.Critical == "Success" then
				table.insert(modifiers, "Attack Was A Critical")
				goto exit
			end
		end
	end
	::exit::

	---@type {string: InjuryName[]}
	local appliedInjuriesTracker = {}

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
					local injuryConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury]
					if injuryConfig.severity == "Disabled" then
						goto continue
					end
					local nextStackInjury = InjuryCommonLogic:GetNextInjuryInStackIfApplicable(defender, injury)

					if nextStackInjury
						and Osi.HasActiveStatus(defender, nextStackInjury) == 0
						and not injuryVar["injuryAppliedReason"][nextStackInjury]
					then
						local npcMultiplier = InjuryCommonLogic:CalculateNpcMultiplier(defenderEntity, nextStackInjury)

						local finalDamageWithPreviousDamage = finalDamageAmount

						if injury ~= nextStackInjury then
							if not injuryVar["stack_reapply_damage"] then
								injuryVar["stack_reapply_damage"] = {}
							end
							if not injuryVar["stack_reapply_damage"][damageType] then
								injuryVar["stack_reapply_damage"][damageType] = {}
							end
							local nextStackDamage = injuryVar["stack_reapply_damage"][damageType]
							nextStackDamage[injury] = nextStackDamage[injury]
								and nextStackDamage[injury] + finalDamageWithPreviousDamage
								or finalDamageWithPreviousDamage

							finalDamageWithPreviousDamage = nextStackDamage[injury]
						else
							if not injuryVar["damage"][damageType] then
								injuryVar["damage"][damageType] = { [injury] = 0 }
							end
							local preexistingDamage = injuryVar["damage"][damageType]

							if preexistingDamage[injury] then
								finalDamageWithPreviousDamage = finalDamageAmount + preexistingDamage[injury]
							end

							preexistingDamage[injury] = finalDamageWithPreviousDamage
						end

						local finalDamageWithInjuryMultiplier = finalDamageWithPreviousDamage * injuryDamageConfig["multiplier"]

						for otherDamageType, otherDamageConfig in pairs(injuryConfig.damage["damage_types"]) do
							local existingDamageForOtherDamageType = injuryVar["damage"][otherDamageType]
							if damageType ~= otherDamageType and (existingDamageForOtherDamageType and existingDamageForOtherDamageType[injury]) then
								local existingInjuryDamage = existingDamageForOtherDamageType[injury] * otherDamageConfig["multiplier"]

								finalDamageWithInjuryMultiplier = finalDamageWithInjuryMultiplier + existingInjuryDamage
							end
						end

						local characterMultiplier = InjuryCommonLogic:CalculateCharacterMultipliers(defenderEntity, injuryConfig)
						finalDamageWithInjuryMultiplier = finalDamageWithInjuryMultiplier * characterMultiplier * npcMultiplier

						local totalHpPercentageRemoved = (finalDamageWithInjuryMultiplier / defenderEntity.Health.MaxHp) * 100

						if totalHpPercentageRemoved >= injuryConfig.damage["threshold"] and InjuryCommonLogic:RollForApplication(nextStackInjury, injuryVar, nil, defender, modifiers, appliedInjuriesTracker) then
							Osi.ApplyStatus(defender, nextStackInjury, -1)
							injuryVar["injuryAppliedReason"][nextStackInjury] = "Damage"

							if injury ~= nextStackInjury then
								for damageType, entry in pairs(injuryVar["damage"]) do
									entry[nextStackInjury] = entry[injury]
									entry[injury] = nil

									if injuryVar["stack_reapply_damage"][damageType] then
										injuryVar["stack_reapply_damage"][damageType][injury] = nil
									end
								end
								injuryVar["injuryAppliedReason"][nextStackInjury] = string.format("Damage (Stacked on top of %s)",
									Ext.Loca.GetTranslatedString(Ext.Stats.Get(injury).DisplayName, injury))
							end
						end
					end
					::continue::
				end
			end
		else
			Logger:BasicDebug("No Injuries are configured to trigger on damageType %s - skipping this entry", damageType)
		end
	end

	InjuryCommonLogic:UpdateUserVar(defenderEntity, injuryVar)
end

--- Event sequence is DealDamage -> BeforeDealDamage (presumably "We're going to deal damage" -> "The damage we're dealing before it's applied" ?)
--- DealDamage doesn't contain any damage or damageType information - just who's attacking and being attacked
--- BeforeDealDamage contains damage and damageType information and who's attacking, but not who's being attacked
---@param event EsvLuaDealDamageEvent
Ext.Events.DealDamage:Subscribe(function(event)
	-- Candles constantly taking burn damage lol
	if MCM.Get("enabled") and not event.Target.IsItem then
		defender = event.Target.Uuid.EntityUuid

		if InjuryCommonLogic:IsEligible(defender) then
			Ext.Events.BeforeDealDamage:Subscribe(ProcessDamageEvent, { Once = true })
		end
	end
end)

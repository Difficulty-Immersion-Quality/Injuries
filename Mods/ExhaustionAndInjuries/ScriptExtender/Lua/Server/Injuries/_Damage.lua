-- Synced to Client/Injuries/InjuryReport
Ext.Vars.RegisterUserVariable("Injuries_Damage", {
	Server = true,
	Client = true,
	SyncToClient = true,
	SyncOnWrite = true -- if this is false, the injuryReport lags by 1 calculation
})

local defender

---@param event EsvLuaBeforeDealDamageEvent
local function ProcessDamageEvent(event)
	---@type EntityHandle
	local defenderEntity = Ext.Entity.Get(defender)

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

	--- @type { [DamageType] :  number }
	local preexistingInjuryDamage = defenderEntity.Vars.Injuries_Damage or {}
	-- Total damage is the sum of damage pre-resistance/invulnerability checks - FinalDamage is post
	for damageType, finalDamageAmount in pairs(event.Hit.Damage.FinalDamagePerType) do
		local damageConfig = ConfigManager.Injuries.Damage[damageType]
		if damageConfig then
			if tempHpReductionTable[damageType] then
				finalDamageAmount = finalDamageAmount - tempHpReductionTable[damageType]
				Logger:BasicTrace("Reduced %s final damage to %d due to tempHp math", damageType, finalDamageAmount)
			end

			if finalDamageAmount > 0 then
				if preexistingInjuryDamage[damageType] then
					finalDamageAmount = finalDamageAmount + preexistingInjuryDamage[damageType]
				end
				
				preexistingInjuryDamage[damageType] = finalDamageAmount

				for injury, injuryDamageConfig in pairs(damageConfig) do
					if Osi.HasActiveStatus(defender, injury) == 0 then
						local finalDamageWithInjuryMultiplier = finalDamageAmount * injuryDamageConfig["multiplier"]

						local injuryConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury]
						for otherDamageType, otherDamageConfig in pairs(injuryConfig.damage["damage_types"]) do
							if damageType ~= otherDamageType and preexistingInjuryDamage[otherDamageType] then
								local existingInjuryDamage = preexistingInjuryDamage[otherDamageType] * otherDamageConfig["multiplier"]
								Logger:BasicTrace("Adding %d damage due to preexisting damageType %s for Injury %s on %s",
									existingInjuryDamage,
									otherDamageType,
									injury,
									defender)

								finalDamageWithInjuryMultiplier = finalDamageWithInjuryMultiplier + existingInjuryDamage
							end
						end

						-- This is apparently how you round to 2 decimal places? Thanks ChatGPT
						local totalHpPercentageRemoved = math.floor((finalDamageWithInjuryMultiplier / defenderEntity.Health.MaxHp) * 10000) / 100

						if totalHpPercentageRemoved >= injuryConfig.damage["threshold"] then
							Logger:BasicDebug("Applying %s to %s since %s damage exceeds the threshold of %s",
								injury,
								defender,
								totalHpPercentageRemoved,
								injuryConfig.damage["threshold"])

							Osi.ApplyStatus(defender, injury, -1)
						end
					end
				end
			end
		else
			Logger:BasicDebug("No Injuries are configured to trigger on damageType %s - skipping this entry", damageType)
		end
	end

	local counter_reset = ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset
	if counter_reset == "Attack/Tick" then
		defenderEntity.Vars.Injuries_Damage = nil
	else
		defenderEntity.Vars.Injuries_Damage = preexistingInjuryDamage

		if counter_reset == "Round" and Osi.IsInCombat(defender) == 0 then
			Ext.Timer.WaitFor(6000, function()
				defenderEntity.Vars.Injuries_Damage = nil
				Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", defender)
			end)
		end
	end
	Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", defender)
end

--- Event sequence is DealDamage -> BeforeDealDamage (presumably "We're going to deal damage" -> "The damage we're dealing before it's applied" ?)
--- DealDamage doesn't contain any damage or damageType information - just who's attacking and being attacked
--- BeforeDealDamage contains damage and damageType information and who's attacking, but not who's being attacked
---@param event EsvLuaDealDamageEvent
Ext.Events.DealDamage:Subscribe(function(event)
	-- Candles constantly taking burn damage lol
	if not event.Target.IsItem then
		defender = event.Target.Uuid.EntityUuid

		local eligibleGroups = ConfigManager.ConfigCopy.injuries.universal.who_can_receive_injuries
		if (eligibleGroups["Allies"] and Osi.IsAlly(Osi.GetHostCharacter(), defender) == 1)
			or (eligibleGroups["Party Members"] and Osi.IsPartyMember(defender, 1) == 1)
			or (eligibleGroups["Enemies"] and Osi.IsEnemy(Osi.GetHostCharacter(), defender) == 1)
		then
			Ext.Events.BeforeDealDamage:Subscribe(ProcessDamageEvent, { Once = true })
		end
	end
end)

EventCoordinator:RegisterEventProcessor("LeftCombat", function(object, combatGuid)
	if Ext.Entity.Get(object).Vars.Injuries_Damage and ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Combat" then
		Ext.Entity.Get(object).Vars.Injuries_Damage = nil
		Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", object)
	end
end)

EventCoordinator:RegisterEventProcessor("CombatRoundStarted", function(combatGuid, round)
	if ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Round" then
		for _, combatParticipant in pairs(Osi.DB_Is_InCombat:Get(nil, combatGuid)) do
			local entity = Ext.Entity.Get(combatParticipant[1])
			if entity.Vars.Injuries_Damage then
				entity.Vars.Injuries_Damage = nil
				Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", combatParticipant[1])
			end
		end
	end
end)

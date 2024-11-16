local printer = ChangePrinter:New()

-- Weapon attacks are spells too - i.e. https://bg3.norbyte.dev/search?q=type%3Aspell+Ranged+%26+Attack#result-eda1854279be71702cf949e192e8b08a2839b809
-- AttackedBy event triggers after Sneaking is removed, so we can't use that
-- EventCoordinator:RegisterEventProcessor("CastSpell", function(caster, _, _, _, _)
-- 	if Osi.IsPartyMember(caster, 0) == 1 then
-- 		printer:Start()
-- 	end
-- end)

Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function(caster, spell, spellType, spellElement, storyActionID)
	if Osi.IsPartyMember(caster, 0) == 1 then
		-- printer:Start()
	end
end)

Ext.Osiris.RegisterListener("HitpointsChanged", 2, "before", function(entity, percentage)
	if Osi.IsPartyMember(entity, 0) == 1 then
	end
end)


EventCoordinator:RegisterEventProcessor("AttackedBy", function(defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionID)
	-- printer:Stop()
	-- Don't wanna global this since ConfigManager replaces the whole table instead of merging in the new table. Might wanna fix at some point
	local injuryConfig = ConfigManager.ConfigCopy.injuries

	local damageConfig = ConfigManager.Injuries.Damage[string.upper(damageType)]
	if not damageConfig then
		Logger:BasicDebug("No injuries are configured to trigger on damageType %s, skipping processing", damageType)
		return
	end

	local eligibleGroups = injuryConfig.universal.who_can_receive_injuries
	if eligibleGroups["Allies"] and Osi.IsAlly(Osi.GetHostCharacter(), defender) == 1
		or eligibleGroups["Party Members"] and Osi.IsPartyMember(defender, 1) == 1
		or eligibleGroups["Enemies"] and Osi.IsEnemy(Osi.GetHostCharacter(), defender) == 1
	then
		local defenderEntity = Ext.Entity.Get(defender)
		local healthRemoved = damageAmount
		if defenderEntity.TemporaryHP >= damageAmount then
			Logger:BasicDebug("%s has %s TemporaryHP, which is >= to the damageAmount of %s, so skipping",
				defender,
				defenderEntity.TemporaryHP,
				damageAmount)

			return
		else
			healthRemoved = healthRemoved - defenderEntity.TemporaryHP
		end
		local healthPercentageRemoved = Osi.GetTotalHit
	end
end)

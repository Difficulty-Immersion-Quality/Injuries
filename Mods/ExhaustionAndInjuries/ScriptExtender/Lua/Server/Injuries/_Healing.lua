Ext.Vars.RegisterUserVariable("Injuries_Healing", {
	Server = true,
	Client = false
})

---@param entity EntityHandle
---@diagnostic disable-next-line: param-type-mismatch
Ext.Entity.Subscribe("Health", function(entity, _, _)
	if entity.Vars.Injuries_Damage and ConfigManager.ConfigCopy.injuries.universal.healing_subtracts_injury_damage then
		---@type HealthComponent
		local healthComp = entity.Health

		if not entity.Vars.Injuries_Healing then
			entity.Vars.Injuries_Healing = healthComp.Hp
			return
		end

		local lastKnownHealth = entity.Vars.Injuries_Healing

		if lastKnownHealth < healthComp.Hp then
			local healingDone = (healthComp.Hp - lastKnownHealth) * ConfigManager.ConfigCopy.injuries.universal.healing_subtracts_injury_damage_modifier
			Logger:BasicDebug("%s will heal for %s points of injury damage", entity.Uuid.EntityUuid, healingDone)

			---@type { [DamageType] : { [string] : number } }
			local existingInjuryDamage = entity.Vars.Injuries_Damage
			for damageType, damageTable in pairs(existingInjuryDamage) do
				local flatAfterHealing = damageTable["flat"] - healingDone

				if flatAfterHealing <= 0 then
					existingInjuryDamage[damageType] = nil
				else
					existingInjuryDamage[damageType]["flat"] = flatAfterHealing
				end
			end

			entity.Vars.Injuries_Damage = existingInjuryDamage
		end

		entity.Vars.Injuries_Healing = healthComp.Hp
	else
		entity.Vars.Injuries_Healing = nil
	end
end)

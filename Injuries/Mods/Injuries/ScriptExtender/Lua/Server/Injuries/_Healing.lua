Ext.Vars.RegisterUserVariable("Injuries_Healing", {
	Server = true,
	Client = false
})

---@param entity EntityHandle
---@diagnostic disable-next-line: param-type-mismatch
Ext.Entity.Subscribe("Health", function(entity, _, _)
	local _, injuryVar = InjuryCommonLogic:GetUserVar(entity.Uuid.EntityUuid)
	local damageVar = injuryVar["damage"]
	if damageVar and next(damageVar) and ConfigManager.ConfigCopy.injuries and ConfigManager.ConfigCopy.injuries.universal.healing_subtracts_injury_damage then
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

			for damageType, injuryDamage in pairs(damageVar) do
				for injury, damage in pairs(injuryDamage) do
					if Osi.HasActiveStatus(entity.Uuid.EntityUuid, injury) == 0 then
						local flatAfterHealing = damage - healingDone

						if flatAfterHealing <= 0 then
							injuryDamage[injury] = nil
						else
							injuryDamage[injury] = flatAfterHealing
						end
					end
					if not next(injuryDamage) then
						damageVar[damageType] = nil
					end
				end
			end

			InjuryCommonLogic:UpdateUserVar(entity, injuryVar)
		end

		entity.Vars.Injuries_Healing = healthComp.Hp
	else
		entity.Vars.Injuries_Healing = nil
	end
end)

ConfigManager = {}

ConfigManager.ConfigCopy = {}

-- Need to make sure the server's copy of the config is up-to-date since that's where the actual functionality is
Ext.RegisterNetListener(ModuleUUID .. "_UpdateConfiguration", function(_, _, _)
	ConfigurationStructure:UpdateConfigForServer()
	ConfigManager.ConfigCopy = ConfigurationStructure:GetRealConfigCopy()

	-- Making the config more code-friendly so we don't have to loop through irrelevant injuries during events
	-- Resetting the table to prevent any removed entries from persisting
	ConfigManager.Injuries = {}
	--- @type { [DamageType] : { [InjuryName] : InjuryDamageTypeClass } }
	ConfigManager.Injuries.Damage = {}

	--- @type { [StatusName] : { [InjuryName] : InjuryApplyOnStatusModifierClass } }
	ConfigManager.Injuries.ApplyOnStatus = {}

	--- @type { [StatusName] : { [InjuryName] : InjuryRemoveOnStatus } }
	ConfigManager.Injuries.RemoveOnStatus = {}

	for injury, config in pairs(ConfigManager.ConfigCopy.injuries.injury_specific) do
		if config.damage and config.damage["damage_types"] then
			for damageType, damageConfig in pairs(config.damage["damage_types"]) do
				if not ConfigManager.Injuries.Damage[damageType] then
					ConfigManager.Injuries.Damage[damageType] = {}
				end
				ConfigManager.Injuries.Damage[damageType][injury] = damageConfig
			end
		end

		if config.apply_on_status and config.apply_on_status["applicable_statuses"] then
			for applyOnStatusName, statusConfig in pairs(config.apply_on_status["applicable_statuses"]) do
				if not ConfigManager.Injuries.ApplyOnStatus[applyOnStatusName] then
					ConfigManager.Injuries.ApplyOnStatus[applyOnStatusName] = {}
				end
				ConfigManager.Injuries.ApplyOnStatus[applyOnStatusName][injury] = statusConfig
			end
		end

		if config.remove_on_status then
			for removeOnStatusName, statusConfig in pairs(config.remove_on_status) do
				if not ConfigManager.Injuries.RemoveOnStatus[removeOnStatusName] then
					ConfigManager.Injuries.RemoveOnStatus[removeOnStatusName] = {}
				end
				ConfigManager.Injuries.RemoveOnStatus[removeOnStatusName][injury] = statusConfig
			end
		end
	end
end)

ConfigManager = {}

ConfigManager.ConfigCopy = ConfigurationStructure:GetRealConfigCopy()

-- Need to make sure the server's copy of the config is up-to-date since that's where the actual functionality is
Ext.RegisterNetListener("Injuries_UpdateConfiguration", function(_, _, _)
	ConfigurationStructure:UpdateConfigForServer()
	ConfigManager.ConfigCopy = ConfigurationStructure:GetRealConfigCopy()

	-- Making the config more code-friendly so we don't have to loop through irrelevant injuries during events
	-- Resetting the table to prevent any removed entries from persisting
	ConfigManager.Injuries = {}
	--- @type { [DamageType] : { [InjuryName] : InjuryDamage } }
	ConfigManager.Injuries.Damage = {}

	--- @type { [StatusName] : { [InjuryName] : InjuryApplyOnStatus } }
	ConfigManager.Injuries.ApplyOnStatus = {}

	--- @type { [StatusName] : { [InjuryName] : InjuryRemoveOnStatus } }
	ConfigManager.Injuries.RemoveOnStatus = {}

	for injury, config in pairs(ConfigManager.ConfigCopy.injuries.injury_specific) do
		for damageType, damageConfig in pairs(config.damage) do
			if not ConfigManager.Injuries.Damage[damageType] then
				ConfigManager.Injuries.Damage[damageType] = {}
			end
			ConfigManager.Injuries.Damage[damageType][injury] = damageConfig
		end

		for applyOnStatusName, statusConfig in pairs(config.apply_on_status) do
			if not ConfigManager.Injuries.ApplyOnStatus[applyOnStatusName] then
				ConfigManager.Injuries.ApplyOnStatus[applyOnStatusName] = {}
			end
			ConfigManager.Injuries.ApplyOnStatus[applyOnStatusName][injury] = statusConfig
		end

		for removeOnStatusName, statusConfig in pairs(config.remove_on_status) do
			if not ConfigManager.Injuries.RemoveOnStatus[removeOnStatusName] then
				ConfigManager.Injuries.RemoveOnStatus[removeOnStatusName] = {}
			end
			ConfigManager.Injuries.RemoveOnStatus[removeOnStatusName][injury] = statusConfig
		end
	end
end)

ConfigManager = {}

ConfigManager.ConfigCopy = ConfigurationStructure:GetRealConfig()
-- Need to make sure the server's copy of the config is up-to-date since that's where the actual functionality is
-- Might as well use that as the place to update the config too
Ext.RegisterNetListener(ModuleUUID .. "_UpdateConfiguration", function(_, payload, _)
	ConfigurationStructure:UpdateConfigForServer(Ext.Json.Parse(payload))
	ConfigManager.ConfigCopy = ConfigurationStructure:GetRealConfig()
end)

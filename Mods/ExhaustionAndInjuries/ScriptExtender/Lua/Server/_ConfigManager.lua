local config = FileUtils:LoadTableFile("config.json")

if not config then
	config = ConfigurationStructure:GetRealConfig()
	FileUtils:SaveTableToFile("config.json", config)
else
	ConfigurationStructure:InitializeConfig(config)
end

Ext.ServerNet.BroadcastMessage(ModuleUUID .. "_InitializedConfig", Ext.Json.Stringify(config))

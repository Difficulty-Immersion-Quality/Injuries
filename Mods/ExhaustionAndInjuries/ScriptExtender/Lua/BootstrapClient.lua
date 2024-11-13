Ext.Require("Shared/Utils/_FileUtils.lua")
Ext.Require("Shared/Utils/_ModUtils.lua")
Ext.Require("Shared/Utils/_Logger.lua")

Ext.Require("Shared/Configurations/_ConfigurationStructure.lua")

local config = FileUtils:LoadTableFile("config.json")

if not config then
	config = ConfigurationStructure:GetRealConfig()
	FileUtils:SaveTableToFile("config.json", config)
else
	ConfigurationStructure:InitializeConfig(config)
end

Ext.Require("Client/Injuries/InjuryMenu.lua")

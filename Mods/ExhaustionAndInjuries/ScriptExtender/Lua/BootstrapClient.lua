Ext.Require("Shared/Utils/_TableUtils.lua")
Ext.Require("Shared/Utils/_FileUtils.lua")
Ext.Require("Shared/Utils/_ModUtils.lua")
Ext.Require("Shared/Utils/_Logger.lua")

-- if Ext.Net.IsHost() then
	Ext.Require("Shared/Configurations/_ConfigurationStructure.lua")
	ConfigurationStructure:InitializeConfig()
	Ext.Require("Client/Injuries/InjuryMenu.lua")
-- else 
	-- Logger:BasicInfo("You're not the host of this session, so not loading functionality.")
-- end

Ext.Vars.RegisterModVariable(ModuleUUID, "Injury_Report", {
	Server = true,
	Client = true,
	WriteableOnServer = true,
	WriteableOnClient = true,
	SyncToClient = true,
	SyncToServer = true
})

Ext.Require("Shared/Utils/_FileUtils.lua")
Ext.Require("Shared/Utils/_ModUtils.lua")
Ext.Require("Shared/Utils/_Logger.lua")
Ext.Require("Shared/Utils/_TableUtils.lua")

Ext.Require("Shared/_EventCoordinator.lua")
Ext.Require("Shared/Configurations/_ConfigurationStructure.lua")
Ext.Require("Server/_ConfigManager.lua")
Ext.Require("Server/ECSPrinter.lua")

Ext.Require("Server/Injuries/_Main.lua")

-- Ext.Vars.RegisterModVariable(ModuleUUID, "Injury_Report", {
-- 	Server = true, Client = true, WriteableOnClient = true, WriteableOnServer = true, SyncToServer = true, SyncToClient = true
-- })

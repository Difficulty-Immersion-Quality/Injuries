Ext.Vars.RegisterModVariable(ModuleUUID, "Injury_Report", {
	Server = true,
	Client = true,
	WriteableOnServer = true,
	WriteableOnClient = true,
	SyncToClient = true,
	SyncToServer = true
})

Ext.Require("Utilities/Common/_Index.lua")
Ext.Require("Utilities/Networking/Channels.lua")
Ext.Require("Utilities/Advanced/_ECSPrinter.lua")

Ext.Require("Shared/Configurations/_ConfigurationStructure.lua")

Logger:ClearLogFile()

Ext.Require("Server/_DifficultyClassMap.lua")
Ext.Require("Server/_EventCoordinator.lua")

Ext.Require("Server/_ConfigManager.lua")

Ext.Require("Shared/Injuries/_InjuryCommonLogic.lua")
Ext.Require("Server/Injuries/_Damage.lua")
Ext.Require("Server/Injuries/_RandomInjuryOnCondition.lua")
Ext.Require("Server/Injuries/_Healing.lua")
Ext.Require("Server/Injuries/_ApplyOnStatus.lua")
Ext.Require("Server/Injuries/_RemoveOnStatus.lua")

Ext.Require("Server/Injuries/GoonsCustomFunctionality/_MadnessTables.lua")
Ext.Require("Server/Injuries/GoonsCustomFunctionality/_ExhaustionTables.lua")
Ext.Require("Server/Injuries/GoonsCustomFunctionality/_UsingSpellOnTargetRemoval.lua")

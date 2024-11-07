local InjuryTable = {}

Ext.Events.SessionLoaded:Subscribe(function()
	for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
		if string.find(name, "Goon_Injury_") then
			table.insert(InjuryTable, string.sub(name, string.len("Goon_Injury_") + 1))
		end
	end

	Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Injuries",
		--- @param tabHeader ExtuiTreeParent
		function(tabHeader)
			local injuryCombobox = tabHeader:AddCombo("Injuries")
			injuryCombobox.Options = InjuryTable
		end)
end)

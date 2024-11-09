local InjuryTable = {}

Ext.Events.SessionLoaded:Subscribe(function()
	for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
		if string.find(name, "Goon_Injury_") then
			local displayName = string.sub(name, string.len("Goon_Injury_") + 1)
			displayName = string.gsub(displayName, "_", " ")
			InjuryTable[displayName] = name
		end
	end

	Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Injuries",
		--- @param tabHeader ExtuiTreeParent
		function(tabHeader)
			local injuryCombobox = tabHeader:AddCombo("Injuries")

			local displayNames = {}
			for displayName, _ in pairs(InjuryTable) do
				table.insert(displayNames, displayName)
			end
			table.sort(displayNames)
			injuryCombobox.Options = displayNames
			injuryCombobox.SelectedIndex = 0

			local damageTab = tabHeader:AddSeparatorText("Damage")
			local damageTypeCombo = tabHeader:AddCombo("")
			-- damageTypeCombo:AddGroup("DamageTypes")
			local damageTypes = {}
			for _, damageType in ipairs(Ext.Enums.DamageType) do
				table.insert(damageTypes, tostring(damageType))
			end
			damageTypeCombo.Options = damageTypes
			damageTypeCombo.SelectedIndex = 0

			local damageTypeThreshold = tabHeader:AddSliderInt("")
			damageTypeThreshold.Min = {1, 1, 1, 1}
			damageTypeThreshold.Max = {100, 100, 100, 100}

			local onCritCheckbox = tabHeader:AddCheckbox("Always On Crit?", true)
			onCritCheckbox.SameLine = true

			-- damageTypeThreshold:AddGroup("DamageTypes")

			damageTypeCombo.OnChange = function()
				damageTypeThreshold.Value = damageTypeThreshold.Min
			end
			injuryCombobox.OnChange = function(comboBox, newIndex)
				damageTypeCombo.SelectedIndex = 0
				damageTypeCombo.OnChange()
			end
		end)
end)

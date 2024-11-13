--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar, injury)
	local damageTab = tabBar:AddTabItem("Damage")

	local damageTable = damageTab:AddTable("DamageTypes", 3)
	damageTable.BordersInnerH = true

	local headerRow = damageTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Damage Type")
	headerRow:AddCell():AddText("% of Total Health")

	damageTab:AddText("Add New Row")
	local damageTypeCombo = damageTab:AddCombo("")
	damageTypeCombo.SameLine = true

	local damageTypes = {}
	for _, damageType in ipairs(Ext.Enums.DamageType) do
		table.insert(damageTypes, tostring(damageType))
	end
	damageTypeCombo.Options = damageTypes
	damageTypeCombo.SelectedIndex = 0
	damageTypeCombo.WidthFitPreview = true

	--- @param combo ExtuiCombo
	--- @param selectedIndex integer
	damageTypeCombo.OnChange = function(combo, selectedIndex)
		local row = damageTable:AddRow()

		local damageType = combo.Options[selectedIndex + 1]
		InjuryMenu.ConfigurationSlice.injury_specific[injury].damage[damageType] = {}

		row:AddCell():AddText(damageType)

		local damageTypeThreshold = row:AddCell():AddSliderInt("", 10, 1, 100)

		damageTypeThreshold.OnChange = function ()
			InjuryMenu.ConfigurationSlice.injury_specific[injury].damage[damageType]["health_threshold"] = damageTypeThreshold.Value[1]
		end

		local deleteRowButton = row:AddCell():AddButton("Delete")

		deleteRowButton.OnClick = function()
			row:Destroy()
		end
	end
end)

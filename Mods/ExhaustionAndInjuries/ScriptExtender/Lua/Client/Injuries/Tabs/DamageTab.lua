--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar)
	local damageTab = tabBar:AddTabItem("Damage")

	local damageTable = damageTab:AddTable("DamageTypes", 4)

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

		row:AddCell():AddText(combo.Options[selectedIndex + 1])

		local damageTypeThreshold = row:AddCell():AddSliderInt("")
		damageTypeThreshold.Min = { 1, 1, 1, 1 }
		damageTypeThreshold.Max = { 100, 100, 100, 100 }

		local onCritCheckbox = row:AddCell():AddCheckbox("Always On Crit?", true)
		local deleteRowButton = row:AddCell():AddButton("Delete")

		deleteRowButton.OnClick = function()
			row:Destroy()
		end
	end

	damageTable.BordersOuter = true
end)

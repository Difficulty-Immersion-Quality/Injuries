--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar)
	local damageTab = tabBar:AddTabItem("Damage")

	local damageTable = damageTab:AddTable("DamageTypes", 5)
	damageTable.BordersInnerH = true

	local headerRow = damageTable:AddRow()
	headerRow:AddCell():AddText("Damage Type")
	headerRow:AddCell():AddText("% of Total Health In One Combat") -- TODO: Add tooltip explaining more
	headerRow:AddCell():AddText("Healing Subtracts From Injury Damage")
	headerRow:AddCell():AddText("Always Apply On Critical Hit")

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
		-- local thresholdTooltip = damageTypeThreshold:Tooltip()
		-- thresholdTooltip:AddText("Percentage of total health that needs to be dealt in a single hit to apply this injury")

		local healingSubtractsCheckbox = row:AddCell():AddCheckbox("", true)
		local onCritCheckbox = row:AddCell():AddCheckbox("", true)
		local deleteRowButton = row:AddCell():AddButton("Delete")

		deleteRowButton.OnClick = function()
			row:Destroy()
		end
	end
end)

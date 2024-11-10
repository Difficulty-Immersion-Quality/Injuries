--- @param tabBar ExtuiTabBar
ExhaustionMenu:RegisterTab(function(tabBar)
	local conditionTab = tabBar:AddTabItem("Apply On Combat Conditions")

	local conditionTable = conditionTab:AddTable("Application Conditions", 3)
	conditionTable.BordersInnerH = true

	local headerRow = conditionTable:AddRow()
	headerRow:AddCell():AddText("Condition")
	headerRow:AddCell():AddText("Enabled") -- TODO: Add tooltip explaining more
	headerRow:AddCell():AddText("# of Levels to Apply")

	local criticalHitRow = conditionTable:AddRow()
	criticalHitRow:AddCell():AddText("Receives Critical Hit")
	criticalHitRow:AddCell():AddCheckbox("")
	criticalHitRow:AddCell():AddSliderInt("", 0, 7, 1)

	local criticalMissRow = conditionTable:AddRow()
	criticalMissRow:AddCell():AddText("Critically Fails An Attack")
	criticalMissRow:AddCell():AddCheckbox("")
	criticalMissRow:AddCell():AddSliderInt("", 0, 7, 1)
end)

--- @param tabBar ExtuiTabBar
ExhaustionMenu:RegisterTab(function(tabBar)
	local conditionTab = tabBar:AddTabItem("Apply On Combat Conditions")

	local conditionTable = conditionTab:AddTable("ExhaustionApplicationConditions", 3)
	conditionTable.BordersInnerH = true

	local headerRow = conditionTable:AddRow()
	headerRow:AddCell():AddText("Condition")
	headerRow:AddCell():AddText("Enabled")
	headerRow:AddCell():AddText("# of Levels to Apply")

	local criticalHitRow = conditionTable:AddRow()
	criticalHitRow:AddCell():AddText("Receives Critical Hit")
	criticalHitRow:AddCell():AddCheckbox("", true)
	criticalHitRow:AddCell():AddSliderInt("", 1, 0, 7)

	local criticalMissRow = conditionTable:AddRow()
	criticalMissRow:AddCell():AddText("Critically Fails An Attack")
	criticalMissRow:AddCell():AddCheckbox("", true)
	criticalMissRow:AddCell():AddSliderInt("", 1, 0, 7)
end)

--- @param tabBar ExtuiTabBar
--- @param injury InjuryName
InjuryMenu:RegisterTab(function(tabBar, injury)
	local generalRulesTab = tabBar:AddTabItem("General Rules")

	InjuryMenu.ConfigurationSlice.injury_specific[injury].chance_of_application = InjuryMenu.ConfigurationSlice.injury_specific[injury].chance_of_application or 100

	generalRulesTab:AddText("What's the % chance of this Injury being applied when conditions are met?")
	generalRulesTab:AddText("Due to technical limitations, this can't be a save - it's just a flat roll out of 100"):SetStyle("Alpha", 0.7)
	local chanceToApplySlider = generalRulesTab:AddSliderInt("", InjuryMenu.ConfigurationSlice.injury_specific[injury].chance_of_application, 1, 100)

	chanceToApplySlider.OnChange = function()
		InjuryMenu.ConfigurationSlice.injury_specific[injury].chance_of_application = chanceToApplySlider.Value[1]
	end

	generalRulesTab:AddNewLine()

	---@type StatusData
	local injuryStat = Ext.Stats.Get(injury)
	if injuryStat.StackId and injuryStat.StackId ~= "" and injuryStat.StackPriority > 1 then
		generalRulesTab:AddText("How many stacks should be removed when this status is removed?")
		generalRulesTab:AddText("i.e. if you set 3rd Degree Burns to remove 2 stacks, you'll have 1st Degree Burns applied"):SetStyle("Alpha", 0.7)
		InjuryMenu.ConfigurationSlice.injury_specific[injury].stacks_to_remove = injuryStat.StackPriority
		local stackRemovalSlider = generalRulesTab:AddSliderInt("", injuryStat.StackPriority, 1, injuryStat.StackPriority)
		stackRemovalSlider.OnChange = function()
			InjuryMenu.ConfigurationSlice.injury_specific[injury].stacks_to_remove = stackRemovalSlider.Value[1]
		end
	end
end)

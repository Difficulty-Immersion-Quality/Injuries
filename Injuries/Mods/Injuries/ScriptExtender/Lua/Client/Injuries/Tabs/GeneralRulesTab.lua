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

end)

--- @param tabBar ExtuiTabBar
--- @param injury InjuryName
InjuryMenu:RegisterTab(function(tabBar, injury)
	local generalRulesTab = tabBar:AddTabItem(Translator:translate("General Rules"))

	InjuryMenu.ConfigurationSlice.injury_specific[injury].chance_of_application = InjuryMenu.ConfigurationSlice.injury_specific[injury].chance_of_application or 100

	generalRulesTab:AddText(Translator:translate("What's the % chance of this Injury being applied when conditions are met?"))
	generalRulesTab:AddText(Translator:translate("Due to technical limitations, this can't be a save - it's just a flat roll out of 100")):SetStyle("Alpha", 0.7)
	local chanceToApplySlider = generalRulesTab:AddSliderInt("", InjuryMenu.ConfigurationSlice.injury_specific[injury].chance_of_application, 1, 100)

	chanceToApplySlider.OnChange = function()
		InjuryMenu.ConfigurationSlice.injury_specific[injury].chance_of_application = chanceToApplySlider.Value[1]
	end
end)

Translator:RegisterTranslation({
	["General Rules"] = "h3eaac07d0b2345208937cfe70cc2602b486g",
	["What's the % chance of this Injury being applied when conditions are met?"] = "h311816e774904290af50dc14cd5dec8bf0a5",
	["Due to technical limitations, this can't be a save - it's just a flat roll out of 100"] = "h3baac0fbaf3846399a8f49ebf893fe490891",
})

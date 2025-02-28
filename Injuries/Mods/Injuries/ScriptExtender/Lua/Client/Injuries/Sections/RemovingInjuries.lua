RemovingInjuriesSettings = Section:new(Translator:translate("Removing Injuries"))

function RemovingInjuriesSettings:BuildBasicConfig(universalOptions)
	local universal = InjuryMenu.ConfigurationSlice.universal

	local removeInjuriesOnDeath = universalOptions:AddCheckbox(Translator:translate("Remove All Injuries On Death"), universal.remove_on_death)
	removeInjuriesOnDeath.OnChange = function()
		universal.remove_on_death = removeInjuriesOnDeath.Checked
	end

	local removeInjuriesOnLongRest = universalOptions:AddCheckbox(Translator:translate("Remove All Injuries On Long Rest"), universal.remove_all_on_long_rest)
	removeInjuriesOnLongRest.OnChange = function()
		universal.remove_all_on_long_rest = removeInjuriesOnLongRest.Checked
	end
end

function RemovingInjuriesSettings:BuildAdvancedConfig(parent)
	local universalSettings = InjuryMenu.ConfigurationSlice.universal
	parent:AddText(Translator:translate("How Many Different Injuries Can Be Removed At Once?")).Font = "Large"
	parent:AddText(Translator:translate(
		"If multiple injuries share the same removal conditions, only the specified number will be removed at once - injuries will be randomly chosen."))
		:SetStyle("Alpha", 0.90)

	local oneRadio = parent:AddRadioButton(Translator:translate("One"), universalSettings.how_many_injuries_can_be_removed_at_once == "One")
	local allRadio = parent:AddRadioButton(Translator:translate("All"), universalSettings.how_many_injuries_can_be_removed_at_once == "All")
	allRadio.SameLine = true

	local prioritizeSeverityText = parent:AddText(Translator:translate("What Severity Should Be Prioritized?"))
	prioritizeSeverityText.Visible = oneRadio.Active
	local prioritizeSeverityCombo = parent:AddCombo("")
	prioritizeSeverityCombo.Visible = oneRadio.Active
	prioritizeSeverityCombo.Options = {
		"Random",
		"Most Severe"
	}
	prioritizeSeverityCombo.WidthFitPreview = true
	prioritizeSeverityCombo.SelectedIndex = 1
	prioritizeSeverityCombo.OnChange = function(_, selectedIndex)
		universalSettings.injury_removal_severity_priority = prioritizeSeverityCombo.Options[selectedIndex + 1]
	end

	oneRadio.OnActivate = function()
		allRadio.Active = oneRadio.Active
		oneRadio.Active = not oneRadio.Active

		if oneRadio.Active then
			universalSettings.how_many_injuries_can_be_removed_at_once = oneRadio.Label
		end

		prioritizeSeverityText.Visible = oneRadio.Active
		prioritizeSeverityCombo.Visible = oneRadio.Active
	end

	allRadio.OnActivate = function()
		oneRadio.Active = allRadio.Active
		allRadio.Active = not allRadio.Active

		if allRadio.Active then
			universalSettings.how_many_injuries_can_be_removed_at_once = allRadio.Label
		end

		prioritizeSeverityText.Visible = oneRadio.Active
		prioritizeSeverityCombo.Visible = oneRadio.Active
	end

	return true
end

Translator:RegisterTranslation({
	["Removing Injuries"] = "h26403ff346f8465dbd6d2f5f70a5ae493fbe"
})

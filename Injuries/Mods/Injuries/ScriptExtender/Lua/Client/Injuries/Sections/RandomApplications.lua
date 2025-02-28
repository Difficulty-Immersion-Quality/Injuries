RandomApplicationSettings = Section:new(Translator:translate("Randomized Application"))

function RandomApplicationSettings:BuildBasicConfig(parent)
	local universalSettings = InjuryMenu.ConfigurationSlice.universal

	parent:AddText(Translator:translate(
		"When the below conditions are met, a random Injury that can apply for the receieved damage type will be applied to the affected character"))
	local downedCheckbox = parent:AddCheckbox(Translator:translate("Downed"), universalSettings.random_injury_conditional["Downed"])
	downedCheckbox.OnChange = function()
		universalSettings.random_injury_conditional["Downed"] = downedCheckbox.Checked
	end

	local critCheckbox = parent:AddCheckbox(Translator:translate("Suffered a Critical Hit"), universalSettings.random_injury_conditional["Suffered a Critical Hit"])
	critCheckbox.SameLine = true
	critCheckbox.OnChange = function()
		universalSettings.random_injury_conditional["Suffered a Critical Hit"] = critCheckbox.Checked
	end

	parent:AddText(Translator:translate("The below sliders configure the likelihood of an Injury with the associated Severity being chosen. Values must add up to 100%"))
	local severityTable = parent:AddTable("", 2)
	severityTable.SizingStretchProp = true

	local lowRow = severityTable:AddRow()
	local lowCell = lowRow:AddCell()
	lowCell:AddText("Low")
	local lowSeverity = lowRow:AddCell():AddSliderInt("", universalSettings.random_injury_severity_weights["Low"], 0, 100)

	local medRow = severityTable:AddRow()
	medRow:AddCell():AddText("Medium")
	local mediumSeverity = medRow:AddCell():AddSliderInt("", universalSettings.random_injury_severity_weights["Medium"], 0, 100)

	local highRow = severityTable:AddRow()
	highRow:AddCell():AddText("High")
	local highSeverity = highRow:AddCell():AddSliderInt("", universalSettings.random_injury_severity_weights["High"], 0, 100)

	local severityErrorText = parent:AddText(Translator:translate("Error: Values must add up to 100%!"))
	severityErrorText:SetColor("Text", { 1, 0.02, 0, 1 })
	severityErrorText.Visible = false
	local ensureAdditionFunction = function()
		severityErrorText.Visible = (lowSeverity.Value[1] + mediumSeverity.Value[1] + highSeverity.Value[1] ~= 100)
		if not severityErrorText.Visible then
			-- Bit of a hack due to metatable shenanigans - can't replace the whole table at once
			local weights = universalSettings.random_injury_severity_weights
			weights["Low"] = lowSeverity.Value[1]
			weights["Medium"] = mediumSeverity.Value[1]
			weights["High"] = highSeverity.Value[1]
		end
	end
	lowSeverity.OnChange = ensureAdditionFunction
	mediumSeverity.OnChange = ensureAdditionFunction
	highSeverity.OnChange = ensureAdditionFunction

	local damageFilterCheckbox = parent:AddCheckbox(Translator:translate("Only consider Injuries that are configured to apply on the relevant damage type"),
		universalSettings.random_injury_filter_by_damage_type)
	damageFilterCheckbox.TextWrapPos = 0
	damageFilterCheckbox.OnChange = function(checkbox)
		universalSettings.random_injury_filter_by_damage_type = checkbox.Checked
	end

	local damageFilterDesc = parent:AddText(
		Translator:translate("If disabled, all Injuries will be placed in the pool to be randomly selected from (if not already applied to the character);"
			.. " otherwise, only Injuries with the damage type that triggers the condition (i.e. critical hit) in their Damage tab will be considered"))
	damageFilterDesc.TextWrapPos = 0
	damageFilterDesc:SetStyle("Alpha", 0.9)
end

Translator:RegisterTranslation({
	["Randomized Application"] = "h32b8cf6763354ee0a75709f889935881fd34"
})

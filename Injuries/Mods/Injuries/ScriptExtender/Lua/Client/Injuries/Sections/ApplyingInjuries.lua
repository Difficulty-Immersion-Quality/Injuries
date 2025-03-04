ApplyingInjuriesSettings = Section:new(Translator:translate("Applying Injuries"))

function ApplyingInjuriesSettings:BuildBasicConfig(parent)
	local universalSettings = InjuryMenu.ConfigurationSlice.universal

	--#region Who Can Receive Injuries
	parent:AddText(Translator:translate("Who Can Receive Injuries?"))
	local partyCheckbox = parent:AddCheckbox(Translator:translate("Party Members"), universalSettings.who_can_receive_injuries["Party Members"])
	partyCheckbox.OnChange = function()
		universalSettings.who_can_receive_injuries["Party Members"] = partyCheckbox.Checked
	end

	local allyCheckbox = parent:AddCheckbox(Translator:translate("Allies"), universalSettings.who_can_receive_injuries["Allies"])
	allyCheckbox.SameLine = true
	allyCheckbox.OnChange = function()
		universalSettings.who_can_receive_injuries["Allies"] = allyCheckbox.Checked
	end

	local enemyCheckbox = parent:AddCheckbox(Translator:translate("Enemies"), universalSettings.who_can_receive_injuries["Enemies"])
	enemyCheckbox.SameLine = true
	enemyCheckbox.OnChange = function()
		universalSettings.who_can_receive_injuries["Enemies"] = enemyCheckbox.Checked
	end

	parent:AddNewLine()

	local applyOutsideCombatCheckbox = parent:AddCheckbox(Translator:translate("Apply Injuries Outside of Combat"), universalSettings.apply_injuries_outside_combat)
	applyOutsideCombatCheckbox.OnChange = function()
		universalSettings.apply_injuries_outside_combat = applyOutsideCombatCheckbox.Checked
	end
end

function ApplyingInjuriesSettings:BuildAdvancedConfig(parent)
	local universalSettings = InjuryMenu.ConfigurationSlice.universal

	local tickText = parent:AddSeparatorText(Translator:translate("When Does the Damage/Status Tick Counter Reset?"))
	tickText:SetStyle("SeparatorTextAlign", 0, .5)
	tickText.Font = "Large"

	local cumulationCombo = parent:AddCombo("")
	cumulationCombo.WidthFitPreview = true
	cumulationCombo.Options = {
		"Attack/Tick",
		"Round",
		"Combat",
		"Short Rest",
		"Long Rest"
	}
	for index, option in pairs(cumulationCombo.Options) do
		if option == universalSettings.when_does_counter_reset then
			cumulationCombo.SelectedIndex = index - 1
		end
	end

	local healingCheckbox = parent:AddCheckbox(Translator:translate("Healing Subtracts From Damage Counter"), universalSettings.healing_subtracts_injury_damage)
	local healingText = parent:AddText(
		Translator:translate("Ratio of Healing:Injury - 50% means you need 2 points of healing to remove 1 point of Injury damage"))
	local healingMultiplierSlider = parent:AddSliderInt("", universalSettings.healing_subtracts_injury_damage_modifier * 100, 0, 200)

	healingMultiplierSlider.OnChange = function(_)
		universalSettings.healing_subtracts_injury_damage_modifier = healingMultiplierSlider.Value[1] / 100
	end

	healingCheckbox.OnChange = function(combo, value)
		healingText.Visible = value
		healingMultiplierSlider.Visible = value
		universalSettings.healing_subtracts_injury_damage = healingCheckbox.Checked
	end

	if cumulationCombo.SelectedIndex == 0 then
		healingCheckbox.Visible = false
		healingText.Visible = false
		healingMultiplierSlider.Visible = false
	end

	cumulationCombo.OnChange = function(combo, selectedIndex)
		healingCheckbox.Visible = selectedIndex ~= 0
		healingText.Visible = selectedIndex ~= 0
		healingMultiplierSlider.Visible = selectedIndex ~= 0

		universalSettings.when_does_counter_reset = cumulationCombo.Options[selectedIndex + 1]
	end

	--#region Application Chance
	parent:AddNewLine()
	local applicationChanceText = parent:AddSeparatorText(Translator:translate("What is the % chance of an Injury being applied when the conditions are met?"))
	applicationChanceText:SetStyle("SeparatorTextAlign", 0, .5)
	applicationChanceText.Font = "Large"

	parent:AddText(Translator:translate("Configured by Severity - Due to technical limitations, this can't be a save, just a flat roll out of 100")):SetStyle("Alpha", 0.65)

	local severityTable = parent:AddTable("", 2)
	severityTable.SizingStretchProp = true

	for key, value in TableUtils:OrderedPairs(universalSettings.application_chance_by_severity, function(key)
		return key == "Exclude" and 0 or (key == "Low" and 1) or (key == "Medium" and 2) or (key == "High" and 3) or 4
	end) do
		if type(value) ~= "table" then
			local severityModifierRow = severityTable:AddRow()
			local severityModifierCell = severityModifierRow:AddCell()
			severityModifierCell:AddText(key)
			local severityModifierSlider = severityModifierRow:AddCell():AddSliderInt("", value, 0, 100)
			severityModifierSlider.IDContext = key .. "SeverityModifier"
			severityModifierSlider.OnChange = function()
				universalSettings.application_chance_by_severity[key] = severityModifierSlider.Value[1]
			end
		end
	end

	parent:AddText(Translator:translate("How much should the application chance increase/decrease when the below conditions are met?"))
	local desc = parent:AddText(
		Translator:translate(
		"These modifiers are additive, not multiplicative, meaning if a low severity injury has a 50% chance of being applied, but maximum weapon damage was dealt and that has a modifier of 10%, then the injury will have a 60% chance of being applied"))
	desc.TextWrapPos = 0
	desc:SetStyle("Alpha", 0.65)

	local severityModiferTable = parent:AddTable("", 2)
	severityModiferTable.SizingStretchProp = true
	for key, value in TableUtils:OrderedPairs(universalSettings.application_chance_by_severity.modifiers) do
		if type(value) ~= "table" then
			local severityModifierRow = severityModiferTable:AddRow()
			local severityModifierCell = severityModifierRow:AddCell()
			local keyText = severityModifierCell:AddText(key)
			if key == "Each Existing Injury Of Same Severity" then
				keyText.Label = keyText.Label .. " (?)"
				keyText:Tooltip():AddText("\t " .. "If the character has 2 Medium-severity injuries already applied and this modifier is set to -5%, then the application chance for all Medium-severity injuries will be -10%").TextWrapPos = 600
			end

			local severityModifierSlider = severityModifierRow:AddCell():AddSliderInt("", value, -100, 100)
			severityModifierSlider.IDContext = key .. "Modifier"
			severityModifierSlider.OnChange = function()
				universalSettings.application_chance_by_severity.modifiers[key] = severityModifierSlider.Value[1]
			end
		end
	end
	--#endregion

	parent:AddNewLine()
	local npcText = parent:AddSeparatorText(Translator:translate("Customize Damage + Status Multipliers For NPCs"))
	npcText:SetStyle("SeparatorTextAlign", 0, .5)
	npcText.Font = "Large"

	local enemyDesc = parent:AddText(
		Translator:translate(
			"These % multipliers will apply after the ones set per-injury (0 = no Injury damage will be taken) - NPC-type determinations are made by their associated Experience Reward Category. 'Base' will be overriden by more specific categories if applicable."
			.. " Supports Mod-added XPReward categories as long as they use the same names prepended with `_` - e.g. MMM_Combatant"))
	enemyDesc.TextWrapPos = 0
	enemyDesc:SetStyle("Alpha", 0.65)

	local enemyMultTable = parent:AddTable("Enemy Multiplier Table", 2)
	enemyMultTable.SizingStretchProp = true

	local function buildNpcMultiSlider(npcType)
		local newRow = enemyMultTable:AddRow()
		newRow:AddCell():AddText(npcType)

		if not universalSettings.npc_multipliers[npcType] then
			universalSettings.npc_multipliers[npcType] = 1
		end

		local newSlider = newRow:AddCell():AddSliderInt("", math.floor(universalSettings.npc_multipliers[npcType] * 100), 0, 500)
		newSlider.OnChange = function(slider)
			---@cast slider ExtuiSliderInt
			universalSettings.npc_multipliers[npcType] = slider.Value[1] / 100
		end

		return newRow
	end

	buildNpcMultiSlider("Base")

	local addRowButton = parent:AddButton("+")
	local npcPopop = parent:AddPopup("")
	local npcTypes = { "Boss", "MiniBoss", "Elite", "Combatant", "Pack", "Zero", "Civilian" }

	for i, npcType in pairs(npcTypes) do
		---@type ExtuiSelectable
		local enemySelect = npcPopop:AddSelectable(npcType, "DontClosePopups")

		enemySelect.OnActivate = function()
			if enemySelect.UserData then
				enemySelect.UserData:Destroy()
				enemySelect.UserData = nil
				universalSettings.npc_multipliers[npcType] = nil
			else
				enemySelect.UserData = buildNpcMultiSlider(npcType)
			end
		end

		if universalSettings.npc_multipliers[npcType] then
			enemySelect.Selected = true
			enemySelect:OnActivate()
		end
	end

	addRowButton.OnClick = function()
		npcPopop:Open()
	end

	return true
end

Translator:RegisterTranslation({
	["Applying Injuries"] = "hbd5660f30114470f96fd309b831455c4632b",
	["Who Can Receive Injuries?"] = "h00f45a44ab9345c1b1106d6852ebcc4d9cb3",
	["Party Members"] = "h9df2a1fcaea949aeb733c493d4d7045ad3d3",
	["Allies"] = "hb2b2ef0a495543a4a5596f821e25226410a7",
	["Enemies"] = "h67f450fc249442b795305a91a9119e3e3790",
	["When Does the Damage/Status Tick Counter Reset?"] = "hc47037eb48214da092ef0e91442a316aff27",
	["Healing Subtracts From Damage Counter"] = "h3cccf831d7dd4ab890ea564320f73af45bc2",
	["Ratio of Healing:Injury - 50% means you need 2 points of healing to remove 1 point of Injury damage"] = "h516dbf2301714121b4f734955aa01f83f997",
	["How much should the application chance increase/decrease when the below conditions are met?"] = "h2ed2ba9c679e4311b9d7b991246d84ff16g2",
	["These modifiers are additive, not multiplicative, meaning if a low severity injury has a 50% chance of being applied, but maximum weapon damage was dealt and that has a modifier of 10%, then the injury will have a 60% chance of being applied"] =
	"h3f75c2db58974c47b8f5553e0fe58301831b",
	["If the character has 2 Medium-severity injuries already applied and this modifier is set to -5%, then the application chance for all Medium-severity injuries will be -10%"] = "hbaa3cadad3c048759ce144bfe8bc76e5b7a9",
	["Customize Damage + Status Multipliers For NPCs"] = "h38c9a5d7d98b4e8fadcb61ceefe9940a0dd4",
	["Apply Injuries Outside of Combat"] = "h19e7eed71ae343bf8571aa5e4ae65ed46c1c",
	["Configured by Severity - Due to technical limitations, this can't be a save, just a flat roll out of 100"] = "h51314d99b05b481f849ebd5a3bee1fa61dgf",
	["What is the % chance of an Injury being applied when the conditions are met?"] = "h0b8d482b2c0841a8bf9ff897fe2023edfafa",
	["These % multipliers will apply after the ones set per-injury (0 = no Injury damage will be taken) - NPC-type determinations are made by their associated Experience Reward Category. 'Base' will be overriden by more specific categories if applicable."
	.. " Supports Mod-added XPReward categories as long as they use the same names prepended with `_` - e.g. MMM_Combatant"] = "h9bda3b06d6b4412ab079c3bcdd9b6aed3ec1",
})

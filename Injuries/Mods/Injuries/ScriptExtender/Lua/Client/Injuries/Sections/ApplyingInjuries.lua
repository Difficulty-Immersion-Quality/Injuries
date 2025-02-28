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

	local applyOutsideCombatCheckbox = parent:AddCheckbox("Apply Injuries Outside of Combat", universalSettings.apply_injuries_outside_combat)
	parent:AddText("If disabled, damage and statuses application won't be processed while not in combat"):SetStyle("Alpha", 0.65)
	applyOutsideCombatCheckbox.OnChange = function()
		universalSettings.apply_injuries_outside_combat = applyOutsideCombatCheckbox.Checked
	end
end

function ApplyingInjuriesSettings:BuildAdvancedConfig(parent)
	local universalSettings = InjuryMenu.ConfigurationSlice.universal

	parent:AddText(Translator:translate("When Does the Damage/Status Tick Counter Reset?"))

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

	parent:AddNewLine()
	parent:AddText(Translator:translate("Customize Damage + Status Multipliers For NPCs"))
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
	["Applying Injuries"] = "hbd5660f30114470f96fd309b831455c4632b"
})

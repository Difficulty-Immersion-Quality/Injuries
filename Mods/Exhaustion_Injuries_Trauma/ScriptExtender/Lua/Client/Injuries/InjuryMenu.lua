---@param configToCount table
---@return number
local function countInjuryConfig(configToCount)
	local count = 0

	if next(configToCount) then
		for _, _ in pairs(configToCount) do
			count = count + 1
		end
	end

	return count
end

---@param displayTooltip ExtuiTooltip
---@param injury_config Injury
local function generateInjuryCountTooltip(displayTooltip, injury_config)
	for _, child in pairs(displayTooltip.Children) do
		child:Destroy()
	end

	displayTooltip:AddText(string.format("ApplyOnStatus: %d", countInjuryConfig(injury_config.apply_on_status["applicable_statuses"])))
	displayTooltip:AddText(string.format("Damage: %d", countInjuryConfig(injury_config.damage["damage_types"])))
	displayTooltip:AddText(string.format("RemoveOnStatus: %d", countInjuryConfig(injury_config.remove_on_status)))
	displayTooltip:AddText(string.format("Races: %d", countInjuryConfig(injury_config.character_multipliers["races"])))
	displayTooltip:AddText(string.format("Tags: %d", countInjuryConfig(injury_config.character_multipliers["tags"])))
end


InjuryMenu = {}
InjuryMenu.Tabs = { ["Generators"] = {} }
InjuryMenu.ConfigurationSlice = ConfigurationStructure.config.injuries

Ext.Require("Client/Injuries/InjuryReport.lua")

function InjuryMenu:RegisterTab(tabGenerator)
	table.insert(InjuryMenu.Tabs["Generators"], tabGenerator)
end

Ext.Require("Client/Injuries/Tabs/DamageTab.lua")
Ext.Require("Client/Injuries/Tabs/ApplyOnStatusTab.lua")
Ext.Require("Client/Injuries/Tabs/CharacterMultipliers.lua")
Ext.Require("Client/Injuries/Tabs/RemoveOnStatusTab.lua")

Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Injuries",
	--- @param tabHeader ExtuiTreeParent
	function(tabHeader)
		tabHeader.TextWrapPos = 0

		--#region Universal Options
		local universalOptions = tabHeader:AddCollapsingHeader("Universal Options")
		local universal = InjuryMenu.ConfigurationSlice.universal

		--#region Who Can Receive Injuries
		universalOptions:AddText("Who Can Receive Injuries?")
		local partyCheckbox = universalOptions:AddCheckbox("Party Members", universal.who_can_receive_injuries["Party Members"])
		partyCheckbox.OnChange = function()
			universal.who_can_receive_injuries["Party Members"] = partyCheckbox.Checked
		end

		local allyCheckbox = universalOptions:AddCheckbox("Allies", universal.who_can_receive_injuries["Allies"])
		allyCheckbox.SameLine = true
		allyCheckbox.OnChange = function()
			universal.who_can_receive_injuries["Allies"] = allyCheckbox.Checked
		end

		local enemyCheckbox = universalOptions:AddCheckbox("Enemies", universal.who_can_receive_injuries["Enemies"])
		enemyCheckbox.SameLine = true
		enemyCheckbox.OnChange = function()
			universal.who_can_receive_injuries["Enemies"] = enemyCheckbox.Checked
		end
		--#endregion

		--#region Injury Removal
		universalOptions:AddNewLine()

		universalOptions:AddText("How Many Different Injuries Can Be Removed At Once?")
		universalOptions:AddText("If multiple injuries share the same removal conditions, only the specified number will be removed at once - injuries will be randomly chosen.")
			:SetStyle("Alpha", 0.90)

		local oneRadio = universalOptions:AddRadioButton("One", universal.how_many_injuries_can_be_removed_at_once == "One")
		local allRadio = universalOptions:AddRadioButton("All", universal.how_many_injuries_can_be_removed_at_once == "All")
		allRadio.SameLine = true

		local prioritizeSeverityText = universalOptions:AddText("What Severity Should Be Prioritized?")
		prioritizeSeverityText.Visible = oneRadio.Active
		local prioritizeSeverityCombo = universalOptions:AddCombo("")
		prioritizeSeverityCombo.Visible = oneRadio.Active
		prioritizeSeverityCombo.Options = {
			"Random",
			"Most Severe"
		}
		prioritizeSeverityCombo.SelectedIndex = 1
		prioritizeSeverityCombo.OnChange = function(_, selectedIndex)
			universal.injury_removal_severity_priority = prioritizeSeverityCombo.Options[selectedIndex + 1]
		end

		oneRadio.OnActivate = function()
			allRadio.Active = oneRadio.Active
			oneRadio.Active = not oneRadio.Active

			if oneRadio.Active then
				universal.how_many_injuries_can_be_removed_at_once = oneRadio.Label
			end

			prioritizeSeverityText.Visible = oneRadio.Active
			prioritizeSeverityCombo.Visible = oneRadio.Active
		end

		allRadio.OnActivate = function()
			oneRadio.Active = allRadio.Active
			allRadio.Active = not allRadio.Active

			if allRadio.Active then
				universal.how_many_injuries_can_be_removed_at_once = allRadio.Label
			end

			prioritizeSeverityText.Visible = oneRadio.Active
			prioritizeSeverityCombo.Visible = oneRadio.Active
		end

		local removeInjuriesOnDeath = universalOptions:AddCheckbox("Remove All Injuries On Death", universal.remove_on_death)
		removeInjuriesOnDeath.OnChange = function()
			universal.remove_on_death = removeInjuriesOnDeath.Checked
		end
		--#endregion

		--#region Damage Counter
		universalOptions:AddNewLine()
		universalOptions:AddText("When Does the Damage/Status Tick Counter Reset?")
		universalOptions:AddText("If anything shorter than Short Rest is selected, Injury Counters will not be processed outside of combat."):SetStyle("Alpha", 0.90)

		local cumulationCombo = universalOptions:AddCombo("")
		cumulationCombo.Options = {
			"Attack/Tick",
			"Round",
			"Combat",
			"Short Rest",
			"Long Rest"
		}
		for index, option in pairs(cumulationCombo.Options) do
			if option == universal.when_does_counter_reset then
				cumulationCombo.SelectedIndex = index - 1
			end
		end

		local healingCheckbox = universalOptions:AddCheckbox("Healing Subtracts From Damage Counter", universal.healing_subtracts_injury_damage)
		local healingText = universalOptions:AddText(
			"Ratio of Healing:Injury - 50% means you need 2 points of healing to remove 1 point of Injury damage")
		local healingMultiplierSlider = universalOptions:AddSliderInt("", universal.healing_subtracts_injury_damage_modifier * 100, 0, 200)

		healingMultiplierSlider.OnChange = function(_)
			universal.healing_subtracts_injury_damage_modifier = healingMultiplierSlider.Value[1] / 100
		end

		healingCheckbox.OnChange = function(combo, value)
			healingText.Visible = value
			healingMultiplierSlider.Visible = value
			universal.healing_subtracts_injury_damage = healingCheckbox.Checked
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

			universal.when_does_counter_reset = cumulationCombo.Options[selectedIndex + 1]
		end

		universalOptions:AddNewLine()
		universalOptions:AddText("Customize Damage + Status Multipliers For NPCs")
		local enemyDesc = universalOptions:AddText(
			"These % multipliers will apply after the ones set per-injury (0 = no Injury damage will be taken) - NPC-type determinations are made by their associated Experience Reward Category. 'Base' will be overriden by more specific categories if applicable."
			.. " Supports Mod-added XPReward categories as long as they use the same names prepended with `_` - e.g. MMM_Combatant")
		enemyDesc.TextWrapPos = 0
		enemyDesc:SetStyle("Alpha", 0.9)

		local enemyMultTable = universalOptions:AddTable("Enemy Multiplier Table", 2)
		enemyMultTable.SizingStretchProp = true

		local function buildNpcMultiSlider(npcType)
			local newRow = enemyMultTable:AddRow()
			newRow:AddCell():AddText(npcType)

			if not universal.npc_multipliers[npcType] then
				universal.npc_multipliers[npcType] = 1
			end

			local newSlider = newRow:AddCell():AddSliderInt("", universal.npc_multipliers[npcType] * 100, 0, 500)
			newSlider.OnChange = function(slider)
				---@cast slider ExtuiSliderInt
				universal.npc_multipliers[npcType] = math.floor(slider.Value[1] * 100 + 0.5) / 10000
			end

			return newRow
		end

		buildNpcMultiSlider("Base")

		local addRowButton = universalOptions:AddButton("+")
		local npcPopop = universalOptions:AddPopup("")
		local npcTypes = { "Boss", "MiniBoss", "Elite", "Combatant", "Pack", "Zero", "Civilian" }

		for i, npcType in pairs(npcTypes) do
			---@type ExtuiSelectable
			local enemySelect = npcPopop:AddSelectable(npcType, "DontClosePopups")

			enemySelect.OnActivate = function()
				if enemySelect.UserData then
					enemySelect.UserData:Destroy()
					enemySelect.UserData = nil
					universal.npc_multipliers[npcType] = nil
				else
					enemySelect.UserData = buildNpcMultiSlider(npcType)
				end
			end

			if universal.npc_multipliers[npcType] then
				enemySelect.Selected = true
				enemySelect:OnActivate()
			end
		end

		addRowButton.OnClick = function()
			npcPopop:Open()
		end

		--#endregion

		--#region Severity
		local severityHeader = tabHeader:AddCollapsingHeader("Severity")
		severityHeader:AddText("When the below conditions are met, a random Injury that can apply for the receieved damage type will be applied to the affected character")
		local downedCheckbox = severityHeader:AddCheckbox("Downed", universal.random_injury_conditional["Downed"])
		downedCheckbox.OnChange = function()
			universal.random_injury_conditional["Downed"] = downedCheckbox.Checked
		end

		local critCheckbox = severityHeader:AddCheckbox("Suffered a Critical Hit", universal.random_injury_conditional["Suffered a Critical Hit"])
		critCheckbox.SameLine = true
		critCheckbox.OnChange = function()
			universal.random_injury_conditional["Suffered a Critical Hit"] = critCheckbox.Checked
		end

		severityHeader:AddText("The below sliders configure the likelihood of an Injury with the associated Severity being chosen. Values must add up to 100%")
		local severityTable = severityHeader:AddTable("", 2)
		severityTable.SizingStretchProp = true

		local lowRow = severityTable:AddRow()
		local lowCell = lowRow:AddCell()
		lowCell:AddText("Low")
		local lowSeverity = lowRow:AddCell():AddSliderInt("", universal.random_injury_severity_weights["Low"], 0, 100)

		local medRow = severityTable:AddRow()
		medRow:AddCell():AddText("Medium")
		local mediumSeverity = medRow:AddCell():AddSliderInt("", universal.random_injury_severity_weights["Medium"], 0, 100)

		local highRow = severityTable:AddRow()
		highRow:AddCell():AddText("High")
		local highSeverity = highRow:AddCell():AddSliderInt("", universal.random_injury_severity_weights["High"], 0, 100)

		local severityErrorText = severityHeader:AddText("Error: Values must add up to 100%!")
		severityErrorText:SetColor("Text", { 1, 0.02, 0, 1 })
		severityErrorText.Visible = false
		local ensureAdditionFunction = function()
			severityErrorText.Visible = (lowSeverity.Value[1] + mediumSeverity.Value[1] + highSeverity.Value[1] ~= 100)
			if not severityErrorText.Visible then
				-- Bit of a hack due to metatable shenanigans - can't replace the whole table at once
				local weights = universal.random_injury_severity_weights
				weights["Low"] = lowSeverity.Value[1]
				weights["Medium"] = mediumSeverity.Value[1]
				weights["High"] = highSeverity.Value[1]
			end
		end
		lowSeverity.OnChange = ensureAdditionFunction
		mediumSeverity.OnChange = ensureAdditionFunction
		highSeverity.OnChange = ensureAdditionFunction

		local damageFilterCheckbox = severityHeader:AddCheckbox("Only consider Injuries that are configured to apply on the relevant damage type",
			universal.random_injury_filter_by_damage_type)
		damageFilterCheckbox.TextWrapPos = 0
		damageFilterCheckbox.OnChange = function(checkbox)
			universal.random_injury_filter_by_damage_type = checkbox.Checked
		end

		local damageFilterDesc = severityHeader:AddText(
			"If disabled, all Injuries will be placed in the pool to be randomly selected from (if not already applied to the character);"
			.. "otherwise, only Injuries with the damage type that triggers the condition (i.e. critical hit) in their Damage tab will be considered")
		damageFilterDesc.TextWrapPos = 0
		damageFilterDesc:SetStyle("Alpha", 0.9)

		--#endregion

		--#endregion

		--#region Injury-Specific Options
		tabHeader:AddSeparatorText("Injury-Specific Options")

		local reportButton = tabHeader:AddButton("Open Injury Report")
		reportButton.OnClick = function()
			InjuryReport:BuildReportWindow()
		end

		local systemGroup = tabHeader:AddGroup("Systems")

		function AddSystem(system)
			local systemHeader = systemGroup:AddCollapsingHeader(system)
			systemHeader.DefaultOpen = false

			systemHeader:AddButton("Delete System").OnClick = function()
				for injury, _ in pairs(InjuryMenu.ConfigurationSlice.injury_specific) do
					if string.find(string.upper(injury), "^" .. string.upper(system) .. ".*") then
						InjuryMenu.ConfigurationSlice.injury_specific[injury].delete = true
						InjuryMenu.ConfigurationSlice.injury_specific[injury] = nil
					end
				end

				local systemCopy = {}
				for _, existing_system in pairs(InjuryMenu.ConfigurationSlice.systems) do
					if existing_system ~= system then
						table.insert(systemCopy, existing_system)
					end
				end
				InjuryMenu.ConfigurationSlice.systems.delete = true
				InjuryMenu.ConfigurationSlice.systems = systemCopy
				systemHeader:Destroy()
			end

			local injuryTable = systemHeader:AddTable(system .. "_InjuryTable", 3)
			injuryTable.BordersInnerH = true
			injuryTable.PreciseWidths = true

			local headerRow = injuryTable:AddRow()
			headerRow.Headers = true
			headerRow:AddCell():AddText("Injury")
			headerRow:AddCell():AddText("Severity")
			headerRow:AddCell():AddText("Actions")

			local injuryDisplayNames = {}
			local injuriesDisplayMap = {}

			-- ConfigurationStructure:RegisterPostConfigInitializers(function()
			for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
				if string.find(string.upper(name), "^" .. string.upper(system) .. ".*") then
					local displayName = string.sub(name, string.len(system) + 1)
					displayName = string.gsub(displayName, "_", " ")

					displayName = Ext.Loca.GetTranslatedString(Ext.Stats.Get(name).DisplayName, displayName)

					table.insert(injuryDisplayNames, displayName)
					injuriesDisplayMap[displayName] = name
				end
			end

			-- This is why we need a list and a map - too lazy to write a sort myself
			table.sort(injuryDisplayNames)

			for _, displayName in pairs(injuryDisplayNames) do
				local injuryName = injuriesDisplayMap[displayName]
				if not InjuryMenu.ConfigurationSlice.injury_specific[injuryName] then
					InjuryMenu.ConfigurationSlice.injury_specific[injuryName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class)
				end
				local injury_config = InjuryMenu.ConfigurationSlice.injury_specific[injuryName]

				local newRow = injuryTable:AddRow()
				local displayCell = newRow:AddCell()
				displayCell:AddImage(Ext.Stats.Get(injuryName).Icon, { 36, 36 })
				displayCell:AddText(displayName).SameLine = true
				local displayTooltip = displayCell:Tooltip()
				displayCell.OnHoverEnter = function()
					generateInjuryCountTooltip(displayTooltip, injury_config)
				end

				local severityCombo = newRow:AddCell():AddCombo("")
				severityCombo.Options = {
					"Low",
					"Medium",
					"High"
				}
				for index, option in pairs(severityCombo.Options) do
					if option == injury_config.severity then
						severityCombo.SelectedIndex = index - 1
						break
					end
				end

				severityCombo.OnChange = function(_, selectedIndex)
					injury_config.severity = severityCombo.Options[selectedIndex + 1]
				end

				local buttonCell = newRow:AddCell()
				local customizeButton = buttonCell:AddButton("Customize")
				local injuryPopup
				customizeButton.OnClick = function()
					injuryPopup = Ext.IMGUI.NewWindow("Customizing " .. displayName)
					injuryPopup.TextWrapPos = 0
					injuryPopup.Closeable = true
					-- injuryPopup.HorizontalScrollbar = true

					local newTabBar = injuryPopup:AddTabBar("InjuryTabBar")
					newTabBar.TextWrapPos = 0
					for _, tabGenerator in pairs(InjuryMenu.Tabs.Generators) do
						local success, error = pcall(function()
							tabGenerator(newTabBar, injuryName)
						end)

						if not success then
							Logger:BasicError("Error while generating a new tab for the Injury Table\n\t%s", error)
						end
					end
				end

				local resetButton = buttonCell:AddButton("Reset")
				resetButton.SameLine = true

				resetButton.OnClick = function()
					if injuryPopup then
						injuryPopup.Open = false
					end

					InjuryMenu.ConfigurationSlice.injury_specific[injuryName].delete = true
					InjuryMenu.ConfigurationSlice.injury_specific[injuryName] = nil
					InjuryMenu.ConfigurationSlice.injury_specific[injuryName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class)
					injury_config = InjuryMenu.ConfigurationSlice.injury_specific[injuryName]

					severityCombo.SelectedIndex = 1
				end

				local copyButton = buttonCell:AddButton("Copy")
				copyButton.SameLine = true

				copyButton.OnClick = function()
					local copyPopup = Ext.IMGUI.NewWindow("Copying Injury Configs")
					copyPopup.Closeable = true

					copyPopup:AddText("Copying from: " .. displayName)
					copyPopup:AddText("Close any Customizing windows you have open - they'll show stale data after this runs (fix TBD)").TextWrapPos = 0
					copyPopup:AddNewLine()

					copyPopup:AddSeparatorText("Which Configs Should Be Copied?")
					local copyWhatGroup = copyPopup:AddGroup("CopyWhat")
					copyWhatGroup:AddCheckbox("ApplyOnStatus", true).UserData = "apply_on_status"

					local dmg = copyWhatGroup:AddCheckbox("Damage", true)
					dmg.SameLine = true
					dmg.UserData = "damage"

					local charMultipliers = copyWhatGroup:AddCheckbox("Character Multipliers", true)
					charMultipliers.SameLine = true
					charMultipliers.UserData = "character_multipliers"

					local removeStatus = copyWhatGroup:AddCheckbox("RemoveOnStatus", true)
					removeStatus.SameLine = true
					removeStatus.UserData = "remove_on_status"

					copyPopup:AddNewLine()
					copyPopup:AddSeparatorText("What Injuries should these configs be copied to?")
					local copyToGroup = copyPopup:AddGroup("CopyTo")
					for _, otherDisplayName in pairs(injuryDisplayNames) do
						if displayName ~= otherDisplayName then
							copyToGroup:AddCheckbox(otherDisplayName, false).UserData = injuriesDisplayMap[otherDisplayName]
						end
					end

					copyPopup:AddButton("Copy Configs").OnClick = function()
						local configsToCopy = {}
						for _, child in pairs(copyWhatGroup.Children) do
							---@cast child ExtuiCheckbox
							if child.Checked then
								table.insert(configsToCopy, child.UserData)
							end
						end

						-- Since we use Metatable proxies in ConfigStructure and TableUtils doesn't use pairs, we have to operate on the real table
						local configCopy = ConfigurationStructure:GetRealConfigCopy().injuries.injury_specific[injuryName]
						for _, child in pairs(copyToGroup.Children) do
							---@cast child ExtuiCheckbox
							if child.Checked then
								local otherInjuryName = child.UserData
								for _, configToCopy in pairs(configsToCopy) do
									InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName][configToCopy].delete = true
									InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName][configToCopy] = TableUtils:DeeplyCopyTable(configCopy[configToCopy])
								end
							end
						end

						copyPopup.Open = false
					end
				end
			end
		end

		for _, system in pairs(InjuryMenu.ConfigurationSlice.systems) do
			AddSystem(system)
		end

		--#region Systems
		tabHeader:AddSeparatorText("Register a New Injury System")
		tabHeader:AddText("Enter the prefix used in all Stats belonging to a single system (e.g. Goon_Injury_Homebrew or Goon_Injury_Grit_And_Glory) to create a new section dedicated to the system." ..
			" All Stats belonging to the registered system(s) will automatically be known and used by this mod - if you want to exclude a system from processing, you must delete it - configurations will not be saved").TextWrapPos = 0

		local systemInput = tabHeader:AddInputText("")
		systemInput.Hint = "Case-insensitive - only specify the prefix (e.g. Goon_Injury_Homebrew)"
		systemInput.AutoSelectAll = true
		systemInput.EscapeClearsAll = true

		local search = tabHeader:AddButton("Search")

		search.OnClick = function()
			if #systemInput.Text > 0 then
				table.insert(InjuryMenu.ConfigurationSlice.systems, systemInput.Text)
				AddSystem(systemInput.Text)
			end
		end
		--#endregion

		--#endregion
	end
)

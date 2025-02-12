---@type {[string] : StatusData}
local cachedStats = {}

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

InjuryMenu = {}
InjuryMenu.Tabs = { ["Generators"] = {} }
InjuryMenu.ConfigurationSlice = ConfigurationStructure.config.injuries

Ext.Require("Client/Injuries/InjuryReport.lua")

function InjuryMenu:RegisterTab(tabGenerator)
	table.insert(InjuryMenu.Tabs["Generators"], tabGenerator)
end

Ext.Require("Client/Injuries/Tabs/GeneralRulesTab.lua")
Ext.Require("Client/Injuries/Tabs/DamageTab.lua")
Ext.Require("Client/Injuries/Tabs/ApplyOnStatusTab.lua")
Ext.Require("Client/Injuries/Tabs/CharacterMultipliers.lua")
Ext.Require("Client/Injuries/Tabs/RemoveOnStatusTab.lua")

local initialized = false
Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Injuries",
	--- @param tabHeader ExtuiTreeParent
	function(tabHeader)
		if initialized then
			return
		end
		initialized = true
		tabHeader.TextWrapPos = 0

		--#region Universal Options
		local universalOptions = tabHeader:AddCollapsingHeader(Translator:translate("Universal Options"))
		local universal = InjuryMenu.ConfigurationSlice.universal

		--#region Who Can Receive Injuries
		universalOptions:AddText(Translator:translate("Who Can Receive Injuries?")).Font = "Large"
		local partyCheckbox = universalOptions:AddCheckbox(Translator:translate("Party Members"), universal.who_can_receive_injuries["Party Members"])
		partyCheckbox.OnChange = function()
			universal.who_can_receive_injuries["Party Members"] = partyCheckbox.Checked
		end

		local allyCheckbox = universalOptions:AddCheckbox(Translator:translate("Allies"), universal.who_can_receive_injuries["Allies"])
		allyCheckbox.SameLine = true
		allyCheckbox.OnChange = function()
			universal.who_can_receive_injuries["Allies"] = allyCheckbox.Checked
		end

		local enemyCheckbox = universalOptions:AddCheckbox(Translator:translate("Enemies"), universal.who_can_receive_injuries["Enemies"])
		enemyCheckbox.SameLine = true
		enemyCheckbox.OnChange = function()
			universal.who_can_receive_injuries["Enemies"] = enemyCheckbox.Checked
		end
		--#endregion

		--#region Injury Removal
		universalOptions:AddNewLine()

		universalOptions:AddText(Translator:translate("How Many Different Injuries Can Be Removed At Once?")).Font = "Large"
		universalOptions:AddText(Translator:translate("If multiple injuries share the same removal conditions, only the specified number will be removed at once - injuries will be randomly chosen."))
			:SetStyle("Alpha", 0.90)

		local oneRadio = universalOptions:AddRadioButton(Translator:translate("One"), universal.how_many_injuries_can_be_removed_at_once == "One")
		local allRadio = universalOptions:AddRadioButton(Translator:translate("All"), universal.how_many_injuries_can_be_removed_at_once == "All")
		allRadio.SameLine = true

		local prioritizeSeverityText = universalOptions:AddText(Translator:translate("What Severity Should Be Prioritized?"))
		prioritizeSeverityText.Visible = oneRadio.Active
		local prioritizeSeverityCombo = universalOptions:AddCombo("")
		prioritizeSeverityCombo.Visible = oneRadio.Active
		prioritizeSeverityCombo.Options = {
			"Random",
			"Most Severe"
		}
		prioritizeSeverityCombo.WidthFitPreview = true
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

		local removeInjuriesOnDeath = universalOptions:AddCheckbox(Translator:translate("Remove All Injuries On Death"), universal.remove_on_death)
		removeInjuriesOnDeath.OnChange = function()
			universal.remove_on_death = removeInjuriesOnDeath.Checked
		end

		local removeInjuriesOnLongRest = universalOptions:AddCheckbox(Translator:translate("Remove All Injuries On Long Rest"), universal.remove_all_on_long_rest)
		removeInjuriesOnLongRest.OnChange = function()
			universal.remove_all_on_long_rest = removeInjuriesOnLongRest.Checked
		end
		--#endregion

		--#region Damage Counter
		universalOptions:AddNewLine()
		universalOptions:AddText(Translator:translate("When Does the Damage/Status Tick Counter Reset?")).Font = "Large"
		universalOptions:AddText(Translator:translate("If anything shorter than Short Rest is selected, Injury Counters will not be processed outside of combat.")):SetStyle("Alpha", 0.90)

		local cumulationCombo = universalOptions:AddCombo("")
		cumulationCombo.WidthFitPreview = true
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

		local healingCheckbox = universalOptions:AddCheckbox(Translator:translate("Healing Subtracts From Damage Counter"), universal.healing_subtracts_injury_damage)
		local healingText = universalOptions:AddText(
			Translator:translate("Ratio of Healing:Injury - 50% means you need 2 points of healing to remove 1 point of Injury damage"))
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
		universalOptions:AddText(Translator:translate("Customize Damage + Status Multipliers For NPCs")).Font = "Large"
		local enemyDesc = universalOptions:AddText(
			Translator:translate("These % multipliers will apply after the ones set per-injury (0 = no Injury damage will be taken) - NPC-type determinations are made by their associated Experience Reward Category. 'Base' will be overriden by more specific categories if applicable."
			.. " Supports Mod-added XPReward categories as long as they use the same names prepended with `_` - e.g. MMM_Combatant"))
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
		local severityHeader = tabHeader:AddCollapsingHeader(Translator:translate("Severity"))
		severityHeader:AddText(Translator:translate("When the below conditions are met, a random Injury that can apply for the receieved damage type will be applied to the affected character"))
		local downedCheckbox = severityHeader:AddCheckbox(Translator:translate("Downed"), universal.random_injury_conditional["Downed"])
		downedCheckbox.OnChange = function()
			universal.random_injury_conditional["Downed"] = downedCheckbox.Checked
		end

		local critCheckbox = severityHeader:AddCheckbox(Translator:translate("Suffered a Critical Hit"), universal.random_injury_conditional["Suffered a Critical Hit"])
		critCheckbox.SameLine = true
		critCheckbox.OnChange = function()
			universal.random_injury_conditional["Suffered a Critical Hit"] = critCheckbox.Checked
		end

		severityHeader:AddText(Translator:translate("The below sliders configure the likelihood of an Injury with the associated Severity being chosen. Values must add up to 100%"))
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

		local severityErrorText = severityHeader:AddText(Translator:translate("Error: Values must add up to 100%!"))
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

		local damageFilterCheckbox = severityHeader:AddCheckbox(Translator:translate("Only consider Injuries that are configured to apply on the relevant damage type"),
			universal.random_injury_filter_by_damage_type)
		damageFilterCheckbox.TextWrapPos = 0
		damageFilterCheckbox.OnChange = function(checkbox)
			universal.random_injury_filter_by_damage_type = checkbox.Checked
		end

		local damageFilterDesc = severityHeader:AddText(
			Translator:translate("If disabled, all Injuries will be placed in the pool to be randomly selected from (if not already applied to the character);"
			.. " otherwise, only Injuries with the damage type that triggers the condition (i.e. critical hit) in their Damage tab will be considered"))
		damageFilterDesc.TextWrapPos = 0
		damageFilterDesc:SetStyle("Alpha", 0.9)

		--#endregion

		--#endregion

		--#region Injury-Specific Options
		tabHeader:AddSeparatorText(Translator:translate("Injury-Specific Options"))

		local reportButton = tabHeader:AddButton(Translator:translate("Open Injury Report"))
		reportButton.OnClick = function()
			InjuryReport:BuildReportWindow()
		end

		local systemGroup = tabHeader:AddGroup(Translator:translate("Systems"))

		function AddSystem(system)
			local systemHeader = systemGroup:AddCollapsingHeader(system)
			systemHeader.DefaultOpen = false

			local deleteSystemButton = systemHeader:AddButton(Translator:translate("Delete System"))
			deleteSystemButton.IDContext = system -- otherwise it won't trigger when there are multiple systems
			deleteSystemButton.OnClick = function()
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

			local function buildTable(tableCategory, injuryNameTable)
				systemHeader:AddText(tableCategory).Font = "Large"
				local injuryTable = systemHeader:AddTable(system .. "_InjuryTable", 5)
				injuryTable.BordersInnerH = true
				injuryTable.SizingStretchProp = true
				injuryTable.PreciseWidths = true

				local headerRow = injuryTable:AddRow()
				headerRow.Headers = true
				headerRow:AddCell():AddText(Translator:translate("Injury"))
				headerRow:AddCell():AddText(Translator:translate("Severity"))
				headerRow:AddCell():AddText(Translator:translate("Actions"))

				for displayName, injuryName in TableUtils:OrderedPairs(injuryNameTable, function(injuryDisplayName)
					return cachedStats[injuryDisplayName].StackPriority .. injuryDisplayName
				end) do
					if not InjuryMenu.ConfigurationSlice.injury_specific[injuryName] then
						InjuryMenu.ConfigurationSlice.injury_specific[injuryName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class)
					end
					local injury_config = InjuryMenu.ConfigurationSlice.injury_specific[injuryName]

					local newRow = injuryTable:AddRow()
					local displayCell = newRow:AddCell()
					local injuryStat = Ext.Stats.Get(injuryName)
					displayCell:AddImage(injuryStat.Icon, { 36, 36 })
					displayCell:AddText(displayName).SameLine = true

					DataSearchHelper:BuildStatusTooltip(displayCell:Tooltip(), injuryStat)

					local severityCombo = newRow:AddCell():AddCombo("")
					severityCombo.Options = {
						"Exclude",
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
					local customizeButton = buttonCell:AddButton(Translator:translate("Customize"))

					local statCountTooltip = customizeButton:Tooltip()

					statCountTooltip.OnHoverEnter = function()
						for _, child in pairs(statCountTooltip.Children) do
							child:Destroy()
						end

						local applyOnStatusCount = countInjuryConfig(injury_config.apply_on_status["applicable_statuses"])
						local damageCount = countInjuryConfig(injury_config.damage["damage_types"])
						local removeOnStatusCount = countInjuryConfig(injury_config.remove_on_status)
						local racesCount = countInjuryConfig(injury_config.character_multipliers["races"])
						local tagsCount = countInjuryConfig(injury_config.character_multipliers["tags"])

						customizeButton.Label = string.format(Translator:translate("Customize (%s)"), applyOnStatusCount + damageCount + removeOnStatusCount + racesCount + tagsCount)

						statCountTooltip:AddNewLine()
						statCountTooltip:AddText(string.format(Translator:translate("Apply On Status: %d"), applyOnStatusCount))
						statCountTooltip:AddText(string.format(Translator:translate("Damage: %d"), damageCount))
						statCountTooltip:AddText(string.format(Translator:translate("Remove On Status: %d"), removeOnStatusCount))
						statCountTooltip:AddText(string.format(Translator:translate("Races: %d"), racesCount))
						statCountTooltip:AddText(string.format(Translator:translate("Tags: %d"), tagsCount))
					end
					statCountTooltip:OnHoverEnter()

					local injuryPopup
					customizeButton.OnClick = function()
						injuryPopup = Ext.IMGUI.NewWindow(Translator:translate("Customizing") .. " " .. displayName)
						injuryPopup.Closeable = true
						injuryPopup.OnClose = function()
							statCountTooltip:OnHoverEnter()
						end

						local newTabBar = injuryPopup:AddTabBar("InjuryTabBar")
						for _, tabGenerator in pairs(InjuryMenu.Tabs.Generators) do
							local success, error = pcall(function()
								tabGenerator(newTabBar, injuryName)
							end)

							if not success then
								Logger:BasicError("Error while generating a new tab for the Injury Table\n\t%s", error)
							end
						end
					end

					local resetButton = buttonCell:AddButton(Translator:translate("Reset"))
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
						statCountTooltip:OnHoverEnter()
					end

					local copyButton = buttonCell:AddButton(Translator:translate("Copy"))
					copyButton.SameLine = true

					copyButton.OnClick = function()
						local copyPopup = Ext.IMGUI.NewWindow(Translator:translate("Copying Injury Configs"))
						copyPopup.AlwaysAutoResize = true
						copyPopup.Closeable = true

						copyPopup:AddText(Translator:translate("Copying from:") .. " " .. displayName).Font = "Large"
						copyPopup:AddText(Translator:translate("Close any Customizing windows you have open - they'll show stale data after this runs")).TextWrapPos = 0
						copyPopup:AddNewLine()

						copyPopup:AddSeparatorText(Translator:translate("Which Configs Should Be Copied?"))
						local copyWhatGroup = copyPopup:AddGroup("CopyWhat")
						copyWhatGroup:AddCheckbox(Translator:translate("ApplyOnStatus"), true).UserData = "apply_on_status"

						local dmg = copyWhatGroup:AddCheckbox(Translator:translate("Damage"), true)
						dmg.SameLine = true
						dmg.UserData = "damage"

						local charMultipliers = copyWhatGroup:AddCheckbox(Translator:translate("Character Multipliers"), true)
						charMultipliers.SameLine = true
						charMultipliers.UserData = "character_multipliers"

						local removeStatus = copyWhatGroup:AddCheckbox(Translator:translate("RemoveOnStatus"), true)
						removeStatus.SameLine = true
						removeStatus.UserData = "remove_on_status"

						copyPopup:AddNewLine()
						copyPopup:AddSeparatorText(Translator:translate("What Injuries should these configs be copied to?"))
						local copyToGroup = copyPopup:AddGroup("CopyTo")
						copyPopup:AddButton(Translator:translate("Select All")).OnClick = function()
							for _, child in pairs(copyToGroup.Children) do
								child.Checked = true
							end
						end

						for otherDisplayName, stat in TableUtils:OrderedPairs(cachedStats) do
							if displayName ~= otherDisplayName then
								copyToGroup:AddCheckbox(otherDisplayName, false).UserData = stat.Name
							end
						end

						copyPopup:AddButton(Translator:translate("Copy Configs")).OnClick = function()
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

			local miscInjuriesDisplayMap = {}
			local stackedInjuriesDisplayMap = {}
			for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
				if string.find(string.upper(name), "^" .. string.upper(system) .. ".*") then
					local displayName = string.sub(name, string.len(system) + 1)
					displayName = string.gsub(displayName, "_", " ")

					---@type StatusData
					local injuryStat = Ext.Stats.Get(name)
					displayName = Ext.Loca.GetTranslatedString(injuryStat.DisplayName, displayName)

					cachedStats[displayName] = injuryStat

					if injuryStat.StackId == "" then
						miscInjuriesDisplayMap[displayName] = name
					else
						stackedInjuriesDisplayMap[injuryStat.StackId] = stackedInjuriesDisplayMap[injuryStat.StackId] or {}
						stackedInjuriesDisplayMap[injuryStat.StackId][displayName] = name
					end
				end
			end

			for stackId, nameMap in TableUtils:OrderedPairs(stackedInjuriesDisplayMap) do
				if TableUtils:CountEntries(nameMap) == 1 then
					local key = next(nameMap)
					miscInjuriesDisplayMap[key] = nameMap[key]
					stackedInjuriesDisplayMap[stackId] = nil
				end
			end

			buildTable(Translator:translate("Miscellaneous"), miscInjuriesDisplayMap)
			for stackId, nameMap in TableUtils:OrderedPairs(stackedInjuriesDisplayMap) do
				buildTable(Translator:translate("Stack:") .. " " .. stackId, nameMap)
			end
		end

		--#region Systems
		for _, system in ipairs(InjuryMenu.ConfigurationSlice.systems) do
			AddSystem(system)
		end

		tabHeader:AddSeparatorText(Translator:translate("Register a New Injury System"))
		tabHeader:AddText(Translator:translate("Enter the prefix used in all Stats belonging to a single system (e.g. Goon_Injury_Homebrew or Goon_Injury_Grit_And_Glory) to create a new section dedicated to the system." ..
			" All Stats belonging to the registered system(s) will automatically be known and used by this mod - if you want to exclude a system from processing, you must delete it - configurations will not be saved")).TextWrapPos = 0

		local systemInput = tabHeader:AddInputText("")
		systemInput.Hint = Translator:translate("Case-insensitive - only specify the prefix (e.g. Goon_Injury_Homebrew)")
		systemInput.AutoSelectAll = true
		systemInput.EscapeClearsAll = true

		local search = tabHeader:AddButton(Translator:translate("Search"))

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

Translator:RegisterTranslation({
	["Universal Options"] = "h1ec71859ad9f44458110fb611c05f4d701ag",
	["Who Can Receive Injuries?"] = "h00f45a44ab9345c1b1106d6852ebcc4d9cb3",
	["Party Members"] = "h9df2a1fcaea949aeb733c493d4d7045ad3d3",
	["Allies"] = "hb2b2ef0a495543a4a5596f821e25226410a7",
	["Enemies"] = "h67f450fc249442b795305a91a9119e3e3790",
	["How Many Different Injuries Can Be Removed At Once?"] = "hf09a78e9f67d4f6ebd69b1831b16bc7e00cf",
	["If multiple injuries share the same removal conditions, only the specified number will be removed at once - injuries will be randomly chosen."] = "h917674e930d34cc8a28ecc9051066f4f332f",
	["One"] = "hfe2ed92d7923481b97a60edf916e5b03d5g7",
	["All"] = "he8141a6f94e24224a4cdd5f198aca85703b6",
	["What Severity Should Be Prioritized?"] = "h4e5210014bf44629b4a8125da7b191158c4a",
	["Remove All Injuries On Death"] = "he00cdfbaa2a6402b8f576e6c556c93d3fffc",
	["Remove All Injuries On Long Rest"] = "h113c81a1391544e8a7bb3a662ce6488b8g6e",
	["When Does the Damage/Status Tick Counter Reset?"] = "hc47037eb48214da092ef0e91442a316aff27",
	["If anything shorter than Short Rest is selected, Injury Counters will not be processed outside of combat."] = "h63c5fd1bbdf34462b71996ca4f74b34fcddb",
	["Healing Subtracts From Damage Counter"] = "h3cccf831d7dd4ab890ea564320f73af45bc2",
	["Ratio of Healing:Injury - 50% means you need 2 points of healing to remove 1 point of Injury damage"] = "h516dbf2301714121b4f734955aa01f83f997",
	["Customize Damage + Status Multipliers For NPCs"] = "h38c9a5d7d98b4e8fadcb61ceefe9940a0dd4",
	["These % multipliers will apply after the ones set per-injury (0 = no Injury damage will be taken) - NPC-type determinations are made by their associated Experience Reward Category. 'Base' will be overriden by more specific categories if applicable."
			.. " Supports Mod-added XPReward categories as long as they use the same names prepended with `_` - e.g. MMM_Combatant"] = "h9bda3b06d6b4412ab079c3bcdd9b6aed3ec1",
	["When the below conditions are met, a random Injury that can apply for the receieved damage type will be applied to the affected character"] = "h49d19708c1bb43ddbcbf5a671e2719aa7f46",
	["Downed"] = "hd0fdb6dcced94e8ab2b0d7a8ca6fe1c46082",
	["Suffered a Critical Hit"] = "h84d4a31ea8014224beac0fe256eba20ad728",
	["The below sliders configure the likelihood of an Injury with the associated Severity being chosen. Values must add up to 100%"] = "hd4d2189ac8cc4d6bbd0b68dd6825ff9fc26e",
	["Error: Values must add up to 100%!"] = "h4983f15cdb6d439b8d7f3e3770b8244997d3",
	["Only consider Injuries that are configured to apply on the relevant damage type"] = "h2a6602e74767415f8bf66edc7a3595e82852",
	["If disabled, all Injuries will be placed in the pool to be randomly selected from (if not already applied to the character);"
			.. " otherwise, only Injuries with the damage type that triggers the condition (i.e. critical hit) in their Damage tab will be considered"] = "h5c3d63b7169d42deaba68a041fde636aab0b",
	["Injury-Specific Options"] = "hc273eb7f41304b7a9e3a4f783cf28b7470c2",
	["Open Injury Report"] = "hd04225c38388437caa4670faf1b5cbea2bb7",
	["Systems"] = "h8c9bbb728c8f407aaa7a886ae05ff4e8cc9b",
	["Delete System"] = "h5d5066b88cda46c1bb91129a1d80777c67d5",
	["Injury"] = "h2b3b5b26e1c44dd495acba638cd593500718",
	["Severity"] = "h7231e1d605ce400ea608fb8d4079e8f493bg",
	["Actions"] = "h6786d51c543e4530a8c2ac7847bce8dd5ce6",
	["Customize (%s)"] = "h1a8bc7c8138d427ba215ad25773655b69f2d",
	["Customize"] = "h44056242a4db4cf3a274eb9d84ef8ae6a1f8",
	["Apply On Status: %d"] = "h2fa3b2dc429e40f9934dfc1da4c9af927ac9",
	["Damage: %d"] = "h9e5903752a86420d83eb9ebfd034a4ae70ga",
	["Remove On Status: %d"] = "h417c2180e95c4b58bf778ab09e9c479d4a9d",
	["Races: %d"] = "h2a4ca5118d19495a922958a7e23b4d18e94d",
	["Tags: %d"] = "h8f02176203414eda9441035b56a5bd855100",
	["Customizing"] = "h38ca8120073446a380df1f13774a09496ab7",
	["Reset"] = "h28fd5e874c854e1c89f87b6a9f526f592ac1",
	["Copy"] = "h75fc356630954ffb866066e2ba5403a3bd02",
	["Copying Injury Configs"] = "he6ca7f6689b442d6b0c69c76701a3acaf37a",
	["Copying from:"] = "h5562bfc3427d49188b12c54e1de1b6877dcd",
	["Close any Customizing windows you have open - they'll show stale data after this runs"] = "h74cf05e59dec40a5bbe71883c53ea77bfd2c",
	["Which Configs Should Be Copied?"] = "h646529ff207d4d87b9ac0ab39eaa076dbd57",
	["ApplyOnStatus"] = "h6dbf73a197664327ada890532dfd9447772a",
	["Damage"] = "hfefd65a4e38b4ccc82cc292e9c3d00615196",
	["Character Multipliers"] = "hec1a8f64e2ee4bba9d7b9d44fa3cf465d715",
	["RemoveOnStatus"] = "h88cc1ca7ae4445b8aea54a5e89c545250dge",
	["What Injuries should these configs be copied to?"] = "hadacfbcc416e4f6eb4c2ea363d4d9ee0056d",
	["Select All"] = "h770262b9d00147e9ac492a8212b58156ge25",
	["Copy Configs"] = "h0f39712a0c144d05878d26a28b85c2c20c03",
	["Search"] = "h82b51d5ccffd4a6b8749867ec3896b803dc8",
	["Miscellaneous"] = "hb9e2a626d6c146a4976bc1241023dda8b7b6",
	["Stack:"] = "hb484765355a94e1e8dce9a1061e33de4ge73",
	["Case-insensitive - only specify the prefix (e.g. Goon_Injury_Homebrew)"] = "h876d8a018fd6472ba406fcd48ab7761e686c",
	["Register a New Injury System"] = "h3fcbb7dcbecd4a57a613931a57720e952ca7",
	["Enter the prefix used in all Stats belonging to a single system (e.g. Goon_Injury_Homebrew or Goon_Injury_Grit_And_Glory) to create a new section dedicated to the system." ..
			" All Stats belonging to the registered system(s) will automatically be known and used by this mod - if you want to exclude a system from processing, you must delete it - configurations will not be saved"] = "h4ad9acd0b0d2422184871ede9022f0b31c22",
})

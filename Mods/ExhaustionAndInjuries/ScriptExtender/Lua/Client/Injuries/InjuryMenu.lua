InjuryMenu = {}
InjuryMenu.Tabs = { ["Generators"] = {} }

InjuryMenu.ConfigurationSlice = ConfigurationStructure.injuries

function InjuryMenu:RegisterTab(tabGenerator)
	table.insert(InjuryMenu.Tabs["Generators"], tabGenerator)
end

Ext.Require("Client/Injuries/Tabs/DamageTab.lua")
Ext.Require("Client/Injuries/Tabs/ApplyOnStatusTab.lua")
Ext.Require("Client/Injuries/Tabs/RemoveOnStatusTab.lua")

local injuryDisplayNames = {}
local injuriesDisplayMap = {}

Ext.Events.SessionLoaded:Subscribe(function()
	for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
		if string.find(name, "Goon_Injury_") then
			local displayName = string.sub(name, string.len("Goon_Injury_") + 1)
			displayName = string.gsub(displayName, "_", " ")
			table.insert(injuryDisplayNames, displayName)
			injuriesDisplayMap[displayName] = name
		end
	end

	table.sort(injuryDisplayNames)

	Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Injuries",
		--- @param tabHeader ExtuiTreeParent
		function(tabHeader)
			--#region Universal Options
			tabHeader:AddSeparatorText("Universal Options")

			--#region Who Can Receive Injuries
			tabHeader:AddText("Who Can Receive Injuries?")
			local partyCheckbox = tabHeader:AddCheckbox("Party Members", true)
			partyCheckbox.OnChange = function()
				InjuryMenu.ConfigurationSlice.universal.who_can_receive_injuries["Party Members"] = partyCheckbox.Checked
			end

			local allyCheckbox = tabHeader:AddCheckbox("Allies", true)
			allyCheckbox.SameLine = true
			allyCheckbox.OnChange = function()
				InjuryMenu.ConfigurationSlice.universal.who_can_receive_injuries["Allies"] = allyCheckbox.Checked
			end

			local enemyCheckbox = tabHeader:AddCheckbox("Enemies", true)
			enemyCheckbox.SameLine = true
			enemyCheckbox.OnChange = function()
				InjuryMenu.ConfigurationSlice.universal.who_can_receive_injuries["Enemies"] = enemyCheckbox.Checked
			end
			--#endregion

			--#region Injury Removal
			tabHeader:AddSeparator()
			tabHeader:AddText("How Many Different Injuries Can Be Removed At Once?")
			tabHeader:AddText("If multiple injuries share the same removal conditions, only the specified number will be removed at once - injuries will be randomly chosen.")
			local oneRadio = tabHeader:AddRadioButton("One", true)
			local allRadio = tabHeader:AddRadioButton("All", false)
			allRadio.SameLine = true

			local prioritizeSeverityText = tabHeader:AddText("What Severity Should Be Prioritized?")
			prioritizeSeverityText.Visible = false
			local prioritizeSeverityCombo = tabHeader:AddCombo("")
			prioritizeSeverityCombo.Visible = false
			prioritizeSeverityCombo.Options = {
				"Random",
				"Most Severe"
			}
			prioritizeSeverityCombo.SelectedIndex = 1
			prioritizeSeverityCombo.OnChange = function(_, selectedIndex)
				InjuryMenu.ConfigurationSlice.universal.injury_removal_severity_priority = prioritizeSeverityCombo.Options[selectedIndex + 1]
			end

			oneRadio.OnActivate = function()
				allRadio.Active = oneRadio.Active
				oneRadio.Active = not oneRadio.Active

				if oneRadio.Active then
					InjuryMenu.ConfigurationSlice.universal.how_many_injuries_can_be_removed_at_once = oneRadio.Label
				end

				prioritizeSeverityText.Visible = oneRadio.Active
				prioritizeSeverityCombo.Visible = oneRadio.Active
			end

			allRadio.OnActivate = function()
				oneRadio.Active = allRadio.Active
				allRadio.Active = not allRadio.Active

				if allRadio.Active then
					InjuryMenu.ConfigurationSlice.universal.how_many_injuries_can_be_removed_at_once = allRadio.Label
				end

				prioritizeSeverityText.Visible = oneRadio.Active
				prioritizeSeverityCombo.Visible = oneRadio.Active
			end
			--#endregion

			--#region Damage Counter
			tabHeader:AddSeparator()
			tabHeader:AddText("When does the damage/status tick counter reset? Each")
			local cumulationCombo = tabHeader:AddCombo("")
			cumulationCombo.SameLine = true
			cumulationCombo.Options = {
				"Attack/Tick",
				"Round",
				"Combat",
				"Short Rest",
				"Long Rest"
			}
			cumulationCombo.SelectedIndex = 0

			local healingCheckbox = tabHeader:AddCheckbox("Healing Subtracts From Damage Counter", true)
			local healingText = tabHeader:AddText(
				"Ratio of Healing:Injury - 50% means you need 2 points of healing to remove 1 point of Injury damage")
			local healingOffsetCombo = tabHeader:AddCombo("")
			healingOffsetCombo.Options = {
				"25%",
				"50%",
				"100%",
				"150%",
				"200%"
			}
			healingOffsetCombo.SelectedIndex = 2
			healingOffsetCombo.OnChange = function(_, selectedIndex)
				InjuryMenu.ConfigurationSlice.universal.healing_subtracts_injury_counter_modifier = healingOffsetCombo.Options[selectedIndex + 1]
			end

			healingCheckbox.OnChange = function(combo, value)
				healingText.Visible = value
				healingOffsetCombo.Visible = value
			end

			healingCheckbox.Visible = false
			healingText.Visible = false
			healingOffsetCombo.Visible = false

			cumulationCombo.OnChange = function(combo, selectedIndex)
				healingCheckbox.Visible = selectedIndex ~= 0
				healingText.Visible = selectedIndex ~= 0
				healingOffsetCombo.Visible = selectedIndex ~= 0

				InjuryMenu.ConfigurationSlice.universal.when_does_counter_reset = cumulationCombo.Options[selectedIndex + 1]
			end
			--#endregion

			--#region Severity
			tabHeader:AddSeparatorText("Severity")
			tabHeader:AddText("When the below conditions are met, a random Injury that can apply for the receieved damage type will be applied to the affected character")
			local downedCheckbox = tabHeader:AddCheckbox("Downed", true)
			downedCheckbox.OnChange = function()
				InjuryMenu.ConfigurationSlice.universal.random_injury_conditional["Downed"] = downedCheckbox.Checked
			end

			local critCheckbox = tabHeader:AddCheckbox("Suffered a Critical Hit", true)
			critCheckbox.SameLine = true
			critCheckbox.OnChange = function()
				InjuryMenu.ConfigurationSlice.universal.random_injury_conditional["Suffered a Critical Hit"] = critCheckbox.Checked
			end

			tabHeader:AddText("The below sliders configure the likelihood of an Injury with the associated Severity being chosen. Values must add up to 100%")
			tabHeader:AddText("Low")
			local lowSeverity = tabHeader:AddSliderInt("", 25, 0, 100)
			lowSeverity.SameLine = true

			tabHeader:AddText("Medium")
			local mediumSeverity = tabHeader:AddSliderInt("", 50, 0, 100)
			mediumSeverity.SameLine = true

			tabHeader:AddText("High")
			local highSeverity = tabHeader:AddSliderInt("", 25, 0, 100)
			highSeverity.SameLine = true

			local severityErrorText = tabHeader:AddText("Error: Values must add up to 100%!")
			severityErrorText.Visible = false
			local ensureAdditionFunction = function()
				severityErrorText.Visible = (lowSeverity.Value[1] + mediumSeverity.Value[1] + highSeverity.Value[1] ~= 100)
				if not severityErrorText.Visible then
					InjuryMenu.ConfigurationSlice.universal.random_injury_severity_weights = {
						["Low"] = lowSeverity.Value[1],
						["Medium"] = mediumSeverity.Value[1],
						["High"] = highSeverity.Value[1],
					}
				end
			end
			lowSeverity.OnChange = ensureAdditionFunction
			mediumSeverity.OnChange = ensureAdditionFunction
			highSeverity.OnChange = ensureAdditionFunction

			--#endregion

			--#endregion

			--#region Injury-Specific Options
			tabHeader:AddSeparatorText("Injury-Specific Options")

			local injuryTable = tabHeader:AddTable("InjuryTable", 3)
			injuryTable.BordersInnerH = true
			injuryTable.PreciseWidths = true

			local headerRow = injuryTable:AddRow()
			headerRow.Headers = true
			headerRow:AddCell():AddText("Injury")
			headerRow:AddCell():AddText("Severity")
			headerRow:AddCell():AddText("Actions")

			for _, displayName in pairs(injuryDisplayNames) do
				InjuryMenu.ConfigurationSlice.injury_specific[displayName] = {}

				local newRow = injuryTable:AddRow()

				newRow:AddCell():AddText(displayName)
				local severityCombo = newRow:AddCell():AddCombo("")
				severityCombo.Options = {
					"Low",
					"Medium",
					"High"
				}
				severityCombo.SelectedIndex = 1
				severityCombo.OnChange = function(_, selectedIndex)
					InjuryMenu.ConfigurationSlice.injury_specific[displayName].severity = severityCombo.Options[selectedIndex]
				end

				local customizeButton = newRow:AddCell():AddButton("Customize")
				customizeButton.OnClick = function()
					local injuryPopup = Ext.IMGUI.NewWindow("Customizing " .. displayName)
					injuryPopup.Closeable = true
					injuryPopup.HorizontalScrollbar = true

					local newTabBar = injuryPopup:AddTabBar("InjuryTabBar")
					for _, tabGenerator in pairs(InjuryMenu.Tabs.Generators) do
						local success, error = pcall(function()
							tabGenerator(newTabBar, injuriesDisplayMap[displayName])
						end)

						if not success then
							Logger:BasicError("Error while generating a new tab for the Injury Table\n\t%s", error)
						end
					end
				end
			end
			--#endregion
		end)
end)

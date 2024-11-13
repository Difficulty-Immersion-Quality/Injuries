--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar, injury)
	-- Since the keys of this table are dynamic, we can't rely on ConfigurationStructure to initialize the defaults if the entry doesn't exist - we need to do that here
	if not InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status then
		InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status = {}
	end
	local saveConfig = InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status

	local statusTab = tabBar:AddTabItem("Remove On Status")

	local statusTable = statusTab:AddTable("RemoveOnStatus", 3)
	statusTable.BordersInnerH = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Status Name")
	headerRow:AddCell():AddText("Save Conditions")

	statusTab:AddText("Add New Row")
	local statusInput = statusTab:AddInputText("")
	statusInput.Hint = "Case-insensitive - use * to wildcard"
	statusInput.AutoSelectAll = true
	statusInput.EscapeClearsAll = true
	-- statusInput.EnterReturnsTrue = true

	local statusInputButton = statusTab:AddButton("Register Status")

	local errorText = statusTab:AddText("Error: Search returned no results")
	errorText.Visible = false

	statusInputButton.OnClick = function()
		local statuses = {}
		local inputText = string.upper(statusInput.Text)
		local isWildcard = false
		if string.find(inputText, "*") then
			inputText = string.gsub(inputText, "*", "")
			isWildcard = true
		end

		for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
			name = string.upper(name)
			if isWildcard then
				if string.find(name, inputText) then
					table.insert(statuses, Ext.Stats.Get(name))
				end
			elseif name == inputText then
				table.insert(statuses, Ext.Stats.Get(name))
				break
			end
		end

		if #statuses > 0 then
			for _, status in pairs(statuses) do
				if string.upper(status.StatusType) == "BOOST" then
					local statusName = status.Name
					local row = statusTable:AddRow()
					saveConfig[statusName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_removal_class)
					local statusConfig = saveConfig[statusName]

					--#region Status Name
					local statusName = row:AddCell():AddText(status.Name)
					local nameTooltip = statusName:Tooltip()

					if status.TooltipDamage ~= "" then
						nameTooltip:AddText("Damage: " .. status.TooltipDamage)
					end

					if status.HealValue ~= "" then
						nameTooltip:AddText("Healing: |Value: " .. status.HealthValue .. " |Stat: " .. status.HealStat .. "|Multiplier: " .. status.HealMultiplier .. "|")
					end

					if status.TooltipSave ~= "" then
						nameTooltip:AddText("Save: " .. status.TooltipSave)
					end

					if status.TickType ~= "" then
						nameTooltip:AddText("TickType: " .. status.TickType)
					end
					--#endregion

					--#region Save Options
					local saveOptions = {}
					for _, ability in ipairs(Ext.Enums.AbilityId) do
						table.insert(saveOptions, tostring(ability))
					end
					table.sort(saveOptions)
					table.insert(saveOptions, 1, "No Save")

					local saveRow = row:AddCell()
					local saveCombo = saveRow:AddCombo("")
					saveCombo.Options = saveOptions
					for index, option in pairs(saveCombo.Options) do
						if option == statusConfig["ability"] then
							saveCombo.SelectedIndex = index - 1
							break
						end
					end

					local saveSlider = saveRow:AddSliderInt("",
						statusConfig["difficulty_class"],
						1,
						30)

					saveSlider.Visible = saveCombo.SelectedIndex ~= 0
					saveSlider.OnChange = function()
						statusConfig["difficulty_class"] = saveSlider.Value[1]
					end

					saveCombo.OnChange = function(combo, selectedIndex)
						saveSlider.Visible = selectedIndex ~= 0
						statusConfig["ability"] = saveCombo.Options[selectedIndex + 1]
					end
					--#endregion

					local deleteRowButton = row:AddCell():AddButton("Delete")

					deleteRowButton.OnClick = function()
						-- hack to allow us to monitor table deletion
						statusConfig.delete = true
						row:Destroy()
					end
				end
			end
		else
			errorText.Visible = true
		end
	end

	statusInput.OnChange = function(inputElement, text)
		errorText.Visible = false
	end
end)

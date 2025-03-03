---@param statusTable ExtuiTable
---@param status string
---@param injury InjuryName
---@param removeOnConfig InjuryRemoveOnStatusClass
---@param ignoreExistingStatus boolean?
local function BuildRows(statusTable, status, injury, removeOnConfig, ignoreExistingStatus)
	---@type StatusData
	local statusObj = Ext.Stats.Get(status)
	if not statusObj then
		return
	end

	local statusName = statusObj.Name
	if not removeOnConfig[statusName] then
		removeOnConfig[statusName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_remove_on_status_class)
	elseif ignoreExistingStatus then
		return
	end
	local statusConfig = removeOnConfig[statusName]

	local row = statusTable:AddRow()

	--#region Status Name
	local statusNameRow = row:AddCell()
	if statusObj.Icon ~= '' then
		statusNameRow:AddImage(statusObj.Icon, { 36, 36 })
	end
	local statusNameText = statusNameRow:AddText(statusObj.Name)
	statusNameText.SameLine = true

	StatusHelper:BuildStatusTooltip(statusNameText:Tooltip(), statusObj)
	--#endregion

	--#region Save Options
	local saveOptions = {}
	for _, ability in ipairs(Ext.Enums.AbilityId) do
		if ability ~= "Sentinel" then
			table.insert(saveOptions, tostring(ability))
		end
	end
	table.sort(saveOptions)
	table.insert(saveOptions, 1, "No Save")

	local saveCell = row:AddCell()
	local saveCombo = saveCell:AddCombo("")
	saveCombo.Options = saveOptions
	for index, option in pairs(saveCombo.Options) do
		if option == statusConfig["ability"] then
			saveCombo.SelectedIndex = index - 1
			break
		end
	end

	local saveSlider = saveCell:AddSliderInt("",
		statusConfig["difficulty_class"] or 15,
		1,
		30)

	saveSlider.Visible = saveCombo.SelectedIndex ~= 0
	if not saveSlider.Visible then
		statusConfig["difficulty_class"] = nil
	end

	saveSlider.OnChange = function()
		statusConfig["difficulty_class"] = saveSlider.Value[1]
	end

	saveCombo.OnChange = function(combo, selectedIndex)
		saveSlider.Visible = selectedIndex ~= 0
		if not saveSlider.Visible then
			statusConfig["difficulty_class"] = nil
		else
			statusConfig["difficulty_class"] = statusConfig["difficulty_class"] or 15
		end
		statusConfig["ability"] = saveCombo.Options[selectedIndex + 1]
	end

	if statusObj.Name == "LONG_REST" then
		saveCell:AddText(Translator:translate("After how many long rests? (Counted by event or status application (including Angelic Slumber), if no event triggers)"))
		statusConfig["after_x_applications"] = statusConfig["after_x_applications"] or 1
		saveCell:AddSliderInt("", statusConfig["after_x_applications"], 1, 30).OnChange = function(slider)
			statusConfig["after_x_applications"] = slider.Value[1]
		end
	end

	---@type StatusData
	local injuryStat = Ext.Stats.Get(injury)
	if injuryStat.StackId and injuryStat.StackId ~= "" and injuryStat.StackPriority > 1 then
		local stackCell = row:AddCell()
		statusConfig["stacks_to_remove"] = statusConfig["stacks_to_remove"] or injuryStat.StackPriority
		local stackRemovalSlider = stackCell:AddSliderInt("", statusConfig["stacks_to_remove"], 1, injuryStat.StackPriority)
		stackRemovalSlider.OnChange = function()
			statusConfig["stacks_to_remove"] = stackRemovalSlider.Value[1]
		end
	end

	local triggers = row:AddCell()
	statusConfig["onApplication"] = statusConfig["onApplication"] == nil and true or statusConfig["onApplication"]
	triggers:AddCheckbox("On Application", statusConfig["onApplication"]).OnChange = function(checkbox)
		statusConfig["onApplication"] = checkbox.Checked
	end
	local onRemove = triggers:AddCheckbox("On Removal", statusConfig["onRemoval"])
	onRemove.SameLine = true
	onRemove.OnChange = function()
		statusConfig["onRemoval"] = onRemove.Checked
	end

	--#endregion

	local deleteRowButton = row:AddCell():AddButton(Translator:translate("Delete"))

	deleteRowButton.OnClick = function()
		-- hack to allow us to monitor table deletion
		statusConfig.delete = true
		row:Destroy()
	end
end

--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar, injury)
	-- Since the keys of this table are dynamic, we can't rely on ConfigurationStructure to initialize the defaults if the entry doesn't exist - we need to do that here
	if not InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status then
		InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status =
			TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class.remove_on_status)
	end
	local removeOnConfig = InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status

	local statusTab = tabBar:AddTabItem(Translator:translate("Remove On Status"))
	statusTab.TextWrapPos = 0

	---@type StatusData
	local injuryStat = Ext.Stats.Get(injury)
	local addStackRemovalAspect = injuryStat.StackId and injuryStat.StackId ~= "" and injuryStat.StackPriority > 1

	local statusTable = statusTab:AddTable("RemoveOnStatus", addStackRemovalAspect and 5 or 4)
	statusTable.BordersInnerH = true
	statusTable.Resizable = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText(Translator:translate("Status Name (ResourceID)"))
	headerRow:AddCell():AddText(Translator:translate("Save Conditions"))
	if addStackRemovalAspect then
		headerRow:AddCell():AddText(Translator:translate("# of Stacks To Remove (?)")):Tooltip():AddText(Translator:translate(
			"i.e. if you set 3rd Degree Burns to remove 2 stacks, you'll have 1st Degree Burns applied"))
	end
	headerRow:AddCell():AddText(Translator:translate("Triggers"))

	StatusHelper:BuildSearch(statusTab,
		Ext.Stats.GetStats("StatusData"),
		function(resourceId)
			return Ext.Loca.GetTranslatedString(Ext.Stats.Get(resourceId).DisplayName, nil)
		end,
		function(status)
			BuildRows(statusTable, status, injury, removeOnConfig, true)
		end)

	for status, _ in TableUtils:OrderedPairs(removeOnConfig) do
		BuildRows(statusTable, status, injury, removeOnConfig)
	end

	StatusHelper:BuildStatusGroupSection(statusTab:AddGroup("removeOnstatusGroups" .. injury),
		injuryStat,
		removeOnConfig,
		ConfigurationStructure.DynamicClassDefinitions.injury_remove_on_status_class,
		function(statusGroupSection, statusConfig)
			--#region Save Options
			local saveOptions = {}
			for _, ability in ipairs(Ext.Enums.AbilityId) do
				if ability ~= "Sentinel" then
					table.insert(saveOptions, tostring(ability))
				end
			end
			table.sort(saveOptions)
			table.insert(saveOptions, 1, "No Save")

			statusGroupSection:AddText(Translator:translate("Save Conditions"))
			local saveCombo = statusGroupSection:AddCombo("")
			saveCombo.WidthFitPreview = true
			saveCombo.SameLine = true
			saveCombo.Options = saveOptions
			for index, option in pairs(saveCombo.Options) do
				if option == statusConfig["ability"] then
					saveCombo.SelectedIndex = index - 1
					break
				end
			end

			local saveSlider = statusGroupSection:AddSliderInt("",
				statusConfig["difficulty_class"] or 15,
				1,
				30)
			saveSlider.SameLine = true

			saveSlider.Visible = saveCombo.SelectedIndex ~= 0
			if not saveSlider.Visible then
				statusConfig["difficulty_class"] = nil
			end

			saveSlider.OnChange = function()
				statusConfig["difficulty_class"] = saveSlider.Value[1]
			end

			saveCombo.OnChange = function(combo, selectedIndex)
				saveSlider.Visible = selectedIndex ~= 0
				statusConfig["ability"] = saveCombo.Options[selectedIndex + 1]

				if not saveSlider.Visible then
					statusConfig["difficulty_class"] = nil
				else
					statusConfig["difficulty_class"] = saveSlider.Value[1]
				end
			end

			if injury.StackId and injury.StackId ~= "" and injury.StackPriority > 1 then
				statusGroupSection:AddText(Translator:translate("# of Stacks To Remove (?)")):Tooltip():AddText(Translator:translate(
					"i.e. if you set 3rd Degree Burns to remove 2 stacks, you'll have 1st Degree Burns applied"))
				statusConfig["stacks_to_remove"] = statusConfig["stacks_to_remove"] or injury.StackPriority
				local stackRemovalSlider = statusGroupSection:AddSliderInt("", statusConfig["stacks_to_remove"], 1, injury.StackPriority)
				stackRemovalSlider.SameLine = true
				stackRemovalSlider.OnChange = function()
					statusConfig["stacks_to_remove"] = stackRemovalSlider.Value[1]
				end
			end

			statusGroupSection:AddText("Triggers")
			statusGroupSection:AddCheckbox("On Application", statusConfig["onApplication"]).OnChange = function(checkbox)
				statusConfig["onApplication"] = checkbox.Checked
			end
			local onRemove = statusGroupSection:AddCheckbox("On Removal", statusConfig["onRemoval"])
			onRemove.SameLine = true
			onRemove.OnChange = function()
				statusConfig["onRemoval"] = onRemove.Checked
			end


			--#endregion

			statusGroupSection:AddNewLine()
		end)
	-- local sgTable = statusTab:AddTable("statusGroup" .. injury, 3)
end)

Translator:RegisterTranslation({
	["Delete"] = "hce2116065bec41b5a7ce75c39e627a302842",
	["Remove On Status"] = "h5aafe7131cb74ee4a0a8df3093386146edf5",
	["Status Name (ResourceID)"] = "h17af04db98664960a5d485740a86f4bb4517",
	["Save Conditions"] = "hbe9455faa0784cb99616e5098fd5247dgcg2",
	["# of Stacks To Remove (?)"] = "h125c3399732d41a4a300eee966450e16e61f",
	["i.e. if you set 3rd Degree Burns to remove 2 stacks, you'll have 1st Degree Burns applied"] = "he6354d4907a7431b82c7ebde28275f9a7eae",
	["After how many long rests? (Counted by event or status application (including Angelic Slumber), if no event triggers)"] = "h0334268fe1274b1e9eb4c0286c0321042ag7",
})

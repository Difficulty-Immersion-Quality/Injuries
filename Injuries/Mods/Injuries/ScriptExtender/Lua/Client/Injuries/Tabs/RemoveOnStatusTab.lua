---@param statusTable ExtuiTable
---@param status string
---@param injury InjuryName
---@param removeOnConfig InjuryRemoveOnStatusClass
---@param ignoreExistingStatus boolean?
local function BuildRows(statusTable, status, injury, removeOnConfig, ignoreExistingStatus)
	---@type StatusData
	local statusObj = Ext.Stats.Get(status)

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

	DataSearchHelper:BuildStatusTooltip(statusNameText:Tooltip(), statusObj)
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

	---@type StatusData
	local injuryStat = Ext.Stats.Get(injury)
	if injuryStat.StackId and injuryStat.StackId ~= "" and injuryStat.StackPriority > 1 then
		local stackCell = row:AddCell()
		statusConfig.stacks_to_remove = statusConfig.stacks_to_remove or injuryStat.StackPriority
		local stackRemovalSlider = stackCell:AddSliderInt("", statusConfig.stacks_to_remove, 1, injuryStat.StackPriority)
		stackRemovalSlider.OnChange = function()
			statusConfig.stacks_to_remove = stackRemovalSlider.Value[1]
		end
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

	local statusTable = statusTab:AddTable("RemoveOnStatus", addStackRemovalAspect and 4 or 3)
	statusTable.BordersInnerH = true
	statusTable.Resizable = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText(Translator:translate("Status Name (ResourceID)"))
	headerRow:AddCell():AddText(Translator:translate("Save Conditions"))
	if addStackRemovalAspect then
		headerRow:AddCell():AddText(Translator:translate("# of Stacks To Remove (?)")):Tooltip():AddText(Translator:translate("i.e. if you set 3rd Degree Burns to remove 2 stacks, you'll have 1st Degree Burns applied"))
	end

	DataSearchHelper:BuildSearch(statusTab,
		Ext.Stats.GetStats("StatusData"),
		function(resourceId)
			return Ext.Loca.GetTranslatedString(Ext.Stats.Get(resourceId).DisplayName, nil)
		end,
		function(status)
			BuildRows(statusTable, status, injury, removeOnConfig, true)
		end)

	for status, _ in pairs(removeOnConfig) do
		BuildRows(statusTable, status, injury, removeOnConfig)
	end
end)

Translator:RegisterTranslation({
	["Delete"] = "hce2116065bec41b5a7ce75c39e627a302842",
	["Remove On Status"] = "h5aafe7131cb74ee4a0a8df3093386146edf5",
	["Status Name (ResourceID)"] = "h17af04db98664960a5d485740a86f4bb4517",
	["Save Conditions"] = "hbe9455faa0784cb99616e5098fd5247dgcg2",
	["# of Stacks To Remove (?)"] = "h125c3399732d41a4a300eee966450e16e61f",
	["i.e. if you set 3rd Degree Burns to remove 2 stacks, you'll have 1st Degree Burns applied"] = "he6354d4907a7431b82c7ebde28275f9a7eae",
})

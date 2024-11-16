---@param statusTable ExtuiTable
---@param status FixedString[]
---@param removeOnConfig InjuryRemoveOnStatusClass
---@param ignoreExistingStatus boolean?
local function BuildRows(statusTable, status, removeOnConfig, ignoreExistingStatus)
	local statusName = status.Name
	if not removeOnConfig[statusName] then
		removeOnConfig[statusName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_remove_on_status_class)
	elseif ignoreExistingStatus then
		return
	end
	local statusConfig = removeOnConfig[statusName]

	local row = statusTable:AddRow()

	--#region Status Name
	local statusNameText = row:AddCell():AddText(status.Name)

	StatusHelper:BuildTooltip(statusNameText:Tooltip(), status)
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

--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar, injury)
	-- Since the keys of this table are dynamic, we can't rely on ConfigurationStructure to initialize the defaults if the entry doesn't exist - we need to do that here
	if not InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status then
		InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status = {}
	end
	local removeOnConfig = InjuryMenu.ConfigurationSlice.injury_specific[injury].remove_on_status

	local statusTab = tabBar:AddTabItem("Remove On Status")

	local statusTable = statusTab:AddTable("RemoveOnStatus", 3)
	statusTable.BordersInnerH = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Status Name")
	headerRow:AddCell():AddText("Save Conditions")

	StatusHelper:BuildSearch(statusTab, function(status)
		BuildRows(statusTable, status, removeOnConfig, true)
	end)

	if next(removeOnConfig) then
		for status, _ in pairs(removeOnConfig) do
			BuildRows(statusTable, Ext.Stats.Get(status), removeOnConfig)
		end
	end
end)

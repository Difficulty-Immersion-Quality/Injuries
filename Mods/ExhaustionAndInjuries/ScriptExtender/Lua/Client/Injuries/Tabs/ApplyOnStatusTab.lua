---@param statusTable ExtuiTable
---@param status string[]
---@param applyOnConfig { [string] : InjuryApplyOnStatus }
---@param ignoreExistingStatus boolean?
local function BuildRows(statusTable, status, applyOnConfig, ignoreExistingStatus)
		local statusName = status.Name
		
		if not applyOnConfig[statusName] then
			applyOnConfig[statusName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_apply_on_status_class)
		elseif ignoreExistingStatus then
			goto continue
		end
		local statusConfig = applyOnConfig[statusName]

		local row = statusTable:AddRow()

		local statusNameText = row:AddCell():AddText(status.Name)

		StatusHelper:BuildTooltip(statusNameText:Tooltip(), status)

		local totalRounds = row:AddCell():AddSliderInt("", statusConfig["number_of_rounds"], 1, 10)
		totalRounds.OnChange = function(slider)
			statusConfig["number_of_rounds"] = slider.Value[1]
		end

		local deleteRowButton = row:AddCell():AddButton("Delete")
		deleteRowButton.OnClick = function()
			statusConfig.delete = true
			row:Destroy()
		end
		::continue::
end

--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar, injury)
	-- Since the keys of this table are dynamic, we can't rely on ConfigurationStructure to initialize the defaults if the entry doesn't exist - we need to do that here
	if not InjuryMenu.ConfigurationSlice.injury_specific[injury].apply_on_status then
		InjuryMenu.ConfigurationSlice.injury_specific[injury].apply_on_status = {}
	end
	local applyOnConfig = InjuryMenu.ConfigurationSlice.injury_specific[injury].apply_on_status
	local statusTab = tabBar:AddTabItem("Apply On Status")

	local statusTable = statusTab:AddTable("ApplyOnStatus", 4)
	statusTable.BordersInnerH = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Status Name")
	headerRow:AddCell():AddText("# Total Rounds")

	StatusHelper:BuildSearch(statusTab, function(status)
		BuildRows(statusTable, status, applyOnConfig, true)
	end)

	if next(applyOnConfig) then
		for status, _ in pairs(applyOnConfig) do
			BuildRows(statusTable, Ext.Stats.Get(status), applyOnConfig)
		end
	end
end)

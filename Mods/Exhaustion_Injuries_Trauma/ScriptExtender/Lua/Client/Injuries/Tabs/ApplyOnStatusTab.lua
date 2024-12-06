---@param statusTable ExtuiTable
---@param status string
---@param applyOnConfig { [StatusName] : InjuryApplyOnStatusModifierClass }
---@param ignoreExistingStatus boolean?
local function BuildRows(statusTable, status, applyOnConfig, ignoreExistingStatus)
	status = Ext.Stats.Get(status)
	local statusName = status.Name

	if not applyOnConfig[statusName] then
		applyOnConfig[statusName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_apply_on_status_class)
	elseif ignoreExistingStatus then
		goto continue
	end
	local statusConfig = applyOnConfig[statusName]

	local row = statusTable:AddRow()

	local statusNameRow = row:AddCell()
	local statusNameText = statusNameRow:AddText(status.Name)
	if status.Icon ~= '' then
		statusNameRow:AddImage(status.Icon, { 30, 30 }).SameLine = true
	end

	StatusHelper:BuildTooltip(statusNameText:Tooltip(), status)

	local multiplier = row:AddCell():AddSliderInt("", statusConfig["multiplier"], 1, 10)
	multiplier.OnChange = function(slider)
		statusConfig["multiplier"] = slider.Value[1]
	end

	local deleteRowButton = row:AddCell():AddButton("Delete")
	deleteRowButton.OnClick = function()
		statusConfig.delete = true
		row:Destroy()
	end
	::continue::
end

--- @param tabBar ExtuiTabBar
--- @param injury InjuryName
InjuryMenu:RegisterTab(function(tabBar, injury)
	-- Since the keys of this table are dynamic, we can't rely on ConfigurationStructure to initialize the defaults if the entry doesn't exist - we need to do that here
	if not InjuryMenu.ConfigurationSlice.injury_specific[injury].apply_on_status then
		InjuryMenu.ConfigurationSlice.injury_specific[injury].apply_on_status =
			TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class.apply_on_status)
	end
	local applyOnConfig = InjuryMenu.ConfigurationSlice.injury_specific[injury].apply_on_status
	local statusTab = tabBar:AddTabItem("Apply On Status")

	statusTab:AddText("How many total (non-consecutive, aggregated) rounds should the below statuses be on a character before the Injury is applied?")
	local statusRounds = statusTab:AddSliderInt("", applyOnConfig["number_of_rounds"], 1, 30)
	statusRounds.OnChange = function()
		applyOnConfig["number_of_rounds"] = statusRounds.Value[1]
	end

	statusTab:AddNewLine()

	local statusTable = statusTab:AddTable("ApplyOnStatus", 4)
	statusTable.BordersInnerH = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Status Name")
	headerRow:AddCell():AddText("Round # Multiplier")

	StatusHelper:BuildSearch(statusTab, function(status)
		BuildRows(statusTable, status, applyOnConfig["applicable_statuses"], true)
	end)

	for status, _ in pairs(applyOnConfig["applicable_statuses"]) do
		BuildRows(statusTable, status, applyOnConfig["applicable_statuses"])
	end
end)

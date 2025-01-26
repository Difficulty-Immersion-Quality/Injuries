---@param statusTable ExtuiTable
---@param status string
---@param applyOnConfig { [StatusName] : InjuryApplyOnStatusModifierClass }
---@param ignoreExistingStatus boolean?
local function BuildRows(statusTable, status, applyOnConfig, ignoreExistingStatus)
	---@type StatsObject
	local statusObj = Ext.Stats.Get(status)

	local statusName = statusObj.Name

	if not applyOnConfig[statusName] then
		applyOnConfig[statusName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_apply_on_status_class)
	elseif ignoreExistingStatus then
		return
	end
	local statusConfig = applyOnConfig[statusName]

	local row = statusTable:AddRow()

	local statusNameRow = row:AddCell()
	if statusObj.Icon ~= '' then
		statusNameRow:AddImage(statusObj.Icon, { 30, 30 })
	end
	local statusNameText = statusNameRow:AddText(statusObj.Name)
	statusNameText.SameLine = true

	DataSearchHelper:BuildStatusTooltip(statusNameText:Tooltip(), statusObj)

	local multiplier = row:AddCell():AddSliderInt("", statusConfig["multiplier"], 1, 10)
	multiplier.OnChange = function(slider)
		statusConfig["multiplier"] = slider.Value[1]
	end

	local guaranteeApplicationCheckbox = row:AddCell():AddCheckbox("", statusConfig["guarantee_application"])
	guaranteeApplicationCheckbox.OnChange = function ()
		statusConfig["guarantee_application"] = guaranteeApplicationCheckbox.Checked
	end

	local deleteRowButton = row:AddCell():AddButton("Delete")
	deleteRowButton.OnClick = function()
		statusConfig.delete = true
		row:Destroy()
	end
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
	statusTab.TextWrapPos = 0

	statusTab:AddText("How many total (non-consecutive, aggregated) rounds should the below statuses be on a character before the Injury is applied?")
	local statusRounds = statusTab:AddSliderInt("", applyOnConfig["number_of_rounds"], 1, 30)
	statusRounds.OnChange = function()
		applyOnConfig["number_of_rounds"] = statusRounds.Value[1]
	end

	statusTab:AddNewLine()

	local statusTable = statusTab:AddTable("ApplyOnStatus", 4)
	statusTable.Resizable = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Status Name (ResourceID)")
	headerRow:AddCell():AddText("Round # Multiplier")
	headerRow:AddCell():AddText("Guarantee Injury Application (?)"):Tooltip():AddText("\t\t If the chance for injury application is less than 100% (General Rules tab), then checking this box will ignore that and apply the injury 100% of the time (if this status is the one that triggers the injury)").TextWrapPos = 600

	DataSearchHelper:BuildSearch(statusTab,
		Ext.Stats.GetStats("StatusData"),
		function(resourceId)
			return Ext.Loca.GetTranslatedString(Ext.Stats.Get(resourceId).DisplayName, nil)
		end,
		function(status)
			BuildRows(statusTable, status, applyOnConfig["applicable_statuses"], true)
		end)

	for status, _ in pairs(applyOnConfig["applicable_statuses"]) do
		BuildRows(statusTable, status, applyOnConfig["applicable_statuses"])
	end
end)

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
	guaranteeApplicationCheckbox.OnChange = function()
		statusConfig["guarantee_application"] = guaranteeApplicationCheckbox.Checked
	end

	local deleteRowButton = row:AddCell():AddButton(Translator:translate("Delete"))
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
	local statusTab = tabBar:AddTabItem(Translator:translate("Apply On Status"))
	statusTab.TextWrapPos = 0

	statusTab:AddText(Translator:translate("How many total (non-consecutive, aggregated) rounds should the below statuses be on a character before the Injury is applied?"))
	local statusRounds = statusTab:AddSliderInt("", applyOnConfig["number_of_rounds"], 1, 30)
	statusRounds.OnChange = function()
		applyOnConfig["number_of_rounds"] = statusRounds.Value[1]
	end

	statusTab:AddNewLine()

	local statusTable = statusTab:AddTable("ApplyOnStatus", 4)
	statusTable.Resizable = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText(Translator:translate("Status Name (ResourceID)"))
	headerRow:AddCell():AddText(Translator:translate("Round # Multiplier"))
	headerRow:AddCell():AddText(Translator:translate("Guarantee Injury Application (?)")):Tooltip():AddText("\t\t " .. Translator:translate("If the chance for injury application is less than 100% (General Rules tab), then checking this box will ignore that and apply the injury 100% of the time (if this status is the one that triggers the injury)")).TextWrapPos = 600

	DataSearchHelper:BuildSearch(statusTab,
		Ext.Stats.GetStats("StatusData"),
		function(resourceId)
			return Ext.Loca.GetTranslatedString(Ext.Stats.Get(resourceId).DisplayName, nil)
		end,
		function(status)
			if not applyOnConfig["applicable_statuses"] then
				applyOnConfig["applicable_statuses"] = {}
			end
			BuildRows(statusTable, status, applyOnConfig["applicable_statuses"], true)
		end)

	if applyOnConfig["applicable_statuses"] then
		for status, _ in pairs(applyOnConfig["applicable_statuses"]) do
			BuildRows(statusTable, status, applyOnConfig["applicable_statuses"])
		end
	end
end)

Translator:RegisterTranslation({
	["Delete"] = "hc1c5dc21b84e4079ad868a8081c86a6301d3",
	["Apply On Status"] = "hd32bf68edf8741eab48fa41ad6c76a8929g4",
	["How many total (non-consecutive, aggregated) rounds should the below statuses be on a character before the Injury is applied?"] = "h088d7c8b3587413f8f9a452ceb4d7e6984d4",
	["Status Name (ResourceID)"] = "ha54ea9b2153f4a95af1a5bbd99b23e9151cd",
	["Round # Multiplier"] = "h937dd0c975ab4ff0acbdfc2cc6b3cf666f7d",
	["Guarantee Injury Application (?)"] = "h58b6ebc929ff49bbba04e3f2e1a1dbe7b4e6",
	["If the chance for injury application is less than 100% (General Rules tab), then checking this box will ignore that and apply the injury 100% of the time (if this status is the one that triggers the injury)"] =
	"h79a85e2f12d44e72a2b4c42dc5e716c11e45",
})

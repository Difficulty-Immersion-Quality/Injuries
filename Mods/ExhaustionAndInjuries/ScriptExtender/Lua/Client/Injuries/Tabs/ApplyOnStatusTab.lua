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
				local statusName = status.Name
				applyOnConfig[statusName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_apply_on_status_class)
				local statusConfig = applyOnConfig[statusName]

				local row = statusTable:AddRow()

				local statusName = row:AddCell():AddText(status.Name)
				local nameTooltip = statusName:Tooltip()

				nameTooltip:AddText("StatusType: " .. status.StatusType)

				if status.TooltipDamage ~= "" then
					nameTooltip:AddText("Damage: " .. status.TooltipDamage)
				end

				if status.TooltipSave ~= "" then
					nameTooltip:AddText("Save: " .. status.TooltipSave)
				end

				if status.TickType ~= "" then
					nameTooltip:AddText("TickType: " .. status.TickType)
				end

				local totalRounds = row:AddCell():AddSliderInt("", 1, 1, 10)
				totalRounds.OnChange = function(slider)
					statusConfig["number_of_rounds"] = slider.Value[1]
				end

				local deleteRowButton = row:AddCell():AddButton("Delete")
				deleteRowButton.OnClick = function()
					statusConfig.delete = true
					row:Destroy()
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

--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar)
	local damageTab = tabBar:AddTabItem("Apply On Status")

	local damageTable = damageTab:AddTable("ApplyOnStatus", 4)
	damageTable.BordersOuter = true
	
	local headerRow = damageTable:AddRow()
	headerRow:AddCell():AddText("Status Name")
	headerRow:AddCell():AddText("# Total Rounds In One Combat")
	headerRow:AddCell():AddText("Always Apply On Critical Hit")

	damageTab:AddText("Add New Row")
	local statusInput = damageTab:AddInputText("")
	statusInput.Hint = "Case-insensitive - use * to wildcard"
	statusInput.AutoSelectAll = true
	statusInput.EscapeClearsAll = true
	
	local statusInputButton = damageTab:AddButton("Register Status")

	local errorText = damageTab:AddText("Error: Search returned no results")
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
				if status.TooltipDamage ~= "" then
					local row = damageTable:AddRow()

					local statusName = row:AddCell():AddText(status.Name)
					local nameTooltip = statusName:Tooltip()
					nameTooltip:AddText(status.TooltipDamage)
					if status.TooltipSave ~= "" then
						nameTooltip:AddText("Save: " .. status.TooltipSave)
					end

					local totalRounds = row:AddCell():AddSliderInt("")
					totalRounds.Min = { 1, 1, 1, 1 }
					totalRounds.Max = { 10, 10, 10, 10 }

					local roundsTooltip = totalRounds:Tooltip()
					roundsTooltip:AddText("How many total rounds within a single combat this status needs to be applied\non a given character before the injury is applied")

					local onCritCheckbox = row:AddCell():AddCheckbox("Always On Critical Fail?", true)
					local deleteRowButton = row:AddCell():AddButton("Delete")

					deleteRowButton.OnClick = function()
						row:Destroy()
					end
				end
			end
		else
			errorText.Visible = true
		end
	end

	statusInput.OnChange = function()
		if errorText then
			errorText.Visible = false
		end
	end
end)

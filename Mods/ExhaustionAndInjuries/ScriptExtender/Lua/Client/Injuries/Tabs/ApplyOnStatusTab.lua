--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar)
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
				if string.upper(status.StatusType) == "BOOST" then
					local row = statusTable:AddRow()

					local statusName = row:AddCell():AddText(status.Name)
					local nameTooltip = statusName:Tooltip()

					if status.TooltipDamage ~= "" then
						nameTooltip:AddText("Damage: " .. status.TooltipDamage)
					end

					if status.TooltipSave ~= "" then
						nameTooltip:AddText("Save: " .. status.TooltipSave)
					end

					if status.TickType ~= "" then
						nameTooltip:AddText("TickType: " .. status.TickType)
					end

					local totalRounds = row:AddCell():AddSliderInt("")
					totalRounds.Min = { 1, 1, 1, 1 }
					totalRounds.Max = { 10, 10, 10, 10 }

					local roundsTooltip = totalRounds:Tooltip()
					roundsTooltip:AddText("How many total rounds within a single combat this status needs to be applied\non a given character before the injury is applied")

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

	statusInput.OnChange = function(inputElement, text)
			errorText.Visible = false
	end
end)

--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar)
	local statusTab = tabBar:AddTabItem("Remove On Status")

	local statusTable = statusTab:AddTable("RemoveOnStatus", 3)
	statusTable.BordersInnerH = true

	local headerRow = statusTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Status Name")
	headerRow:AddCell():AddText("Save Conditions")

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

					--#region Status Name
					local statusName = row:AddCell():AddText(status.Name)
					local nameTooltip = statusName:Tooltip()

					if status.TooltipDamage ~= "" then
						nameTooltip:AddText("Damage: " .. status.TooltipDamage)
					end

					if status.HealValue ~= "" then
						nameTooltip:AddText("Healing: |Value: " .. status.HealthValue .. " |Stat: " .. status.HealStat .. "|Multiplier: " .. status.HealMultiplier .. "|")
					end

					if status.TooltipSave ~= "" then
						nameTooltip:AddText("Save: " .. status.TooltipSave)
					end

					if status.TickType ~= "" then
						nameTooltip:AddText("TickType: " .. status.TickType)
					end
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
					saveCombo.SelectedIndex = 0

					local saveSlider = saveRow:AddSliderInt("")
					saveSlider.Min = { 1, 1, 1, 1 }
					saveSlider.Max = { 30, 30, 30, 30 }
					saveSlider.Value = {15, 15, 15, 15}
					saveSlider.Visible = false

					saveCombo.OnChange = function(combo, selectedIndex)
						saveSlider.Visible = selectedIndex ~= 0
					end
					--#endregion

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

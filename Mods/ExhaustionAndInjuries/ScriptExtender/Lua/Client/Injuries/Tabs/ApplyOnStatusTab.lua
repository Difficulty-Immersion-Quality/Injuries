--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar)
	local damageTab = tabBar:AddTabItem("Apply On Status")

	local damageTable = damageTab:AddTable("ApplyOnStatus", 4)
	damageTable.BordersOuter = true

	damageTab:AddText("Add New Row")
	local statusInput = damageTab:AddInputText("")
	local statusInputButton = damageTab:AddButton("Register Status")

	--- @type ExtuiText|nil
	local errorText

	statusInputButton.OnClick = function()
		local statuses = {}
		local inputText = string.upper(statusInput.Text)

		for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
			if string.find(string.upper(name), inputText) then
				table.insert(statuses, Ext.Stats.Get(name))
			end
		end

		if #statuses then
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
					roundsTooltip:AddText("How many total rounds within a single combat this status needs to be applied on a given character before the injury is applied")

					local onCritCheckbox = row:AddCell():AddCheckbox("Always On Critical Fail?", true)
					local deleteRowButton = row:AddCell():AddButton("Delete")

					deleteRowButton.OnClick = function()
						row:Destroy()
					end
				end
			end
		else
			errorText = damageTab:AddText("Error: There are no statuses that contain the provided text")
		end
	end

	statusInput.OnChange = function()
		if errorText then
			errorText:Destroy()
			errorText = nil
		end
	end
end)

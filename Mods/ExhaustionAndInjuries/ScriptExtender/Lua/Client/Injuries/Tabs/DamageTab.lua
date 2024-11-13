--- @param tabBar ExtuiTabBar
InjuryMenu:RegisterTab(function(tabBar, injury)
	-- Since the keys of this table are dynamic, we can't rely on ConfigurationStructure to initialize the defaults if the entry doesn't exist - we need to do that here
	if not InjuryMenu.ConfigurationSlice.injury_specific[injury].damage then
		InjuryMenu.ConfigurationSlice.injury_specific[injury].damage = {}
	end
	local damageConfig = InjuryMenu.ConfigurationSlice.injury_specific[injury].damage

	local damageTab = tabBar:AddTabItem("Damage")

	local damageTable = damageTab:AddTable("DamageTypes", 3)
	damageTable.BordersInnerH = true

	local headerRow = damageTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Damage Type")
	headerRow:AddCell():AddText("% of Total Health")

	damageTab:AddText("Add New Row")
	local damageTypeCombo = damageTab:AddCombo("")
	damageTypeCombo.SameLine = true

	local damageTypes = {}
	for _, damageType in ipairs(Ext.Enums.DamageType) do
		table.insert(damageTypes, tostring(damageType))
	end
	damageTypeCombo.Options = damageTypes
	damageTypeCombo.SelectedIndex = 0
	damageTypeCombo.WidthFitPreview = true

	--- @param combo ExtuiCombo
	--- @param selectedIndex integer
	damageTypeCombo.OnChange = function(combo, selectedIndex)
		local row = damageTable:AddRow()

		local damageType = combo.Options[selectedIndex + 1]

		if not damageConfig[damageType] then
			damageConfig[damageType] = {}
		end

		row:AddCell():AddText(damageType)

		local damageThresholdDefault = 10
		local configThresholdValue = damageConfig[damageType]["health_threshold"]
		if configThresholdValue then
			damageThresholdDefault = configThresholdValue
		else
			damageConfig[damageType]["health_threshold"] = damageThresholdDefault
		end
		local damageTypeThreshold = row:AddCell():AddSliderInt("", damageThresholdDefault, 1, 100)

		damageTypeThreshold.OnChange = function()
			damageConfig[damageType]["health_threshold"] = damageTypeThreshold.Value[1]
		end

		local deleteRowButton = row:AddCell():AddButton("Delete")

		deleteRowButton.OnClick = function()
			-- hack to allow us to monitor table deletion
			damageConfig[damageType].delete = true
			row:Destroy()
		end
	end
end)

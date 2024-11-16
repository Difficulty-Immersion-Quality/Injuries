local function BuildRow(damageTable, damageType, damageConfig, damageCombo)
	local row = damageTable:AddRow()

	if not damageConfig[damageType] then
		damageConfig[damageType] = ConfigurationStructure.DynamicClassDefinitions.injury_damage_class
	end

	row:AddCell():AddText(damageType)

	local damageTypeThreshold = row:AddCell():AddSliderInt("", damageConfig[damageType]["health_threshold"], 1, 100)

	damageTypeThreshold.OnChange = function()
		damageConfig[damageType]["health_threshold"] = damageTypeThreshold.Value[1]
	end

	local deleteRowButton = row:AddCell():AddButton("Delete")

	local newOptions = {}
	for _, option in pairs(damageCombo.Options) do
		if option ~= damageType then
			table.insert(newOptions, option)
		end
	end
	table.sort(newOptions)
	damageCombo.Options = newOptions

	deleteRowButton.OnClick = function()
		-- hack to allow us to monitor table deletion
		damageConfig[damageType].delete = true

		local newOptions = {}
		for _, option in pairs(damageCombo.Options) do
			table.insert(newOptions, option)
		end
		table.insert(newOptions, damageType)
		table.sort(newOptions)
		damageCombo.Options = newOptions

		row:Destroy()
	end
end

--- @param tabBar ExtuiTabBar
--- @param injury InjuryName
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
	table.sort(damageTypes)

	damageTypeCombo.Options = damageTypes
	damageTypeCombo.SelectedIndex = 0
	damageTypeCombo.WidthFitPreview = true

	--- @param combo ExtuiCombo
	--- @param selectedIndex integer
	damageTypeCombo.OnChange = function(combo, selectedIndex)
		BuildRow(damageTable, combo.Options[selectedIndex + 1], damageConfig, damageTypeCombo)
	end

	if next(damageConfig) then
		for damageType, _ in pairs(damageConfig) do
			BuildRow(damageTable, damageType, damageConfig, damageTypeCombo)
		end
	end
end)

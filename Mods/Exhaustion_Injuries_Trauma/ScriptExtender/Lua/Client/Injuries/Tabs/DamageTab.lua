---@param damageTable ExtuiTable
---@param damageType DamageType
---@param damageConfig InjuryDamageClass
---@param damageCombo ExtuiCombo
local function BuildRow(damageTable, damageType, damageConfig, damageCombo)
	local row = damageTable:AddRow()

	if not damageConfig["damage_types"][damageType] then
		damageConfig["damage_types"][damageType] = ConfigurationStructure.DynamicClassDefinitions.injury_damage_type_class
	end
	local damageTypeConfig = damageConfig["damage_types"][damageType]

	row:AddCell():AddText(damageType)

	local damageTypeThreshold = row:AddCell():AddSliderInt("", damageTypeConfig["multiplier"] * 100, 1, 500)

	damageTypeThreshold.OnChange = function()
		-- Rounding, according to ChatGPT
		damageTypeConfig["multiplier"] = math.floor(damageTypeThreshold.Value[1] * 100 + 0.5) / 10000
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
		damageConfig["damage_types"][damageType].delete = true

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

	damageTab:AddText("Applied after losing the following % of Health:")
	local damageThreshold = damageTab:AddSliderInt("", damageConfig["threshold"], 0, 100)
	damageThreshold.SameLine = true
	damageThreshold.OnChange = function ()
		damageConfig["threshold"] = damageThreshold.Value[1]
	end

	local damageTable = damageTab:AddTable("DamageTypes", 3)
	damageTable.BordersInnerH = true

	local headerRow = damageTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Damage Type")
	headerRow:AddCell():AddText("Multiplier %")

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
		for damageType, _ in pairs(damageConfig["damage_types"]) do
			BuildRow(damageTable, damageType, damageConfig, damageTypeCombo)
		end
	end
end)

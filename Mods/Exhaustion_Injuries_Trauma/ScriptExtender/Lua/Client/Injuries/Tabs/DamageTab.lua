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

	local damageCell = row:AddCell()
	local damageTypeForImage = damageType
	if damageTypeForImage == "Piercing" or damageTypeForImage == "Bludgeoning" or damageTypeForImage == "Slashing" then
		damageTypeForImage = "Physical"
	end

	damageCell:AddImage("GenericIcon_DamageType_" .. damageTypeForImage, { 36, 36 })
	damageCell:AddText(damageType).SameLine = true

	local damageTypeThreshold = row:AddCell():AddSliderInt("", damageTypeConfig["multiplier"] * 100, 1, 500)

	local thresholdTooltip = damageTypeThreshold:Tooltip()
	local tooltipText = thresholdTooltip:AddText(string.format("\t\t10 points of %s damage contributes %s points of Injury Damage",
		damageType,
		10 * damageTypeConfig["multiplier"]))

	damageTypeThreshold.OnChange = function()
		-- Rounding, according to ChatGPT
		damageTypeConfig["multiplier"] = math.floor(damageTypeThreshold.Value[1] * 100 + 0.5) / 10000
		
		tooltipText.Label = string.format("\t\t10 points of %s damage contributes %s points of Injury Damage",
			damageType,
			10 * damageTypeConfig["multiplier"])
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
	damageCombo.SelectedIndex = -1

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

		damageCombo.SelectedIndex = -1

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

	damageTab:AddText("Applied after total damage from all configured DamageTypes is >= the following % of Health:")
	local damageThreshold = damageTab:AddSliderInt("", damageConfig["threshold"], 0, 100)
	damageThreshold.OnChange = function()
		damageConfig["threshold"] = damageThreshold.Value[1]
	end

	damageTab:AddSeparatorText("What Damage Types Contribute to Injury Damage?")

	local damageTable = damageTab:AddTable("DamageTypes", 3)
	damageTable.BordersInnerH = true

	local headerRow = damageTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Damage Type")
	headerRow:AddCell():AddText("Injury Damage Multiplier %")

	damageTab:AddText("Add New Row")
	local damageTypeCombo = damageTab:AddCombo("")
	damageTypeCombo.SameLine = true

	local damageTypes = {}
	for _, damageType in ipairs(Ext.Enums.DamageType) do
		table.insert(damageTypes, tostring(damageType))
	end
	table.sort(damageTypes)

	damageTypeCombo.Options = damageTypes
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

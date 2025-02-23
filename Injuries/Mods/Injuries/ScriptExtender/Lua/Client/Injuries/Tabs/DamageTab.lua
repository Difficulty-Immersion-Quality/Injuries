---@param damageTable ExtuiTable
---@param damageType DamageType
---@param damageConfig InjuryDamageClass
---@return ExtuiTableRow
local function BuildRow(damageTable, damageType, damageConfig)
	local row = damageTable:AddRow()

	if not damageConfig["damage_types"] then
		damageConfig["damage_types"] = {}
	end
	if not damageConfig["damage_types"][damageType] then
		damageConfig["damage_types"][damageType] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_damage_type_class)
	end
	local damageTypeConfig = damageConfig["damage_types"][damageType]

	local damageCell = row:AddCell()
	local damageTypeForImage = damageType
	if damageTypeForImage == "Piercing" or damageTypeForImage == "Bludgeoning" or damageTypeForImage == "Slashing" then
		damageTypeForImage = "Physical"
	end

	damageCell:AddImage("GenericIcon_DamageType_" .. damageTypeForImage, { 36, 36 })
	damageCell:AddText(damageType).SameLine = true

	local damageTypeThreshold = row:AddCell():AddSliderInt("", math.floor(damageTypeConfig["multiplier"] * 100), 1, 500)

	local thresholdTooltip = damageTypeThreshold:Tooltip()
	local tooltipText = thresholdTooltip:AddText(string.format("\t\t" .. Translator:translate("10 points of %s damage contributes %s points of Injury Damage"),
		damageType,
		10 * damageTypeConfig["multiplier"]))

	damageTypeThreshold.OnChange = function()
		damageTypeConfig["multiplier"] = damageTypeThreshold.Value[1] / 100

		tooltipText.Label = string.format("\t\t" .. Translator:translate("10 points of %s damage contributes %s points of Injury Damage"),
			damageType,
			10 * damageTypeConfig["multiplier"])
	end

	return row
end

--- @param tabBar ExtuiTabBar
--- @param injury InjuryName
InjuryMenu:RegisterTab(function(tabBar, injury)
	-- Since the keys of this table are dynamic, we can't rely on ConfigurationStructure to initialize the defaults if the entry doesn't exist - we need to do that here
	if not InjuryMenu.ConfigurationSlice.injury_specific[injury].damage then
		InjuryMenu.ConfigurationSlice.injury_specific[injury].damage = {}
	end
	local damageConfig = InjuryMenu.ConfigurationSlice.injury_specific[injury].damage

	local damageTab = tabBar:AddTabItem(Translator:translate("Damage"))
	damageTab.TextWrapPos = 0

	damageTab:AddText(Translator:translate("Applied after total damage from all configured DamageTypes is >= the following % of Health:"))
	local damageThreshold = damageTab:AddSliderInt("", damageConfig["threshold"], 0, 100)
	damageThreshold.OnChange = function()
		damageConfig["threshold"] = damageThreshold.Value[1]
	end

	damageTab:AddSeparatorText(Translator:translate("What Damage Types Contribute to Injury Damage?"))

	local damageTable = damageTab:AddTable("DamageTypes", 3)
	damageTable.BordersInnerH = true

	local headerRow = damageTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText(Translator:translate("Damage Type"))
	headerRow:AddCell():AddText(Translator:translate("Injury Damage Multiplier %"))

	local damageTypes = {}
	for _, damageType in ipairs(Ext.Enums.DamageType) do
		if tostring(damageType) ~= "Sentinel" then
			table.insert(damageTypes, tostring(damageType))
		end
	end
	table.sort(damageTypes)

	local addRowButton = damageTab:AddButton("+")
	local damageTypePopup = damageTab:AddPopup("")

	for _, damageType in pairs(damageTypes) do
		---@type ExtuiSelectable
		local damageSelect = damageTypePopup:AddSelectable(damageType, "DontClosePopups")

		damageSelect.OnActivate = function()
			if damageSelect.UserData then
				damageSelect.UserData:Destroy()
				damageSelect.UserData = nil
				damageConfig["damage_types"][damageType].delete = true
				damageConfig["damage_types"][damageType] = nil
			else
				damageSelect.UserData = BuildRow(damageTable, damageType, damageConfig)
			end
		end

		if damageConfig["damage_types"] and damageConfig["damage_types"][damageType] then
			damageSelect.Selected = true
			damageSelect:OnActivate()
		end
	end

	addRowButton.OnClick = function()
		damageTypePopup:Open()
	end
end)

Translator:RegisterTranslation({
	["10 points of %s damage contributes %s points of Injury Damage"] = "h77732ab1f47b48599d1583e8f57932aad0a2",
	["Damage"] = "h95a95752c92647a8a9c2c6eb130e1696b6gb",
	["Applied after total damage from all configured DamageTypes is >= the following % of Health:"] = "hdf110c00af5c447782a7bf5e7e3e35c954e6",
	["What Damage Types Contribute to Injury Damage?"] = "h942494a3f05b4795be91c7d83536346f8g72",
	["Damage Type"] = "h192362c2dca1421da023f113a75fa49dc485",
	["Injury Damage Multiplier %"] = "h3c6d9998781a457b88ff11c6d2376a0670ef",
})

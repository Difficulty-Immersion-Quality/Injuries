-- #region Friggen Lua relying on numbers for everything
local raceNameToUUID = {}
local sortedRaceList = {}
for _, raceUUID in pairs(Ext.StaticData.GetAll("Race")) do
	---@type ResourceRace
	local raceData = Ext.StaticData.Get(raceUUID, "Race")

	local displayName = string.format("%s (%s)",
		(raceData.DisplayName:Get() or (Translator:translate("Can't Translate"))),
		string.sub(raceUUID, -5))

	raceNameToUUID[displayName] = raceUUID
	table.insert(sortedRaceList, displayName)
end

table.sort(sortedRaceList)
--#endregion

--- @param tabBar ExtuiTabBar
--- @param injury InjuryName
InjuryMenu:RegisterTab(function(tabBar, injury)
	-- Since the keys of this table are dynamic, we can't rely on ConfigurationStructure to initialize the defaults if the entry doesn't exist - we need to do that here
	if not InjuryMenu.ConfigurationSlice.injury_specific[injury].character_multipliers then
		InjuryMenu.ConfigurationSlice.injury_specific[injury].character_multipliers =
			TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class.character_multipliers)
	end
	local charMultiplierConfig = InjuryMenu.ConfigurationSlice.injury_specific[injury].character_multipliers

	local multiplierTab = tabBar:AddTabItem(Translator:translate("Character Multipliers"))
	multiplierTab.TextWrapPos = 0

	--#region Races
	local raceHeader = multiplierTab:AddCollapsingHeader(Translator:translate("Races"))
	raceHeader.DefaultOpen = true

	local raceTable = raceHeader:AddTable("Races", 2)
	raceTable.BordersInnerH = true
	raceTable.SizingStretchProp = true
	raceTable.Resizable = true

	local headerRow = raceTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText(Translator:translate("Race"))
	headerRow:AddCell():AddText(Translator:translate("Multiplier (%)"))

	local function buildRaceSlider(raceUUID, raceName)
		local newRow = raceTable:AddRow()
		newRow:AddCell():AddText(raceName)

		if not charMultiplierConfig["races"] or not charMultiplierConfig["races"][raceUUID] then
			charMultiplierConfig["races"][raceUUID] = 1
		end

		local newSlider = newRow:AddCell():AddSliderInt("", math.floor(charMultiplierConfig["races"][raceUUID] * 100), 0, 500)
		newSlider.OnChange = function(slider)
			if not charMultiplierConfig["races"] then
				charMultiplierConfig["races"] = {}
			end

			---@cast slider ExtuiSliderInt
			charMultiplierConfig["races"][raceUUID] = slider.Value[1] / 100
		end

		return newRow
	end

	local addRowButton = raceHeader:AddButton("+")
	local racePopop = raceHeader:AddPopup("")

	for _, raceName in pairs(sortedRaceList) do
		local raceUUID = raceNameToUUID[raceName]
		---@type ResourceRace
		local raceData = Ext.StaticData.Get(raceUUID, "Race")

		---@type ExtuiSelectable
		local raceSelect = racePopop:AddSelectable(raceName, "DontClosePopups")

		local raceTooltip = raceSelect:Tooltip()
		raceTooltip:AddText(string.format(Translator:translate("Resource Name:") .. " %s", raceData.Name))
		raceTooltip:AddText(string.format(Translator:translate("UUID:") .. " %s", raceUUID))
		raceTooltip:AddText(string.format(Translator:translate("Description:") .. " %s", raceData.Description:Get())).TextWrapPos = 600

		raceSelect.OnActivate = function()
			if raceSelect.UserData then
				raceSelect.UserData:Destroy()
				raceSelect.UserData = nil
				charMultiplierConfig["races"][raceUUID] = nil
			else
				raceSelect.UserData = buildRaceSlider(raceUUID, raceName)
			end
		end

		if charMultiplierConfig["races"] and charMultiplierConfig["races"][raceUUID] then
			raceSelect.Selected = true
			raceSelect:OnActivate()
		end
	end

	addRowButton.OnClick = function()
		racePopop:Open()
	end
	--#endregion

	--#region Tags
	multiplierTab:AddNewLine()
	local tagsHeader = multiplierTab:AddCollapsingHeader(Translator:translate("Tags"))
	tagsHeader.DefaultOpen = true

	tagsHeader:AddText(Translator:translate("If multiple tags are present on a character, their multipliers will be multiplied together - e.g. (100% * 30% == 30% final multiplier)")).TextWrapPos = 0

	local tagTable = tagsHeader:AddTable("TagTable", 3)
	tagTable.BordersInnerH = true
	tagTable.SizingStretchProp = true
	tagTable.Resizable = true

	local tagHeaderRow = tagTable:AddRow()
	tagHeaderRow.Headers = true
	tagHeaderRow:AddCell():AddText(Translator:translate("Name (Display Name - ID)"))
	tagHeaderRow:AddCell():AddText(Translator:translate("% Multiplier"))

	local function buildTagRow(tagUUID, ignoreExistingRecord)
		---@type ResourceTag
		local tagData = Ext.StaticData.Get(tagUUID, "Tag")

		if not charMultiplierConfig["tags"][tagUUID] then
			charMultiplierConfig["tags"][tagUUID] = 1
		elseif ignoreExistingRecord then
			return
		end

		local row = tagTable:AddRow()

		local tagNameCell = row:AddCell()
		tagNameCell:AddText(string.format("%s (%s - %s)",
			tagData.Name,
			tagData.DisplayName:Get() or Translator:translate("N/A"),
			string.sub(tagData.ResourceUUID, -5)
		))

		local toolTip = tagNameCell:Tooltip()
		if tagData.Icon ~= "" then
			toolTip:AddImage(tagData.Icon, { 30, 30 })
		end
		toolTip:AddText(Translator:translate("Display Name:") .. " " .. (tagData.DisplayName:Get() or Translator:translate("N/A"))).SameLine = true
		toolTip:AddText(Translator:translate("ResourceId:") .. " " .. tagUUID)
		toolTip:AddText(Translator:translate("Tag UUID:") .. " " .. tagData.ResourceUUID)
		toolTip:AddText(Translator:translate("Description:") .. " " .. (tagData.Description ~= "" and tagData.Description or Translator:translate("N/A")))
		toolTip:AddText(Translator:translate("Display Description:") .. " " .. (tagData.DisplayDescription:Get() or Translator:translate("N/A")))

		local multiplier = row:AddCell():AddSliderInt("", math.floor(charMultiplierConfig["tags"][tagUUID] * 100), 0, 500)
		multiplier.OnChange = function()
			charMultiplierConfig["tags"][tagUUID] = multiplier.Value[1] / 100
		end

		row:AddCell():AddButton(Translator:translate("Delete")).OnClick = function()
			charMultiplierConfig["tags"][tagUUID] = nil
			row:Destroy()
		end
	end

	StatusHelper:BuildSearch(tagsHeader,
		Ext.StaticData.GetAll("Tag"),
		function(id)
			return Ext.StaticData.Get(id, "Tag").DisplayName:Get()
		end,
		function(tagUUID)
			buildTagRow(tagUUID, true)
		end)

	if charMultiplierConfig["tags"] then
		for tagUUID, _ in pairs(charMultiplierConfig["tags"]) do
			buildTagRow(tagUUID, false)
		end
	end
	--#endregion
end)

Translator:RegisterTranslation({
	["Can't Translate"] = "h083eca37a9d64a499e02c746c60459ab97g2",
	["Character Multipliers"] = "hc53c9e27bdff459a8fca5241b55e5ba8eg4f",
	["Races"] = "ha53ab4a9feb24908bb820177c714ab0e8g00",
	["Race"] = "h274d07d40f19497bb2725503e284af1ac516",
	["Multiplier (%)"] = "hb70b79aad49b400f824161698ebc612c5d68",
	["Resource Name:"] = "h0cee4cf85a3b4c4580c7f6d396ed9b5c8609",
	["UUID:"] = "h652d5e5c916f4f20b9022f295bb7aa9345e2",
	["Description:"] = "hed01418847b541ed8d7409f2005680ad457g",
	["Tags"] = "h8901bd2ebb8d4f4da8e4df70c44e83745b7f",
	["If multiple tags are present on a character, their multipliers will be multiplied together - e.g. (100% * 30% == 30% final multiplier)"] =
	"he5e4f7e52a264633bfed00514a7c077ab506",
	["Name (Display Name - ID)"] = "h923d7335722f4c6589f8abb9761d124b47a1",
	["% Multiplier"] = "h77b2a94cb0204e0c98ee08217f5098a28136",
	["N/A"] = "h4dc4bb8bd0574f3790f38849055385955b50",
	["Display Name:"] = "h09cebe760b1d4e3f9df49ae1091f6bd14b7d",
	["ResourceId:"] = "h7cf79c8770384e6b933ad9a7c5f17b2dcbd9",
	["Tag UUID:"] = "h72738de2d12d41798d6780e4512bef70a9g1",
	["Display Description:"] = "h56eb6fe545af4fe3b335bc5483844b98be02",
	["Delete"] = "h55fb845d61da4b6ba21457c35b05edfc672g",
	[""] = "",
	[""] = "",
	[""] = "",
	[""] = "",
})

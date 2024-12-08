-- #region Friggen Lua relying on numbers for everything
local raceNameToUUID = {}
local sortedRaceList = {}
for _, raceUUID in pairs(Ext.StaticData.GetAll("Race")) do
	---@type ResourceRace
	local raceData = Ext.StaticData.Get(raceUUID, "Race")

	local displayName = string.format("%s (%s)",
		(raceData.DisplayName:Get() or ("Can't Translate")),
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

	local multiplierTab = tabBar:AddTabItem("Character Multipliers")

	--#region Races
	local raceHeader = multiplierTab:AddCollapsingHeader("Races")
	raceHeader.DefaultOpen = true

	local raceTable = raceHeader:AddTable("Races", 2)
	raceTable.SizingStretchProp = true
	local headerRow = raceTable:AddRow()
	headerRow.Headers = true
	headerRow:AddCell():AddText("Race")
	headerRow:AddCell():AddText("Multiplier (%)")

	local function buildRaceSlider(raceUUID, raceName)
		local newRow = raceTable:AddRow()
		newRow:AddCell():AddText(raceName)

		if not charMultiplierConfig["races"][raceUUID] then
			charMultiplierConfig["races"][raceUUID] = 1
		end

		local newSlider = newRow:AddCell():AddSliderInt("", charMultiplierConfig["races"][raceUUID] * 100, 0, 500)
		newSlider.OnChange = function(slider)
			---@cast slider ExtuiSliderInt
			charMultiplierConfig["races"][raceUUID] = tonumber(string.format("%.2f", slider.Value[1] / 100))
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
		raceTooltip:AddText(string.format("Resource Name: %s", raceData.Name))
		raceTooltip:AddText(string.format("UUID: %s", raceUUID))
		raceTooltip:AddText(string.format("Description: %s", raceData.Description:Get())).TextWrapPos = 600

		raceSelect.OnActivate = function()
			if raceSelect.UserData then
				raceSelect.UserData:Destroy()
				raceSelect.UserData = nil
				charMultiplierConfig["races"][raceUUID] = nil
			else
				raceSelect.UserData = buildRaceSlider(raceUUID, raceName)
			end
		end

		if charMultiplierConfig["races"][raceUUID] then
			raceSelect.Selected = true
			raceSelect:OnActivate()
		end
	end

	addRowButton.OnClick = function()
		racePopop:Open()
	end
	--#endregion

	--#region Tags
	local tagsHeader = multiplierTab:AddCollapsingHeader("Tags")
	tagsHeader.DefaultOpen = true

	local tagTable = tagsHeader:AddTable("TagTable", 3)
	local tagHeaderRow = tagTable:AddRow()
	tagHeaderRow.Headers = true
	tagHeaderRow:AddCell():AddText("Name (Display Name - ID)")
	tagHeaderRow:AddCell():AddText("% Multiplier")

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
			tagData.DisplayName:Get() or "N/A",
			string.sub(tagData.ResourceUUID, -5)
		))

		local toolTip = tagNameCell:Tooltip()
		if tagData.Icon ~= "" then
			toolTip:AddImage(tagData.Icon, { 30, 30 })
		end
		toolTip:AddText(tagData.DisplayName:Get() or "No Display Name").SameLine = true
		toolTip:AddText("Stat UUID (Search using this): " .. tagUUID)
		toolTip:AddText("Tag UUID: " .. tagData.ResourceUUID)
		toolTip:AddText("Description: " .. (tagData.Description ~= "" and tagData.Description or "N/A"))
		toolTip:AddText("Display Description: " .. (tagData.DisplayDescription:Get() or "N/A"))

		local multiplier = row:AddCell():AddSliderInt("", charMultiplierConfig["tags"][tagUUID] * 100, 0, 500)
		multiplier.OnChange = function()
			charMultiplierConfig["tags"][tagUUID] = tonumber(string.format("%.2f", multiplier.Value[1] / 100))
		end

		row:AddCell():AddButton("Delete").OnClick = function()
			charMultiplierConfig["tags"][tagUUID] = nil
			row:Destroy()
		end
	end

	DataSearchHelper:BuildSearch(tagsHeader,
		Ext.StaticData.GetAll("Tag"),
		function(id)
			return Ext.StaticData.Get(id, "Tag").DisplayName:Get()
		end,
		function(tagUUID)
			buildTagRow(tagUUID, true)
		end)

	for tagUUID, _ in pairs(charMultiplierConfig["tags"]) do
		buildTagRow(tagUUID, false)
	end
	--#endregion
end)

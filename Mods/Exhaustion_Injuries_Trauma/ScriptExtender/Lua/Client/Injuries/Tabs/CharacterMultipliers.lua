-- #region O(fuck it)
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
end)

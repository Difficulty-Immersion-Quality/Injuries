---@type {[string] : StatusData}
local cachedStats = {}

---@param configToCount table?
---@return number
local function countInjuryConfig(configToCount)
	local count = 0

	if configToCount and next(configToCount) then
		for _, _ in pairs(configToCount) do
			count = count + 1
		end
	end

	return count
end

InjuryMenu = {}
InjuryMenu.Tabs = { ["Generators"] = {} }
InjuryMenu.ConfigurationSlice = ConfigurationStructure.config.injuries

Ext.Require("Client/Injuries/InjuryReport.lua")

function InjuryMenu:RegisterTab(tabGenerator)
	table.insert(InjuryMenu.Tabs["Generators"], tabGenerator)
end

Ext.Require("Client/Injuries/Sections/SectionBuilder.lua")
Ext.Require("Client/Injuries/Sections/ApplyingInjuries.lua")
Ext.Require("Client/Injuries/Sections/RandomApplications.lua")
Ext.Require("Client/Injuries/Sections/RemovingInjuries.lua")

Ext.Require("Client/Injuries/Tabs/DamageTab.lua")
Ext.Require("Client/Injuries/Tabs/ApplyOnStatusTab.lua")
Ext.Require("Client/Injuries/Tabs/CharacterMultipliers.lua")
Ext.Require("Client/Injuries/Tabs/RemoveOnStatusTab.lua")

local initialized = false
Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Injuries",
	--- @param tabHeader ExtuiTreeParent
	function(tabHeader)
		if initialized then
			return
		end
		initialized = true
		tabHeader.TextWrapPos = 0

		SectionBuilder:build(tabHeader, {
			ApplyingInjuriesSettings,
			RandomApplicationSettings,
			RemovingInjuriesSettings
		})

		--#region Injury-Specific Options
		tabHeader:AddSeparatorText(Translator:translate("Injury-Specific Options"))

		local reportButton = tabHeader:AddButton(Translator:translate("Open Injury Report"))
		reportButton.OnClick = function()
			InjuryReport:BuildReportWindow()
		end

		local systemGroup = tabHeader:AddGroup(Translator:translate("Systems"))

		function AddSystem(system)
			local systemHeader = systemGroup:AddCollapsingHeader(system)
			systemHeader.DefaultOpen = false

			local deleteSystemButton = systemHeader:AddButton(Translator:translate("Delete System"))
			deleteSystemButton.IDContext = system -- otherwise it won't trigger when there are multiple systems
			deleteSystemButton.OnClick = function()
				for injury, _ in pairs(InjuryMenu.ConfigurationSlice.injury_specific) do
					if string.find(string.upper(injury), "^" .. string.upper(system) .. ".*") then
						InjuryMenu.ConfigurationSlice.injury_specific[injury].delete = true
						InjuryMenu.ConfigurationSlice.injury_specific[injury] = nil
					end
				end

				local systemCopy = {}
				for _, existing_system in pairs(InjuryMenu.ConfigurationSlice.systems) do
					if existing_system ~= system then
						table.insert(systemCopy, existing_system)
					end
				end
				InjuryMenu.ConfigurationSlice.systems.delete = true
				InjuryMenu.ConfigurationSlice.systems = systemCopy
				systemHeader:Destroy()
			end

			local function buildTable(tableCategory, injuryNameTable)
				systemHeader:AddText(tableCategory).Font = "Large"
				local injuryTable = systemHeader:AddTable(system .. "_InjuryTable", 5)
				injuryTable.BordersInnerH = true
				injuryTable.SizingStretchProp = true
				injuryTable.PreciseWidths = true

				local headerRow = injuryTable:AddRow()
				headerRow.Headers = true
				headerRow:AddCell():AddText(Translator:translate("Injury"))
				headerRow:AddCell():AddText(Translator:translate("Severity"))
				headerRow:AddCell():AddText(Translator:translate("Actions"))

				for displayName, injuryName in TableUtils:OrderedPairs(injuryNameTable, function(injuryDisplayName)
					return cachedStats[injuryDisplayName].StackPriority .. injuryDisplayName
				end) do
					if not InjuryMenu.ConfigurationSlice.injury_specific[injuryName] then
						InjuryMenu.ConfigurationSlice.injury_specific[injuryName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class)
					end
					local injury_config = InjuryMenu.ConfigurationSlice.injury_specific[injuryName]

					local newRow = injuryTable:AddRow()
					local displayCell = newRow:AddCell()
					local injuryStat = Ext.Stats.Get(injuryName)
					displayCell:AddImage(injuryStat.Icon, { 36, 36 })
					local injuryNameText = displayCell:AddText(displayName)
					injuryNameText.SameLine = true

					StatusHelper:BuildStatusTooltip(displayCell:Tooltip(), injuryStat)

					local severityCombo = newRow:AddCell():AddCombo("")
					severityCombo.Options = {
						"Disabled",
						"Exclude",
						"Low",
						"Medium",
						"High",
						"Extreme"
					}
					severityCombo:Tooltip():AddText("\t " .. Translator:translate("'Exclude' will exclude this injury from being included in the randomized table - 'Disabled' will prevent this injury from being applied under any circumstances")).TextWrapPos = 600

					for index, option in pairs(severityCombo.Options) do
						if option == injury_config.severity then
							severityCombo.SelectedIndex = index - 1
							break
						end
					end

					if severityCombo.SelectedIndex == 0 then
						injuryNameText:SetStyle("Alpha", 0.5)
					else
						injuryNameText:SetStyle("Alpha", 1)
					end

					severityCombo.OnChange = function(_, selectedIndex)
						injury_config.severity = severityCombo.Options[selectedIndex + 1]
						if severityCombo.SelectedIndex == 0 then
							injuryNameText:SetStyle("Alpha", 0.5)
						else
							injuryNameText:SetStyle("Alpha", 1)
						end
					end

					local buttonCell = newRow:AddCell()
					local customizeButton = buttonCell:AddButton(Translator:translate("Customize"))

					local statCountTooltip = customizeButton:Tooltip()

					statCountTooltip.OnHoverEnter = function()
						for _, child in pairs(statCountTooltip.Children) do
							child:Destroy()
						end

						local applyOnStatusCount = countInjuryConfig(injury_config.apply_on_status["applicable_statuses"])
						local damageCount = countInjuryConfig(injury_config.damage["damage_types"])
						local removeOnStatusCount = countInjuryConfig(injury_config.remove_on_status)
						local racesCount = countInjuryConfig(injury_config.character_multipliers and injury_config.character_multipliers["races"])
						local tagsCount = countInjuryConfig(injury_config.character_multipliers and injury_config.character_multipliers["tags"])

						customizeButton.Label = string.format(Translator:translate("Customize (%s)"), applyOnStatusCount + damageCount + removeOnStatusCount + racesCount + tagsCount)

						statCountTooltip:AddNewLine()
						statCountTooltip:AddText(string.format(Translator:translate("Apply On Status: %d"), applyOnStatusCount))
						statCountTooltip:AddText(string.format(Translator:translate("Damage: %d"), damageCount))
						statCountTooltip:AddText(string.format(Translator:translate("Remove On Status: %d"), removeOnStatusCount))
						statCountTooltip:AddText(string.format(Translator:translate("Races: %d"), racesCount))
						statCountTooltip:AddText(string.format(Translator:translate("Tags: %d"), tagsCount))
					end
					statCountTooltip:OnHoverEnter()

					local injuryPopup
					customizeButton.OnClick = function()
						injuryPopup = Ext.IMGUI.NewWindow(Translator:translate("Customizing") .. " " .. displayName)
						injuryPopup.Closeable = true
						injuryPopup.OnClose = function()
							statCountTooltip:OnHoverEnter()
						end

						local newTabBar = injuryPopup:AddTabBar("InjuryTabBar")
						for _, tabGenerator in pairs(InjuryMenu.Tabs.Generators) do
							local success, error = pcall(function()
								tabGenerator(newTabBar, injuryName)
							end)

							if not success then
								Logger:BasicError("Error while generating a new tab for the Injury Table\n\t%s", error)
							end
						end
					end

					local resetButton = buttonCell:AddButton(Translator:translate("Reset"))
					resetButton.SameLine = true

					resetButton.OnClick = function()
						if injuryPopup then
							injuryPopup.Open = false
						end

						InjuryMenu.ConfigurationSlice.injury_specific[injuryName].delete = true
						InjuryMenu.ConfigurationSlice.injury_specific[injuryName] = nil
						InjuryMenu.ConfigurationSlice.injury_specific[injuryName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class)
						injury_config = InjuryMenu.ConfigurationSlice.injury_specific[injuryName]

						severityCombo.SelectedIndex = 1
						statCountTooltip:OnHoverEnter()
					end

					local copyButton = buttonCell:AddButton(Translator:translate("Copy"))
					copyButton.SameLine = true

					copyButton.OnClick = function()
						local copyPopup = Ext.IMGUI.NewWindow(Translator:translate("Copying Injury Configs"))
						copyPopup.AlwaysAutoResize = true
						copyPopup.Closeable = true

						copyPopup:AddText(Translator:translate("Copying from:") .. " " .. displayName).Font = "Large"
						copyPopup:AddText(Translator:translate("Close any Customizing windows you have open - they'll show stale data after this runs")).TextWrapPos = 0
						copyPopup:AddNewLine()

						copyPopup:AddSeparatorText(Translator:translate("Which Configs Should Be Copied?"))
						local copyWhatGroup = copyPopup:AddGroup("CopyWhat")
						copyWhatGroup:AddCheckbox(Translator:translate("ApplyOnStatus"), true).UserData = "apply_on_status"

						local dmg = copyWhatGroup:AddCheckbox(Translator:translate("Damage"), true)
						dmg.SameLine = true
						dmg.UserData = "damage"

						local charMultipliers = copyWhatGroup:AddCheckbox(Translator:translate("Character Multipliers"), true)
						charMultipliers.SameLine = true
						charMultipliers.UserData = "character_multipliers"

						local removeStatus = copyWhatGroup:AddCheckbox(Translator:translate("RemoveOnStatus"), true)
						removeStatus.SameLine = true
						removeStatus.UserData = "remove_on_status"

						copyPopup:AddNewLine()
						copyPopup:AddSeparatorText(Translator:translate("What Injuries should these configs be copied to?"))
						local copyToGroup = copyPopup:AddGroup("CopyTo")
						copyPopup:AddButton(Translator:translate("Select All")).OnClick = function()
							for _, child in pairs(copyToGroup.Children) do
								child.Checked = true
							end
						end

						for otherDisplayName, stat in TableUtils:OrderedPairs(cachedStats) do
							if displayName ~= otherDisplayName then
								copyToGroup:AddCheckbox(otherDisplayName, false).UserData = stat.Name
							end
						end

						copyPopup:AddButton(Translator:translate("Copy Configs")).OnClick = function()
							local configsToCopy = {}
							for _, child in pairs(copyWhatGroup.Children) do
								---@cast child ExtuiCheckbox
								if child.Checked then
									table.insert(configsToCopy, child.UserData)
								end
							end

							-- Since we use Metatable proxies in ConfigStructure and TableUtils doesn't use pairs, we have to operate on the real table
							local configCopy = ConfigurationStructure:GetRealConfigCopy().injuries.injury_specific[injuryName]
							for _, child in pairs(copyToGroup.Children) do
								---@cast child ExtuiCheckbox
								if child.Checked then
									local otherInjuryName = child.UserData
									for _, configToCopy in pairs(configsToCopy) do
										if InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName] and InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName][configToCopy] then
											InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName][configToCopy].delete = true
										end
										InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName][configToCopy] = TableUtils:DeeplyCopyTable(configCopy[configToCopy])
									end
								end
							end

							copyPopup.Open = false
						end
					end
				end
			end

			local miscInjuriesDisplayMap = {}
			local stackedInjuriesDisplayMap = {}
			for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
				if string.find(string.upper(name), "^" .. string.upper(system) .. ".*") then
					local displayName = string.sub(name, string.len(system) + 1)
					displayName = string.gsub(displayName, "_", " ")

					---@type StatusData
					local injuryStat = Ext.Stats.Get(name)
					displayName = Ext.Loca.GetTranslatedString(injuryStat.DisplayName, displayName)

					cachedStats[displayName] = injuryStat

					if injuryStat.StackId == "" then
						miscInjuriesDisplayMap[displayName] = name
					else
						stackedInjuriesDisplayMap[injuryStat.StackId] = stackedInjuriesDisplayMap[injuryStat.StackId] or {}
						stackedInjuriesDisplayMap[injuryStat.StackId][displayName] = name
					end
				end
			end

			for stackId, nameMap in TableUtils:OrderedPairs(stackedInjuriesDisplayMap) do
				if TableUtils:CountEntries(nameMap) == 1 then
					local key = next(nameMap)
					miscInjuriesDisplayMap[key] = nameMap[key]
					stackedInjuriesDisplayMap[stackId] = nil
				end
			end

			buildTable(Translator:translate("Miscellaneous"), miscInjuriesDisplayMap)
			for stackId, nameMap in TableUtils:OrderedPairs(stackedInjuriesDisplayMap) do
				buildTable(Translator:translate("Stack:") .. " " .. stackId, nameMap)
			end
		end

		--#region Systems
		for _, system in ipairs(InjuryMenu.ConfigurationSlice.systems) do
			AddSystem(system)
		end

		tabHeader:AddSeparatorText(Translator:translate("Register a New Injury System"))
		tabHeader:AddText(Translator:translate("Enter the prefix used in all Stats belonging to a single system (e.g. Goon_Injury_Homebrew or Goon_Injury_Grit_And_Glory) to create a new section dedicated to the system." ..
			" All Stats belonging to the registered system(s) will automatically be known and used by this mod - if you want to exclude a system from processing, you must delete it - configurations will not be saved")).TextWrapPos = 0

		local systemInput = tabHeader:AddInputText("")
		systemInput.Hint = Translator:translate("Case-insensitive - only specify the prefix (e.g. Goon_Injury_Homebrew)")
		systemInput.AutoSelectAll = true
		systemInput.EscapeClearsAll = true

		local search = tabHeader:AddButton(Translator:translate("Search"))

		search.OnClick = function()
			if #systemInput.Text > 0 then
				table.insert(InjuryMenu.ConfigurationSlice.systems, systemInput.Text)
				AddSystem(systemInput.Text)
			end
		end
		--#endregion

		--#endregion
	end
)

Translator:RegisterTranslation({
	["Injury-Specific Options"] = "hc273eb7f41304b7a9e3a4f783cf28b7470c2",
	["Open Injury Report"] = "hd04225c38388437caa4670faf1b5cbea2bb7",
	["Systems"] = "h8c9bbb728c8f407aaa7a886ae05ff4e8cc9b",
	["Delete System"] = "h5d5066b88cda46c1bb91129a1d80777c67d5",
	["Injury"] = "h2b3b5b26e1c44dd495acba638cd593500718",
	["Severity"] = "h7231e1d605ce400ea608fb8d4079e8f493bg",
	["'Exclude' will exclude this injury from being included in the randomized table - 'Disabled' will prevent this injury from being applied under any circumstances"] = "h33e313fcb75f468dabcb7c43d76ba8f984e0",
	["Actions"] = "h6786d51c543e4530a8c2ac7847bce8dd5ce6",
	["Customize (%s)"] = "h1a8bc7c8138d427ba215ad25773655b69f2d",
	["Customize"] = "h44056242a4db4cf3a274eb9d84ef8ae6a1f8",
	["Apply On Status: %d"] = "h2fa3b2dc429e40f9934dfc1da4c9af927ac9",
	["Damage: %d"] = "h9e5903752a86420d83eb9ebfd034a4ae70ga",
	["Remove On Status: %d"] = "h417c2180e95c4b58bf778ab09e9c479d4a9d",
	["Races: %d"] = "h2a4ca5118d19495a922958a7e23b4d18e94d",
	["Tags: %d"] = "h8f02176203414eda9441035b56a5bd855100",
	["Customizing"] = "h38ca8120073446a380df1f13774a09496ab7",
	["Reset"] = "h28fd5e874c854e1c89f87b6a9f526f592ac1",
	["Copy"] = "h75fc356630954ffb866066e2ba5403a3bd02",
	["Copying Injury Configs"] = "he6ca7f6689b442d6b0c69c76701a3acaf37a",
	["Copying from:"] = "h5562bfc3427d49188b12c54e1de1b6877dcd",
	["Close any Customizing windows you have open - they'll show stale data after this runs"] = "h74cf05e59dec40a5bbe71883c53ea77bfd2c",
	["Which Configs Should Be Copied?"] = "h646529ff207d4d87b9ac0ab39eaa076dbd57",
	["ApplyOnStatus"] = "h6dbf73a197664327ada890532dfd9447772a",
	["Damage"] = "hfefd65a4e38b4ccc82cc292e9c3d00615196",
	["Character Multipliers"] = "hec1a8f64e2ee4bba9d7b9d44fa3cf465d715",
	["RemoveOnStatus"] = "h88cc1ca7ae4445b8aea54a5e89c545250dge",
	["What Injuries should these configs be copied to?"] = "hadacfbcc416e4f6eb4c2ea363d4d9ee0056d",
	["Select All"] = "h770262b9d00147e9ac492a8212b58156ge25",
	["Copy Configs"] = "h0f39712a0c144d05878d26a28b85c2c20c03",
	["Search"] = "h82b51d5ccffd4a6b8749867ec3896b803dc8",
	["Miscellaneous"] = "hb9e2a626d6c146a4976bc1241023dda8b7b6",
	["Stack:"] = "hb484765355a94e1e8dce9a1061e33de4ge73",
	["Case-insensitive - only specify the prefix (e.g. Goon_Injury_Homebrew)"] = "h876d8a018fd6472ba406fcd48ab7761e686c",
	["Register a New Injury System"] = "h3fcbb7dcbecd4a57a613931a57720e952ca7",
	["Enter the prefix used in all Stats belonging to a single system (e.g. Goon_Injury_Homebrew or Goon_Injury_Grit_And_Glory) to create a new section dedicated to the system." ..
	" All Stats belonging to the registered system(s) will automatically be known and used by this mod - if you want to exclude a system from processing, you must delete it - configurations will not be saved"] =
	"h4ad9acd0b0d2422184871ede9022f0b31c22",
})

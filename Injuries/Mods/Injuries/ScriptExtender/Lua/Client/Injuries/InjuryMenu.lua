InjuryMenu = {
	---@type {[string] : {[string]: string}}
	systemsAndInjuries = {},
	severities = {
		"Exclude",
		"Low",
		"Medium",
		"High",
		"Extreme",
		"Disabled",
		["Exclude"] = 1,
		["Low"] = 2,
		["Medium"] = 3,
		["High"] = 4,
		["Extreme"] = 5,
		["Disabled"] = 6
	}
}
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

		InjuryMenu.popup = tabHeader:AddPopup("injuries")
		InjuryMenu.popup:SetColor("PopupBg", { 0, 0, 0, 1 })
		InjuryMenu.popup:SetColor("Border", { 1, 0, 0, 0.5 })


		local helpTextButton = tabHeader:AddButton(Translator:translate("Toggle Help Text"))
		local helpTextGroup = tabHeader:AddGroup("helpText")
		helpTextGroup.TextWrapPos = 0
		helpTextGroup.Visible = false
		helpTextGroup:AddText("\t - " .. Translator:translate("All injury and status names in all windows except the injury report have tooltips associated to them - hover over their names to see them. Tooltips in other areas are marked by (?)")).TextWrapPos = 0
		helpTextGroup:AddText("\t - " .. Translator:translate("Sliders can have values manually entered by ctrl + left clicking on them")).TextWrapPos = 0
		helpTextGroup:AddText("\t - " .. Translator:translate("Table columns within the Customize windows can be manually resized by left clicking and dragging on the vertical lines between columns")).TextWrapPos = 0
		local usersHelpText = helpTextGroup:AddSeparatorText(Translator:translate("For Players"))
		usersHelpText.Font = "Large"
		usersHelpText:SetStyle("SeparatorTextAlign", 0)
		helpTextGroup:AddText(Translator:translate("Customizing a provided configuration is largely intended to be an iterative process while playing the game, starting by using the Injury Report (button is further below, default MCM keybind is LSHIFT + LALT + R) to see what injuries are being processed per character and how the modifiers are affecting that processing (as it can vary wildly between characters)")).TextWrapPos = 0
		helpTextGroup:AddText(Translator:translate("Then:")).TextWrapPos = 0
		helpTextGroup:AddText("\t - " .. Translator:translate("If you want to adjust general aspects like application chance, how healing affects damage, removing all injuries on long rest, etc, use the settings section below.")).TextWrapPos = 0
		helpTextGroup:AddText("\t - " .. Translator:translate("If you want to adjust injury-specific settings like which damage types are used, the multipliers for races/tags, granular removal conditions, etc, locate the relevant injury in the section further below and open the window via the customize button")).TextWrapPos = 0
		helpTextGroup:AddText("\t - " .. Translator:translate("If you want to prevent an injury from being processed at all, change the severity to 'Disabled' within the Injury-specific section")).TextWrapPos = 0
		helpTextGroup:AddText(Translator:translate("Any changes to configs affecting a given injury will not be reflected in the Injury Report until that injury is re-processed under the relevant scenario (i.e. changing a damage threshold requires taking the right kind of damage for it to be updated)")).TextWrapPos = 0

		helpTextGroup:AddNewLine()
		local moddersHelpText = helpTextGroup:AddSeparatorText(Translator:translate("For Creators"))
		moddersHelpText.Font = "Large"
		moddersHelpText:SetStyle("SeparatorTextAlign", 0)
		helpTextGroup:AddText(Translator:translate("Check the Github (linked on the mod page) to see the underlying implementation for the Grit and Glory / Madness / Exhaustion system - there's a lot of templates that can be used to help in developing your own system, either directly or as reference")).TextWrapPos = 0
		helpTextGroup:AddText(Translator:translate("While developing, if you need to clear statuses that no longer exist from the config, you can enter client mode in the SE console (using the 'client' command) and run !Injuries_CleanConfig - this will remove configs for injuries that don't exist in the game, along with other non-destructive clean up operations")).TextWrapPos = 0

		helpTextButton.OnClick = function()
			helpTextGroup.Visible = not helpTextGroup.Visible
		end

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

		InjuryMenu:buildSystemSection(tabHeader)

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
				InjuryMenu.ConfigurationSlice = InjuryMenu.ConfigurationSlice or {}
				InjuryMenu.ConfigurationSlice.systems = InjuryMenu.ConfigurationSlice.systems or {}
				table.insert(InjuryMenu.ConfigurationSlice.systems, systemInput.Text)
				AddSystem(systemInput.Text)
			end
		end
		--#endregion

		--#endregion
	end
)

---@param parent ExtuiTreeParent
function InjuryMenu:buildSystemSection(parent)
	local settings = ConfigurationStructure.config.injuries.settings

	local coloursGroup = parent:AddGroup("colours")

	local sidebarTableRow = Styler:TwoColumnTable(parent, "systems"):AddRow()
	local sidebarCell = sidebarTableRow:AddCell()

	local customizationCell = sidebarTableRow:AddCell():AddChildWindow("customizer")

	local systemDropdown = sidebarCell:AddCombo("")
	systemDropdown.UserData = "keep"
	systemDropdown.WidthFitPreview = true
	local opts = {}
	if ConfigurationStructure.config.injuries.systems then
		for _, systemName in TableUtils:OrderedPairs(ConfigurationStructure.config.injuries.systems) do
			if not self.systemsAndInjuries[systemName] then
				self.systemsAndInjuries[systemName] = {}
				for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
					if string.find(string.upper(name), "^" .. string.upper(systemName) .. ".*") then
						local displayName = string.sub(name, string.len(systemName) + 1)
						displayName = string.gsub(displayName, "_", " ")
						---@type StatusData
						local injuryStat = Ext.Stats.Get(name)
						self.systemsAndInjuries[systemName][name] = Ext.Loca.GetTranslatedString(injuryStat.DisplayName, displayName)
					end
				end
			end
			table.insert(opts, systemName)
		end
	end
	systemDropdown.Options = opts
	systemDropdown.SelectedIndex = 0

	systemDropdown.OnChange = function()
		local activeSystem = systemDropdown.Options[systemDropdown.SelectedIndex + 1]

		Helpers:KillChildren(sidebarCell)
		local systemGroup = sidebarCell:AddChildWindow("sidebar")

		---@type {[string]: string}
		local miscInjuriesDisplayMap = {}

		---@type {[string] : {[string]: string}}
		local stackedInjuriesDisplayMap = {}

		for statName, displayName in pairs(self.systemsAndInjuries[activeSystem]) do
			---@type StatusData
			local injuryStat = Ext.Stats.Get(statName)
			if injuryStat.StackId == "" then
				miscInjuriesDisplayMap[displayName] = statName
			else
				stackedInjuriesDisplayMap[injuryStat.StackId] = stackedInjuriesDisplayMap[injuryStat.StackId] or {}
				stackedInjuriesDisplayMap[injuryStat.StackId][displayName] = statName
			end
		end

		for stackId, nameMap in TableUtils:OrderedPairs(stackedInjuriesDisplayMap) do
			if TableUtils:CountElements(nameMap) == 1 then
				local key = next(nameMap)
				miscInjuriesDisplayMap[key] = nameMap[key]
				stackedInjuriesDisplayMap[stackId] = nil
			end
		end

		self:BuildSystemSelects(systemGroup, miscInjuriesDisplayMap, customizationCell)

		for stackId, nameMap in TableUtils:OrderedPairs(stackedInjuriesDisplayMap) do
			local sep = systemGroup:AddSeparatorText(stackId)
			sep.Font = "Small"
			sep:SetColor("Text", { 1, 1, 1, 0.55 })
			self:BuildSystemSelects(systemGroup, nameMap, customizationCell)
		end
	end
	systemDropdown:OnChange()

	local count = 0
	for severity, colour in TableUtils:OrderedPairs(settings.severityColours,
		function(key, value)
			return self.severities[key]
		end)
	do
		count = count + 1

		local colourEdit = coloursGroup:AddColorEdit(Translator:translate(severity) .. "##" .. severity)
		colourEdit.AlphaBar = true
		colourEdit.Color = colour._real
		colourEdit.NoInputs = true
		colourEdit.SameLine = count > 1 and ((count - 1) % 3 ~= 0)
		colourEdit.OnChange = function()
			settings.severityColours[severity].delete = true
			settings.severityColours[severity] = colourEdit.Color

			systemDropdown:OnChange()
		end
	end
end

---@param parent ExtuiTreeParent
---@param injuryMap {[string] : string}
---@param customizationCell ExtuiChildWindow
function InjuryMenu:BuildSystemSelects(parent, injuryMap, customizationCell)
	local settings = ConfigurationStructure.config.injuries.settings._real
	for displayName, statName in TableUtils:OrderedPairs(injuryMap, function(key, value)
		local severity = ConfigurationStructure.config.injuries.injury_specific[value].severity
		return tostring(self.severities[severity]) .. value
	end) do
		local injury = ConfigurationStructure.config.injuries.injury_specific[statName]

		---@type ExtuiSelectable
		local select = parent:AddSelectable(displayName)
		select:SetColor("Text", Styler:ConvertRGBAToIMGUI(settings.severityColours[injury.severity]))
		select:SetColor("HeaderHovered", Styler:ConvertRGBAToIMGUI({ 1, 1, 1, 0.1 }))
		select.OnClick = function()
			select.Selected = false
			Helpers:KillChildren(customizationCell)
			customizationCell:SetScroll({ 0, 0 })
			Styler:CheapTextAlign(displayName, customizationCell, "Large")
			local newTabBar = customizationCell:AddTabBar("InjuryTabBar")
			for _, tabGenerator in pairs(InjuryMenu.Tabs.Generators) do
				local success, error = xpcall(function()
					tabGenerator(newTabBar, statName)
				end, debug.traceback)

				if not success then
					Logger:BasicError("Error while generating a new tab for the Injury Table\n\t%s", error)
				end
			end
		end

		select.OnRightClick = function()
			Helpers:KillChildren(self.popup)
			self.popup:Open()

			self.popup:AddSelectable(Translator:translate("Open In New Window")).OnClick = function()
				local injuryPopup = Ext.IMGUI.NewWindow(Translator:translate("Customizing") .. " " .. displayName)
				injuryPopup:SetSizeConstraints(Styler:ScaleFactor({200, 200}))
				injuryPopup.Closeable = true

				local newTabBar = injuryPopup:AddTabBar("InjuryTabBar")
				for _, tabGenerator in pairs(InjuryMenu.Tabs.Generators) do
					local success, error = xpcall(function()
						tabGenerator(newTabBar, statName)
					end, debug.traceback)

					if not success then
						Logger:BasicError("Error while generating a new tab for the Injury Table\n\t%s", error)
					end
				end
			end

			---@type ExtuiMenu
			local severityMenu = self.popup:AddMenu(Translator:translate("Change Severity"))
			local function buildSeverityMenu()
				Helpers:KillChildren(severityMenu)
				for _, severityOpt in ipairs(self.severities) do
					if severityOpt ~= injury.severity then
						local item = severityMenu:AddItem(Translator:translate(severityOpt))
						item.AutoClosePopups = false
						item:SetColor("Text", Styler:ConvertRGBAToIMGUI(settings.severityColours[severityOpt]))

						item.OnClick = function()
							injury.severity = severityOpt
							select:SetColor("Text", Styler:ConvertRGBAToIMGUI(settings.severityColours[severityOpt]))
							buildSeverityMenu()
						end
					end
				end
			end
			buildSeverityMenu()

			self.popup:AddSelectable(Translator:translate("Copy"), "DontClosePopups").OnClick = function(copySel)
				copySel.Selected = false
				self:CopyInjuryConfig(statName)
			end

			self.popup:AddSelectable(Translator:translate("Reset"), "DontClosePopups").OnClick = function(resetSelect)
				select.Selected = false
				InjuryMenu.ConfigurationSlice.injury_specific[statName].delete = true
				InjuryMenu.ConfigurationSlice.injury_specific[statName] = TableUtils:DeeplyCopyTable(ConfigurationStructure.DynamicClassDefinitions.injury_class)
				select:OnClick()
			end
		end
	end
end

function InjuryMenu:CopyInjuryConfig(injuiryToCopyFrom)
	Helpers:KillChildren(self.popup)

	local systemForInjury = TableUtils:IndexOf(self.systemsAndInjuries, function(value)
		return value[injuiryToCopyFrom] ~= nil
	end)

	Styler:CheapTextAlign(Translator:translate("Copying from:") .. " " .. self.systemsAndInjuries[systemForInjury][injuiryToCopyFrom], self.popup, "Large")

	Styler:CheapTextAlign(Translator:translate("Close any Customizing windows you have open - they'll show stale data after this runs"), self.popup)
	self.popup:AddNewLine()

	self.popup:AddSeparatorText(Translator:translate("Which Configs Should Be Copied?"))
	local copyWhatGroup
	Styler:MiddleAlignedColumnLayout(self.popup, function(ele)
		copyWhatGroup = ele:AddGroup("CopyWhat")
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
	end)

	self.popup:AddNewLine()
	self.popup:AddSeparatorText(Translator:translate("What Injuries should these configs be copied to?"))

	local trackerMap = {}

	Styler:MiddleAlignedColumnLayout(self.popup, function(ele)
		ele:AddButton(Translator:translate("Copy Configs")).OnClick = function()
			local configsToCopy = {}
			for _, child in pairs(copyWhatGroup.Children) do
				---@cast child ExtuiCheckbox
				if child.Checked then
					table.insert(configsToCopy, child.UserData)
				end
			end

			-- Since we use Metatable proxies in ConfigStructure and TableUtils doesn't use pairs, we have to operate on the real table
			local configCopy = ConfigurationStructure:GetRealConfigCopy().injuries.injury_specific[injuiryToCopyFrom]
			for otherInjuryName in pairs(trackerMap) do
				for _, configToCopy in pairs(configsToCopy) do
					if InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName] and InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName][configToCopy] then
						InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName][configToCopy].delete = true
					end
					InjuryMenu.ConfigurationSlice.injury_specific[otherInjuryName][configToCopy] = TableUtils:DeeplyCopyTable(configCopy[configToCopy])
				end
			end
		end
	end)

	local sameLine = false
	for system, injuryMap in TableUtils:OrderedPairs(self.systemsAndInjuries) do
		local win = self.popup:AddChildWindow(system)
		win.NoSavedSettings = true
		win.Size = Styler:ScaleFactor { 500, 600 }
		win.SameLine = sameLine
		sameLine = true

		win:AddSeparatorText(system)
		local selectAllButton = win:AddButton(Translator:translate("Select All") .. "##" .. system)

		local secondWin = win:AddChildWindow("second")
		secondWin.NoSavedSettings = true
		secondWin:SetScroll({ 0, 0 })

		selectAllButton.OnClick = function()
			for _, child in pairs(secondWin.Children) do
				if child.UserData then
					child.Checked = true
					trackerMap[child.UserData] = true
				end
			end
		end

		for statName, displayName in TableUtils:OrderedPairs(injuryMap, function(key, value)
			return tostring(self.severities[ConfigurationStructure.config.injuries.injury_specific[key].severity]) .. value
		end) do
			if statName ~= injuiryToCopyFrom then
				local severity = ConfigurationStructure.config.injuries.injury_specific[statName].severity
				local box = secondWin:AddCheckbox(displayName)
				box.UserData = statName
				box:SetColor("Text", Styler:ConvertRGBAToIMGUI(ConfigurationStructure.config.injuries.settings.severityColours[severity]._real))
				box.OnChange = function()
					trackerMap[statName] = trackerMap[statName] and nil or true
				end
			end
		end
	end
end

Translator:RegisterTranslation({
	["Toggle Help Text"] = "he1662ef5633243af808c395d3550dfc4833g",
	["All injury and status names in all windows except the injury report have tooltips associated to them - hover over their names to see them. Tooltips in other areas are marked by (?)"] =
	"hfb7e22414b544bf5820ac50d99addb9408b5",
	["Sliders can have values manually entered by ctrl + left clicking on them"] = "h31f607652dd64e52acfa0fd748fdf5ab33g9",
	["Table columns within the Customize windows can be manually resized by left clicking and dragging on the vertical lines between columns"] =
	"h65fc2263758341e9b115d235f2ac2a2ddbe3",
	["For Players"] = "h6ff2f32c256a4d0d825532383de50ee03561",
	["Customizing a provided configuration is largely intended to be an iterative process while playing the game, starting by using the Injury Report (button is further below, default MCM keybind is LSHIFT + LALT + R) to see what injuries are being processed per character and how the modifiers are affecting that processing (as it can vary wildly between characters)"] =
	"h296f5564e2d1461699a144b6122ed5beefdb",
	["Then:"] = "hca642f1f841948a7a30b387bf83a08914f9f",
	["If you want to adjust general aspects like application chance, how healing affects damage, removing all injuries on long rest, etc, use the settings section below."] =
	"hf0325eecf78a433c9e07ca5b4bb58879a065",
	["If you want to adjust injury-specific settings like which damage types are used, the multipliers for races/tags, granular removal conditions, etc, locate the relevant injury in the section further below and open the window via the customize button"] =
	"ha5d5109cd75c4e86af1206bca2fc2dfb82g8",
	["If you want to prevent an injury from being processed at all, change the severity to 'Disabled' within the Injury-specific section"] = "h756d78fba731439d88de3a6e8e7d4b4b5f84",
	["Any changes to configs affecting a given injury will not be reflected in the Injury Report until that injury is re-processed under the relevant scenario (i.e. changing a damage threshold requires taking the right kind of damage for it to be updated)"] =
	"h7b61fd3af2204b989f1cfbb68bbe3bf41916",
	["For Creators"] = "hf5e54a92558944d5b7e7bae84114913e99f5",
	["Check the Github (linked on the mod page) to see the underlying implementation for the Grit and Glory / Madness / Exhaustion system - there's a lot of templates that can be used to help in developing your own system, either directly or as reference"] =
	"hb291dc8fd9d143fc829762905c5746464g4c",
	["While developing, if you need to clear statuses that no longer exist from the config, you can enter client mode in the SE console (using the 'client' command) and run !Injuries_CleanConfig - this will remove configs for injuries that don't exist in the game, along with other non-destructive clean up operations"] =
	"h7f417e48ae86435aaabb6feba172d276a364",
	["Injury-Specific Options"] = "hc273eb7f41304b7a9e3a4f783cf28b7470c2",
	["Open Injury Report"] = "hd04225c38388437caa4670faf1b5cbea2bb7",
	["Systems"] = "h8c9bbb728c8f407aaa7a886ae05ff4e8cc9b",
	["Delete System"] = "h5d5066b88cda46c1bb91129a1d80777c67d5",
	["Injury"] = "h2b3b5b26e1c44dd495acba638cd593500718",
	["Severity"] = "h7231e1d605ce400ea608fb8d4079e8f493bg",
	["Change Severity"] = "he1097f5fbb4c4ff5b616166dc6514d71161b",
	["'Exclude' will exclude this injury from being included in the randomized table - 'Disabled' will prevent this injury from being applied under any circumstances"] =
	"h33e313fcb75f468dabcb7c43d76ba8f984e0",
	["Actions"] = "h6786d51c543e4530a8c2ac7847bce8dd5ce6",
	["Customize (%s)"] = "h1a8bc7c8138d427ba215ad25773655b69f2d",
	["Open In New Window"] = "h44056242a4db4cf3a274eb9d84ef8ae6a1f8",
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

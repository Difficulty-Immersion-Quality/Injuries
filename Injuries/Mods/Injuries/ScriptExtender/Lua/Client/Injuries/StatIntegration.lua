StatIntegration = {
	config = ConfigurationStructure.config.injuries.statIntegration,
	---@enum GameLevel
	levels = {
		[1] = "TUT_Avernus_C", -- nautiloid
		[2] = "WLD_Main_A", -- beach, grove, goblin camp, underdark
		[3] = "CRE_Main_A", -- mountain pass, creche
		[4] = "SCL_Main_A", -- shadow cursed lands
		[5] = "INT_Main_A", -- camp before baldur's gate
		[6] = "BGO_Main_A", -- rivington, wyrm's crossing
		[7] = "CTY_Main_A", -- lower city, sewers
		[8] = "IRN_Main_A", -- iron throne
		[9] = "END_Main", -- morphic pool
		TUT_Avernus_C = 1,
		WLD_Main_A = 2,
		CRE_Main_A = 3,
		SCL_Main_A = 4,
		INT_Main_A = 5,
		BGO_Main_A = 6,
		CTY_Main_A = 7,
		IRN_Main_A = 8,
		END_Main = 9,
	}
}

---@param parent ExtuiTreeParent
function StatIntegration:buildUI(parent)
	local popup = parent:AddPopup("stats")

	parent:AddSeparatorText("Supplementary Behavior via Integrations")

	local integrationTable = Styler:TwoColumnTable(parent):AddRow()

	local statsConfiguredCell = integrationTable:AddCell()
	local statsConfiguredWindow = statsConfiguredCell:AddChildWindow("configuredWindow")
	
	local configurationCell = integrationTable:AddCell():AddChildWindow("integrationConfigCell")

	local function renderConfigured()
		Helpers:KillChildren(statsConfiguredWindow)
		statsConfiguredWindow:AddSeparatorText("Game Levels")
		for level, levelConfig in TableUtils:OrderedPairs(self.config.levels) do
			local select = statsConfiguredWindow:AddSelectable(level)
			select.OnClick = function()
				self:renderConfigurations(configurationCell, levelConfig, true)
			end
		end

		statsConfiguredWindow:AddSeparatorText("Statuses")
		for statusName, statusConfig in TableUtils:OrderedPairs(self.config.statuses) do
			---@type StatusData
			local status = Ext.Stats.Get(statusName)
			local statusImageButton = statsConfiguredWindow:AddImage(status.Icon ~= "" and status.Icon or "Item_Unknown", Styler:ScaleFactor({ 24, 24 }))
			if statusImageButton.ImageData.Icon == "" then
				statusImageButton:Destroy()
				statusImageButton = statsConfiguredWindow:AddImage("Item_Unknown", Styler:ScaleFactor({ 24, 24 }))
			end

			local displayName = Ext.Loca.GetTranslatedString(status.DisplayName, statusName)
			displayName = displayName:upper() == "%%% EMPTY" and statusName or displayName
			local select = statsConfiguredWindow:AddSelectable(displayName .. "##" .. statusName)
			select.SameLine = true
			select.OnClick = function()
				self:renderConfigurations(configurationCell, statusConfig)
			end
		end

		statsConfiguredWindow:AddSeparatorText("Passives")
		for passiveName, passiveConfig in TableUtils:OrderedPairs(self.config.passives) do
			---@type PassiveData
			local passive = Ext.Stats.Get(passiveName)
			local passiveImageButton = statsConfiguredWindow:AddImage(passive.Icon ~= "" and passive.Icon or "Item_Unknown",
				Styler:ScaleFactor({ 24, 24 }))

			if passiveImageButton.ImageData.Icon == "" then
				passiveImageButton:Destroy()
				passiveImageButton = statsConfiguredWindow:AddImage("Item_Unknown", Styler:ScaleFactor({ 24, 24 }))
			end

			local displayName = Ext.Loca.GetTranslatedString(passive.DisplayName, passiveName)
			displayName = displayName:upper() == "%%% EMPTY" and passiveName or displayName
			local select = statsConfiguredWindow:AddSelectable(displayName)
			select.SameLine = true
			select.OnClick = function()
				self:renderConfigurations(configurationCell, passiveConfig)
			end
		end
	end
	renderConfigured()

	local addButton = statsConfiguredCell:AddButton("Add Stat/Level")
	addButton.OnClick = function()
		Helpers:KillChildren(popup)
		popup:Open()

		---@type ExtuiMenu
		local levelMenu = popup:AddMenu("Add Game Level")
		for _, level in ipairs(self.levels) do
			if not self.config.levels[level] then
				local addLevel = levelMenu:AddItem(level)
				addLevel.AutoClosePopups = false

				addLevel.OnClick = function()
					self.config.levels[level] = {}
					addLevel:Destroy()
				end
			end
		end

		---@type ExtuiMenu
		local statusMenu = popup:AddMenu("Add Status")
		StatBrowser:Render("StatusData",
			statusMenu,
			nil,
			function(pos)
				return pos % 7 ~= 0
			end,
			function(statusName)
				return self.config.statuses[statusName] ~= nil
			end,
			nil,
			function(_, statusName)
				if self.config.statuses[statusName] then
					self.config.statuses[statusName].delete = true
				else
					self.config.statuses[statusName] = {}
				end

				renderConfigured()
			end)

		---@type ExtuiMenu
		local passiveMenu = popup:AddMenu("Add Passive")
		StatBrowser:Render("PassiveData",
			passiveMenu,
			nil,
			function(pos)
				return pos % 7 ~= 0
			end,
			function(passiveName)
				return self.config.passives[passiveName] ~= nil
			end,
			nil,
			function(_, passiveName)
				if self.config.passives[passiveName] then
					self.config.passives[passiveName].delete = true
				else
					self.config.passives[passiveName] = {}
				end

				renderConfigured()
			end)
	end
end

---@param parent ExtuiTreeParent
---@param config IntegrationConfig
---@param isLevel boolean?
function StatIntegration:renderConfigurations(parent, config, isLevel)
	parent:AddText("Hello?")
end

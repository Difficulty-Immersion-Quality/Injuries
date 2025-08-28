StatBrowser = {}

---@param statType string
---@param parent ExtuiWindowBase
---@param supplementaryResultProcessor fun(parent: ExtuiTreeParent, results: string[])?
---@param wrapFunc fun(pos: number): boolean?
---@param shouldTint fun(statusName: string): boolean?
---@param customizer fun(statusImage: ExtuiImageButton, statusName: string)?
---@param onClickCallback fun(statusImage: ExtuiImageButton, statusName: string)
function StatBrowser:Render(statType, parent, supplementaryResultProcessor, wrapFunc, shouldTint, customizer, onClickCallback)
	local settings = ConfigurationStructure.config.injuries.settings.statBrowser

	local input = parent:AddInputText("")
	input.ItemWidth = (53 * Styler:ScaleFactor()) * 7
	input.Hint = "Min 3 Characters"

	local helpText = parent:AddText("( ? )")
	helpText.SameLine = true
	helpText:Tooltip():AddText([[
	See detailed tooltips on spell images by holding shift -
click outside of the text input first, as the modifier won't be registered while the input is accepting keystrokes.
You can shift-click on images to pop out their tooltip into a new window, but that will close the search popup]])

	local settingsPopup = parent:AddPopup("settings")
	local settingsButton = Styler:ImageButton(parent:AddImageButton("settings", "ico_edit_d", { 32, 32 }))
	settingsButton.SameLine = true

	local resultsGroup = parent:AddChildWindow("results")

	settingsButton.OnClick = function()
		Helpers:KillChildren(settingsPopup)
		settingsPopup:Open()

		---@param checkbox ExtuiCheckbox
		settingsPopup:AddCheckbox("Only Display Icons (With Tooltips)?", settings.onlyIcons).OnChange = function(checkbox)
			settings.onlyIcons = checkbox.Checked
			input:OnChange(input, input.Text)
		end

		settingsPopup:AddText("Sort ")
		local sortKey = settingsPopup:AddCombo("")
		sortKey.SameLine = true
		sortKey.WidthFitPreview = true
		sortKey.Options = { "DisplayName", "Name" }
		sortKey.SelectedIndex = settings.sort.name == "spellName" and 1 or 0
		sortKey.OnChange = function()
			settings.sort.name = sortKey.SelectedIndex == 1 and "spellName" or "displayName"
			input:OnChange(input, input.Text)
		end

		local directionKey = settingsPopup:AddCombo("")
		directionKey.SameLine = true
		directionKey.WidthFitPreview = true
		directionKey.Options = { "Descending", "Ascending" }
		directionKey.SelectedIndex = settings.sort.direction == "Ascending" and 1 or 0
		directionKey.OnChange = function()
			settings.sort.direction = directionKey.SelectedIndex == 1 and "Ascending" or "Descending"
			input:OnChange(input, input.Text)
		end
	end

	resultsGroup.NoSavedSettings = true
	resultsGroup.Size = { 0, 300 * Styler:ScaleFactor() }
	local timer
	input.OnChange = function()
		if timer then
			Ext.Timer.Cancel(timer)
		end

		Helpers:KillChildren(resultsGroup)
		if #input.Text >= 3 then
			timer = Ext.Timer.WaitFor(300, function()
				local value = input.Text:upper()
				local results = {}
				for _, spellName in pairs(Ext.Stats.GetStats(statType)) do
					---@type SpellData|PassiveData|StatusData
					local stat = Ext.Stats.Get(spellName)
					if stat.ModifierList ~= "SpellData" or stat.RootSpellID == "" then
						if spellName:upper():find(value) then
							table.insert(results, spellName)
						else
							if stat.DisplayName and Ext.Loca.GetTranslatedString(stat.DisplayName, stat.Name):find(value) then
								table.insert(results, spellName)
							end
						end
					end
				end
				if #results > 0 then
					if supplementaryResultProcessor then
						supplementaryResultProcessor(resultsGroup, results)
					end

					local rowCounter = 0

					local resultsParent = resultsGroup
					if not settings.onlyIcons then
						---@cast resultsParent ExtuiTable
						resultsParent = resultsGroup:AddTable("results", 3)
						resultsParent.NoSavedSettings = true

						resultsParent:AddColumn("", "WidthFixed")
						resultsParent:AddColumn("", "WidthFixed")
						resultsParent:AddColumn("", "WidthFixed")

						local headers = resultsParent:AddRow()
						headers.Headers = true
						headers:AddCell()
						headers:AddCell():AddText("Name")
						headers:AddCell():AddText("Display Name")
					end

					table.sort(results, function(a, b)
						local a = settings.sort.name == "displayName" and Ext.Loca.GetTranslatedString(Ext.Stats.Get(a).DisplayName, a) or a
						local b = settings.sort.name == "displayName" and Ext.Loca.GetTranslatedString(Ext.Stats.Get(b).DisplayName, b) or b
						if settings.sort.direction == "Descending" then
							return a < b
						else
							return a > b
						end
					end)

					for i, statName in ipairs(results) do
						local imageParent = settings.onlyIcons and resultsParent or resultsParent:AddRow()

						---@type SpellData|PassiveData|StatusData
						local spell = Ext.Stats.Get(statName)

						local imageRealParent = (settings.onlyIcons and imageParent or imageParent:AddCell())
						local statImage = imageRealParent:AddImageButton(statName .. i, spell.Icon, { 48 * Styler:ScaleFactor(), 48 * Styler:ScaleFactor() })

						statImage.AutoClosePopups = false
						if statImage.Image.Icon == "" then
							statImage:Destroy()
							statImage = imageRealParent:AddImageButton(statName .. i, "Item_Unknown", { 48 * Styler:ScaleFactor(), 48 * Styler:ScaleFactor() })
						end
						statImage.SameLine = settings.onlyIcons and wrapFunc and wrapFunc(i - 1) or false
						rowCounter = rowCounter + (statImage.SameLine and 0 or 1)

						if shouldTint(statName) then
							statImage.Tint = { 1, 1, 1, 0.2 }
						end

						if customizer then
							customizer(statImage, statName)
						end

						statImage.OnClick = function()
							onClickCallback(statImage, statName)
							statImage.Tint = { 1, 1, 1, shouldTint(statName) and 0.2 or 1 }
						end

						if not settings.onlyIcons then
							---@cast imageParent ExtuiTableRow
							imageParent:AddCell():AddText(statName)
							imageParent:AddCell():AddText(Ext.Loca.GetTranslatedString(spell.DisplayName, statName))
						end
					end

					if resultsGroup.Size[2] ~= 0 then
						resultsGroup.Size = {
							0,
							math.min(600 * Styler:ScaleFactor(), 100 + ((settings.onlyIcons and 48 * Styler:ScaleFactor() or 100 * Styler:ScaleFactor()) * rowCounter))
						}
					end
				end
			end)
		end
	end
end

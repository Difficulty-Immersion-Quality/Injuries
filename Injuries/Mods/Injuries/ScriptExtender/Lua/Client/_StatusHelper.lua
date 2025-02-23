StatusHelper = {}

---@param input string
---@param callback function
---@param dataTable table
---@param displayNameFunc function
---@param searchMethod "ResourceId"|"DisplayName"
---@return boolean
local function BuildStatusesForData(input, callback, dataTable, displayNameFunc, searchMethod)
	local inputText = string.upper(input)
	local isWildcard = false
	if string.find(inputText, "*") then
		inputText = "^" .. string.gsub(inputText, "%*", ".*") .. "$"
		isWildcard = true
	end

	local recordCount = 0
	for _, name in pairs(dataTable) do
		local id
		if searchMethod == "ResourceId" then
			id = name
		elseif searchMethod == "DisplayName" then
			id = displayNameFunc(name)
			if not id then
				goto continue
			end
		end
		id = string.upper(id)

		if isWildcard then
			if string.find(id, inputText) then
				recordCount = recordCount + 1
				callback(name)
			end
		elseif id == inputText then
			callback(name)
			if searchMethod == "ResourceId" then
				return true
			else
				recordCount = recordCount + 1
			end
		end
		::continue::
	end

	return recordCount > 0
end

---@param parent ExtuiTabItem|ExtuiCollapsingHeader
---@param dataTable table
---@param displayNameFunc function
---@param onClick function
function StatusHelper:BuildSearch(parent, dataTable, displayNameFunc, onClick)
	parent:AddText("Add New Row")

	local statusInput = parent:AddInputText("")
	statusInput.Hint = Translator:translate("Case-insensitive - use * to wildcard. Example: *ing*trap* for BURNING_TRAPWALL")
	statusInput.AutoSelectAll = true
	statusInput.EscapeClearsAll = true

	local searchId = parent:AddButton(Translator:translate("Search by Resource ID (e.g. BURNING_TRAPWALL)"))
	searchId.UserData = "ResourceId"

	local searchDisplayName = parent:AddButton(Translator:translate("Search by Display Name (e.g. Burning)"))
	searchDisplayName.UserData = "DisplayName"
	searchDisplayName:Tooltip():AddText(Translator:translate(
		"Depends on the resource having a Display Name set in the game resources and localization being implemented for your language"))

	local errorText = parent:AddText(Translator:translate("Error: Search returned no results"))
	errorText:SetColor("Text", { 1, 0.02, 0, 1 })
	errorText.Visible = false

	local searchFunc = function(button)
		if not BuildStatusesForData(statusInput.Text, onClick, dataTable, displayNameFunc, button.UserData) then
			errorText.Visible = true
		end
	end
	searchId.OnClick = searchFunc
	searchDisplayName.OnClick = searchFunc

	statusInput.OnChange = function(inputElement, text)
		errorText.Visible = false
	end
end

---@param tooltip ExtuiTooltip
---@param status StatusData
function StatusHelper:BuildStatusTooltip(tooltip, status)
	tooltip:AddText("\n")
	tooltip:AddText(Translator:translate("Display Name:") .. " " .. Ext.Loca.GetTranslatedString(status.DisplayName, Translator:translate("N/A")))

	if status.Using and status.Using ~= "" then
		tooltip:AddText(Translator:translate("Using:") .. " " .. status.Using)
	end

	tooltip:AddText(Translator:translate("StatusType:") .. " " .. status.StatusType)

	if status.TooltipDamage and status.TooltipDamage ~= "" then
		tooltip:AddText(Translator:translate("Damage:") .. " " .. status.TooltipDamage)
	end

	if status.StatusGroups and next(status.StatusGroups) then
		tooltip:AddText(Translator:translate("Status Groups:") .. " " .. table.concat(status.StatusGroups, ", "))
	end

	if status.TooltipSave and status.TooltipSave ~= "" then
		tooltip:AddText(Translator:translate("Save:") .. " " .. status.TooltipSave)
	end

	if status.TickType and status.TickType ~= "" then
		tooltip:AddText(Translator:translate("TickType:") .. " " .. status.TickType)
	end

	local description = Ext.Loca.GetTranslatedString(status.Description, "N/A")
	description = string.gsub(description, "<br>", "\n")
	-- Getting rid of all content contained in <>, like <LsTags../> and <br/>
	description = string.gsub(description, "<.->", "")
	local desc = tooltip:AddText(Translator:translate("Description:") .. " " .. description)
	desc.TextWrapPos = 600

	if status.DescriptionParams ~= "" then
		tooltip:AddText(Translator:translate("Description Params:") .. " " .. status.DescriptionParams)
	end

	if status.Boosts ~= "" then
		tooltip:AddText(Translator:translate("Boosts:") .. " " .. status.Boosts).TextWrapPos = 600
	end
end

local statusGroupIndex = {}

---@param group ExtuiTreeParent
---@param injuryStatusConfig InjuryRemoveOnStatusClass|{ [StatusName] : InjuryApplyOnStatusModifierClass }
local function MarkDuplicatedStatuses(group, injuryStatusConfig)
	for _, header in pairs(group.Children) do
		for _, statusNameText in pairs(header.Children) do
			if statusNameText.UserData and not TableUtils:ListContains(injuryStatusConfig[header.UserData]["excluded_statuses"], statusNameText.UserData) then
				---@type StatusData
				local statusData = Ext.Stats.Get(statusNameText.UserData)
				statusNameText:SetColor("Text", { 219 / 255, 201 / 255, 173 / 255, 0.78 })
				statusNameText.Label = statusData.Name

				for _, statusSG in ipairs(statusData.StatusGroups) do
					if statusSG ~= header.UserData then
						if injuryStatusConfig[statusSG] and injuryStatusConfig[statusSG]["excluded_statuses"] and not TableUtils:ListContains(injuryStatusConfig[statusSG]["excluded_statuses"], statusData.Name) then
							statusNameText:SetColor("Text", { 1, 0.02, 0, 1 })
							statusNameText.Label = statusNameText.Label .. string.format(" " .. Translator:translate("(ALSO IN %s, SHOULD ONLY BE ACTIVE IN ONE GROUP)"), statusSG)
							break
						end
					end
				end
			end
		end
	end
end

---@param group ExtuiGroup
---@param injury StatusData
---@param injuryStatusConfig InjuryRemoveOnStatusClass|{ [StatusName] : InjuryApplyOnStatusModifierClass }
---@param configDefault table
---@param customizer function
function StatusHelper:BuildStatusGroupSection(group, injury, injuryStatusConfig, configDefault, customizer)
	if not next(statusGroupIndex) then
		for _, status in pairs(Ext.Stats.GetStats("StatusData")) do
			---@type StatusData
			local statusData = Ext.Stats.Get(status)
			if statusData.StatusGroups and next(statusData.StatusGroups) then
				for _, statusGroup in pairs(statusData.StatusGroups) do
					if not statusGroupIndex[statusGroup] then
						statusGroupIndex[statusGroup] = {}
					end
					table.insert(statusGroupIndex[statusGroup], status)
				end
			end
		end
	end

	group:AddNewLine()
	group:AddSeparatorText(Translator:translate("By Status Group")).Font = "Large"
	group:AddText("If a status belonging to a configured group is configured above, those settings will take precedence"):SetStyle("Alpha", 0.65)

	local sgButton = group:AddButton(Translator:translate("Manage Status Groups"))
	local sgPopup = group:AddPopup("Status Group Picker")

	local headerGroup = group:AddGroup("Headers" .. group.Label)
	for statusGroup, statuses in TableUtils:OrderedPairs(statusGroupIndex) do
		---@type ExtuiSelectable
		local statusGroupSelectable = sgPopup:AddSelectable(statusGroup, "DontClosePopups")
		statusGroupSelectable.IDContext = statusGroup .. injury.Name

		if injuryStatusConfig[statusGroup] then
			statusGroupSelectable.Selected = true
		end

		statusGroupSelectable.OnClick = function()
			if statusGroupSelectable.Selected then
				local statusGroupSection = headerGroup:AddCollapsingHeader(statusGroup)
				statusGroupSection.IDContext = statusGroup .. injury.Name
				statusGroupSection.UserData = statusGroup
				if not injuryStatusConfig[statusGroup] then
					injuryStatusConfig[statusGroup] = TableUtils:DeeplyCopyTable(configDefault)
				end
				local statusConfig = injuryStatusConfig[statusGroup]

				customizer(statusGroupSection, statusConfig)

				table.sort(statuses)
				for _, status in ipairs(statuses) do
					local excludeButton = statusGroupSection:AddButton(Translator:translate("Exclude"))
					excludeButton.IDContext = statusGroup .. injury.Name .. status

					local statusName = statusGroupSection:AddText(status)
					statusName.UserData = status
					statusName.SameLine = true
					---@type StatusData
					local statusData = Ext.Stats.Get(status)
					StatusHelper:BuildStatusTooltip(statusName:Tooltip(), statusData)

					if statusConfig["excluded_statuses"] and TableUtils:ListContains(statusConfig["excluded_statuses"], status) then
						excludeButton.Label = Translator:translate("Include")
						statusName:SetStyle("Alpha", 0.65)
					end

					excludeButton.OnClick = function()
						if statusConfig["excluded_statuses"] then
							local isInList, index = TableUtils:ListContains(statusConfig["excluded_statuses"], status)
							if isInList then
								table.remove(statusConfig["excluded_statuses"], index)
								statusName:SetStyle("Alpha", 1.0)
								excludeButton.Label = Translator:translate("Exclude")
								MarkDuplicatedStatuses(headerGroup, injuryStatusConfig)
								return
							end
						end

						if not statusConfig["excluded_statuses"] then
							statusConfig["excluded_statuses"] = {}
						end
						table.insert(statusConfig["excluded_statuses"], status)
						statusName:SetStyle("Alpha", 0.65)
						statusName:SetColor("Text", { 219 / 255, 201 / 255, 173 / 255, 0.78 })
						statusName.Label = status
						MarkDuplicatedStatuses(headerGroup, injuryStatusConfig)

						excludeButton.Label = Translator:translate("Include")
					end
				end
			else
				for _, element in pairs(headerGroup.Children) do
					if element.UserData == statusGroup then
						injuryStatusConfig[statusGroup].delete = true
						element:Destroy()
					end
				end
			end
		end

		if statusGroupSelectable.Selected then
			statusGroupSelectable.OnClick()
		end
	end
	sgButton.OnClick = function()
		sgPopup:Open()
	end

	MarkDuplicatedStatuses(headerGroup, injuryStatusConfig)
end

Translator:RegisterTranslation({
	["Case-insensitive - use * to wildcard. Example: *ing*trap* for BURNING_TRAPWALL"] = "h2e88b0710ceb4251857a20baa5db708518ga",
	["Search by Resource ID (e.g. BURNING_TRAPWALL)"] = "hb175759ba6364cbd8541f78ed5e57dfcb88g",
	["Search by Display Name (e.g. Burning)"] = "hcccdc9d4c968484face6cafe1c4fc85dg976",
	["Depends on the resource having a Display Name set in the game resources and localization being implemented for your language"] = "h4dc34140f4b04942bda08d46f466084e70cb",
	["Error: Search returned no results"] = "heaca690f1a234dd0b638f94759ee45ebaf1d",
	["Display Name:"] = "hb1d97de1b6f84157ab633ddcb6619e734241",
	["N/A"] = "h71758e3e9cda46e89585505ba804f9e70e74",
	["Using:"] = "hc9c2632641fe40cf8f1bcdefa6c05e4324e2",
	["StatusType:"] = "h372bdafe25ef4cb4b8cd5ccf2b43c53c1bgc",
	["Damage:"] = "h2c5f4e6578684f76a3ef34eb3ff61cd27471",
	["Status Groups:"] = "h365e5e8db0d745dcbc83c4eaee60eb3df64g",
	["Save:"] = "h7b8807a109ac4d8c91e0845cfb133abee843",
	["TickType:"] = "h69b7b3d364594f018016d204da59e45b3040",
	["Description:"] = "h7890abcdef1234567890abcdef1234567890",
	["Description Params:"] = "h890abcdef1234567890abcdef12345678901",
	["Boosts:"] = "h90abcdef1234567890abcdef123456789012",
	["(ALSO IN %s, SHOULD ONLY BE ACTIVE IN ONE GROUP)"] = "hafed135d7dc945e18fa3dbfa8bb3eb946e5e",
	["By Status Group"] = "ha92c7ebfd29545b284d4dc46c5638b4d7245",
	["Manage Status Groups"] = "h0485ebba5acb4e9aa422bbe9163b13cbgd7b",
	["Include"] = "he1723b1c477144bd9e4c69594b60f64f6a9b",
	["Exclude"] = "hcfc9c68627ac4cd9a365d94a32e48c0cc4fd",
})

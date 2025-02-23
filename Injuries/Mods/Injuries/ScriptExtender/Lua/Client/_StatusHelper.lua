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
	statusInput.Hint = "Case-insensitive - use * to wildcard. Example: *ing*trap* for BURNING_TRAPWALL"
	statusInput.AutoSelectAll = true
	statusInput.EscapeClearsAll = true

	local searchId = parent:AddButton("Search by Resource ID (e.g. BURNING_TRAPWALL)")
	searchId.UserData = "ResourceId"

	local searchDisplayName = parent:AddButton("Search by Display Name (e.g. Burning)")
	searchDisplayName.UserData = "DisplayName"
	searchDisplayName:Tooltip():AddText("Depends on the resource having a Display Name set in the game resources and localization being implemented for your language")

	local errorText = parent:AddText("Error: Search returned no results")
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
	tooltip:AddText("Display Name: " .. Ext.Loca.GetTranslatedString(status.DisplayName, "N/A"))

	if status.Using and status.Using ~= "" then
		tooltip:AddText("Using: " .. status.Using)
	end

	tooltip:AddText("StatusType: " .. status.StatusType)

	if status.TooltipDamage and status.TooltipDamage ~= "" then
		tooltip:AddText("Damage: " .. status.TooltipDamage)
	end

	if status.StatusGroups and next(status.StatusGroups) then
		tooltip:AddText("Status Groups: " .. table.concat(status.StatusGroups, ", "))
	end

	if status.HealValue and status.HealValue ~= "" then
		tooltip:AddText("Healing: |Value: " .. status.HealthValue .. " |Stat: " .. status.HealStat .. "|Multiplier: " .. status.HealMultiplier .. "|")
	end

	if status.TooltipSave and status.TooltipSave ~= "" then
		tooltip:AddText("Save: " .. status.TooltipSave)
	end

	if status.TickType and status.TickType ~= "" then
		tooltip:AddText("TickType: " .. status.TickType)
	end

	local description = Ext.Loca.GetTranslatedString(status.Description, "N/A")
	description = string.gsub(description, "<br>", "\n")
	-- Getting rid of all content contained in <>, like <LsTags../> and <br/>
	description = string.gsub(description, "<.->", "")
	local desc = tooltip:AddText("Description: " .. description)
	desc.TextWrapPos = 600

	if status.DescriptionParams ~= "" then
		tooltip:AddText("Description Params: " .. status.DescriptionParams)
	end

	if status.Boosts ~= "" then
		tooltip:AddText("Boosts: " .. status.Boosts).TextWrapPos = 600
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
							statusNameText.Label = statusNameText.Label .. string.format(" (ALSO IN %s, SHOULD ONLY BE ACTIVE IN ONE GROUP)", statusSG)
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
	group:AddSeparatorText("By Status Group").Font = "Large"
	group:AddText("If a status belonging to a configured group is configured above, those settings will take precedence"):SetStyle("Alpha", 0.65)

	local sgButton = group:AddButton("Manage Status Groups")
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
					local excludeButton = statusGroupSection:AddButton("Exclude")
					excludeButton.IDContext = statusGroup .. injury.Name .. status

					local statusName = statusGroupSection:AddText(status)
					statusName.UserData = status
					statusName.SameLine = true
					---@type StatusData
					local statusData = Ext.Stats.Get(status)
					StatusHelper:BuildStatusTooltip(statusName:Tooltip(), statusData)

					if statusConfig["excluded_statuses"] and TableUtils:ListContains(statusConfig["excluded_statuses"], status) then
						excludeButton.Label = "Include"
						statusName:SetStyle("Alpha", 0.65)
					end

					excludeButton.OnClick = function()
						if statusConfig["excluded_statuses"] then
							local isInList, index = TableUtils:ListContains(statusConfig["excluded_statuses"], status)
							if isInList then
								table.remove(statusConfig["excluded_statuses"], index)
								statusName:SetStyle("Alpha", 1.0)
								excludeButton.Label = "Exclude"
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

						excludeButton.Label = "Include"
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

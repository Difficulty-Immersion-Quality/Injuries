DataSearchHelper = {}

local function BuildStatusesForInput(input, callback, dataTable)
	local inputText = string.upper(input)
	local isWildcard = false
	if string.find(inputText, "*") then
		inputText = "^" .. string.gsub(inputText, "%*", ".*") .. "$"
		isWildcard = true
	end

	local statusCount = 0
	for _, name in pairs(dataTable) do
		local upperName = string.upper(name)
		if isWildcard then
			if string.find(upperName, inputText) then
				statusCount = statusCount + 1
				callback(name)
			end
		elseif upperName == inputText then
			statusCount = statusCount + 1
			callback(name)
			break
		end
	end

	return statusCount > 0
end

---@param parent ExtuiTabItem|ExtuiCollapsingHeader
---@param dataTable table
---@param onClick function
function DataSearchHelper:BuildSearch(parent, dataTable, onClick)
	parent:AddText("Add New Row")

	local statusInput = parent:AddInputText("")
	statusInput.Hint = "Case-insensitive - use * to wildcard. Example: *ing*trap* for BURNING_TRAPWALL"
	statusInput.AutoSelectAll = true
	statusInput.EscapeClearsAll = true

	local statusInputButton = parent:AddButton("Search")

	local errorText = parent:AddText("Error: Search returned no results")
	errorText:SetColor("Text", { 1, 0.02, 0, 1 })
	errorText.Visible = false

	statusInputButton.OnClick = function()
		if not BuildStatusesForInput(statusInput.Text, onClick, dataTable) then
			errorText.Visible = true
		end
	end

	statusInput.OnChange = function(inputElement, text)
		errorText.Visible = false
	end
end

---@param tooltip ExtuiTooltip
---@param status StatsObject
function DataSearchHelper:BuildStatusTooltip(tooltip, status)
	tooltip:AddText("Display Name: " .. Ext.Loca.GetTranslatedString(status.DisplayName, "N/A"))
	tooltip:AddText("StatusType: " .. status.StatusType)

	if status.TooltipDamage ~= "" then
		tooltip:AddText("Damage: " .. status.TooltipDamage)
	end

	if status.HealValue ~= "" then
		tooltip:AddText("Healing: |Value: " .. status.HealthValue .. " |Stat: " .. status.HealStat .. "|Multiplier: " .. status.HealMultiplier .. "|")
	end

	if status.TooltipSave ~= "" then
		tooltip:AddText("Save: " .. status.TooltipSave)
	end

	if status.TickType ~= "" then
		tooltip:AddText("TickType: " .. status.TickType)
	end

	local description = Ext.Loca.GetTranslatedString(status.Description, "N/A")
	-- Getting rid of all content contained in <>, like <LsTags../> and <br/>
	description = string.gsub(description, "<.->", "")
	local desc = tooltip:AddText("Description: " .. description)
	desc.TextWrapPos = 600

	if status.DescriptionParams ~= "" then
		tooltip:AddText("Description Params: " .. status.DescriptionParams)
	end

end

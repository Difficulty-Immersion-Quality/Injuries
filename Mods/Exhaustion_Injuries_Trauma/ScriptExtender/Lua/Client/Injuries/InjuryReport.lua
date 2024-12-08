Ext.Require("Shared/Injuries/_ConfigHelper.lua")

InjuryReport = {}

Ext.Vars.RegisterModVariable(ModuleUUID, "Injury_Report", {
	Server = true,
	Client = true,
	WriteableOnServer = true,
	WriteableOnClient = true,
	SyncToClient = true,
	SyncToServer = true
})

---@type { [CHARACTER] : InjuryVar }
local entityInjuriesReport = {}

--- @type ExtuiWindow?
local reportWindow

---@param parent ExtuiTableCell
---@param entity EntityHandle
---@param injuryConfig Injury
---@return number?
local function AddRaceMultiplierText(parent, entity, injuryConfig)
	---@type ResourceRace
	local raceResource = Ext.StaticData.Get(entity.Race.Race, "Race")

	parent:AddText(string.format("Race: %s (%s)",
		(raceResource.DisplayName:Get() or ("Can't Translate")),
		string.sub(raceResource.ResourceUUID, -5)))

	return injuryConfig.character_multipliers["races"][raceResource.ResourceUUID]
end

---@param parent ExtuiTableCell
---@param entity EntityHandle
---@param injuryConfig Injury
---@return number?
local function AddTagMultiplierText(parent, entity, injuryConfig)
	local seeTagButton = parent:AddImageButton("AllTags", "Spell_Divination_SeeInvisibility", { 30, 30 })
	seeTagButton.SameLine = true

	local tagPopup = seeTagButton:Tooltip("Tags")

	local tagTable = tagPopup:AddTable("TagTable", 2)
	tagTable.SizingStretchProp = true
	tagTable.BordersInnerH = true
	tagTable.BordersInnerV = true
	tagTable.RowBg = true

	local foundTag = false
	local totalTagMultiplier = 1
	for _, tagUUID in pairs(entity.Tag.Tags) do
		---@type ResourceTag
		local tagData = Ext.StaticData.Get(tagUUID, "Tag")

		local row = tagTable:AddRow()

		local tagMulti = injuryConfig.character_multipliers["tags"][tagUUID]
		if tagMulti then
			totalTagMultiplier = totalTagMultiplier * tagMulti
			row:AddCell():AddText(string.format("%s%%", tagMulti * 100))
			foundTag = true
			-- RGB -> Green with 50% opacity (multiply each value by 255)
			row:SetColor("TableRowBg", {0.09, 0.55, 0.04, 0.5})
			row:SetColor("TableRowBgAlt", {0.09, 0.55, 0.04, 0.5})
		else
			row:AddCell():AddText("---")
			row:SetColor("TableRowBg", {0.09, 0.55, 0.04, 0})
			row:SetColor("TableRowBgAlt", {0.09, 0.55, 0.04, 0})
		end

		row:AddCell():AddText(string.format("%s (%s - %s)",
			tagData.Name,
			tagData.DisplayName:Get() or "N/A",
			string.sub(tagData.ResourceUUID, -5)
		))
	end

	return foundTag and totalTagMultiplier or nil
end

local function BuildReport()
	if reportWindow then
		for _, child in pairs(reportWindow.Children) do
			if child.UserData and (child.UserData ~= "keep" or not entityInjuriesReport[child.UserData]) then
				child:Destroy()
			end
		end

		for character, injuryReport in pairs(entityInjuriesReport) do
			---@type EntityHandle
			local entity = Ext.Entity.Get(character)

			local charReport
			for _, child in pairs(reportWindow.Children) do
				if character == child.UserData then
					charReport = child
					break
				end
			end

			if not charReport then
				charReport = reportWindow:AddCollapsingHeader(string.format("%s (%s)",
					entity.CustomName and entity.CustomName.Name or entity.DisplayName.NameKey:Get(),
					entity.Uuid.EntityUuid))

				charReport.DefaultOpen = false
				charReport.UserData = character
			end

			for _, child in pairs(charReport.Children) do
				child:Destroy()
			end

			local clearButton = charReport:AddButton("Clear Report")
			clearButton.OnClick = function()
				entityInjuriesReport[character] = nil
				BuildReport()
			end

			local characterMultiplier, npcCategory = InjuryConfigHelper:CalculateCharacterMultiplier(entity)
			if npcCategory then
				charReport:AddText(string.format("NPC Category: %s | Multiplier: %s%%", npcCategory, characterMultiplier * 100))
			end

			for injury, injuryConfig in pairs(ConfigurationStructure.config.injuries.injury_specific) do
				local injuryReportGroup = charReport:AddGroup(injury)

				local sepText = Ext.Loca.GetTranslatedString(Ext.Stats.Get(injury).DisplayName, injury)
				sepText = sepText .. " || " .. injuryConfig.severity .. " Severity"

				if injuryReport["injuryAppliedReason"][injury] then
					sepText = sepText .. " || Applied Due To " .. injuryReport["injuryAppliedReason"][injury]
				end
				injuryReportGroup:AddSeparatorText(sepText)

				local keepGroup = false

				--#region Damage Report
				if next(injuryConfig.damage["damage_types"]) then
					local damageGroup = injuryReportGroup:AddGroup("Damage")

					local damageResultText = damageGroup:AddText("Injury Damage / Threshold: ")

					-- damageGroup:AddText("Click To See Report")
					local damageReportButton = damageGroup:AddImageButton("DamageReport", "Spell_Divination_SeeInvisibility", { 30, 30 })
					damageReportButton.SameLine = true
					damageReportButton:Tooltip():AddText("Click to toggle the table")

					local damageReportTable = damageGroup:AddTable("Damage Report", 4)
					damageReportTable.SizingStretchSame = true
					damageReportTable.BordersInnerH = true
					damageReportTable.Visible = false

					local damageReportHeaders = damageReportTable:AddRow()
					damageReportHeaders.Headers = true
					damageReportHeaders:AddCell():AddText("")
					damageReportHeaders:AddCell():AddText("Multiplier")
					damageReportHeaders:AddCell():AddText("Before")
					damageReportHeaders:AddCell():AddText("After")

					local wasClicked = false
					damageReportButton.OnHoverEnter = function()
						damageReportTable.Visible = true
					end

					damageReportButton.OnClick = function()
						wasClicked = not wasClicked
					end

					damageReportButton.OnHoverLeave = function()
						damageReportTable.Visible = wasClicked
					end

					local totalDamage = 0
					for damageType, damageTypeConfig in pairs(injuryConfig.damage["damage_types"]) do
						local damageAmount = injuryReport["damage"][damageType]
						if damageAmount and damageAmount[injury] then
							local flatWithMultiplier = damageAmount[injury] * damageTypeConfig["multiplier"]
							totalDamage = totalDamage + flatWithMultiplier

							local row = damageReportTable:AddRow()
							row:AddCell():AddText(damageType)
							row:AddCell():AddText(string.format("%d%%", damageTypeConfig["multiplier"] * 100))
							row:AddCell():AddText(tostring(damageAmount[injury]))
							row:AddCell():AddText(tostring(flatWithMultiplier))
						end
					end

					if totalDamage == 0 then
						damageGroup:Destroy()
					else
						local row = damageReportTable:AddRow()
						row:AddCell():AddText("Total Damage")
						row:AddCell():AddText("---")
						row:AddCell():AddText("---")
						row:AddCell():AddText(tostring(totalDamage))

						local raceRow = damageReportTable:AddRow()
						local raceMulti = AddRaceMultiplierText(raceRow:AddCell(), entity, injuryConfig)
						raceRow:AddCell():AddText(raceMulti and ((raceMulti * 100) .. "%") or "N/A")
						raceRow:AddCell():AddText("---")
						totalDamage = totalDamage * (raceMulti or 1)
						raceRow:AddCell():AddText(tostring(totalDamage))

						local tagRow = damageReportTable:AddRow()
						local tagDisplayCell = tagRow:AddCell()
						tagDisplayCell:AddText("Tag")
						local totalTagMultiplier = AddTagMultiplierText(tagDisplayCell, entity, injuryConfig)
						tagRow:AddCell():AddText(totalTagMultiplier and ((totalTagMultiplier * 100) .. "%") or "N/A")
						tagRow:AddCell():AddText("---")
						totalDamage = totalDamage * (totalTagMultiplier or 1)
						tagRow:AddCell():AddText(tostring(totalDamage))

						if npcCategory then
							local npcMulti = damageReportTable:AddRow()
							npcMulti:AddCell():AddText("NPC Category")
							npcMulti:AddCell():AddText(string.format("%s%%", characterMultiplier * 100))
							npcMulti:AddCell():AddText("---")
							totalDamage = totalDamage * characterMultiplier
							npcMulti:AddCell():AddText(tostring(totalDamage))
						end

						damageResultText.Label = string.format("%s: %.2f%%/%.2f%%",
							damageResultText.Label,
							((totalDamage / entity.Health.MaxHp) * 100),
							injuryConfig.damage["threshold"])

						keepGroup = true
					end
				end
				--#endregion

				--#region ApplyOnStatus report
				if next(injuryConfig.apply_on_status["applicable_statuses"]) then
					local statusGroup = injuryReportGroup:AddGroup("ApplyOnStatus")
					if keepGroup then
						statusGroup:AddNewLine()
					end
					statusGroup:AddText("Apply On Status Report")

					local totalRounds = 0

					for status, statusConfig in pairs(injuryConfig.apply_on_status["applicable_statuses"]) do
						local numRoundsApplied = injuryReport["applyOnStatus"][status]
						if numRoundsApplied and numRoundsApplied[injury] then
							totalRounds = totalRounds + (numRoundsApplied[injury] * statusConfig["multiplier"])
							statusGroup:AddText(string.format("%s: Multiplier: %s | Number of (Non-Consecutive) Rounds Applied After Multiplier: %s",
								status,
								statusConfig["multiplier"],
								numRoundsApplied[injury] * statusConfig["multiplier"]))
						end
					end

					if totalRounds == 0 then
						statusGroup:Destroy()
					else
						totalRounds = totalRounds * raceMulti * totalTagMultiplier * characterMultiplier
						statusGroup:AddText(string.format("Total Rounds For All Multipliers / Threshold: %s/%s",
							totalRounds,
							injuryConfig.apply_on_status["number_of_rounds"]))
						keepGroup = true
					end
				end
				--#endregion


				if not keepGroup then
					injuryReportGroup:Destroy()
				else
					injuryReportGroup:AddNewLine()
				end
			end
		end
	end
end

-- Temporary until we can listen to specific UserVars, probably in SE 22
Ext.RegisterNetListener("Injuries_Update_Report", function(channel, character, user)
	character = Ext.Entity.Get(character).Uuid.EntityUuid

	local entityVars = Ext.Entity.Get(character).Vars

	entityInjuriesReport = Ext.Vars.GetModVariables(ModuleUUID).Injury_Report or {}

	if not entityVars.Goon_Injuries then
		entityInjuriesReport[character] = nil
	else
		if not next(entityVars.Goon_Injuries["damage"]) and not next(entityVars.Goon_Injuries["applyOnStatus"]) then
			entityInjuriesReport[character] = nil
		else
			entityInjuriesReport[character] = entityVars.Goon_Injuries
		end
	end

	Ext.Vars.GetModVariables(ModuleUUID).Injury_Report = entityInjuriesReport
	BuildReport()
end)

function InjuryReport:BuildReportWindow()
	reportWindow = Ext.IMGUI.NewWindow("Viewing Live Injury Report")
	reportWindow.Closeable = true

	local moreInfo = reportWindow:AddImageButton("More Info", "Action_Help", { 30, 30 })
	local tooltip = moreInfo:Tooltip()
	tooltip:AddText("Data for an injury will stop updating once that injury is applied, but will remain for transparency.")
	tooltip:AddSeparator()
	tooltip:AddText("Characters will be removed from the report when they die or all injury information is removed from them, such as when:").TextWrapPos = 0
	tooltip:AddBulletText("The Counters are reset")
	tooltip:AddBulletText("All Damage is Healed")
	tooltip:AddBulletText("All applied injuries are removed")
	tooltip:AddSeparator()
	tooltip:AddText("The provided 'Clear Report' button will remove any given Character from the report until one of their trackers is updated. Really only useful for clearing Allies that survive battles.").TextWrapPos = 0

	reportWindow.OnClose = function()
		reportWindow = nil
	end

	entityInjuriesReport = Ext.Vars.GetModVariables(ModuleUUID).Injury_Report or {}
	Ext.Vars.GetModVariables(ModuleUUID).Injury_Report = entityInjuriesReport

	BuildReport()
end

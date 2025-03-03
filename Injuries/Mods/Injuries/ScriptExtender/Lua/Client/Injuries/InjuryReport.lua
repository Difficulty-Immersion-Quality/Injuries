Ext.Require("Shared/Injuries/_InjuryCommonLogic.lua")

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
	if not entity.Race then
		return nil
	end
	---@type ResourceRace
	local raceResource = Ext.StaticData.Get(entity.Race.Race, "Race")

	parent:AddText("Race")

	local button = parent:AddImageButton("npcCategory", "Spell_Divination_SeeInvisibility", { 30, 30 })
	button.SameLine = true
	button:Tooltip():AddText(string.format("\t%s (%s)",
		(raceResource.DisplayName:Get() or ("Can't Translate")),
		string.sub(raceResource.ResourceUUID, -5)))

	return (injuryConfig.character_multipliers and injuryConfig.character_multipliers["races"]) and injuryConfig.character_multipliers["races"][raceResource.ResourceUUID] or nil
end

---@param parent ExtuiTableCell
---@param entity EntityHandle
---@param injuryConfig Injury
---@return number?
local function AddTagMultiplierText(parent, entity, injuryConfig)
	if not entity.Tag then
		return nil
	end

	local seeTagButton = parent:AddImageButton("AllTags", "Spell_Divination_SeeInvisibility", { 30, 30 })
	seeTagButton.SameLine = true

	local tagPopup = seeTagButton:Tooltip("Tags")
	tagPopup:AddNewLine()

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

		local tagMulti = (injuryConfig.character_multipliers and injuryConfig.character_multipliers["tags"]) and injuryConfig.character_multipliers["tags"][tagUUID]
		if tagMulti then
			totalTagMultiplier = totalTagMultiplier * tagMulti
			row:AddCell():AddText(string.format("%s%%", tagMulti * 100))
			foundTag = true
			-- RGB -> Green with 50% opacity (multiply each value by 255)
			row:SetColor("TableRowBg", { 0.09, 0.55, 0.04, 0.5 })
			row:SetColor("TableRowBgAlt", { 0.09, 0.55, 0.04, 0.5 })
		else
			row:AddCell():AddText("---")
			row:SetColor("TableRowBg", { 0.09, 0.55, 0.04, 0 })
			row:SetColor("TableRowBgAlt", { 0.09, 0.55, 0.04, 0 })
		end

		row:AddCell():AddText(string.format("%s (%s - %s)",
			tagData.Name,
			tagData.DisplayName:Get() or Translator:translate("N/A"),
			string.sub(tagData.ResourceUUID, -5)
		))
	end

	return foundTag and totalTagMultiplier or nil
end

---@param reportTable ExtuiTable
---@param entity EntityHandle
---@param injuryConfig Injury
---@param totalAmount number
---@param npcCategory string?
---@param characterMultiplier number
---@return number
local function AddMultiplierRows(reportTable, entity, injuryConfig, totalAmount, npcCategory, characterMultiplier)
	local raceRow = reportTable:AddRow()
	local raceMulti = AddRaceMultiplierText(raceRow:AddCell(), entity, injuryConfig)
	raceRow:AddCell():AddText(raceMulti and ((raceMulti * 100) .. "%") or Translator:translate("N/A"))
	raceRow:AddCell():AddText("---")
	totalAmount = totalAmount * (raceMulti or 1)
	raceRow:AddCell():AddText(tostring(totalAmount))

	local tagRow = reportTable:AddRow()
	local tagDisplayCell = tagRow:AddCell()
	tagDisplayCell:AddText(Translator:translate("Tag"))
	local totalTagMultiplier = AddTagMultiplierText(tagDisplayCell, entity, injuryConfig)
	tagRow:AddCell():AddText(totalTagMultiplier and ((totalTagMultiplier * 100) .. "%") or Translator:translate("N/A"))
	tagRow:AddCell():AddText("---")
	totalAmount = totalAmount * (totalTagMultiplier or 1)
	tagRow:AddCell():AddText(tostring(totalAmount))

	if npcCategory then
		local npcMulti = reportTable:AddRow()
		local npcDisplay = npcMulti:AddCell()
		npcDisplay:AddText(Translator:translate("NPC Category"))
		local seeNpcButton = npcDisplay:AddImageButton("npcCategory", "Spell_Divination_SeeInvisibility", { 30, 30 })
		seeNpcButton.SameLine = true
		seeNpcButton:Tooltip():AddText("\t" .. npcCategory)

		npcMulti:AddCell():AddText(string.format("%s%%", characterMultiplier * 100))
		npcMulti:AddCell():AddText("---")
		totalAmount = totalAmount * characterMultiplier
		npcMulti:AddCell():AddText(tostring(totalAmount))
	end

	return totalAmount
end

---@param group ExtuiGroup
---@return ExtuiTable
local function CreateReport(group)
	-- prefixing with UserData otherwise subsequent buttons can't maintain state, as earlier buttons with the same ID are already reserved
	local reportButton = group:AddImageButton(group.UserData .. "Report", "Spell_Divination_SeeInvisibility", { 30, 30 })
	reportButton.SameLine = true
	reportButton:Tooltip():AddText("\tClick To Toggle")

	local reportTable = group:AddTable(group.UserData .. "Report", 4)
	reportTable.SizingStretchSame = true
	reportTable.BordersInnerH = true
	reportTable.Visible = false

	local statusReportHeaders = reportTable:AddRow()
	statusReportHeaders.Headers = true
	statusReportHeaders:AddCell():AddText("")
	statusReportHeaders:AddCell():AddText(Translator:translate("Multiplier"))
	statusReportHeaders:AddCell():AddText(Translator:translate("Before"))
	statusReportHeaders:AddCell():AddText(Translator:translate("After"))

	reportTable.UserData = false
	reportButton.OnHoverEnter = function()
		reportTable.Visible = true
	end

	reportButton.OnClick = function()
		reportTable.UserData = not reportTable.UserData
	end

	reportButton.OnHoverLeave = function()
		reportTable.Visible = reportTable.UserData
	end

	return reportTable
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

			if not entity or not entity.Data or not entity.IsAlive then
				entityInjuriesReport[character] = nil
				Ext.Vars.GetModVariables(ModuleUUID).Injury_Report = entityInjuriesReport
				goto next_injury
			end

			local charReport
			for _, child in pairs(reportWindow.Children) do
				if character == child.UserData then
					charReport = child
					break
				end
			end

			if not charReport then
				charReport = reportWindow:AddCollapsingHeader(string.format("%s (%s)",
					entity.CustomName and entity.CustomName.Name or (entity.DisplayName and entity.DisplayName.NameKey:Get() or entity.Uuid.EntityUuid),
					entity.Uuid.EntityUuid))

				charReport.DefaultOpen = false
				charReport.UserData = character
			end

			for _, child in pairs(charReport.Children) do
				child:Destroy()
			end

			local clearButton = charReport:AddButton("Clear Report")
			clearButton.IDContext = character
			clearButton.OnClick = function()
				entityInjuriesReport[character] = nil
				BuildReport()
			end

			local characterMultiplier, npcCategory = InjuryCommonLogic:CalculateNpcMultiplier(entity)

			local keepHeader = false

			for injury, injuryConfig in TableUtils:OrderedPairs(ConfigurationStructure.config.injuries.injury_specific, function(key)
				---@type StatusData?
				local status = Ext.Stats.Get(key)
				return status and Ext.Loca.GetTranslatedString(status.DisplayName, key) or key
			end) do
				---@cast injuryConfig Injury

				---@type StatusData?
				local injuryStat = Ext.Stats.Get(injury)

				if not injuryStat then
					Logger:BasicWarning("Injury %s is in the config, but does not exist in the game - should delete from the config.json!", injury)
					goto continue
				end

				local injuryReportGroup = charReport:AddGroup(injury)

				local sepText = Ext.Loca.GetTranslatedString(injuryStat.DisplayName, injury)
				sepText = sepText .. " || " .. injuryConfig.severity .. " Severity"

				local keepGroup = false
				if injuryReport["injuryAppliedReason"][injury] then
					keepGroup = true
					sepText = sepText .. " " .. Translator:translate("|| Applied Due To") .. " " .. injuryReport["injuryAppliedReason"][injury]
				end
				injuryReportGroup:AddSeparatorText(sepText).Font = "Large"

				if injuryReport["numberOfApplicationsAttempted"] and injuryReport["numberOfApplicationsAttempted"][injury] then
					injuryReportGroup:AddText(string.format(Translator:translate("Application Chance:") .. " %s%% ", injuryReport["applicationChance"][injury]))
					injuryReportGroup:AddText(string.format(Translator:translate("| Number Of Attempted Applications:") .. " %s", injuryReport["numberOfApplicationsAttempted"][injury])).SameLine = true
				end

				if injuryReport["numberOfLongRests"] and injuryReport["numberOfLongRests"][injury] then
					injuryReportGroup:AddText(string.format("# of Long Rests: %s / %s", injuryReport["numberOfLongRests"][injury],
						injuryConfig.remove_on_status["LONG_REST"]["after_x_applications"]))
				end

				--#region Damage Report
				if injuryConfig.damage and injuryConfig.damage["damage_types"] and next(injuryConfig.damage["damage_types"]) then
					local damageGroup = injuryReportGroup:AddGroup("Damage")
					damageGroup.UserData = injury .. "damage"

					local damageResultText = damageGroup:AddText(Translator:translate("Injury Damage / Threshold"))
					local damageReportTable = CreateReport(damageGroup)

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
						row:AddCell():AddText(Translator:translate("Total Damage"))
						row:AddCell():AddText("---")
						row:AddCell():AddText("---")
						row:AddCell():AddText(tostring(totalDamage))

						totalDamage = AddMultiplierRows(damageReportTable, entity, injuryConfig, totalDamage, npcCategory, characterMultiplier)

						damageResultText.Label = string.format("%s: %.2f%%/%.2f%%",
							damageResultText.Label,
							((totalDamage / entity.Health.MaxHp) * 100),
							injuryConfig.damage["threshold"])

						keepGroup = true
					end
				end
				--#endregion

				--#region ApplyOnStatus report
				if injuryConfig.apply_on_status and injuryConfig.apply_on_status["applicable_statuses"] and next(injuryConfig.apply_on_status["applicable_statuses"]) then
					local statusGroup = injuryReportGroup:AddGroup("ApplyOnStatus")
					statusGroup.UserData = injury .. "applyOnStatus"

					local statusText = statusGroup:AddText(Translator:translate("Apply On Status: Cumulative Rounds / Threshold"))
					local statusReportTable = CreateReport(statusGroup)

					local totalRounds = 0
					for status, numRoundsApplied in pairs(injuryReport["applyOnStatus"]) do
						---@type StatusData
						local statusData = Ext.Stats.Get(status)

						local statusConfig = injuryConfig.apply_on_status["applicable_statuses"][status]
						local configuredGroup
						if not statusConfig then
							if next(statusData.StatusGroups) then
								for _, statusGroup in pairs(statusData.StatusGroups) do
									if injuryConfig.apply_on_status["applicable_statuses"][statusGroup]
										and (not injuryConfig.apply_on_status["applicable_statuses"][statusGroup]["excluded_statuses"] or not injuryConfig.apply_on_status["applicable_statuses"][statusGroup]["excluded_statuses"][status])
									then
										statusConfig = injuryConfig.apply_on_status["applicable_statuses"][statusGroup]
										configuredGroup = statusGroup
										break
									end
								end
							end
						end

						if statusConfig and numRoundsApplied and numRoundsApplied[injury] then
							totalRounds = totalRounds + (numRoundsApplied[injury] * statusConfig["multiplier"])
							local row = statusReportTable:AddRow()
							StatusHelper:BuildStatusTooltip(row:AddCell():AddText(status .. (configuredGroup and string.format(" (%s)", configuredGroup) or "")):Tooltip(),
								statusData)
							row:AddCell():AddText(string.format("%d%%", statusConfig["multiplier"] * 100))
							row:AddCell():AddText(tostring(numRoundsApplied[injury]))
							row:AddCell():AddText(tostring(numRoundsApplied[injury] * statusConfig["multiplier"]))
						end
					end

					if totalRounds == 0 then
						statusGroup:Destroy()
					else
						local row = statusReportTable:AddRow()
						row:AddCell():AddText(Translator:translate("Total # of Rounds"))
						row:AddCell():AddText("---")
						row:AddCell():AddText("---")
						row:AddCell():AddText(tostring(totalRounds))

						totalRounds = AddMultiplierRows(statusReportTable, entity, injuryConfig, totalRounds, npcCategory, characterMultiplier)

						statusText.Label = string.format("%s: %.2f/%s",
							statusText.Label,
							totalRounds,
							injuryConfig.apply_on_status["number_of_rounds"])

						keepGroup = true
					end
				end
				--#endregion

				if not keepGroup then
					injuryReportGroup:Destroy()
				else
					injuryReportGroup:AddNewLine()
					keepHeader = true
				end
				::continue::
			end
			if not keepHeader then
				charReport:Destroy()
			end
			::next_injury::
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
		if (not entityVars.Goon_Injuries["damage"] or not next(entityVars.Goon_Injuries["damage"]))
			and (not entityVars.Goon_Injuries["applyOnStatus"] or not next(entityVars.Goon_Injuries["applyOnStatus"]))
			and (not entityVars.Goon_Injuries["injuryAppliedReason"] or not next(entityVars.Goon_Injuries["injuryAppliedReason"]))
		then
			entityInjuriesReport[character] = nil
		else
			entityInjuriesReport[character] = entityVars.Goon_Injuries
		end
	end

	Ext.Vars.GetModVariables(ModuleUUID).Injury_Report = entityInjuriesReport
	BuildReport()
end)

function InjuryReport:BuildReportWindow()
	reportWindow = Ext.IMGUI.NewWindow(Translator:translate("Viewing Live Injury Report"))
	reportWindow.Closeable = true

	local moreInfo = reportWindow:AddImageButton("More Info", "Action_Help", { 30, 30 })
	local tooltip = moreInfo:Tooltip()
	tooltip:AddText("\t\t " .. Translator:translate("Data for an injury will stop updating once that injury is applied, but will remain for transparency."))
	tooltip:AddSeparator()
	tooltip:AddText(Translator:translate("Characters will be removed from the report when they die or all injury information is removed from them, such as when:")).TextWrapPos = 0
	tooltip:AddBulletText(Translator:translate("The Counters are reset"))
	tooltip:AddBulletText(Translator:translate("All Damage is Healed"))
	tooltip:AddBulletText(Translator:translate("All applied injuries are removed"))
	tooltip:AddSeparator()
	tooltip:AddText(Translator:translate("The provided 'Clear Report' button will remove any given Character from the report until one of their trackers is updated. Really only useful for clearing Allies that survive battles.")).TextWrapPos = 0

	reportWindow.OnClose = function()
		reportWindow = nil
	end

	entityInjuriesReport = Ext.Vars.GetModVariables(ModuleUUID).Injury_Report or {}
	Ext.Vars.GetModVariables(ModuleUUID).Injury_Report = entityInjuriesReport

	BuildReport()
end

Translator:RegisterTranslation({
	["N/A"] = "hc8b5175f44b74b64987bad4f9dc5a92795cf",
	["Tag"] = "h69c86afe9aca452c99c22b622e132edb3faf",
	["NPC Category"] = "h00ffb5e8947a49a2809db7c6040a507c8720",
	["Multiplier"] = "h7e09d99860024b8fbd8cb4150e0a38f4b75b",
	["Before"] = "h5043a3dc062140d18bb41f64e64919c53808",
	["After"] = "h027c1850829a4110bd48020e5cc3568b07b6",
	["|| Applied Due To"] = "hbeb89344fa92437bb90906a174e97422a41g",
	["Application Chance:"] = "h6a6c0cf5788a4c53bfa79f34f80c649855ge",
	["| Number Of Attempted Applications:"] = "hbfc67df75c9c415984e82956001094eb36fe",
	["Injury Damage / Threshold"] = "h6c7f017278c34386ae1fe4810beaa30fa7d5",
	["Total Damage"] = "ha7b7cc41b59d406f93b7c4e8d6f99c50b7eb",
	["Apply On Status: Cumulative Rounds / Threshold"] = "h68f3d107a4e2413191eb6608c2758c9dfb52",
	["Total # of Rounds"] = "h6d75e18a324a41cd9eca0f4d026a0391g4ab",
	["Viewing Live Injury Report"] = "h16fe43f0f3bf460cafe41b643caf19a97gge",
	["Data for an injury will stop updating once that injury is applied, but will remain for transparency."] = "ha435e14fb43c4aae8ad3333e1a3629e931b0",
	["Characters will be removed from the report when they die or all injury information is removed from them, such as when:"] = "hc6ab9696c9b64211b720b3cf7758c6d17b5g",
	["The Counters are reset"] = "h756f70ecde4f4f34a5948db95002cfa487g8",
	["All Damage is Healed"] = "h4c2c9f6d81804c1ab25415e9930fde1c22f0",
	["All applied injuries are removed"] = "hcc19224ba7234daeacec4ee2a68e044e86d6",
	["The provided 'Clear Report' button will remove any given Character from the report until one of their trackers is updated. Really only useful for clearing Allies that survive battles."] =
	"he7a1ecba3c5e48e3bf3b992e949c802f497d",
})

-- MCM dependency
if Ext.Mod.IsModLoaded("755a8a72-407f-4f0d-9a33-274ac0f0b53d") and Ext.Mod.GetMod("755a8a72-407f-4f0d-9a33-274ac0f0b53d").Info.ModVersion[2] >= 19 then
	MCM.SetKeybindingCallback('report_keybind', function()
		if not reportWindow then
			InjuryReport:BuildReportWindow()
		end
		BuildReport()
	end)
end

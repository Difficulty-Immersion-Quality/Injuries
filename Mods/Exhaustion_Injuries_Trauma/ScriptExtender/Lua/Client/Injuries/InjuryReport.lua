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
				injuryReportGroup:AddSeparatorText(Ext.Loca.GetTranslatedString(Ext.Stats.Get(injury).DisplayName, injury))

				if injuryReport["injuryAppliedReason"][injury] then
					injuryReportGroup:AddText("Injury Applied Due To: " .. injuryReport["injuryAppliedReason"][injury])
					injuryReportGroup:AddNewLine()
				end

				injuryReportGroup:AddText("Severity: " .. injuryConfig.severity)
				injuryReportGroup:AddNewLine()

				local keepGroup = false

				--#region Damage Report
				local damageGroup = injuryReportGroup:AddGroup("Damage")
				if next(injuryConfig.damage["damage_types"]) then
					damageGroup:AddText("Damage Report")

					local totalDamage = 0
					for damageType, damageTypeConfig in pairs(injuryConfig.damage["damage_types"]) do
						local damageAmount = injuryReport["damage"][damageType]
						if damageAmount and damageAmount[injury] then
							local flatWithMultiplier = (damageAmount[injury] * damageTypeConfig["multiplier"]) * characterMultiplier
							-- Rounding to 2 digits
							totalDamage = totalDamage + flatWithMultiplier
							damageGroup:AddText(string.format("%s: Multiplier: %d%% | Flat Damage Before Multiplier: %s | Flat Damage After Multiplier: %s",
								damageType,
								damageTypeConfig["multiplier"] * 100,
								damageAmount[injury],
								flatWithMultiplier))
						end
					end

					if totalDamage == 0 then
						damageGroup:Destroy()
					else
						damageGroup:AddText(string.format("Total Injury Damage in %% of Health / Threshold %%: %.2f%%/%.2f%% ",
							((totalDamage / entity.Health.MaxHp) * 100),
							injuryConfig.damage["threshold"]))

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
							totalRounds = totalRounds + ((numRoundsApplied[injury] * statusConfig["multiplier"]) * characterMultiplier)
							statusGroup:AddText(string.format("%s: Multiplier: %s | Number of (Non-Consecutive) Rounds Applied After Multiplier: %s",
								status,
								statusConfig["multiplier"],
								(numRoundsApplied[injury] * statusConfig["multiplier"]) * characterMultiplier))
						end
					end

					if totalRounds == 0 then
						statusGroup:Destroy()
					else
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

	local moreInfo = reportWindow:AddImageButton("More Info", "GenericIcon_Intent_Utility", { 30, 30 })
	local tooltip = moreInfo:Tooltip()
	tooltip:AddText("Reports for each injury will stop updating once an injury is applied, but will remain for transparency.")
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

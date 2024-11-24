InjuryReport = {}

Ext.Vars.RegisterUserVariable("Injuries_Damage", {
	Server = true,
	Client = true,
	SyncToClient = true
})

Ext.Vars.RegisterUserVariable("Injuries_ApplyOnStatus", {
	Server = true,
	Client = true,
	SyncToClient = true
})

Ext.Vars.RegisterModVariable(ModuleUUID, "Injury_Report", {
	Server = true,
	Client = true,
	WriteableOnServer = true,
	WriteableOnClient = true,
	SyncToClient = true,
	SyncToServer = true
})

---@class InjuryReport
local injuryReportClass = {
	---@type {[StatusName] : integer}
	["applyOnStatus"] = {},
	---@type {[DamageType] : number}
	["damage"] = {}
}

---@type { [GUIDSTRING] : InjuryReport }
local entityInjuriesReport = {}

--- @type ExtuiWindow
local reportWindow

---@param character GUIDSTRING
local function BuildReport()
	if reportWindow then
		for _, child in pairs(reportWindow.Children) do
			if child.UserData and not entityInjuriesReport[child.UserData] then
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
				charReport = reportWindow:AddCollapsingHeader(entity.CustomName and entity.CustomName.Name or entity.DisplayName.NameKey:Get())
				charReport.UserData = character
			end

			for _, child in pairs(charReport.Children) do
				child:Destroy()
			end

			for injury, injuryConfig in pairs(ConfigurationStructure.config.injuries.injury_specific) do
				local injuryReportGroup = charReport:AddGroup(injury)
				injuryReportGroup:AddSeparatorText(Ext.Loca.GetTranslatedString(Ext.Stats.Get(injury).DisplayName, injury))

				local keepGroup = false

				--#region Damage Report
				local damageGroup = injuryReportGroup:AddGroup("Damage")
				if next(injuryReport["damage"]) then
					if next(injuryConfig.damage["damage_types"]) then
						damageGroup:AddText("Damage Report")
						damageGroup:AddText("Health Threshold: " .. injuryConfig.damage["threshold"] .. "%")

						local totalDamage = 0
						for damageType, damageTypeConfig in pairs(injuryConfig.damage["damage_types"]) do
							local damageAmount = injuryReport["damage"][damageType]
							if damageAmount then
								local flatWithMultiplier = damageAmount * damageTypeConfig["multiplier"]
								-- Rounding to 2 digits
								totalDamage = totalDamage + flatWithMultiplier
								damageGroup:AddText(string.format("%s: Multiplier: %d%% | Flat Damage Before Multiplier: %s | Flat Damage After Multiplier: %s",
									damageType,
									damageTypeConfig["multiplier"] * 100,
									damageAmount,
									flatWithMultiplier))
							end
						end

						if totalDamage == 0 then
							damageGroup:Destroy()
						else
							damageGroup:AddText(string.format("Total Injury Damge in %% of Health: %.2f%%",
								((totalDamage / entity.Health.MaxHp) * 100)))
							keepGroup = true
						end
					end
				end
				--#endregion

				--#region ApplyOnStatus report
				if next(injuryReport["applyOnStatus"]) then
					if next(injuryConfig.apply_on_status) then
						local statusGroup = injuryReportGroup:AddGroup("ApplyOnStatus")
						if keepGroup then
							statusGroup:AddNewLine()
						end
						statusGroup:AddText("Apply On Status Report")

						local statusesFound = false

						for status, statusConfig in pairs(injuryConfig.apply_on_status) do
							local numRoundsApplied = injuryReport["applyOnStatus"][status]
							if numRoundsApplied then
								statusesFound = true
								statusGroup:AddText(string.format("%s: Number of (Non-Consecutive) Rounds Applied: %s | Number Of Rounds Required: %s",
									status,
									numRoundsApplied,
									statusConfig["number_of_rounds"]))
							end
						end

						if not statusesFound then
							statusGroup:Destroy()
						else
							keepGroup = true
						end
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
	--- @type EntityHandle
	local entity = Ext.Entity.Get(character)
	character = entity.Uuid.EntityUuid
	local entityVars = entity.Vars

	entityInjuriesReport = Ext.Vars.GetModVariables(ModuleUUID).Injury_Report or {}

	if not entityVars.Injuries_Damage and not entityVars.Injuries_ApplyOnStatus then
		entityInjuriesReport[character] = nil
	else
		entityInjuriesReport[character] = TableUtils:DeeplyCopyTable(injuryReportClass)
		entityInjuriesReport[character]["damage"] = entityVars.Injuries_Damage or {}
		entityInjuriesReport[character]["applyOnStatus"] = entityVars.Injuries_ApplyOnStatus or {}
	end

	Ext.Vars.GetModVariables(ModuleUUID).Injury_Report = entityInjuriesReport
	BuildReport()
end)

function InjuryReport:BuildReportWindow()
	reportWindow = Ext.IMGUI.NewWindow("Viewing Live Injury Report")
	reportWindow.Closeable = true
	reportWindow.HorizontalScrollbar = true
	-- reportPopup.AlwaysAutoResize = true

	entityInjuriesReport = Ext.Vars.GetModVariables(ModuleUUID).Injury_Report or {}
	Ext.Vars.GetModVariables(ModuleUUID).Injury_Report = entityInjuriesReport

	BuildReport()
end

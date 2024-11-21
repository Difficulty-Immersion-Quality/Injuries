Ext.Vars.RegisterUserVariable("Injuries_Damage", {
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

InjuryReport = {}

---@type { [GUIDSTRING] : { [DamageType] : { [string] : number } } }
local entityInjuriesDamageReport = {}

--- @type ExtuiCollapsingHeader|nil
local partySection

local function BuildReport()
	if partySection then
		for _, child in pairs(partySection.Children) do
			partySection:RemoveChild(child)
		end

		for entityUuid, existingInjuryDamage in pairs(entityInjuriesDamageReport) do
			if not next(existingInjuryDamage) then
				goto continue
			end

			---@type EntityHandle
			local entity = Ext.Entity.Get(entityUuid)
			if entity.PartyMember then
				local partyHeader = partySection:AddCollapsingHeader(entity.CustomName.Name)
				for injury, damageConfig in pairs(ConfigurationStructure.config.injuries.injury_specific) do
					if next(damageConfig.damage["damage_types"]) then
						local seperator = partyHeader:AddSeparatorText(Ext.Loca.GetTranslatedString(Ext.Stats.Get(injury).DisplayName, injury))
						local thresholdText = partyHeader:AddText("Health Threshold: " .. damageConfig.damage["threshold"] .. "%")
						local foundDamage = false
						for damageType, damageTypeConfig in pairs(damageConfig.damage["damage_types"]) do
							local damageTable = existingInjuryDamage[damageType]
							if damageTable and next(damageTable) then
								local flatWithMultiplier = damageTable["flat"] * damageTypeConfig["multiplier"]
								-- Rounding to 2 digits
								local healthPercentage = (flatWithMultiplier / entity.Health.MaxHp) * 100
								partyHeader:AddText(string.format("%s: Multiplier: %d%% | Flat Damage Before Multiplier: %s | Damage in %% of Total Health After Multiplier: %.2f%%",
									damageType,
									damageTypeConfig["multiplier"] * 100,
									damageTable["flat"],
									healthPercentage))

								foundDamage = true
							end
						end

						if not foundDamage then
							seperator:Destroy()
							thresholdText:Destroy()
						end
					end
				end
			end
			::continue::
		end
	end
end

Ext.RegisterNetListener(ModuleUUID .. "_Injury_Damage_Updated", function(channel, entity, user)
	entity = Ext.Entity.Get(entity)

	entityInjuriesDamageReport = Ext.Vars.GetModVariables(ModuleUUID).Injury_Report

	if entity.Vars.Injuries_Damage then
		entityInjuriesDamageReport[entity.Uuid.EntityUuid] = entity.Vars.Injuries_Damage
	else
		entityInjuriesDamageReport[entity.Uuid.EntityUuid] = nil
	end

	table.sort(entityInjuriesDamageReport)

	Ext.Vars.GetModVariables(ModuleUUID).Injury_Report = entityInjuriesDamageReport

	BuildReport()
end)


function InjuryReport:BuildReportWindow()
	local reportPopup = Ext.IMGUI.NewWindow("Viewing Live Injury Report")
	reportPopup.Closeable = true
	reportPopup.HorizontalScrollbar = true
	-- reportPopup.AlwaysAutoResize = true

	partySection = reportPopup:AddCollapsingHeader("Party Members")
	partySection.DefaultOpen = true

	reportPopup.OnClose = function()
		partySection:Destroy()
		partySection = nil
	end

	entityInjuriesDamageReport = Ext.Vars.GetModVariables(ModuleUUID).Injury_Report

	BuildReport()
end

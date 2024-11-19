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
			---@type EntityHandle
			local entity = Ext.Entity.Get(entityUuid)
			if entity.PartyMember then
				local partyHeader = partySection:AddCollapsingHeader(entity.CustomName.Name)
				for damageType, damageTable in pairs(existingInjuryDamage) do
					partyHeader:AddSeparatorText(damageType .. ": " .. damageTable["percentage"] .. "%")
					for injury, damageConfg in pairs(ConfigurationStructure.config.injuries.injury_specific) do
						for applicableDamageType, damageTypeConfig in pairs(damageConfg.damage) do
							if damageType == applicableDamageType then
								partyHeader:AddText(injury .. ": " .. damageTable["percentage"] .. "%/" .. damageTypeConfig["health_threshold"] .. "%")
							end
						end
					end
				end
			end
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

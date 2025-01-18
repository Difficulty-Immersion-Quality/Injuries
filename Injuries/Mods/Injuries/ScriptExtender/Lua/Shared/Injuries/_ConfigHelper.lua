-- Synced to Client/Injuries/InjuryReport
Ext.Vars.RegisterUserVariable("Goon_Injuries", {
	Server = true,
	Client = true,
	SyncToClient = true,
	SyncOnWrite = true -- if this is false, the injuryReport lags by 1 calculation
})

-- Want to make sure that an injury isn't reapplied on the next damage/status tick after it's
-- removed, so we need to track each counter separately for each injury so they can be reset independently
---@class InjuryVar
local injuryVar = {
	---@type {[DamageType] : {[InjuryName] : number }}
	["damage"] = {},
	---@type {[StatusName] : {[InjuryName] : number }}
	["applyOnStatus"] = {},
	---@type {[InjuryName] : string}
	["injuryAppliedReason"] = {},
}

InjuryConfigHelper = {}

--- Returns the npcType just for the InjuryReport, so we know if the character even has a multiplier available instead of
--- defaulting in the absence of one
---@param character EntityHandle
---@return number, string?
function InjuryConfigHelper:CalculateNpcMultiplier(character)
	local xpReward = Ext.Stats.Get(character.Data.StatsId).XPReward
	if character.PartyMember or not xpReward then
		return 1
	else
		local xpCategory = Ext.StaticData.Get(xpReward, "ExperienceReward").Name

		local config
		if Ext.IsServer() then
			config = ConfigManager.ConfigCopy
		else
			config = ConfigurationStructure.config
		end
		config = config.injuries.universal

		local lowerCat = string.lower(xpCategory)
		for npcType, multiplier in pairs(config.npc_multipliers) do
			npcType = string.lower(npcType)

			-- Some mods use custom categories, like MMM using MMM_{type}, so need to try to account for those. Hopefully they all use `_`
			if lowerCat == npcType or string.find(lowerCat, "_" .. npcType .. "$") then
				return multiplier, xpCategory
			end
		end

		return config.npc_multipliers["Base"], xpCategory .. " (Base Multiplier)"
	end
end

---@param character EntityHandle
---@param injuryConfig Injury
function InjuryConfigHelper:CalculateCharacterMultipliers(character, injuryConfig)
	local finalMultiplier = 1

	if injuryConfig.character_multipliers["races"][character.Race.Race] then
		finalMultiplier = finalMultiplier * injuryConfig.character_multipliers["races"][character.Race.Race]
	end

	for _, tagUUID in pairs(character.Tag.Tags) do
		if injuryConfig.character_multipliers["tags"][tagUUID] then
			finalMultiplier = finalMultiplier * injuryConfig.character_multipliers["tags"][tagUUID]
		end
	end

	return finalMultiplier
end

if Ext.IsServer() then
	---@param character GUIDSTRING
	---@return boolean
	function InjuryConfigHelper:IsEligible(character)
		local reset = ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset
		if (reset ~= "Short Rest" and reset ~= "Long Rest") and Osi.IsInCombat(character) == 0 then
			return false
		end

		local eligibleGroups = ConfigManager.ConfigCopy.injuries.universal.who_can_receive_injuries
		if (eligibleGroups["Allies"] and Osi.IsAlly(Osi.GetHostCharacter(), character) == 1)
			or (eligibleGroups["Party Members"] and Osi.IsPartyMember(character, 1) == 1)
			or (eligibleGroups["Enemies"] and Osi.IsEnemy(Osi.GetHostCharacter(), character) == 1)
		then
			if Osi.HasPassive(character, "Goon_Damage_Detect") == 0 then
				Osi.AddPassive(character, "Goon_Damage_Detect")
			end

			if Osi.HasPassive(character, "Goon_Attack_Detect") == 0 then
				Osi.AddPassive(character, "Goon_Attack_Detect")
			end

			return true
		else
			return false
		end
	end

	---@param character GUIDSTRING
	---@return EntityHandle, InjuryVar
	function InjuryConfigHelper:GetUserVar(character)
		local entity = Ext.Entity.Get(character)

		if not entity.Vars.Goon_Injuries then
			return entity, TableUtils:DeeplyCopyTable(injuryVar)
		else
			return entity, entity.Vars.Goon_Injuries
		end
	end

	--- @param character EntityHandle
	--- @param injuryVar InjuryVar?
	function InjuryConfigHelper:UpdateUserVar(character, injuryVar)
		local counter_reset = ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset
		if counter_reset == "Attack/Tick" then
			character.Vars.Goon_Injuries = nil
		else
			character.Vars.Goon_Injuries = injuryVar

			if counter_reset == "Round" and Osi.IsInCombat(character.Uuid.EntityUuid) == 0 then
				Ext.Timer.WaitFor(6000, function()
					character.Vars.Goon_Injuries = nil
					Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", character.Uuid.EntityUuid)
				end)
			end
		end

		Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", character.Uuid.EntityUuid)
	end

	--- If an eligible injury shares a stack with an applied injury, and is not the next injury in the stack, find the injury with the next
	--- highest stackPriority (of the applied injury)
	---@param character GUIDSTRING
	---@param injury InjuryName
	function InjuryConfigHelper:GetNextInjuryInStackIfApplicable(character, injury)
		---@type StatusData
		local injuryEntry = Ext.Stats.Get(injury)
		if injuryEntry.StackId and injuryEntry.StackPriority then
			---@type EntityHandle
			local entity = Ext.Entity.Get(character)

			for _, existingStatusName in pairs(entity.StatusContainer.Statuses) do
				---@type StatusData
				local existingInjuryEntry = Ext.Stats.Get(existingStatusName)
				if existingInjuryEntry
					and injuryEntry.StackId == existingInjuryEntry.StackId
					and tonumber(injuryEntry.StackPriority) <= tonumber(existingInjuryEntry.StackPriority)
				then
					for configuredInjuryName, _ in pairs(ConfigManager.ConfigCopy.injuries.injury_specific) do
						---@type StatusData
						local configuredInjuryEntry = Ext.Stats.Get(configuredInjuryName)

						if existingInjuryEntry.StackId == configuredInjuryEntry.StackId
							and (tonumber(existingInjuryEntry.StackPriority) + 1) == tonumber(configuredInjuryEntry.StackPriority)
						then
							Logger:BasicDebug("Original injury %s was upgraded to %s due to stack logic", injury, configuredInjuryName)
							return configuredInjuryName
						end
					end
				end
			end
		end

		return injury
	end

	local function RemoveTrackers(character)
		if Osi.HasPassive(character, "Goon_Damage_Detect") == 1 then
			Osi.RemovePassive(character, "Goon_Damage_Detect")
		end

		if Osi.HasPassive(character, "Goon_Attack_Detect") == 1 then
			Osi.RemovePassive(character, "Goon_Attack_Detect")
		end
	end

	local function ResetCounters(character, entityVar)
		---@type InjuryVar
		local injuryUserVar = entityVar.Goon_Injuries

		for damageType, injuryTable in pairs(injuryUserVar["damage"]) do
			for injury, _ in pairs(injuryTable) do
				if not injuryUserVar["injuryAppliedReason"][injury] then
					injuryTable[injury] = nil
				end
			end

			if not next(injuryTable) then
				injuryUserVar["damage"][damageType] = nil
			end
		end

		for statusName, injuryTable in pairs(injuryUserVar["applyOnStatus"]) do
			for injury, _ in pairs(injuryTable) do
				if not injuryUserVar["injuryAppliedReason"][injury] then
					injuryTable[injury] = nil
				end
			end

			if not next(injuryTable) then
				injuryUserVar["applyOnStatus"][statusName] = nil
			end
		end

		entityVar.Goon_Injuries = injuryUserVar

		RemoveTrackers(character)

		Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", character)
	end

	EventCoordinator:RegisterEventProcessor("CombatRoundStarted", function(combatGuid, round)
		if ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Round" then
			for _, combatParticipant in pairs(Osi.DB_Is_InCombat:Get(nil, combatGuid)) do
				local entity = Ext.Entity.Get(combatParticipant[1])
				if entity.Vars.Goon_Injuries then
					ResetCounters(combatParticipant[1], entity.Vars)
				end
			end
		end
	end)

	EventCoordinator:RegisterEventProcessor("LeftCombat", function(object, combatGuid)
		local entity = Ext.Entity.Get(object)
		if entity.Vars.Goon_Injuries and ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Combat" then
			ResetCounters(object, entity.Vars)
		end
	end)

	EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
		if Osi.IsItem(character) == 0 then
			local counterReset = ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset
			if (status == "SHORT_REST" and counterReset == "Short Rest") or (status == "LONG_REST" and counterReset == "Long Rest") then
				local entity = Ext.Entity.Get(character)
				if entity.Vars.Goon_Injuries then
					ResetCounters(character, entity.Vars)
				end
			end
		end
	end)

	function InjuryConfigHelper:RemoveAllInjuries(character)
		local entity, _ = InjuryConfigHelper:GetUserVar(character)
		for injury, _ in pairs(ConfigManager.ConfigCopy.injuries.injury_specific) do
			Osi.RemoveStatus(character, injury)
		end

		entity.Vars.Goon_Injuries = nil
		RemoveTrackers(character)

		Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", character)
	end

	Ext.Osiris.RegisterListener("Died", 1, "after", function(character)
		if ConfigManager.ConfigCopy.injuries.universal.remove_on_death then
			InjuryConfigHelper:RemoveAllInjuries(character)
		end
	end)

	Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(character, status, causee, applyStoryActionID)
		if Osi.IsItem(character) == 0 then
			local entity, injuryUserVar = InjuryConfigHelper:GetUserVar(character)

			if injuryUserVar["injuryAppliedReason"][status] then
				for damageType, injuryTable in pairs(injuryUserVar["damage"]) do
					injuryTable[status] = nil
					if not next(injuryTable) then
						injuryUserVar["damage"][damageType] = nil
					end
				end

				for statusName, injuryTable in pairs(injuryUserVar["applyOnStatus"]) do
					injuryTable[status] = nil
					if not next(injuryTable) then
						injuryUserVar["applyOnStatus"][statusName] = nil
					end
				end

				injuryUserVar["injuryAppliedReason"][status] = nil

				if not next(injuryUserVar["injuryAppliedReason"])
					and not next(injuryUserVar["damage"])
					and not next(injuryUserVar["applyOnStatus"])
				then
					injuryUserVar = nil

					RemoveTrackers(character)
				end

				entity.Vars.Goon_Injuries = injuryUserVar

				Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", character)
			end
		end
	end)
end

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
	---@type {[DamageType] : {[InjuryName] : number }}
	["stack_reapply_damage"] = {},
	---@type {[StatusName] : {[InjuryName] : number }}
	["applyOnStatus"] = {},
	---@type {[StatusName] : {[InjuryName] : number }}
	["stack_reapply_status"] = {},
	---@type {[InjuryName] : string}
	["injuryAppliedReason"] = {},
	---@type {[InjuryName] : number}
	["numberOfApplicationsAttempted"] = {},
	---@type {[InjuryName] : number|"Skipped Because of Total Injury Limit"|"Skipped Because of Severity Injury Limit"}
	["applicationChance"] = {},
	---@type {[InjuryName] : string}
	["removedDueTo"] = {},
	---@type {[InjuryName] : number}
	["numberOfLongRests"] = {},
}

InjuryCommonLogic = {}

--- Returns the npcType just for the InjuryReport, so we know if the character even has a multiplier available instead of
--- defaulting in the absence of one
---@param character EntityHandle
---@param injuryName InjuryName?
---@return number, string?
function InjuryCommonLogic:CalculateNpcMultiplier(character, injuryName)
	if not character or not character.Data then
		return 1
	end

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

		local function determineMultiplier(localconfig)
			local lowerCat = string.lower(xpCategory)
			for npcType, multiplier in pairs(localconfig.npc_multipliers) do
				npcType = string.lower(npcType)

				-- Some mods use custom categories, like MMM using MMM_{type}, so need to try to account for those. Hopefully they all use `_`
				if lowerCat == npcType or string.find(lowerCat, "_" .. npcType .. "$") then
					return multiplier
				end
			end
		end

		if injuryName
			and config.injuries.injury_specific[injuryName].character_multipliers
			and config.injuries.injury_specific[injuryName].character_multipliers["npc_multipliers"]
		then
			local multiplier = determineMultiplier(config.injuries.injury_specific[injuryName].character_multipliers)
			if multiplier then
				return multiplier, xpCategory .. " (Injury Override)"
			end
		end

		local multiplier = determineMultiplier(config.injuries.universal)
		if multiplier then
			return multiplier, xpCategory
		end

		return config.injuries.universal.npc_multipliers["Base"], xpCategory .. " (Base Multiplier)"
	end
end

---@param character EntityHandle
---@param injuryConfig Injury
function InjuryCommonLogic:CalculateCharacterMultipliers(character, injuryConfig)
	local finalMultiplier = 1

	if injuryConfig.character_multipliers and injuryConfig.character_multipliers["races"] and injuryConfig.character_multipliers["races"][character.Race.Race] then
		finalMultiplier = finalMultiplier * injuryConfig.character_multipliers["races"][character.Race.Race]
	end

	if injuryConfig.character_multipliers and injuryConfig.character_multipliers["tags"] then
		for _, tagUUID in pairs(character.Tag.Tags) do
			if injuryConfig.character_multipliers["tags"][tagUUID] then
				finalMultiplier = finalMultiplier * injuryConfig.character_multipliers["tags"][tagUUID]
			end
		end
	end

	return finalMultiplier
end

if Ext.IsServer() then
	Ext.Require("Server/Injuries/_LongRestProcessor.lua")

	---@param character GUIDSTRING
	---@return boolean
	function InjuryCommonLogic:IsEligible(character)
		if not ConfigManager.ConfigCopy.injuries then
			return false
		end

		if Osi.IsItem(character) == 1
			or Osi.Exists(character) == 0
			or Osi.IsDead(character) == 1
			or (not ConfigManager.ConfigCopy.injuries.universal.apply_injuries_outside_combat and Osi.IsInCombat(character) == 0)
		then
			return false
		end

		---@type EntityHandle
		local entity = Ext.Entity.Get(character)
		for _, tag in ipairs(entity.Tag.Tags) do
			if string.find(Ext.StaticData.Get(tag, "Tag").Name, "WPN_") then
				return false
			end
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

			if Osi.HasPassive(character, "Goon_Exhaustion_Detect_Critical_Threshold_Reduction") == 0 then
				Osi.AddPassive(character, "Goon_Exhaustion_Detect_Critical_Threshold_Reduction")
			end

			return true
		else
			return false
		end
	end

	---@param character GUIDSTRING
	---@return EntityHandle?, InjuryVar?
	function InjuryCommonLogic:GetUserVar(character)
		local entity = Ext.Entity.Get(character)

		if entity then
			if not entity.Vars.Goon_Injuries then
				return entity, TableUtils:DeeplyCopyTable(injuryVar)
			else
				for key in pairs(injuryVar) do
					if not entity.Vars.Goon_Injuries[key] then
						entity.Vars.Goon_Injuries[key] = {}
					end
				end
				return entity, entity.Vars.Goon_Injuries
			end
		end
	end

	--- @param character EntityHandle
	--- @param injuryVar InjuryVar?
	function InjuryCommonLogic:UpdateUserVar(character, injuryVar)
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

	Ext.Osiris.RegisterListener("DownedChanged", 2, "after", function(character, isDowned)
		if isDowned == 1 then
			Osi.ApplyStatus(character, "GOON_DOWNED_TRACKER", 1)
		end
	end)

	---@param injuryName InjuryName
	---@param existingInjuryVar InjuryVar
	---@param status string?
	---@param character CHARACTER
	---@param modifiers InjuryApplicationChanceModifiers[]?
	---@param appliedInjuriesTracker {string : InjuryName[]}
	function InjuryCommonLogic:RollForApplication(injuryName, existingInjuryVar, status, character, modifiers, appliedInjuriesTracker)
		local injuryConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injuryName]
		local limitConfig = ConfigManager.ConfigCopy.injuries.universal.injury_limit_per_event

		if appliedInjuriesTracker[injuryConfig.severity] and #appliedInjuriesTracker[injuryConfig.severity] >= limitConfig[injuryConfig.severity] then
			Logger:BasicDebug("Will not apply %s on %s due to exceeding %s injury limit of %s", injuryName, character, injuryConfig.severity, limitConfig[injuryConfig.severity])
			if not existingInjuryVar["applicationChance"] then
				existingInjuryVar["applicationChance"] = {}
			end
			existingInjuryVar["applicationChance"][injuryName] = "Skipped Because of Severity Injury Limit"
			return
		elseif appliedInjuriesTracker["Total"] and appliedInjuriesTracker["Total"] >= limitConfig["Base"] then
			Logger:BasicDebug("Will not apply %s on %s due to exceeding total injury limit of %s", injuryName, character, limitConfig["Base"])
			if not existingInjuryVar["applicationChance"] then
				existingInjuryVar["applicationChance"] = {}
			end
			existingInjuryVar["applicationChance"][injuryName] = "Skipped Because of Total Injury Limit"
			return
		end

		local applicationChanceConfig = ConfigManager.ConfigCopy.injuries.universal.application_chance_by_severity

		---@type number?
		local chanceOfApplication = applicationChanceConfig[injuryConfig.severity]
		if not chanceOfApplication then
			return false
		end

		if Osi.HasActiveStatus(character, "GOON_DOWNED_TRACKER") == 1 then
			modifiers = modifiers and TableUtils:DeeplyCopyTable(modifiers) or {}
			table.insert(modifiers, "Was Downed This Round")
		end

		if modifiers then
			for _, modifier in pairs(modifiers) do
				chanceOfApplication = chanceOfApplication + applicationChanceConfig.modifiers[modifier]
				Logger:BasicDebug("Adding %s%% application chance due to %s being applicable to %s (for injury %s) - result is %s%%",
					applicationChanceConfig.modifiers[modifier],
					modifier,
					character,
					injuryName,
					chanceOfApplication)
			end
		end

		if applicationChanceConfig.modifiers["Each Existing Injury Of Same Severity"] ~= 0 then
			for injury in pairs(existingInjuryVar["injuryAppliedReason"]) do
				if ConfigManager.ConfigCopy.injuries.injury_specific[injury] and ConfigManager.ConfigCopy.injuries.injury_specific[injury].severity == injuryConfig.severity then
					chanceOfApplication = chanceOfApplication + applicationChanceConfig.modifiers["Each Existing Injury Of Same Severity"]
				end
			end
		end

		Logger:BasicDebug("Final application chance is %s for %s on %s", chanceOfApplication, injuryName, character)

		if not existingInjuryVar["applicationChance"] then
			existingInjuryVar["applicationChance"] = {}
		end
		existingInjuryVar["applicationChance"][injuryName] = chanceOfApplication

		if chanceOfApplication == 100
			or ((status and injuryConfig.apply_on_status["applicable_statuses"] and injuryConfig.apply_on_status["applicable_statuses"][status]) and injuryConfig.apply_on_status["applicable_statuses"][status]["guarantee_application"])
		then
			if not appliedInjuriesTracker[injuryConfig.severity] then
				appliedInjuriesTracker[injuryConfig.severity] = {}
			end
			table.insert(appliedInjuriesTracker[injuryConfig.severity], injuryName)
			appliedInjuriesTracker["Total"] = (appliedInjuriesTracker["Total"] or 0) + 1
			return true
		elseif chanceOfApplication <= 0 then
			return false
		end

		if not existingInjuryVar["numberOfApplicationsAttempted"] then
			existingInjuryVar["numberOfApplicationsAttempted"] = {}
		end

		existingInjuryVar["numberOfApplicationsAttempted"][injuryName] = (existingInjuryVar["numberOfApplicationsAttempted"][injuryName] or 0) + 1

		local randomNumber = Osi.Random(100) + 1

		if randomNumber <= chanceOfApplication then
			if not appliedInjuriesTracker[injuryConfig.severity] then
				appliedInjuriesTracker[injuryConfig.severity] = {}
			end
			table.insert(appliedInjuriesTracker[injuryConfig.severity], injuryName)
			appliedInjuriesTracker["Total"] = (appliedInjuriesTracker["Total"] or 0) + 1
			return true
		else
			return false
		end
	end

	--- If an eligible injury shares a stack with an applied injury, and is not the next injury in the stack, find the injury with the next
	--- highest stackPriority (of the applied injury)
	---@param character GUIDSTRING
	---@param injury InjuryName?
	function InjuryCommonLogic:GetNextInjuryInStackIfApplicable(character, injury)
		local _, injuryVarOnChar = InjuryCommonLogic:GetUserVar(character)
		if not injuryVarOnChar then
			return
		end

		---@type StatusData
		local injuryEntry = Ext.Stats.Get(injury)
		if injuryEntry.StackId and injuryEntry.StackPriority then
			---@type EntityHandle
			local entity = Ext.Entity.Get(character)

			for existingInjury, _ in pairs(injuryVarOnChar["injuryAppliedReason"]) do
				---@type StatusData
				local existingInjuryEntry = Ext.Stats.Get(existingInjury)
				if existingInjuryEntry
					and injuryEntry.StackId == existingInjuryEntry.StackId
					and tonumber(injuryEntry.StackPriority) <= tonumber(existingInjuryEntry.StackPriority)
				then
					for configuredInjuryName, _ in pairs(ConfigManager.ConfigCopy.injuries.injury_specific) do
						---@type StatusData
						local configuredInjuryEntry = Ext.Stats.Get(configuredInjuryName)

						if configuredInjuryEntry
							and existingInjuryEntry.StackId == configuredInjuryEntry.StackId
							and (tonumber(existingInjuryEntry.StackPriority) + 1) == tonumber(configuredInjuryEntry.StackPriority)
						then
							Logger:BasicDebug("Original injury %s was upgraded to %s due to stack logic", injury, configuredInjuryName)
							return configuredInjuryName
						end
					end
					Logger:BasicDebug("%s has reached the highest stack on %s, will be skipped", injury, character)
					-- If we're at the highest stack, don't bother continuing
					return nil
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

		if Osi.HasPassive(character, "Goon_Exhaustion_Detect_Critical_Threshold_Reduction") == 1 then
			Osi.RemovePassive(character, "Goon_Exhaustion_Detect_Critical_Threshold_Reduction")
		end
	end

	function InjuryCommonLogic:ResetCounters(character, entityVar)
		---@type InjuryVar
		local injuryUserVar = entityVar.Goon_Injuries
		if not injuryUserVar then
			return
		end

		for injury in pairs(injuryUserVar["injuryAppliedReason"]) do
			if not ConfigManager.ConfigCopy.injuries.injury_specific[injury] and Osi.HasActiveStatus(character, injury) == 1 then
				Logger:BasicWarning("%s had %s applied through Injuries, but it no longer exists in the config - removing from the character!", character, injury)
				Osi.RemoveStatus(character, injury)
				injuryUserVar["injuryAppliedReason"][injury] = nil
			end
		end

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

		for damageType, injuryTable in pairs(injuryUserVar["stack_reapply_damage"]) do
			for injury, _ in pairs(injuryTable) do
				if not injuryUserVar["injuryAppliedReason"][injury] then
					injuryTable[injury] = nil
				end
			end

			if not next(injuryTable) then
				injuryUserVar["stack_reapply_damage"][damageType] = nil
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

		for statusName, injuryTable in pairs(injuryUserVar["stack_reapply_status"]) do
			for injury, _ in pairs(injuryTable) do
				if not injuryUserVar["injuryAppliedReason"][injury] then
					injuryTable[injury] = nil
				end
			end

			if not next(injuryTable) then
				injuryUserVar["stack_reapply_status"][statusName] = nil
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
					InjuryCommonLogic:ResetCounters(combatParticipant[1], entity.Vars)
				end
			end
		end
	end)

	EventCoordinator:RegisterEventProcessor("LeftCombat", function(object, combatGuid)
		local entity = Ext.Entity.Get(object)
		if entity.Vars.Goon_Injuries and ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Combat" then
			InjuryCommonLogic:ResetCounters(object, entity.Vars)
		end
	end)

	EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
		if Osi.IsItem(character) == 0 then
			local counterReset = ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset
			if (status == "SHORT_REST" and counterReset == "Short Rest") or (status == "LONG_REST" and counterReset == "Long Rest") then
				local entity = Ext.Entity.Get(character)
				if entity.Vars.Goon_Injuries then
					InjuryCommonLogic:ResetCounters(character, entity.Vars)
				end
			end
		end
	end)

	function InjuryCommonLogic:RemoveAllInjuries(character)
		local entity, _ = InjuryCommonLogic:GetUserVar(character)
		if entity then
			for injury, _ in pairs(ConfigManager.ConfigCopy.injuries.injury_specific) do
				Osi.RemoveStatus(character, injury)
			end

			entity.Vars.Goon_Injuries = nil
			RemoveTrackers(character)

			Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", character)
		end
	end

	Ext.Osiris.RegisterListener("Died", 1, "after", function(character)
		if ConfigManager.ConfigCopy.injuries.universal.remove_on_death then
			InjuryCommonLogic:RemoveAllInjuries(character)
		end
	end)

	Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(character, injury, causee, applyStoryActionID)
		if Osi.IsItem(character) == 0 then
			local entity, injuryUserVar = InjuryCommonLogic:GetUserVar(character)

			if entity
				and injuryUserVar
				and injuryUserVar["injuryAppliedReason"]
				and injuryUserVar["injuryAppliedReason"][injury]
			then
				local injuryToMoveTo
				if Osi.IsDead(character) == 0 and injuryUserVar["removedDueTo"][injury] then
					local statusRemovingInjury = injuryUserVar["removedDueTo"][injury]
					local removeOnStatusConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury].remove_on_status[statusRemovingInjury]
					if not removeOnStatusConfig then
						---@type StatusData
						local statusData = Ext.Stats.Get(statusRemovingInjury)
						if statusData and next(statusData.StatusGroups) then
							for _, statusGroup in ipairs(statusData.StatusGroups) do
								local sgConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury].remove_on_status[statusGroup]
								if sgConfig and (not sgConfig["excluded_statuses"] or not TableUtils:ListContains(sgConfig["excluded_statuses"], statusRemovingInjury)) then
									removeOnStatusConfig = sgConfig
									Logger:BasicDebug("%s was removed from %s due to %s belonging to %s", injury, character, statusRemovingInjury, statusGroup)
								end
							end
						end
					end

					local stacksToRemove = removeOnStatusConfig.stacks_to_remove
					if stacksToRemove then
						---@type StatusData
						local injuryStat = Ext.Stats.Get(injury)

						if stacksToRemove < injuryStat.StackPriority then
							for otherInjury in pairs(ConfigManager.ConfigCopy.injuries.injury_specific) do
								---@type StatusData
								local otherInjuryStat = Ext.Stats.Get(otherInjury)
								if otherInjuryStat.StackId == injuryStat.StackId then
									if injuryUserVar["injuryAppliedReason"][otherInjury] and otherInjuryStat.StackPriority > injuryStat.StackPriority then
										injuryToMoveTo = nil
										break
									end

									if otherInjuryStat.StackPriority == (injuryStat.StackPriority - stacksToRemove) then
										injuryToMoveTo = otherInjury
										Osi.ApplyStatus(character, injuryToMoveTo, -1, 1)
										injuryUserVar["injuryAppliedReason"][injuryToMoveTo] = "Removal of " .. (Ext.Loca.GetTranslatedString(injuryStat.DisplayName, injury))
									end
								end
							end
						end
					end
				end

				for damageType, injuryTable in pairs(injuryUserVar["damage"]) do
					if injuryToMoveTo then
						injuryTable[injuryToMoveTo] = injuryTable[injury]
					end
					injuryTable[injury] = nil
					if not next(injuryTable) then
						injuryUserVar["damage"][damageType] = nil
					end
				end

				for damageType, injuryTable in pairs(injuryUserVar["stack_reapply_damage"]) do
					if injuryToMoveTo then
						injuryTable[injuryToMoveTo] = injuryTable[injury]
					end
					injuryTable[injury] = nil
					if not next(injuryTable) then
						injuryUserVar["stack_reapply_damage"][damageType] = nil
					end
				end

				for statusName, injuryTable in pairs(injuryUserVar["applyOnStatus"]) do
					if injuryToMoveTo then
						injuryTable[injuryToMoveTo] = injuryTable[injury]
					end
					injuryTable[injury] = nil
					if not next(injuryTable) then
						injuryUserVar["applyOnStatus"][statusName] = nil
					end
				end

				for statusName, injuryTable in pairs(injuryUserVar["stack_reapply_status"]) do
					if injuryToMoveTo then
						injuryTable[injuryToMoveTo] = injuryTable[injury]
					end
					injuryTable[injury] = nil
					if not next(injuryTable) then
						injuryUserVar["stack_reapply_status"][statusName] = nil
					end
				end

				if injuryUserVar["numberOfApplicationsAttempted"] then
					injuryUserVar["numberOfApplicationsAttempted"][injury] = nil
				end

				if injuryUserVar["numberOfLongRests"] then
					injuryUserVar["numberOfLongRests"][injury] = nil
				end

				if injuryUserVar["removedDueTo"] then
					injuryUserVar["removedDueTo"][injury] = nil
				end

				injuryUserVar["injuryAppliedReason"][injury] = nil

				if not next(injuryUserVar["injuryAppliedReason"])
					and not next(injuryUserVar["damage"])
					and not next(injuryUserVar["stack_reapply_damage"])
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

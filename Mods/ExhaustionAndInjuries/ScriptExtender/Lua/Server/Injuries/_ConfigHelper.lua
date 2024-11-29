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
	["injuryAppliedReason"] = {}
}

InjuryConfigHelper = {}

---@param character GUIDSTRING
---@return boolean
function InjuryConfigHelper:IsEligible(character)
	local eligibleGroups = ConfigManager.ConfigCopy.injuries.universal.who_can_receive_injuries
	if (eligibleGroups["Allies"] and Osi.IsAlly(Osi.GetHostCharacter(), character) == 1)
		or (eligibleGroups["Party Members"] and Osi.IsPartyMember(character, 1) == 1)
		or (eligibleGroups["Enemies"] and Osi.IsEnemy(Osi.GetHostCharacter(), character) == 1)
	then
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
--- @param injuryVar InjuryVar
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

EventCoordinator:RegisterEventProcessor("CombatRoundStarted", function(combatGuid, round)
	if ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Round" then
		for _, combatParticipant in pairs(Osi.DB_Is_InCombat:Get(nil, combatGuid)) do
			local entity = Ext.Entity.Get(combatParticipant[1])
			if entity.Vars.Goon_Injuries then
				entity.Vars.Goon_Injuries = nil
				Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", combatParticipant[1])
			end
		end
	end
end)

EventCoordinator:RegisterEventProcessor("LeftCombat", function(object, combatGuid)
	if Ext.Entity.Get(object).Vars.Goon_Injuries and ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset == "Combat" then
		Ext.Entity.Get(object).Vars.Goon_Injuries = nil
		Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", object)
	end
end)

EventCoordinator:RegisterEventProcessor("StatusApplied", function (character, status, causee, storyActionID)
	local counterReset = ConfigManager.ConfigCopy.injuries.universal.when_does_counter_reset
	if (status == "SHORT_REST" and counterReset == "Short Rest") or (status == "LONG_REST" and counterReset == "Long Rest") then
		local entity = Ext.Entity.Get(character)
		if entity.Vars.Goon_Injuries then
			Ext.Entity.Get(character).Vars.Goon_Injuries = nil
			Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", character)
		end
	end
end)

Ext.Osiris.RegisterListener("KilledBy", 4, "before", function (character, _, _, _)
	local entity = Ext.Entity.Get(character)
	if entity.Vars.Goon_Injuries then
		entity.Vars.Goon_Injuries = nil
		Ext.ServerNet.BroadcastMessage("Injuries_Update_Report", character)
	end
end)

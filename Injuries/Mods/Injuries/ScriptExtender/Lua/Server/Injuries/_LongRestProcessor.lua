local processed = false

local function process(character)
	if ConfigManager.ConfigCopy.injuries.universal.remove_all_on_long_rest then
		InjuryCommonLogic:RemoveAllInjuries(character)
	else
		local entity, injuryVar = InjuryCommonLogic:GetUserVar(character)
		if entity and injuryVar then
			InjuryCommonLogic:ResetCounters(character, entity.Vars)

			for injury in pairs(injuryVar["injuryAppliedReason"]) do
				local removeConfig = ConfigManager.ConfigCopy.injuries.injury_specific[injury].remove_on_status
				if removeConfig and removeConfig["LONG_REST"] then
					local longRestConfig = removeConfig["LONG_REST"]
					if not longRestConfig["after_x_applications"] or longRestConfig["after_x_applications"] == 1 then
						-- InjuryCommonLogic handles the rest of the logic on this event
						Osi.RemoveStatus(character, injury)
					end

					if not injuryVar["numberOfLongRests"] then
						injuryVar["numberOfLongRests"] = { injury = 1 }
					elseif not injuryVar["numberOfLongRests"][injury] then
						injuryVar["numberOfLongRests"][injury] = 1
					else
						injuryVar["numberOfLongRests"][injury] = injuryVar["numberOfLongRests"][injury] + 1

						if injuryVar["numberOfLongRests"][injury] >= longRestConfig["after_x_applications"] then
							-- InjuryCommonLogic handles the rest of the logic on this event
							Osi.RemoveStatus(character, injury)
						end
					end
				end
			end
		end
	end
end

EventCoordinator:RegisterEventProcessor("StatusApplied", function(character, status, causee, storyActionID)
	if status == "ALCH_POTION_REST_SLEEP_GREATER_RESTORATION" then
		process(character)
	end
end)

Ext.Osiris.RegisterListener("UserCharacterLongRested", 2, "after", function(character, isFullRest)
	Logger:BasicDebug("%s long rested", character)
	if isFullRest == 0 or processed then
		return
	end

	processed = true

	for _, injuredCharacter in pairs(Ext.Vars.GetEntitiesWithVariable("Goon_Injuries")) do
		process(injuredCharacter)
	end
end)

Ext.Osiris.RegisterListener("LongRestStarted", 0, "after", function()
	Logger:BasicDebug("Long rest started")
	processed = false
end)

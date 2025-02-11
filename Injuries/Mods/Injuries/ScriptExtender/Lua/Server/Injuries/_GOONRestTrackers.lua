local sharedPrefix = "GOON_INJURY_GRIT_GLORY_"

local function GetNextRestStack(character, shortInjuryName)
    local fullInjuryName = sharedPrefix .. shortInjuryName
    local highestPriority = 0
    local nextStack = nil

    -- Loop to find the highest stack priority for the given injury name
    local entity = Ext.Entity.Get(character)
    for _, status in Osi.HasActiveStatus(character, currentStatus) do
        local statusData = Ext.Stats.Get(status.StatusId)
        if statusData and statusData.StackId == nextStackName then
            local priority = tonumber(statusData.StackPriority)
            print("Current status: " .. status.StatusId .. ", Priority: " .. priority)
            if priority and priority > highestPriority then
                highestPriority = priority
                nextStack = statusData.Name
            end
        end
    end

    -- Return the next stack
    if nextStack then
        local nextPriority = highestPriority + 1
        local nextStackName = "GOON_" .. shortInjuryName .. "_LONG_REST_TRACKER_" .. nextPriority
        print("Next stack: " .. nextStackName)
        return nextStackName
    else
        local firstStackName = "GOON_" .. shortInjuryName .. "_LONG_REST_TRACKER_1"
        print("First stack: " .. firstStackName)
        return firstStackName
    end
end

local function trackRestStacks(entity, shortInjuryName)
    local character = entity.Uuid.EntityUuid
    local nextRestStack = GetNextRestStack(character, shortInjuryName)

    -- Apply the next stack if it's not already present
    if Osi.HasActiveStatus(character, nextRestStack) == 0 then
        print("Applying status: " .. nextRestStack .. " to character: " .. character)
        Osi.ApplyStatus(character, nextRestStack, -1)
    else
        print("Status already present: " .. nextRestStack)
    end
end

-- StatusRemoved Listener for Rest Tracking (Handling multiple injury names)
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(object, status)
    if status == "LONG_REST" or status == "CAMP_ASTARION_DAISYDREAM" then
        local entity = Ext.Entity.Get(object)
        
        if entity then
            -- Define the different rest injury names (you can expand this)
            local InjuryNames = { 
                "GOON_INJURY_GRIT_GLORY_ANOSMIA",
                "GOON_INJURY_GRIT_GLORY_BLINDNESS",
                "GOON_INJURY_GRIT_GLORY_PARTIAL_BLINDNESS",
                "GOON_INJURY_GRIT_GLORY_BLISTERS",
                "GOON_INJURY_GRIT_GLORY_BRAIN_INJURY",
                "GOON_INJURY_GRIT_GLORY_BROKEN_NOSE",
                "GOON_INJURY_GRIT_GLORY_FIRST_DEGREE_BURNS",
                "GOON_INJURY_GRIT_GLORY_SECOND_DEGREE_BURNS",
                "GOON_INJURY_GRIT_GLORY_THIRD_DEGREE_BURNS",
                "GOON_INJURY_GRIT_GLORY_FOURTH_DEGREE_BURNS",
                "GOON_INJURY_GRIT_GLORY_CARDIAC_INJURY",
                "GOON_INJURY_GRIT_GLORY_MAJOR_CONCUSSION",
                "GOON_INJURY_GRIT_GLORY_MINOR_CONCUSSION",
                "GOON_INJURY_GRIT_GLORY_DEAFNESS",
                "GOON_INJURY_GRIT_GLORY_PARTIAL_DEAFNESS",
                "GOON_INJURY_GRIT_GLORY_DESTROYED_FOOT",
                "GOON_INJURY_GRIT_GLORY_DESTROYED_HAND",
                "GOON_INJURY_GRIT_GLORY_HORRIBLE_DISFIGUREMENT",
                "GOON_INJURY_GRIT_GLORY_MINOR_DISFIGUREMENT",
                "GOON_INJURY_GRIT_GLORY_FESTERING_WOUND",
                "GOON_INJURY_GRIT_GLORY_FLASH_BURNS",
                "GOON_INJURY_GRIT_GLORY_FROSTBITTEN_FOOT",
                "GOON_INJURY_GRIT_GLORY_FROSTBITTEN_HAND",
                "GOON_INJURY_GRIT_GLORY_MINOR_HEADACHES",
                "GOON_INJURY_GRIT_GLORY_SEVERE_HEADACHES",
                "GOON_INJURY_GRIT_GLORY_INAPPROPRIATE_VOLUME",
                "GOON_INJURY_GRIT_GLORY_INFLAMMATION",
                "GOON_INJURY_GRIT_GLORY_MAJOR_KIDNEY_FAILURE",
                "GOON_INJURY_GRIT_GLORY_MINOR_KIDNEY_FAILURE",
                "GOON_INJURY_GRIT_GLORY_MAJOR_LIVER_DAMAGE",
                "GOON_INJURY_GRIT_GLORY_MINOR_LIVER_DAMAGE",
                "GOON_INJURY_GRIT_GLORY_LONGTERM_MADNESS",
                "GOON_INJURY_GRIT_GLORY_SHORTTERM_MADNESS",
                "GOON_INJURY_GRIT_GLORY_MUSCLE_SPASMS",
                "GOON_INJURY_GRIT_GLORY_NAUSEA",
                "GOON_INJURY_GRIT_GLORY_NECROTIC_DISCOLOURATION",
                "GOON_INJURY_GRIT_GLORY_NECROTIC_STENCH",
                "GOON_INJURY_GRIT_GLORY_MAJOR_NEURALGIA",
                "GOON_INJURY_GRIT_GLORY_MINOR_NEURALGIA",
                "GOON_INJURY_GRIT_GLORY_NEURODEGENERATIVE_DISORDER",
                "GOON_INJURY_GRIT_GLORY_NEUROREGRESSIVE_ATAXIA",
                "GOON_INJURY_GRIT_GLORY_PHANTOM_PAIN",
                "GOON_INJURY_GRIT_GLORY_SEVERE_BRUISING",
                "GOON_INJURY_GRIT_GLORY_SKELETAL_MUSCLE_BREAKDOWN",
                "GOON_INJURY_GRIT_GLORY_LARGE_SKIN_TUMOURS",
                "GOON_INJURY_GRIT_GLORY_SMALL_SKIN_TUMOURS",
                "GOON_INJURY_GRIT_GLORY_SLEEP_DISRUPTION",
                "GOON_INJURY_GRIT_GLORY_SYSTEMATIC_DAMAGE",
                "GOON_INJURY_GRIT_GLORY_THROAT_INJURY",
                "GOON_INJURY_GRIT_GLORY_WEAK_PERSONA",
            }

            -- Track stacks separately for each injury name
            for _, injury in ipairs(InjuryNames) do
                local shortInjuryName = string.gsub(injury, sharedPrefix, "")
                if Osi.HasActiveStatus(entity.Uuid.EntityUuid, injury) == 1 then
                    trackRestStacks(entity, shortInjuryName)
                end
            end
        end
    end
end)
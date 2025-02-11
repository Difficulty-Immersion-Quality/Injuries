local function GetNextRestStack(character, InjuryName)
    -- Loop to find the highest stack for the given injury name
    for i = 1, 100 do  -- Safety limit
        local currentStatus = "GOON_" .. shortInjuryName .. "_REST_TRACKER_" .. i
        local nextStatus = "GOON_" .. shortInjuryName .. "_REST_TRACKER_" .. (i + 1)

        if Osi.HasActiveStatus(character, currentStatus) == 1 then
            print("Current status found: " .. currentStatus)
            return nextStatus  -- Move to the next stack
        end
    end

    -- If no stack is found, start at 1
    return InjuryName .. "_REST_TRACKER_1"
end

local function trackRestStacks(entity, InjuryName)
    local character = entity.Uuid.EntityUuid
    local nextRestStack = GetNextRestStack(character, InjuryName)

    -- Apply the next stack if it's not already present
    if Osi.HasActiveStatus(character, nextRestStack) == 0 then
        print("Applying status: " .. nextRestStack .. " to character: " .. character)
        Osi.ApplyStatus(character, nextRestStack, -1)
    else
        print("Status already present: " .. nextRestStack)
    end
end

local sharedPrefix = "GOON_INJURY_GRIT_GLORY_"
local fullInjuryName = sharedPrefix .. shortInjuryName

-- StatusApplied Listener for Rest Tracking (Handling multiple injury names)
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
                "GOON_INJURY_GRIT_GLORY_PARTIAL_BLINDNESS",
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
            for _, InjuryName in ipairs(InjuryNames) do
                if Osi.HasActiveStatus(entity.Uuid.EntityUuid, InjuryName) == 1 then
                    trackRestStacks(entity, InjuryName)
                end
            end
        end
    end
end)
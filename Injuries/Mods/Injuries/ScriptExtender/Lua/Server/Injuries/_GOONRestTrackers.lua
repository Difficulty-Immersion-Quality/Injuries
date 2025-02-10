local function GetNextRestStack(character, category)
    -- Loop to find the highest stack for the given category
    for i = 1, 100 do  -- Safety limit
        local currentStatus = "GOON_" .. category .. "_REST_TRACKER_" .. i
        local nextStatus = "GOON_" .. category .. "_REST_TRACKER_" .. (i + 1)

        if Osi.HasActiveStatus(character, currentStatus) == 1 then
            return nextStatus  -- Move to the next stack
        end
    end

    -- If no stack is found, start at 1
    return "GOON_" .. category .. "_REST_TRACKER_1"
end

local function trackRestStacks(entity, restVar, category)
    local character = entity.Uuid.EntityUuid
    local nextRestStack = GetNextRestStack(character, category)

    -- Apply the next stack if it's not already present
    if Osi.HasActiveStatus(character, nextRestStack) == 0 then
        Osi.ApplyStatus(character, nextRestStack, -1)
        restVar["appliedReason"][nextRestStack] = "Long Rest (" .. category .. ")"
    end
end

-- StatusApplied Listener for Rest Tracking (Handling multiple categories)
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status)
    if status == "LONG_REST" or status == "CAMP_ASTARION_DAISYDREAM" then
        local entity = Ext.Entity.Get(object)
        local restVar = ConfigHelper:GetCharacterRestVar(object)
        
        if entity and restVar then
            -- Define the different rest categories (you can expand this)
            local categories = { "INJURY", "MADNESS", "EXHAUSTION" }

            -- Track stacks separately for each category
            for _, category in ipairs(categories) do
                trackRestStacks(entity, restVar, category)
            end
        end
    end
end)

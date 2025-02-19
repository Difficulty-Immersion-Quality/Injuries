-- Mapping of constitution statuses to their cooldown durations
local TechnicalCooldownDurations = {
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_1 = {10, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_2 = {10, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_3 = {5, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_4 = {5, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_5 = {5, 15},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_6 = {5, 15},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_7 = {2, 10}
}

-- Mapping of sleep statuses to their respective duration ranges
local TechnicalSleepDurations = {
    GOON_FALL_ASLEEP_EASY_TECHNICAL = {2, 5},
    GOON_FALL_ASLEEP_MEDIUM_TECHNICAL = {2, 10},
    GOON_FALL_ASLEEP_HARD_TECHNICAL = {2, 15},
    GOON_FALL_ASLEEP_EXTREME_TECHNICAL = {2, 20}
}

-- Direct mapping of technical statuses to their non-technical sleep statuses
local TechnicalToSleepStatusMap = {
    GOON_FALL_ASLEEP_EASY_TECHNICAL = "GOON_FALL_ASLEEP_EASY",
    GOON_FALL_ASLEEP_MEDIUM_TECHNICAL = "GOON_FALL_ASLEEP_MEDIUM",
    GOON_FALL_ASLEEP_HARD_TECHNICAL = "GOON_FALL_ASLEEP_HARD",
    GOON_FALL_ASLEEP_EXTREME_TECHNICAL = "GOON_FALL_ASLEEP_EXTREME"
}

-- Listener 1: Apply cooldown when the technical status is applied
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    -- Check if the status is one of the technical cooldown statuses
    local cooldownStatus = status
    if TechnicalCooldownDurations[cooldownStatus] then
        local cooldownRange = TechnicalCooldownDurations[cooldownStatus]
        if cooldownRange then
            -- Generate a random cooldown duration and convert to seconds
            local cooldownDuration = math.random(cooldownRange[1], cooldownRange[2]) * 6
            -- Apply the cooldown status with the generated duration
            Osi.ApplyStatus(object, "GOON_FALL_ASLEEP_COOLDOWN", cooldownDuration, 1)
        end
    end
end)

-- Listener 2: Apply sleep status when the corresponding technical sleep status is applied
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    -- Check if the status is one of the sleep-related technical statuses
    if TechnicalToSleepStatusMap[status] then
        local sleepStatus = TechnicalToSleepStatusMap[status]
        local sleepRange = TechnicalSleepDurations[status]
        
        if sleepStatus and sleepRange then
            -- Generate a random sleep duration within the range and convert to seconds
            local sleepDuration = math.random(sleepRange[1], sleepRange[2]) * 6
            -- Apply the sleep status with the generated duration
            Osi.ApplyStatus(object, sleepStatus, sleepDuration, 1)
        end
    end
end)
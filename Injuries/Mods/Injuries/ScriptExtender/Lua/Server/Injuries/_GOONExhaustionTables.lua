-- Mapping of technical statuses to their respective cooldown duration ranges
local TechnicalCooldownDurations = {
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_1 = {2, 25},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_2 = {2, 25},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_3 = {2, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_4 = {2, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_5 = {2, 15},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_6 = {2, 15},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_7 = {2, 10}
}

-- Mapping of technical statuses to their respective duration ranges
local TechnicalSleepDurations = {
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_1 = {2, 5},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_2 = {2, 5},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_3 = {2, 10},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_4 = {2, 10},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_5 = {2, 15},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_6 = {2, 15},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_7 = {2, 20}
}

-- Mapping of technical statuses to their corresponding non-technical statuses
local TechnicalToSleepStatusMap = {
    GOON_FALL_ASLEEP_EASY_TECHNICAL = "GOON_FALL_ASLEEP_EASY",
    GOON_FALL_ASLEEP_MEDIUM_TECHNICAL = "GOON_FALL_ASLEEP_MEDIUM",
    GOON_FALL_ASLEEP_HARD_TECHNICAL = "GOON_FALL_ASLEEP_HARD",
    GOON_FALL_ASLEEP_EXTREME_TECHNICAL = "GOON_FALL_ASLEEP_EXTREME"
}

-- Function to apply a random duration sleep status
local function ApplySleepStatus(object, technicalStatus)
    local sleepStatus = TechnicalToSleepStatusMap[technicalStatus]
    if sleepStatus then
        local cooldownRange = TechnicalCooldownDurations[technicalStatus]
        local sleepRange = TechnicalSleepDurations[technicalStatus]
        if cooldownRange and sleepRange then
            -- Generate a random cooldown duration within the specified range and convert to seconds
            local cooldownDuration = math.random(cooldownRange[1], cooldownRange[2]) * 6
            -- Generate a random sleep duration within the specified range and convert to seconds
            local sleepDuration = math.random(sleepRange[1], sleepRange[2]) * 6
            -- Apply the cooldown status with the cooldown duration
            Osi.ApplyStatus(object, "GOON_FALL_ASLEEP_COOLDOWN", cooldownDuration, 1)
            -- Apply the sleep status with the sleep duration
            Osi.ApplyStatus(object, sleepStatus, sleepDuration, 1)
        end
    end
end

-- StatusApplied Listener
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    -- Check if the cooldown status is already active
    if Osi.HasActiveStatus(object, "GOON_FALL_ASLEEP_COOLDOWN") == 0 then
        if TechnicalToSleepStatusMap[status] then
            ApplySleepStatus(object, status)
        end
    end
end)
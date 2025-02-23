-- Mapping of constitution statuses to their cooldown durations
local CooldownDurations = {
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_1 = {10, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_2 = {10, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_3 = {5, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_4 = {5, 20},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_5 = {5, 15},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_6 = {5, 15},
    GOON_FALL_ASLEEP_CONSTITUTION_TECHNICAL_7 = {2, 10}
}

-- Mapping of sleep statuses to their respective duration ranges
local SleepDurations = {
    GOON_FALL_ASLEEP_EASY_TECHNICAL = {2, 5},
    GOON_FALL_ASLEEP_MEDIUM_TECHNICAL = {2, 10},
    GOON_FALL_ASLEEP_HARD_TECHNICAL = {2, 15},
    GOON_FALL_ASLEEP_EXTREME_TECHNICAL = {2, 20}
}

-- Direct mapping of technical statuses to their non-technical sleep statuses
local SleepStatuses = {
    GOON_FALL_ASLEEP_EASY_TECHNICAL = "GOON_FALL_ASLEEP_EASY",
    GOON_FALL_ASLEEP_MEDIUM_TECHNICAL = "GOON_FALL_ASLEEP_MEDIUM",
    GOON_FALL_ASLEEP_HARD_TECHNICAL = "GOON_FALL_ASLEEP_HARD",
    GOON_FALL_ASLEEP_EXTREME_TECHNICAL = "GOON_FALL_ASLEEP_EXTREME"
}

-- Listener 1: Cooldown
EventCoordinator:RegisterEventProcessor("StatusApplied", function(object, status, causee, storyActionID)
    if CooldownDurations[status] then
        local cooldownDuration = math.random(CooldownDurations[status][1], CooldownDurations[status][2]) * 6
        Osi.ApplyStatus(object, "GOON_FALL_ASLEEP_COOLDOWN", cooldownDuration, 1)
    end
end)

-- Listener 2: Sleep
EventCoordinator:RegisterEventProcessor("StatusApplied", function(object, status, causee, storyActionID)
    if SleepStatuses[status] and SleepDurations[status] then
        local sleepDuration = math.random(SleepDurations[status][1], SleepDurations[status][2]) * 6
        Osi.ApplyStatus(object, SleepStatuses[status], sleepDuration, 1)
    end
end)

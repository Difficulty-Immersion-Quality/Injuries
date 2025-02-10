-- Predefined tables for each triggering status
local LongTermMadnessTable = {
    "GOON_MADNESS_5E_CODEPENDANT",
    "GOON_MADNESS_5E_COMATOSED",
    "GOON_MADNESS_5E_HALLUCINATIONS",
    "GOON_MADNESS_5E_PANICKY",
    "GOON_MADNESS_5E_PARANOIA",
    "GOON_MADNESS_5E_TREMORS"
}

local ShortTermMadnessTable = {
    "GOON_MADNESS_5E_HALLUCINATIONS",
    "GOON_MADNESS_5E_HOMICIDAL",
    "GOON_MADNESS_5E_HYSTERIA",
    "GOON_MADNESS_5E_INTIMIDATED",
    "GOON_MADNESS_5E_PARALYSED",
    "GOON_MADNESS_5E_STUNNED",
    "GOON_MADNESS_5E_TONGUE_TIED",
    "GOON_MADNESS_5E_UNCONSCIOUS"
}

-- Helper function to get a random status from a given table
local function GetRandomStatus(statusTable, object, isShortTerm)
    local characterStatusManager = Ext.Entity.Get(object).ServerCharacter.StatusManager
    local activeStatuses = {}

    -- Collect active statuses to prevent duplicate application to the same character
    for _, esvStatus in pairs(characterStatusManager.Statuses) do
        activeStatuses[esvStatus.StatusId] = true
    end

    -- Filter valid statuses that aren't already applied to the current character
    local validStatuses = {}
    for _, status in ipairs(statusTable) do
        if not activeStatuses[status] then
            table.insert(validStatuses, status)
        end
    end

    -- If there are valid statuses, apply one randomly
    if #validStatuses > 0 then
        local selectedStatus = validStatuses[math.random(#validStatuses)]
        
        -- Adjust duration: Use 1-50 rounds for short-term madness, converted to seconds
        local duration = isShortTerm and math.random(1, 50) * 6 or -1  -- 1-50 rounds for short-term, -1 for permanent

        Osi.ApplyStatus(object, selectedStatus, duration, 1)
    end
end

-- StatusApplied Listener
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if status == "GOON_INJURY_GRIT_GLORY_LONGTERM_MADNESS" then
        GetRandomStatus(LongTermMadnessTable, object, false) -- Long-term: Permanent duration
    
    elseif status == "GOON_INJURY_GRIT_GLORY_SHORTTERM_MADNESS" then
        GetRandomStatus(ShortTermMadnessTable, object, true) -- Short-term: 1-50 rounds
    end
end)
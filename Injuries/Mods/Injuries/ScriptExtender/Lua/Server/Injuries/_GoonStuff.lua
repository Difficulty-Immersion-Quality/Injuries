function Goon_Lesser_Restoration_Check(spell)
    return spell == 'Target_LesserRestoration'
        or spell == 'Target_LesserRestoration_3'
        or spell == 'Target_LesserRestoration_4'
        or spell == 'Target_LesserRestoration_5'
        or spell == 'Target_LesserRestoration_6'
        or spell == 'Target_LesserRestoration_7'
        or spell == 'Target_LesserRestoration_8'
        or spell == 'Target_LesserRestoration_9'
end

Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, spellType, spellElement, storyActionID)
    if Goon_Lesser_Restoration_Check(spell) then
        Osi.ApplyStatus(target, "GOON_LESSER_RESTORATION_INJURY_REMOVAL_TECHNICAL", 1, 1, caster)
    end
end)

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

local function GetRandomStatus(statusTable, object, isShortTerm)
    local characterStatusManager = Ext.Entity.Get(object).ServerCharacter.StatusManager
    local activeStatuses = {}

    -- Collect active statuses to prevent duplicate application
    for _, esvStatus in pairs(characterStatusManager.Statuses) do
        activeStatuses[esvStatus.StatusId] = true
    end

    -- Filter valid statuses that aren't already applied
    local validStatuses = {}
    for _, status in ipairs(statusTable) do
        if not activeStatuses[status] then
            table.insert(validStatuses, status)
        end
    end

    -- If there are valid statuses, apply one randomly
    if #validStatuses > 0 then
        local selectedStatus = validStatuses[math.random(#validStatuses)]
        
        -- Adjust duration: Multiply by 10 if game scales it down
        local duration = isShortTerm and math.random(10, 500) or -1  -- Adjusted scaling
        
        print("Applying status: " .. selectedStatus .. " with duration: " .. duration)  -- Debugging

        Osi.ApplyStatus(object, selectedStatus, duration, 1)
    end
end

-- StatusApplied Listener
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if status == "GOON_INJURY_GRIT_GLORY_LONGTERM_MADNESS" then
        GetRandomStatus(LongTermMadnessTable, object, false) -- Long-term: Permanent duration
    
    elseif status == "GOON_INJURY_GRIT_GLORY_SHORTTERM_MADNESS" then
        GetRandomStatus(ShortTermMadnessTable, object, true) -- Short-term: 1-50 turns
    end
end)

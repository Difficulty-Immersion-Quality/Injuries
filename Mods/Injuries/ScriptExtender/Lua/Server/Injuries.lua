-- Injury tables for different damage types
local InjuriesByDamageType = {
    Bludgeoning = {"Goon_Concussion", "Goon_Broken_Bone", "Goon_Crushed_Ribs"},
    Piercing = {"Goon_Pierced_Lung", "Goon_Ruptured_Intestine", "Goon_Severed_Tendon"},
    Slashing = {"Goon_Flesh_Wound", "Goon_Severed_Tendon", "Goon_Ruptured_Intestine"},
    Cold = {"Goon_Hypothermia", "Goon_Severed_Tendon"},
    Fire = {"Goon_1st_Degree_Burn", "Goon_2nd_Degree_Burn", "Goon_3rd_Degree_Burn"},
    Lightning = {"Goon_Nerve_Damage", "Goon_Fried_Synapses"},
    Thunder = {"Goon_Crushed_Ribs", "Goon_Ruptured_EarDrums", "Goon_Concussion", "Goon_Broken_Bone"},
    Acid = {"Goon_Bubbled_Brow", "Goon_Flesh_Wound"},
    Poison = {"Goon_Poisoning", "Goon_Ruptured_Intestine"},
    Radiant = {"Goon_1st_Degree_Burn", "Goon_2nd_Degree_Burn", "Goon_3rd_Degree_Burn"},
    Necrotic = {"Goon_Tissue_Death", "Goon_Flesh_Wound"},
    Force = {"Goon_Crushed_Ribs", "Goon_Ruptured_EarDrums", "Goon_Concussion", "Goon_Broken_Bone"},
    Psychic = {"Goon_Psychic_Psychosis","Goon_Fried_Synapses"}
}

-- MAIN INJURY CODE
-- Table to track the most recent damage type and attacker for each character
local RecentDamageInfo = {}

-- Damage Listener to track recent damage type and attacker for each character
Ext.Osiris.RegisterListener("AttackedBy", 7, "after", function(defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionID)
    if IsCharacter(defender) == 1 then
        local damageType = damageType or "Unknown Damage Type"
        
        -- Initialize the table for the defender if it doesn't exist
        RecentDamageInfo[defender] = RecentDamageInfo[defender] or {}
        
        -- Store the damage type and attacker for the defender (character)
        RecentDamageInfo[defender] = {
            damageType = damageType,
            attacker = attackerOwner -- Ensure attacker is correctly set
        }
    end
end)

-- StatusApplied Listener to handle injuries and prevent double application
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if status == "DOWNED" then
        print("Status DOWNED applied to: " .. object)

        -- Initialize the table for the character if it doesn't exist
        RecentDamageInfo[object] = RecentDamageInfo[object] or {}

        -- Check recent damage info for the character
        local recentInfo = RecentDamageInfo[object]
        if recentInfo and recentInfo.damageType then
            local damageType = recentInfo.damageType
            local attacker = recentInfo.attacker
            print("Recent damage type for character: " .. object .. " is: " .. tostring(damageType))

            -- Apply injury based on damage type if no injury is already applied
            if damageType and InjuriesByDamageType[damageType] then
                local availableInjuries = InjuriesByDamageType[damageType]
                
                -- Get the current active statuses of the character
                local characterStatusManager = Ext.Entity.Get(object).ServerCharacter.StatusManager
                local activeStatuses = {}
                
                -- Loop through statuses to avoid double application
                for _, esvStatus in pairs(characterStatusManager.Statuses) do
                    activeStatuses[esvStatus.StatusId] = true
                end

                -- Create a list of injuries not yet applied
                local validInjuries = {}
                for _, injury in ipairs(availableInjuries) do
                    if not activeStatuses[injury] then
                        table.insert(validInjuries, injury)
                    end
                end

                -- If there are valid injuries left, apply a random one
                if #validInjuries > 0 then
                    local randomIndex = math.random(#validInjuries)
                    local selectedInjury = validInjuries[randomIndex]
                    print("Applying injury status: " .. selectedInjury)
                    Osi.ApplyStatus(object, selectedInjury, -1)

                    -- Check if the selected injury is "Goon_Phobia_AURA"
                    if selectedInjury == "Goon_Phobia_AURA" then
                        print("Phobia injury selected. Applying phobia status.")
                        if attacker and attacker ~= "00000000-0000-0000-0000-000000000000" then
                            local phobiaStatus = "Goon_Phobia_AURA"
                            print("Applying phobia status: " .. phobiaStatus .. " for attacker: " .. attacker)
                            Osi.ApplyStatus(object, phobiaStatus, -1)
                        else
                            print("No valid attacker GUID found for phobia application.")
                        end
                    end
                else
                    print("No more valid injuries left to apply for damage type: " .. damageType)
                end
            else
                print("No injuries available for the damage type: " .. tostring(damageType))
            end
        else
            print("No recent damage info found for character: " .. object)
        end

        -- Clear the recent damage info after handling DOWNED status
        RecentDamageInfo[object] = nil
    end
end)

-- REMOVAL OF STATUSES
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if status == "Target_GreaterRestoration" then
        print("Greater Restoration applied to: " .. object)

        local activeInjuries = {}
        local characterStatusManager = Ext.Entity.Get(object).ServerCharacter.StatusManager

        -- Get the current active statuses of the character
        local activeStatuses = {}
        for _, esvStatus in pairs(characterStatusManager.Statuses) do
            activeStatuses[esvStatus.StatusId] = true
        end

        -- Loop through all damage types to check for injuries
        for damageType, injuryList in pairs(InjuriesByDamageType) do
            for _, injury in ipairs(injuryList) do
                if activeStatuses[injury] then
                    table.insert(activeInjuries, injury)
                end
            end
        end

        if #activeInjuries > 0 then
            local randomIndex = math.random(#activeInjuries)
            local injuryToRemove = activeInjuries[randomIndex]
            print("Removing injury: " .. injuryToRemove)
            Osi.RemoveStatus(object, injuryToRemove)
        else
            print("No injuries found to remove for: " .. object)
        end
    end
end)

Ext.Osiris.RegisterListener("ShortRested", 1, "after", function(character)
    print("Short rest for character: " .. character)

    local activeInjuries = {}
    local characterStatusManager = Ext.Entity.Get(character).ServerCharacter.StatusManager

    -- Get the current active statuses of the character
    local activeStatuses = {}
    for _, esvStatus in pairs(characterStatusManager.Statuses) do
        activeStatuses[esvStatus.StatusId] = true
    end

    -- Loop through all damage types to check for injuries
    for damageType, injuryList in pairs(InjuriesByDamageType) do
        for _, injury in ipairs(injuryList) do
            if activeStatuses[injury] then
                table.insert(activeInjuries, injury)
            end
        end
    end

    if #activeInjuries > 0 then
        local randomIndex = math.random(#activeInjuries)
        local injuryToRemove = activeInjuries[randomIndex]
        print("Removing injury from short rest: " .. injuryToRemove .. " for character: " .. character)
        Osi.RemoveStatus(character, injuryToRemove)
    else
        print("No injuries found to remove for character: " .. character)
    end
end)

  
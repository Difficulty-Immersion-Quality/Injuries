local EXHA_Passive_Remove_All_On_Long_Rest = "FATIGUE_REMOVE_ALL_LEVELS_LONG_REST"

local function EXHA_CharIsHero(char)
    return char ~= nil and string.find(char.Passives, "WeaponThrow") and string.find(char.Passives, "CombatStartAttack") and string.find(char.Passives, "ShortResting") and string.find(char.Passives, "NonLethal")
end

local function EXHA_Addon_RemoveAllOnLongRest_StatsLoaded()
    for _, name in pairs(Ext.Stats.GetStats("Character")) do
        local char = Ext.Stats.Get(name)

        
        if EXHA_CharIsHero(char) then
            if string.find(char.Passives, EXHA_Passive_Remove_All_On_Long_Rest) then
                -- Ext.Utils.Print("\tSkipping; Hero already has passive")
            else
                char.Passives = EXHA_Passive_Remove_All_On_Long_Rest .. ";" .. char.Passives
                -- Ext.Utils.Print("\nCharacter: " .. name)
                -- Ext.Utils.Print("\tPassives: " .. char.Passives)
            end
        end
    end
end

Ext.Events.StatsLoaded:Subscribe(EXHA_Addon_RemoveAllOnLongRest_StatsLoaded)

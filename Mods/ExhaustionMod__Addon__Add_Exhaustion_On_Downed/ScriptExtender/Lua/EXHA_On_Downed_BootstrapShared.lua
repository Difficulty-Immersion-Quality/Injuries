local EXHA_Passive_On_Downed = "FATIGUE_ADD_LEVEL_ON_DOWNED_STATUS"


local function EXHA_CharIsHero(char, name)
    return char ~= nil and string.find(char.Passives, "WeaponThrow") and string.find(char.Passives, "CombatStartAttack") and string.find(char.Passives, "ShortResting") and string.find(char.Passives, "NonLethal")
end

local function EXHA_Addon_OnDowned_StatsLoaded()
    for _, name in pairs(Ext.Stats.GetStats("Character")) do
        local char = Ext.Stats.Get(name)

        
        if EXHA_CharIsHero(char, name) then
            if string.find(char.Passives, EXHA_Passive_On_Downed) then
                -- Ext.Utils.Print("\tSkipping; Hero already has passive")
            else
                char.Passives = EXHA_Passive_On_Downed .. ";" .. char.Passives
                -- Ext.Utils.Print("\nCharacter: " .. name)
                -- Ext.Utils.Print("\tPassives: " .. char.Passives)
            end
        end
    end
end

Ext.Events.StatsLoaded:Subscribe(EXHA_Addon_OnDowned_StatsLoaded)

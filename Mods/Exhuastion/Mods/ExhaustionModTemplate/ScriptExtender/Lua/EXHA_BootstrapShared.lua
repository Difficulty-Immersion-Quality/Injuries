local EXHA_Passive_Short_Rest = "PASSIVE_SHORT_REST_MODIFIERS"
local EXHA_Passive_Long_Rest = "PASSIVE_LONG_REST_MODIFIERS"
local EXHA_Passive_Remove_One_level_On_Long_rest = "FATIGUE_MINUS_ONE_LEVEL_LONG_REST"

local function EXHA_CharIsHero(char)
    return char ~= nil and string.find(char.Passives, "WeaponThrow") and string.find(char.Passives, "CombatStartAttack") and string.find(char.Passives, "ShortResting") and string.find(char.Passives, "NonLethal")
end

local function EXHA_TEMPLATE_StatsLoaded()
    for _, name in pairs(Ext.Stats.GetStats("Character")) do
        local char = Ext.Stats.Get(name)

        
        if EXHA_CharIsHero(char) then
            if string.find(char.Passives, EXHA_Passive_Short_Rest) then
                -- Ext.Utils.Print("\tSkipping; Hero already has passive" .. char.Passives)
            else
                char.Passives = EXHA_Passive_Short_Rest .. ";" .. char.Passives
            end
            if string.find(char.Passives, EXHA_Passive_Long_Rest) then
            else
                char.Passives = EXHA_Passive_Long_Rest.. ";" ..  char.Passives
            end
            if string.find(char.Passives, EXHA_Passive_Remove_One_level_On_Long_rest) then
            else
                char.Passives = EXHA_Passive_Remove_One_level_On_Long_rest.. ";" ..  char.Passives
                -- Ext.Utils.Print("\nCharacter: " .. name)
                -- Ext.Utils.Print("\tPassives: " .. char.Passives)
            end
        end
    end
end

Ext.Events.StatsLoaded:Subscribe(EXHA_TEMPLATE_StatsLoaded)

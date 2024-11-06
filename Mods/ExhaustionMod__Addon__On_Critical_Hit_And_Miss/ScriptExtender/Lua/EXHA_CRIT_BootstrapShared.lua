local EXHA_Passive_Crit_HIT = "ADD_EXHAUSTION_ON_HIT_WITH_CRITIAL"
local EXHA_Passive_Crit_MISS = "ADD_EXHAUSTION_IF_CRITIAL_MISSED"

local function EXHA_CharIsHero(char)
    return char ~= nil and string.find(char.Passives, "WeaponThrow") and string.find(char.Passives, "CombatStartAttack") and string.find(char.Passives, "ShortResting") and string.find(char.Passives, "NonLethal")
end

local function EXHA_Crit_StatsLoaded()
    for _, name in pairs(Ext.Stats.GetStats("Character")) do
        local char = Ext.Stats.Get(name)

        
        if EXHA_CharIsHero(char) then
            if string.find(char.Passives, EXHA_Passive_Crit_HIT) then
                -- Ext.Utils.Print("\tSkipping; Hero already has passive" .. char.Passives)
            else
                char.Passives = EXHA_Passive_Crit_HIT .. ";" .. char.Passives
            end
            if string.find(char.Passives, EXHA_Passive_Crit_MISS) then
            else
                char.Passives = EXHA_Passive_Crit_MISS.. ";" ..  char.Passives
            end
        end
    end
end

Ext.Events.StatsLoaded:Subscribe(EXHA_Crit_StatsLoaded)

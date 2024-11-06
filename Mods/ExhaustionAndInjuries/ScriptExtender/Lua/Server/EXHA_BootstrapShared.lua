local EXHA_Passive_Short_Rest = "PASSIVE_SHORT_REST_MODIFIERS"
local EXHA_Passive_Long_Rest = "PASSIVE_LONG_REST_MODIFIERS"
local EXHA_Passive_Remove_One_level_On_Long_rest = "FATIGUE_MINUS_ONE_LEVEL_LONG_REST"
local EXHA_Passive_Custom_Type = "FATIGUE_PASSIVE_CUSTOM"
local EXHA_Passive_Short_Rest_Remove_All = "PASSIVE_SHORT_REST_MODIFIERS_REMOVE_ALL_LEVELS"
local EXHA_Passive_Remove_All_On_Long_Rest = "FATIGUE_REMOVE_ALL_LEVELS_LONG_REST"
local EXHA_Passive_Crit_HIT = "ADD_EXHAUSTION_ON_HIT_WITH_CRITIAL"
local EXHA_Passive_Crit_MISS = "ADD_EXHAUSTION_IF_CRITIAL_MISSED"
local EXHA_Passive_On_Status = "FATIGUE_FROM_STATUSES"
local EXHA_Passive_On_Knocked_Down = "FATIGUE_FROM_KNOCKED_DOWN"
local EXHA_Passive_On_Incapacitated = "FATIGUE_FROM_INCAPACITATED"
local EXHA_Passive_On_Downed = "FATIGUE_ADD_LEVEL_ON_DOWNED_STATUS"

local function EXHA_CharIsHero(char)
    return char ~= nil and string.find(char.Passives, "WeaponThrow") and string.find(char.Passives, "CombatStartAttack") and string.find(char.Passives, "ShortResting") and string.find(char.Passives, "NonLethal")
end

local function EXHA_TEMPLATE_StatsLoaded()
    for _, name in pairs(Ext.Stats.GetStats("Character")) do
        local char = Ext.Stats.Get(name)
        
        if EXHA_CharIsHero(char) then
            if not string.find(char.Passives, EXHA_Passive_Short_Rest) then
                char.Passives = EXHA_Passive_Short_Rest .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_Long_Rest) then
                char.Passives = EXHA_Passive_Long_Rest.. ";" ..  char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_Remove_One_level_On_Long_rest) then
                char.Passives = EXHA_Passive_Remove_One_level_On_Long_rest.. ";" ..  char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_Custom_Type) then
                char.Passives = EXHA_Passive_Custom_Type .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_Short_Rest_Remove_All) then
                char.Passives = EXHA_Passive_Short_Rest_Remove_All .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_Remove_All_On_Long_Rest) then
                char.Passives = EXHA_Passive_Remove_All_On_Long_Rest .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_Crit_HIT) then
                char.Passives = EXHA_Passive_Crit_HIT .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_Crit_MISS) then
                char.Passives = EXHA_Passive_Crit_MISS .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_On_Status) then
                char.Passives = EXHA_Passive_On_Status .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_On_Knocked_Down) then
                char.Passives = EXHA_Passive_On_Knocked_Down .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_On_Incapacitated) then
                char.Passives = EXHA_Passive_On_Incapacitated .. ";" .. char.Passives
            end
            if not string.find(char.Passives, EXHA_Passive_On_Downed) then
                char.Passives = EXHA_Passive_On_Downed .. ";" .. char.Passives
            end
        end
    end
end

Ext.Events.StatsLoaded:Subscribe(EXHA_TEMPLATE_StatsLoaded)

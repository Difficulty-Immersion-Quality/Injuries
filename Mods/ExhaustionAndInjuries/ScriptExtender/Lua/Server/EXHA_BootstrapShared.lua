local passives = {
    "PASSIVE_SHORT_REST_MODIFIERS",
    "PASSIVE_LONG_REST_MODIFIERS",
    "FATIGUE_MINUS_ONE_LEVEL_LONG_REST",
    "FATIGUE_PASSIVE_CUSTOM",
    "PASSIVE_SHORT_REST_MODIFIERS_REMOVE_ALL_LEVELS",
    "FATIGUE_REMOVE_ALL_LEVELS_LONG_REST",
    "ADD_EXHAUSTION_ON_HIT_WITH_CRITIAL",
    "ADD_EXHAUSTION_IF_CRITIAL_MISSED",
    "FATIGUE_FROM_STATUSES",
    "FATIGUE_FROM_KNOCKED_DOWN",
    "FATIGUE_FROM_INCAPACITATED",
    "FATIGUE_ADD_LEVEL_ON_DOWNED_STATUS"
}

local function EXHA_CharIsHero(char)
    return char ~= nil and string.find(char.Passives, "WeaponThrow") and string.find(char.Passives, "CombatStartAttack") and string.find(char.Passives, "ShortResting") and
    string.find(char.Passives, "NonLethal")
end

Ext.Events.StatsLoaded:Subscribe(function()
    for _, name in pairs(Ext.Stats.GetStats("Character")) do
        local char = Ext.Stats.Get(name)

        if EXHA_CharIsHero(char) then
            for _, passive in ipairs(passives) do
                if not string.find(char.Passives, passive) then
                    char.Passives = passive .. ";" .. char.Passives
                end
            end
        end
    end
end)

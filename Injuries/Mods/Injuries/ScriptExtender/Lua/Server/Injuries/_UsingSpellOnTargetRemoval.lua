-- Spell check functions
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

function Goon_Greater_Restoration_Check(spell)
    return spell == 'Target_GreaterRestoration'
        or spell == 'Target_GreaterRestoration_6'
        or spell == 'Target_GreaterRestoration_7'
        or spell == 'Target_GreaterRestoration_8'
        or spell == 'Target_GreaterRestoration_9'
end

function Goon_Heal_Check(spell)
    return spell == 'Target_Heal'
        or spell == 'Target_Heal_6'
        or spell == 'Target_Heal_7'
        or spell == 'Target_Heal_8'
        or spell == 'Target_Heal_9'
end

function Goon_Regenerate_Check(spell)
    return spell == 'Target_Regenerate'
        or spell == 'Target_Regenerate_7'
        or spell == 'Target_Regenerate_8'
        or spell == 'Target_Regenerate_9'
end

-- UsingSpellOnTarget Listener
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, spellType, spellElement, storyActionID)
    if Goon_Lesser_Restoration_Check(spell) then
        Osi.ApplyStatus(target, "GOON_LESSER_RESTORATION_INJURY_REMOVAL_TECHNICAL", 1, 1, caster)
    elseif Goon_Greater_Restoration_Check(spell) then
        Osi.ApplyStatus(target, "GOON_GREATER_RESTORATION_INJURY_REMOVAL_TECHNICAL", 1, 1, caster)
    elseif Goon_Heal_Check(spell) then
        Osi.ApplyStatus(target, "GOON_HEAL_INJURY_REMOVAL_TECHNICAL", 1, 1, caster)
    elseif Goon_Regenerate_Check(spell) then
        Osi.ApplyStatus(target, "GOON_REGENERATE_INJURY_REMOVAL_TECHNICAL", 1, 1, caster)
    end
end)
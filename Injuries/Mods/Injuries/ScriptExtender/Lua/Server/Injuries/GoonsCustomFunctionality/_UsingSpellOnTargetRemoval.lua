-- Spell check functions using regex
function Goon_Lesser_Restoration_Check(spell)
    return string.match(spell, "^Target_LesserRestoration") or spell == 'Target_DEN_BearReward_LesserRestoration'
end

function Goon_Lesser_Restoration_Status_Check(status)
    return status == 'MAG_JHANNYL_GLOVES_LESSER_RESTORATION'
end

function Goon_Greater_Restoration_Check(spell)
    return string.match(spell, "^Target_GreaterRestoration") or spell == 'Target_LOW_Hag_GreaterRestoration'
end

function Goon_Heal_Check(spell)
    return string.match(spell, "^Target_Heal") or spell == 'Target_LOW_Raphael_Heal'
end

function Goon_Regenerate_Check(spell)
    return string.match(spell, "^Target_Regenerate")
end

function Goon_Song_Of_Rest_Check(spell)
    return spell == 'Shout_SongOfRest'
end

-- Listener
EventCoordinator:RegisterEventProcessor("UsingSpellOnTarget", function(caster, target, spell, spellType, spellElement, storyActionID)
    if Goon_Lesser_Restoration_Check(spell) then
        Osi.ApplyStatus(target, "GOON_LESSER_RESTORATION_INJURY_REMOVAL", 1, 1, caster)
    elseif Goon_Greater_Restoration_Check(spell) then
        Osi.ApplyStatus(target, "GOON_GREATER_RESTORATION_INJURY_REMOVAL", 1, 1, caster)
    elseif Goon_Heal_Check(spell) then
        Osi.ApplyStatus(target, "GOON_HEAL_INJURY_REMOVAL", 1, 1, caster)
    elseif Goon_Regenerate_Check(spell) then
        Osi.ApplyStatus(target, "GOON_REGENERATE_INJURY_REMOVAL", 1, 1, caster)
    elseif Goon_Song_Of_Rest_Check(spell) then
        Osi.ApplyStatus(target, "GOON_SONG_OF_REST_INJURY_REMOVAL", 1, 1, caster)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if Goon_Lesser_Restoration_Status_Check(status) then
        Osi.ApplyStatus(object, "GOON_LESSER_RESTORATION_INJURY_REMOVAL", 1, 1, causee)
    end
end)
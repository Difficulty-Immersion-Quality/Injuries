-- ==================================== Helper ====================================

function Goon_InjurySpellCheck_Helper(spell, possibleSpellStrings, affixes)
  local match = false
  for _, spellString in pairs(possibleSpellStrings) do
    if spell == spellString then
      match = true
    else
      for _, aff in pairs(affixes) do
        if spell == aff.Pre .. spellString .. aff.Suf then
          match = true
        end
      end
    end
  end

  return match
end

-- ==================================== Spells ====================================

function Goon_Lesser_Restoration_Check(spell)
  local spellStrings = {"Target_LesserRestoration", "Target_DEN_BearReward_LesserRestoration"}
  local affixes = {}
  table.insert(affixes, {Pre = "^", Suf = "_"})
  table.insert(affixes, {Pre = "_", Suf = "$"})
  table.insert(affixes, {Pre = "_", Suf = "_"})
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, affixes)
end

function Goon_Greater_Restoration_Check(spell)
  local spellStrings = {"Target_GreaterRestoration", "Target_LOW_Hag_GreaterRestoration"}
  local affixes = {}
  table.insert(affixes, {Pre = "^", Suf = "_"})
  table.insert(affixes, {Pre = "_", Suf = "$"})
  table.insert(affixes, {Pre = "_", Suf = "_"})
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, affixes)
end

function Goon_Heal_Check(spell)
  local spellStrings = {"Target_Heal", "Target_LOW_Raphael_Heal"}
  local affixes = {}
  table.insert(affixes, {Pre = "^", Suf = "_"})
  table.insert(affixes, {Pre = "_", Suf = "$"})
  table.insert(affixes, {Pre = "_", Suf = "_"})
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, affixes)
end

function Goon_Regenerate_Check(spell)
  local spellStrings = {"Target_Regenerate", "Target_ATT_Regenerate", "SDOE_Regenerate"}
  local affixes = {}
  table.insert(affixes, {Pre = "^", Suf = "_"})
  table.insert(affixes, {Pre = "_", Suf = "$"})
  table.insert(affixes, {Pre = "_", Suf = "_"})
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, affixes)
end

function Goon_Song_Of_Rest_Check(spell)
  local spellStrings = {"Shout_SongOfRest"}
  local affixes = {}
  table.insert(affixes, {Pre = "^", Suf = "_"})
  table.insert(affixes, {Pre = "_", Suf = "$"})
  table.insert(affixes, {Pre = "_", Suf = "_"})
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, affixes)
end

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

-- ==================================== Statuses ====================================

function Goon_Lesser_Restoration_Status_Check(status)
    return status == 'MAG_JHANNYL_GLOVES_LESSER_RESTORATION'
end

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if Goon_Lesser_Restoration_Status_Check(status) then
        Osi.ApplyStatus(object, "GOON_LESSER_RESTORATION_INJURY_REMOVAL", 1, 1, causee)
    end
end)
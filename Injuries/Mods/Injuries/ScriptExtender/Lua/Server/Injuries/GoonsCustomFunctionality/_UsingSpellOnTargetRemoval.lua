-- ==================================== Helper ====================================

-- Escape Lua pattern magic characters so spell base is treated literally
local function escape_lua_pattern(s)
  return s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Default affix patterns (adjust/add as needed)
local DefaultAffixes = {
  { Pre = "^",    Suf = "_.*$" },   -- base followed by "_" + anything
  { Pre = "^.-_", Suf = "$"    },   -- anything_ before base (ending at base)
  { Pre = "^.-_", Suf = "_.*$" },   -- anything_ before base and _anything after
}

function Goon_InjurySpellCheck_Helper(spell, possibleSpellStrings, affixes)
  -- print("[Helper] Checking spell:", spell)

  for _, spellString in pairs(possibleSpellStrings) do
    -- print("  Comparing against base:", spellString)

    -- 1) exact match
    if spell == spellString then
      -- print("  -> Direct match found:", spellString)
      return true
    end

    -- prepare literal-safe base for pattern assembly
    local escBase = escape_lua_pattern(spellString)

    -- 2) affix-based pattern matches (aff.Pre and aff.Suf are Lua patterns)
    for _, aff in ipairs(affixes) do
      local pattern = aff.Pre .. escBase .. aff.Suf
      -- print("    Trying affix pattern:", pattern)
      if string.match(spell, pattern) then
        -- print("    -> Affix match found:", spell, "with pattern:", pattern)
        return true
      end
    end
  end

  -- print("[Helper] Result for", spell, "= false")
  return false
end

-- ==================================== Spells ====================================

function Goon_Lesser_Restoration_Check(spell)
  -- print("[Check] Lesser Restoration:", spell)
  local spellStrings = {
    "Target_LesserRestoration",
    "Target_DEN_BearReward_LesserRestoration"
  }
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, DefaultAffixes)
end

function Goon_Greater_Restoration_Check(spell)
  -- print("[Check] Greater Restoration:", spell)
  local spellStrings = {
    "Target_GreaterRestoration",
    "Target_LOW_Hag_GreaterRestoration"
  }
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, DefaultAffixes)
end

function Goon_Heal_Check(spell)
  -- print("[Check] Heal:", spell)
  local spellStrings = {
    "Target_Heal",
    "Target_LOW_Raphael_Heal"
  }
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, DefaultAffixes)
end

function Goon_Regenerate_Check(spell)
  -- print("[Check] Regenerate:", spell)
  local spellStrings = {
    "Target_Regenerate",
    "Target_ATT_Regenerate",
    "SDOE_Regenerate"
  }
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, DefaultAffixes)
end

function Goon_Song_Of_Rest_Check(spell)
  -- print("[Check] Song of Rest:", spell)
  local spellStrings = {"Shout_SongOfRest"}
  return Goon_InjurySpellCheck_Helper(spell, spellStrings, DefaultAffixes)
end

-- ==================================== Event Hook ====================================

EventCoordinator:RegisterEventProcessor("UsingSpellOnTarget", function(caster, target, spell, spellType, spellElement, storyActionID)
  -- print("[Event] UsingSpellOnTarget -> caster:", caster, "target:", target, "spell:", spell)

  if Goon_Lesser_Restoration_Check(spell) then
    -- print("  -> Applying Lesser Restoration Injury Removal")
    Osi.ApplyStatus(target, "GOON_LESSER_RESTORATION_INJURY_REMOVAL", 1, 1, caster)
  elseif Goon_Greater_Restoration_Check(spell) then
    -- print("  -> Applying Greater Restoration Injury Removal")
    Osi.ApplyStatus(target, "GOON_GREATER_RESTORATION_INJURY_REMOVAL", 1, 1, caster)
  elseif Goon_Heal_Check(spell) then
    -- print("  -> Applying Heal Injury Removal")
    Osi.ApplyStatus(target, "GOON_HEAL_INJURY_REMOVAL", 1, 1, caster)
  elseif Goon_Regenerate_Check(spell) then
    -- print("  -> Applying Regenerate Injury Removal")
    Osi.ApplyStatus(target, "GOON_REGENERATE_INJURY_REMOVAL", 1, 1, caster)
  elseif Goon_Song_Of_Rest_Check(spell) then
    -- print("  -> Applying Song of Rest Injury Removal")
    Osi.ApplyStatus(target, "GOON_SONG_OF_REST_INJURY_REMOVAL", 1, 1, caster)
  else
    -- print("  -> No matching spell check for:", spell)
  end
end)

-- ==================================== Statuses ====================================

function Goon_Lesser_Restoration_Status_Check(status)
  -- print("[StatusCheck] Lesser Restoration status:", status)
  return status == 'MAG_JHANNYL_GLOVES_LESSER_RESTORATION'
end

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
  -- print("[Event] StatusApplied -> object:", object, "status:", status, "causee:", causee)
  if Goon_Lesser_Restoration_Status_Check(status) then
    -- print("  -> Applying Lesser Restoration Injury Removal from status")
    Osi.ApplyStatus(object, "GOON_LESSER_RESTORATION_INJURY_REMOVAL", 1, 1, causee)
  end
end)

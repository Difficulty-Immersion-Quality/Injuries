-- Can't assign any of these fields to local fields for convenience - breaks VSCode Lua type hints

--#region Injuries
ConfigurationStructure.config.injuries = {}

--#region Systems
ConfigurationStructure.config.injuries.systems = {
}

--#endregion

--#region Universal
ConfigurationStructure.config.injuries.universal = {}

ConfigurationStructure.config.injuries.universal.who_can_receive_injuries = {
	["Allies"] = true,
	["Party Members"] = true,
	["Enemies"] = true
}

-- #region Injury Removal
--- @alias how_many_injuries_can_be_removed_at_once "One"|"All"
--- @type how_many_injuries_can_be_removed_at_once
ConfigurationStructure.config.injuries.universal.how_many_injuries_can_be_removed_at_once = "One"

---@alias injury_removal_severity_priority "Random"|"Most Severe"
---@type injury_removal_severity_priority
ConfigurationStructure.config.injuries.universal.injury_removal_severity_priority = "Most Severe"

--- @type boolean
ConfigurationStructure.config.injuries.universal.remove_on_death = true

---@type boolean
ConfigurationStructure.config.injuries.universal.remove_all_on_long_rest = true
--#endregion

--#region Damage Counter
--- @alias injury_counter_reset "Attack/Tick"|"Round"|"Combat"|"Short Rest"|"Long Rest"
--- @type injury_counter_reset
ConfigurationStructure.config.injuries.universal.when_does_counter_reset = "Attack/Tick"

ConfigurationStructure.config.injuries.universal.apply_injuries_outside_combat = true

ConfigurationStructure.config.injuries.universal.healing_subtracts_injury_damage = true

ConfigurationStructure.config.injuries.universal.healing_subtracts_injury_damage_modifier = 1.0

ConfigurationStructure.config.injuries.universal.application_chance_by_severity = {
	["Low"] = 100,
	["Medium"] = 100,
	["High"] = 100,
	modifiers = {
		["Max Damage From Attack"] = 0,
		["Attack Was A Critical"] = 0,
		["Was Downed This Round"] = -100
	}
}


--#region NPC Modifiers
---@alias NPCCategories "Base"|"Boss"|"MiniBoss"|"Elite"|"Combatant"|"Pack"|"Zero"|"Civilian"
---@type { [NPCCategories] : number}
ConfigurationStructure.config.injuries.universal.npc_multipliers = {}
--#endregion

--#endregion

--#region Severity
ConfigurationStructure.config.injuries.universal.random_injury_conditional = {
	["Downed"] = true,
	["Suffered a Critical Hit"] = true
}

ConfigurationStructure.config.injuries.universal.random_injury_severity_weights = {
	["Low"] = 25,
	["Medium"] = 50,
	["High"] = 25
}

--- @type boolean
ConfigurationStructure.config.injuries.universal.random_injury_filter_by_damage_type = true
--#endregion

--#endregion

--#region Injury-Specific Options
---@class Injury
ConfigurationStructure.DynamicClassDefinitions.injury_class = {}

---@alias severity "Exclude"|"Low"|"Medium"|"High"
---@type severity
ConfigurationStructure.DynamicClassDefinitions.injury_class.severity = "Medium"

ConfigurationStructure.DynamicClassDefinitions.injury_class.include_in_random_table = true

---@type number
ConfigurationStructure.DynamicClassDefinitions.injury_class.chance_of_application = 100

---@class InjuryDamageTypeClass
ConfigurationStructure.DynamicClassDefinitions.injury_damage_type_class = {
	["multiplier"] = 1
}

--- @class InjuryDamageClass
ConfigurationStructure.DynamicClassDefinitions.injury_class.damage = {
	["threshold"] = 10,
	---@type { [DamageType] : InjuryDamageTypeClass }
	["damage_types"] = {}
}

---@class InjuryRemoveOnStatus
ConfigurationStructure.DynamicClassDefinitions.injury_remove_on_status_class = {
	---@type AbilityId|"No Save"
	["ability"] = "No Save",
	---@type number?
	["difficulty_class"] = nil,
	---@type number?
	["stacks_to_remove"] = nil,
	---@type string[]?
	["excluded_statuses"] = nil
}

---@alias StatusName string
---@alias InjuryRemoveOnStatusClass { [StatusName] : InjuryRemoveOnStatus }
---@type InjuryRemoveOnStatusClass
ConfigurationStructure.DynamicClassDefinitions.injury_class.remove_on_status = {}

---@class InjuryApplyOnStatusModifierClass
ConfigurationStructure.DynamicClassDefinitions.injury_apply_on_status_class = {
	["multiplier"] = 1,
	["guarantee_application"] = false,
	---@type string[]?
	["excluded_statuses"] = nil
}
---@class InjuryApplyOnStatusClass
ConfigurationStructure.DynamicClassDefinitions.injury_class.apply_on_status = {
	["number_of_rounds"] = 3,
	---@type { [StatusName] : InjuryApplyOnStatusModifierClass }
	["applicable_statuses"] = {},
}

---@class InjuryCharacterMultiplierClass
ConfigurationStructure.DynamicClassDefinitions.injury_class.character_multipliers = {
	---@type {[TAG] : number}?
	["tags"] = nil,
	---@type {[GUIDSTRING] : number}?
	["races"] = nil
}

---@alias InjuryName string
---@type { [InjuryName] : Injury }
ConfigurationStructure.config.injuries.injury_specific = {}
--#endregion

--#endregion

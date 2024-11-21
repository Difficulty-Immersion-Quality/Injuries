-- Can't assign any of these fields to local fields for convenience - breaks VSCode Lua type hints

--#region Injuries
ConfigurationStructure.config.injuries = {}

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
--#endregion

--#region Damage Counter
--- @alias injury_counter_reset "Attack/Tick"|"Round"|"Combat"|"Short Rest"|"Long Rest"
--- @type injury_counter_reset
ConfigurationStructure.config.injuries.universal.when_does_counter_reset = "Attack/Tick"

ConfigurationStructure.config.injuries.universal.healing_subtracts_injury_counter = true

--- @alias healing_subtracts_injury_counter_modifier "25%"|"50%"|"100%"|"150%"|"200%"
--- @type healing_subtracts_injury_counter_modifier
ConfigurationStructure.config.injuries.universal.healing_subtracts_injury_counter_modifier = "100%"
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
--#endregion

--#endregion

--#region Injury-Specific Options
---@class Injury
ConfigurationStructure.DynamicClassDefinitions.injury_class = {}

---@alias severity "Low"|"Medium"|"High"
---@type severity
ConfigurationStructure.DynamicClassDefinitions.injury_class.severity = "Medium"

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
	["difficulty_class"] = 15
}

---@alias StatusName string
---@alias InjuryRemoveOnStatusClass { [StatusName] : InjuryRemoveOnStatus }
---@type InjuryRemoveOnStatusClass
ConfigurationStructure.DynamicClassDefinitions.injury_class.remove_on_status = {}

---@class InjuryApplyOnStatus
ConfigurationStructure.DynamicClassDefinitions.injury_apply_on_status_class = {
	["number_of_rounds"] = 1
}
---@alias ApplyOnStatusClass { [StatusName] : InjuryApplyOnStatus }
---@type ApplyOnStatusClass
ConfigurationStructure.DynamicClassDefinitions.injury_class.apply_on_status = {}

---@alias InjuryName string
---@type { [InjuryName] : Injury }
ConfigurationStructure.config.injuries.injury_specific = {}
--#endregion

--#endregion

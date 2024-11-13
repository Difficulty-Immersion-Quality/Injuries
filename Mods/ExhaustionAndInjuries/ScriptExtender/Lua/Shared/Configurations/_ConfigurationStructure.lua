ConfigurationStructure = {}

local real_config_table = {}

local initialized = false
local updateTimer

-- This allows us to react to any changes made to fields at any level in the structure and send a NetMessage
-- just by defining the base table, ConfigurationStructure.config. Client/* implementations can now
-- reference any slice of this table and allow their IMGUI elements to modify the table without
-- any additional logic for letting the server know there were changes. Only works for this implementation -
-- too fragile for general use (e.g. doesn't account for the value being a table containing a table) - TODO: Fix?
local function generate_recursive_metatable(proxy_table, real_table)
	return setmetatable(proxy_table, {
		__index = function(this_table, key)
			return real_table[key]
		end,
		__newindex = function(this_table, key, value)
			real_table[key] = value

			if type(value) == "table" then
				rawset(proxy_table, key, generate_recursive_metatable({}, real_table[key]))
			end

			if initialized then
				if updateTimer then
					Ext.Timer.Cancel(updateTimer)
				end
				updateTimer = Ext.Timer.WaitFor(500, function()
					Logger:BasicDebug("Configuration updates made - sending updated table to server")

					Ext.ClientNet.PostMessageToServer(ModuleUUID .. "_UpdateConfiguration", Ext.Json.Stringify(real_config_table))
				end)
			end
		end
	})
end

--- Can't use metamethods to track key removal from a table, so this is a minor hack given that this doesn't happen much
function ConfigurationStructure:SignalConfigDeletion()
	Logger:BasicDebug("A config was deleted - sending updated config to server")
	Ext.ClientNet.PostMessageToServer(ModuleUUID .. "_UpdateConfiguration", Ext.Json.Stringify(real_config_table))
end

ConfigurationStructure.config = generate_recursive_metatable({}, real_config_table)

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
local injury_class = {}

---@alias severity "Low"|"Medium"|"High"
---@type severity
injury_class.severity = "Medium"

---@class InjuryDamage
local injury_damage_class = {
	["health_threshold"] = 10
}

---@type { [string] : InjuryDamage }
injury_class.damage = {}

---@type { [string] : Injury }
ConfigurationStructure.config.injuries.injury_specific = {}
--#endregion

--#endregion
initialized = true

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
			if key == "delete" then
				rawset(proxy_table, this_table._parent_key, nil)
				this_table._parent_table[this_table._parent_key] = nil
			else
				real_table[key] = value

				if type(value) == "table" then
					rawset(proxy_table, key, generate_recursive_metatable({_parent_key = key, _parent_table = real_table}, real_table[key]))
				end
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

function ConfigurationStructure:GetRealConfig()
	return TableUtils:MakeImmutableTableCopy(real_config_table)
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

local function CopyConfigsIntoReal(table_from_file, proxy_table)
	for key, value in pairs(table_from_file) do
		local default_value = proxy_table[key]
		-- if default_value then
			if type(value) == "table" then
				if not default_value then
					proxy_table[key] = {}
					default_value = proxy_table[key]
				end
				-- if type(default_value) == "table" then
					CopyConfigsIntoReal(value, default_value)
				-- else
				-- 	Logger:BasicWarning("Config property %s with value %s was loaded from the server and is a table, but the Config definition isn't a table - ignoring.",
				-- 		key,
				-- 		type(value) == "table" and Ext.Json.Stringify(value) or value)
				-- end
			else
				-- if type(default_value) ~= table then
					proxy_table[key] = value
				-- else
				-- 	Logger:BasicWarning("Config property %s with value %s was loaded from the server and is not a table, but the Config definition is a table - ignoring.",
				-- 		key,
				-- 		type(value) == "table" and Ext.Json.Stringify(value) or value)
				-- end
			end
		-- else
		-- 	Logger:BasicWarning("Config property %s with value %s was loaded from the server, but it's not in the Config definition - ignoring.",
		-- 		key,
		-- 		type(value) == "table" and Ext.Json.Stringify(value) or value)
		-- end
	end
end

function ConfigurationStructure:InitializeConfig()
	
	local config = FileUtils:LoadTableFile("config.json")

	if not config then
		config = ConfigurationStructure:GetRealConfig()
		FileUtils:SaveTableToFile("config.json", config)
	else
		CopyConfigsIntoReal(config, ConfigurationStructure.config)
	end

	initialized = true
	Logger:BasicInfo("Successfully loaded the config!")
end

-- Need to make sure the server's copy of the config is up-to-date since that's where the actual functionality is
-- Might as well use that as the place to update the config too
Ext.RegisterNetListener(ModuleUUID .. "_UpdateConfiguration", function(_, payload, _)
	CopyConfigsIntoReal(Ext.Json.Parse(payload), ConfigurationStructure.config)
	FileUtils:SaveTableToFile("config.json", real_config_table)
	Logger:BasicDebug("Successfully updated config on server side!")
end)


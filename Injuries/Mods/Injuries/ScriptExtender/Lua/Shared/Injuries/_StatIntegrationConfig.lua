---@class StatIntegrationConfig
ConfigurationStructure.config.injuries.statIntegration = {
	---@type {[GameLevel] : IntegrationConfig}
	levels = {},
	---@type {[string] : IntegrationConfig}
	statuses = {},
	---@type {[string] : IntegrationConfig}
	passives = {}
}

---@class IntegrationConfig
ConfigurationStructure.DynamicClassDefinitions.integration_configs = {
	---@type {["all"|DamageType]: number}?
	injuryDamageModifier = nil,
	healRandomInjury = {
		numberToHeal = 1,
		worstFirst = true
	},
	healInjuryDamage = {
		takeFromHealth = true,
		amountPercentage = 1
	},
}

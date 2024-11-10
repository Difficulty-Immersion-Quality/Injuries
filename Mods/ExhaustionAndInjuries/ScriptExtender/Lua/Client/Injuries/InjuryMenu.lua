InjuryMenu = {}
InjuryMenu.Tabs = { ["Generators"] = {} }

function InjuryMenu:RegisterTab(tabGenerator)
	table.insert(InjuryMenu.Tabs["Generators"], tabGenerator)
end

Ext.Require("Client/Injuries/Tabs/DamageTab.lua")
Ext.Require("Client/Injuries/Tabs/ApplyOnStatusTab.lua")

local InjuryTable = {}

Ext.Events.SessionLoaded:Subscribe(function()
	for _, name in pairs(Ext.Stats.GetStats("StatusData")) do
		if string.find(name, "Goon_Injury_") then
			local displayName = string.sub(name, string.len("Goon_Injury_") + 1)
			displayName = string.gsub(displayName, "_", " ")
			InjuryTable[displayName] = name
		end
	end

	Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Injuries",
		--- @param tabHeader ExtuiTreeParent
		function(tabHeader)
			local injuryCombobox = tabHeader:AddCombo("Injuries")

			local displayNames = {}
			for displayName, _ in pairs(InjuryTable) do
				table.insert(displayNames, displayName)
			end
			table.sort(displayNames)
			injuryCombobox.Options = displayNames
			injuryCombobox.SelectedIndex = 0

			local newTabBar = tabHeader:AddTabBar("TabBar")
			
			for _, tabGenerator in pairs(InjuryMenu.Tabs.Generators) do
				local success, error = pcall(function()
					tabGenerator(newTabBar)
				end)

				if not success then
					Logger:BasicError("Error while generating a new tab for the Injury Table\n\t%s", error)
				end
			end
		end)
end)

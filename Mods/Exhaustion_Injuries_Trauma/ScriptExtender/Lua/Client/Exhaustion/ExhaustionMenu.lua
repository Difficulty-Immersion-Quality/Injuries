ExhaustionMenu = {}
ExhaustionMenu.Tabs = { ["Generators"] = {} }

function ExhaustionMenu:RegisterTab(tabGenerator)
	table.insert(ExhaustionMenu.Tabs["Generators"], tabGenerator)
end

Ext.Require("Client/Exhaustion/Tabs/ActionTriggersTab.lua")
Ext.Require("Client/Exhaustion/Tabs/ApplyOnStatusTab.lua")
Ext.Require("Client/Exhaustion/Tabs/RemoveOnStatusTab.lua")

Ext.Events.SessionLoaded:Subscribe(function()
	Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Exhaustion",
		--- @param tabHeader ExtuiTreeParent
		function(tabHeader)
			local newTabBar = tabHeader:AddTabBar("ExhastionTabBar")

			for _, tabGenerator in pairs(ExhaustionMenu.Tabs.Generators) do
				local success, error = pcall(function()
					tabGenerator(newTabBar)
				end)

				if not success then
					Logger:BasicError("Error while generating a new tab for the Injury Table\n\t%s", error)
				end
			end
		end)
end)

InjuryMenu = {}
InjuryMenu.Tabs = { ["Generators"] = {} }

function InjuryMenu:RegisterTab(tabGenerator)
	table.insert(InjuryMenu.Tabs["Generators"], tabGenerator)
end

Ext.Require("Client/Injuries/Tabs/DamageTab.lua")
Ext.Require("Client/Injuries/Tabs/ApplyOnStatusTab.lua")
Ext.Require("Client/Injuries/Tabs/RemoveOnStatusTab.lua")

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
			--#region Universal Options
			tabHeader:AddSeparatorText("Universal Options")

			--#region Who Can Receive Injuries
			tabHeader:AddText("Who Can Receive Injuries?")
			local partyCheckbox = tabHeader:AddCheckbox("Party Members", true)

			local allyCheckbox = tabHeader:AddCheckbox("Allies", true)
			allyCheckbox.SameLine = true

			local enemyCheckbox = tabHeader:AddCheckbox("Enemies", true)
			enemyCheckbox.SameLine = true
			--#endregion

			--#region Injury Removal
			tabHeader:AddSeparator()
			tabHeader:AddText("How Many Different Injuries Can Be Removed At Once?")
			tabHeader:AddText("If multiple injuries share the same removal conditions, only the specified number will be removed at once - injuries will be randomly chosen.")
			local oneRadio = tabHeader:AddRadioButton("One", true)
			local allRadio = tabHeader:AddRadioButton("All", false)
			allRadio.SameLine = true

			oneRadio.OnActivate = function()
				oneRadio.Active = not oneRadio.Active
				allRadio.Active = oneRadio.Active
			end

			allRadio.OnActivate = function()
				allRadio.Active = not allRadio.Active
				oneRadio.Active = allRadio.Active
			end
			--#endregion

			--#region Damage Counter
			tabHeader:AddSeparator()
			tabHeader:AddText("When does the damage counter reset? Each")
			local cumulationCombo = tabHeader:AddCombo("")
			cumulationCombo.SameLine = true
			cumulationCombo.Options = {
				"Attack",
				"Round",
				"Combat",
				"Short Rest",
				"Long Rest"
			}
			cumulationCombo.SelectedIndex = 1
			--#endregion

			--#endregion

			--#region Injury-Specific Options
			tabHeader:AddSeparatorText("Injury-Specific Options")
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
			--#endregion
		end)
end)

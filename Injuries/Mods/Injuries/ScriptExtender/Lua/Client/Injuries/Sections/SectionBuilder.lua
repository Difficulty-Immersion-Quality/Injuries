---@class InjurySettingSectionBuilder
SectionBuilder = {
	---@type ExtuiTable
	parent = nil,
	---@type ExtuiTableCell
	settingSelectColumn = nil,
	---@type ExtuiTableCell
	settingManagerColumn = nil,
	---@type InjurySettingSection[]
	sections = nil
}

---@param parent ExtuiTreeParent
---@param sections InjurySettingSection[]
function SectionBuilder:build(parent, sections)
	---@type InjurySettingSectionBuilder
	local instance = {}

	setmetatable(instance, self)
	self.__index = self

	parent:AddSeparatorText("Settings")
	instance.parent = parent:AddTable("injurySettingUnder" .. (parent.IDContext or ""), 2)
	instance.parent.BordersInnerV = true

	instance.parent:AddColumn("settingSelect", "WidthFixed")
	instance.parent:AddColumn("settingManager", "WidthStretch")
	local row = instance.parent:AddRow()
	instance.settingSelectColumn = row:AddCell()
	instance.settingManagerColumn = row:AddCell()

	instance.sections = sections

	instance:buildSections()
end

function SectionBuilder:buildSections()
	for _, section in ipairs(self.sections) do
		---@type ExtuiSelectable
		local selectable = self.settingSelectColumn:AddSelectable(section.title)
		selectable.OnClick = function()
			UIHelpers:KillChildren(self.settingManagerColumn)

			if selectable.Selected then
				for _, childSelectable in pairs(self.settingSelectColumn.Children) do
					---@cast childSelectable ExtuiSelectable

					if childSelectable.Handle ~= selectable.Handle then
						childSelectable.Selected = false
					end
				end

				section:BuildBasicConfig(self.settingManagerColumn:AddGroup(section.title .. "settings"))

				local advancedSettings = self.settingManagerColumn:AddCollapsingHeader("Advanced")
				if not section:BuildAdvancedConfig(advancedSettings) then
					advancedSettings:Destroy()
				end
			end
		end
	end
end

---@class InjurySettingSection
Section = {
	---@type string
	title = nil
}

function Section:new(title)
	---@type InjurySettingSection
	local instance = {
		title = title
	}

	setmetatable(instance, self)
	self.__index = self

	return instance
end

---@param parent ExtuiTreeParent
function Section:BuildBasicConfig(parent) end

---@param parent ExtuiTreeParent
---@return boolean
function Section:BuildAdvancedConfig(parent)
	return false
end

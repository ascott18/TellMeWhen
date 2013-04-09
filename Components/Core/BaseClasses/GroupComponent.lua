-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local error
	= error
local tDeleteItem = TMW.tDeleteItem


--- {{{TMW.Classes.GroupComponent}}} is a base class of any objects that will be implemented into a {{{TMW.Classes.Group}}}
-- 
-- GroupComponent provides a common base for these objects, and it provides methods for registering default group settings and group configuration tables. It is an abstract class, and should not be directly instantiated.
-- 
-- @class file
-- @name GroupComponent.lua


local GroupComponent = TMW:NewClass("GroupComponent", "GenericComponent")
GroupComponent.ConfigTables = {}


function GroupComponent:OnClassInherit_GroupComponent(newClass)
	newClass:InheritTable(self, "ConfigTables")
end


--- Merges a set of default settings into {{{TMW.Group_Defaults}}}.
-- @param defaults [table] A table of default settings that will be merged into {{{TMW.Group_Defaults}}}.
-- @usage
--	GroupComponent:RegisterGroupDefaults{
--		SomeNonViewDependentSetting = true,
--		SettingsPerView = {
--			icon = {
--				TextLayout = "icon1",
--			},
--		},
--	}
function GroupComponent:RegisterGroupDefaults(defaults)
	TMW:ValidateType("2 (defaults)", "GroupComponent:RegisterGroupDefaults(defaults)", defaults, "table")
	
	if TMW.InitializedDatabase then
		error(("Defaults for component %q are being registered too late. They need to be registered before the database is initialized."):format(self.name or "<??>"))
	end
	
	-- Copy the defaults into the main defaults table.
	TMW:MergeDefaultsTables(defaults, TMW.Group_Defaults)
end


local function getParentTableFromPath(path)
	parentTable = TMW.approachTable(TMW.GroupConfigTemplate, strsplit(".", path))
	
	if parentTable == nil then
		error("An invalid parent table path passed to GroupComponent:RegisterConfigTable()!", 3)
	end
	
	return parentTable
end

--- Registers an AceConfig-3.0 options table that will only be displayed for groups that implement this {{{TMW.Classes.GroupComponent}}}. May be called before TellMeWhen_Options has been loaded.
-- @param parentTable [table|string] The parent table that {{{configTable}}} will be put in. Should be an AceConfig-3.0 {{{args}}} table, and should be nested within {{{TMW.GroupConfigTemplate}}}. If passed a string, this should be a period-delimited path to the desired parentTable, relative to {{{TMW.GroupConfigTemplate}}}. A string should be passed when calling this method before TellMeWhen_Options has been loaded.
-- @param key [string] The key that {{{configTable}}} will be assigned within {{{parentTable}}}.
-- @param configTable [table] The table that contains the necessary AceConfig-3.0 settings data.
-- @usage -- Example usage from GroupModule_Alpha:
--	TMW.Classes.GroupModule_Alpha:RegisterConfigTable(TMW.GroupConfigTemplate.args.main.args, "Alpha", {
--		name = L["UIPANEL_GROUPALPHA"],
--		desc = L["UIPANEL_GROUPALPHA_DESC"],
--		type = "range",
--		order = 24,
--		min = 0,
--		max = 1,
--		step = 0.01,
--	})
-- 
--	-- Example of calling with a string path to the parent table:
--	TMW.Classes.GroupModule_Alpha:RegisterConfigTable("args.main.args", "Alpha", {
--		name = L["UIPANEL_GROUPALPHA"],
--		desc = L["UIPANEL_GROUPALPHA_DESC"],
--		type = "range",
--		order = 24,
--		min = 0,
--		max = 1,
--		step = 0.01,
--	})
function GroupComponent:RegisterConfigTable(parentTable, key, configTable)
	self:AssertSelfIsClass()
	
	TMW:ValidateType("2 (defaults)", "GroupComponent:RegisterConfigTable(parentTable, key, configTable)", parentTable, "table;string")
	TMW:ValidateType("3 (key)", "GroupComponent:RegisterConfigTable(parentTable, key, configTable)", key, "string")
	TMW:ValidateType("4 (configTable)", "GroupComponent:RegisterConfigTable(parentTable, key, configTable)", configTable, "table")
	
	configTable.hidden = function(info)
		local g = TMW.FindGroupIDFromInfo(info)
		
		return not TMW[g] or not TMW[g]:GetModuleOrModuleChild(self.className, true)
	end
		
	if type(parentTable) == "string" and IsAddOnLoaded("TellMeWhen_Options") then
		parentTable = getParentTableFromPath(parentTable)
	end
	
	if type(parentTable) == "table" then
		self.ConfigTables[configTable] = parentTable
		parentTable[key] = configTable
		
	elseif type(parentTable) == "string" and not IsAddOnLoaded("TellMeWhen_Options") then
		TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
			parentTable = getParentTableFromPath(parentTable)
			
			self.ConfigTables[configTable] = parentTable
			parentTable[key] = configTable
			
		end)
	else
		error("WTF, why was this code reached?")
	end
	
end





-- [INTERNAL]
function GroupComponent:ImplementIntoGroup(group)
	if not group.ComponentsLookup[self] then
		group.ComponentsLookup[self] = true
		group.Components[#group.Components+1] = self
	
		if self.OnImplementIntoGroup then
			self:OnImplementIntoGroup(group)
		end
	end
end

-- [INTERNAL]
function GroupComponent:UnimplementFromGroup(group)
	if group.ComponentsLookup[self] then
	
		tDeleteItem(group.Components, self, true)
		group.ComponentsLookup[self] = nil
		
		if self.OnUnimplementFromGroup then
			self:OnUnimplementFromGroup(group)
		end
	end
end

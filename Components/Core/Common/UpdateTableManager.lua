-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print



local UpdateTableManager = TMW:NewClass("UpdateTableManager")

function UpdateTableManager:UpdateTable_Set(table)
	self.UpdateTable_UpdateTable = table or {} -- create an anonymous table if one wasnt passed in
	self.UpdateTable_Lookup = {} -- O(1) lookup table for registered items
	if table then
		for k,v in pairs(table) do
			self.UpdateTable_Lookup[v] = true
		end
	end
end

function UpdateTableManager:UpdateTable_Register(target)
	if not self.UpdateTable_UpdateTable then
		error("No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	end
	
	TMW:ValidateType("2 (target)", "UpdateTableManager:UpdateTable_Register(target)", target, "!boolean")
	
	if target == nil then
		if self.class == UpdateTableManager then
		TMW:ValidateType("2 (target)", "UpdateTableManager:UpdateTable_Register(target)", target, "!nil")
		else
			target = self
		end
	end
	

	local oldLength = #self.UpdateTable_UpdateTable

	if not self.UpdateTable_Lookup[target] then
		if self.UpdateTable_DoAutoSort then
			TMW.binaryInsert(self.UpdateTable_UpdateTable, target, self.UpdateTable_AutoSortFunc)
		else
			tinsert(self.UpdateTable_UpdateTable, target)
		end
		
		-- Add to lookup table
		self.UpdateTable_Lookup[target] = true
		
		-- Update indexed views
		self:UpdateTable_UpdateIndexedViews(target, "register")
		
		if oldLength == 0 and self.UpdateTable_OnUsed then
			self:UpdateTable_OnUsed()
		end
	end
end

function UpdateTableManager:UpdateTable_Unregister(target)
	if not self.UpdateTable_UpdateTable then
		error("No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	end
	
	target = target or self

	-- Check lookup table first to avoid O(n) deletion if item doesn't exist
	if not self.UpdateTable_Lookup[target] then
		-- No removal was done
		return false
	end

	local oldLength = #self.UpdateTable_UpdateTable

	TMW.tDeleteItem(self.UpdateTable_UpdateTable, target, true)
	
	-- Remove from lookup table
	self.UpdateTable_Lookup[target] = nil
	
	-- Update indexed views
	self:UpdateTable_UpdateIndexedViews(target, "unregister")
	
	if oldLength > 0 and #self.UpdateTable_UpdateTable == 0 and self.UpdateTable_OnUnused then
		self:UpdateTable_OnUnused()
	end

	-- Notify that a removal was done
	return true
end

function UpdateTableManager:UpdateTable_UnregisterAll()
	if not self.UpdateTable_UpdateTable then
		error("No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	end
	local oldLength = #self.UpdateTable_UpdateTable
	
	-- Clear all indexed views
	if self.UpdateTable_IndexedViews then
		for viewName, viewData in pairs(self.UpdateTable_IndexedViews) do
			wipe(viewData.index)
		end
	end
	
	wipe(self.UpdateTable_UpdateTable)
	wipe(self.UpdateTable_Lookup)
	
	if oldLength > 0 and self.UpdateTable_OnUnused then
		self:UpdateTable_OnUnused()
	end
end

function UpdateTableManager:UpdateTable_Sort(func)
	if not self.UpdateTable_UpdateTable then
		error("No update table was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Set one using self:UpdateTable_Set(table).")
	end
	
	sort(self.UpdateTable_UpdateTable, func)
end

function UpdateTableManager:UpdateTable_SetAutoSort(func)
	self.UpdateTable_DoAutoSort = not not func
	if type(func) == "function" then
		self.UpdateTable_DoAutoSort = true
		self.UpdateTable_AutoSortFunc = func
	elseif func == true then
		self.UpdateTable_DoAutoSort = true
		self.UpdateTable_AutoSortFunc = nil
	else
		self.UpdateTable_DoAutoSort = false
	end
end

function UpdateTableManager:UpdateTable_PerformAutoSort()
	if self.UpdateTable_DoAutoSort then
		self:UpdateTable_Sort(self.UpdateTable_AutoSortFunc)
	end
end

function UpdateTableManager:UpdateTable_CreateIndexedView(viewName, keyMapDelegate)
	TMW:ValidateType("2 (viewName)", "UpdateTableManager:UpdateTable_CreateIndexedView(viewName, keyMapDelegate)", viewName, "string")
	TMW:ValidateType("3 (keyMapDelegate)", "UpdateTableManager:UpdateTable_CreateIndexedView(viewName, keyMapDelegate)", keyMapDelegate, "function")
	
	if not self.UpdateTable_IndexedViews then
		self.UpdateTable_IndexedViews = {}
	end
	
	-- Initialize the indexed view
	self.UpdateTable_IndexedViews[viewName] = {
		keyMapDelegate = keyMapDelegate,
		index = {}
	}
	
	-- Populate the index with existing targets
	if self.UpdateTable_UpdateTable then
		for _, target in ipairs(self.UpdateTable_UpdateTable) do
			local key = keyMapDelegate(target)
			if key ~= nil then
				if not self.UpdateTable_IndexedViews[viewName].index[key] then
					self.UpdateTable_IndexedViews[viewName].index[key] = {}
				end
				tinsert(self.UpdateTable_IndexedViews[viewName].index[key], target)
			end
		end
	end

	return self.UpdateTable_IndexedViews[viewName].index
end

function UpdateTableManager:UpdateTable_GetIndexedView(viewName)
	TMW:ValidateType("2 (viewName)", "UpdateTableManager:UpdateTable_GetIndexedView(viewName)", viewName, "string")
	
	if not self.UpdateTable_IndexedViews or not self.UpdateTable_IndexedViews[viewName] then
		error("No indexed view named '" .. viewName .. "' was found for " .. tostring(self.GetName and self[0] and self:GetName() or self) .. ". Create one using self:UpdateTable_CreateIndexedView(viewName, keyMapDelegate).")
	end
	
	return self.UpdateTable_IndexedViews[viewName].index
end

--- @internal
function UpdateTableManager:UpdateTable_UpdateIndexedViews(target, operation)
	if not self.UpdateTable_IndexedViews then
		return
	end
	
	for viewName, viewData in pairs(self.UpdateTable_IndexedViews) do
		local key = viewData.keyMapDelegate(target)
		if key ~= nil then
			if operation == "register" then
				if not viewData.index[key] then
					viewData.index[key] = {}
				end
				tinsert(viewData.index[key], target)
			elseif operation == "unregister" then
				if viewData.index[key] then
					TMW.tDeleteItem(viewData.index[key], target, true)
					if #viewData.index[key] == 0 then
						viewData.index[key] = nil
					end
				end
			end
		end
	end
end


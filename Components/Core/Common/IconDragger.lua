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
	

	
local IconDragger = TMW:NewModule("IconDragger", "AceTimer-3.0", "AceEvent-3.0")
TMW.IconDragger = IconDragger

function IconDragger:OnInitialize()
	WorldFrame:HookScript("OnMouseDown", function() -- this contains other bug fix stuff too
		IconDragger.DraggerFrame:Hide()
		IconDragger.IsDragging = nil
	end)
end


---------- Icon Dragging ----------
function IconDragger:DropDownFunc()
	local lastAddedCentury = 1
	local hasAddedOne = false

	for i, handlerData in ipairs(IconDragger.Handlers) do
		local info = UIDropDownMenu_CreateInfo()

		info.notCheckable = true
		info.tooltipOnButton = true
		
		local shouldAddButton = handlerData.dropdownFunc(IconDragger, info)
		
		info.func = IconDragger.Handler
		info.arg1 = handlerData.actionFunc

		if shouldAddButton then
			-- Spacers are placed between each increment of 100 in the order.
			local thisCentury = floor(handlerData.order/100) + 1

			if hasAddedOne and lastAddedCentury < thisCentury then
				TMW.AddDropdownSpacer()
			end

			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			lastAddedCentury = thisCentury
			hasAddedOne = true
		end


	end	

	if hasAddedOne then
		TMW.AddDropdownSpacer()
	end
	
	local info = UIDropDownMenu_CreateInfo()
	info.text = CANCEL
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	UIDropDownMenu_JustifyText(self, "LEFT")
end

function IconDragger:Start(icon)
	IconDragger.srcicon = icon

	IconDragger.DraggerFrame:SetScale(icon.group:GetEffectiveScale())
	IconDragger.DraggerFrame.texture:SetTexture(IconDragger.srcicon.attributes.texture)
	
	IconDragger.DraggerFrame:Show()
	IconDragger.IsDragging = true
end

function IconDragger:SetIsDraggingFalse()
	IconDragger.IsDragging = false
end

function IconDragger:CompleteDrag(script, icon)
	IconDragger.DraggerFrame:Hide()
	IconDragger:ScheduleTimer("SetIsDraggingFalse", 0.1)

	-- icon is the destination
	icon = icon or GetMouseFocus()

	if IconDragger.IsDragging then

		if type(icon) == "table" and icon.IsIcon then -- if the frame that got the drag is an icon, set the destination stuff.

			IconDragger.desticon = icon
			IconDragger.destFrame = nil

			if script == "OnDragStop" then -- wait for OnDragReceived
				return
			end

			if IconDragger.desticon == IconDragger.srcicon then
				return
			end

			UIDropDownMenu_SetAnchor(IconDragger.DraggerFrame.Dropdown, 0, 0, "TOPLEFT", icon, "BOTTOMLEFT")

		else
			IconDragger.desticon = nil
			IconDragger.destFrame = icon -- not actually an icon. just some frame.
			local cursorX, cursorY = GetCursorPosition()
			local UIScale = UIParent:GetScale()
			UIDropDownMenu_SetAnchor(IconDragger.DraggerFrame.Dropdown, cursorX/UIScale, cursorY/UIScale, nil, UIParent, "BOTTOMLEFT")
		end

		if not DropDownList1:IsShown() or UIDROPDOWNMENU_OPEN_MENU ~= IconDragger.DraggerFrame.Dropdown then
			ToggleDropDownMenu(1, nil, IconDragger.DraggerFrame.Dropdown)
		end
	end
end

IconDragger.Handlers = {}
function IconDragger:RegisterIconDragHandler(order, dropdownFunc, actionFunc)
	TMW:ValidateType("2 (order)", "IconDragger:RegisterIconDragHandler(order, dropdownFunc, actionFunc)", order, "number")
	TMW:ValidateType("3 (func)", "IconDragger:RegisterIconDragHandler(order, dropdownFunc, actionFunc)", dropdownFunc, "function")
	TMW:ValidateType("4 (func)", "IconDragger:RegisterIconDragHandler(order, dropdownFunc, actionFunc)", actionFunc, "function")
	
	tinsert(IconDragger.Handlers, {
		order = order,
		dropdownFunc = dropdownFunc,
		actionFunc = actionFunc,
	})
	
	TMW:SortOrderedTables(IconDragger.Handlers)
end

IconDragger:RegisterIconDragHandler(1,	-- Move
	function(IconDragger, info)
		if IconDragger.desticon then
			info.text = L["ICONMENU_MOVEHERE"]
			info.tooltipTitle = nil
			info.tooltipText = nil
			return true
		end
	end,
	function(IconDragger)
		-- move the actual settings
		local srcgs = IconDragger.srcicon.group:GetSettings()
		local srcics = IconDragger.srcicon:GetSettings()
		
		TMW:PrepareIconSettingsForCopying(srcics, srcgs)
		
		IconDragger.desticon.group:GetSettings().Icons[IconDragger.desticon:GetID()] = srcicon:GetGUID()
		srcgs.Icons[IconDragger.srcicon:GetID()] = nil
		

		-- preserve buff/debuff/other types textures
		IconDragger.desticon:SetInfo("texture", IconDragger.srcicon.attributes.texture)
	end
)
IconDragger:RegisterIconDragHandler(2,	-- Copy
	function(IconDragger, info)
		if IconDragger.desticon then
			info.text = L["ICONMENU_COPYHERE"]
			info.tooltipTitle = nil
			info.tooltipText = nil
			return true
		end
	end,
	function(IconDragger)
		-- copy the settings
		local srcgs = IconDragger.srcicon.group:GetSettings()
		local srcics = IconDragger.srcicon:GetSettings()
		TMW:PrepareIconSettingsForCopying(srcics, srcgs)
		
		local newGUID = TMW:CloneData(IconDragger.srcicon:GetGUID())
		IconDragger.desticon.group:GetSettings().Icons[IconDragger.desticon:GetID()] = newGUID

		-- preserve buff/debuff/other types textures
		IconDragger.desticon:SetInfo("texture", IconDragger.srcicon.attributes.texture)
	end
)
IconDragger:RegisterIconDragHandler(3,	-- Swap
	function(IconDragger, info)
		if IconDragger.desticon then
			info.text = L["ICONMENU_SWAPWITH"]
			info.tooltipTitle = nil
			info.tooltipText = nil
			return true
		end
	end,
	function(IconDragger)
		-- swap the actual settings
		local destgs = IconDragger.desticon.group:GetSettings()
		local destics = IconDragger.desticon:GetSettings()
		local srcgs = IconDragger.srcicon.group:GetSettings()
		local srcics = IconDragger.srcicon:GetSettings()
		TMW:PrepareIconSettingsForCopying(destics, destgs)
		TMW:PrepareIconSettingsForCopying(srcics, srcgs)
		
		destgs.Icons[IconDragger.desticon:GetID()] = srcics
		srcgs.Icons[IconDragger.srcicon:GetID()] = destics

		-- preserve buff/debuff/other types textures
		local desttex = IconDragger.desticon.attributes.texture
		IconDragger.desticon:SetInfo("texture", IconDragger.srcicon.attributes.texture)
		IconDragger.srcicon:SetInfo("texture", desttex)
	end
)


IconDragger:RegisterIconDragHandler(40,	-- Split
	function(IconDragger, info)
		if IconDragger.destFrame then
			info.text = L["ICONMENU_SPLIT"]
			info.tooltipTitle = L["ICONMENU_SPLIT"]
			info.tooltipText = L["ICONMENU_SPLIT_DESC"]
			return true
		end
	end,
	function(IconDragger)
		local groupID, group = TMW:Group_Add()


		-- back up the icon data of the source group
		local SOURCE_ICONS = TMW.db.profile.Groups[IconDragger.srcicon.group:GetID()].Icons
		-- nullify it (we don't want to copy it)
		TMW.db.profile.Groups[IconDragger.srcicon.group:GetID()].Icons = nil

		-- copy the source group.
		-- pcall so that, in the rare event of some unforseen error, we don't lose the user's settings (they haven't yet been restored)
		local success, err = pcall(TMW.CopyTableInPlaceWithMeta, TMW, IconDragger.srcicon.group:GetSettings(), group:GetSettings())

		-- restore the icon data of the source group
		IconDragger.srcicon.group:GetSettings().Icons = SOURCE_ICONS
		
		-- now it is safe to error since we restored the old settings
		assert(success, err)


		local gs = group:GetSettings()

		-- group tweaks
		gs.Rows = 1
		gs.Columns = 1
		gs.Name = ""

		-- adjustments and positioning
		local p = gs.Point
		p.point, p.relativeTo, p.relativePoint, p.x, p.y = IconDragger.DraggerFrame.texture:GetPoint(2)
		
		p.relativeTo = "UIParent"
		
		group:Setup()

		-- move the actual icon settings
		gs.Icons[1] = IconDragger.srcicon:GetGUID()
		IconDragger.srcicon.group:GetSettings().Icons[IconDragger.srcicon:GetID()] = nil

		-- preserve textures
		if group and group[1] then
			group[1]:SetInfo("texture", IconDragger.srcicon.attributes.texture)
		end

		TMW[groupID]:Setup()
	end
)

---------- Icon Handler ----------
function IconDragger:Handler(method)
	-- close the menu
	CloseDropDownMenus()

	-- save misc. settings
	TMW.IE:SaveSettings()

	-- attempt to create a backup before doing anything
	TMW.IE:AttemptBackup(IconDragger.srcicon)
	TMW.IE:AttemptBackup(IconDragger.desticon)

	-- finally, invoke the method to handle the operation.
	method(IconDragger)

	-- then, update things
	TMW:Update()
	TMW.IE:Load(1)
end


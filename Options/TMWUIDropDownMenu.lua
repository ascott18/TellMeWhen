-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis

-- This file's code is heavily modified from Blizzard's UIDropDownMenu code.
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print



local DD = TMW:NewClass("Config_DropDownMenu", "Config_Frame"){
	noResize = 1,

	OnNewInstance_DropDownMenu = function(self, data)
		self.Button:SetMotionScriptsWhileDisabled(false)
		self.wrapTooltips = true

		if data then
			if data.func then
				self:SetFunction(data.func)
			end
			if data.title then
				self:SetText(data.title)
			end
		end
	end,

	SetTexts = function(self, title, tooltip)
		self:SetTooltip(title, tooltip)
		self:SetText(title)
	end,

	SetUIDropdownText = function(self, value, tbl, text)
		self.selectedValue = value

		if tbl then
			for k, v in pairs(tbl) do
				if v.value == value then
					self:SetText(v.text)
					return v
				end
			end
		end
		self:SetText(text or value)
	end,

	SetFunction = function(self, func)
		self.initialize = func
	end,

	METHOD_EXTENSIONS = {
		OnEnable = function(self)
			self.Button:Enable()
		end,
		OnDisable = function(self)
			self.Button:Disable()
		end,
	}
}


TMW.DROPDOWNMENU = DD
TMW.DD = DD




DD.MINBUTTONS = 0;
DD.MAXBUTTONS = 0;
DD.MAXLEVELS = 0;
DD.BUTTON_HEIGHT = 16;
DD.BORDER_HEIGHT = 15;
DD.MAX_HEIGHT = 400;
-- The current open menu
DD.OPEN_MENU = nil;
-- The current menu being initialized
DD.INIT_MENU = nil;
-- Current level shown of the open menu
DD.MENU_LEVEL = 1;
-- Current value of the open menu
DD.MENU_VALUE = nil;
-- Time to wait to hide the menu
DD.SHOW_TIME = 2;

DD.LISTS = CreateFrame("Frame", "TMWDropDowns")


local function fixself(self)
	if self == DD then
		self = self:GetCurrentDropDown()
	end
	return self
end

function DD:InitializeHelper()
	-- This deals with the always tainted stuff!
	if ( self ~= DD.OPEN_MENU ) then
		DD.MENU_LEVEL = 1;
	end

	-- Set the frame that's being intialized
	DD.INIT_MENU = self
	
	-- Hide all the buttons
	local button, dropDownList;
	for i = 1, DD.MAXLEVELS, 1 do
		dropDownList = DD.LISTS[i];
		if ( i >= DD.MENU_LEVEL or self ~= DD.OPEN_MENU ) then
			dropDownList.numButtons = 0;
			dropDownList.maxWidth = 0;
			for j=1, DD.MAXBUTTONS, 1 do
				button = dropDownList[j];
				button:Hide();
			end
			dropDownList:Hide();
		end
	end
end

function DD:Initialize(initFunction, displayMode, level, menuList)
	self.menuList = menuList;

	self:InitializeHelper()
	
	-- Set the initialize function and call it.  The initFunction populates the dropdown list.
	if ( initFunction ) then
		self.initialize = initFunction;
		initFunction(self, level, self.menuList);
	end

	--master frame
	if(level == nil) then
		level = 1;
	end
	DD.LISTS[level].dropdown = self;

	-- Change appearance based on the displayMode
	if ( displayMode == "MENU" ) then
		local name = self:GetName();
		self.Left:Hide();
		self.Middle:Hide();
		self.Right:Hide();
		self.Button:GetNormalTexture():SetTexture("");
		self.Button:GetDisabledTexture():SetTexture("");
		self.Button:GetPushedTexture():SetTexture("");
		self.Button:GetHighlightTexture():SetTexture("");
		self.Button:ClearAllPoints();
		self.Button:SetPoint("LEFT", name.."Text", "LEFT", -9, 0);
		self.Button:SetPoint("RIGHT", name.."Text", "RIGHT", 6, 0);
		self.displayMode = "MENU";
	end
end

-- Start the countdown on a frame
function DD.StartCounting(self)
	if ( self.parent ) then
		DD.StartCounting(self.parent);
	else
		self.showTimer = self.dropdown.SHOW_TIME
		self.isCounting = 1;
	end
end

-- Stop the countdown on a frame
function DD.StopCounting(self)
	if ( self.parent ) then
		DD.StopCounting(self.parent);
	else
		self.isCounting = nil;
	end
end

--[[
List of button attributes
======================================================
info.text = [STRING]  --  The text of the button
info.value = [ANYTHING]  --  The value that TMW.DD.MENU_VALUE is set to when the button is clicked
info.func = [function()]  --  The function that is called when you click the button
info.checked = [nil, true, function]  --  Check the button if true or function returns true
info.isNotRadio = [nil, true]  --  Check the button uses radial image if false check box image if true
info.isTitle = [nil, true]  --  If it's a title the button is disabled and the font color is set to yellow
info.disabled = [nil, true]  --  Disable the button and show an invisible button that still traps the mouseover event so menu doesn't time out
info.tooltipWhileDisabled = [nil, 1] -- Show the tooltip, even when the button is disabled.
info.hasArrow = [nil, true]  --  Show the expand arrow for multilevel menus
info.hasColorSwatch = [nil, true]  --  Show color swatch or not, for color selection
info.r = [1 - 255]  --  Red color value of the color swatch
info.g = [1 - 255]  --  Green color value of the color swatch
info.b = [1 - 255]  --  Blue color value of the color swatch
info.colorCode = [STRING] -- "|cAARRGGBB" embedded hex value of the button text color. Only used when button is enabled
info.swatchFunc = [function()]  --  Function called by the color picker on color change
info.hasOpacity = [nil, 1]  --  Show the opacity slider on the colorpicker frame
info.opacity = [0.0 - 1.0]  --  Percentatge of the opacity, 1.0 is fully shown, 0 is transparent
info.opacityFunc = [function()]  --  Function called by the opacity slider when you change its value
info.cancelFunc = [function(previousValues)] -- Function called by the colorpicker when you click the cancel button (it takes the previous values as its argument)
info.notClickable = [nil, 1]  --  Disable the button and color the font white
info.notCheckable = [nil, 1]  --  Shrink the size of the buttons and don't display a check box
info.owner = [Frame]  --  Dropdown frame that "owns" the current dropdownlist
info.keepShownOnClick = [nil, 1]  --  Don't hide the dropdownlist after a button is clicked
info.tooltipTitle = [nil, STRING] -- Title of the tooltip shown on mouseover
info.tooltipText = [nil, STRING] -- Text of the tooltip shown on mouseover
info.tooltipWrap = [nil, BOOLEAN] -- Set whether the tooltip text should wrap or not. If defined, this overrides DropDown.wrapTooltips
info.justifyH = [nil, "CENTER"] -- Justify button text
info.arg1 = [ANYTHING] -- This is the first argument used by info.func
info.arg2 = [ANYTHING] -- This is the second argument used by info.func
info.fontObject = [FONT] -- font object replacement for Normal and Highlight
info.menuTable = [TABLE] -- This contains an array of info tables to be displayed as a child menu
info.noClickSound = [nil, 1]  --  Set to 1 to suppress the sound when clicking the button. The sound only plays if .func is set.
info.padding = [nil, NUMBER] -- Number of pixels to pad the text on the right side
info.leftPadding = [nil, NUMBER] -- Number of pixels to pad the button on the left side
info.minWidth = [nil, NUMBER] -- Minimum width for this line
]]

local ButtonInfo = {};

function DD:CreateInfo()
	-- Reuse the same table to prevent memory churn
	
	return wipe(ButtonInfo);
end

function DD:CreateFrames(level, index)

	while ( level > DD.MAXLEVELS ) do
		DD.MAXLEVELS = DD.MAXLEVELS + 1;
		local newList = CreateFrame("Button", "$parentList" .. DD.MAXLEVELS, DD.LISTS, "TMW_UIDropDownListTemplate", DD.MAXLEVELS);
		newList:SetFrameStrata("FULLSCREEN_DIALOG");
		newList:SetToplevel(1);
		newList:Hide();
		newList:SetWidth(180)
		newList:SetHeight(10)
		for i=DD.MINBUTTONS+1, DD.MAXBUTTONS do
			newList[i] = CreateFrame("Button", nil, newList.Buttons, "TMW_UIDropDownMenuButtonTemplate", i);
			newList[i].listFrame = newList
		end
	end

	while ( index > DD.MAXBUTTONS ) do
		DD.MAXBUTTONS = DD.MAXBUTTONS + 1;
		for i=1, DD.MAXLEVELS do
			local listFrame = DD.LISTS[i]

			local button = CreateFrame("Button", nil, listFrame.Buttons, "TMW_UIDropDownMenuButtonTemplate", DD.MAXBUTTONS);
			button.listFrame = listFrame

			listFrame[DD.MAXBUTTONS] = button
		end
	end
end

function DD:AddButton(info, level)
	self = fixself(self)
	--[[
	Might to uncomment this if there are performance issues 
	if ( not self.OPEN_MENU ) then
		return;
	end
	]]
	if ( not level ) then
		level = self.MENU_LEVEL;
	end
	
	local listFrame = self.LISTS[level]
	local index = listFrame and (listFrame.numButtons + 1) or 1;
	local width;

	self:CreateFrames(level, index);
	
	listFrame = listFrame or self.LISTS[level]
	
	-- Set the number of buttons in the listframe
	listFrame.numButtons = index;
	
	local button = listFrame[index];
	local normalText = button:GetFontString();
	local icon = button.Icon;
	-- This button is used to capture the mouse OnEnter/OnLeave events if the dropdown button is disabled, since a disabled button doesn't receive any events
	-- This is used specifically for drop down menu time outs
	local invisibleButton = button.InvisibleButton;
	
	-- Default settings
	button:SetDisabledFontObject(GameFontDisableSmallLeft);
	invisibleButton:Hide();
	button:Enable();
	
	-- If not clickable then disable the button and set it white
	if ( info.notClickable ) then
		info.disabled = 1;
		button:SetDisabledFontObject(GameFontHighlightSmallLeft);
	end

	-- Set the text color and disable it if its a title
	if ( info.isTitle ) then
		info.disabled = 1;
		button:SetDisabledFontObject(GameFontNormalSmallLeft);
	end
	
	-- Disable the button if disabled and turn off the color code
	if ( info.disabled ) then
		button:Disable();
		invisibleButton:Show();
		info.colorCode = nil;
	end
	
	-- If there is a color for a disabled line, set it
	if( info.disablecolor ) then
		info.colorCode = info.disablecolor;
	end

	-- Configure button
	if ( info.text ) then
		-- look for inline color code this is only if the button is enabled
		if ( info.colorCode ) then
			button:SetText(info.colorCode..info.text.."|r");
		else
			button:SetText(info.text);
		end
		-- Determine the width of the button
		width = normalText:GetWidth() + 40;
		-- Add padding if has and expand arrow or color swatch
		if ( info.hasArrow or info.hasColorSwatch ) then
			width = width + 10;
		end
		if ( info.notCheckable ) then
			width = width - 30;
		end
		-- Set icon
		if ( info.icon ) then
			icon:SetTexture(info.icon);
			icon:ClearAllPoints();
			icon:SetPoint("RIGHT");

			if ( info.tCoordLeft ) then
				icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom);
			else
				icon:SetTexCoord(0, 1, 0, 1);
			end
			icon:Show();
			-- Add padding for the icon
			width = width + 10;
		else
			icon:Hide();
		end
		if ( info.padding ) then
			width = width + info.padding;
		end
		width = max(width, info.minWidth or 0);
		-- Set maximum button width
		if ( width > listFrame.maxWidth ) then
			listFrame.maxWidth = width;
		end
		-- Check to see if there is a replacement font
		if ( info.fontObject ) then
			button:SetNormalFontObject(info.fontObject);
			button:SetHighlightFontObject(info.fontObject);
		else
			button:SetNormalFontObject(GameFontHighlightSmallLeft);
			button:SetHighlightFontObject(GameFontHighlightSmallLeft);
		end
	else
		button:SetText("");
		icon:Hide();
	end
	
	button.iconOnly = nil;
	button.icon = nil;
	button.iconInfo = nil;
	if (info.iconOnly and info.icon) then
		button.iconOnly = true;
		button.icon = info.icon;
		button.iconInfo = info.iconInfo;

		self:SetIconImage(icon, info.icon, info.iconInfo);
		icon:ClearAllPoints();
		icon:SetPoint("LEFT");

		width = icon:GetWidth();
		if ( info.hasArrow or info.hasColorSwatch ) then
			width = width + 50 - 30;
		end
		if ( info.notCheckable ) then
			width = width - 30;
		end
		if ( width > listFrame.maxWidth ) then
			listFrame.maxWidth = width;
		end
	end

	-- Pass through attributes
	button.func = info.func;
	button.owner = info.owner;
	button.hasOpacity = info.hasOpacity;
	button.opacity = info.opacity;
	button.opacityFunc = info.opacityFunc;
	button.cancelFunc = info.cancelFunc;
	button.swatchFunc = info.swatchFunc;
	button.keepShownOnClick = info.keepShownOnClick;
	button.tooltipTitle = info.tooltipTitle;
	button.tooltipText = info.tooltipText;
	button.tooltipWrap = info.tooltipWrap;
	button.arg1 = info.arg1;
	button.arg2 = info.arg2;
	button.hasArrow = info.hasArrow;
	button.hasColorSwatch = info.hasColorSwatch;
	button.notCheckable = info.notCheckable;
	button.menuList = info.menuList;
	button.tooltipWhileDisabled = info.tooltipWhileDisabled;
	button.noClickSound = info.noClickSound;
	button.padding = info.padding;
	
	if ( info.value ) then
		button.value = info.value;
	elseif ( info.text ) then
		button.value = info.text;
	else
		button.value = nil;
	end
	
	-- Show the expand arrow if it has one
	if ( info.hasArrow ) then
		button.ExpandArrow:Show();
	else
		button.ExpandArrow:Hide();
	end
	button.hasArrow = info.hasArrow;
	
	-- If not checkable move everything over to the left to fill in the gap where the check would be
	local xPos = 5;
	local yPos = -((button:GetID() - 1) * DD.BUTTON_HEIGHT) -- - DD.BORDER_HEIGHT;
	local displayInfo = normalText;
	if (info.iconOnly) then
		displayInfo = icon;
	end
	
	displayInfo:ClearAllPoints();
	if ( info.notCheckable ) then
		if ( info.justifyH and info.justifyH == "CENTER" ) then
			displayInfo:SetPoint("CENTER", button, "CENTER", -7, 0);
		else
			displayInfo:SetPoint("LEFT", button, "LEFT", 0, 0);
		end
		xPos = xPos + 10;
		
	else
		xPos = xPos + 12;
		displayInfo:SetPoint("LEFT", button, "LEFT", 20, 0);
	end

	-- Adjust offset if displayMode is menu
	if ( self and self.displayMode == "MENU" ) then
		if ( not info.notCheckable ) then
			xPos = xPos - 6;
		end
	end
	
	if ( info.leftPadding ) then
		xPos = xPos + info.leftPadding;
	end
	button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", xPos, yPos);


	if not info.notCheckable then 
		if info.isNotRadio then
			button.Check:SetTexCoord(0.0, 0.5, 0.0, 0.5);
			button.UnCheck:SetTexCoord(0.5, 1.0, 0.0, 0.5);
		else
			button.Check:SetTexCoord(0.0, 0.5, 0.5, 1.0);
			button.UnCheck:SetTexCoord(0.5, 1.0, 0.5, 1.0);
		end
		
		-- Checked can be a function now
		local checked = info.checked;
		if ( type(checked) == "function" ) then
			checked = checked(button);
		end

		-- Show the check if checked
		if ( checked ) then
			button:LockHighlight();
			button.Check:Show();
			button.UnCheck:Hide();
		else
			button:UnlockHighlight();
			button.Check:Hide();
			button.UnCheck:Show();
		end
	else
		button.Check:Hide();
		button.UnCheck:Hide();
	end	
	button.checked = info.checked;

	-- If has a colorswatch, show it and vertex color it
	local colorSwatch = button.ColorSwatch;
	if ( info.hasColorSwatch ) then
		colorSwatch:GetNormalTexture():SetVertexColor(info.r, info.g, info.b);
		button.r = info.r;
		button.g = info.g;
		button.b = info.b;
		colorSwatch:Show();
	else
		colorSwatch:Hide();
	end

	local height = (index * self.BUTTON_HEIGHT) + (self.BORDER_HEIGHT * 2)
	if height > self.MAX_HEIGHT and self:GetScrollable() then
		height = self.MAX_HEIGHT
		listFrame.shouldScroll = true
	else
		listFrame.shouldScroll = false
	end
	listFrame:SetHeight(height);

	button:Show();
end

local spacerInfo = {
	text = "",
	isTitle = true,
	notCheckable = true,
}
function DD:AddSpacer()
	self:AddButton(spacerInfo)
end



function DD:Refresh(useValue, dropdownLevel)
	local button, checked, checkImage, uncheckImage, normalText, width;
	local maxWidth = 0;
	local somethingChecked = nil; 
	if ( not dropdownLevel ) then
		dropdownLevel = DD.MENU_LEVEL;
	end

	local listFrame = DD.LISTS[dropdownLevel];
	listFrame.numButtons = listFrame.numButtons or 0;
	-- Just redraws the existing menu
	for i=1, DD.MAXBUTTONS do
		button = listFrame[i];
		checked = nil;

		if (button.checked and type(button.checked) == "function") then
			checked = button.checked(button);
		end

		if not button.notCheckable and button:IsShown() then	
			-- If checked show check image
			checkImage = button.Check;
			uncheckImage = button.UnCheck;
			if ( checked ) then
				somethingChecked = true;
				local icon = self.Icon;
				if (button.iconOnly and icon and button.icon) then
					DD:SetIconImage(icon, button.icon, button.iconInfo);
				elseif ( useValue ) then
					DD.SetText(self, button.value);
					icon:Hide();
				else
					DD.SetText(self, button:GetText());
					icon:Hide();
				end
				button:LockHighlight();
				checkImage:Show();
				uncheckImage:Hide();
			else
				button:UnlockHighlight();
				checkImage:Hide();
				uncheckImage:Show();
			end
		end

		if ( button:IsShown() ) then
			if ( button.iconOnly ) then
				local icon = self.Icon;
				width = icon:GetWidth();
			else
				normalText = button:GetFontString();
				width = normalText:GetWidth() + 40;
			end
			-- Add padding if has and expand arrow or color swatch
			if ( button.hasArrow or button.hasColorSwatch ) then
				width = width + 10;
			end
			if ( button.notCheckable ) then
				width = width - 30;
			end
			if ( button.padding ) then
				width = width + button.padding;
			end
			if ( width > maxWidth ) then
				maxWidth = width;
			end
		end
	end

	if(somethingChecked == nil) then
		self:SetText(VIDEO_QUALITY_LABEL6);
	end

end

function DD:RefreshAll(useValue)
	for dropdownLevel = DD.MENU_LEVEL, 2, -1 do
		local listFrame = DD.LISTS[dropdownLevel]
		if ( listFrame:IsShown() ) then
			self:Refresh(nil, dropdownLevel);
		end
	end
	-- useValue is the text on the dropdown, only needs to be set once
	self:Refresh(useValue, 1);
end

function DD:SetIconImage(icon, texture, info)
	icon:SetTexture(texture);
	if ( info.tCoordLeft ) then
		icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom);
	else
		icon:SetTexCoord(0, 1, 0, 1);
	end
	if ( info.tSizeX ) then
		icon:SetWidth(info.tSizeX);
	else
		icon:SetWidth(16);
	end
	if ( info.tSizeY ) then
		icon:SetHeight(info.tSizeY);
	else
		icon:SetHeight(16);
	end
	icon:Show();
end


function DD.Button_OnClick(self)
	local checked = self.checked;
	if ( type (checked) == "function" ) then
		checked = checked(self);
	end
	

	if ( self.keepShownOnClick ) then
		if not self.notCheckable then
			if ( checked ) then
				self.Check:Hide();
				self.UnCheck:Show();
				checked = false;
			else
				self.Check:Show();
				self.UnCheck:Hide();
				checked = true;
			end
		end
	else
		self.listFrame:Hide();
	end

	if ( type (self.checked) ~= "function" ) then 
		self.checked = checked;
	end

	-- saving this here because func might use a dropdown, changing this self's attributes
	local playSound = true;
	if ( self.noClickSound ) then
		playSound = false;
	end

	local func = self.func;
	if ( func ) then
		func(self, self.arg1, self.arg2, checked);
	else
		return;
	end

	if ( playSound ) then
		PlaySound("UChatScrollButton");
	end
end

function DD:HideDropDownMenu(level)
	local listFrame = DD.LISTS[level];
	listFrame:Hide();
end

function DD:Toggle(level, value, anchorName, xOffset, yOffset, menuList, button, autoHideDelay)
	local dropDownFrame = self

	if ( not level ) then
		level = 1;
	end

	DD:CreateFrames(level, 0);

	DD.MENU_LEVEL = level;
	DD.MENU_VALUE = value;
	local listFrame = DD.LISTS[level]

	local tempFrame;
	local point, relativePoint, relativeTo;
	if ( not dropDownFrame ) then
		tempFrame = button:GetParent();
	else
		tempFrame = dropDownFrame;
	end
	if ( listFrame:IsShown() and (DD.OPEN_MENU == tempFrame) ) then
		listFrame:Hide();
	else
		-- Set the dropdownframe scale
		local uiScale;
		local uiParentScale = UIParent:GetScale();
		--if ( tempFrame ~= WorldMapContinentDropDown and tempFrame ~= WorldMapZoneDropDown ) then
			if ( GetCVar("useUIScale") == "1" ) then
				uiScale = tonumber(GetCVar("uiscale"));
				if ( uiParentScale < uiScale ) then
					uiScale = uiParentScale;
				end
			else
				uiScale = uiParentScale;
			end
		--else
		--	uiScale = 1;
		--end
		listFrame:SetScale(uiScale);
		
		-- Hide the listframe anyways since it is redrawn OnShow() 
		listFrame:Hide();
		
		-- Frame to anchor the dropdown menu to
		local anchorFrame;

		-- Display stuff
		-- Level specific stuff
		if ( level == 1 ) then	
			DD.OPEN_MENU = dropDownFrame

			listFrame:ClearAllPoints();
			-- If there's no specified anchorName then use left side of the dropdown menu
			if ( not anchorName ) then
				-- See if the anchor was set manually using setanchor
				if ( dropDownFrame.xOffset ) then
					xOffset = dropDownFrame.xOffset;
				end
				if ( dropDownFrame.yOffset ) then
					yOffset = dropDownFrame.yOffset;
				end
				if ( dropDownFrame.point ) then
					point = dropDownFrame.point;
				end
				if ( dropDownFrame.relativeTo ) then
					relativeTo = dropDownFrame.relativeTo;
				else
					relativeTo = DD.OPEN_MENU.Left;
				end
				if ( dropDownFrame.relativePoint ) then
					relativePoint = dropDownFrame.relativePoint;
				end
			elseif ( anchorName == "cursor" ) then
				relativeTo = nil;
				local cursorX, cursorY = GetCursorPosition();
				cursorX = cursorX/uiScale;
				cursorY =  cursorY/uiScale;

				if ( not xOffset ) then
					xOffset = 0;
				end
				if ( not yOffset ) then
					yOffset = 0;
				end
				xOffset = cursorX + xOffset;
				yOffset = cursorY + yOffset;
			else
				-- See if the anchor was set manually using setanchor
				if ( dropDownFrame.xOffset ) then
					xOffset = dropDownFrame.xOffset;
				end
				if ( dropDownFrame.yOffset ) then
					yOffset = dropDownFrame.yOffset;
				end
				if ( dropDownFrame.point ) then
					point = dropDownFrame.point;
				end
				if ( dropDownFrame.relativeTo ) then
					relativeTo = dropDownFrame.relativeTo;
				else
					relativeTo = anchorName;
				end
				if ( dropDownFrame.relativePoint ) then
					relativePoint = dropDownFrame.relativePoint;
				end
			end
			if ( not xOffset or not yOffset ) then
				xOffset = 8;
				yOffset = 22;
			end
			if ( not point ) then
				point = "TOPLEFT";
			end
			if ( not relativePoint ) then
				relativePoint = "BOTTOMLEFT";
			end
			listFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
		else
			if ( not dropDownFrame ) then
				dropDownFrame = DD.OPEN_MENU;
			end
			listFrame:ClearAllPoints();
			-- If this is a dropdown button, not the arrow anchor it to itself
			local bParent = button:GetParent()
			if DD.LISTS[bParent:GetID()] == bParent then
				anchorFrame = button;
			else
				anchorFrame = button:GetParent();
			end
			point = "TOPLEFT";
			relativePoint = "TOPRIGHT";
			listFrame:SetPoint(point, anchorFrame, relativePoint, 0, 0);
		end
		
		-- Change list box appearance depending on display mode
		if ( dropDownFrame and dropDownFrame.displayMode == "MENU" ) then
			listFrame.Backdrop:Hide();
			listFrame.MenuBackdrop:Show();
		else
			listFrame.Backdrop:Show();
			listFrame.MenuBackdrop:Hide();
		end
		dropDownFrame.menuList = menuList;
		DD.Initialize(dropDownFrame, dropDownFrame.initialize, nil, level, menuList);
		-- If no items in the drop down don't show it
		if ( listFrame.numButtons == 0 ) then
			return;
		end

		-- Check to see if the dropdownlist is off the screen, if it is anchor it to the top of the dropdown button
		listFrame:Show();
		-- Hack since GetCenter() is returning coords relative to 1024x768
		local x, y = listFrame:GetCenter();
		-- Hack will fix this in next revision of dropdowns
		if ( not x or not y ) then
			listFrame:Hide();
			return;
		end

		listFrame.onHide = dropDownFrame.onHide;
		
		
		--  We just move level 1 enough to keep it on the screen. We don't necessarily change the anchors.
		if ( level == 1 ) then
			local offLeft = listFrame:GetLeft()/uiScale;
			local offRight = (GetScreenWidth() - listFrame:GetRight())/uiScale;
			local offTop = (GetScreenHeight() - listFrame:GetTop())/uiScale;
			local offBottom = listFrame:GetBottom()/uiScale;
			
			local xAddOffset, yAddOffset = 0, 0;
			if ( offLeft < 0 ) then
				xAddOffset = -offLeft;
			elseif ( offRight < 0 ) then
				xAddOffset = offRight;
			end
			
			if ( offTop < 0 ) then
				yAddOffset = offTop;
			elseif ( offBottom < 0 ) then
				yAddOffset = -offBottom;
			end
			
			listFrame:ClearAllPoints();
			if ( anchorName == "cursor" ) then
				listFrame:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset);
			else
				listFrame:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset);
			end
		else
			-- Determine whether the menu is off the screen or not
			local offscreenY, offscreenX;
			if ( (y - listFrame:GetHeight()/2) < 0 ) then
				offscreenY = 1;
			end
			if ( listFrame:GetRight() > GetScreenWidth() ) then
				offscreenX = 1;	
			end
			if ( offscreenY and offscreenX ) then
				point = gsub(point, "TOP(.*)", "BOTTOM%1");
				point = gsub(point, "(.*)LEFT", "%1RIGHT");
				relativePoint = gsub(relativePoint, "TOP(.*)", "BOTTOM%1");
				relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT");
				xOffset = -11;
				yOffset = -14;
			elseif ( offscreenY ) then
				point = gsub(point, "TOP(.*)", "BOTTOM%1");
				relativePoint = gsub(relativePoint, "TOP(.*)", "BOTTOM%1");
				xOffset = 0;
				yOffset = -14;
			elseif ( offscreenX ) then
				point = gsub(point, "(.*)LEFT", "%1RIGHT");
				relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT");
				xOffset = -11;
				yOffset = 14;
			else
				xOffset = 0;
				yOffset = 14;
			end
			
			listFrame:ClearAllPoints();
			listFrame:SetPoint(point, anchorFrame, relativePoint, xOffset, yOffset);

			listFrame:SetFrameLevel(DD.LISTS[level-1]:GetFrameLevel() + 10)
		end

		if ( autoHideDelay and tonumber(autoHideDelay)) then
			listFrame.showTimer = autoHideDelay;
			listFrame.isCounting = 1;
		end
	end
end

function DD:CloseDropDownMenus(level)
	if ( not level ) then
		level = 1;
	end
	for i=level, DD.MAXLEVELS do
		DD.LISTS[i]:Hide();
	end
end

function DD:SetText(text)
	self.Text:SetText(text)
end

function DD:GetText()
	return self.Text:GetText()
end

function DD:ClearAll()
	-- Previous code refreshed the menu quite often and was a performance bottleneck
	self.selectedID = nil;
	self.selectedName = nil;
	self.selectedValue = nil;
	DD.SetText(self, "");

	local button, checkImage, uncheckImage;
	for i=1, DD.MAXBUTTONS do
		button = DD.LISTS[DD.MENU_LEVEL][i];
		button:UnlockHighlight();

		checkImage = button.Check;
		checkImage:Hide();
		uncheckImage = button.UnCheck;
		uncheckImage:Hide();
	end
end

function DD:JustifyText(justification)
	local text = self.Text
	text:ClearAllPoints();
	if ( justification == "LEFT" ) then
		text:SetPoint("LEFT", self.Left, "LEFT", 27, 1);
		text:SetJustifyH("LEFT");
	elseif ( justification == "RIGHT" ) then
		text:SetPoint("RIGHT", self.Right, "RIGHT", -43, 1);
		text:SetJustifyH("RIGHT");
	elseif ( justification == "CENTER" ) then
		text:SetPoint("CENTER", self.Middle, "CENTER", -5, 1);
		text:SetJustifyH("CENTER");
	end
end

function DD:SetDropdownAnchor(point, relativeTo, relativePoint, xOffset, yOffset)
	self.xOffset = xOffset;
	self.yOffset = yOffset;
	self.point = point;
	self.relativeTo = relativeTo;
	self.relativePoint = relativePoint;
end

function DD:GetCurrentDropDown()
	if ( DD.OPEN_MENU ) then
		return DD.OPEN_MENU;
	elseif ( DD.INIT_MENU ) then
		return DD.INIT_MENU;
	end
end


function DD:OnDisable()
	self.Text:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	self.Button:Disable();
	self.Enabled = false;
end

function DD:OnEnable()
	self.Text:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	self.Button:Enable();
	self.Enabled = true;
end

function DD:SetScrollable(scrollable, maxHeight)
	self = fixself(self)

	self.scrollable = scrollable
	self.MAX_HEIGHT = maxHeight
end

function DD:GetScrollable()
	self = fixself(self)
	
	return self.scrollable
end







TMW:NewClass("Config_DropDownMenu_Icon", "Config_DropDownMenu"){
	previewSize = 18,

	OnNewInstance_DropDownMenu_Icon = function(self, data)
		self:SetPreviewSize(self.previewSize)
	end,

	SetPreviewSize = function(self, size)
		self.previewSize = size
		self.IconPreview:SetSize(size, size)
		self.Left:SetPoint("LEFT", -17 + size, 0)
	end,


	SetUIDropdownGUIDText = function(self, GUID, text)
		self.selectedValue = GUID

		local owner = TMW.GUIDToOwner[GUID]
		local type = TMW:ParseGUID(GUID)

		if owner then
			if type == "icon" then
				local icon = owner

				self:SetText(icon:GetIconMenuText())

				return icon

			elseif type == "group" then
				local group = owner

				self:SetText(group:GetGroupName())

				return group
			end

		elseif GUID and GUID ~= "" then
			if type == "icon" then
				text = L["UNKNOWN_ICON"]
			elseif type == "group" then
				text = L["UNKNOWN_GROUP"]
			else
				text = L["UNKNOWN_UNKNOWN"]
			end
		end
		
		self:SetText(text)
	end,

	SetIconPreviewIcon = function(self, icon)
		if not icon or not icon.IsIcon then
			self.IconPreview:Hide()
			return
		end

		local desc = L["ICON_TOOLTIP2NEWSHORT"]

		if TMW.db.global.ShowGUIDs then
			desc = desc .. "\r\n\r\n|cffffffff" .. (not icon.TempGUID and (icon:GetGUID() .. "\r\n") or "") .. icon.group:GetGUID()
		end

		TMW:TT(self.IconPreview, icon:GetIconName(), desc, 1, 1)
		self.IconPreview.icon = icon
		self.IconPreview.texture:SetTexture(icon and icon.attributes.texture)
		self.IconPreview:Show()
	end,

	SetGUID = function(self, GUID)
		local icon = TMW.GUIDToOwner[GUID]

		self:SetUIDropdownGUIDText(GUID, L["CHOOSEICON"])
		self:SetIconPreviewIcon(icon)
	end,

	SetIcon = function(self, icon)
		local GUID = icon:GetGUID()

		self:SetUIDropdownGUIDText(GUID, L["CHOOSEICON"])
		self:SetIconPreviewIcon(icon)
	end,

}
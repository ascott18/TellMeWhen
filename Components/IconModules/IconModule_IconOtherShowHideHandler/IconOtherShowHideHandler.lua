-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local type = type
	

local Module = TMW:NewClass("IconModule_IconEventOtherShowHideHandler", "IconModule")
Module.dontInherit = true

TMW:RegisterUpgrade(60014, {
	-- I just discovered that this module use a string "Icon" event setting for the icon to watch
	-- that conflicts with other event settings. Try to fix it.
	icon = function(self, ics)
		for _, eventSettings in TMW:InNLengthTable(ics.Events) do
			if type(eventSettings.Icon) == "boolean" then
				eventSettings.Icon = ""
			end
		end
	end,
})

Module:RegisterIconEvent(81, "OnIconShow", {
	text = L["SOUND_EVENT_ONICONSHOW"],
	desc = L["SOUND_EVENT_ONICONSHOW_DESC"],
	settings = {
		Icon = true,
	},
})
Module:RegisterIconEvent(82, "OnIconHide", {
	text = L["SOUND_EVENT_ONICONHIDE"],
	desc = L["SOUND_EVENT_ONICONHIDE_DESC"],
	settings = {
		Icon = true,
	},
})

Module:ExtendMethod("OnImplementIntoIcon", function(self, icon)
	local EventHandlersSet = icon.EventHandlersSet
	
	if EventHandlersSet.OnIconShow or EventHandlersSet.OnIconHide then
		self:Enable()
	else
		self:Disable()
	end
end)

local function TMW_ICON_DATA_CHANGED_REALALPHA(icon, event, ic, alpha, oldalpha)
	if TMW.Locked then
		-- ic is the icon that changed
		-- icon is the icon that might be handling it
		
		local iconEvent
		if alpha == 0 then
			iconEvent = "OnIconHide"
		elseif oldalpha == 0 then
			iconEvent = "OnIconShow"
		end
		
		if iconEvent and icon.EventHandlersSet[iconEvent] then
			local icName = ic:GetName()
			
			for _, EventSettings in TMW:InNLengthTable(icon.Events) do
				if EventSettings.iconEvent == iconEvent and EventSettings.Icon == icName then
					icon:QueueEvent(EventSettings)
				end
			end
		end
	end
end

function Module:OnEnable()
	TMW:RegisterCallback("TMW_ICON_DATA_CHANGED_REALALPHA", TMW_ICON_DATA_CHANGED_REALALPHA, self.icon)
end

function Module:OnDisable()
	TMW:UnregisterCallback("TMW_ICON_DATA_CHANGED_REALALPHA", TMW_ICON_DATA_CHANGED_REALALPHA, self.icon)
end

TMW:RegisterCallback("TMW_CONFIG_ICON_RECONCILIATION_REQUESTED", function(event, replace, limitSourceGroup)
	for ics, groupID in TMW:InIconSettings() do
		if not limitSourceGroup or groupID == limitSourceGroup then
			for _, eventSettings in TMW:InNLengthTable(ics.Events) do
				if type(eventSettings.Icon) == "string" then
					replace(eventSettings, "Icon")
				end
			end
		end
	end
end)
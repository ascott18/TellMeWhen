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

local type = type
	

local Module = TMW:NewClass("IconModule_IconEventOtherShowHideHandler", "IconModule")
Module.dontInherit = true

TMW.Classes.EventHandler:RegisterEventDefaults{
	Icon			= "",
}

TMW:RegisterUpgrade(60014, {
	-- I just discovered that this module use a string "Icon" event setting for the icon to watch
	-- that conflicts with other event settings. Try to fix it.
	iconEventHandler = function(self, eventSettings)
		if type(eventSettings.Icon) == "boolean" then
			eventSettings.Icon = ""
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

		for i, EventSettings in TMW:InNLengthTable(icon.Events) do
			if EventSettings.Event == "OnIconShow" or EventSettings.Event == "OnIconHide" then
				TMW:QueueValidityCheck(icon, EventSettings.Icon, L["VALIDITY_ONICONSHOWHIDE_DESC"], i)
			end
		end
		
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
			local icGUID = ic:GetGUID()
			
			if icGUID then
				for _, EventSettings in TMW:InNLengthTable(icon.Events) do
					if EventSettings.Event == iconEvent and EventSettings.Icon == icGUID then
						icon:QueueEvent(EventSettings)
					end
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

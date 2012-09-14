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


local Alpha = TMW:NewClass("IconModule_Alpha", "IconModule")
Alpha.dontInherit = true

Alpha:RegisterIconDefaults{
	FakeHidden				= false,
}


Alpha:RegisterConfigPanel_ConstructorFunc(195, "TellMeWhen_AlphaModuleSettings", function(self)
	self.Header:SetText(L["ICONALPHAPANEL_FAKEHIDDEN"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		{
			setting = "FakeHidden",
			title = L["ICONALPHAPANEL_FAKEHIDDEN"],
			tooltip = L["ICONALPHAPANEL_FAKEHIDDEN_DESC"],
		}
	})
end)

Alpha:RegisterEventHandlerData("Animations", 40, "ICONALPHAFLASH", {
	text = L["ANIM_ICONALPHAFLASH"],
	desc = L["ANIM_ICONALPHAFLASH_DESC"],
	ConfigFrames = {
		"Duration",
		"Infinite",
		"Period",
		"Fade",
	},

	Play = function(icon, eventSettings)
		local Duration = 0
		local Period = eventSettings.Period
		if eventSettings.Infinite then
			Duration = huge
		else
			if Period == 0 then
				Duration = eventSettings.Duration
			else
				while Duration < eventSettings.Duration do
					Duration = Duration + (Period * 2)
				end
			end
		end

		icon:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Duration = Duration,

			Period = Period,
			Fade = eventSettings.Fade,
		}
	end,

	OnUpdate = function(icon, table)
		local IconModule_Alpha = icon:GetModuleOrModuleChild("IconModule_Alpha")
		local FlashPeriod = table.Period

		local timePassed = TMW.time - table.Start
		local fadingIn = FlashPeriod == 0 or floor(timePassed/FlashPeriod) % 2 == 1

		if not IconModule_Alpha.FakeHidden then
			if table.Fade and FlashPeriod ~= 0 then
				local remainingFlash = timePassed % FlashPeriod
				if not fadingIn then
					icon:SetAlpha(icon.attributes.realAlpha*((FlashPeriod-remainingFlash)/FlashPeriod))
				else
					icon:SetAlpha(icon.attributes.realAlpha*(remainingFlash/FlashPeriod))
				end
			else
				icon:SetAlpha(fadingIn and icon.attributes.realAlpha or 0)
			end
		end

		-- (mostly) generic expiration -- we just finished the last flash, so dont do any more
		if timePassed > table.Duration then
			icon:Animations_Stop(table)
		end
	end,
	OnStart = function(icon, table)
		local IconModule_Alpha = icon:GetModuleOrModuleChild("IconModule_Alpha")
		local FadeHandlers = IconModule_Alpha.FadeHandlers
		
		FadeHandlers[#FadeHandlers + 1] = "ICONALPHAFLASH"
	end,
	OnStop = function(icon, table)
		local IconModule_Alpha = icon:GetModuleOrModuleChild("IconModule_Alpha")
		
		tDeleteItem(IconModule_Alpha.FadeHandlers, "ICONALPHAFLASH")
	end,
})
Alpha:RegisterEventHandlerData("Animations", 50, "ICONFADE", {
	text = L["ANIM_ICONFADE"],
	desc = L["ANIM_ICONFADE_DESC"],
	ConfigFrames = {
		"Duration",
	},

	Play = function(icon, eventSettings)
		icon:Animations_Start{
			eventSettings = eventSettings,
			Start = TMW.time,
			Duration = eventSettings.Duration,

			FadeDuration = eventSettings.Duration,
		}
	end,

	OnUpdate = function(icon, table)
		local IconModule_Alpha = icon:GetModuleOrModuleChild("IconModule_Alpha")
		
		local remaining = table.Duration - (TMW.time - table.Start)

		if remaining < 0 then
			icon:Animations_Stop(table)
		else
			local pct = remaining / table.FadeDuration
			local inv = 1-pct
			if not IconModule_Alpha.FakeHidden then
				icon:SetAlpha((IconModule_Alpha.actualAlphaAtLastChange * pct) + (icon.attributes.realAlpha * inv))
			end
		end
	end,
	OnStart = function(icon, table)
		local IconModule_Alpha = icon:GetModuleOrModuleChild("IconModule_Alpha")
		local FadeHandlers = IconModule_Alpha.FadeHandlers
		
		FadeHandlers[#FadeHandlers + 1] = "ICONFADE"
	end,
	OnStop = function(icon, table)
		local IconModule_Alpha = icon:GetModuleOrModuleChild("IconModule_Alpha")
		
		tDeleteItem(IconModule_Alpha.FadeHandlers, "ICONFADE")
	end,
})

function Alpha:OnNewInstance_Alpha()
	self.FadeHandlers = {}
end

function Alpha:SetupForIcon(icon)
	self.FakeHidden = icon.FakeHidden
	
	local attributes = icon.attributes
	
	self:REALALPHA(icon, icon.attributes.realAlpha)
end

function Alpha:REALALPHA(icon, realAlpha)
	if TMW.Locked then
		self.actualAlphaAtLastChange = icon:GetAlpha()
		
		if not self.FadeHandlers[1] then
			icon:SetAlpha(self.FakeHidden and 0 or realAlpha)
		end
	else
		icon:SetAlpha(realAlpha)
	end
end

Alpha:SetDataListner("REALALPHA")

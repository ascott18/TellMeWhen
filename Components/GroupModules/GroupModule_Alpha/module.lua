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


local GroupModule_Alpha = TMW:NewClass("GroupModule_Alpha", "GroupModule"){	
	OnEnable = function(self)
		local group = self.group
		if TMW.Locked then
			local settings = group:GetSettings()
			
			-- Setup inheritance if configured
			group:SetAlpha(settings.Alpha)

			if settings.AlphaInherit ~= "" then
				self.inheritGUID = settings.AlphaInherit
				TMW:RegisterCallback("TMW_ICON_DATA_CHANGED_CALCULATEDSTATE", self)
			end
		else
			self:Disable()
		end
	end,
	
	OnDisable = function(self)
		TMW:UnregisterCallback("TMW_ICON_DATA_CHANGED_CALCULATEDSTATE", self)
		self.inheritGUID = nil
		self.group:SetAlpha(1)
	end,
	
	TMW_ICON_DATA_CHANGED_CALCULATEDSTATE = function(self, event, icon, state)
		-- Only update if this is the icon we're inheriting from
		if self.inheritGUID and icon:GetGUID() == self.inheritGUID then
			if state.secretBool ~= nil then
				self.group:SetAlphaFromBoolean(state.secretBool, state.trueState.Alpha, state.falseState.Alpha)
				return
			end
			
			self.group:SetAlpha(state.Alpha)
		end
	end,
}

GroupModule_Alpha:RegisterConfigPanel_XMLTemplate(11, "TellMeWhen_GM_Alpha")

GroupModule_Alpha:RegisterGroupDefaults{
	Alpha = 1,
	AlphaInherit = "",
}

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



local Formatter = TMW:NewClass("Formatter"){
	OnNewInstance = function(self, fmt)
		self.fmt = fmt
	end,

	Format = function(self, value)
		local type = type(self.fmt)

		if type == "string" then
			return string.format(self.fmt, value)
		elseif type == "table" then
			return self.fmt[value]
		elseif type == "function" then
			return self.fmt(value)
		else
			return value
		end
	end,

	SetFormattedText = function(self, frame, value)
		frame:SetText(self:Format(value))
	end,
}
Formatter:MakeInstancesWeak()

Formatter{
	PASS = Formatter:New(tostring),


	F_1 = Formatter:New("%.1f"),
	F_2 = Formatter:New("%.2f"),

	PERCENT = Formatter:New("%s%%"),
	PERCENT100 = Formatter:New(function(value)
		return ("%s%%"):format(value*100)
	end),

	PLUSPERCENT = Formatter:New("+%s%%"),

	D_SECONDS = Formatter:New(D_SECONDS),
	S_SECONDS = Formatter:New(L["ANIM_SECONDS"]),

	PIXELS = Formatter:New(L["ANIM_PIXELS"]),

	SECONDS = Formatter:New(function(value)
		return TMW:FormatSeconds(value, nil, 1)
	end),

	COMMANUMBER = Formatter:New(function(k)
		k = gsub(k, "(%d)(%d%d%d)$", "%1,%2", 1)
		local found
		repeat
			k, found = gsub(k, "(%d)(%d%d%d),", "%1,%2,", 1)
		until found == 0

		return k
	end),
}
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

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local type = type
local bitband = bit.band

local ColorMSQ, OnlyMSQ

local Texture_Colored = TMW:NewClass("IconModule_Texture_Colored", "IconModule_Texture")

function Texture_Colored:SetupForIcon(icon)
	self.Colors = icon.typeData.Colors
	self.ShowWhen = icon.ShowWhen
	self.ShowTimer = icon.ShowTimer
	self:UPDATE(icon)
end

local COLOR_UNLOCKED = {
	r=1,
	b=1,
	g=1,
	Gray=false,
}
--TODO: the whole colors thing needs to be completely redone. This is a really depressing todo, but you need to do it.
function Texture_Colored:UPDATE(icon)
	local attributes = icon.attributes
	local duration, inrange, nomana = attributes.duration, attributes.inRange, attributes.noMana
--[[
	CBC = 	{r=0,	g=1,	b=0		},	-- cooldown bar complete
	CBS = 	{r=1,	g=0,	b=0		},	-- cooldown bar start

	OOR	=	{r=0.5,	g=0.5,	b=0.5	},	-- out of range
	OOM	=	{r=0.5,	g=0.5,	b=0.5	},	-- out of mana
	OORM=	{r=0.5,	g=0.5,	b=0.5	},	-- out of range and mana

	CTA	=	{r=1,	g=1,	b=1		},	-- counting with timer always
	COA	=	{r=1,	g=1,	b=1		},	-- counting withOUT timer always
	CTS	=	{r=1,	g=1,	b=1		},	-- counting with timer somtimes
	COS	=	{r=1,	g=1,	b=1		},	-- counting withOUT timer somtimes

	NA	=	{r=1,	g=1,	b=1		},	-- not counting always
	NS	=	{r=1,	g=1,	b=1		},	-- not counting somtimes]]

	local color
	if not TMW.Locked then
		color = COLOR_UNLOCKED
	elseif inrange == 0 and nomana then
		color = self.Colors.OORM
	elseif inrange == 0 then
		color = self.Colors.OOR
	elseif nomana then
		color = self.Colors.OOM
	else

		local s

		if not duration or duration == 0 then
			s = "N" -- Not counting
		else
			s = "C" -- Counting
		end

		if s == "C" then
			if self.ShowTimer then
				s = s .. "T" -- Timer
			else
				s = s .. "O" -- nOtimer
			end
		end

		
		--if (self.ShowWhen or "always") == "always" then
		if (bitband(self.ShowWhen or 0x3, 0x3)) == 0x3 then
			s = s .. "A" -- Always
		else
			s = s .. "S" -- Sometimes
		end
		
		--assert(self.Colors[s])

		color = self.Colors[s]
	end
	
	local texture = self.texture
	local r, g, b, d = color.r, color.g, color.b, color.Gray
	
	if not (LMB and OnlyMSQ) then
		texture:SetVertexColor(r, g, b, 1)
	end
	texture:SetDesaturated(d)
	
	if LMB and ColorMSQ then
		local iconnt = icon.normaltex
		if iconnt then
			iconnt:SetVertexColor(r, g, b, 1)
		end
	end
end

Texture_Colored:SetDataListner("INRANGE", Texture_Colored.UPDATE)
Texture_Colored:SetDataListner("NOMANA", Texture_Colored.UPDATE)


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	ColorMSQ = TMW.db.profile.ColorMSQ
	OnlyMSQ = TMW.db.profile.OnlyMSQ
end)
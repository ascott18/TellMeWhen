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

local pairs, type, ipairs, bit, select =
      pairs, type, ipairs, bit, select


---------------------------------------------------------
-- NEGATIVE SPELLIDS WILL BE REPLACED BY THEIR SPELL NAME
---------------------------------------------------------

-- The three categories must exist even when empty: TMW.BE.casts and friends
-- are indexed directly by the suggester and the CLEU icon type.
TMW.BE = {
	debuffs = {
	},
	buffs = {
	},
	casts = {
	},
}

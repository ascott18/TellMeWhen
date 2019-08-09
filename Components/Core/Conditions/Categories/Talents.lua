-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

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

local CNDT = TMW.CNDT
local Env = CNDT.Env
local strlowerCache = TMW.strlowerCache

local _, pclass = UnitClass("Player")

local ConditionCategory = CNDT:GetCategory("TALENTS", 1.4, L["CNDTCAT_TALENTS"], true, false)

ConditionCategory:RegisterCondition(0.2,  "CLASS2", {
	text = L["CONDITIONPANEL_CLASS"],

	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSECLASS"],
	bitFlags = (function()
		local t = {}
		for i = 1, MAX_CLASSES do
			local token = CLASS_SORT_ORDER[i]
			local name = LOCALIZED_CLASS_NAMES_MALE[token]
			t[i] = {
				order = i,
				text = PLAYER_CLASS_NO_SPEC:format(RAID_CLASS_COLORS[token].colorStr, name),
				icon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
				tcoords = {
					(CLASS_ICON_TCOORDS[token][1]+.02),
					(CLASS_ICON_TCOORDS[token][2]-.02),
					(CLASS_ICON_TCOORDS[token][3]+.02),
					(CLASS_ICON_TCOORDS[token][4]-.02),
				}
			}
		end
		return t
	end)(),

	icon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
	tcoords = {
		CLASS_ICON_TCOORDS[pclass][1]+.02,
		CLASS_ICON_TCOORDS[pclass][2]-.02,
		CLASS_ICON_TCOORDS[pclass][3]+.02,
		CLASS_ICON_TCOORDS[pclass][4]-.02,
	},

	Env = {
		UnitClass = UnitClass,
	},
	funcstr = function(c)
		return [[ BITFLAGSMAPANDCHECK( select(3, UnitClass(c.Unit)) or 0 ) ]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit(c.Unit)) -- classes cant change, so this is all we should need
	end,
})


ConditionCategory:RegisterSpacer(6)

Env.TalentMap = {}
function CNDT:CHARACTER_POINTS_CHANGED()
	wipe(Env.TalentMap)
	for tab = 1, GetNumTalentTabs() do
		for talent = 1, GetNumTalents(tab) do
			local name, _, _, _, rank = GetTalentInfo(tab, talent)
			local lower = name and strlowerCache[name]
			if lower then
				Env.TalentMap[lower] = rank or 0
			end
		end
	end
end

ConditionCategory:RegisterCondition(9,	 "PTSINTAL", {
	text = L["UIPANEL_PTSINTAL"],
	value = "PTSINTAL",
	min = 0,
	max = 5,
	unit = PLAYER,
	name = function(editbox) 
		editbox:SetTexts(L["SPELLTOCHECK"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = "talents",
	icon = function() return select(2, GetTalentInfo(1, 1)) end,
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = [[(TalentMap[c.NameString] or 0) c.Operator c.Level]],
	events = function(ConditionObject, c)
		-- this is handled externally because TalentMap is so extensive a process,
		-- and if it ends up getting processed in an OnUpdate condition, it could be very bad.
		CNDT:RegisterEvent("CHARACTER_POINTS_CHANGED")
		CNDT:CHARACTER_POINTS_CHANGED()

		return
			ConditionObject:GenerateNormalEventString("CHARACTER_POINTS_CHANGED")
	end,
})
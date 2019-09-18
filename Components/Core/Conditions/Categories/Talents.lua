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
		for classID = 1, TMW.GetMaxClassID() do
			local name, token = TMW.GetClassInfo(classID)
			if name then
				t[classID] = {
					order = classID,
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

ConditionCategory:RegisterCondition(2,	 "HAPPINESS", {
	-- poor translation to other languages, but better than just HAPPINESS on its own.
	text = PET .. " " .. HAPPINESS,
	
	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEVALUES"],
	bitFlags = {
		[1] = PET_HAPPINESS1,
		[2] = PET_HAPPINESS2,
		[3] = PET_HAPPINESS3
	},

	unit = PET,
	icon = "Interface\\PetPaperDollFrame\\UI-PetHappiness",
	tcoords = {0.390625, 0.5491, 0.03, 0.3305},
	Env = {
		GetPetHappiness = GetPetHappiness,
	},
	funcstr = [[ BITFLAGSMAPANDCHECK( GetPetHappiness() or 0 ) ]],
	hidden = pclass ~= "HUNTER",
	events = function(ConditionObject, c)
		return
			ConditionObject:GetUnitChangedEventString(CNDT:GetUnit("pet")),
			ConditionObject:GenerateNormalEventString("UNIT_HAPPINESS", "pet"),
			ConditionObject:GenerateNormalEventString("UNIT_POWER_FREQUENT", "pet")
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
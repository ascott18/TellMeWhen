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

local IsInInstance, GetInstanceDifficulty, GetNumShapeshiftForms, GetShapeshiftFormInfo = 
	  IsInInstance, GetInstanceDifficulty, GetNumShapeshiftForms, GetShapeshiftFormInfo
local GetPetActionInfo = 
	  GetPetActionInfo
	  
	  
local ConditionCategory = CNDT:GetCategory("ATTRIBUTES_PLAYER", 2, L["CNDTCAT_ATTRIBUTES_PLAYER"], false, false)




ConditionCategory:RegisterCondition(3,	 "MOUNTED", {
	text = L["CONDITIONPANEL_MOUNTED"],

	bool = true,
	
	unit = PLAYER,
	icon = "Interface\\Icons\\Ability_Mount_Charger",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsMounted = IsMounted,
	},
	funcstr = [[BOOLCHECK( IsMounted() )]],
})
ConditionCategory:RegisterCondition(4,	 "SWIMMING", {
	text = L["CONDITIONPANEL_SWIMMING"],

	bool = true,
	
	unit = PLAYER,
	icon = "Interface\\Icons\\Spell_Shadow_DemonBreath",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		IsSwimming = IsSwimming,
	},
	funcstr = [[BOOLCHECK( IsSwimming() )]],
	--events = absolutely no events (SPELL_UPDATE_USABLE is close, but not close enough)
})
ConditionCategory:RegisterCondition(5,	 "RESTING", {
	text = L["CONDITIONPANEL_RESTING"],

	bool = true,
	
	unit = PLAYER,
	icon = "Interface\\CHARACTERFRAME\\UI-StateIcon",
	tcoords = {0.0625, 0.453125, 0.046875, 0.421875},
	Env = {
		IsResting = IsResting,
	},
	funcstr = [[BOOLCHECK( IsResting() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PLAYER_UPDATE_RESTING"),
			ConditionObject:GenerateNormalEventString("PLAYER_ENTERING_WORLD")
	end,
})


local NumShapeshiftForms
local GetShapeshiftForm = GetShapeshiftForm
TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	NumShapeshiftForms = GetNumShapeshiftForms()
end)


ConditionCategory:RegisterSpacer(5.5)

-- TODO-CLASSIC: STANCE probably needs to be totally redone.
local FirstStances = {
	DRUID = 5487, 		-- Bear Form
	PRIEST = 15473, 	-- Shadowform
	ROGUE = 1784, 		-- Stealth
	WARRIOR = 2457, 	-- Battle Stance
}
ConditionCategory:RegisterCondition(6,	 "STANCE", {
	text = 	pclass == "DRUID" and L["SHAPESHIFT"] or
			L["STANCE"],

	bool = true,
	
	name = function(editbox)
		editbox:SetTexts(L["STANCE"], L["STANCE_DESC"])
		editbox:SetLabel(L["STANCE_LABEL"])
	end,
	useSUG = "stances",
	allowMultipleSUGEntires = true,
	unit = PLAYER,
	icon = function()
		return GetSpellTexture(FirstStances[pclass] or FirstStances.WARRIOR) or GetSpellTexture(FirstStances.WARRIOR)
	end,
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetShapeshiftForm = function()
			-- very hackey function because of inconsistencies in blizzard's GetShapeshiftForm
			local i = GetShapeshiftForm()
			if pclass == "ROGUE" and i > 1 then	--vanish and shadow dance return 3 when active, vanish returns 2 when shadow dance isnt learned. Just treat everything as stealth
				i = 1
			end
			if i > NumShapeshiftForms then 	--many Classes return an invalid number on login, but not anymore!
				i = 0
			end

			if i == 0 then
				return NONE
			else
				local icons, active, catable, spellID = GetShapeshiftFormInfo(i)
				return spellID and GetSpellInfo(spellID) or ""
			end
		end
	},
	funcstr = [[BOOLCHECK(MULTINAMECHECK(  GetShapeshiftForm() or ""  ))]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UPDATE_SHAPESHIFT_FORM")
	end,
	hidden = not FirstStances[pclass],
})

ConditionCategory:RegisterSpacer(6.5)



ConditionCategory:RegisterCondition(12,	 "AUTOCAST", {
	text = L["CONDITIONPANEL_AUTOCAST"],
	tooltip = L["CONDITIONPANEL_AUTOCAST_DESC"],

	bool = true,
	
	unit = PET,
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_AUTOCAST"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = true,
	icon = "Interface\\Icons\\ability_physical_taunt",
	tcoords = CNDT.COMMON.standardtcoords,
	Env = {
		GetSpellAutocast = GetSpellAutocast,
	},
	funcstr = [[BOOLCHECK( select(2, GetSpellAutocast(c.NameString)) )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("PET_BAR_UPDATE")
	end,
})



TMW:RegisterUpgrade(73019, {
	condition = function(self, condition)
		if condition.Type == "PETMODE" then
			condition.Type = "PETMODE2"
			condition.Checked = false

			CNDT:ConvertSliderCondition(condition, 1, 3)
		end
	end,
})
local PetModes = {
	PET_MODE_AGGRESSIVE = 1,
	PET_MODE_DEFENSIVE = 2,
	PET_MODE_PASSIVE = 3,
}
ConditionCategory:RegisterCondition(13.1, "PETMODE2", {
	text = L["CONDITIONPANEL_PETMODE"],
	tooltip = L["CONDITIONPANEL_PETMODE_DESC"],

	bitFlagTitle = L["CONDITIONPANEL_BITFLAGS_CHOOSEMENU_TYPES"],
	bitFlags = {
		[0] = L["CONDITIONPANEL_PETMODE_NONE"],
		[1] = PET_MODE_AGGRESSIVE,
		[2] = PET_MODE_DEFENSIVE,
		[3] = PET_MODE_PASSIVE
	},

	unit = false,
	icon = PET_PASSIVE_TEXTURE,
	tcoords = CNDT.COMMON.standardtcoords,

	Env = {
		GetActivePetMode2 = function()
			for i = NUM_PET_ACTION_SLOTS, 1, -1 do -- go backwards since they are probably at the end of the action bar
				local name, _, isToken, isActive = GetPetActionInfo(i)
				if isToken and isActive and PetModes[name] then
					return PetModes[name]
				end
			end
			return 0
		end,
	},
	funcstr = [[BITFLAGSMAPANDCHECK( GetActivePetMode2() )]],
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("UNIT_PET", "player"),
			ConditionObject:GenerateNormalEventString("PET_BAR_UPDATE")
	end,
})


ConditionCategory:RegisterSpacer(15.5)


Env.Tracking = {}
local Parser, LT1 = TMW:GetParser()
function CNDT:MINIMAP_UPDATE_TRACKING()
	wipe(Env.Tracking)
	Parser:SetOwner(UIParent, "ANCHOR_NONE")
	Parser:SetTrackingSpell()
	local text = LT1:GetText() or ""
	Parser:Hide()

	if text and text ~= "" then
		Env.Tracking[strlower(text)] = 1
	end
end
ConditionCategory:RegisterCondition(16,	 "TRACKING", {
	text = L["CONDITIONPANEL_TRACKING"],
	tooltip = L["CONDITIONPANEL_TRACKING_DESC"],

	bool = true,
	
	unit = PLAYER,
	name = function(editbox)
		editbox:SetTexts(L["CONDITIONPANEL_TRACKING"], L["CNDT_ONLYFIRST"])
		editbox:SetLabel(L["SPELLTOCHECK"])
	end,
	useSUG = "tracking",
	icon = "Interface\\MINIMAP\\TRACKING\\None",
	tcoords = CNDT.COMMON.standardtcoords,
	funcstr = function(ConditionObject, c)
		-- this event handling it is really extensive, so keep it in a handler separate from the condition
		CNDT:RegisterEvent("MINIMAP_UPDATE_TRACKING")
		CNDT:MINIMAP_UPDATE_TRACKING()
	
		return [[BOOLCHECK( Tracking[c.NameString] )]]
	end,
	events = function(ConditionObject, c)
		return
			ConditionObject:GenerateNormalEventString("MINIMAP_UPDATE_TRACKING")
	end,
})


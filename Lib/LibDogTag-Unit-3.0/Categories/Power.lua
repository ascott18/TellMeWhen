local MAJOR_VERSION = "LibDogTag-Unit-3.0"
local MINOR_VERSION = 90000 + tonumber(("$Revision: 225 $"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_Unit_MINOR_VERSION then
	_G.DogTag_Unit_MINOR_VERSION = MINOR_VERSION
end

local _G, select, unpack = _G, select, unpack
local ALTERNATE_POWER_INDEX, UnitPower, UnitPowerMax, UnitPowerType = 
	  ALTERNATE_POWER_INDEX, UnitPower, UnitPowerMax, UnitPowerType
	  
DogTag_Unit_funcs[#DogTag_Unit_funcs+1] = function(DogTag_Unit, DogTag)

local L = DogTag_Unit.L

-- Parnic: support for Cataclysm; UNIT_MANA et al changed to UNIT_(MAX)POWER
local wow_400 = select(4, GetBuildInfo()) >= 40000
local mpEvents = "UNIT_MANA#$unit;UNIT_RAGE#$unit;UNIT_FOCUS#$unit;UNIT_ENERGY#$unit;UNIT_RUNIC_POWER#$unit;UNIT_MAXMANA#$unit;UNIT_MAXRAGE#$unit;UNIT_MAXFOCUS#$unit;UNIT_MAXENERGY#$unit;UNIT_MAXRUNIC_POWER#$unit;UNIT_DISPLAYPOWER#$unit"
if wow_400 then
	mpEvents = "UNIT_POWER#$unit;UNIT_MAXPOWER#$unit;UNIT_DISPLAYPOWER#$unit"
end

DogTag:AddTag("Unit", "MP", {
	code = UnitPower,
	arg = {
		'unit', 'string;undef', 'player'
	},
	ret = "number",
	events = mpEvents .. ";FastPower#$unit",
	doc = L["Return the current mana/rage/energy of unit"],
	example = ('[MP] => "%d"'):format(UnitPowerMax("player")*.632),
	category = L["Power"]
})

DogTag:AddTag("Unit", "MaxMP", {
	code = UnitPowerMax,
	arg = {
		'unit', 'string;undef', 'player'
	},
	ret = "number",
	events = mpEvents,
	doc = L["Return the maximum mana/rage/energy of unit"],
	example = ('[MaxMP] => "%d"'):format(UnitPowerMax("player")),
	category = L["Power"]
})

DogTag:AddTag("Unit", "PercentMP", {
	alias = "[MP(unit=unit) / MaxMP(unit=unit) * 100]:Round(1)",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return the percentage mana/rage/energy of unit"],
	example = '[PercentMP] => "63.2"; [PercentMP:Percent] => "63.2%"',
	category = L["Power"]
})

DogTag:AddTag("Unit", "MissingMP", {
	alias = "MaxMP(unit=unit) - MP(unit=unit)",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return the missing mana/rage/energy of unit"],
	example = ('[MissingMP] => "%d"'):format(UnitPowerMax("player")*.368),
	category = L["Power"]
})

DogTag:AddTag("Unit", "FractionalMP", {
	alias = "Concatenate(MP(unit=unit), '/', MaxMP(unit=unit))",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return the current and maximum mana/rage/energy of unit"],
	example = ('[FractionalMP] => "%d/%d"'):format(UnitPowerMax("player")*.632, UnitPowerMax("player")),
	category = L["Power"]
})

DogTag:AddTag("Unit", "AltP", {
	code = UnitPower,
	arg = {
		'unit', 'string;undef', 'player',
		'index', 'number;undef', ALTERNATE_POWER_INDEX
	},
	ret = "number",
	events = mpEvents .. ";FastPower#$unit",
	doc = L["Return the current alternate power of unit"],
	example = ('[AltP] => "%d"'):format(UnitPowerMax("player",ALTERNATE_POWER_INDEX)*.632),
	category = L["Power"]
})

DogTag:AddTag("Unit", "MaxAltP", {
	code = UnitPowerMax,
	arg = {
		'unit', 'string;undef', 'player',
		'index', 'number;undef', ALTERNATE_POWER_INDEX
	},
	ret = "number",
	events = mpEvents,
	doc = L["Return the maximum alternate power of unit"],
	example = ('[MaxAltP] => "%d"'):format(UnitPowerMax("player",ALTERNATE_POWER_INDEX)),
	category = L["Power"]
})

DogTag:AddTag("Unit", "PercentAltP", {
	alias = "[AltP(unit=unit) / MaxAltP(unit=unit) * 100]:Round(1)",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return the percentage alternate power of unit"],
	example = '[PercentAltP] => "63.2"; [PercentAltP:Percent] => "63.2%"',
	category = L["Power"]
})

DogTag:AddTag("Unit", "MissingAltP", {
	alias = "MaxAltP(unit=unit) - AltP(unit=unit)",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return the missing alternate power of unit"],
	example = ('[MissingAltP] => "%d"'):format(UnitPowerMax("player",ALTERNATE_POWER_INDEX)*.368),
	category = L["Power"]
})

DogTag:AddTag("Unit", "FractionalAltP", {
	alias = "Concatenate(AltP(unit=unit), '/', MaxAltP(unit=unit))",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return the current and maximum alternate power of unit"],
	example = ('[FractionalAltP] => "%d/%d"'):format(UnitPowerMax("player",ALTERNATE_POWER_INDEX)*.632, UnitPowerMax("player",ALTERNATE_POWER_INDEX)),
	category = L["Power"]
})

DogTag:AddTag("Unit", "TypePower", {
	code = function(unit)
		local p = UnitPowerType(unit)
		if p == 1 then
			return L["Rage"]
		elseif p == 2 then
		 	return L["Focus"]
		elseif p == 3 then
			return L["Energy"]
		elseif p == 6 then
			return L["Runic Power"]
		else
			return L["Mana"]
		end
	end,
	arg = {
		'unit', 'string;undef', 'player'
	},
	ret = "string",
	events = "UNIT_DISPLAYPOWER#$unit",
	doc = L["Return whether unit currently uses Rage, Focus, Energy, or Mana"],
	example = ('[TypePower] => %q; [TypePower] => %q'):format(L["Rage"], L["Mana"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "IsPowerType", {
	alias = [=[Boolean(TypePower(unit=unit) = type)]=],
	arg = {
		'type', 'string', '@req',
		'unit', 'string;undef', 'player'
	},
	ret = "boolean",
	events = "UNIT_DISPLAYPOWER#$unit",
	doc = L["Return True if unit currently uses the power of argument"],
	example = ('[HasPower(%q)] => %q; [HasPower(%q)] => ""'):format(L["Rage"], L["True"], L["Mana"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "IsRage", {
	alias = ("IsPowerType(type=%q, unit=unit)"):format(L["Rage"]),
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return True if unit currently uses rage"],
	example = ('[IsRage] => %q; [IsRage] => ""'):format(L["True"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "IsFocus", {
	alias = ("IsPowerType(type=%q, unit=unit)"):format(L["Focus"]),
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return True if unit currently uses focus"],
	example = ('[IsFocus] => %q; [IsFocus] => ""'):format(L["True"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "IsEnergy", {
	alias = ("IsPowerType(type=%q, unit=unit)"):format(L["Energy"]),
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return True if unit currently uses energy"],
	example = ('[IsEnergy] => %q; [IsEnergy] => ""'):format(L["True"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "IsMana", {
	alias = ("IsPowerType(type=%q, unit=unit)"):format(L["Mana"]),
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return True if unit currently uses mana"],
	example = ('[IsMana] => %q; [IsMana] => ""'):format(L["True"]),
	category = L["Power"]
})

if RUNIC_POWER then
	DogTag:AddTag("Unit", "IsRunicPower", {
		alias = ("IsPowerType(type=%q, unit=unit)"):format(L["Runic Power"]),
		arg = {
			'unit', 'string;undef', 'player'
		},
		doc = L["Return True if unit currently uses runic power"],
		example = ('[IsRunicPower] => %q; [IsRunicPower] => ""'):format(L["True"]),
		category = L["Power"]
	})
end

DogTag:AddTag("Unit", "IsMaxMP", {
	alias = "Boolean(MP(unit=unit) = MaxMP(unit=unit))",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return True if unit is at full rage/mana/energy"],
	example = ('[IsMaxMP] => %q; [IsMaxMP] => ""'):format(L["True"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "HasMP", {
	alias = "Boolean(MaxMP(unit=unit) > 0)",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return True if unit has any power type at all"],
	example = ('[HasMP] => %q; [HasMP] => ""'):format(L["True"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "IsMaxAltP", {
	alias = "Boolean(AltP(unit=unit) = MaxAltP(unit=unit))",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return True if unit is at full alternate power"],
	example = ('[IsMaxAltP] => %q; [IsMaxAltP] => ""'):format(L["True"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "HasAltP", {
	alias = "Boolean(MaxAltP(unit=unit) > 0)",
	arg = {
		'unit', 'string;undef', 'player'
	},
	doc = L["Return True if unit has any alternate power"],
	example = ('[HasAltP] => %q; [HasAltP] => ""'):format(L["True"]),
	category = L["Power"]
})

DogTag:AddTag("Unit", "PowerColor", {
	code = function(value, unit)
		local powerType = UnitPowerType(unit)
		local r,g,b
		if powerType == 0 then
			r,g,b = unpack(DogTag.__colors.mana)
		elseif powerType == 1 then
			r,g,b = unpack(DogTag.__colors.rage)
		elseif powerType == 2 then
			r,g,b = unpack(DogTag.__colors.focus)
		elseif powerType == 3 then
			r,g,b = unpack(DogTag.__colors.energy)
		elseif powerType == 6 then
			r,g,b = unpack(DogTag.__colors.runicPower)
		else
			r,g,b = unpack(DogTag.__colors.unknown)
		end
		if value then
			return ("|cff%02x%02x%02x%s|r"):format(r * 255, g * 255, b * 255, value)
		else
			return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
		end
	end,
	arg = {
		'value', 'string;undef', '@undef',
		'unit', 'string;undef', 'player'
	},
	ret = "string",
	events = "UNIT_DISPLAYPOWER#$unit",
	doc = L["Return the color or wrap value with current power color of unit, whether rage, mana, or energy"],
	example = '["Hello":PowerColor] => "|cff3071bfHello|r"; [PowerColor "Hello"] => "|cff3071bfHello"',
	category = L["Power"]
})

end
local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = 90000 + tonumber(("$Revision: 203 $"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

if GetLocale() == "koKR" then

DogTag_funcs[#DogTag_funcs+1] = function(DogTag)
	local L = DogTag.L
	
	L["DogTag Help"] = "DogTag 도움말"
	L["True"] = "True" -- check
end

end
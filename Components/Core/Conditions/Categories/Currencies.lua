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

local CNDT = TMW.CNDT
local Env = CNDT.Env


local ConditionCategory = CNDT:GetCategory("CURRENCIES", 7, L["CNDTCAT_CURRENCIES"], false, false)

local currencies = {
	-- currencies were extracted using the script in the /Scripts folder (source is wowhead)
	-- make sure and order them here in a way that makes sense (most common first, blah blah derp herping)
	395,	--Justice Points
	396,	--Valor Points
	392,	--Honor Points
	390,	--Conquest Points
	--692,	--Conquest Random BG Meta
	"SPACE",
	391,	--Tol Barad Commendation
	416,	--Mark of the World Tree
	241,	--Champion\'s Seal
	515,	--Darkmoon Prize Ticket
	"SPACE",
	697,	--Elder Charm of Good Fortune
	614,	--Mote of Darkness
	615,	--Essence of Corrupted Deathwing
	"SPACE",
	698,	--Zen Jewelcrafter\'s Token
	361,	--Illustrious Jewelcrafter\'s Token
	402,	--Ironpaw Token
	61,		--Dalaran Jewelcrafter\'s Token
	81,		--Epicurean\'s Award
	"SPACE",
	384,	--Dwarf Archaeology Fragment
	398,	--Draenei Archaeology Fragment
	393,	--Fossil Archaeology Fragment
	394,	--Night Elf Archaeology Fragment
	397,	--Orc Archaeology Fragment
	385,	--Troll Archaeology Fragment
	
	400,	--Nerubian Archaeology Fragment
	399,	--Vrykul Archaeology Fragment
	
	401,	--Tol\'vir Archaeology Fragment
	
	676,	--Pandaren Archaeology Fragment
	677,	--Mogu Archaeology Fragment
}


local eventsFunc = function(ConditionObject, c)
	return
		ConditionObject:GenerateNormalEventString("CURRENCY_DISPLAY_UPDATE")
end

local spacenext
Env.GetCurrencyInfo = GetCurrencyInfo
for i, id in ipairs(currencies) do
	if id == "SPACE" then
		ConditionCategory:RegisterSpacer(i + 0.5)
	else
		ConditionCategory:RegisterCondition(i, "CURRENCY"..id, {
			range = 500,
			unit = false,
			funcstr = [[select(2, GetCurrencyInfo(]]..id..[[)) c.Operator c.Level]],
			tcoords = CNDT.COMMON.standardtcoords,
			hidden = true,
			events = eventsFunc,
		})
		spacenext = nil
	end
end

function CNDT:CURRENCY_DISPLAY_UPDATE()
	for _, id in pairs(currencies) do
		if id ~= "SPACE" then
			local data = CNDT.ConditionsByType["CURRENCY"..id]
			local name, amount, texture, _, _, totalMax = GetCurrencyInfo(id)
			if name ~= "" then
				data.text = name
				data.icon = "Interface\\Icons\\"..texture
				data.hidden = false
				if TMWOptDB then
					TMWOptDB.Currencies = TMWOptDB.Currencies or {}
					TMWOptDB.Currencies[id] = name .. "^" .. texture
				end
				--[[if totalMax > 0 then -- not using this till blizzard fixes the bug where it shows the honor and conquest caps as 40,000
					data.max = totalMax
				end]]
			elseif TMWOptDB and TMWOptDB.Currencies then
				if TMWOptDB.Currencies[id] then
					local name, texture = strmatch(TMWOptDB.Currencies[id], "(.*)^(.*)")
					if name and texture then
						data.text = name
						data.icon = "Interface\\Icons\\"..texture
						data.hidden = false
					end
				end
			end
		end
	end
end
CNDT:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
CNDT:CURRENCY_DISPLAY_UPDATE()
TMW:RegisterCallback("TMW_OPTIONS_LOADED", "CURRENCY_DISPLAY_UPDATE", CNDT)
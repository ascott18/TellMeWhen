-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print


local Processor = TMW.Classes.IconDataProcessor:New("SPELL", "spell")

function Processor:CompileFunctionSegment(t)
	-- GLOBALS: spell
	t[#t+1] = [[
	if attributes.spell ~= spell then
		attributes.spell = spell
		
		if EventHandlersSet.OnSpell then
			icon:QueueEvent("OnSpell")
		end

		TMW:Fire(SPELL.changedEvent, icon, spell)
		doFireIconUpdated = true
	end
	--]]
end

Processor:AddDogTag("TMW", "Spell", {
	code = function (groupID, iconID, link)
		local group = TMW[groupID]
		local icon = group and group[iconID]
		if icon then
			local name, checkcase = icon.typeData:GetNameForDisplay(icon, icon.attributes.spell, link)
			name = name or ""
			if checkcase and name ~= "" then
				name = TMW:RestoreCase(name)
			end
			return name
		else
			return ""
		end
	end,
	arg = {
		'group', 'number', '@req',
		'icon', 'number', '@req',
		'link', 'boolean', false,
	},
	events = TMW:CreateDogTagEventString("SPELL"),
	ret = "string",
	doc = L["DT_DOC_Spell"],
	example = ('[Spell] => %q; [Spell(link=true)] => %q; [Spell(4, 5)] => %q; [Spell(4, 5, true)] => %q'):format(GetSpellInfo(2139), GetSpellLink(2139), GetSpellInfo(1766), GetSpellLink(1766)),
	category = L["ICON"],
})

TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", function(event, icon, typeData, oldTypeData)
	icon:SetInfo("spell", nil)
end)

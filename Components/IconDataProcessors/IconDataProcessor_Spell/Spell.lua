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

Processor:RegisterIconEvent(31, "OnSpell", {
	text = L["SOUND_EVENT_ONSPELL"],
	desc = L["SOUND_EVENT_ONSPELL_DESC"],
})
	
Processor:RegisterDogTag("TMW", "Spell", {
	code = function(icon, link)
		icon = TMW.GUIDToOwner[icon]

		if icon then
			local name, checkcase = icon.typeData:FormatSpellForOutput(icon, icon.attributes.spell, link)
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
		'icon', 'string', '@req',
		'link', 'boolean', false,
	},
	events = TMW:CreateDogTagEventString("SPELL"),
	ret = "string",
	doc = L["DT_DOC_Spell"] .. "\r\n \r\n" .. L["DT_INSERTGUID_GENERIC_DESC"],
	example = ('[Spell] => %q; [Spell(link=true)] => %q; [Spell(icon="TMW:icon:1I7MnrXDCz8T")] => %q; [Spell(icon="TMW:icon:1I7MnrXDCz8T", link=true)] => %q'):format(TMW_GetSpellInfo(2139), GetSpellLink(2139), TMW_GetSpellInfo(1766), GetSpellLink(1766)),
	category = L["ICON"],
})

TMW:RegisterCallback("TMW_ICON_TYPE_CHANGED", function(event, icon, typeData, oldTypeData)
	icon:SetInfo("spell", nil)
end)

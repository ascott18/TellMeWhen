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

local SUG = TMW.SUG
local strlowerCache = TMW.strlowerCache
local GetSpellInfo = TMW.GetSpellInfo
local GetSpellName = TMW.GetSpellName

local _, pclass = UnitClass("Player")

local function makeId(tab, talent)
	return "" .. tab .. "," .. talent
end
local function parseId(id)
	return (","):split(id)
end

local Module = SUG:NewModule("talents", SUG:GetModule("default"))
Module.noMin = true
Module.showColorHelp = false
Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
Module.table = {}

function Module:OnInitialize()
	-- nothing
end
function Module:Table_Get()
	wipe(self.table)

	if C_ClassTalents then
		local ranksbySpellId = TMW.CNDT:GetTalentRanksBySpellID()
		for spellID, ranks in pairs(ranksbySpellId) do
			local name = GetSpellName(spellID)

			local lower = name and strlowerCache[name]
			if lower then
				self.table[spellID] = lower
			end
		end
	elseif GetNumTalentTabs then
		-- Wrath
		for tab = 1, GetNumTalentTabs() do
			for talent = 1, GetNumTalents(tab) do
				local name, iconTexture = GetTalentInfo(tab, talent)
				
				local lower = name and strlowerCache[name]
				if lower then
					self.table[makeId(tab, talent)] = lower
				end
			end
		end
	else
		for tier = 1, MAX_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				local id, name = GetTalentInfo(tier, column, 1)
				
				local lower = name and strlowerCache[name]
				if lower then
					self.table[id] = lower
				end
			end
		end
	end


	return self.table
end
function Module:Entry_AddToList_1(f, id)
	if C_ClassTalents then
		local name = GetSpellName(id)
	
		f.Name:SetText(name)
		f.insert = name

		f.ID:SetText(id)
		f.insert2 = id

		f.tooltipmethod = "SetSpellByID"
		f.tooltiparg = id
	
		f.Icon:SetTexture(TMW.GetSpellTexture(id))
	elseif GetNumTalentTabs then
		-- Wrath
		local tab, talent = parseId(id)
		local name, iconTexture = GetTalentInfo(tab, talent)

		f.insert = name
		f.Name:SetText(name)

		f.tooltipmethod = "SetTalent"
		f.tooltiparg = {tab, talent}

		f.Icon:SetTexture(iconTexture)
	else
		local id, name, iconTexture = GetTalentInfoByID(id) -- restore case

		f.Name:SetText(name)
		f.insert = name

		f.ID:SetText(id)
		f.insert2 = id
	
		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = GetTalentLink(id)
	
		f.Icon:SetTexture(iconTexture)
	end
end
Module.Entry_Colorize_1 = TMW.NULLFUNC

if C_ClassTalents then
	local Module = SUG:NewModule("talentloadout", SUG:GetModule("default"))
	Module.noMin = true
	Module.showColorHelp = false
	Module.noTexture = true
	Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
	Module.table = {}

	function Module:Table_Get()
		wipe(self.table)

		tinsert(self.table, TALENT_FRAME_DROP_DOWN_STARTER_BUILD)
		tinsert(self.table, TALENT_FRAME_DROP_DOWN_DEFAULT)

		for i = TMW.GetNumSpecializations(), 1, -1 do
			local specID = TMW.GetSpecializationInfo(i)
			for _, configId in pairs(C_ClassTalents.GetConfigIDsBySpecID(specID)) do
				local config = C_Traits.GetConfigInfo(configId)
				if config and config.name then
					tinsert(self.table, config.name)
				end
			end
		end

		return self.table
	end
	function Module:Table_GetNormalSuggestions(suggestions, tbl)
		local lastName = SUG.lastName

		for _, name in pairs(self.table) do
			if strfind(strlower(name), lastName) then
				suggestions[#suggestions + 1] = name
			end
		end
	end
	function Module:Entry_AddToList_1(f, name)
		f.Name:SetText(name)
		f.insert = name
		f.tooltiptitle = name
	end
end

if GetPvpTalentInfoByID then
	local Module = SUG:NewModule("pvptalents", SUG:GetModule("talents"))
	Module.table = {}

	function Module:Table_Get()
		wipe(self.table)

		for slot = 1, 10 do
			local info = C_SpecializationInfo.GetPvpTalentSlotInfo(slot)
			if not info then break end

			for _, id in pairs(info.availableTalentIDs) do 
				local _, name = GetPvpTalentInfoByID(id)
				
				local lower = name and strlowerCache[name]
				if lower then
					self.table[id] = lower
				end
			end
		end

		return self.table
	end
	function Module:Entry_AddToList_1(f, id)
		local id, name, iconTexture = GetPvpTalentInfoByID(id) -- restore case

		f.Name:SetText(name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetHyperlink"
		f.tooltiparg = GetPvpTalentLink(id)

		f.insert = name
		f.insert2 = id

		f.Icon:SetTexture(iconTexture)
	end
end



if C_AzeriteEssence then
	local Module = SUG:NewModule("azerite_essence", SUG:GetModule("default"))
	Module.noMin = true
	Module.showColorHelp = false
	Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
	Module.table = {}

	function Module:OnInitialize()
		-- nothing
	end
	function Module:Table_Get()
		wipe(self.table)
		local essences = C_AzeriteEssence.GetEssences()
		if not essences then  
			return self.table
		end
		
		for _, info in pairs(essences) do
			self.table[info.ID] = strlowerCache[info.name]
		end

		return self.table
	end
	function Module:Table_GetSorter()
		if SUG.inputType == "number" then
			return nil -- use the default sort func
		else
			SUG.SortTable = self:Table_Get()
			return self.Sorter_ByName
		end
	end
	function Module:Entry_AddToList_1(f, id)
		local info = C_AzeriteEssence.GetEssenceInfo(id)

		f.Name:SetText(info.name)
		f.ID:SetText(id)

		f.tooltipmethod = "SetAzeriteEssence"
		f.tooltiparg = id

		f.insert = info.name
		f.insert2 = id

		f.Icon:SetTexture(info.icon)
	end
end



if C_Soulbinds then
	local Module = SUG:NewModule("soulbind", SUG:GetModule("default"))
	Module.noMin = true
	Module.showColorHelp = false
	Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
	Module.table = {}
	function Module:OnInitialize()
		-- nothing
	end
	function Module:Table_Get()
		wipe(self.table)

		for id = 1, 30 do
			local data = C_Soulbinds.GetSoulbindData(id)
			if data.name and data.name ~= "" then
				self.table[id] = strlowerCache[data.name]
			end
		end

		return self.table
	end
	function Module.Sorter(a, b)
		local nameA, nameB = C_Soulbinds.GetSoulbindData(a), C_Soulbinds.GetSoulbindData(b)
		if nameA.covenantID == nameB.covenantID then
			--sort identical names by ID
			return a < b
		else
			--sort by name
			return nameA.covenantID < nameB.covenantID
		end
	end
	function Module:Table_GetSorter()
		return self.Sorter
	end
	function Module:Entry_AddToList_1(f, id)
		local info = C_Soulbinds.GetSoulbindData(id)

		f.Name:SetText(info.name)
		f.ID:SetText(id)

		f.tooltiptitle = info.name
		f.tooltiptext = info.description

		f.insert = info.name
		f.insert2 = id

		f.Icon:SetTexture(TMW.CovenantIcons[info.covenantID])
	end
	Module.Entry_Colorize_1 = TMW.NULLFUNC
end

if GetGlyphSocketInfo then
	local Module = SUG:NewModule("glyphs", SUG:GetModule("spell"))
	Module.noMin = true
	Module.showColorHelp = false
	Module.helpText = L["SUG_TOOLTIPTITLE_GENERIC"]
	Module.table = {}


	-- From GetCSC.py
	local Glyphs = TMW.isCata and {[58616]=6,[58618]=6,[58620]=6,[58623]=6,[58629]=6,[58631]=6,[58635]=6,[58640]=6,[58642]=6,[58647]=6,[58657]=6,[58669]=6,[58671]=6,[58673]=6,[58676]=6,[58677]=6,[58680]=6,[58686]=6,[59307]=6,[59309]=6,[59327]=6,[59332]=6,[59336]=6,[60200]=6,[62259]=6,[63330]=6,[63331]=6,[63333]=6,[63335]=6,[96279]=6,[52648]=11,[54733]=11,[54743]=11,[54754]=11,[54756]=11,[54760]=11,[54810]=11,[54811]=11,[54812]=11,[54813]=11,[54815]=11,[54818]=11,[54821]=11,[54824]=11,[54825]=11,[54826]=11,[54828]=11,[54829]=11,[54830]=11,[54831]=11,[54832]=11,[54845]=11,[57855]=11,[57856]=11,[57857]=11,[57858]=11,[57862]=11,[58136]=11,[59219]=11,[62080]=11,[62135]=11,[62969]=11,[62970]=11,[62971]=11,[63055]=11,[63056]=11,[63057]=11,[67598]=11,[94382]=11,[94386]=11,[94388]=11,[94390]=11,[95212]=11,[413895]=11,[56824]=3,[56826]=3,[56828]=3,[56829]=3,[56830]=3,[56832]=3,[56833]=3,[56836]=3,[56841]=3,[56842]=3,[56844]=3,[56845]=3,[56846]=3,[56847]=3,[56848]=3,[56849]=3,[56850]=3,[56851]=3,[56856]=3,[56857]=3,[57866]=3,[57870]=3,[57902]=3,[57903]=3,[57904]=3,[63065]=3,[63066]=3,[63067]=3,[63068]=3,[63069]=3,[63086]=3,[56363]=8,[56364]=8,[56365]=8,[56366]=8,[56368]=8,[56370]=8,[56372]=8,[56373]=8,[56374]=8,[56375]=8,[56376]=8,[56377]=8,[56380]=8,[56381]=8,[56382]=8,[56383]=8,[56384]=8,[57924]=8,[57925]=8,[57927]=8,[57928]=8,[58070]=8,[61205]=8,[62126]=8,[62210]=8,[63090]=8,[63091]=8,[63092]=8,[63093]=8,[63095]=8,[70937]=8,[89749]=8,[89926]=8,[98397]=8,[54922]=2,[54923]=2,[54924]=2,[54925]=2,[54926]=2,[54927]=2,[54928]=2,[54930]=2,[54931]=2,[54934]=2,[54935]=2,[54936]=2,[54937]=2,[54938]=2,[54939]=2,[54940]=2,[54943]=2,[56414]=2,[56416]=2,[56420]=2,[57937]=2,[57947]=2,[57954]=2,[57955]=2,[57958]=2,[57979]=2,[63218]=2,[63219]=2,[63220]=2,[63222]=2,[63223]=2,[63224]=2,[63225]=2,[89401]=2,[93466]=2,[405004]=2,[55672]=5,[55673]=5,[55674]=5,[55675]=5,[55676]=5,[55677]=5,[55678]=5,[55679]=5,[55680]=5,[55681]=5,[55682]=5,[55683]=5,[55684]=5,[55685]=5,[55686]=5,[55687]=5,[55688]=5,[55689]=5,[55690]=5,[55691]=5,[55692]=5,[57985]=5,[57986]=5,[57987]=5,[58009]=5,[58015]=5,[58228]=5,[63229]=5,[63231]=5,[63235]=5,[63237]=5,[63246]=5,[63248]=5,[107906]=5,[56798]=4,[56799]=4,[56800]=4,[56801]=4,[56802]=4,[56803]=4,[56804]=4,[56805]=4,[56806]=4,[56807]=4,[56808]=4,[56809]=4,[56810]=4,[56811]=4,[56812]=4,[56813]=4,[56814]=4,[56818]=4,[56819]=4,[56820]=4,[56821]=4,[58017]=4,[58027]=4,[58032]=4,[58033]=4,[58038]=4,[58039]=4,[63249]=4,[63252]=4,[63253]=4,[63254]=4,[63256]=4,[63268]=4,[63269]=4,[89758]=4,[91299]=4,[55436]=7,[55437]=7,[55438]=7,[55439]=7,[55440]=7,[55441]=7,[55442]=7,[55443]=7,[55444]=7,[55445]=7,[55446]=7,[55447]=7,[55448]=7,[55449]=7,[55450]=7,[55451]=7,[55452]=7,[55453]=7,[55454]=7,[55455]=7,[55456]=7,[58057]=7,[58058]=7,[58059]=7,[58135]=7,[59289]=7,[62132]=7,[63270]=7,[63271]=7,[63273]=7,[63279]=7,[63280]=7,[63291]=7,[63298]=7,[89646]=7,[101052]=7,[56217]=9,[56218]=9,[56224]=9,[56226]=9,[56228]=9,[56229]=9,[56231]=9,[56232]=9,[56233]=9,[56235]=9,[56238]=9,[56240]=9,[56241]=9,[56242]=9,[56244]=9,[56246]=9,[56247]=9,[56248]=9,[56249]=9,[56250]=9,[58079]=9,[58080]=9,[58081]=9,[58094]=9,[58107]=9,[63302]=9,[63303]=9,[63304]=9,[63309]=9,[63310]=9,[63312]=9,[63320]=9,[70947]=9,[58095]=1,[58096]=1,[58097]=1,[58098]=1,[58099]=1,[58104]=1,[58355]=1,[58356]=1,[58357]=1,[58364]=1,[58366]=1,[58367]=1,[58368]=1,[58369]=1,[58370]=1,[58372]=1,[58375]=1,[58377]=1,[58382]=1,[58384]=1,[58385]=1,[58386]=1,[58387]=1,[58388]=1,[63324]=1,[63325]=1,[63326]=1,[63327]=1,[63328]=1,[63329]=1,[68164]=1,[89003]=1,[94372]=1,[94374]=1,[414812]=1} 
	
	-- Wrath:
	or {[58613]=6,[58616]=6,[58618]=6,[58620]=6,[58623]=6,[58625]=6,[58629]=6,[58631]=6,[58635]=6,[58640]=6,[58647]=6,[58657]=6,[58669]=6,[58671]=6,[58673]=6,[58676]=6,[58677]=6,[58680]=6,[58686]=6,[59307]=6,[59309]=6,[59327]=6,[59332]=6,[59336]=6,[60200]=6,[62259]=6,[63330]=6,[63331]=6,[63332]=6,[63333]=6,[63334]=6,[63335]=6,[52084]=11,[52085]=11,[52648]=11,[54733]=11,[54743]=11,[54754]=11,[54756]=11,[54760]=11,[54810]=11,[54811]=11,[54812]=11,[54813]=11,[54815]=11,[54818]=11,[54821]=11,[54824]=11,[54825]=11,[54826]=11,[54828]=11,[54829]=11,[54830]=11,[54831]=11,[54832]=11,[54845]=11,[54912]=11,[57855]=11,[57856]=11,[57857]=11,[57858]=11,[57862]=11,[58133]=11,[58136]=11,[59219]=11,[62080]=11,[62135]=11,[62969]=11,[62970]=11,[62971]=11,[63055]=11,[63056]=11,[63057]=11,[65243]=11,[67598]=11,[71013]=11,[56824]=3,[56826]=3,[56828]=3,[56829]=3,[56830]=3,[56832]=3,[56833]=3,[56836]=3,[56838]=3,[56841]=3,[56842]=3,[56844]=3,[56845]=3,[56846]=3,[56847]=3,[56848]=3,[56849]=3,[56850]=3,[56851]=3,[56856]=3,[56857]=3,[57866]=3,[57870]=3,[57900]=3,[57902]=3,[57903]=3,[57904]=3,[63065]=3,[63066]=3,[63067]=3,[63068]=3,[63069]=3,[63086]=3,[56360]=8,[56363]=8,[56364]=8,[56365]=8,[56366]=8,[56367]=8,[56368]=8,[56369]=8,[56370]=8,[56371]=8,[56372]=8,[56373]=8,[56374]=8,[56375]=8,[56376]=8,[56377]=8,[56380]=8,[56381]=8,[56382]=8,[56383]=8,[56384]=8,[57924]=8,[57925]=8,[57926]=8,[57927]=8,[57928]=8,[58070]=8,[61205]=8,[62126]=8,[62210]=8,[63090]=8,[63091]=8,[63092]=8,[63093]=8,[63095]=8,[70937]=8,[54922]=2,[54923]=2,[54924]=2,[54925]=2,[54926]=2,[54927]=2,[54928]=2,[54929]=2,[54930]=2,[54931]=2,[54934]=2,[54935]=2,[54936]=2,[54937]=2,[54938]=2,[54939]=2,[54940]=2,[54943]=2,[56414]=2,[56416]=2,[56420]=2,[57937]=2,[57947]=2,[57954]=2,[57955]=2,[57958]=2,[57979]=2,[63218]=2,[63219]=2,[63220]=2,[63222]=2,[63223]=2,[63224]=2,[63225]=2,[63231]=2,[55672]=5,[55673]=5,[55674]=5,[55675]=5,[55676]=5,[55677]=5,[55678]=5,[55679]=5,[55680]=5,[55681]=5,[55682]=5,[55683]=5,[55684]=5,[55685]=5,[55686]=5,[55687]=5,[55688]=5,[55689]=5,[55690]=5,[55691]=5,[55692]=5,[57985]=5,[57986]=5,[57987]=5,[58009]=5,[58015]=5,[58228]=5,[63229]=5,[63235]=5,[63237]=5,[63246]=5,[63248]=5,[56798]=4,[56799]=4,[56800]=4,[56801]=4,[56802]=4,[56803]=4,[56804]=4,[56805]=4,[56806]=4,[56807]=4,[56808]=4,[56809]=4,[56810]=4,[56811]=4,[56812]=4,[56813]=4,[56814]=4,[56818]=4,[56819]=4,[56820]=4,[56821]=4,[58017]=4,[58027]=4,[58032]=4,[58033]=4,[58038]=4,[58039]=4,[63249]=4,[63252]=4,[63253]=4,[63254]=4,[63256]=4,[63268]=4,[63269]=4,[55436]=7,[55437]=7,[55438]=7,[55439]=7,[55440]=7,[55441]=7,[55442]=7,[55443]=7,[55444]=7,[55445]=7,[55446]=7,[55447]=7,[55448]=7,[55449]=7,[55450]=7,[55451]=7,[55452]=7,[55453]=7,[55454]=7,[55455]=7,[55456]=7,[58055]=7,[58057]=7,[58058]=7,[58059]=7,[58063]=7,[58134]=7,[58135]=7,[59289]=7,[62132]=7,[63270]=7,[63271]=7,[63273]=7,[63279]=7,[63280]=7,[63291]=7,[63298]=7,[56216]=9,[56217]=9,[56218]=9,[56224]=9,[56226]=9,[56228]=9,[56229]=9,[56231]=9,[56232]=9,[56233]=9,[56235]=9,[56238]=9,[56240]=9,[56241]=9,[56242]=9,[56244]=9,[56246]=9,[56247]=9,[56248]=9,[56249]=9,[56250]=9,[58079]=9,[58080]=9,[58081]=9,[58094]=9,[58107]=9,[63302]=9,[63303]=9,[63304]=9,[63309]=9,[63310]=9,[63312]=9,[70947]=9,[58095]=1,[58096]=1,[58097]=1,[58098]=1,[58099]=1,[58104]=1,[58353]=1,[58355]=1,[58356]=1,[58357]=1,[58364]=1,[58365]=1,[58366]=1,[58367]=1,[58368]=1,[58369]=1,[58370]=1,[58372]=1,[58375]=1,[58376]=1,[58377]=1,[58382]=1,[58384]=1,[58385]=1,[58386]=1,[58387]=1,[58388]=1,[63324]=1,[63325]=1,[63326]=1,[63327]=1,[63328]=1,[63329]=1,[68164]=1}

	function Module:OnInitialize()
		local _, _, pclassId = UnitClass("player")

		for id, class in pairs(Glyphs) do
			if class == pclassId then
				local name = GetSpellName(id)
				name = strlowerCache[name]
				self.table[id] = name
			end
		end
	end
	function Module:Table_Get()
		return self.table
	end
	function Module:Table_GetNormalSuggestions(suggestions, tbl)
		local atBeginning = SUG.atBeginning
		local lastName = SUG.lastName

		for id, name in pairs(tbl) do
			if strfind(strlower(name), lastName) then
				suggestions[#suggestions + 1] = id
			end
		end
	end
	function Module:Entry_AddToList_1(f, spellID)
		local name, _, tex = GetSpellInfo(spellID)
		
		f.Name:SetText(name)
		f.ID:SetText(spellID)

		f.insert = name
		f.insert2 = spellID

		f.tooltipmethod = TMW.GameTooltip_SetSpellByIDWithClassIcon
		f.tooltiparg = spellID

		f.Icon:SetTexture(tex)
	end
end

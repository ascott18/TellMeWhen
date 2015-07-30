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


TMW.Classes.SharableDataType.types.group:RegisterMenuBuilder(10, function(Item_group)
	local gs = Item_group.Settings
	local IMPORTS, EXPORTS = Item_group:GetEditBox():GetAvailableImportExportTypes()

	-- copy group position
	local info = TMW.DD:CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["COPYPOSSCALE"]
	info.func = function()
		TMW.DD:CloseDropDownMenus()
		local destgroup = IMPORTS.group_overwrite
		local destgs = destgroup:GetSettings()
		
		-- Restore all default settings first.
		-- Not a special table (["**"]), so just normally copy it.
		-- Setting it nil won't recreate it like other settings tables, so re-copy from defaults.
		destgs.Point = CopyTable(TMW.Group_Defaults.Point)
		
		TMW:CopyTableInPlaceWithMeta(gs.Point, destgs.Point, true)

		destgs.Scale = gs.Scale or TMW.Group_Defaults.Scale
		destgs.Level = gs.Level or TMW.Group_Defaults.Level
		destgs.Strata = gs.Strata or TMW.Group_Defaults.Strata
		
		destgroup:Setup()
	end
	info.notCheckable = true
	info.disabled = not IMPORTS.group_overwrite
	TMW.DD:AddButton(info)
end)


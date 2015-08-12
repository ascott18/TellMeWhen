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

local CNDT = TMW.CNDT

local TMW = TMW
local L = TMW.L
local print = TMW.print



TMW:RegisterCallback("TMW_CNDT_GROUP_DRAWGROUP", function(event, CndtGroup, conditionData, conditionSettings)
	if conditionData and conditionData.identifier == "LUA" then
		if not CndtGroup.EditBox.HookedGUIDInsertion then 

			TMW.Classes.ChatEdit_InsertLink_Hook:New(CndtGroup.EditBox, function(self, text, linkType, linkData)

				-- if this editbox is active and is for a Lua condition,
				-- attempt to insert a reference to the icon by GUID into the editbox
				if linkType == "TMW" and TMW.CNDT:GetSettings()[CndtGroup:GetID()].Type == "LUA" then

					-- Reconstruct the GUID
					local GUID = linkType .. ":" .. linkData

					self.editbox:Insert(("TMW:GetDataOwner(%q)"):format(GUID))

					-- notify success
					return true
				end
			end)

			CndtGroup.EditBox.HookedGUIDInsertion = true
		end
	end
end)


TMW.IconDragger:RegisterIconDragHandler(210, -- Add as icon shown condition
	function(IconDragger, info)
		if IconDragger.desticon then
			if IconDragger.srcicon:IsValid() then
				info.text = L["ICONMENU_APPENDCONDT"]
				info.tooltipTitle = nil
				info.tooltipText = nil
				return true
			end
		end
	end,
	function(IconDragger)
		-- add a condition to the destination icon
		local Condition = CNDT:AddCondition(IconDragger.desticon:GetSettings().Conditions)

		-- set the settings
		Condition.Type = "ICON"
		Condition.Icon = IconDragger.srcicon:GetGUID(true)
	end
)
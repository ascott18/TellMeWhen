local AceDB = LibStub("AceDB-3.0")

local TMW_GetUpgradeTable = TMW.GetUpgradeTable

TellMeWhen_TestDB = {
	["profileKeys"] = {
		["Cybeloras - Mal'Ganis"] = "Cybeloras - Mal'Ganis",
	},
	profiles = {
		["Cybeloras - Mal'Ganis"] = {
			Version = 1,
			EffThreshold	=	5,
			TextureName		= 	"NonExistantTexture",
			DrawEdge		=	true,
			NumGroups = 1,
			Groups = {
				[1] = {
					Rows = 1,
					Columns = 3,
					Strata			= "FULLSCREEN",
					Scale			= 4.0,
					SortPriorities = {
						{Method = "duration",		Order =	-1,	},
						{Method = "id",				Order =	-1,	},
					},
					Conditions = {
						n 					= 1,
						[1] = {
							Type 	   		= "MANA",
							Operator   		= ">",
							Level 	   		= 90,
							Unit 	   		= "player",
						},
					},
					Icons = {
						[1] = {
							CBarOffs				= 3,
							Type					= "test1",
						},
						[2] = {
							Type					= "test2",
							Conditions = {
								n 					= 1,
								[1] = {
									AndOr 	   		= "OR",
									Type 	   		= "HEALTH",
									Operator   		= "<",
									Level 	   		= 40,
									Unit 	   		= "target",
								},
							},
						},
						[3] = {
							Type					= "test2",
						},
					},
				},
			},
		},
	},
}
local realDB = TMW.db
TMW.db = AceDB:New("TellMeWhen_TestDB", TMW.Defaults)

function TMW:GetUpgradeTable()
	
	local t = {
		[3] = {
			global = function(self)
				if TMW.db.profile.TextureName == "NonExistantTexture" then
					TMW.db.profile.TextureName = "Blizzard"
				end
				if TMW.db.profile.DrawEdge and TMW.db.profile.EffThreshold == 5 then
					TMW.db.profile.DrawEdge = false
				end
			end,
			icon = function(self, ics, groupID, iconID)
				if groupID == 1 and iconID == 1 and ics.CBarOffs == 3 then
					ics.CBarOffs = 2
				end
				if groupID == 1 and iconID == 3 and ics.Type == "test2" then
					ics.Type = "test3"
				end
			end,
			condition = function(self, condition, conditionID, groupID, iconID)
				if conditionID == 1 and groupID == 1 and iconID == 2 then
					condition.Level = 50
				end
			end,
		},
		[7] = {
			global = function(self)
				if not TMW.db.profile.DrawEdge and TMW.db.profile.EffThreshold == 5 then
					TMW.db.profile.EffThreshold = 7
				end
			end,
			icon = function(self, ics, groupID, iconID)
				if groupID == 1 and iconID == 1 and ics.CBarOffs == 2 then
					ics.CBarOffs = 1
				end
			end,
			condition = function(self, condition, conditionID, groupID, iconID)
				if conditionID == 1 and groupID == 1 and not iconID then
					condition.Level = 5.2
				end
			end,
		}	
	}
	
	TMW.UpgradeTable = {}
	for k, v in pairs(t) do
		v.Version = k
		tinsert(TMW.UpgradeTable, v)
	end
	sort(TMW.UpgradeTable, function(a, b)
			if a.priority or b.priority then
				if a.priority and b.priority then
					return a.priority < b.priority
				else
					return a.priority
				end
			end
			return a.Version < b.Version
	end)
	return TMW.UpgradeTable
end

TMW:DoUpgrade("global", TMW.db.profile.Version)

assert(TMW.db.profile.TextureName == "Blizzard")
assert(TMW.db.profile.EffThreshold == 7)
assert(TMW.db.profile.Groups[1].Icons[3].Type == "test3")
assert(TMW.db.profile.Groups[1].Icons[1].CBarOffs == 1)
assert(TMW.db.profile.Groups[1].Icons[2].Conditions[1].Level == 50)
assert(TMW.db.profile.Groups[1].Conditions[1].Level == 5.2)
assert(TMW.db.profile.Version == TELLMEWHEN_VERSIONNUMBER)

TMW.db = realDB
TMW.GetUpgradeTable = TMW_GetUpgradeTable
TellMeWhen_TestDB = nil
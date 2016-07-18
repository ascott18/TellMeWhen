
local function PRINT(...)
    DEFAULT_CHAT_FRAME:AddMessage(strjoin(" ", ...))
end

local match = "silenc"
print("RESULTS FOR MATCH ", match)

local Parser = GameTooltip

local CSC = TMW:GetModule("ClassSpellCache"):GetCache()

    local results = {}
for class, spells in pairs(CSC) do
    for spellID in pairs(spells) do
        Parser:SetOwner(UIParent, "ANCHOR_NONE")
        
        Parser:SetSpellByID(spellID)
        for i, fs in TMW:Vararg(Parser:GetRegions()) do
            if fs.GetText then
                local text = fs:GetText()
                if text then
                    text = text:lower()
                    if text:find(match) then
                        PRINT(class, GetSpellInfo(spellID), spellID, text)
                        tinsert(results, spellID)
                    end
                end
            end
        end
    end
end

sort(results)
for k, v in pairs(results) do

    PRINT(v, GetSpellInfo(v), nil)
end


local match = "finishes"
print("RESULTS FOR MATCH ", match)

local Parser = GameTooltip

local CSC = TMW:GetModule("ClassSpellCache"):GetCache()

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
                        print(class, spellID, text)
                    end
                end
            end
        end
        
    end
end

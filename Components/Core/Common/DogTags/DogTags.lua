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

local DogTag = LibStub("LibDogTag-3.0")

local DOGTAGS = TMW:NewModule("DogTags")
TMW.DOGTAGS = DOGTAGS



-- The purpose of this is to remove the code from a function that prevents it from updating its text
-- if the unit kwarg doesn't exist. This happens all the time in TMW, but it doesn't mean we should
-- send the rest of the text to the abyss. I tried making this change to LDT-Unit-3.0, a long time
-- ago, but got yelled at because apparently it broke something for other addons. This solution
-- can only break things for TMW, which is perfect.
DogTag:AddCompilationStep("TMW", "finish", function(t, ast, kwargTypes, extraKwargs)
    if kwargTypes["unit"] then
        for i = 1, #t do
            if t[i] == [=[if ]=]

            -- extraKwargs gets cleared out (seriously? why the fuck would you do that?) before finish steps,
            -- so we can't check for this. It doesn't matter, though, because the next line is unique.
            --and t[i+1] == extraKwargs["unit"][1] 

            and t[i+2] == [=[ ~= "player" and not UnitExists(]=]
            then
            	local safety = 0
                while tremove(t, i) ~= [=[end;]=] do
                    -- continue deleting
                    safety = safety + 1
                    if safety > 1000 then
                    	error("loop went on way too long")
                    	return
                    end
                end
            end
        end
    end
end)


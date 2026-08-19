-- --------------------
-- TellMeWhen
-- Originally by NephMakes

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local print = TMW.print
local issecretvalue = TMW.issecretvalue

local pairs, wipe, max, CreateFrame =
	  pairs, wipe, max, CreateFrame

local Type = rawget(TMW.Types, "meta")
if not Type then return end


-- ----------------------------------------------------------------------------
-- Stacked meta icons
--
-- A meta icon normally reads its component icons' computed visibility, picks the first one
-- that is showing, and copies that icon's data and module setup onto itself. Neither half
-- of that survives secret values. An icon whose visibility comes from a secret publishes a
-- realAlpha of 1 whatever the secret says (IconStateArbitrator has nothing else it could
-- publish), so the first component always looks like the one to show; and an aura container
-- icon has no data to copy at all - its display is Blizzard's own aura buttons.
--
-- A stacked meta icon reads nothing. It takes its component icons out of their groups,
-- parents them into its own cell one on top of the next, and lets each one hide itself with
-- its own alpha, secret or not. Priority is draw order: the first component in the list is
-- on top.
--
-- Draw order alone would leave a lower-priority component showing through wherever the one
-- above it doesn't cover, and two components are usually both showing at once (a buff and
-- that buff's cooldown run together). So each component also hangs off a chain of frames,
-- one per component above it, each transparent exactly while its own component is showing:
--
--     meta icon --- component 1
--          |
--        chain 1 --- component 2          chain N is transparent
--          |                              while component N is showing
--        chain 2 --- component 3
--
-- Alpha nests, so component N is visible only when every component above it is hidden,
-- which is what a meta icon has always done - now without reading anything. A component
-- whose visibility is secret drives its chain frame with SetAlphaFromBoolean, leaving the
-- secret to be applied by the engine instead of branched on here.
-- ----------------------------------------------------------------------------

local Stack = {}
Type.Stack = Stack

-- Frame level room for one component's own display. An icon's modules take levels at fixed
-- offsets from the icon (TMW.CONST.FRAMELEVEL tops out at 5), so consecutive components
-- have to be at least this far apart to keep their displays from interleaving.
local LEVEL_STRIDE = 10

-- Published while stacked, in place of the state a meta icon would inherit from the
-- component it is showing. The meta icon is only the cell the components are stacked into:
-- it draws nothing, and full opacity here leaves each component's own alpha - and the meta
-- icon's own conditions, which outrank this state - to decide what is visible.
local STATE_CARRIER = { Alpha = 1, Color = "ffffffff", Texture = "" }


-- The chain frame that hides everything below component `index`. Created on demand; frame
-- `index` is a child of frame `index-1` so that their opacities multiply.
local function GetChainFrame(host, index)
	local chain = host.__stackChain
	if not chain then
		chain = {}
		host.__stackChain = chain
	end

	local frame = chain[index]
	if not frame then
		frame = CreateFrame("Frame", nil, index == 1 and host or GetChainFrame(host, index - 1))
		frame:SetAllPoints(host)
		chain[index] = frame
	end

	return frame
end

-- Whether a state counts as showing. The same test a meta icon has always made on
-- realAlpha: any opacity at all is showing, including a dimmed "absent" state.
local function StateShows(state)
	return state ~= nil and state.Alpha ~= nil and state.Alpha > 0
end

-- Point the chain frame below component `index` at that component's current visibility.
function Stack.UpdateSuppression(host, index)
	local stack = host.__stack
	if not index or index >= #stack then
		-- The last component has nothing under it to hide.
		return
	end

	local ic = stack[index]
	local frame = GetChainFrame(host, index)
	local state = ic.attributes.calculatedState

	if ic.typeData.stackedVisibilityUnknown or ic.__stacked then
		-- Nothing this icon publishes says whether it is drawing anything - either its type
		-- can't say (an aura container) or it is a stack itself, and a stack publishes the
		-- full opacity it carries its own components with. The components under it can only
		-- be covered up, never switched off.
		frame:SetAlpha(1)
	elseif state and state.secretBool ~= nil then
		frame:SetAlphaFromBoolean(state.secretBool,
			StateShows(state.trueState) and 0 or 1,
			StateShows(state.falseState) and 0 or 1
		)
	elseif issecretvalue(ic.attributes.realAlpha) then
		frame:SetAlpha(1)
	else
		frame:SetAlpha(ic.attributes.realAlpha > 0 and 0 or 1)
	end
end

TMW:RegisterCallback("TMW_ICON_DATA_CHANGED_CALCULATEDSTATE", function(event, icon)
	local host = icon.__stackHost
	if host and host.__stackLookup then
		Stack.UpdateSuppression(host, host.__stackLookup[icon])
	end
end)


-- Fake Hidden means "keep this icon working but don't draw it", which is how component
-- icons are normally kept out of sight for a meta icon that copies their data. A stacked
-- meta icon draws the component itself, so the setting has to come off while we hold it.
local function SetFakeHidden(ic, value)
	local Module = ic:GetModuleOrModuleChild("IconModule_Alpha", true)
	if Module and Module.FakeHidden ~= value then
		Module.FakeHidden = value

		local state = ic.attributes.calculatedState
		if state then
			Module:CALCULATEDSTATE(ic, state)
		end
	end
end


-- Hand a component icon back to its own group.
function Stack.ReleaseIcon(ic)
	if not ic.__stackHost then return end

	ic.__stackHost = nil
	SetFakeHidden(ic, ic.FakeHidden)

	local group = ic.group
	ic:SetParent(group)
	ic:SetFrameLevel(group:GetFrameLevel() + 1)

	local viewData = group.viewData
	if viewData then
		ic:SetSize(viewData:Icon_GetSize(ic))
	end

	-- Its cell is its group's to give back - the group skipped it while we held it.
	local IconPosition = group:GetModuleOrModuleChild("GroupModule_IconPosition", true)
	if IconPosition then
		IconPosition:PositionIcons()
	end
end

-- Hand every component icon back to its own group.
function Stack.Release(host)
	host.__stacked = nil

	local stack = host.__stack
	if stack then
		for i = #stack, 1, -1 do
			Stack.ReleaseIcon(stack[i])
		end
		wipe(stack)
		wipe(host.__stackLookup)
	end

	local chain = host.__stackChain
	if chain then
		for i = 1, #chain do
			chain[i]:SetAlpha(1)
		end
	end
end


-- Whether stacking `ic` here would put the two icons inside each other - which is what two
-- stacked meta icons that list each other are asking for.
local function WouldCycle(host, ic)
	while host do
		if host == ic then
			return true
		end
		host = host.__stackHost
	end

	return false
end

local wasHeld = {}

-- Bring the stack in line with the meta icon's current component list. Idempotent, and
-- cheap enough to re-run whenever anything the meta icon depends on is set up again, which
-- is the only way it hears that a component now exists.
function Stack.Apply(host)
	host.__stackDirty = nil

	local stack = host.__stack
	local lookup = host.__stackLookup

	wipe(wasHeld)
	for i = 1, #stack do
		wasHeld[stack[i]] = true
	end
	wipe(stack)
	wipe(lookup)

	-- Collected in full first: a component's frame level depends on how many there are.
	for i = 1, #host.CompiledIcons do
		local ic = TMW.GUIDToOwner[host.CompiledIcons[i]]

		if ic and ic ~= host and ic.Enabled and ic.viewData == host.viewData then
			if ic.__stackHost ~= nil and ic.__stackHost ~= host then
				TMW:Warn(L["META_STACKED_TAKEN"]:format(
					host:GetIconName(true), ic:GetIconName(true), ic.__stackHost:GetIconName(true)
				))
			elseif WouldCycle(host, ic) then
				TMW:Warn(L["META_STACKED_RECURSIVE"]:format(
					host:GetIconName(true), ic:GetIconName(true)
				))
			else
				stack[#stack + 1] = ic
				lookup[ic] = #stack
			end
		end
	end

	local count = #stack
	local level = host:GetFrameLevel()
	local sizeX, sizeY = host.viewData:Icon_GetSize(host)

	for i = 1, count do
		local ic = stack[i]

		-- Both re-applied rather than only set on the way in: a component that was set up
		-- again since kept its place in the stack but read its own settings back.
		ic.__stackHost = host
		SetFakeHidden(ic, false)
		wasHeld[ic] = nil

		ic:SetParent(i == 1 and host or GetChainFrame(host, i - 1))
		ic:SetFrameLevel(level + 1 + (count - i)*LEVEL_STRIDE)
		ic:SetSize(sizeX, sizeY)

		-- Recorded as well as applied: animations that move an icon (Shake) put it back
		-- from here when they finish.
		local position = ic.position
		position.point, position.relativePoint = "TOPLEFT", "TOPLEFT"
		position.relativeTo = host
		position.x, position.y = 0, 0

		ic:ClearAllPoints()
		ic:SetPoint(position.point, position.relativeTo, position.relativePoint, position.x, position.y)
	end

	-- Chain frames past the end of the stack would go on hiding whatever lands under them.
	-- The frame at `count` is one of those: the last component has nothing under it.
	local chain = host.__stackChain
	if chain then
		for i = max(count, 1), #chain do
			chain[i]:SetAlpha(1)
		end
	end

	for i = 1, count do
		Stack.UpdateSuppression(host, i)
	end

	for ic in pairs(wasHeld) do
		Stack.ReleaseIcon(ic)
	end
end


-- The meta icon's own display, which the components are drawn on top of. Modules flagged
-- dontInherit stay: they are the icon's alpha - what the whole stack hangs off - and its
-- click and condition handlers.
local function DisableOwnDisplay(host)
	for _, Module in pairs(host.Modules) do
		if Module.IsImplemented and not Module.dontInherit then
			Module:Disable()
		end
	end
end

-- Called from Type:Setup. Returns true if the icon is going to stack its components.
function Stack.Setup(host)
	host.__stack = host.__stack or {}
	host.__stackLookup = host.__stackLookup or {}

	-- Config mode leaves every icon in its own group, where it can be seen and dragged.
	-- A group controller already gives each component a cell, which is the opposite of this.
	if not (host.Stacked and TMW.Locked) or host:IsGroupController() then
		Stack.Release(host)
		return false
	end

	host.__stacked = true
	DisableOwnDisplay(host)
	-- The inherited state goes with the rest of the copying: it outranks the carrier state
	-- and would otherwise pin the icon to whatever it last showed.
	host:SetInfo("state; state_metaChild", STATE_CARRIER, nil)

	host.__stackDirty = true
	host.NextUpdateTime = 0

	return true
end

-- Setup runs before the components of a meta icon in a later group exist, and a component
-- that is set up again reverts its own size and frame level, so the stack is rebuilt
-- whenever anything it depends on is set up. Type:Setup and Meta_OnEvent flag it.
function Stack.OnUpdate(host, time)
	if host.__stackDirty then
		Stack.Apply(host)
	end
end

TMW:RegisterCallback("TMW_ICON_DISABLE", function(event, icon)
	if icon.__stack then
		Stack.Release(icon)
	end
end)

-- Classes
Condo = {}
Condo.__index = Condo

--[[
	Condo Constructor

	Parameters:
		slider (element)
		slot (element)
		railNorth (element)
		railEast (element)
		railSouth (element)
		railWest (element)
]]
function Condo.new(slider, slot, railNorth, railEast, railSouth, railWest)
	local self = setmetatable({}, Condo)
	self.slider = slider
	self.slot = slot
	self.railNorth = railNorth
	self.railEast = railEast
	self.railSouth = railSouth
	self.railWest = railWest

	-- Needs to stay in sync with animation toggle
	self.railNorthActive = false
	self.railEastActive = false
	self.railSouthActive = false
	self.railWestActive = false

	self.height = 0

	return self
end

-- Returns whether condo height value was changed from previous state
function Condo:heightChanged()
	local newHeight = round(self.slider.value * 3)

	if self.height != newHeight then
		self.height = newHeight
		return true
	else
		return false
	end
end

-- Return whether a person figure is slotted in
function Condo:slotted()
	return self.slot.unlocked
end

--[[
	Raise/lower rail.

	Parameters:
		active (bool) - True is up. False is down.

	Returns true if a change was made
]]
function Condo:setRailNorth(active)
	if (active and not self.railNorthActive)
	or (not active and self.railNorthActive) then
		self.railNorthActive = active
		api.setLockValue(self.railNorth, 1, 1)
		return true
	else
		return false
	end
end

function Condo:setRailEast(active)
	if (active and not self.railEastActive)
	or (not active and self.railEastActive) then
		self.railEastActive = active
		api.setLockValue(self.railEast, 1, 1)
		return true
	else
		return false
	end
end

function Condo:setRailSouth(active)
	if (active and not self.railSouthActive)
	or (not active and self.railSouthActive) then
		self.railSouthActive = active
		api.setLockValue(self.railSouth, 1, 1)
		return true
	else
		return false
	end
end

function Condo:setRailWest(active)
	if (active and not self.railWestActive)
	or (not active and self.railWestActive) then
		self.railWestActive = active
		api.setLockValue(self.railWest, 1, 1)
		return true
	else
		return false
	end
end

--[[
	ScreenLight Constructor

	Parameters:
		lightHide (element) - activator that hides the light
		lightShow (element) - activator that shows the light
		coverHide (element) - activator that hides the light cover
		coverShow (element) - activator that shows the light cover
]]
ScreenLight = {}
ScreenLight.__index = ScreenLight

function ScreenLight.new(lightHide, lightShow, coverHide, coverShow)
	local self = setmetatable({}, ScreenLight)
	self.lightHide = lightHide
	self.lightShow = lightShow
	self.coverHide = coverHide
	self.coverShow = coverShow
	self.active = false
	self:off()
	return self
end

function ScreenLight:on()
	if not self.active then
		self.active = true
		api.toggleActivator(self.lightShow)
		api.toggleActivator(self.coverHide)
		api.setLockValue(zesty_sfx_condolight, 1, 1)
	end
end

function ScreenLight:off()
	if (self.active) then
		api.setLockValue(zesty_sfx_condolight, 1, 1)
	end
	self.active = false
	api.toggleActivator(self.lightHide)
	api.toggleActivator(self.coverShow)
end

-- Functions
function round(num)
    return math.floor(num + 0.5)
end

--[[
	Return table of cells that describe what is visible from a certain perspective.

	Parameters:
		condos (Condo[][]) - 2D table of condos to check.
			Ex:
				Condo[1][1] is the condo in the back/furthest row, to the left
				Condo[1][2] is the condo in the back/furthest row, in the middle
				Condo[3][3] is the condo in the front/closest row, to the right
	
	Return example:
		{
			{1, 0, 0}, -- Bottom row - has a person visible on the left
			{0, 1, 0}, -- Mid-height row - has a person visible in middle
			{0, 0, 0}, -- Top row - no one visible
		}
]]
function getPerspective(condosPerspective)
	local perspective = {}

	for y = 1, 3 do
		perspective[y] = {}
		for x = 1, 3 do
			perspective[y][x] = 0
		end
	end

	for y, row in ipairs(condosPerspective) do
		for x, condo in ipairs(row) do
			-- Check condo height, overwrite previous values (as though the condo is blocking the view of things behind)

			for z = 1, condo.height do
				perspective[z][x] = 0
			end

			-- Record whether a person is slotted
			if condo:slotted() and condo.height <= 2 then -- Ignore if condo is fully extended
				perspective[condo.height + 1][x] = 1
			end
		end
	end

	return perspective
end

function updateCondoRails(playSound)
	local playSound = playSound or false
	local changed = 0

	-- Raise/lower guard rails (completely aesthetic)
	for y, condoRow in ipairs(condos) do
		for x, condo in ipairs(condoRow) do

			-- North
			if y == 1 then
				changed = changed + (condo:setRailNorth(true) and 1 or 0)
			else
				local condoNeighbourNorth = condos[y - 1][x]
				if condo.height > condoNeighbourNorth.height then
					changed = changed + (condo:setRailNorth(true) and 1 or 0)
				else 
					changed = changed + (condo:setRailNorth(false) and 1 or 0)
				end
			end

			-- West
			if x == 1 then
				changed = changed + (condo:setRailWest(true) and 1 or 0)
			else
				local condoNeighbourWest = condos[y][x - 1]
				if condo.height > condoNeighbourWest.height then
					changed = changed + (condo:setRailWest(true) and 1 or 0)
				else 
					changed = changed + (condo:setRailWest(false) and 1 or 0)
				end
			end

			-- South
			if y == 3 then
				changed = changed + (condo:setRailSouth(true) and 1 or 0)
			else
				local condoNeighbourSouth = condos[y + 1][x]
				if condo.height > condoNeighbourSouth.height then
					changed = changed + (condo:setRailSouth(true) and 1 or 0)
				else 
					changed = changed + (condo:setRailSouth(false) and 1 or 0)
				end
			end

			-- East
			if x == 3 then
				changed = changed + (condo:setRailEast(true) and 1 or 0)
			else
				local condoNeighbourEast = condos[y][x + 1]
				if condo.height > condoNeighbourEast.height then
					changed = changed + (condo:setRailEast(true) and 1 or 0)
				else 
					changed = changed + (condo:setRailEast(false) and 1 or 0)
				end
			end
		end
	end

	-- Play sound when condo rails raised/lowered
	if playSound then
		if changed > 0 then
			api.setLockValue(zesty_sfx_condorail, 1, 1)
		else
			api.setLockValue(zesty_sfx_condoclick, 1, 1)
		end
	end
end

-- Update the screen state to show which "man" is obscured/visible after a condo pillar is changed.	
function updateScreen(screenIcons, perspective)
	for y, row in ipairs(perspective) do
		for x, cell in ipairs(row) do
			local visible = perspective[y][x] == 1
			local activators = screenIcons[y][x]
			local hide = activators[1]
			local show = activators[2]

			if visible then
				api.toggleActivator(show)
			else
				api.toggleActivator(hide)
			end
		end
	end

end

function updateCondos()
	-- Check perspectives
	local perspectiveSouth = getPerspective(condosSouthPerspective)
	local perspectiveWest = getPerspective(condosWestPerspective)
	local perspectiveEast = getPerspective(condosEastPerspective)

	-- Update screen
	updateScreen(condoScreenSouth, perspectiveSouth)
	updateScreen(condoScreenWest, perspectiveWest)
	updateScreen(condoScreenEast, perspectiveEast)
	
	local southMatched = areTablesEqual(condosSouthSolution, perspectiveSouth)
	local westMatched = areTablesEqual(condosWestSolution, perspectiveWest)
	local eastMatched = areTablesEqual(condosEastSolution, perspectiveEast)

	if southMatched then
		screenLightSouth:on()
	else
		screenLightSouth:off()
	end

	if westMatched then
		screenLightWest:on()
	else
		screenLightWest:off()
	end

	if eastMatched then
		screenLightEast:on()
	else
		screenLightEast:off()
	end

	if southMatched and westMatched and eastMatched then
		api.setLockValue(zesty_condo_complete, 1, 1)
	end
end

function complete()
	if win then
		return false
	end

	api.toggleActivator(zesty_condotoken_show)

	local northWestCondo = condos[1][1]

	northWestCondo:setRailNorth(false)
	northWestCondo:setRailSouth(false)
	northWestCondo:setRailEast(false)
	northWestCondo:setRailWest(false)

	win = true
end

-- Return whether two 2D tables have the same values.
-- Note: Assumes both tables are equal dimensions.
function areTablesEqual(table1, table2)
    for i = 1, #table1 do
        -- Check each element in the row
        for j = 1, #table1[i] do
            if table1[i][j] ~= table2[i][j] then
                return false  -- Found a mismatch
            end
        end
    end

    return true
end

-- For debugging
function printTable(table)
	for y = 1, #table do
		local line = ""
		for x = 1, #table[y] do
			line = line .. table[y][x] .. "\t"
		end
		api.log(line)
	end
end


if callType == LuaCallType.Unlock then
	if context == zesty_init then
		win = false

		api.toggleActivator(zesty_condopillars_hide)
		api.toggleActivator(zesty_condoscreenw_hide)
		api.toggleActivator(zesty_condoscreens_hide)
		api.toggleActivator(zesty_condoscreene_hide)
	
		condos = {
			{
				Condo.new(
					zesty_condo_11_slider,
					zesty_condo_11_slot,
					zesty_condo_rail_toggle_11n,
					zesty_condo_rail_toggle_11e,
					zesty_condo_rail_toggle_11s,
					zesty_condo_rail_toggle_11w
				),
				Condo.new(
					zesty_condo_12_slider,
					zesty_condo_12_slot,
					zesty_condo_rail_toggle_12n,
					zesty_condo_rail_toggle_12e,
					zesty_condo_rail_toggle_12s,
					zesty_condo_rail_toggle_12w
				),
				Condo.new(
					zesty_condo_13_slider,
					zesty_condo_13_slot,
					zesty_condo_rail_toggle_13n,
					zesty_condo_rail_toggle_13e,
					zesty_condo_rail_toggle_13s,
					zesty_condo_rail_toggle_13w
				),
			},
			{
				Condo.new(
					zesty_condo_21_slider,
					zesty_condo_21_slot,
					zesty_condo_rail_toggle_21n,
					zesty_condo_rail_toggle_21e,
					zesty_condo_rail_toggle_21s,
					zesty_condo_rail_toggle_21w
				),
				Condo.new(
					zesty_condo_22_slider,
					zesty_condo_22_slot,
					zesty_condo_rail_toggle_22n,
					zesty_condo_rail_toggle_22e,
					zesty_condo_rail_toggle_22s,
					zesty_condo_rail_toggle_22w
				),
				Condo.new(
					zesty_condo_23_slider,
					zesty_condo_23_slot,
					zesty_condo_rail_toggle_23n,
					zesty_condo_rail_toggle_23e,
					zesty_condo_rail_toggle_23s,
					zesty_condo_rail_toggle_23w
				),
			},
			{
				Condo.new(
					zesty_condo_31_slider,
					zesty_condo_31_slot,
					zesty_condo_rail_toggle_31n,
					zesty_condo_rail_toggle_31e,
					zesty_condo_rail_toggle_31s,
					zesty_condo_rail_toggle_31w
				),
				Condo.new(
					zesty_condo_32_slider,
					zesty_condo_32_slot,
					zesty_condo_rail_toggle_32n,
					zesty_condo_rail_toggle_32e,
					zesty_condo_rail_toggle_32s,
					zesty_condo_rail_toggle_32w
				),
				Condo.new(
					zesty_condo_33_slider,
					zesty_condo_33_slot,
					zesty_condo_rail_toggle_33n,
					zesty_condo_rail_toggle_33e,
					zesty_condo_rail_toggle_33s,
					zesty_condo_rail_toggle_33w
				),
			},
		}
	
		condoScreenSouth = {
			{
				{zesty_condomans11_hide, zesty_condomans11_show},
				{zesty_condomans12_hide, zesty_condomans12_show},
				{zesty_condomans13_hide, zesty_condomans13_show},
			},
			{
				{zesty_condomans21_hide, zesty_condomans21_show},
				{zesty_condomans22_hide, zesty_condomans22_show},
				{zesty_condomans23_hide, zesty_condomans23_show},
			},
			{
				{zesty_condomans31_hide, zesty_condomans31_show},
				{zesty_condomans32_hide, zesty_condomans32_show},
				{zesty_condomans33_hide, zesty_condomans33_show},
			}
		}
	
		condoScreenWest = {
			{
				{zesty_condomanw11_hide, zesty_condomanw11_show},
				{zesty_condomanw12_hide, zesty_condomanw12_show},
				{zesty_condomanw13_hide, zesty_condomanw13_show},
			},
			{
				{zesty_condomanw21_hide, zesty_condomanw21_show},
				{zesty_condomanw22_hide, zesty_condomanw22_show},
				{zesty_condomanw23_hide, zesty_condomanw23_show},
			},
			{
				{zesty_condomanw31_hide, zesty_condomanw31_show},
				{zesty_condomanw32_hide, zesty_condomanw32_show},
				{zesty_condomanw33_hide, zesty_condomanw33_show},
			}
		}
	
		condoScreenEast = {
			{
				{zesty_condomane11_hide, zesty_condomane11_show},
				{zesty_condomane12_hide, zesty_condomane12_show},
				{zesty_condomane13_hide, zesty_condomane13_show},
			},
			{
				{zesty_condomane21_hide, zesty_condomane21_show},
				{zesty_condomane22_hide, zesty_condomane22_show},
				{zesty_condomane23_hide, zesty_condomane23_show},
			},
			{
				{zesty_condomane31_hide, zesty_condomane31_show},
				{zesty_condomane32_hide, zesty_condomane32_show},
				{zesty_condomane33_hide, zesty_condomane33_show},
			}
		}
	
		condosSouthPerspective = condos
	
		condosWestPerspective = {
			{
				condos[1][3],
				condos[2][3],
				condos[3][3],
			},
			{
				condos[1][2],
				condos[2][2],
				condos[3][2],
			},
			{
				condos[1][1],
				condos[2][1],
				condos[3][1],
			},
		}
	
		condosEastPerspective = {
			{
				condos[3][1],
				condos[2][1],
				condos[1][1],
			},
			{
				condos[3][2],
				condos[2][2],
				condos[1][2],
			},
			{
				condos[3][3],
				condos[2][3],
				condos[1][3],
			},
		}
	
		condosSouthSolution = {
			{ 0, 0, 0 },
			{ 1, 1, 0 },
			{ 0, 0, 1 },
		}
		
		condosWestSolution = {
			{ 0, 0, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 0 },
		}
	
		condosEastSolution = {
			{ 0, 1, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 1 },
		}
	
		screenLightSouth = ScreenLight.new(
			zesty_condolights_hide,
			zesty_condolights_show,
			zesty_condolightcovers_hide,
			zesty_condolightcovers_show
		)

		screenLightWest = ScreenLight.new(
			zesty_condolightw_hide,
			zesty_condolightw_show,
			zesty_condolightcoverw_hide,
			zesty_condolightcoverw_show
		)

		screenLightEast = ScreenLight.new(
			zesty_condolighte_hide,
			zesty_condolighte_show,
			zesty_condolightcovere_hide,
			zesty_condolightcovere_show
		)
		
		updateCondos()
		updateCondoRails(false)
	elseif context == zesty_condo_update then
		if condos ~= nil then
			updateCondos()
			--[[
				Bug: this gets triggered twice when the item is slotted (here, and in LuaCallType.Slot).
				It's not a huge deal, it just means it runs this function twice each time a person is slotted.
				Not sure how to avoid this.
				- Zesty
			]]
		end
	elseif context == zesty_condo_lid_open then
		api.toggleActivator(zesty_condopillars_show)
		api.toggleActivator(zesty_condoscreenw_show)
		api.toggleActivator(zesty_condoscreens_show)
		api.toggleActivator(zesty_condoscreene_show)
		api.toggleActivator(zesty_digit3_hide) -- Hide power display
	elseif context == zesty_condo_complete then
		complete()
	end
elseif callType == LuaCallType.Slot then
	if condos ~= nil then
		for _, condoRow in ipairs(condos) do
			for _, condo in ipairs(condoRow) do
				if context == condo.slot then
					updateCondos()
				end
			end
		end
	end
elseif callType == LuaCallType.SlidableMoved then
	for _, condoRow in ipairs(condos) do
		for _, condo in ipairs(condoRow) do
			if context == condo.slider then
				if condo:heightChanged() then
					updateCondoRails(true)
				end
			end
		end
	end
end
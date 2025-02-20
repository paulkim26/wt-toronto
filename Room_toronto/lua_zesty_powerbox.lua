-- Classes
PowerSlot = {}
PowerSlot.__index = PowerSlot

--[[
	PowerSlot Constructor

	Parameters:
		element (element) - Element name of slot.
		x (num) - Origin x position on grid.
			Ex: A connector whose left/top node is on the leftmost column has x = 1
		y (num) - Origin y position on grid.
			Ex: A connector whose left/top node is on the topmost row has y = 1
		horizontal (bool) - Whether the connector is horizontal or vertical.
			Ex: true -> horizontal connector
			Ex: false -> vertical connector
		hide (element) - Activator that hides slot.
		show (element) - Activator that shows slot.
]]
function PowerSlot.new(element, x, y, horizontal, hide, show)
	local self = setmetatable({}, PowerSlot)
	self.element = element
	self.x = x
	self.y = y
	self.horizontal = horizontal
	self.hide = hide
	self.show = show
	
	self.cells = {}
	for i = 0, 3 do
		local x = self.x
		local y = self.y
		if horizontal then
			x = x + i
		else
			y = y + i
		end
		table.insert(self.cells, {x, y})
	end

	return self
end

-- Return whether slot is occupied
function PowerSlot:isFilled()
	return self.element.unlocked
end

-- Enable slot's collider
function PowerSlot:enable()
	api.toggleActivator(self.show)
end

-- Disable slot's collider
function PowerSlot:disable()
	api.toggleActivator(self.hide)
end

PowerNode = {}
PowerNode.__index = PowerNode

--[[
	PowerNode Constructor

	Parameters:
		onHide (element) - Activator that hides "On" element.
		onShow (element) - Activator that shows "On" element.
		offHide (element) - Activator that hides "Off" element.
		offShow (element) - Activator that shows "Off" element.
		x (num) - Origin x position on grid.
		y (num) - Origin y position on grid.
		energy (num) - How much energy this node provides when on.
]]
function PowerNode.new(onHide, onShow, offHide, offShow, x, y, energy)
	local self = setmetatable({}, PowerNode)
	self.onHide = onHide
	self.onShow = onShow
	self.offHide = offHide
	self.offShow = offShow
	self.x = x
	self.y = y
	self.energy = energy
	self:off()
	return self
end

-- Set to on
function PowerNode:on()
	if (self.onShow) then
		api.toggleActivator(self.onShow)
		api.toggleActivator(self.offHide)
	end
end

-- Set to off
function PowerNode:off()
	if (self.onShow) then
		api.toggleActivator(self.onHide)
		api.toggleActivator(self.offShow)
	end
end

PowerDisplay = {}
PowerDisplay.__index = PowerDisplay

--[[
	PowerDisplay Constructor

	Parameters:
		elementDigitTen (element) - Ten's display digit
		elementDigitOne (element) - One's display digit
		value (num) - Number to display
]]
function PowerDisplay.new(elementDigitTen, elementDigitOne, value)
	local self = setmetatable({}, PowerDisplay)
	self.elementDigitTen = elementDigitTen
	self.elementDigitOne = elementDigitOne
	self:setValue(value)
	return self
end

function PowerDisplay:setValue(value)
	self.value = value
	local digitTen = math.floor(self.value / 10) % 10

	api.setLockValue(self.elementDigitTen, digitTen, 1)
	api.setLockValue(self.elementDigitOne, self.value % 10, 1)
end

PowerDisplaySplit = {}
PowerDisplaySplit.__index = PowerDisplaySplit

--[[
	PowerDisplaySplit Constructor

	Parameters:
		powerDisplayTop (PowerDisplay) - Top number display
		powerDisplayBottom (PowerDisplay) - Bottom number display
		powerDisplaySlash (lock)
		buttonHide (element) - Activator that hides button
		buttonShow (element) - Activator that shows button
		energyRequired (num) - Required energy to activate
]]
function PowerDisplaySplit.new(powerDisplayTop, powerDisplayBottom, powerDisplaySlash, buttonHide, buttonShow, energyRequired)
	local self = setmetatable({}, PowerDisplaySplit)
	self.powerDisplayTop = powerDisplayTop
	self.powerDisplayBottom = powerDisplayBottom
	self.buttonHide = buttonHide
	self.buttonShow = buttonShow
	self.energyRequired = energyRequired

	api.setLockValue(powerDisplaySlash, 1, 1) -- A 1 pretending to be a slash
	self.powerDisplayBottom:setValue(self.energyRequired) -- Set bottom display to required value
	self:setValue(0)
	
	return self
end

function PowerDisplaySplit:setValue(value)
	self.powerDisplayTop:setValue(value)

	if value < self.energyRequired then
		api.toggleActivator(self.buttonHide)
	else
		api.toggleActivator(self.buttonShow)
	end
end

-- Functions

-- Utility function to check if a table contains a value
function table.contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Update state of power grid upon change
function powerUpdate()
	powerEnergy = 1

	-- Initialize table of values
	--[[
		0 - empty
		1 - occupied
		2 - linked
	]]
	for i = 1, powerRows do
		powerCells[i] = {}
		for j = 1, powerColumns do
			powerCells[i][j] = 0
		end
	end

	-- Initialize nodes
	for _, powerNode in ipairs(powerNodes) do
		powerNode:off()
		powerCells[powerNode.x][powerNode.y] = 1
	end

	-- Initialize connectors
	api.toggleActivator(zesty_connector_1_off_show)
	api.toggleActivator(zesty_connector_2_off_show)
	api.toggleActivator(zesty_connector_3_off_show)
	api.toggleActivator(zesty_connector_4_off_show)
	api.toggleActivator(zesty_connector_5_off_show)
	api.toggleActivator(zesty_connector_1_on_hide)
	api.toggleActivator(zesty_connector_2_on_hide)
	api.toggleActivator(zesty_connector_3_on_hide)
	api.toggleActivator(zesty_connector_4_on_hide)
	api.toggleActivator(zesty_connector_5_on_hide)

	-- Check which slots are occupied and which cells they cover
	for _, powerSlot in ipairs(powerSlots) do

		powerSlot:enable() -- Reset to default state

		if powerSlot:isFilled() then
			for _, cell in ipairs(powerSlot.cells) do
				local x = cell[1]
				local y = cell[2]
				powerCells[x][y] = 1
			end
		end
	end

	--- Starting point
	powerCells[powerNodeInit.x][powerNodeInit.y] = 2

	-- Check which cells are linked to energy source
	local changedCells
	repeat
		changedCells = false
		for i = 1, powerRows do
			for j = 1, powerColumns do
				if powerCells[i][j] == 1 then
					-- Check adjacent cells
					if (i > 1 and powerCells[i - 1][j] == 2)
					or (i < powerRows and powerCells[i + 1][j] == 2)
					or (j > 1 and powerCells[i][j - 1] == 2)
					or (j < powerColumns and powerCells[i][j + 1] == 2) then
						powerCells[i][j] = 2
						changedCells = true
					end
				end
			end
		end
	until not changedCells -- Keep checking until no more changes are made

	for _, powerNode in ipairs(powerNodes) do
		if powerCells[powerNode.x][powerNode.y] == 2 then
			powerNode:on()
			powerEnergy = powerEnergy + powerNode.energy
		end
	end

	for _, powerSlot in ipairs(powerSlots) do

		local highestCellValue = -1
		for _, cell in ipairs(powerSlot.cells) do
			local x = cell[1]
			local y = cell[2]
			if powerCells[x][y] > highestCellValue then
				highestCellValue = powerCells[x][y]
			end
		end

		if powerSlot:isFilled() then
			if highestCellValue == 2 then
				-- "Activate" slotted connector

				if powerSlot.element.insertedKey == zesty_connector_1.transform.gameObject then
					api.toggleActivator(zesty_connector_1_off_hide)
					api.toggleActivator(zesty_connector_1_on_show)
				elseif powerSlot.element.insertedKey == zesty_connector_2.transform.gameObject then
					api.toggleActivator(zesty_connector_2_off_hide)
					api.toggleActivator(zesty_connector_2_on_show)
				elseif powerSlot.element.insertedKey == zesty_connector_3.transform.gameObject then
					api.toggleActivator(zesty_connector_3_off_hide)
					api.toggleActivator(zesty_connector_3_on_show)
				elseif powerSlot.element.insertedKey == zesty_connector_4.transform.gameObject then
					api.toggleActivator(zesty_connector_4_off_hide)
					api.toggleActivator(zesty_connector_4_on_show)
				elseif powerSlot.element.insertedKey == zesty_connector_5.transform.gameObject then
					api.toggleActivator(zesty_connector_5_off_hide)
					api.toggleActivator(zesty_connector_5_on_show)
				end
			end
		elseif highestCellValue > 0 then
			-- Disable slot if empty and obscured by some other slotted connector
			powerSlot:disable()
		end
	end

	powerDisplay0:setValue(powerEnergy)
	powerDisplaySplit1:setValue(powerEnergy)
	powerDisplaySplit3:setValue(powerEnergy)

	-- debug
	-- powerDisplay()
end

-- Print power grid values (debug)
function powerDisplay()
	--[[
	for j = 1, #powerCells do
		local line = ""
		for i = 1, #powerCells[j] do
			line = line .. powerCells[i][j] .. "\t"
		end
		api.log(line)
	end
	]]
	api.log("Total energy: " .. powerEnergy)
end

if callType == LuaCallType.Unlock then
	if context == zesty_init then

		
		-- Globals
		powerRows = 8
		powerColumns = 8
		powerCells = {}
		powerEnergy = 0
	
		-- Set up power displays
		powerDisplaySplit1 = PowerDisplaySplit.new(
			PowerDisplay.new(zesty_digit_1a_10, zesty_digit_1a_1, powerEnergy),
			PowerDisplay.new(zesty_digit_1b_10, zesty_digit_1b_1, powerEnergy),
			zesty_digit_1_slash,
			zesty_display1_activate_hide,
			zesty_display1_activate_show,
			11
		)
	
		powerDisplaySplit3 = PowerDisplaySplit.new(
			PowerDisplay.new(zesty_digit_3a_10, zesty_digit_3a_1, powerEnergy),
			PowerDisplay.new(zesty_digit_3b_10, zesty_digit_3b_1, powerEnergy),
			zesty_digit_3_slash,
			zesty_display3_activate_hide,
			zesty_display3_activate_show,
			20
		)
	
		powerDisplay0 = PowerDisplay.new(zesty_digit_0_10, zesty_digit_0_1, powerEnergy)
	
		-- The first power node that is always on
		powerNodeInit = PowerNode.new(nil, nil, nil, nil, 4, 5, 1)
		powerNodeInit:on()
	
		powerNodes = {
			PowerNode.new(zesty_powernode_2_on_hide, zesty_powernode_2_on_show, zesty_powernode_2_off_hide, zesty_powernode_2_off_show, 1, 1, 1),
			PowerNode.new(zesty_powernode_3_on_hide, zesty_powernode_3_on_show, zesty_powernode_3_off_hide, zesty_powernode_3_off_show, 3, 1, 3),
			PowerNode.new(zesty_powernode_4_on_hide, zesty_powernode_4_on_show, zesty_powernode_4_off_hide, zesty_powernode_4_off_show, 8, 1, 4),
			PowerNode.new(zesty_powernode_5_on_hide, zesty_powernode_5_on_show, zesty_powernode_5_off_hide, zesty_powernode_5_off_show, 7, 2, 1),
			PowerNode.new(zesty_powernode_6_on_hide, zesty_powernode_6_on_show, zesty_powernode_6_off_hide, zesty_powernode_6_off_show, 3, 4, 3),
			PowerNode.new(zesty_powernode_7_on_hide, zesty_powernode_7_on_show, zesty_powernode_7_off_hide, zesty_powernode_7_off_show, 7, 4, 1),
			PowerNode.new(zesty_powernode_8_on_hide, zesty_powernode_8_on_show, zesty_powernode_8_off_hide, zesty_powernode_8_off_show, 2, 6, 2),
			PowerNode.new(zesty_powernode_9_on_hide, zesty_powernode_9_on_show, zesty_powernode_9_off_hide, zesty_powernode_9_off_show, 6, 7, 2),
			PowerNode.new(zesty_powernode_10_on_hide, zesty_powernode_10_on_show, zesty_powernode_10_off_hide, zesty_powernode_10_off_show, 1, 8, 1),
			PowerNode.new(zesty_powernode_11_on_hide, zesty_powernode_11_on_show, zesty_powernode_11_off_hide, zesty_powernode_11_off_show, 8, 8, 1)
		}
	
		powerSlots = {
			PowerSlot.new(zesty_powerslot_h11, 1, 1, true, zesty_powerslot_h11_hide, zesty_powerslot_h11_show),
			PowerSlot.new(zesty_powerslot_h12, 2, 1, true, zesty_powerslot_h12_hide, zesty_powerslot_h12_show),
			PowerSlot.new(zesty_powerslot_h13, 3, 1, true, zesty_powerslot_h13_hide, zesty_powerslot_h13_show),
			PowerSlot.new(zesty_powerslot_h14, 4, 1, true, zesty_powerslot_h14_hide, zesty_powerslot_h14_show),
			PowerSlot.new(zesty_powerslot_h15, 5, 1, true, zesty_powerslot_h15_hide, zesty_powerslot_h15_show),
			PowerSlot.new(zesty_powerslot_h21, 1, 2, true, zesty_powerslot_h21_hide, zesty_powerslot_h21_show),
			PowerSlot.new(zesty_powerslot_h22, 2, 2, true, zesty_powerslot_h22_hide, zesty_powerslot_h22_show),
			PowerSlot.new(zesty_powerslot_h23, 3, 2, true, zesty_powerslot_h23_hide, zesty_powerslot_h23_show),
			PowerSlot.new(zesty_powerslot_h24, 4, 2, true, zesty_powerslot_h24_hide, zesty_powerslot_h24_show),
			PowerSlot.new(zesty_powerslot_h25, 5, 2, true, zesty_powerslot_h25_hide, zesty_powerslot_h25_show),
			PowerSlot.new(zesty_powerslot_h31, 1, 3, true, zesty_powerslot_h31_hide, zesty_powerslot_h31_show),
			PowerSlot.new(zesty_powerslot_h32, 2, 3, true, zesty_powerslot_h32_hide, zesty_powerslot_h32_show),
			PowerSlot.new(zesty_powerslot_h33, 3, 3, true, zesty_powerslot_h33_hide, zesty_powerslot_h33_show),
			PowerSlot.new(zesty_powerslot_h34, 4, 3, true, zesty_powerslot_h34_hide, zesty_powerslot_h34_show),
			PowerSlot.new(zesty_powerslot_h35, 5, 3, true, zesty_powerslot_h35_hide, zesty_powerslot_h35_show),
			PowerSlot.new(zesty_powerslot_h41, 1, 4, true, zesty_powerslot_h41_hide, zesty_powerslot_h41_show),
			PowerSlot.new(zesty_powerslot_h42, 2, 4, true, zesty_powerslot_h42_hide, zesty_powerslot_h42_show),
			PowerSlot.new(zesty_powerslot_h43, 3, 4, true, zesty_powerslot_h43_hide, zesty_powerslot_h43_show),
			PowerSlot.new(zesty_powerslot_h44, 4, 4, true, zesty_powerslot_h44_hide, zesty_powerslot_h44_show),
			PowerSlot.new(zesty_powerslot_h45, 5, 4, true, zesty_powerslot_h45_hide, zesty_powerslot_h45_show),
			PowerSlot.new(zesty_powerslot_h51, 1, 5, true, zesty_powerslot_h51_hide, zesty_powerslot_h51_show),
			PowerSlot.new(zesty_powerslot_h52, 2, 5, true, zesty_powerslot_h52_hide, zesty_powerslot_h52_show),
			PowerSlot.new(zesty_powerslot_h53, 3, 5, true, zesty_powerslot_h53_hide, zesty_powerslot_h53_show),
			PowerSlot.new(zesty_powerslot_h54, 4, 5, true, zesty_powerslot_h54_hide, zesty_powerslot_h54_show),
			PowerSlot.new(zesty_powerslot_h55, 5, 5, true, zesty_powerslot_h55_hide, zesty_powerslot_h55_show),
			PowerSlot.new(zesty_powerslot_h61, 1, 6, true, zesty_powerslot_h61_hide, zesty_powerslot_h61_show),
			PowerSlot.new(zesty_powerslot_h62, 2, 6, true, zesty_powerslot_h62_hide, zesty_powerslot_h62_show),
			PowerSlot.new(zesty_powerslot_h63, 3, 6, true, zesty_powerslot_h63_hide, zesty_powerslot_h63_show),
			PowerSlot.new(zesty_powerslot_h64, 4, 6, true, zesty_powerslot_h64_hide, zesty_powerslot_h64_show),
			PowerSlot.new(zesty_powerslot_h65, 5, 6, true, zesty_powerslot_h65_hide, zesty_powerslot_h65_show),
			PowerSlot.new(zesty_powerslot_h71, 1, 7, true, zesty_powerslot_h71_hide, zesty_powerslot_h71_show),
			PowerSlot.new(zesty_powerslot_h72, 2, 7, true, zesty_powerslot_h72_hide, zesty_powerslot_h72_show),
			PowerSlot.new(zesty_powerslot_h73, 3, 7, true, zesty_powerslot_h73_hide, zesty_powerslot_h73_show),
			PowerSlot.new(zesty_powerslot_h74, 4, 7, true, zesty_powerslot_h74_hide, zesty_powerslot_h74_show),
			PowerSlot.new(zesty_powerslot_h75, 5, 7, true, zesty_powerslot_h75_hide, zesty_powerslot_h75_show),
			PowerSlot.new(zesty_powerslot_h81, 1, 8, true, zesty_powerslot_h81_hide, zesty_powerslot_h81_show),
			PowerSlot.new(zesty_powerslot_h82, 2, 8, true, zesty_powerslot_h82_hide, zesty_powerslot_h82_show),
			PowerSlot.new(zesty_powerslot_h83, 3, 8, true, zesty_powerslot_h83_hide, zesty_powerslot_h83_show),
			PowerSlot.new(zesty_powerslot_h84, 4, 8, true, zesty_powerslot_h84_hide, zesty_powerslot_h84_show),
			PowerSlot.new(zesty_powerslot_h85, 5, 8, true, zesty_powerslot_h85_hide, zesty_powerslot_h85_show),
			PowerSlot.new(zesty_powerslot_v11, 1, 1, false, zesty_powerslot_v11_hide, zesty_powerslot_v11_show),
			PowerSlot.new(zesty_powerslot_v12, 2, 1, false, zesty_powerslot_v12_hide, zesty_powerslot_v12_show),
			PowerSlot.new(zesty_powerslot_v13, 3, 1, false, zesty_powerslot_v13_hide, zesty_powerslot_v13_show),
			PowerSlot.new(zesty_powerslot_v14, 4, 1, false, zesty_powerslot_v14_hide, zesty_powerslot_v14_show),
			PowerSlot.new(zesty_powerslot_v15, 5, 1, false, zesty_powerslot_v15_hide, zesty_powerslot_v15_show),
			PowerSlot.new(zesty_powerslot_v16, 6, 1, false, zesty_powerslot_v16_hide, zesty_powerslot_v16_show),
			PowerSlot.new(zesty_powerslot_v17, 7, 1, false, zesty_powerslot_v17_hide, zesty_powerslot_v17_show),
			PowerSlot.new(zesty_powerslot_v18, 8, 1, false, zesty_powerslot_v18_hide, zesty_powerslot_v18_show),
			PowerSlot.new(zesty_powerslot_v21, 1, 2, false, zesty_powerslot_v21_hide, zesty_powerslot_v21_show),
			PowerSlot.new(zesty_powerslot_v22, 2, 2, false, zesty_powerslot_v22_hide, zesty_powerslot_v22_show),
			PowerSlot.new(zesty_powerslot_v23, 3, 2, false, zesty_powerslot_v23_hide, zesty_powerslot_v23_show),
			PowerSlot.new(zesty_powerslot_v24, 4, 2, false, zesty_powerslot_v24_hide, zesty_powerslot_v24_show),
			PowerSlot.new(zesty_powerslot_v25, 5, 2, false, zesty_powerslot_v25_hide, zesty_powerslot_v25_show),
			PowerSlot.new(zesty_powerslot_v26, 6, 2, false, zesty_powerslot_v26_hide, zesty_powerslot_v26_show),
			PowerSlot.new(zesty_powerslot_v27, 7, 2, false, zesty_powerslot_v27_hide, zesty_powerslot_v27_show),
			PowerSlot.new(zesty_powerslot_v28, 8, 2, false, zesty_powerslot_v28_hide, zesty_powerslot_v28_show),
			PowerSlot.new(zesty_powerslot_v31, 1, 3, false, zesty_powerslot_v31_hide, zesty_powerslot_v31_show),
			PowerSlot.new(zesty_powerslot_v32, 2, 3, false, zesty_powerslot_v32_hide, zesty_powerslot_v32_show),
			PowerSlot.new(zesty_powerslot_v33, 3, 3, false, zesty_powerslot_v33_hide, zesty_powerslot_v33_show),
			PowerSlot.new(zesty_powerslot_v34, 4, 3, false, zesty_powerslot_v34_hide, zesty_powerslot_v34_show),
			PowerSlot.new(zesty_powerslot_v35, 5, 3, false, zesty_powerslot_v35_hide, zesty_powerslot_v35_show),
			PowerSlot.new(zesty_powerslot_v36, 6, 3, false, zesty_powerslot_v36_hide, zesty_powerslot_v36_show),
			PowerSlot.new(zesty_powerslot_v37, 7, 3, false, zesty_powerslot_v37_hide, zesty_powerslot_v37_show),
			PowerSlot.new(zesty_powerslot_v38, 8, 3, false, zesty_powerslot_v38_hide, zesty_powerslot_v38_show),
			PowerSlot.new(zesty_powerslot_v41, 1, 4, false, zesty_powerslot_v41_hide, zesty_powerslot_v41_show),
			PowerSlot.new(zesty_powerslot_v42, 2, 4, false, zesty_powerslot_v42_hide, zesty_powerslot_v42_show),
			PowerSlot.new(zesty_powerslot_v43, 3, 4, false, zesty_powerslot_v43_hide, zesty_powerslot_v43_show),
			PowerSlot.new(zesty_powerslot_v44, 4, 4, false, zesty_powerslot_v44_hide, zesty_powerslot_v44_show),
			PowerSlot.new(zesty_powerslot_v45, 5, 4, false, zesty_powerslot_v45_hide, zesty_powerslot_v45_show),
			PowerSlot.new(zesty_powerslot_v46, 6, 4, false, zesty_powerslot_v46_hide, zesty_powerslot_v46_show),
			PowerSlot.new(zesty_powerslot_v47, 7, 4, false, zesty_powerslot_v47_hide, zesty_powerslot_v47_show),
			PowerSlot.new(zesty_powerslot_v48, 8, 4, false, zesty_powerslot_v48_hide, zesty_powerslot_v48_show),
			PowerSlot.new(zesty_powerslot_v51, 1, 5, false, zesty_powerslot_v51_hide, zesty_powerslot_v51_show),
			PowerSlot.new(zesty_powerslot_v52, 2, 5, false, zesty_powerslot_v52_hide, zesty_powerslot_v52_show),
			PowerSlot.new(zesty_powerslot_v53, 3, 5, false, zesty_powerslot_v53_hide, zesty_powerslot_v53_show),
			PowerSlot.new(zesty_powerslot_v54, 4, 5, false, zesty_powerslot_v54_hide, zesty_powerslot_v54_show),
			PowerSlot.new(zesty_powerslot_v55, 5, 5, false, zesty_powerslot_v55_hide, zesty_powerslot_v55_show),
			PowerSlot.new(zesty_powerslot_v56, 6, 5, false, zesty_powerslot_v56_hide, zesty_powerslot_v56_show),
			PowerSlot.new(zesty_powerslot_v57, 7, 5, false, zesty_powerslot_v57_hide, zesty_powerslot_v57_show),
			PowerSlot.new(zesty_powerslot_v58, 8, 5, false, zesty_powerslot_v58_hide, zesty_powerslot_v58_show)
		}
	
		powerUpdate()
	elseif context == zesty_powerslot_remove then
		api.setLockValue(zesty_sfx_connectoroff, 1, 1)
		powerUpdate()
	end
elseif callType == LuaCallType.Slot then
	if powerSlots ~= nil then
		for _, powerSlot in ipairs(powerSlots) do
			if context == powerSlot.element then
				api.setLockValue(zesty_sfx_connectoron, 1, 1)
				powerUpdate()
			end
		end
	end
end
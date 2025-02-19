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
]]
function PowerSlot.new(element, x, y, horizontal)
	local self = setmetatable({}, PowerSlot)
	self.element = element
	self.x = x
	self.y = y
	self.horizontal = horizontal
	
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
	activate({self.element}, true, false, false, true)
end

-- Disable slot's collider
function PowerSlot:disable()
	activate({self.element}, false, false, false, true)
end

PowerNode = {}
PowerNode.__index = PowerNode

--[[
	PowerNode Constructor

	Parameters:
		elementOn (element) - "On" element.
		elementOff (element) - "Off" element.
		x (num) - Origin x position on grid.
		y (num) - Origin y position on grid.
		energy (num) - How much energy this node provides when on.
]]
function PowerNode.new(elementOn, elementOff, x, y, energy)
	local self = setmetatable({}, PowerNode)
	self.elementOn = elementOn
	self.elementOff = elementOff
	self.x = x
	self.y = y
	self.energy = energy
	self:off()
	return self
end

-- Set to on
function PowerNode:on()
	activate({self.elementOn}, true, true)
	activate({self.elementOff}, false, true)
end

-- Set to off
function PowerNode:off()
	activate({self.elementOn}, false, true)
	activate({self.elementOff}, true, true)
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

	-- Hide ten's digit if value < 10
	activate({self.elementDigitTen}, (digitTen > 0), false, true, false)
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
		button (element) - Activate button that appears when
		energyRequired (num) - required energy to activate
]]
function PowerDisplaySplit.new(powerDisplayTop, powerDisplayBottom, powerDisplaySlash, button, energyRequired)
	local self = setmetatable({}, PowerDisplaySplit)
	self.powerDisplayTop = powerDisplayTop
	self.powerDisplayBottom = powerDisplayBottom
	self.button = button
	self.energyRequired = energyRequired

	api.setLockValue(powerDisplaySlash, 1, 1) -- A 1 pretending to be a slash
	self.powerDisplayBottom:setValue(self.energyRequired) -- Set bottom display to required value
	self:setValue(0)
	
	return self
end

function PowerDisplaySplit:setValue(value)
	self.powerDisplayTop:setValue(value)

	if value < self.energyRequired then
		activate({self.button}, false, true)
	else
		activate({self.button}, true, true)
	end
end

-- Functions

--[[
	Custom activator to programatically use.
	Works by setting the activator's attributes on-demand and then enacting it.
	Requires a spare visibility activator to be present in the room.

	Parameters:
		targets (element[]) - Array of element names.
			Ex: { target1, target2 }
		enable (bool) - Whether to enable or disable.
		targetObject (bool) - Whether to target whole object.
		targetRenderer (bool) - Whether to target object renderer.
		targetCollider (bool) - Whether to target object collider.
]]
function activate(targets, enable, targetObject, targetRenderer, targetCollider)
	if enable then
		zesty_activator.type = (enable and zesty_activator.ActivatorType.enable) or zesty_activator.ActivatorType.disable
	else
		zesty_activator.type = zesty_activator.ActivatorType.disable
	end

	zesty_activator.targetObject = targetObject or true
	zesty_activator.targetRenderer = targetRenderer or false
	zesty_activator.targetCollider = targetCollider or false

	-- Convert list of targets to game objects
	local gameObjects = {}
	for i, obj in ipairs(targets) do
		gameObjects[i] = obj.gameObject
	end
	zesty_activator.keys = gameObjects

	api.toggleActivator(zesty_activator)
end

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
	activate({
		zesty_connector_1_on,
		zesty_connector_2_on,
		zesty_connector_3_on,
		zesty_connector_4_on,
		zesty_connector_5_on
	}, false, true)
	activate({
		zesty_connector_1_off,
		zesty_connector_2_off,
		zesty_connector_3_off,
		zesty_connector_4_off,
		zesty_connector_5_off
	}, true, true)

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

				-- Ideally the connectors are tables/classes, but it works for now
				if powerSlot.element.insertedKey == zesty_connector_1.transform.gameObject then
					activate({zesty_connector_1_off}, false, true)
					activate({zesty_connector_1_on}, true, true)
				elseif powerSlot.element.insertedKey == zesty_connector_2.transform.gameObject then
					activate({zesty_connector_2_off}, false, true)
					activate({zesty_connector_2_on}, true, true)
				elseif powerSlot.element.insertedKey == zesty_connector_3.transform.gameObject then
					activate({zesty_connector_3_off}, false, true)
					activate({zesty_connector_3_on}, true, true)
				elseif powerSlot.element.insertedKey == zesty_connector_4.transform.gameObject then
					activate({zesty_connector_4_off}, false, true)
					activate({zesty_connector_4_on}, true, true)
				elseif powerSlot.element.insertedKey == zesty_connector_5.transform.gameObject then
					activate({zesty_connector_5_off}, false, true)
					activate({zesty_connector_5_on}, true, true)
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
			zesty_digit_1_button,
			11
		)
	
		powerDisplaySplit3 = PowerDisplaySplit.new(
			PowerDisplay.new(zesty_digit_3a_10, zesty_digit_3a_1, powerEnergy),
			PowerDisplay.new(zesty_digit_3b_10, zesty_digit_3b_1, powerEnergy),
			zesty_digit_3_slash,
			zesty_digit_3_button,
			20
		)
	
		powerDisplay0 = PowerDisplay.new(zesty_digit_0_10, zesty_digit_0_1, powerEnergy)
	
		-- The first power node that is always on
		powerNodeInit = PowerNode.new(zesty_powernode_1_on, zesty_powernode_1_off, 4, 5, 1)
		powerNodeInit:on()
	
		powerNodes = {
			PowerNode.new(zesty_powernode_2_on, zesty_powernode_2_off, 1, 1, 1),
			PowerNode.new(zesty_powernode_3_on, zesty_powernode_3_off, 3, 1, 3),
			PowerNode.new(zesty_powernode_4_on, zesty_powernode_4_off, 8, 1, 4),
			PowerNode.new(zesty_powernode_5_on, zesty_powernode_5_off, 7, 2, 1),
			PowerNode.new(zesty_powernode_6_on, zesty_powernode_6_off, 3, 4, 3),
			PowerNode.new(zesty_powernode_7_on, zesty_powernode_7_off, 7, 4, 1),
			PowerNode.new(zesty_powernode_8_on, zesty_powernode_8_off, 2, 6, 2),
			PowerNode.new(zesty_powernode_9_on, zesty_powernode_9_off, 6, 7, 2),
			PowerNode.new(zesty_powernode_10_on, zesty_powernode_10_off, 1, 8, 1),
			PowerNode.new(zesty_powernode_11_on, zesty_powernode_11_off, 8, 8, 1)
		}
	
		powerSlots = {
			PowerSlot.new(zesty_powerslot_h11, 1, 1, true),
			PowerSlot.new(zesty_powerslot_h12, 2, 1, true),
			PowerSlot.new(zesty_powerslot_h13, 3, 1, true),
			PowerSlot.new(zesty_powerslot_h14, 4, 1, true),
			PowerSlot.new(zesty_powerslot_h15, 5, 1, true),
			PowerSlot.new(zesty_powerslot_h21, 1, 2, true),
			PowerSlot.new(zesty_powerslot_h22, 2, 2, true),
			PowerSlot.new(zesty_powerslot_h23, 3, 2, true),
			PowerSlot.new(zesty_powerslot_h24, 4, 2, true),
			PowerSlot.new(zesty_powerslot_h25, 5, 2, true),
			PowerSlot.new(zesty_powerslot_h31, 1, 3, true),
			PowerSlot.new(zesty_powerslot_h32, 2, 3, true),
			PowerSlot.new(zesty_powerslot_h33, 3, 3, true),
			PowerSlot.new(zesty_powerslot_h34, 4, 3, true),
			PowerSlot.new(zesty_powerslot_h35, 5, 3, true),
			PowerSlot.new(zesty_powerslot_h41, 1, 4, true),
			PowerSlot.new(zesty_powerslot_h42, 2, 4, true),
			PowerSlot.new(zesty_powerslot_h43, 3, 4, true),
			PowerSlot.new(zesty_powerslot_h44, 4, 4, true),
			PowerSlot.new(zesty_powerslot_h45, 5, 4, true),
			PowerSlot.new(zesty_powerslot_h51, 1, 5, true),
			PowerSlot.new(zesty_powerslot_h52, 2, 5, true),
			PowerSlot.new(zesty_powerslot_h53, 3, 5, true),
			PowerSlot.new(zesty_powerslot_h54, 4, 5, true),
			PowerSlot.new(zesty_powerslot_h55, 5, 5, true),
			PowerSlot.new(zesty_powerslot_h61, 1, 6, true),
			PowerSlot.new(zesty_powerslot_h62, 2, 6, true),
			PowerSlot.new(zesty_powerslot_h63, 3, 6, true),
			PowerSlot.new(zesty_powerslot_h64, 4, 6, true),
			PowerSlot.new(zesty_powerslot_h65, 5, 6, true),
			PowerSlot.new(zesty_powerslot_h71, 1, 7, true),
			PowerSlot.new(zesty_powerslot_h72, 2, 7, true),
			PowerSlot.new(zesty_powerslot_h73, 3, 7, true),
			PowerSlot.new(zesty_powerslot_h74, 4, 7, true),
			PowerSlot.new(zesty_powerslot_h75, 5, 7, true),
			PowerSlot.new(zesty_powerslot_h81, 1, 8, true),
			PowerSlot.new(zesty_powerslot_h82, 2, 8, true),
			PowerSlot.new(zesty_powerslot_h83, 3, 8, true),
			PowerSlot.new(zesty_powerslot_h84, 4, 8, true),
			PowerSlot.new(zesty_powerslot_h85, 5, 8, true),
			PowerSlot.new(zesty_powerslot_v11, 1, 1, false),
			PowerSlot.new(zesty_powerslot_v12, 2, 1, false),
			PowerSlot.new(zesty_powerslot_v13, 3, 1, false),
			PowerSlot.new(zesty_powerslot_v14, 4, 1, false),
			PowerSlot.new(zesty_powerslot_v15, 5, 1, false),
			PowerSlot.new(zesty_powerslot_v16, 6, 1, false),
			PowerSlot.new(zesty_powerslot_v17, 7, 1, false),
			PowerSlot.new(zesty_powerslot_v18, 8, 1, false),
			PowerSlot.new(zesty_powerslot_v21, 1, 2, false),
			PowerSlot.new(zesty_powerslot_v22, 2, 2, false),
			PowerSlot.new(zesty_powerslot_v23, 3, 2, false),
			PowerSlot.new(zesty_powerslot_v24, 4, 2, false),
			PowerSlot.new(zesty_powerslot_v25, 5, 2, false),
			PowerSlot.new(zesty_powerslot_v26, 6, 2, false),
			PowerSlot.new(zesty_powerslot_v27, 7, 2, false),
			PowerSlot.new(zesty_powerslot_v28, 8, 2, false),
			PowerSlot.new(zesty_powerslot_v31, 1, 3, false),
			PowerSlot.new(zesty_powerslot_v32, 2, 3, false),
			PowerSlot.new(zesty_powerslot_v33, 3, 3, false),
			PowerSlot.new(zesty_powerslot_v34, 4, 3, false),
			PowerSlot.new(zesty_powerslot_v35, 5, 3, false),
			PowerSlot.new(zesty_powerslot_v36, 6, 3, false),
			PowerSlot.new(zesty_powerslot_v37, 7, 3, false),
			PowerSlot.new(zesty_powerslot_v38, 8, 3, false),
			PowerSlot.new(zesty_powerslot_v41, 1, 4, false),
			PowerSlot.new(zesty_powerslot_v42, 2, 4, false),
			PowerSlot.new(zesty_powerslot_v43, 3, 4, false),
			PowerSlot.new(zesty_powerslot_v44, 4, 4, false),
			PowerSlot.new(zesty_powerslot_v45, 5, 4, false),
			PowerSlot.new(zesty_powerslot_v46, 6, 4, false),
			PowerSlot.new(zesty_powerslot_v47, 7, 4, false),
			PowerSlot.new(zesty_powerslot_v48, 8, 4, false),
			PowerSlot.new(zesty_powerslot_v51, 1, 5, false),
			PowerSlot.new(zesty_powerslot_v52, 2, 5, false),
			PowerSlot.new(zesty_powerslot_v53, 3, 5, false),
			PowerSlot.new(zesty_powerslot_v54, 4, 5, false),
			PowerSlot.new(zesty_powerslot_v55, 5, 5, false),
			PowerSlot.new(zesty_powerslot_v56, 6, 5, false),
			PowerSlot.new(zesty_powerslot_v57, 7, 5, false),
			PowerSlot.new(zesty_powerslot_v58, 8, 5, false)
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
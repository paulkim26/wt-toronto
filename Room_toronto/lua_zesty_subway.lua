-- Classes
LetterSlider = {}
LetterSlider.__index = LetterSlider

--[[
	LetterSlider Constructor

	Parameters:
		slider (element)
		defaultValue (num) - Initial default index (should match what's set on slider)
		digits - Table of display digits & their offsets
			{
				displayElement,
				indexOffset - how much offset to the index (i.e. +2 will turn A to C)
			}
]]
function LetterSlider.new(slider, defaultValue, digits, answerValue)
	local self = setmetatable({}, LetterSlider)
	self.slider = slider
	self.value = defaultValue
	self.digits = digits
	self.answerValue = answerValue

	-- Initialize all displays
	for _, digit in ipairs(self.digits) do
		local display = digit[1]
		api.setLockValue(display, 23, 1)
	end

	return self
end

--[[
	Set new state value for slider. To be called whenever slider is moved.

	Parameters:
		value (num) - Number to change to

	Returns whether the value that it was changed to is different from the current one.
]]
function LetterSlider:setValue(value)
	if value != self.value then
		self.value = value

		-- Only change display if still playing
		if winner == 0 then
			for _, digit in ipairs(self.digits) do
				local display = digit[1]
				local indexOffset = digit[2]

				local index = (self.value + indexOffset) % sliderSegments
				api.setLockValue(display, index, 1)
			end
		end

		return true
	end

	return false
end

-- Return whether slider is set to correct position
function LetterSlider:check()
	return (self.value == self.answerValue)
end

-- Functions

function round(num)
    return math.floor(num + 0.5)
end

function checkSliders()
	local correct = true
	for _, slider in ipairs(letterSliders) do
		if not slider:check() then
			correct = false
		end
	end
	
	if correct then
		startWinner()
	end
end

 -- Start "WINER" animation
function startWinner()
	if winner == 0 then
		api.setLockValue(zesty_trophydoor, 1, 1)
		api.setLockValue(zesty_winner_exitzoom, 1, 1)
		api.activateSwitch(zesty_winner_anim)
		winner = 1
	end
end

-- Toggle between "winner" animation states
function displayWinner()
	if winner == 1 then
		api.setLockValue(sfx_zesty_winner, 1, 1)
		winner = 2
	end
	
	if winner == 2 then
		winner = 3		
		api.setLockValue(zesty_subway_digit11, 28, 1)
		api.setLockValue(zesty_subway_digit12, 29, 1)
		api.setLockValue(zesty_subway_digit13, 30, 1)
		api.setLockValue(zesty_subway_digit14, 31, 1)
		api.setLockValue(zesty_subway_digit15, 32, 1)
		
		api.setLockValue(zesty_subway_digit21, 28, 1)
		api.setLockValue(zesty_subway_digit22, 29, 1)
		api.setLockValue(zesty_subway_digit23, 30, 1)
		api.setLockValue(zesty_subway_digit24, 31, 1)
		api.setLockValue(zesty_subway_digit25, 32, 1)
		
		api.setLockValue(zesty_subway_digit31, 28, 1)
		api.setLockValue(zesty_subway_digit32, 29, 1)
		api.setLockValue(zesty_subway_digit33, 30, 1)
		api.setLockValue(zesty_subway_digit34, 31, 1)
		api.setLockValue(zesty_subway_digit35, 32, 1)
	else
		winner = 2
		api.setLockValue(zesty_subway_digit11, 22, 1)
		api.setLockValue(zesty_subway_digit12, 8, 1)
		api.setLockValue(zesty_subway_digit13, 13, 1)
		api.setLockValue(zesty_subway_digit14, 4, 1)
		api.setLockValue(zesty_subway_digit15, 17, 1)

		api.setLockValue(zesty_subway_digit21, 22, 1)
		api.setLockValue(zesty_subway_digit22, 8, 1)
		api.setLockValue(zesty_subway_digit23, 13, 1)
		api.setLockValue(zesty_subway_digit24, 4, 1)
		api.setLockValue(zesty_subway_digit25, 17, 1)

		api.setLockValue(zesty_subway_digit31, 22, 1)
		api.setLockValue(zesty_subway_digit32, 8, 1)
		api.setLockValue(zesty_subway_digit33, 13, 1)
		api.setLockValue(zesty_subway_digit34, 4, 1)
		api.setLockValue(zesty_subway_digit35, 17, 1)
	end
end

if callType == LuaCallType.Init then
	winner = 0
	sliderSegments = 26
	-- # of unique sliderSegments on slider
	-- Should be 26 (1 for each letter)

	letterSliders = {
		LetterSlider.new(zesty_letterslider1, 0, {
			{zesty_subway_digit12, 0}, --O
			{zesty_subway_digit24, 0}, --O
			{zesty_subway_digit31, 2}, --Q
			{zesty_subway_digit14, -8}, --G
		}, 14),
		LetterSlider.new(zesty_letterslider2, 0, {
			{zesty_subway_digit32, 0}, --U
			{zesty_subway_digit21, 0}, --U
			{zesty_subway_digit11, 4}, --Y (U + 4)
			{zesty_subway_digit23, -12}, --I (U - 12)
		}, 20),
		LetterSlider.new(zesty_letterslider3, 0, {
			{zesty_subway_digit33, 0}, --E
			{zesty_subway_digit34, 0}, --E
			{zesty_subway_digit15, 0}, --E
		}, 4),
		LetterSlider.new(zesty_letterslider4, 0, {
			{zesty_subway_digit35, 0}, --N
			{zesty_subway_digit13, 0}, --N
			{zesty_subway_digit22, 0}, --N
			{zesty_subway_digit25, 0}, --N
		}, 13),
	}

elseif callType == LuaCallType.Unlock then
	if context == zesty_winner_lock then
		displayWinner()
	elseif context == zesty_subwayslider_moved then
		checkSliders()
	end

elseif callType == LuaCallType.SlidableMoved then
	for _, letterSlider in ipairs(letterSliders) do
		if context == letterSlider.slider then
			local newValue = round(letterSlider.slider.value * (sliderSegments - 1))
			if letterSlider:setValue(newValue) then
				api.setLockValue(zesty_sfx_subwayhandle, 1, 1)
			end
		end
	end
	
end
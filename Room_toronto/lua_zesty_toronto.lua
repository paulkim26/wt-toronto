-- Functions

-- Initialize gear angles + rotation speed
function initGears()
	gearRotationFactor = 0				-- Base factor that all gear rotation is based on
	gearControlPosition = 0				-- Slider that controls rotation
	gearTargetDegrees = nil				-- If set, rotate to this angle

	gearSunDegrees = 90					-- Angle of the central "sun" gear
	gearPlanetDegrees = 360 / 32 / 2	-- Angle of the 3 "planet" gears
	gearRingDegrees = 0					-- Angle of the outer "ring" gear
	
	--[[
	Note: The "ring" gear does not actually spin, because the player is standing inside the tower
	and also rotating with the ring gear.
	]]
end

-- Return difference between two angles
function angleDelta(angle, targetAngle)
	local delta = (targetAngle - angle + 360) % 360
	if delta > 180 then
		delta = math.abs(360 - delta) * -1
	end
	return delta
end

-- Calculate gear rotation based on time since last update
function calcGearDegrees(deltaSeconds)
	-- Calculate rotation speed scale
	local gearRotationFactorTarget

	if gearTargetDegrees then
		-- Rotate tower to target angle
		local gearTargetDegreesDiff = angleDelta(gearSunDegrees, gearTargetDegrees)
		
		if math.abs(gearTargetDegreesDiff) < 1 then
			return
		end

		gearRotationFactorTarget = gearRotationFactorMax

		-- Slow down rotation as approaching target
		if (math.abs(gearTargetDegreesDiff) < 15) then
			gearRotationFactorTarget = gearRotationFactorTarget * math.abs(gearTargetDegreesDiff) / 15
		end

		-- Invert rotation speed if going clockwise
		if (gearTargetDegreesDiff < 0) then
			gearRotationFactorTarget = -gearRotationFactorTarget
		end
	else
		-- Set target angle based on slider control
		gearRotationFactorTarget = gearControlPosition * gearRotationFactorMax * -1
	end
	
	-- Accelerate gear rotation factor based on slider control
	local gearRotationFactorDiff = gearRotationFactorTarget - gearRotationFactor

	if gearRotationFactor ~= gearRotationFactorTarget then
		if math.abs(gearRotationFactorDiff) < 0.05 then
			gearRotationFactor = gearRotationFactorTarget
		else
			gearRotationFactor = gearRotationFactor + gearRotationFactorDiff / 30
		end
	end
	
	-- Calculate gear rotation speed
	local gearRingDegreesPerSecond = gearRotationFactor
	local gearPlanetDegreesPerSecond = -1.5 * gearRotationFactor
	local gearSunDegreesPerSecond = 6 * gearRotationFactor

	-- Update gear angles
	gearRingDegrees = (gearRingDegrees + deltaSeconds * gearRingDegreesPerSecond) % 360
	gearSunDegrees = (gearSunDegrees + deltaSeconds * gearSunDegreesPerSecond) % 360
	gearPlanetDegrees = (gearPlanetDegrees + deltaSeconds * gearPlanetDegreesPerSecond) % 360

	-- Set gear angles
	zesty_gear_sun.transform.rotation = Quaternion.Euler(0, gearSunDegrees, 0)
	zesty_gear_planet1.transform.rotation = Quaternion.Euler(0, gearPlanetDegrees, 0)
	zesty_gear_planet2.transform.rotation = Quaternion.Euler(0, gearPlanetDegrees, 0)
	zesty_gear_planet3.transform.rotation = Quaternion.Euler(0, gearPlanetDegrees, 0)
	zesty_gear_ring_parent.transform.rotation = Quaternion.Euler(0, gearRingDegrees, 0)

	zesty_wheel.transform.rotation = Quaternion.Euler(0, 90, 90 - gearSunDegrees)
end

-- Events
if callType == LuaCallType.Init then
	-- Global variables
	lastUpdateTime = 0
	deltaIntervalSeconds = 1 / 60 -- Interval of time between updates to gears
	gearRotationFactorMax = 2

	initGears()
	calcGearDegrees(0)

elseif callType == LuaCallType.Unlock then

elseif callType == LuaCallType.Update then
	local currentTime = Time.time
	local deltaSeconds = currentTime - lastUpdateTime

	if deltaSeconds >= deltaIntervalSeconds then
		calcGearDegrees(deltaSeconds)
		lastUpdateTime = currentTime
	end

elseif callType == LuaCallType.SlidableMoved then
	if context == zesty_slider then
		gearControlPosition = (zesty_slider.value - 0.5) * 2
		gearTargetDegrees = nil -- Override target angle
	end

elseif callType == LuaCallType.SwitchDone then
	if context == zesty_button_east then
		gearTargetDegrees = 0
	elseif context == zesty_button_north then
		gearTargetDegrees = 90
	elseif context == zesty_button_west then
		gearTargetDegrees = 180
	elseif context == zesty_button_south then
		gearTargetDegrees = 270
	end

elseif callType == LuaCallType.Slot then
end
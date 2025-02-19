-- Functions

function round(num)
    return math.floor(num + 0.5)
end

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
		zesty_condo_activator.type = (enable and zesty_condo_activator.ActivatorType.enable) or zesty_condo_activator.ActivatorType.disable
	else
		zesty_condo_activator.type = zesty_condo_activator.ActivatorType.disable
	end

	zesty_condo_activator.targetObject = targetObject or true
	zesty_condo_activator.targetRenderer = targetRenderer or false
	zesty_condo_activator.targetCollider = targetCollider or false

	-- Convert list of targets to game objects
	local gameObjects = {}
	for i, obj in ipairs(targets) do
		gameObjects[i] = obj.gameObject
	end
	zesty_condo_activator.keys = gameObjects

	api.toggleActivator(zesty_condo_activator)
end

-- Initialize gear angles + rotation speed
function initGears()
	gearRotationFactor = 0				-- Base factor that all gear rotation is based on
	gearControlPosition = 0				-- Slider that controls rotation

	--gearSunDegrees = 11.25				-- Angle of the central "sun" gear
	gearSunDegrees = 0
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

--[[
	Calculate gear rotation based on time since last update
	
	Params:
		deltaSeconds (num) - number of seconds since last update (can be fractions of seconds)
	
	Returns:
		true if tower was rotating
		false if no rotation
]]
function calcGearDegrees(deltaSeconds)
	-- Calculate rotation speed scale

	-- Set target angle based on slider control
	local gearRotationFactorTarget = gearControlPosition * gearRotationFactorMax * -1
	
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

	return (gearRotationFactor ~= 0)
end

-- Events
if callType == LuaCallType.Unlock then
	if context == zesty_init then
		-- Global variables
		lastUpdateTime = 0
		deltaIntervalSeconds = 1 / 60 -- Interval of time between updates to gears
		gearRotationFactorMax = 2
		sliderIncrement = 0
		rotating = false -- Whether or not tower is currently rotating

		initGears()
		calcGearDegrees(0)
		activate({zesty_elevator_obstacle2}, false, true) -- Hide this obstacle at start
	end
elseif callType == LuaCallType.Update then
	if lastUpdateTime ~= nil then -- Don't run this if global vars are uninitialized

		local currentTime = Time.time
		local deltaSeconds = currentTime - lastUpdateTime

		if deltaSeconds >= deltaIntervalSeconds then
			if calcGearDegrees(deltaSeconds) then
				if not rotating then
					activate({zesty_elevator_obstacle2}, true, true) -- Spawn elevator obstacle to prevent people clipping in and stealing trophy early
					rotating = true
					--api.log("rotating...")
				end
			else
				if rotating then
					activate({zesty_elevator_obstacle2}, false, true)
					rotating = false
					--api.log("stopped.")
				end
			end
			lastUpdateTime = currentTime
		end
	end
elseif callType == LuaCallType.SlidableMoved then
	if context == zesty_slider then
		local newSliderIncrement = round((zesty_slider.value - 0.5) * 4)

		if sliderIncrement != newSliderIncrement then
			if newSliderIncrement == 0 then
				api.setLockValue(zesty_sfx_rotation_winddown, 1, 1)
			else
				api.setLockValue(zesty_sfx_rotation_windup, 1, 1)
			end

			sliderIncrement = newSliderIncrement
			gearControlPosition = sliderIncrement * 0.5
		end
	end
end
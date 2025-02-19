-- Return whether the maple leaf slots will collide due to inserted pieces
function checkMapleCollision()
	-- Initialize table of cells
	local cells = {}
	local rows = 3
	local columns = 6

	for i = 1, rows do
		cells[i] = {}
		for j = 1, columns do
			cells[i][j] = 0
		end
	end

	-- Hard set bottom right slot (because there's a fixed crest there)
	cells[1][5] = 1
	cells[2][5] = 1
	cells[3][6] = 1

	--[[
		Row 1 - small red jewels
		Row 2 - large red jewels
		Row 3 - medium white jewels
	]]

	for i, slot in ipairs(mapleSlotsOuter) do
		-- Add +1 for each cell that is obscured inserted
		if slot.insertedKey == zesty_maple_key_1.transform.gameObject then
			-- earring
			cells[2][i] = cells[2][i] + 1
		elseif slot.insertedKey == zesty_maple_key_2.transform.gameObject then
			-- crown
			cells[1][i] = cells[1][i] + 1
			cells[1][i + 1] = cells[1][i + 1] + 1
			cells[2][i] = cells[2][i] + 1
		elseif slot.insertedKey == zesty_maple_key_3.transform.gameObject then
			-- left hook
			cells[2][i] = cells[2][i] + 1
			cells[3][i] = cells[3][i] + 1
		elseif slot.insertedKey == zesty_maple_key_4.transform.gameObject then
			-- right hook
			cells[2][i] = cells[2][i] + 1
			cells[3][i + 1] = cells[3][i + 1] + 1
		elseif slot.insertedKey == zesty_maple_key_5.transform.gameObject then
			-- pierced right hook
			cells[1][i] = cells[1][i] + 1
			cells[2][i] = cells[2][i] + 1
			cells[3][i + 1] = cells[3][i + 1] + 1
		elseif slot.insertedKey == zesty_maple_key_6.transform.gameObject then
			-- full
			cells[2][i] = cells[2][i] + 1
			cells[3][i] = cells[3][i] + 1
			cells[3][i + 1] = cells[3][i + 1] + 1
		end
	end

	for i, slot in ipairs(mapleSlotsInner) do
		if slot.insertedKey == zesty_maple_key_1.transform.gameObject then
			-- earring
			cells[1][i + 2] = cells[1][i + 2] + 1
			cells[3][i + 2] = cells[3][i + 2] + 1
		elseif slot.insertedKey == zesty_maple_key_2.transform.gameObject then
			-- crown
			cells[1][i + 2] = cells[1][i + 2] + 1
			cells[2][i + 1] = cells[2][i + 1] + 1
			cells[2][i + 2] = cells[2][i + 2] + 1
			cells[3][i] = cells[3][i] + 1
			cells[3][i + 1] = cells[3][i + 1] + 1
			cells[3][i + 2] = cells[3][i + 2] + 1
			cells[3][i + 3] = cells[3][i + 3] + 1
		elseif slot.insertedKey == zesty_maple_key_3.transform.gameObject then
			-- left hook
			cells[3][i] = 2 -- Pierces button
		elseif slot.insertedKey == zesty_maple_key_4.transform.gameObject then
			-- right hook
			cells[3][i] = 2 -- Pierces button
		elseif slot.insertedKey == zesty_maple_key_5.transform.gameObject then
			-- pierced right hook
			cells[3][i] = 2 -- Pierces button
		elseif slot.insertedKey == zesty_maple_key_6.transform.gameObject then
			-- full
			cells[3][i] = 2 -- Pierces button
		end
	end
	
	printTable(cells) --TODODEBUG

	for i = 1, rows do
		for j = 1, columns do
			if cells[i][j] > 1 then
				return true
			end
		end
	end

	return false
end

function printTable(table)
    for j = 1, #table do
        local line = ""
        for i = 1, #table[j] do
            line = line .. table[j][i] .. "\t"
        end
        api.log(line)
    end
end

if callType == LuaCallType.Init then
	mapleSlotsOuter = {
		zesty_maple_slot_11,
		zesty_maple_slot_12,
		zesty_maple_slot_13,
		zesty_maple_slot_14,
		zesty_maple_slot_15
	}

	mapleSlotsInner = {
		zesty_maple_slot_21,
		zesty_maple_slot_22
	}

elseif callType == LuaCallType.Unlock then
	if context == zesty_maple_button then
		-- Pull maple slots halfway in
		api.setLockValue(zesty_maple_toggle1, 1, 1)
		api.setLockValue(zesty_maple_toggle1_reset, 1, 1)

		if not checkMapleCollision() then
			-- Pull maple slots all the way in
			api.setLockValue(zesty_maple_toggle2, 1, 1)
			api.setLockValue(zesty_maple_toggle2_reset, 1, 1)
		end
	end
end
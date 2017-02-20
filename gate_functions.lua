local MP = minetest.get_modpath(minetest.get_current_modname())
dofile(MP.."/class_pointset.lua")

-- Given a facedir, returns a set of all the corresponding directions
local get_dirs = function(facedir)
	local dirs = {}
	local top = {[0]={x=0, y=1, z=0},
		{x=0, y=0, z=1},
		{x=0, y=0, z=-1},
		{x=1, y=0, z=0},
		{x=-1, y=0, z=0},
		{x=0, y=-1, z=0}}	
	dirs.back = minetest.facedir_to_dir(facedir)
	dirs.top = top[math.floor(facedir/4)]
	dirs.right = {
		x=dirs.top.y*dirs.back.z - dirs.back.y*dirs.top.z,
		y=dirs.top.z*dirs.back.x - dirs.back.z*dirs.top.x,
		z=dirs.top.x*dirs.back.y - dirs.back.x*dirs.top.y
	}
	dirs.front = vector.multiply(dirs.back, -1)
	dirs.bottom = vector.multiply(dirs.top, -1)
	dirs.left = vector.multiply(dirs.right, -1)
	return dirs
end

local interpret_hinge = function(hinge_def, pos, node_dirs)
	local axis_dir = node_dirs[hinge_def.axis]
	local axis
	if axis_dir.x ~= 0 then
		axis = "x"
	elseif axis_dir.y ~= 0 then
		axis = "y"
	else
		axis = "z"
	end
	
	local placement
	if type(hinge_def.offset) == "string" then
		placement = vector.add(pos, node_dirs[hinge_def.offset])
	elseif type(hinge_def.offset) == "table" then
		placement = vector.new(0,0,0)
		for _, val in pairs(hinge_def.offset) do
			placement = vector.add(placement, node_dirs[val])
		end
		placement = vector.add(pos, vector.normalize(placement))
	else
		placement = pos
	end

	return axis, placement
end

local get_door_layout = function(pos, facedir, player)
	-- This method does a flood-fill looking for all nodes that meet the following criteria:
	-- belongs to a "castle_gate" group
	-- has the same "back" direction as the initial node
	-- is accessible via up, down, left or right directions unless one of those directions goes through an edge that one of the two nodes has marked as a gate edge
	local door = {}

	door.all = {}
	door.contains_protected_node = false
	door.directions = get_dirs(facedir)
	door.previous_move = minetest.get_meta(pos):get_string("previous_move")

	-- temporary pointsets used while searching
	local to_test = Pointset.create()
	local tested = Pointset.create()
	local can_slide_to = Pointset.create()
	
	to_test:set_pos(pos, true)
	
	local test_pos, _ = to_test:pop()
	while test_pos ~= nil do
		tested:set_pos(test_pos, true) -- track nodes we've looked at
		local test_node = minetest.get_node(test_pos)

		if test_node.name == "ignore" then
			--array is next to unloaded nodes, too dangerous to do anything. Abort.
			return nil
		end
		
		if minetest.is_protected(test_pos, player:get_player_name()) and not minetest.check_player_privs(player, "protection_bypass") then
			door.contains_protected_node = true
		end
		
		local test_node_def = minetest.registered_nodes[test_node.name]
		can_slide_to:set_pos(test_pos, test_node_def.buildable_to == true)
		
		if test_node_def.paramtype2 == "facedir" then
			local test_node_dirs = get_dirs(test_node.param2)
			local coplanar = vector.equals(test_node_dirs.back, door.directions.back)

			if coplanar and test_node_def.groups.castle_gate then
				local entry = {["pos"] = test_pos, ["node"] = test_node}
				table.insert(door.all, entry)
				if test_node_def._gate_hinge ~= nil then
					local axis, placement = interpret_hinge(test_node_def._gate_hinge, test_pos, test_node_dirs)
					if door.hinge == nil then
						door.hinge = {axis=axis, placement=placement}
					elseif door.hinge.axis ~= axis then
						return nil -- Misaligned hinge axes, door cannot rotate.
					else
						local axis_dir = {x=0, y=0, z=0}
						axis_dir[axis] = 1
						local displacement = vector.normalize(vector.subtract(placement, door.hinge.placement))
						if not (vector.equals(displacement, axis_dir) or vector.equals(displacement, vector.multiply(axis_dir, -1))) then
							return nil -- Misaligned hinge offset, door cannot rotate.
						end
					end
				end
				
				can_slide_to:set_pos(test_pos, true) -- since this is part of the door, other parts of the door can slide into it

				local test_directions = {"top", "bottom", "left", "right"}
				for _, dir in pairs(test_directions) do
					local adjacent_pos = vector.add(test_pos, door.directions[dir])
					local adjacent_node = minetest.get_node(adjacent_pos)
					local adjacent_def = minetest.registered_nodes[adjacent_node.name]
					can_slide_to:set_pos(adjacent_pos, adjacent_def.buildable_to == true or adjacent_def.groups.castle_gate)
					
					if test_node_def._gate_edges == nil or not test_node_def._gate_edges[dir] then -- if we ourselves are an edge node, don't look in the direction we're an edge in
						if tested:get_pos(adjacent_pos) == nil then -- don't look at nodes that have already been looked at
							if adjacent_def.paramtype2 == "facedir" then -- all doors are facedir nodes so we can pre-screen some targets
							
								local edge_points_back_at_test_pos = false
								-- Look at the adjacent node's definition. If it's got gate edges, check if they point back at us.
								if adjacent_def._gate_edges ~= nil then
									local adjacent_directions = get_dirs(adjacent_node.param2)
									for dir, val in pairs(adjacent_def._gate_edges) do
										if vector.equals(vector.add(adjacent_pos, adjacent_directions[dir]), test_pos) then
											edge_points_back_at_test_pos = true
											break
										end
									end									
								end
								
								if not edge_points_back_at_test_pos then
									to_test:set_pos(adjacent_pos, true)
								end
							end
						end
					end				
				end
			end
		end
		
		test_pos, _ = to_test:pop()
	end
	
	if door.hinge == nil then
		--sliding door, evaluate which directions it can go
		door.can_slide = {top=true, bottom=true, left=true, right=true}
		for _,door_node in pairs(door.all) do
			door.can_slide.top = door.can_slide.top and can_slide_to:get_pos(vector.add(door_node.pos, door.directions.top))
			door.can_slide.bottom = door.can_slide.bottom and can_slide_to:get_pos(vector.add(door_node.pos, door.directions.bottom))
			door.can_slide.left = door.can_slide.left and can_slide_to:get_pos(vector.add(door_node.pos, door.directions.left))
			door.can_slide.right = door.can_slide.right and can_slide_to:get_pos(vector.add(door_node.pos, door.directions.right))
		end
	end
	
	return door
end

--------------------------------------------------------------------------
-- Sliding

local slide_gate = function(door, direction)
	for _, door_node in pairs(door.all) do
		door_node.pos = vector.add(door_node.pos, door.directions[direction])
	end
	door.previous_move = direction
end

--------------------------------------------------------------------------
-- Rotation (slightly more complex than sliding)

local facedir_rotate = {
	['x'] = {
		[-1] = {[0]=4, 5, 6, 7, 22, 23, 20, 21, 0, 1, 2, 3, 13, 14, 15, 12, 19, 16, 17, 18, 10, 11, 8, 9}, -- 270 degrees
		[1] = {[0]=8, 9, 10, 11, 0, 1, 2, 3, 22, 23, 20, 21, 15, 12, 13, 14, 17, 18, 19, 16, 6, 7, 4, 5}, -- 90 degrees
	},
	['y'] = {
		[-1] = {[0]=3, 0, 1, 2, 19, 16, 17, 18, 15, 12, 13, 14, 7, 4, 5, 6, 11, 8, 9, 10, 21, 22, 23, 20}, -- 270 degrees
		[1] = {[0]=1, 2, 3, 0, 13, 14, 15, 12, 17, 18, 19, 16, 9, 10, 11, 8, 5, 6, 7, 4, 23, 20, 21, 22}, -- 90 degrees
	},
	['z'] = {
		[-1] = {[0]=16, 17, 18, 19, 5, 6, 7, 4, 11, 8, 9, 10, 0, 1, 2, 3, 20, 21, 22, 23, 12, 13, 14, 15}, -- 270 degrees
		[1] = {[0]=12, 13, 14, 15, 7, 4, 5, 6, 9, 10, 11, 8, 20, 21, 22, 23, 0, 1, 2, 3, 16, 17, 18, 19}, -- 90 degrees
	}
}
	--90 degrees CW about x-axis: (x, y, z) -> (x, -z, y)
	--90 degrees CCW about x-axis: (x, y, z) -> (x, z, -y)
	--90 degrees CW about y-axis: (x, y, z) -> (-z, y, x)
	--90 degrees CCW about y-axis: (x, y, z) -> (z, y, -x)
	--90 degrees CW about z-axis: (x, y, z) -> (y, -x, z)
	--90 degrees CCW about z-axis: (x, y, z) -> (-y, x, z)
local rotate_pos = function(axis, direction, pos)
	if axis == "x" then
		if direction < 0 then
			return {x= pos.x, y= -pos.z, z= pos.y}
		else
			return {x= pos.x, y= pos.z, z= -pos.y}
		end
	elseif axis == "y" then
		if direction < 0 then
			return {x= -pos.z, y= pos.y, z= pos.x}
		else
			return {x= pos.z, y= pos.y, z= -pos.x}
		end
	else	
		if direction < 0 then
			return {x= -pos.y, y= pos.x, z= pos.z}
		else
			return {x= pos.y, y= -pos.x, z= pos.z}
		end
	end
end
local rotate_pos_displaced = function(pos, origin, axis, direction)
	-- position in space relative to origin
	local newpos = vector.subtract(pos, origin)
	newpos = rotate_pos(axis, direction, newpos)
	-- Move back to original reference frame
	return vector.add(newpos, origin)
end

-- TODO: this doesn't yet test for obstructions during the swing (since it "teleports" the gate into its new orientation) which makes common drawbridge designs misbehave.
local rotate_door = function (door, direction)
	local origin = door.hinge.placement
	local axis = door.hinge.axis
	
	for _, door_node in pairs(door.all) do
		origin[axis] = door_node.pos[axis]
		if not vector.equals(door_node.pos, origin) then -- There's no obstruction if the node is literally located along the rotation axis
			local newpos = rotate_pos_displaced(door_node.pos, origin, axis, direction)
			local newnode = minetest.get_node(newpos)
			local newdef = minetest.registered_nodes[newnode.name]
			if not newdef.buildable_to then
				return false
			end
		end
	end
	
	for _, door_node in pairs(door.all) do
		door_node.pos = rotate_pos_displaced(door_node.pos, origin, axis, direction)
		door_node.node.param2 = facedir_rotate[axis][direction][door_node.node.param2]
	end
	return true
end

----------------------------------------------------------------------------------------------------
-- When creating new gate pieces use this as the "on_rightclick" method of their node definitions
-- if you want the player to be able to trigger the gate by clicking on that particular node.
-- If you just want the node to move with the gate and not trigger it this isn't necessary,
-- only the "castle_gate" group is needed for that.

castle_gates.trigger_gate = function(pos, node, player)
	local door = get_door_layout(pos, node.param2, player)
	
	if door ~= nil then
		for _, door_node in pairs(door.all) do
			minetest.set_node(door_node.pos, {name="air"})
		end
		
		local door_moved = false
		if door.can_slide ~= nil then -- this is a sliding door
			if door.previous_move == "top" and door.can_slide.top then
				slide_gate(door, "top")
				door_moved = true
			elseif door.previous_move == "bottom" and door.can_slide.bottom then
				slide_gate(door, "bottom")
				door_moved = true
			elseif door.previous_move == "left" and door.can_slide.left then
				slide_gate(door, "left")
				door_moved = true
			elseif door.previous_move == "right" and door.can_slide.right then
				slide_gate(door, "right")
				door_moved = true
			end
			
			if not door_moved then -- reverse door's direction for next time
				if door.previous_move == "top" and door.can_slide.bottom then
					door.previous_move = "bottom"
				elseif door.previous_move == "bottom" and door.can_slide.top then
					door.previous_move = "top"
				elseif door.previous_move == "left" and door.can_slide.right then
					door.previous_move = "right"
				elseif door.previous_move == "right" and door.can_slide.left then
					door.previous_move = "left"
				else
					-- find any open direction
					for slide_dir, enabled in pairs(door.can_slide) do
						if enabled then
							door.previous_move = slide_dir
							break
						end
					end
				end
			end
		elseif door.hinge ~= nil then -- this is a hinged door
			if door.previous_move == "deosil" or door.previous_move == "clockwise" then
				door_moved = rotate_door(door, 1)
			elseif door.previous_move == "widdershins" or door.previous_move == "counterclockwise" then
				door_moved = rotate_door(door, -1)
			end				
			
			if not door_moved then
				if door.previous_move == "deosil" or door.previous_move == "clockwise" then
					door.previous_move = "widdershins"
				else
					door.previous_move = "deosil"
				end
			end
		end

		for _, door_node in pairs(door.all) do
			minetest.set_node(door_node.pos, door_node.node)
			minetest.get_meta(door_node.pos):set_string("previous_move", door.previous_move)
		end
		
		if door_moved then
			minetest.after(1, function()
				castle_gates.trigger_gate(door.all[1].pos, door.all[1].node, player)
				end)
		end
	end	
end
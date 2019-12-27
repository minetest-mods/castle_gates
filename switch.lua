local MP, S, NS = nil

if (minetest.get_modpath("intllib") == nil) then
	S = minetest.get_translator("castle_gates")

else
	-- internationalization boilerplate
	MP = minetest.get_modpath(minetest.get_current_modname())
	S, NS = dofile(MP.."/intllib.lua")

end

local worldpath = minetest.get_worldpath()
local filename = worldpath .. "/castle_gates_switch_map.lua"
local load_switch_data = function()
	local f, e = loadfile(filename)
	if f then
		castle_gates.switch_map = f()
	else
		castle_gates.switch_map = {}
	end
end

local dirty_data = false
castle_gates.save_switch_data = function()
	if dirty_data == true then
		return
	end
	dirty_data = true
	-- Simple way of accumulating a bunch of simultaneous save data calls
	-- into a single file write
	minetest.after(0.1, function()
		dirty_data = false
		local file, e = io.open(filename, "w")
		if not file then
			return
		end
		file:write(minetest.serialize(castle_gates.switch_map))
		file:close()
	end)
end

load_switch_data()

local switch_map = castle_gates.switch_map
-- The switch map is a bi-directional multimap linking world positions (in the form of hashes) to other world positions. So for example:
--{
--	[gate_node_1_hash] = {[switch_node_1_hash] = true, [switch_node_2_hash] = true},
--	[switch_node_1_hash] = {[gate_node_1_hash] = true},
--	[switch_node_2_hash] = {[gate_node_1_hash] = true},
--}
-- This would record that switches 1 and 2 are linked to gate node 1. You can navigate from one end of the link to the other efficiently
-- using this multimap.


------------------------------------------------------------------------------------
-- User interface

-- This tracks the ID numbers of any hud waypoints being displayed to players
local waypoint_huds = {}

local PARTICLE_LIFE = 1
local HUD_LIFE = 10

local particle_link = function(player_name, switch_pos, gate_pos)
	local distance = math.min(vector.distance(switch_pos, gate_pos), 20)
	local dir = vector.multiply(vector.direction(switch_pos, gate_pos), distance)
	minetest.add_particlespawner({
		amount = 10,
		time = PARTICLE_LIFE,
		minpos = switch_pos,
		maxpos = switch_pos,
		minvel = dir,
		maxvel = dir,
		minacc = {x=0, y=0, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = 1,
		maxexptime = 1,
		minsize = 1,
		maxsize = 1,
		collisiondetection = false,
		vertical = false,
		glow = 8,
		texture = "castle_gates_link_particle.png",
		playername = player_name,
	})
end

local update_switch_targets = function(player, switch_hash)
	local player_name = player:get_player_name()
	
	-- First, remove any existing waypoints
	local player_context = waypoint_huds[player_name]		
	if player_context then
		for _, hud_id in pairs(player_context.hud_ids) do
			player:hud_remove(hud_id)
		end
		if player_context.switch_hud_id ~= nil then
			player:hud_remove(player_context.switch_hud_id)
		end
		waypoint_huds[player_name] = nil
	end
	
	-- If nil was provided as a parameter, we're done.
	if switch_hash == nil then
		return
	end
	
	-- If switch_hash gives us valid targets, show them
	local gates = switch_map[switch_hash] or {}
	local switch_pos = minetest.get_position_from_hash(switch_hash)
	local player_huds = {}
	player_huds.hud_lifetime = 0 -- allows the display to time out
	player_huds.particle_lifetime = 0
	player_huds.switch_pos = switch_pos
	player_huds.hud_ids = {}
	waypoint_huds[player_name] = player_huds
	for gate_hash, _ in pairs(gates) do
		local gate_pos = minetest.get_position_from_hash(gate_hash)
		local hud_id = player:hud_add({
			hud_elem_type = "waypoint",
			name = S("Target Gate"),
			--text = "<text>",-- distance suffix, can be blank
			number = 0xFFFFFF,
			world_pos = gate_pos})
		player_huds.hud_ids[gate_hash] = hud_id
		particle_link(player_name, switch_pos, gate_pos)
	end
	player_huds.switch_hud_id = player:hud_add({
		hud_elem_type = "waypoint",
		name = S("Source Switch"),
		--text = "<text>",-- distance suffix, can be blank
		number = 0xFFFF00,
		world_pos = switch_pos})
end

-- For refreshing particles and expiring huds
minetest.register_globalstep(function(dtime)
	local expiring_huds = {}
	for player_name, context in pairs (waypoint_huds) do
		context.hud_lifetime = context.hud_lifetime + dtime
		if context.hud_lifetime > HUD_LIFE then
			table.insert(expiring_huds, player_name)
		else
			context.particle_lifetime = context.particle_lifetime + dtime
			if context.particle_lifetime > PARTICLE_LIFE then
				context.particle_lifetime = 0
				for gate_hash, _ in pairs(context.hud_ids) do
					particle_link(player_name, context.switch_pos, minetest.get_position_from_hash(gate_hash))
				end
			end
		end
	end
	for _, player_name in ipairs(expiring_huds) do
		local player = minetest.get_player_by_name(player_name)
		if player then
			update_switch_targets(player, nil)
		end
	end
end)

-- Remove any hud stuff when a player dies or leaves
minetest.register_on_dieplayer(function(objectref, reason)
	update_switch_targets(objectref, nil)
end)
minetest.register_on_leaveplayer(function(objectref, timed_out)
	local player_name = objectref:get_player_name()
	waypoint_huds[player_name] = nil
end)

--------------------------------------------------------------------------------------

local remove_switch_hash = function(invalid_target)
	local switches = switch_map[invalid_target]
	if switches then
		for switch_hash, _ in pairs(switches) do
			local switch_pointing_here = switch_map[switch_hash]
			switch_pointing_here[invalid_target] = nil
			if next(switch_pointing_here) == nil then
				-- switch has no more targets
				switch_map[switch_hash] = nil
			end
		end
		switch_map[invalid_target] = nil
		castle_gates.save_switch_data()
	end
end

local swap_switch = function(pos, node)
	if node.name == "castle_gates:switch" then
		node.name = "castle_gates:switch2"
		minetest.swap_node(pos, node)
	else
		node.name = "castle_gates:switch"
		minetest.swap_node(pos, node)	
	end
end

castle_gates.trigger_switch = function(pos, node, clicker, itemstack, pointed_thing)
	local player_name
	if clicker then
		player_name = clicker:get_player_name()
	end
	local switch_hash = minetest.hash_node_position(pos)
	local targets = switch_map[switch_hash]
	if targets then
		local invalid_gates = {}
		local triggered = false
		for target_hash, _ in pairs(targets) do
			local target_pos = minetest.get_position_from_hash(target_hash)
			local target_node = minetest.get_node(target_pos)
			if target_node.name == "ignore" and player_name then
				minetest.chat_send_player(player_name, S("Target gate node at @1 was too far away to trigger.",
					minetest.pos_to_string(target_pos)))
			elseif minetest.get_item_group(target_node.name, "castle_gate") == 0 then
				table.insert(invalid_gates, target_hash)
			else
				castle_gates.trigger_gate(target_pos, target_node, clicker)
				triggered = true
			end
		end
		if triggered then
			swap_switch(pos, node)
		end
		-- if there were invalid gate targets, remove those gate targets from all switches pointing to them
		-- and then remove the invalid gate targets themselves
		for _, invalid_target in ipairs(invalid_gates) do
			remove_switch_hash(invalid_target)
		end
		if player_name then
			minetest.chat_send_player(player_name, S("Gate triggered"))
		end
	else
		if player_name then
			minetest.chat_send_player(player_name, S("Switch not connected to a gate"))
		end
	end
end

castle_gates.clear_switch = function(pos)
	local switch_hash = minetest.hash_node_position(pos)
	remove_switch_hash(switch_hash)
end

local switch_def = {
	description = S("Gate Switch"),
	_doc_items_longdesc = nil,
	_doc_items_usagehelp = nil,
	drawtype = "mesh",
	mesh = "castle_gates_switch.obj",
	tiles = {"default_wood.png",	--Exterior of switch holder
		"default_wood.png",	--Interior of switch holder
		"default_coal_block.png",	--switch hub
		"default_copper_block.png",	--switch shaft
		"default_steel_block.png",},	--base
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {choppy=1, castle_gate_switch = 1},
	sounds = default.node_sound_wood_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
			{-0.1875, -0.375, -0.3125, 0.1875, -0.0625, 0.3125},
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
			{-0.1875, -0.375, -0.3125, 0.1875, -0.0625, 0.3125},
		},
	},
	drops = "castle_gates:switch",
	is_ground_content = false,
	on_rightclick = castle_gates.trigger_switch,
	on_destruct = castle_gates.clear_switch,
}

if minetest.get_modpath("mesecons") then
	switch_def.mesecons = {
		effector = {
			action_on = function(pos, node)
				castle_gates.trigger_switch(pos, node)
			end,
		}
	}
end

local function deep_copy(input)
	if type(input) ~= "table" then
		return input
	end
	local output = {}
	for index, value in pairs(input) do
		output[index] = deep_copy(value)
	end
	return output
end

minetest.register_node("castle_gates:switch", switch_def)
local switch2_def = deep_copy(switch_def)
switch2_def.mesh = "castle_gates_switch2.obj"
switch2_def.groups.not_in_creative_inventory = 1 -- if you don't deep-copy and just use the original, this group change applies to both
minetest.register_node("castle_gates:switch2", switch2_def)

local switch_gate_linkage_def = {
	description = S("Switch/Gate Linkage"),
	_doc_items_longdesc = nil,
	_doc_items_usagehelp = nil,
	
	inventory_image = "castle_gates_linkage.png",
	groups = {tool = 1},
	on_use = function(itemstack, user, pointed_thing)	
		if pointed_thing.type ~="node" then
			return
		end
		local pointed_pos = pointed_thing.under
		local pointed_node = minetest.get_node(pointed_pos)
		local pointed_node_name = pointed_node.name
		local pointed_gate_group = minetest.get_item_group(pointed_node_name, "castle_gate")
		local pointed_switch_group = minetest.get_item_group(pointed_node_name, "castle_gate_switch")
	
		-- If there's a recorded switch position, load that from the tool's meta
		local meta = itemstack:get_meta()
		local switch_hash = nil
		local switch_pos = meta:get("switch")
		if switch_pos then
			switch_pos = minetest.string_to_pos(switch_pos)
			switch_hash = minetest.hash_node_position(switch_pos)
		end
		
		-- Sanity check
		if pointed_gate_group > 0 and pointed_switch_group > 0 then
			minetest.log("error", "[castle_gates] the node " .. pointed_node_name
				.. " belongs to both castle_gate and castle_gate_switch groups, this is invalid.")
			return
		end
		
		local player_name = user:get_player_name()
		
		-- If we clicked on a switch
		if pointed_switch_group > 0 then
			-- if either we've never clicked on a switch before or this is a new switch
			if not switch_pos or not vector.equals(switch_pos, pointed_pos) then
				-- update the linkage's stored switch
				switch_pos = pointed_pos
				switch_hash = minetest.hash_node_position(switch_pos)
				meta:set_string("switch", minetest.pos_to_string(switch_pos))
				meta:set_string("description", S("Gate linkage to switch at @1", minetest.pos_to_string(switch_pos)))
				minetest.chat_send_player(player_name, S("Switch linkage target updated to @1", minetest.pos_to_string(switch_pos)))
			end
			update_switch_targets(user, switch_hash)
			return itemstack
		end
		
		-- If we clicked on a gate and we have a switch
		if switch_pos and pointed_gate_group > 0 then
			local gate_pos = pointed_pos
			local gate_hash = minetest.hash_node_position(gate_pos)

			local gate_links = switch_map[gate_hash] or {}
			local switch_links = switch_map[switch_hash] or {}

			if gate_links[switch_hash] and switch_links[gate_hash] then
				-- link already exists, remove it
				minetest.chat_send_player(player_name, S("Removing link from @1", minetest.pos_to_string(gate_pos)))
				remove_switch_hash(gate_hash)
				update_switch_targets(user, switch_hash)
				return
			end

			-- link doesn't exist, create it
			gate_links[switch_hash] = true
			switch_links[gate_hash] = true

			switch_map[gate_hash] = gate_links
			switch_map[switch_hash] = switch_links
			
			update_switch_targets(user, switch_hash)
			castle_gates.save_switch_data()
			
			minetest.log("action", player_name .. " added a link from a switch at "
				.. minetest.pos_to_string(switch_pos) .. " to a gate at " .. minetest.pos_to_string(gate_pos))
			minetest.chat_send_player(player_name, S("Added a link from a switch at @1 to a gate at @2",
				minetest.pos_to_string(switch_pos), minetest.pos_to_string(gate_pos)))
			if not (creative and creative.is_enabled_for and creative.is_enabled_for(player_name)) then
				itemstack:add_wear(65535 / ((uses or 200) - 1))
			end
			return itemstack
		end

		-- Clicked on anything else
		if switch_pos then
			update_switch_targets(user, switch_hash)
		end		
	end,
}

minetest.register_tool("castle_gates:linkage", switch_gate_linkage_def)

if minetest.get_modpath("basic_materials") then
	minetest.register_craft({
		output = "castle_gates:linkage 2",
		recipe = {
			{"", "basic_materials:chain_steel", ""},
			{"", "basic_materials:gear_steel", ""},
			{"","",""},
		}
	})
	minetest.register_craft({
		output = "castle_gates:linkage 2",
		recipe = {
			{"", "basic_materials:chain_brass", ""},
			{"", "basic_materials:gear_steel", ""},
			{"","",""},
		}
	})
elseif minetest.get_modpath("castle_lighting") then
	minetest.register_craft({
		output = "castle_gates:linkage 2",
		recipe = {
			{"", "castle:chandelier_chain", ""},
			{"", "", ""},
			{"","castle:chandelier_chain",""},
		}
	})
else
	minetest.register_craft({
		output = "castle_gates:linkage",
		recipe = {
			{"", "default:steel_ingot", ""},
			{"", "", ""},
			{"","default:steel_ingot",""},
		}
	})
end

minetest.register_craft({
	output = "castle_gates:switch",
	recipe = {
		{"", "", ""},
		{"", "group:wood", ""},
		{"default:steel_ingot","castle_gates:linkage","default:steel_ingot"},
	}
})
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

-- Was used to rotate the switch, but decided to just bite the bullet and use a second model instead
--local param2_swap =
--{
--	[0] = 2, [1] = 3, [2] = 0, [3] = 1,
--	[4] = 6, [6] = 4, [7] = 5, [5] = 7,
--	[8] = 10, [10] = 8, [11] = 9, [9] = 11,
--	[12] = 14, [14] = 12, [13] = 15, [15] = 13,
--	[16] = 18, [18] = 16, [17] = 19, [19] = 17,
--	[20] = 22, [22] = 20, [21] = 23, [23] = 21
--}
local swap_switch = function(pos, node)
	if node.name == "castle_gates:switch" then
		node.name = "castle_gates:switch2"
		minetest.swap_node(pos, node)
	else
		node.name = "castle_gates:switch"
		minetest.swap_node(pos, node)	
	end
end

local switch_on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
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
			if minetest.get_item_group(target_node.name, "castle_gate") == 0 then
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
			minetest.chat_send_all("removing invalid gate target from switch")
		end
		if player_name then
			minetest.chat_send_player(player_name, "Gate triggered")
		end
	else
		if player_name then
			minetest.chat_send_player(player_name, "Switch not connected to a gate")			
		end
	end
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
	on_rightclick = switch_on_rightclick,
	on_destruct = function(pos)
		local switch_hash = minetest.hash_node_position(pos)
		remove_switch_hash(switch_hash)
	end,
}

if minetest.get_modpath("mesecons") then
	switch_def.mesecons = {
		effector = {
			action_on = function(pos, node)
				switch_on_rightclick(pos, node)
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
			return itemstack
		end
		local pointed_pos = pointed_thing.under
		local pointed_node = minetest.get_node(pointed_pos)
		local pointed_node_name = pointed_node.name
		local pointed_gate_group = minetest.get_item_group(pointed_node_name, "castle_gate")
		local pointed_switch_group = minetest.get_item_group(pointed_node_name, "castle_gate_switch")
	
		local meta = itemstack:get_meta()
		local switch_pos = meta:get("switch")
		local gate_pos = meta:get("gate")
		if switch_pos then
			switch_pos = minetest.string_to_pos(switch_pos)
		end
		if gate_pos then
			gate_pos = minetest.string_to_pos(gate_pos)
		end
		
		if pointed_gate_group > 0 and pointed_switch_group > 0 then
			minetest.log("error", "[castle_gates] the node " .. pointed_node_name
				.. " belongs to both castle_gate and castle_gate_switch groups, this is invalid.")
			return itemstack
		end
		
		local player_name = user:get_player_name()
		local add_link = false
		if pointed_gate_group > 0 then
			if not gate_pos or not vector.equals(gate_pos, pointed_pos) then
				gate_pos = pointed_pos
				meta:set_string("gate", minetest.pos_to_string(gate_pos))
				minetest.chat_send_player(player_name, "Gate linkage target updated to " .. minetest.pos_to_string(gate_pos))
			end
			add_link = true
		end
		if pointed_switch_group > 0 then
			if not switch_pos or not vector.equals(switch_pos, pointed_pos) then
				switch_pos = pointed_pos
				meta:set_string("switch", minetest.pos_to_string(switch_pos))
				minetest.chat_send_player(player_name, "Switch linkage target updated to " .. minetest.pos_to_string(switch_pos))
			end
			add_link = true
		end
		
		if add_link and gate_pos and switch_pos then
			local gate_hash = minetest.hash_node_position(gate_pos)
			local switch_hash = minetest.hash_node_position(switch_pos)

			local gate_links = switch_map[gate_hash] or {}
			local switch_links = switch_map[switch_hash] or {}

			if gate_links[switch_hash] and switch_links[gate_hash] then
				-- link already exists
				minetest.chat_send_player(player_name, "Link already exists")
				return itemstack
			end

			gate_links[switch_hash] = true
			switch_links[gate_hash] = true

			switch_map[gate_hash] = gate_links
			switch_map[switch_hash] = switch_links
			
			castle_gates.save_switch_data()
			
			minetest.log("action", player_name .. " added a link from a switch at "
				.. minetest.pos_to_string(switch_pos) .. " to a gate at " .. minetest.pos_to_string(gate_pos))
			minetest.chat_send_player(player_name, "Added a link from a switch at "
				.. minetest.pos_to_string(switch_pos) .. " to a gate at " .. minetest.pos_to_string(gate_pos))
			if not (creative and creative.is_enabled_for and creative.is_enabled_for(player_name)) then
				itemstack:add_wear(65535 / ((uses or 200) - 1))
			end
		end
		
		return itemstack
	end,

	on_place = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		meta:set_string("switch", "")
		meta:set_string("gate", "")
		minetest.chat_send_player(user:get_player_name(), "Cleared switch and gate targets")
		return itemstack
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
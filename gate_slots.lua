-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

-- copied from castle_masonry in case that mod is not loaded
local get_material_properties = function(material)
	local composition_def
	local burn_time
	if material.composition_material ~= nil then
		composition_def = minetest.registered_nodes[material.composition_material]
		burn_time = minetest.get_craft_result({method="fuel", width=1, items={ItemStack(material.composition_material)}}).time
	else
		composition_def = minetest.registered_nodes[material.craft_material]
		burn_time = minetest.get_craft_result({method="fuel", width=1, items={ItemStack(material.craft_materia)}}).time
	end
	
	local tiles = material.tile
	if tiles == nil then
		tiles = composition_def.tile
	elseif type(tiles) == "string" then
		tiles = {tiles}
	end

	local desc = material.desc
	if desc == nil then
		desc = composition_def.description
	end
	
	return composition_def, burn_time, tiles, desc
end

local materials
if minetest.get_modpath("castle_masonry") then
	materials = castle_masonry.materials
else
	materials = {{name="stonebrick", desc=S("Stonebrick"), tile="default_stone_brick.png", craft_material="default:stonebrick"}}
end

castle_gates.register_gate_slot = function(material)
	local composition_def, burn_time, tile, desc = get_material_properties(material)
	local mod_name = minetest.get_current_modname()

	minetest.register_node(mod_name..":"..material.name.."_gate_slot", {
		drawtype = "nodebox",
		description = S("@1 Gate Slot", desc),
		_doc_items_longdesc = castle_gates.doc.gate_slot_longdesc,
		_doc_items_usagehelp = castle_gates.doc.gate_slot_usagehelp,
		tiles = tile,
		paramtype = "light",
		paramtype2 = "facedir",
		groups = composition_def.groups,
		sounds = composition_def.sounds,
		
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- body
				{-0.5, -0.5, -0.75, 0.5, 0.5, -1.5}, -- bracket
			}
		},
		
		collision_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 1.5}, -- body
		},
	})
	
	minetest.register_node(mod_name..":"..material.name.."_gate_slot_reverse", {
		drawtype = "nodebox",
		description = S("@1 Gate Slot Reverse", desc), 
		_doc_items_longdesc = castle_gates.doc.gate_slot_reverse_longdesc,
		_doc_items_usagehelp = castle_gates.doc.gate_slot_reverse_usagehelp,
		tiles = tile,
		paramtype = "light",
		paramtype2 = "facedir",
		groups = composition_def.groups,
		sounds = composition_def.sounds,
		
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -1.25, 0.5, 0.5, 0.5}, -- body
			}
		},
		
		collision_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -1.25, 0.5, 0.5, 0.5}, -- body
		},
	})
	
	
	minetest.register_craft({
	output = mod_name..":"..material.name.."_gate_slot 2",
	recipe = {
		{material.craft_material,"",material.craft_material},
		{material.craft_material,"",material.craft_material},
		},
	})
	
	minetest.register_craft({
		output = mod_name..":"..material.name.."_gate_slot",
		type = "shapeless",
		recipe = {mod_name..":"..material.name.."_gate_slot_reverse"},
	})
	minetest.register_craft({
		output = mod_name..":"..material.name.."_gate_slot_reverse",
		type = "shapeless",
		recipe = {mod_name..":"..material.name.."_gate_slot"},
	})
	
	if burn_time > 0 then
		minetest.register_craft({
			type = "fuel",
			recipe = mod_name..":"..material.name.."_gate_slot",
			burntime = burn_time * 2,
		})
		minetest.register_craft({
			type = "fuel",
			recipe = mod_name..":"..material.name.."_gate_slot_reverse",
			burntime = burn_time * 2,
		})	
	end
end

castle_gates.register_gate_slot_alias = function(old_mod_name, old_material_name, new_mod_name, new_material_name)
	minetest.register_alias(old_mod_name..":"..old_material_name.."_gate_slot",			new_mod_name..":"..new_material_name.."_gate_slot")
	minetest.register_alias(old_mod_name..":"..old_material_name.."_gate_slot_reverse",	new_mod_name..":"..new_material_name.."_gate_slot_reverse")
end
castle_gates.register_gate_slot_alias_force = function(old_mod_name, old_material_name, new_mod_name, new_material_name)
	minetest.register_alias_force(old_mod_name..":"..old_material_name.."_gate_slot",			new_mod_name..":"..new_material_name.."_gate_slot")
	minetest.register_alias_force(old_mod_name..":"..old_material_name.."_gate_slot_reverse",	new_mod_name..":"..new_material_name.."_gate_slot_reverse")
end

for _, material in pairs(materials) do
	castle_gates.register_gate_slot(material)
end

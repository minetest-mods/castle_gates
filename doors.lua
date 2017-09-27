-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

if minetest.get_modpath("doors") then
	doors.register("castle_gates:oak_door", {
		tiles = {{ name = "castle_door_oak.png", backface_culling = true }},
		description = S("Oak Door"),
		inventory_image = "castle_oak_door_inv.png",
		protected = true,
		groups = { choppy = 2, door = 1 },
		sounds = default.node_sound_wood_defaults(),
		recipe = {
			{"default:tree", "default:tree"},
			{"default:tree", "default:tree"},
			{"default:tree", "default:tree"},
		}
	})

	local door_recipe
	if minetest.get_modpath("xpanes") then
		door_recipe = {
			{"xpanes:jailbars_flat", "xpanes:jailbars_flat"},
			{"xpanes:jailbars_flat", "xpanes:jailbars_flat"},
			{"xpanes:jailbars_flat", "xpanes:jailbars_flat"},
		}
	else
		door_recipe = {
			{"default:steel_ingot", ""},
			{"", "default:steel_ingot"},
			{"default:steel_ingot", ""},
		}
	end
	
	doors.register("castle_gates:jail_door", {
		tiles = {{ name = "castle_door_jail.png", backface_culling = true }},
		description = S("Jail Door"),
		inventory_image = "castle_jail_door_inv.png",
		protected = true,
		groups = { cracky = 2, door = 1, flow_through = 1},
		sound_open = "doors_steel_door_open",
		sound_close = "doors_steel_door_close",
		recipe = door_recipe,
	})
	
	minetest.register_alias("castle:oak_door_a", "castle_gates:oak_door_a")
	minetest.register_alias("castle:oak_door_b", "castle_gates:oak_door_b")
	minetest.register_alias("castle:jail_door_a", "castle_gates:jail_door_a")
	minetest.register_alias("castle:jail_door_b", "castle_gates:jail_door_b")
end

if minetest.get_modpath("xpanes") then
	xpanes.register_pane("jailbars", {
		description = S("Jail Bars"),
		tiles = {"castle_jailbars.png"},
		drawtype = "airlike",
		paramtype = "light",
		textures = {"castle_jailbars.png", "castle_jailbars.png", "xpanes_space.png"},
		inventory_image = "castle_jailbars.png",
		wield_image = "castle_jailbars.png",
		sounds = default.node_sound_metal_defaults(),
		groups = {cracky=1, pane=1, flow_through=1},
		recipe = {
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
			{"default:steel_ingot", "",                    "default:steel_ingot"},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}},
	})
end

for i = 1, 15 do
	minetest.register_alias("castle:jailbars_"..i, "xpanes:jailbars_"..i)
end
minetest.register_alias("castle:jailbars", "xpanes:jailbars")

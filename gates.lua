local S = minetest.get_translator("castle_gates")

minetest.register_alias("castle_gates:gate_edge", "castle_gates:wood_gate_edge")
minetest.register_alias("castle_gates:gate_edge_handle", "castle_gates:wood_gate_edge_handle")
minetest.register_alias("castle_gates:gate_hinge", "castle_gates:wood_gate_hinge")
minetest.register_alias("castle_gates:gate_panel", "castle_gates:wood_gate_panel")
minetest.register_alias("castle_gates:portcullis_bars", "castle_gates:wood_portcullis_bars")
minetest.register_alias("castle_gates:portcullis_bars_bottom", "castle_gates:wood_portcullis_bars_bottom")

local function register_gates(
    node_prefix, material_description, material_texture, gate_groups, gate_sounds, portcullis_recipe, panel_recipe
)
    local portcullis_groups = { castle_gate = 1, flow_through = 1 }
    local panel_groups = { castle_gate = 1 }
    for group, val in pairs(gate_groups) do
        portcullis_groups[group] = val
        panel_groups[group] = val
    end

    minetest.register_node("castle_gates:" .. node_prefix .. "_portcullis_bars", {
        drawtype = "nodebox",
        description = S("@1 Portcullis Bars", material_description),
        _doc_items_longdesc = castle_gates.doc.portcullis_bars_longdesc,
        _doc_items_usagehelp = castle_gates.doc.portcullis_bars_usagehelp,
        groups = portcullis_groups,
        tiles = {
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_portcullis_mask.png)",
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_portcullis_mask.png)",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_portcullis_mask.png)",
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_portcullis_mask.png)",
        },
        sounds = gate_sounds,
        paramtype = "light",
        paramtype2 = "facedir",
        node_box = {
            type = "fixed",
            fixed = {
                { -0.125, -0.5, -0.5, 0.125, 0.5, -0.25 }, -- middle bar
                { -0.5, -0.5, -0.5, -0.375, 0.5, -0.25 }, -- side bar
                { 0.375, -0.5, -0.5, 0.5, 0.5, -0.25 }, -- side bar
                { -0.375, 0.1875, -0.4375, 0.375, 0.3125, -0.3125 }, -- crosspiece
                { -0.375, -0.3125, -0.4375, 0.375, -0.1875, -0.3125 }, -- crosspiece
            }
        },
        on_rightclick = castle_gates.trigger_gate,
    })

    minetest.register_node("castle_gates:" .. node_prefix .. "_portcullis_bars_bottom", {
        drawtype = "nodebox",
        description = S("@1 Portcullis Bottom", material_description),
        _doc_items_longdesc = castle_gates.doc.portcullis_bars_bottom_longdesc,
        _doc_items_usagehelp = castle_gates.doc.portcullis_bars_bottom_usagehelp,
        groups = portcullis_groups,
        tiles = {
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_portcullis_mask.png)",
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_portcullis_mask.png)",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_portcullis_mask.png)",
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_portcullis_mask.png)",
        },
        sounds = gate_sounds,
        paramtype = "light",
        paramtype2 = "facedir",
        node_box = {
            type = "fixed",
            fixed = {
                { -0.125, -0.5, -0.5, 0.125, 0.5, -0.25 }, -- middle bar
                { -0.5, -0.5, -0.5, -0.375, 0.5, -0.25 }, -- side bar
                { 0.375, -0.5, -0.5, 0.5, 0.5, -0.25 }, -- side bar
                { -0.375, 0.1875, -0.4375, 0.375, 0.3125, -0.3125 }, -- crosspiece
                { -0.375, -0.3125, -0.4375, 0.375, -0.1875, -0.3125 }, -- crosspiece
                { -0.0625, -0.5, -0.4375, 0.0625, -0.625, -0.3125 }, -- peg
                { 0.4375, -0.5, -0.4375, 0.5, -0.625, -0.3125 }, -- peg
                { -0.5, -0.5, -0.4375, -0.4375, -0.625, -0.3125 }, -- peg
            }
        },
        _gate_edges = { bottom = true },
        on_rightclick = castle_gates.trigger_gate,
    })

    minetest.register_craft({
        output = "castle_gates:" .. node_prefix .. "_portcullis_bars 3",
        recipe = portcullis_recipe,
    })

    minetest.register_craft({
        output = "castle_gates:" .. node_prefix .. "_portcullis_bars",
        recipe = {
            { "castle_gates:" .. node_prefix .. "_portcullis_bars_bottom" }
        },
    })

    minetest.register_craft({
        output = "castle_gates:" .. node_prefix .. "_portcullis_bars_bottom",
        recipe = {
            { "castle_gates:" .. node_prefix .. "_portcullis_bars" }
        },
    })

    --------------------------------------------------------------------------------------------------------------

    minetest.register_craft({
        output = "castle_gates:" .. node_prefix .. "_gate_panel 8",
        recipe = panel_recipe,
    })

    minetest.register_node("castle_gates:" .. node_prefix .. "_gate_panel", {
        drawtype = "nodebox",
        description = S("@1 Gate Door", material_description),
        _doc_items_longdesc = castle_gates.doc.gate_panel_longdesc,
        _doc_items_usagehelp = castle_gates.doc.gate_panel_usagehelp,
        groups = panel_groups,
        tiles = {
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
        },
        sounds = gate_sounds,
        paramtype = "light",
        paramtype2 = "facedir",
        node_box = {
            type = "fixed",
            fixed = {
                { -0.5, -0.5, -0.5, 0.5, 0.5, -0.25 },
            }
        },
        on_rightclick = castle_gates.trigger_gate,
    })

    minetest.register_craft({
        output = "castle_gates:" .. node_prefix .. "_gate_edge",
        type = "shapeless",
        recipe = { "castle_gates:" .. node_prefix .. "_gate_panel" },
    })

    minetest.register_node("castle_gates:" .. node_prefix .. "_gate_edge", {
        drawtype = "nodebox",
        description = S("@1 Gate Door Edge", material_description),
        _doc_items_longdesc = castle_gates.doc.gate_edge_longdesc,
        _doc_items_usagehelp = castle_gates.doc.gate_edge_usagehelp,
        groups = panel_groups,
        tiles = {
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90",
            material_texture .. "^[transformR90^(default_coal_block.png^[mask:castle_door_edge_mask.png^[transformFX)",
            material_texture .. "^[transformR90^(default_coal_block.png^[mask:castle_door_edge_mask.png)",
        },
        sounds = gate_sounds,
        paramtype = "light",
        paramtype2 = "facedir",
        node_box = {
            type = "fixed",
            fixed = {
                { -0.5, -0.5, -0.5, 0.5, 0.5, -0.25 },
            }
        },
        _gate_edges = { right = true },
        on_rightclick = castle_gates.trigger_gate,
    })

    minetest.register_craft({
        output = "castle_gates:" .. node_prefix .. "_gate_edge_handle",
        type = "shapeless",
        recipe = { "castle_gates:" .. node_prefix .. "_gate_edge" },
    })

    minetest.register_craft({
        output = "castle_gates:" .. node_prefix .. "_gate_panel",
        type = "shapeless",
        recipe = { "castle_gates:" .. node_prefix .. "_gate_edge_handle" },
    })

    minetest.register_node("castle_gates:" .. node_prefix .. "_gate_edge_handle", {
        drawtype = "nodebox",
        description = S("@1 Gate Door With Handle", material_description),
        _doc_items_longdesc = castle_gates.doc.gate_edge_handle_longdesc,
        _doc_items_usagehelp = castle_gates.doc.gate_edge_handle_usagehelp,
        groups = panel_groups,
        tiles = {
            "castle_steel.png^(" .. material_texture .. "^[mask:castle_door_side_mask.png^[transformR90)",
            "castle_steel.png^(" .. material_texture .. "^[mask:castle_door_side_mask.png^[transformR270)",
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:castle_door_side_mask.png)",
            "castle_steel.png^(" .. material_texture .. "^[transformR90^[mask:(castle_door_side_mask.png" ..
                "^[transformFX))",
            material_texture .. "^[transformR90^(default_coal_block.png^[mask:castle_door_edge_mask.png" ..
                "^[transformFX)^(castle_steel.png^[mask:castle_door_handle_mask.png^[transformFX)",
            material_texture .. "^[transformR90^(default_coal_block.png^[mask:castle_door_edge_mask.png)" ..
                "^(castle_steel.png^[mask:castle_door_handle_mask.png)",
        },
        sounds = gate_sounds,
        paramtype = "light",
        paramtype2 = "facedir",
        node_box = {
            type = "fixed",
            fixed = {
                { -0.5, -0.5, -0.5, 0.5, 0.5, -0.25 },
                { 4 / 16, -4 / 16, -2 / 16, 6 / 16, 4 / 16, -3 / 16 },
                { 4 / 16, -4 / 16, -9 / 16, 6 / 16, 4 / 16, -10 / 16 },
                { 4 / 16, -4 / 16, -9 / 16, 6 / 16, -3 / 16, -3 / 16 },
                { 4 / 16, 4 / 16, -9 / 16, 6 / 16, 3 / 16, -3 / 16 },
            }
        },
        _gate_edges = { right = true },
        on_rightclick = castle_gates.trigger_gate,
    })


    ------------------------------------------------------------------------------

    minetest.register_craft({
        output = "castle_gates:" .. node_prefix .. "_gate_hinge 3",
        recipe = {
            { "", "castle_gates:" .. node_prefix .. "_gate_panel", "" },
            { "default:steel_ingot", "castle_gates:" .. node_prefix .. "_gate_panel", "" },
            { "", "castle_gates:" .. node_prefix .. "_gate_panel", "" }
        },
    })

    minetest.register_node("castle_gates:" .. node_prefix .. "_gate_hinge", {
        drawtype = "nodebox",
        description = S("@1 Gate Door With Hinge", material_description),
        _doc_items_longdesc = castle_gates.doc.gate_hinge_longdesc,
        _doc_items_usagehelp = castle_gates.doc.gate_hinge_usagehelp,
        groups = panel_groups,
        tiles = {
            material_texture .. "^[transformR90",
        },
        sounds = gate_sounds,
        paramtype = "light",
        paramtype2 = "facedir",

        node_box = {
            type = "fixed",
            fixed = {
                { -0.5, -0.5, -0.5, 0.5, 0.5, -0.25 },
                { -10 / 16, -4 / 16, -10 / 16, -6 / 16, 4 / 16, -6 / 16 },
            }
        },
        collision_box = {
            type = "fixed",
            fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, -0.25 },
        },

        _gate_hinge = { axis = "top", offset = { "front", "left" } },
        on_rightclick = castle_gates.trigger_gate,
    })

end

register_gates("wood", S("Wooden"), "default_wood.png", { choppy = 1 }, default.node_sound_wood_defaults(),
    {
        { "group:wood", "default:steel_ingot", "group:wood" },
        { "group:wood", "default:steel_ingot", "group:wood" },
        { "group:wood", "default:steel_ingot", "group:wood" },
    },
    {
        { "stairs:slab_wood", "stairs:slab_wood", "" },
        { "stairs:slab_wood", "stairs:slab_wood", "" },
    }
)

register_gates("steel", S("Steel"), "default_steel_block.png", { cracky = 1, level = 2 },
    default.node_sound_metal_defaults(),
    {
        { "", "default:steel_ingot", "" },
        { "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" },
        { "", "default:steel_ingot", "" },
    },
    {
        { "stairs:slab_steelblock", "stairs:slab_steelblock", "" },
        { "stairs:slab_steelblock", "stairs:slab_steelblock", "" },
    }
)

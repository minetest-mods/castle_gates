castle_gates.doc = {}

if not minetest.get_modpath("doc") then
	return
end

-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

castle_gates.doc.portcullis_bars_longdesc = S("Heavy wooden bars designed to prevent entry even to siege equipment.")
castle_gates.doc.portcullis_bars_usagehelp = S("Place these bars in a structure together and they will slide as a unified gate when clicked on.")

castle_gates.doc.portcullis_bars_bottom_longdesc = S("The bottom edge of a portcullis gate, with knobs to lock securely into the floor.")
castle_gates.doc.portcullis_bars_bottom_usagehelp = S("This block can be used to define the edge of a portcullius that meets up with another gate, should you have an arrangement like that. Otherwise it's just decorative.")

castle_gates.doc.gate_panel_longdesc = S("A basic gate panel.")
castle_gates.doc.gate_panel_usagehelp = S("This gate segment will move in unison with adjoining gate segments when right-clicked.")

castle_gates.doc.gate_edge_longdesc = S("A gate panel with a defined edge.")
castle_gates.doc.gate_edge_usagehelp = S("The darkened edge of this panel marks the edge of the gate it's a part of. You can use these when building double doors to ensure the two parts swing separately, for example. Note that edges aren't strictly necessary for gates that stand alone.")

castle_gates.doc.gate_edge_handle_longdesc = S("A gate edge with a handle.")
castle_gates.doc.gate_edge_handle_usagehelp = S("The handle is basically decorative, a door this size can be swung by clicking anywhere on it. But the darkened edge of this panel is useful for defining the edge of a gate when it abuts a partner to the side.")

castle_gates.doc.gate_hinge_longdesc = S("A hinged gate segment that allows a gate to swing.")
castle_gates.doc.gate_hinge_usagehelp = S("If you have more than one hinge in your gate, make sure the hinges line up correctly otherwise the gate will not be able to swing. The hinge is the protruding block along the edge of the gate panel.")

castle_gates.doc.gate_slot_longdesc = S("A block with a slot to allow an adjacent sliding gate through.")
castle_gates.doc.gate_slot_usagehelp = S("This block is designed to extend into a neighboring node that a sliding gate passes through, to provide a tight seal for the gate to move through without allowing anything else to squeeze in.")

castle_gates.doc.gate_slot_reverse_longdesc = S("A block that extends into an adjacent node to provide a tight seal for a large gate.")
castle_gates.doc.gate_slot_reverse_usagehelp = S("Two nodes cannot occupy the same space, but this block extends into a neighboring node's space to allow for gates to form a tight seal. It can be used with sliding gates or swinging gates.")

doc.add_category("castle_gates",
{
	name = S("Gates"),
	description = S("Gates are large multi-node constructions that swing on hinges or slide out of the way when triggered."),
	build_formspec = doc.entry_builders.text_and_gallery,
})

doc.add_entry("castle_gates", "construction", {
	name = S("Gate construction"),
	data = { text =
S("Gates are multi-node constructions, usually (though not always) consisting of multiple node types that fit together into a unified whole. The orientation of gate nodes is significant, so a screwdriver will be a helpful tool when constructing gates."
.."\n\n"..
"A gate's extent is determined by a \"flood fill\" operation. When you trigger a gate block, all compatible neighboring blocks will be considered part of the same structure and will move in unison. Only gate blocks that are aligned with each other will be considered part of the same gate. If you wish to build adjoining gates (for example, a large pair of double doors that meet in the center) you'll need to make use of gate edge blocks to prevent it all from being considered one big door. Note that if your gate does not abut any other gates you don't actually need to define its edges this way - you don't have to use edge blocks in this case."
.."\n\n"..
"If a gate has no hinge nodes it will be considered a sliding gate. When triggered, the gate code will search for a direction that the gate can slide in and will move it in that direction at a rate of one block-length per second. Once it reaches an obstruction it will stop, and when triggered again it will try sliding in the opposite direction."
.."\n\n"..
"If a gate has hinge nodes then triggering it will cause the gate to try swinging around the hinge. If the gate has multiple hinges and they don't line up properly the gate will be unable to move. Note that the gate can only exist in 90-degree increments of orientation, but the gate still looks for obstructions in the region it is swinging through and will not swing if there's something in the way.")
}})
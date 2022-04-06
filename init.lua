if not minetest.get_translator then
	error("castle_gates requires Minetest 5.0.0 or newer")
end

castle_gates = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/doc.lua")
dofile(modpath.."/gate_functions.lua")
dofile(modpath.."/gate_slots.lua")
dofile(modpath.."/gates.lua")
dofile(modpath.."/doors.lua")

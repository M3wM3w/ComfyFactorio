local string_sub = string.sub

local balance_functions = {
	["land-mine"] = function(force_name)
		game.forces[force_name].set_ammo_damage_modifier("landmine", -0.6)
	end,
	["stronger-explosives"] = function(force_name)						
		game.forces[force_name].set_ammo_damage_modifier("landmine", -0.6)
	end,
}

local function on_research_finished(event)
	local research_name = event.research.name
	local force_name = event.research.force.name		
	local key
	for b = 1, string.len(research_name), 1 do
		key = string_sub(research_name, 0, b)
		if balance_functions[key] then
			balance_functions[key](force_name)
			return
		end
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_research_finished, on_research_finished)


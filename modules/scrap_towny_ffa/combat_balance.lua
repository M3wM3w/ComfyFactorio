local string_sub = string.sub

-- ammo damage modifiers are static values that increase with research
-- modifier is multiplied by base damage and then added to damage, so a negative value will reduce base damage and a positive value will increase damage
local balance_functions = {
	["land-mine"] = function(force_name)
		-- landmines normally have a modifier of 0, so have them start at 25% of normal
		game.forces[force_name].set_ammo_damage_modifier("landmine", -0.75)
	end,
	["military-2"] = function(force_name)
		-- grenades normally have a modifier of 0, so have them start at 50% of normal
		game.forces[force_name].set_ammo_damage_modifier("grenade", -0.5)
	end,
	["military-4"] = function(force_name)
		-- cluster-grenades normally have a modifier of 0, so have them start at 50% of normal
		game.forces[force_name].set_ammo_damage_modifier("cluster-grenade", -0.5)
	end,
	["stronger-explosives"] = function(research_name, force_name)
		-- landmines should never increase in damage with stronger explosives
		game.forces[force_name].set_ammo_damage_modifier("landmine", -0.75)
		-- allow grenades to increase by 10%
		game.forces[force_name].set_ammo_damage_modifier("grenade", game.forces[force_name].get_ammo_damage_modifier("grenade") + 0.1)
		game.forces[force_name].set_ammo_damage_modifier("cluster-grenade", game.forces[force_name].get_ammo_damage_modifier("cluster-grenade") + 0.1)
	end,
}

local function on_research_finished(event)
	local research_name = event.research.name
	local force_name = event.research.force.name		
	local key
	for b = 1, string.len(research_name), 1 do
		key = string_sub(research_name, 0, b)
		if balance_functions[key] then
			balance_functions[key](research_name, force_name)
			return
		end
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_research_finished, on_research_finished)


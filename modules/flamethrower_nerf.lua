--Flamethrower Turret Nerf
local function on_research_finished(event)
	local research = event.research
	local force_name = research.force.name
	if research.name == "military" then
		if not global.flamethrower_damage then global.flamethrower_damage = {} end
		global.flamethrower_damage[force_name] = -0.50
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.flamethrower_damage[force_name])
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.flamethrower_damage[force_name])
	end

	if string.sub(research.name, 0, 18) == "refined-flammables" then
		global.flamethrower_damage[force_name] = global.flamethrower_damage[force_name] + 0.10
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.flamethrower_damage[force_name])
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.flamethrower_damage[force_name])
	end
end

local event = require 'utils.event'
event.add(defines.events.on_research_finished, on_research_finished)

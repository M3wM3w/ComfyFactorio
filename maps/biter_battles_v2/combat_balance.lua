local Public = {}

local string_sub = string.sub

local balance_functions = {
	["flamethrower"] = function(force_name)
		global.combat_balance[force_name].flamethrower_damage = -0.6
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.combat_balance[force_name].flamethrower_damage)
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.combat_balance[force_name].flamethrower_damage)
	end,
	["refined-flammables"] = function(force_name)
		global.combat_balance[force_name].flamethrower_damage = global.combat_balance[force_name].flamethrower_damage + 0.05
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.combat_balance[force_name].flamethrower_damage)								
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.combat_balance[force_name].flamethrower_damage)
	end,
	["land-mine"] = function(force_name)
		if not global.combat_balance[force_name].land_mine then global.combat_balance[force_name].land_mine = -0.75 end
		game.forces[force_name].set_ammo_damage_modifier("landmine", global.combat_balance[force_name].land_mine)
	end,
	["stronger-explosives"] = function(force_name)
		if not global.combat_balance[force_name].land_mine then global.combat_balance[force_name].land_mine = -0.75 end
		global.combat_balance[force_name].land_mine = global.combat_balance[force_name].land_mine + 0.05								
		game.forces[force_name].set_ammo_damage_modifier("landmine", global.combat_balance[force_name].land_mine)
	end,
	["military"] = function(force_name)
		global.combat_balance[force_name].shotgun = 1
		game.forces[force_name].set_ammo_damage_modifier("shotgun-shell", global.combat_balance[force_name].shotgun)
	end,
}

function Public.research_finished(event)
	local research_name = event.research.name
	local force_name = event.research.force.name		
	local key
	for b = 1, string.len(research_name), 1 do
		key = string_sub(research_name, 0, b)
		if balance_functions[key] then
			if not global.combat_balance[force_name] then global.combat_balance[force_name] = {} end
			balance_functions[key](force_name)
			return
		end
	end
end

return Public
local Public = {}
local math_random = math.random


function Public.add_unit(force_name,unit_number, unit)
	global.map_forces[force_name].units[unit_number] = unit
end

function Public.on_buy_wave(surface, force, tier)
	if tier == "red" or tier == "green" then
		local random_biter = math.random(5,9)
		for i = 1, random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "small-biter", position = {global.map_forces[force].spawn.x + i, global.map_forces[force].spawn.y} , force = game.forces[force]}
				global.map_forces[force].units[unit.unit_number] = unit
		end
		for i = 1, 10-random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "small-spitter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
				global.map_forces[force].units[unit.unit_number] = unit
		end
	  return
	end
	if tier=="grey" then
		local random_biter=math.random(5,9)
		for i = 1, random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "medium-biter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
		for i = 1, 10-random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "medium-spitter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
	  return
	end
	if tier=="blue" then
		local random_biter = math.random(5,9)
		for i = 1, random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "big-biter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
		for i = 1, 10-random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "big-spitter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
		return
	end
	if tier=="purple" or tier=="yellow" then
		local random_biter = math.random(5,9)
		for i = 1, random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "-biter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
		for i = 1, 10-random_biter, 1 do
			local unit = game.surfaces[surface].create_entity{name = "behemoth-spitter", position = {global.map_forces[force].spawn.x + i,global.map_forces[force].spawn.y}, force = game.forces[force]}
			global.map_forces[force].units[unit.unit_number] = unit
		end
	  return
	end
end

function Public.buy_worm_turret(surface,force_name, dist, player, player_nb_sp, nb_sp_price, sp)
	local size_table_turret = #global.map_forces[force_name].worm_turrets_positions
	if dist == "All" then
		local player_sp_count = player_nb_sp
		count = 0
		for k, pos in pairs(global.map_forces[force_name].worm_turrets_positions) do
			local turret = surface.find_entity('small-worm-turret',{pos.x,pos.y})
			if turret == nil and player_sp_count >= nb_sp_price then
				local turrets = surface.find_entities_filtered{position = {pos.x,pos.y}, name ={'medium-worm-turret','big-worm-turret','behemoth-worm-turret'}}
				if #turrets ==0 then
					local position = surface.find_non_colliding_position("big-worm-turret", {pos.x,pos.y}, 5, 1)
					if not position  then position = {pos.x,pos.y} end
					surface.create_entity({name = "small-worm-turret", position = {position.x,position.y}, force = force_name})
					player.remove_item({name=sp, count=nb_sp_price})
					player_sp_count = player_sp_count - nb_sp_price
					count = count + 1
				end
			end
		end
		if count == 0 then
			return false
		else
			return true
		end
	elseif dist == "Farthest" then
		for i=size_table_turret,1,-1 do
			local pos = global.map_forces[force_name].worm_turrets_positions[i]
			local turret = surface.find_entity('small-worm-turret',{pos.x,pos.y})
			if turret == nil and player_nb_sp >= nb_sp_price then
				local turrets = surface.find_entities_filtered{position = {pos.x,pos.y}, name ={'medium-worm-turret','big-worm-turret','behemoth-worm-turret'}}
				if #turrets ==0 then
					local position = surface.find_non_colliding_position("big-worm-turret", {pos.x,pos.y}, 5, 1)
					if not position  then position = {pos.x,pos.y} end
					surface.create_entity({name = "small-worm-turret", position = {position.x,position.y}, force = force_name})
					player.remove_item({name=sp, count=nb_sp_price})
					return true
				end
			end
		end
		return false
	elseif dist == "Closest" then
		for i=1,size_table_turret,1 do
			local pos = global.map_forces[force_name].worm_turrets_positions[i]
			local turret = surface.find_entity('small-worm-turret',{pos.x,pos.y})
			if turret == nil and player_nb_sp >= nb_sp_price then
				local turrets = surface.find_entities_filtered{position = {pos.x,pos.y}, name ={'medium-worm-turret','big-worm-turret','behemoth-worm-turret'}}
				if #turrets ==0 then
					local position = surface.find_non_colliding_position("big-worm-turret", {pos.x,pos.y}, 5, 1)
					if not position  then position = {pos.x,pos.y} end
					surface.create_entity({name = "small-worm-turret", position = {position.x,position.y}, force = force_name})
					player.remove_item({name=sp, count=nb_sp_price})
					return true
				end
			end
		end
		return false
	end
end

function Public.upgrade_worm_turret(surface, force_name, dist, player, player_nb_sp, nb_sp_price, sp, tier)
	local table_upgrade = {
		["medium-worm-turret"] = "small-worm-turret",
		["big-worm-turret"] = "medium-worm-turret",
		["behemoth-worm-turret"] = "big-worm-turret"
	}
	local size_table_turret = #global.map_forces[force_name].worm_turrets_positions
	print(size_table_turret)
	if dist == "All" then
		local player_sp_count = player_nb_sp
		count = 0
		for k, pos in pairs(global.map_forces[force_name].worm_turrets_positions) do
			local turret = surface.find_entity(table_upgrade[tier],{pos.x,pos.y})
			if turret ~= nil and player_nb_sp >= nb_sp_price then
				turret.destroy()
				local position = surface.find_non_colliding_position("big-worm-turret", {pos.x,pos.y}, 5, 1)
				if not position  then position = {pos.x,pos.y} end
				surface.create_entity({name = tier, position = {position.x,position.y}, force = force_name})
				player.remove_item({name=sp, count=nb_sp_price})
				player_sp_count = player_sp_count - nb_sp_price
				count = count + 1
			else end
		end
		if count == 0 then
			return false
		else
			return true
		end
	elseif dist == "Farthest" then
		for i = #global.map_forces[force_name].worm_turrets_positions, 1, -1 do
			local turret = surface.find_entity(table_upgrade[tier],{global.map_forces[force_name].worm_turrets_positions[i].x,global.map_forces[force_name].worm_turrets_positions[i].y})
			if turret ~= nil and player_nb_sp >= nb_sp_price then
				turret.destroy()
				local position = surface.find_non_colliding_position("big-worm-turret", {global.map_forces[force_name].worm_turrets_positions[i].x,global.map_forces[force_name].worm_turrets_positions[i].y}, 5, 1)
				if not position  then position = {pos.x,pos.y} end
				surface.create_entity({name = tier, position = {position.x,position.y}, force = force_name})
				player.remove_item({name=sp, count=nb_sp_price})
				return true
			else end
		end
		return false
	elseif dist == "Closest" then
		for k, pos in pairs(global.map_forces[force_name].worm_turrets_positions) do
			local turret = surface.find_entity(table_upgrade[tier],{pos.x,pos.y})
			if turret ~= nil and player_nb_sp >= nb_sp_price then
				turret.destroy()
				local position = surface.find_non_colliding_position("big-worm-turret", {pos.x,pos.y}, 5, 1)
				if not position  then position = {pos.x,pos.y} end
				surface.create_entity({name = tier, position = {position.x,position.y}, force = force_name})
				player.remove_item({name=sp, count=nb_sp_price})
				return true
			else end
		end
		return false
	end
end

function Public.buy_extra_life(force_name)
		local force_index = game.forces[force_name].index
		global.biter_reanimator.forces[force_index] = global.biter_reanimator.forces[force_index] +1
end

return Public

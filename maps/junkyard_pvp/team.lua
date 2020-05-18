local Public = {}
local math_random = math.random

Public.starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['rail'] = 16}

function Public.set_force_attributes()
	game.forces.west.set_friend("spectator", true)
	game.forces.east.set_friend("spectator", true)
	game.forces.spectator.set_friend("west", true)
	game.forces.spectator.set_friend("east", true)
	game.forces.west.share_chart = true
	game.forces.east.share_chart = true
	for _, force_name in pairs({"west", "east"}) do
		game.forces[force_name].research_queue_enabled = true
		game.forces[force_name].technologies["artillery"].enabled = false
		game.forces[force_name].technologies["artillery-shell-range-1"].enabled = false					
		game.forces[force_name].technologies["artillery-shell-speed-1"].enabled = false
		game.forces[force_name].technologies["railway"].researched = true
		global.map_forces[force_name].unit_health_boost = 1
		global.map_forces[force_name].unit_count = 0	
		global.map_forces[force_name].max_unit_count = 1024
		global.map_forces[force_name].player_count = 0
	end	
end

function Public.create_forces()
	game.create_force("west")
	game.create_force("east")
	game.create_force("spectator")
end

function Public.assign_random_force_to_active_players()
	local player_indexes = {}
	for _, player in pairs(game.connected_players) do
		if player.force.name ~= "spectator" then	player_indexes[#player_indexes + 1] = player.index end
	end
	if #player_indexes > 1 then table.shuffle_table(player_indexes) end
	local a = math_random(0, 1)
	for key, player_index in pairs(player_indexes) do
		if key % 2 == a then
			game.players[player_index].force = game.forces.west
		else
			game.players[player_index].force = game.forces.east
		end
	end
end

function Public.assign_force_to_player(player)
	player.spectator = false
	if math_random(1, 2) == 1 then
		if #game.forces.east.connected_players > #game.forces.west.connected_players then
			player.force = game.forces.west
		else
			player.force = game.forces.east 
		end
	else
		if #game.forces.east.connected_players < #game.forces.west.connected_players then
			player.force = game.forces.east
		else
			player.force = game.forces.west 
		end
	end
end

function Public.teleport_player_to_active_surface(player)
	local surface = game.surfaces[global.active_surface_index]
	local position	
	if player.force.name == "spectator" then
		position = player.force.get_spawn_position(surface)
		position = {x = (position.x - 160) + math_random(0, 320), y = (position.y - 16) + math_random(0, 32)}
	else
		position = surface.find_non_colliding_position("character", player.force.get_spawn_position(surface), 48, 1)
		if not position then position = player.force.get_spawn_position(surface) end
	end
	player.teleport(position, surface)
end

function Public.put_player_into_random_team(player)
	if player.character then
		if player.character.valid then
			player.character.destroy()
		end
	end		
	player.character = nil
	player.set_controller({type=defines.controllers.god})
	player.create_character()
	for item, amount in pairs(Public.starting_items) do
		player.insert({name = item, count = amount})
	end
	global.map_forces[player.force.name].player_count = global.map_forces[player.force.name].player_count + 1
end

function Public.set_player_to_spectator(player)
	if player.character then player.character.die() end
	player.force = game.forces.spectator	
	player.character = nil
	player.spectator = true
	player.set_controller({type=defines.controllers.spectator})
end

return Public
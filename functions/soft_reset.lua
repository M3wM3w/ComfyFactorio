local Server = require 'utils.server'
local Modifers = require 'player_modifiers'

local Public = {}

local function reset_forces(new_surface, old_surface)
	for _, f in pairs(game.forces) do
		local spawn = {x = game.forces.player.get_spawn_position(old_surface).x, y = game.forces.player.get_spawn_position(old_surface).y}
		f.reset()
		for _, tech in pairs(f.technologies) do 
			f.set_saved_technology_progress(tech, 0)
		end
		f.reset_evolution()
		f.set_spawn_position(spawn, new_surface)
	end
end

local function teleport_players(surface)	
	for _, player in pairs(game.connected_players) do
		local spawn = player.force.get_spawn_position(surface)
		local chunk = {math.floor(spawn.x / 32), math.floor(spawn.y / 32)}
		if not surface.is_chunk_generated(chunk) then
			surface.request_to_generate_chunks(spawn, 1)
			surface.force_generate_chunk_requests()
		end		
		local pos = surface.find_non_colliding_position("character", spawn, 3, 0.5)
		player.teleport(pos, surface)
	end
end

local function equip_players(player_starting_items)
	for k, player in pairs(game.connected_players) do
		if player.character then	player.character.destroy()	end
		player.character = nil
		player.set_controller({type=defines.controllers.god})
		player.create_character()
		for item, amount in pairs(player_starting_items) do
			player.insert({name = item, count = amount})
		end
		Modifers.update_player_modifiers(player)
	end
end

function Public.soft_reset_map(old_surface, map_gen_settings, player_starting_items)
	if not global.soft_reset_counter then global.soft_reset_counter = 0 end
	if not global.original_surface_name then global.original_surface_name = old_surface.name end
	global.soft_reset_counter = global.soft_reset_counter + 1

	local new_surface = game.create_surface(global.original_surface_name .. "_" .. tostring(global.soft_reset_counter), map_gen_settings)
	new_surface.request_to_generate_chunks({0,0}, 1)
	new_surface.force_generate_chunk_requests()
	
	reset_forces(new_surface, old_surface)
	teleport_players(new_surface)
	equip_players(player_starting_items)
	
	game.delete_surface(old_surface)
	
	local message = table.concat({">> Welcome to ", global.original_surface_name, "!"})
	if global.soft_reset_counter > 1 then
		message = table.concat({">> The world has been reshaped, welcome to ", global.original_surface_name, " number ", tostring(global.soft_reset_counter), "!"})
	end
	game.print(message, {r=0.98, g=0.66, b=0.22})
	Server.to_discord_embed(message)
	
	return new_surface
end

return Public
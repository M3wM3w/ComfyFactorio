local Public = {}
local Constants = require 'maps.journey.constants'

function Public.deny_building(event)
    local entity = event.created_entity
    if not entity.valid then
        return
    end

	if not game.item_prototypes[entity.name] then return end
	
	if event.player_index then
		local player = game.players[event.player_index]
		if entity.position.x % 2 == 1 and entity.position.y % 2 == 1 and entity.name == 'stone-furnace' then
			local score_change = mark_mine(entity, player)
			Map_score.set_score(player, Map_score.get_score(player) + score_change)
			return
		end
		player.insert({name = entity.name, count = 1})
	else
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity.name, count = 1})
	end
	entity.destroy() 
end


function Public.deny_tile_building(surface, tiles)
    for _, placed_tile in pairs(tiles) do
		local hidden_tile = surface.get_tile(placed_tile.position).hidden_tile
		if hidden_tile then
			
		end
    end
end

local function is_mothership(position)
	if math.abs(position.x) > Constants.mothership_radius then return false end
	if math.abs(position.y) > Constants.mothership_radius then return false end
	local p = {x = position.x, y = position.y}
	if p.x > 0 then p.x = p.x + 1 end
	if p.y > 0 then p.y = p.y + 1 end
	local d = math.sqrt(p.x ^ 2 + p.y ^ 2)
	if d < Constants.mothership_radius then
		return true
	end	
end

function Public.on_mothership_chunk_generated(event)
	local left_top = event.area.left_top
	local surface = event.surface
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			if is_mothership(position) then
				table.insert(tiles, {name = "black-refined-concrete", position = position})
			else
				table.insert(tiles, {name = "out-of-map", position = position})
			end		
		end
	end
	surface.set_tiles(tiles, true)
end


function Public.reset(journey)
	if game.surfaces.mothership and game.surfaces.mothership.valid then
		game.delete_surface(game.surfaces.mothership)
	end
	
	journey.mothership_speed = 0.5
	journey.world_selectors = {}
	
	for i = 1, 3, 1 do
		journey.world_selectors[i] = {activation_level = 0}
	end
	
	journey.game_state = "create_mothership"
end

function Public.create_mothership(journey)
	local surface = game.create_surface("mothership", Constants.mothership_gen_settings)
	surface.request_to_generate_chunks({x = 0, y = 0}, 6)
	surface.force_generate_chunk_requests()
	journey.game_state = "draw_mothership"
end

function Public.draw_mothership(journey)
	local surface = game.surfaces.mothership
	
	for x = Constants.mothership_radius * -1, Constants.mothership_radius, 1 do
		for y = Constants.mothership_radius * -1, 0, 1 do
			local position = {x = x, y = y}
			
			if is_mothership(position) and surface.count_tiles_filtered({area = {{position.x - 1, position.y - 1}, {position.x + 2, position.y + 2}}, name = "out-of-map"}) > 0 then
				local e = surface.create_entity({name = "stone-wall", position = position})
				e.destructible = false			
			end			
		end
	end
	
	local tiles = {}
	for k, area in pairs(Constants.world_selector_areas) do
		for _, tile in pairs(surface.find_tiles_filtered({area = area})) do
			table.insert(tiles, {name = "orange-refined-concrete", position = tile.position})
		end
		
		journey.world_selectors[k].rectangles = {}

		local center = {x = area.left_top.x + Constants.world_selector_width * 0.5, y = area.left_top.y + Constants.world_selector_height * 0.5}
				
		local position = area.left_top
		local rectangle = rendering.draw_rectangle {
			width = 1,
			filled=true,
			surface = surface,
			left_top = position,
			right_bottom = {position.x + Constants.world_selector_width, position.y + Constants.world_selector_height},
			color = Constants.world_selector_colors[k],
			draw_on_ground = true,
			only_in_alt_mode = false
		}
		table.insert(journey.world_selectors[k].rectangles, rectangle)
				
	end
	surface.set_tiles(tiles, true)
	
	journey.game_state = "mothership"
end

function Public.teleport_players_to_mothership(journey)
	local surface = game.surfaces.mothership
	for _, player in pairs(game.connected_players) do
		if player.surface.name ~= "mothership" then		
			player.teleport(surface.find_non_colliding_position("character", {x = 0, y = 0}, 32, 0.5), surface)
			return
		end
	end
end

local function get_activation_level(surface, area)
	local total_player_count = #game.connected_players
	local player_count_in_area = surface.count_entities_filtered({area = area, name = "character"})
	local level = math.round(player_count_in_area / total_player_count, 3)
	level = level * 2
	if level > 1 then level = 1 end
	return level
end

local function animate_selectors(journey)
	local surface = game.surfaces.mothership
	for k, world_selector in pairs(journey.world_selectors) do
		local activation_level = get_activation_level(surface, Constants.world_selector_areas[k])
		if activation_level < 0.2 then activation_level = 0.2 end
		for _, rectangle in pairs(world_selector.rectangles) do
			local color = Constants.world_selector_colors[k]
			rendering.set_color(rectangle, {r = color.r * activation_level, g = color.g * activation_level, b = color.b * activation_level, a = 255})
		end
	end
end

function Public.mothership(journey)
	local surface = game.surfaces.mothership
	Public.teleport_players_to_mothership(journey)
	
	for c = 1, 16, 1 do
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "shotgun-pellet", position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = journey.mothership_speed})
	end
	for c = 1, 16, 1 do
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "piercing-shotgun-pellet", position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = journey.mothership_speed})
	end
	for c = 1, 2, 1 do
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "cannon-projectile", position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = journey.mothership_speed})
	end
	for c = 1, 1, 1 do
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "uranium-cannon-projectile", position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = journey.mothership_speed})
	end
	if math.random(1, 32) == 1 then		
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "explosive-uranium-cannon-projectile", position = position, target = {position[1], position[2] + Constants.mothership_radius * 3}, speed = journey.mothership_speed})	
	end
	
	
	animate_selectors(journey)
	
end

function Public.resetsfsf(journey)
    
end

function Public.resetsfsf(journey)
    
end

return Public
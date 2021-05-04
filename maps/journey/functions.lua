local Public = {}
local Constants = require 'maps.journey.constants'

function Public.mothership_message_queue(journey)
	local text = journey.mothership_messages[1]
	if not text then return end
	if text ~= "" then
		text = "[font=default-game][color=200,200,200]" .. text .. "[/color][/font]"
		text = "[font=heading-1][color=255,155,155]<Mothership> [/color][/font]" .. text
		game.print(text)
		--game.forces.player.play_sound{path="utility/armor_insert", volume_modifier = 1}
	end
	table.remove(journey.mothership_messages, 1)
end

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

function Public.draw_gui(journey)
	local surface = game.surfaces.nauvis
	local mgs = surface.map_gen_settings	
	local caption = "World - " .. journey.world_number
	local tooltip = ""
	for k, autoplace in pairs(mgs.autoplace_controls) do
		tooltip = tooltip .. Constants.modifiers[k][3] .. " - " .. math.floor(autoplace.frequency * 100) .. "%\n"
	end
	tooltip = tooltip .. "Cliff Interval - " .. math.round(mgs.cliff_settings.cliff_elevation_interval, 2) .. "\n"
	tooltip = tooltip .. "Water - " .. math.floor(mgs.water * 100) .. "%\n"
	tooltip = tooltip .. "Starting area - " .. math.floor(mgs.starting_area * 100) .. "%\n"
	tooltip = tooltip .. "Evolution Time Factor - " .. math.round(game.map_settings.enemy_evolution.time_factor * 25000000, 1) .. "%\n"
	tooltip = tooltip .. "Evolution Destroy Factor - " .. math.round(game.map_settings.enemy_evolution.destroy_factor * 50000, 1) .. "%\n"
	tooltip = tooltip .. "Evolution Pollution Factor - " .. math.round(game.map_settings.enemy_evolution.pollution_factor * 111100000, 1) .. "%\n"	
	
	for _, player in pairs(game.connected_players) do	
		if not player.gui.top.journey_button then
			local button = player.gui.top.add({type = "sprite-button", name = "journey_button", caption = ""})
			button.style.font = "heading-1"
			button.style.font_color = {222, 222, 222}
			button.style.minimal_height = 38
			button.style.minimal_width = 100
			button.style.padding = -2
		end
		local gui = player.gui.top.journey_button
		gui.caption = caption
		gui.tooltip = tooltip
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
	local seed = surface.map_gen_settings.seed
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
	journey.mothership_messages = {}
	journey.world_selectors = {}
	journey.world_number = 0
	
	for i = 1, 3, 1 do
		journey.world_selectors[i] = {activation_level = 0, renderings = {}}
	end
	
	journey.game_state = "create_mothership"
end

function Public.create_mothership(journey)
	local surface = game.create_surface("mothership", Constants.mothership_gen_settings)
	surface.request_to_generate_chunks({x = 0, y = 0}, 6)
	surface.force_generate_chunk_requests()
	surface.freeze_daytime = true
	journey.game_state = "draw_mothership"
end

function Public.draw_mothership(journey)
	local surface = game.surfaces.mothership
	
	local positions = {}
	for x = Constants.mothership_radius * -1, Constants.mothership_radius, 1 do
		for y = Constants.mothership_radius * -1, Constants.mothership_radius, 1 do
			local position = {x = x, y = y}
			if is_mothership(position) then table.insert(positions, position) end
		end
	end
	
	table.shuffle_table(positions)
	
	for _, position in pairs(positions) do	
		if surface.count_tiles_filtered({area = {{position.x - 1, position.y - 1}, {position.x + 2, position.y + 2}}, name = "out-of-map"}) > 0 then
			local e = surface.create_entity({name = "stone-wall", position = position})
			e.destructible = false	
		end
		if surface.count_tiles_filtered({area = {{position.x - 1, position.y - 1}, {position.x + 2, position.y + 2}}, name = "lab-dark-1"}) < 4 then
			surface.set_tiles({{name = "lab-dark-1", position = position}}, true)
		end					
	end

	for _, tile in pairs(surface.find_tiles_filtered({area = {{Constants.mothership_teleporter_position.x - 2, Constants.mothership_teleporter_position.y - 2}, {Constants.mothership_teleporter_position.x + 2, Constants.mothership_teleporter_position.y + 2}}})) do
		surface.set_tiles({{name = "lab-dark-1", position = tile.position}}, true)
	end

	for k, area in pairs(Constants.world_selector_areas) do
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
		
		local rectangle = rendering.draw_rectangle {
			width = 8,
			filled=false,
			surface = surface,
			left_top = position,
			right_bottom = {position.x + Constants.world_selector_width, position.y + Constants.world_selector_height},
			color = {r = 100, g = 100, b = 100, a = 255},
			draw_on_ground = true,
			only_in_alt_mode = false
		}		
	end
	
	for x = Constants.mothership_radius * -1, Constants.mothership_radius, 1 do
		for y = Constants.mothership_radius * -1, Constants.mothership_radius, 1 do
			local position = {x = x, y = y}
		end
	end

	for _ = 1, 5, 1 do
		local e = surface.create_entity({name = "compilatron", position = Constants.mothership_teleporter_position, force = "player"})
		e.destructible = false
	end

	journey.game_state = "set_world_selectors"
end

function Public.teleport_players_to_mothership(journey)
	local surface = game.surfaces.mothership
	for _, player in pairs(game.connected_players) do
		if player.surface.name ~= "mothership" then		
			player.teleport(surface.find_non_colliding_position("character", Constants.mothership_teleporter_position, 32, 0.5), surface)
			table.insert(journey.mothership_messages, "Welcome home " .. player.name .. "!")
			return
		end
	end
end

local function get_activation_level(surface, area)
	local player_count_in_area = surface.count_entities_filtered({area = area, name = "character"})	
	local player_count_for_max_activation = #game.connected_players * 0.66	
	local level = player_count_in_area / player_count_for_max_activation	
	level = math.round(level, 2)
	return level
end

local function animate_selectors(journey)
	for k, world_selector in pairs(journey.world_selectors) do
		local activation_level = journey.world_selectors[k].activation_level
		if activation_level < 0.2 then activation_level = 0.2 end
		if activation_level > 1 then activation_level = 1 end
		for _, rectangle in pairs(world_selector.rectangles) do
			local color = Constants.world_selector_colors[k]
			rendering.set_color(rectangle, {r = color.r * activation_level, g = color.g * activation_level, b = color.b * activation_level, a = 255})
		end
	end
end

local function draw_background(journey, surface)
	local speed = journey.mothership_speed
	for c = 1, 16 * speed, 1 do
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "shotgun-pellet", position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = speed})
	end
	for c = 1, 16 * speed, 1 do
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "piercing-shotgun-pellet", position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = speed})
	end
	for c = 1, 2 * speed, 1 do
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "cannon-projectile", position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = speed})
	end
	for c = 1, 1 * speed, 1 do
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "uranium-cannon-projectile", position = position, target = {position[1], position[2] + Constants.mothership_radius * 2}, speed = speed})
	end
	if math.random(1, 32) == 1 then		
		local position = Constants.particle_spawn_vectors[math.random(1, Constants.size_of_particle_spawn_vectors)]
		surface.create_entity({name = "explosive-uranium-cannon-projectile", position = position, target = {position[1], position[2] + Constants.mothership_radius * 3}, speed = speed})	
	end
end

function Public.set_world_selectors(journey)
	local surface = game.surfaces.mothership
	local modifier_names = {}
	for k, _ in pairs(Constants.modifiers) do
		table.insert(modifier_names, k)
	end		
	
	for k, world_selector in pairs(journey.world_selectors) do
		table.shuffle_table(modifier_names)
		world_selector.modifiers = {}
		local modifiers = world_selector.modifiers
		
		for i = 1, 4, 1 do
			local modifier = modifier_names[i]
			modifiers[i] = {modifier, math.random(Constants.modifiers[modifier][1], Constants.modifiers[modifier][2])}
		end
		for i = 5, 6, 1 do
			local modifier = modifier_names[i]
			modifiers[i] = {modifier, -1 * math.random(Constants.modifiers[modifier][1], Constants.modifiers[modifier][2])}
		end	
		
		local renderings = world_selector.renderings
		for k2, modifier in pairs(modifiers) do
			local position = Constants.world_selector_areas[k].left_top
			local text = ""
			if modifier[2] > 0 then text = text .. "+" end
			text = text .. modifier[2] .. "% "
			text = text .. Constants.modifiers[modifier[1]][3]
			
			local color
			if k2 < 5 then
				color = {200, 0, 0, 255}
			else
				color = {0, 200, 0, 255}
			end				
			
			renderings[k2] = rendering.draw_text{
				text = text,
				surface = surface,
				target = {position.x + Constants.world_selector_width * 0.5, position.y + k2 * 0.8 - 6},
				color = color,
				scale = 1.25,
				font = "default-large",
				alignment = "center",
				scale_with_zoom = false
			}
		end	
	end	
	journey.game_state = "mothership_world_selection"
end

function Public.mothership_world_selection(journey)
	local surface = game.surfaces.mothership
	
	local daytime = surface.daytime
	daytime = daytime - 0.025	
	if daytime < 0 then daytime = 0 end
	surface.daytime = daytime
	
	Public.teleport_players_to_mothership(journey)
	
	journey.mothership_teleporter_online = false
	journey.selected_world = false
	for i = 1, 3, 1 do
		local activation_level = get_activation_level(surface, Constants.world_selector_areas[i])
		journey.world_selectors[i].activation_level = activation_level
		if activation_level > 1 then
			journey.selected_world = i 
		end
	end
	
	if journey.selected_world then
		if not journey.mothership_advancing_to_world then
			table.insert(journey.mothership_messages, "Advancing to selected world.")
			--journey.mothership_advancing_to_world = game.tick + math.random(60 * 45, 60 * 75)
			journey.mothership_advancing_to_world = game.tick + math.random(60 * 5, 60 * 10)
		else
			local seconds_left = math.floor((journey.mothership_advancing_to_world - game.tick) / 60)
			if seconds_left <= 0 then
				journey.mothership_advancing_to_world = false
				table.insert(journey.mothership_messages, "Arriving at targeted destination!")
				journey.game_state = "mothership_arrives_at_world"
				return
			end
			if seconds_left % 10 == 0 then table.insert(journey.mothership_messages, "Estimated arrival in " .. seconds_left .. " seconds.") end
		end
		
		journey.mothership_speed = journey.mothership_speed + 0.1
		if journey.mothership_speed > 4 then journey.mothership_speed = 4 end
	else
		if journey.mothership_advancing_to_world then
			table.insert(journey.mothership_messages, "Aborting travling sequence.")
			journey.mothership_advancing_to_world = false
		end	
		journey.mothership_speed = journey.mothership_speed - 0.25
		if journey.mothership_speed < 0.35 then journey.mothership_speed = 0.35 end
	end
			
	draw_background(journey, surface)
	animate_selectors(journey)
end

function Public.mothership_arrives_at_world(journey)
	local surface = game.surfaces.mothership
	
	Public.teleport_players_to_mothership(journey)
	
	if journey.mothership_speed == 0.15 then
		journey.mothership_teleporter = surface.create_entity({name = "player-port", position = Constants.mothership_teleporter_position, force = "player"})
		table.insert(journey.mothership_messages, "[gps=" .. Constants.mothership_teleporter_position.x .. "," .. Constants.mothership_teleporter_position.y .. ",mothership] Teleporter deployed.")
		journey.mothership_teleporter.destructible = false
		journey.mothership_teleporter.minable = false
		
		for _ = 1, 16, 1 do table.insert(journey.mothership_messages, "") end
		table.insert(journey.mothership_messages, "[img=item/nuclear-fuel]Nuclear fuel depleted ;_;")
		for _ = 1, 16, 1 do table.insert(journey.mothership_messages, "") end
		table.insert(journey.mothership_messages, "Refuel via supply rocket required!")
		for _ = 1, 16, 1 do table.insert(journey.mothership_messages, "") end
		table.insert(journey.mothership_messages, "Good luck on your adventure! ^.^")
	
		for i = 1, 3, 1 do
			journey.world_selectors[i].activation_level = 0
		end
		animate_selectors(journey)
			
		journey.game_state = "create_the_world"
	else
		journey.mothership_speed = journey.mothership_speed - 0.15
	end
	
	if journey.mothership_speed < 0.15 then 
		journey.mothership_speed = 0.15
	end
		
	draw_background(journey, surface)
end

function Public.create_the_world(journey)
	local surface = game.surfaces.nauvis
	local mgs = surface.map_gen_settings
	
	mgs.peaceful_mode = false
	
	local modifiers = journey.world_selectors[journey.selected_world].modifiers
	for _, modifier in pairs(modifiers) do
		local m = (100 + modifier[2]) * 0.01
		local name = modifier[1]
		for _, autoplace in pairs({"iron-ore", "copper-ore", "uranium-ore", "coal", "stone", "crude-oil", "stone", "trees", "enemy-base"}) do
			if name == autoplace then
				for k, v in pairs(mgs.autoplace_controls[name]) do
					mgs.autoplace_controls[name][k] = mgs.autoplace_controls[name][k] * m
				end
				break
			end
		end	
		if name == "cliff_settings" then
			--smaller value = more cliffs
			local m2 = (100 - modifier[2]) * 0.01
			mgs.cliff_settings.cliff_elevation_interval = mgs.cliff_settings.cliff_elevation_interval * m2
			mgs.cliff_settings.cliff_elevation_0 = mgs.cliff_settings.cliff_elevation_0 * m2
		end
		if name == "water" then			
			mgs.water = mgs.water * m
		end
		if name == "starting_area" then			
			mgs.water = mgs.water * m					
		end
		for _, evo in pairs({"time_factor", "destroy_factor", "pollution_factor"}) do
			if name == evo then
				game.map_settings.enemy_evolution[name] = game.map_settings.enemy_evolution[name] * m
				break
			end
		end	
	end

	surface.map_gen_settings = mgs
    surface.clear(true)
	surface.request_to_generate_chunks({x = 0, y = 0}, 5)
	surface.force_generate_chunk_requests()

	journey.world_number = journey.world_number + 1
	
	Public.draw_gui(journey)
	
	journey.game_state = "place_teleporter_into_world"
end

function Public.place_teleporter_into_world(journey)
	local surface = game.surfaces.nauvis
	journey.nauvis_teleporter = surface.create_entity({name = "player-port", position = Constants.mothership_teleporter_position, force = "player"})
	journey.nauvis_teleporter.destructible = false
	journey.nauvis_teleporter.minable = false
	journey.mothership_teleporter_online = true
	journey.game_state = "make_it_night"
end

function Public.make_it_night(journey)
	local surface = game.surfaces.mothership
	local daytime = surface.daytime
	daytime = daytime + 0.02
	surface.daytime = daytime
	if daytime > 0.5 then
		for k, world_selector in pairs(journey.world_selectors) do
			for _, ID in pairs(world_selector.renderings) do
				rendering.destroy(ID)
			end
		end
		journey.game_state = "world" 
	end
end

function Public.world(journey)
	draw_background(journey, game.surfaces.mothership)	
end

function Public.resetsfsf(journey)
    
end

function Public.teleporters(journey, player)
	local surface = player.surface
	if surface.count_entities_filtered({position = player.position, name = "player-port"}) == 0 then return end
	if surface.index == 1 then
		player.teleport(surface.find_non_colliding_position("character", {Constants.mothership_teleporter_position.x , Constants.mothership_teleporter_position.y - 4}, 32, 0.5), game.surfaces.mothership)
		return
	end
	if not journey.mothership_teleporter_online then player.print("Teleporter offline.") return end
	if surface.name == "mothership" then
		player.teleport(surface.find_non_colliding_position("character", {Constants.mothership_teleporter_position.x , Constants.mothership_teleporter_position.y - 4}, 32, 0.5), game.surfaces.nauvis)
		return
	end
end

return Public
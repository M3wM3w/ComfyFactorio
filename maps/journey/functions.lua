local Public = {}
local Constants = require 'maps.journey.constants'

local function clear_world_selectors(journey)
	for k, world_selector in pairs(journey.world_selectors) do
		for _, ID in pairs(world_selector.texts) do
			rendering.destroy(ID)
		end
		journey.world_selectors[k].texts = {}
		journey.world_selectors[k].activation_level = 0
	end
end

local function drop_player_items(player)
	local character = player.character
	if not character then return end
	if not character.valid then return end
	
	player.clear_cursor()
	
	for i = 1, player.crafting_queue_size, 1 do
		if player.crafting_queue_size > 0 then
			player.cancel_crafting{index = 1, count = 99999999}
		end
	end
	
	local surface = player.surface	
	for _, define in pairs({defines.inventory.character_main, defines.inventory.character_guns, defines.inventory.character_ammo, defines.inventory.character_armor, defines.inventory.character_vehicle, defines.inventory.character_trash}) do
		local inventory = character.get_inventory(define)
		if inventory and inventory.valid then
			for i = 1, #inventory, 1 do
				local slot = inventory[i]
				if slot.valid and slot.valid_for_read then
					surface.spill_item_stack(player.position, slot, true, nil, false)
				end		
			end
			inventory.clear()
		end	
	end
end

function Public.mothership_message_queue(journey)
	local text = journey.mothership_messages[1]
	if not text then return end
	if text ~= "" then
		text = "[font=default-game][color=200,200,200]" .. text .. "[/color][/font]"
		text = "[font=heading-1][color=255,155,155]<Mothership> [/color][/font]" .. text
		game.print(text)
	end
	table.remove(journey.mothership_messages, 1)
end

function Public.deny_building(event)
    local entity = event.created_entity
    if not entity.valid then return end	
	if entity.surface.name ~= "mothership" then return end
	if Constants.build_type_whitelist[entity.type] then return end
	entity.die() 
end

function Public.draw_gui(journey)
	local surface = game.surfaces.nauvis
	local mgs = surface.map_gen_settings	
	local caption = "World - " .. journey.world_number
	local tooltip = ""
	for k, autoplace in pairs(mgs.autoplace_controls) do
		tooltip = tooltip .. Constants.modifiers[k][3] .. " - " .. math.floor(autoplace.frequency * 100) .. "%\n"
	end
	tooltip = tooltip .. "Cliff Interval - " .. math.round(mgs.cliff_settings.cliff_elevation_interval * 2.5, 2) .. "%\n"
	tooltip = tooltip .. "Water - " .. math.floor(mgs.water * 100) .. "%\n"
	tooltip = tooltip .. "Starting area - " .. math.floor(mgs.starting_area * 100) .. "%\n"
	tooltip = tooltip .. "Evolution Time Factor - " .. math.round(game.map_settings.enemy_evolution.time_factor * 25000000, 1) .. "%\n"
	tooltip = tooltip .. "Evolution Destroy Factor - " .. math.round(game.map_settings.enemy_evolution.destroy_factor * 50000, 1) .. "%\n"
	tooltip = tooltip .. "Evolution Pollution Factor - " .. math.round(game.map_settings.enemy_evolution.pollution_factor * 111100000, 1) .. "%\n"	
	tooltip = tooltip .. "Nest Expansion Cooldown - " .. math.round(game.map_settings.enemy_expansion.min_expansion_cooldown / 144, 1) .. "%\n"
	tooltip = tooltip .. Constants.modifiers["enemy_attack_pollution_consumption_modifier"][3] .. " - " .. math.round(game.map_settings.pollution.enemy_attack_pollution_consumption_modifier * 100, 1) .. "%\n"
	tooltip = tooltip .. Constants.modifiers["ageing"][3] .. " - " .. math.round(game.map_settings.pollution.ageing * 100, 1) .. "%\n"	
	tooltip = tooltip .. Constants.modifiers["technology_price_multiplier"][3] .. " - " .. math.round(game.difficulty_settings.technology_price_multiplier * 100, 1) .. "%\n"
	
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

function Public.hard_reset(journey)
	if game.surfaces.mothership and game.surfaces.mothership.valid then
		game.delete_surface(game.surfaces.mothership)
	end
	
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_distance = 20
	game.map_settings.enemy_expansion.settler_group_min_size = 5
	game.map_settings.enemy_expansion.settler_group_max_size = 50
	game.map_settings.enemy_expansion.min_expansion_cooldown = 14400
	game.map_settings.enemy_expansion.max_expansion_cooldown = 216000

	game.map_settings.pollution.enabled = true
	game.map_settings.pollution.ageing = 1
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 1

	game.difficulty_settings.technology_price_multiplier = 1

	game.map_settings.enemy_evolution.time_factor = 0.000004
	game.map_settings.enemy_evolution.destroy_factor = 0.002
	game.map_settings.enemy_evolution.pollution_factor = 0.0000009
	
	local surface = game.surfaces[1]
    local mgs = surface.map_gen_settings
    mgs.water = 1
	mgs.starting_area = 1
    mgs.cliff_settings = {cliff_elevation_interval = 40, cliff_elevation_0 = 10}
    mgs.autoplace_controls = {
		["coal"] = {frequency = 1, size = 1, richness = 1},
		["stone"] = {frequency = 1, size = 1, richness = 1},
		["copper-ore"] = {frequency = 1, size = 1, richness = 1},
		["iron-ore"] = {frequency = 1, size = 1, richness = 1},
		["uranium-ore"] = {frequency = 1, size = 1, richness = 1},
		["crude-oil"] = {frequency = 1, size = 1, richness = 1},
		["trees"] = {frequency = 1, size = 1, richness = 1},
		["enemy-base"] = {frequency = 1, size = 1, richness = 1},
    }
    surface.map_gen_settings = mgs
    surface.clear(true)
		
	if journey.world_selectors and journey.world_selectors[1].border then
		for k, world_selector in pairs(journey.world_selectors) do
			for _, ID in pairs(world_selector.rectangles) do
				rendering.destroy(ID)
			end
			rendering.destroy(world_selector.border)
		end	
	end
	
	journey.world_selectors = {}
	for i = 1, 3, 1 do journey.world_selectors[i] = {activation_level = 0, texts = {}} end	
	journey.mothership_speed = 0.5
	journey.characters_in_mothership = 0
	journey.mothership_messages = {}
	journey.mothership_cargo = {}
	
	journey.world_number = 0
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
		
		journey.world_selectors[k].border = rendering.draw_rectangle {
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

	for k, item_name in pairs({"arithmetic-combinator", "constant-combinator", "decider-combinator", "programmable-speaker", "red-wire", "green-wire", "small-lamp", "substation", "pipe", "gate", "stone-wall", "transport-belt"}) do
		local e = surface.create_entity({name = "steel-chest", position = {-7 + k, Constants.mothership_radius - 3}, force = "player"})
		e.insert({name = item_name, count = 1000})
		e.minable = false
		e.destructible = false
	end
		
	for m = -1, 1, 2 do
		local e = surface.create_entity({name = "electric-energy-interface", position = {8 * m, Constants.mothership_radius - 4}, force = "player"})	
		e.minable = false
		e.destructible = false
		local e = surface.create_entity({name = "substation", position = {10 * m, Constants.mothership_radius - 5}, force = "player"})
		e.minable = false
		e.destructible = false
	end
	
	for _ = 1, 5, 1 do
		local e = surface.create_entity({name = "compilatron", position = Constants.mothership_teleporter_position, force = "player"})
		e.destructible = false
	end

	Public.draw_gui(journey)
	
	journey.game_state = "set_world_selectors"
end

function Public.teleport_players_to_mothership(journey)
	local surface = game.surfaces.mothership
	for _, player in pairs(game.connected_players) do
		if player.surface.name ~= "mothership" then
			drop_player_items(player)
			player.teleport(surface.find_non_colliding_position("character", {0,0}, 32, 0.5), surface)
			journey.characters_in_mothership = journey.characters_in_mothership + 1
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
		
		for i = 1, 6, 1 do
			local modifier = modifier_names[i]
			modifiers[i] = {modifier, math.random(Constants.modifiers[modifier][1], Constants.modifiers[modifier][2])}
		end
		for i = 7, 8, 1 do
			local modifier = modifier_names[i]
			modifiers[i] = {modifier, -1 * math.random(Constants.modifiers[modifier][1], Constants.modifiers[modifier][2])}
		end	
		
		local texts = world_selector.texts
		for k2, modifier in pairs(modifiers) do
			local position = Constants.world_selector_areas[k].left_top
			local text = ""
			if modifier[2] > 0 then text = text .. "+" end
			text = text .. modifier[2] .. "% "
			text = text .. Constants.modifiers[modifier[1]][3]
			
			local color
			if k2 < 7 then
				color = {200, 0, 0, 255}
			else
				color = {0, 200, 0, 255}
			end				
			
			texts[k2] = rendering.draw_text{
				text = text,
				surface = surface,
				target = {position.x + Constants.world_selector_width * 0.5, position.y + k2 * 0.8 - 7.5},
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
	if journey.nauvis_teleporter and journey.nauvis_teleporter.valid then
		journey.nauvis_teleporter.destroy()
	end

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
			journey.mothership_advancing_to_world = game.tick + math.random(60 * 45, 60 * 75)
		else
			local seconds_left = math.floor((journey.mothership_advancing_to_world - game.tick) / 60)
			if seconds_left <= 0 then
				journey.mothership_advancing_to_world = false
				table.insert(journey.mothership_messages, "Arriving at targeted destination!")
				journey.game_state = "mothership_arrives_at_world"
				return
			end
			if seconds_left % 15 == 0 then table.insert(journey.mothership_messages, "Estimated arrival in " .. seconds_left .. " seconds.") end
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
		table.insert(journey.mothership_messages, "[img=item/uranium-fuel-cell] Fuel cells depleted ;_;")
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
		if name == "expansion_cooldown" then			
			game.map_settings.enemy_expansion.min_expansion_cooldown = game.map_settings.enemy_expansion.min_expansion_cooldown * m
			game.map_settings.enemy_expansion.max_expansion_cooldown = game.map_settings.enemy_expansion.min_expansion_cooldown * m
		end
		if name == "technology_price_multiplier" then			
			game.difficulty_settings.technology_price_multiplier = game.difficulty_settings.technology_price_multiplier * m
		end
		if name == "enemy_attack_pollution_consumption_modifier" then			
			game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = game.map_settings.pollution.enemy_attack_pollution_consumption_modifier * m
		end
		if name == "ageing" then			
			game.map_settings.pollution.ageing = game.map_settings.pollution.ageing * m
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
	for _, player in pairs(game.players) do
		if not player.connected then
			player.force = game.forces.enemy
		end	
	end
	journey.nauvis_teleporter = surface.create_entity({name = "player-port", position = Constants.mothership_teleporter_position, force = "player"})
	journey.nauvis_teleporter.destructible = false
	journey.nauvis_teleporter.minable = false
	journey.game_state = "make_it_night"
end

function Public.make_it_night(journey)
	local surface = game.surfaces.mothership
	local daytime = surface.daytime
	daytime = daytime + 0.02
	surface.daytime = daytime
	if daytime > 0.5 then		
		clear_world_selectors(journey)
		game.reset_time_played()
		game.forces.player.reset()
		game.forces.player.reset_technologies()
		game.forces.player.reset_technology_effects()
		game.forces.enemy.reset_evolution()
		journey.characters_in_mothership = surface.count_entities_filtered{name = "character"}
		journey.mothership_cargo["uranium-fuel-cell"] = nil
		journey.mothership_teleporter_online = true
		journey.game_state = "world" 
	end
end

function Public.world(journey)
	if journey.mothership_cargo["uranium-fuel-cell"] then
		if journey.mothership_cargo["uranium-fuel-cell"] >= 50 then
			table.insert(journey.mothership_messages, "Refuel operation successful!! =^.^=")
			journey.game_state = "mothership_waiting_for_players"
		end
	end

	if journey.characters_in_mothership == 0 then return end
	draw_background(journey, game.surfaces.mothership)
end 

function Public.mothership_waiting_for_players(journey)
	if journey.characters_in_mothership > #game.connected_players * 0.5 then
		journey.game_state = "set_world_selectors"
		return
	end

	if math.random(1, 2) == 1 then return end
	local tick = game.tick % 3600
	if tick == 0 then
		local messages = Constants.mothership_messages.waiting
		table.insert(journey.mothership_messages, messages[math.random(1, #messages)])
	end
end

function Public.teleporters(journey, player)
	local surface = player.surface
	local base_position = {Constants.mothership_teleporter_position.x , Constants.mothership_teleporter_position.y - 5}
	if surface.count_entities_filtered({position = player.position, name = "player-port"}) == 0 then return end
	if surface.index == 1 then
		drop_player_items(player)
		local position = game.surfaces.mothership.find_non_colliding_position("character", base_position, 32, 0.5)
		if position then
			player.teleport(position, game.surfaces.mothership)
		else
			player.teleport(base_position, game.surfaces.mothership)
		end
		journey.characters_in_mothership = journey.characters_in_mothership + 1
		return
	end
	if not journey.mothership_teleporter_online then player.print("Teleporter offline.") return end
	if surface.name == "mothership" then
		drop_player_items(player)
		local position = game.surfaces.nauvis.find_non_colliding_position("character", base_position, 32, 0.5)
		if position then
			player.teleport(position, game.surfaces.nauvis)
		else
			player.teleport(base_position, game.surfaces.nauvis)
		end
		
		journey.characters_in_mothership = journey.characters_in_mothership - 1
		return
	end
end

return Public
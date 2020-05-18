require "modules.sticky_landfill"
require "modules.dynamic_player_spawn"
require "modules.biters_yield_ore"

local math_random = math.random
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local math_sqrt = math.sqrt
local math_round = math.round
local math_abs = math.abs

local map_height = 96

local infini_ores = {"iron-ore", "iron-ore", "copper-ore", "coal", "stone"}

local function on_player_joined_game(event)
	local surface = game.surfaces["railway_troopers"]
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
	end
end

local function set_commands(unit_group)
	local surface = unit_group.surface
	local position = unit_group.position
	local commands = {}
	for x = position.x, -8196, -32 do
		if surface.is_chunk_generated({math_floor(x / 32), math_floor(position.y / 32)}) then
			if math_random(1, 16) == 1 then
				commands[#commands + 1] = {
					type = defines.command.build_base,
					destination = {x = x, y = position.y},
					distraction = defines.distraction.by_anything,
					ignore_planner = true,
				}
			else
				commands[#commands + 1] = {
					type = defines.command.attack_area,
					destination = {x = x, y = position.y},
					radius = 16,
					distraction = defines.distraction.by_anything
				}
			end
		else
			break
		end
	end
	
	if #commands == 0 then return end
	
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = commands
	})
end

local function send_wave(spawner, search_radius)
	local biters = spawner.surface.find_enemy_units(spawner.position, search_radius, "player")	
	if biters[1] then
		local unit_group = spawner.surface.create_unit_group({position = {x = spawner.position.x, y = -42 + math_random(0, 84)}, force = "enemy"})
		for _, unit in pairs(biters) do unit_group.add_member(unit) end
		set_commands(unit_group)
	end
end

local function on_entity_spawned(event)
	global.on_entity_spawned_counter = global.on_entity_spawned_counter + 1	
	local c = global.on_entity_spawned_counter * 0.5	
	if c % 2 ~= 0 then return end
	for a = 14, 6, -2 do
		local b = 2 ^ a
		if c % b == 0 then
			send_wave(event.spawner, a ^ 2 - 28)
			return
		end
	end		
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.type == "unit" and entity.spawner then
		entity.spawner.damage(20, game.forces[1])
	end
end

local function is_out_of_map(p)
	local a = p.x + 1960
	local b = math_abs(p.y)
	if a * 0.025 >= b then return end
	if a * -0.025 > b then return end
	return true
end

local function draw_west_side(surface, left_top)
	local entities = {}	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			if math_abs(position.y) > map_height * 0.5 then
				surface.set_tiles({{name = "out-of-map", position = position}}, true)
			else
				surface.set_tiles({{name = "deepwater-green", position = position}}, true)
				if math_random(1, 64) == 1 then table_insert(entities, {name = "fish", position = position}) end
				if math_random(1, 8196) == 1 and position.x < -64 then table_insert(entities, {name = "crude-oil", position = position, amount = 200000 + math_abs(left_top.x * 500)}) end			
			end		
		end
	end
	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
end

local function draw_east_side(surface, left_top)
	local entities = {}
	
	if left_top.y == 0 and left_top.x < 64 then
		for x = 0, 30, 2 do
			surface.create_entity({name = "straight-rail", position = {left_top.x + x, 0}, direction = 2, force = "player"})
		end
		if left_top.x == -32 then
			local entity = surface.create_entity({name = "cargo-wagon", position = {-24, 0}, force = "player", direction = 2})
			entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "firearm-magazine", count = 600})
			entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "shotgun", count = 2})
			entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "shotgun-shell", count = 64})
			entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "light-armor", count = 5})
			entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "grenade", count = 32})
			entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "pistol", count = 10})
			entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "rail", count = 100})
			local entity = surface.create_entity({name = "locomotive", position = {-18, 0}, force = "player", direction = 2})			
			entity.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 25})
		end
	end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			if is_out_of_map(position) then
				surface.set_tiles({{name = "out-of-map", position = position}}, true)
			else
				if math_random(1, 4096) == 1 and left_top.x > -32 and math_abs(left_top.y) > 2 then
					table_insert(entities, {name = infini_ores[math_random(1, #infini_ores)], position = position, amount = 99999999})
					table_insert(entities, {name = "electric-mining-drill", position = position, force = "enemy"})				
				end
			end		
		end
	end
	
	for _, entity in pairs(entities) do
		local e = surface.create_entity(entity)
		if e.name == "electric-mining-drill" then
			if e.position.y < 0 then
				e.direction = 4
			else
				e.direction = 0
			end
			e.minable = false
			e.destructible = false
			--e.insert({name = "coal", count = math_random(8, 36)})
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top

	if left_top.x < -32 then
		draw_west_side(surface, left_top)
	else
		draw_east_side(surface, left_top)
	end
end

local type_whitelist = {
	["artillery-wagon"] = true,
	["car"] = true,
	["cargo-wagon"] = true,
	["construction-robot"] = true,
	["container"] = true,
	["curved-rail"] = true,
	["electric-pole"] = true,
	["entity-ghost"] = true,
	["fluid-wagon"] = true,
	["heat-pipe"] = true,
	["inserter"] = true,
	["lamp"] = true,
	["locomotive"] = true,
	["logistic-robot"] = true,
	["rail-chain-signal"] = true,
	["rail-signal"] = true,
	["splitter"] = true,
	["straight-rail"] = true,
	["tile-ghost"] = true,
	["train-stop"] = true,	
	["transport-belt"] = true,
	["underground-belt"] = true,
	["wall"] = true,
	["gate"] = true,
	["beacon"] = true,
}

local function deny_building(event)
	local entity = event.created_entity
	if not entity.valid then return end
	
	if type_whitelist[event.created_entity.type] then return end

	if entity.position.x < -32 then return end

	if event.player_index then
		game.players[event.player_index].insert({name = entity.name, count = 1})		
	else	
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity.name, count = 1})													
	end
	
	event.created_entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "Can only be built west!",
		color = {r=0.98, g=0.66, b=0.22}
	})
	
	entity.destroy()
end

local function on_built_entity(event)
	deny_building(event)
end

local function on_robot_built_entity(event)
	deny_building(event)
end

local function on_research_finished(event)
	event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 200
	event.research.force.character_item_pickup_distance_bonus = game.forces.player.mining_drill_productivity_bonus * 10
end

local function send_tick_wave()
	if game.tick % 54000 ~= 3600 then return end
	local surface = game.surfaces["railway_troopers"]
	local spawners = surface.find_entities_filtered({type = "unit-spawner"})
	if not spawners[1] then return end
	
	local search_radius = 16
	for _, player in pairs(game.connected_players) do
		if player.position.x * 0.5 > search_radius then search_radius = math_floor(player.position.x * 0.5) end
	end
	if search_radius > 256 then search_radius = 256 end
	
	send_wave(spawners[math_random(1, #spawners)], search_radius)
end

local function on_tick()
	send_tick_wave()
end

local function on_init()
	global.drop_schedule = {}
	global.on_entity_spawned_counter = 0

	game.map_settings.enemy_evolution.destroy_factor = 0.001
	--game.map_settings.enemy_evolution.pollution_factor = 0	
	--game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 900
	game.map_settings.enemy_expansion.min_expansion_cooldown = 900
	game.map_settings.enemy_expansion.settler_group_max_size = 128
	game.map_settings.enemy_expansion.settler_group_min_size = 32
	game.map_settings.enemy_expansion.max_expansion_distance = 16
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.25
	
	local map_gen_settings = {
		["water"] = 0,
		["starting_area"] = 0.60,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["autoplace_controls"] = {
			["coal"] = {frequency = 0, size = 0.65, richness = 0.5},
			["stone"] = {frequency = 0, size = 0.65, richness = 0.5},
			["copper-ore"] = {frequency = 0, size = 0.65, richness = 0.5},
			["iron-ore"] = {frequency = 0, size = 0.65, richness = 0.5},
			["uranium-ore"] = {frequency = 0, size = 1, richness = 1},
			["crude-oil"] = {frequency = 0, size = 1, richness = 0.75},
			["trees"] = {frequency = 2, size = 0.15, richness = 1},
			["enemy-base"] = {frequency = 256, size = 2, richness = 1},
		},
	}
	
	local surface = game.create_surface("railway_troopers", map_gen_settings)
	surface.request_to_generate_chunks({0,0}, 4)
	surface.force_generate_chunk_requests()
	
	local force = game.forces.player
	
	force.set_spawn_position({-30, 0}, surface)	
	
	force.technologies["landfill"].researched = true
	force.technologies["railway"].researched = true
	force.technologies["engine"].researched = true
	
	local types_to_disable = {
		["ammo"] = true,
		["armor"] = true,
		["car"] = true,
		["gun"] = true,
		["capsule"] = true,
	}
	
	for _, recipe in pairs(game.recipe_prototypes) do
		if types_to_disable[recipe.subgroup.name] then
			force.set_hand_crafting_disabled_for_recipe(recipe.name, true)
		end
	end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
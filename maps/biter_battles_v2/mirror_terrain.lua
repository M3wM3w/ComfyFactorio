local Public = {}

local Functions = require "maps.biter_battles_v2.functions"
local table_remove = table.remove
local table_insert = table.insert

local direction_translation = {
	[0] = 4,
	[1] = 5,
	[2] = 6,
	[3] = 7,
	[4] = 0,
	[5] = 1,
	[6] = 2,
	[7] = 3
}

local cliff_orientation_translation = {
	["east-to-none"] =  "west-to-none",
	["east-to-north"] =  "west-to-south",
	["east-to-south"] =  "west-to-north",
	["east-to-west"] =  "west-to-east",
	["north-to-east"] =  "south-to-west",
	["north-to-none"] =  "south-to-none",
	["north-to-south"] =  "south-to-north",
	["north-to-west"] =  "south-to-east",
	["south-to-east"] =  "north-to-west",
	["south-to-none"] =  "north-to-none",
	["south-to-north"] =  "north-to-south",
	["south-to-west"] =  "north-to-east",
	["west-to-east"] =  "east-to-west",
	["west-to-none"] =  "east-to-none",
	["west-to-north"] =  "east-to-south",
	["west-to-south"] =  "east-to-north",
	["none-to-east"] =  "none-to-west",
	["none-to-north"] =  "none-to-south",
	["none-to-south"] =  "none-to-north",
	["none-to-west"] =  "none-to-east"
}

local entity_copy_functions = {
	["tree"] = function(surface, entity, target_position, force_name)
		if not surface.can_place_entity({name = entity.name, position = target_position}) then return end
		entity.clone({position = target_position, surface = surface, force = "neutral"})
	end,
	["simple-entity"] = function(surface, entity, target_position, force_name)
		local mirror_entity = {name = entity.name, position = target_position, direction = direction_translation[entity.direction]}
		if not surface.can_place_entity(mirror_entity) then return end
		local mirror_entity = surface.create_entity(mirror_entity)
		mirror_entity.graphics_variation = entity.graphics_variation
	end,
	["cliff"] = function(surface, entity, target_position, force_name)
		local mirror_entity = {name = entity.name, position = target_position, cliff_orientation = cliff_orientation_translation[entity.cliff_orientation]}
		if not surface.can_place_entity(mirror_entity) then return end
		surface.create_entity(mirror_entity)
		return
	end,	
	["resource"] = function(surface, entity, target_position, force_name)
		surface.create_entity({name = entity.name, position = target_position, amount = entity.amount})
	end,	
	["corpse"] = function(surface, entity, target_position, force_name)
		surface.create_entity({name = entity.name, position = target_position})
	end,	
	["unit-spawner"] = function(surface, entity, target_position, force_name)
		local mirror_entity = {name = entity.name, position = target_position, direction = direction_translation[entity.direction], force = force_name .. "_biters"}
		if not surface.can_place_entity(mirror_entity) then return end		
		table_insert(global.unit_spawners[force_name .. "_biters"], surface.create_entity(mirror_entity))
	end,
	["turret"] = function(surface, entity, target_position, force_name)
		local mirror_entity = {name = entity.name, position = target_position, direction = direction_translation[entity.direction], force = force_name .. "_biters"}
		if not surface.can_place_entity(mirror_entity) then return end
		surface.create_entity(mirror_entity)
	end,
	["rocket-silo"] = function(surface, entity, target_position, force_name)
		if surface.count_entities_filtered({name = "rocket-silo", area = {{target_position.x - 8, target_position.y - 8},{target_position.x + 8, target_position.y + 8}}}) > 0 then return end
		global.rocket_silo[force_name] = surface.create_entity({name = entity.name, position = target_position, direction = direction_translation[entity.direction], force = force_name})
		global.rocket_silo[force_name].minable = false
		Functions.add_target_entity(global.rocket_silo[force_name])
	end,	
	["ammo-turret"] = function(surface, entity, target_position, force_name)
		local direction = 0
		if force_name == "south" then direction = 4 end
		local mirror_entity = {name = entity.name, position = target_position, force = force_name, direction = direction}
		if not surface.can_place_entity(mirror_entity) then return end
		local e = surface.create_entity(mirror_entity)
		Functions.add_target_entity(e)
		local inventory = entity.get_inventory(defines.inventory.turret_ammo)
		if inventory.is_empty() then return end
		for name, count in pairs(inventory.get_contents()) do e.insert({name = name, count = count}) end	
	end,
	["wall"] = function(surface, entity, target_position, force_name)
		local e = entity.clone({position = target_position, surface = surface, force = force_name})
		e.active = true
	end,
	["container"] = function(surface, entity, target_position, force_name)
		local e = entity.clone({position = target_position, surface = surface, force = force_name})
		e.active = true
	end,
	["fish"] = function(surface, entity, target_position, force_name)
		local mirror_entity = {name = entity.name, position = target_position}
		if not surface.can_place_entity(mirror_entity) then return end
		local e = surface.create_entity(mirror_entity)
	end,
}

local function process_entity(surface, entity, force_name)
	if not entity.valid then return end
	if not entity_copy_functions[entity.type] then return end
	
	local target_position
	if force_name == "north" then
		target_position = entity.position
	else
		target_position = {x = entity.position.x * -1, y = entity.position.y * -1}
	end
 
	entity_copy_functions[entity.type](surface, entity, target_position, force_name)
end

local function copy_chunk(chunk)
	local target_surface = game.surfaces.biter_battles
	
	local source_surface = game.surfaces.bb_source
	local source_chunk_position = {chunk[1][1], chunk[1][2]}
	local source_left_top = {x = source_chunk_position[1] * 32, y = source_chunk_position[2] * 32}
	local source_area = {{source_left_top.x, source_left_top.y}, {source_left_top.x + 32, source_left_top.y + 32}}
	
	local target_chunk_position = chunk[1]	
	local target_left_top = {x = target_chunk_position[1] * 32, y = target_chunk_position[2] * 32}
	local target_area = {{target_left_top.x, target_left_top.y}, {target_left_top.x + 32, target_left_top.y + 32}}
	
	if not source_surface.is_chunk_generated(source_chunk_position) then
		source_surface.request_to_generate_chunks({x = source_left_top.x + 16, y = source_left_top.y + 16}, 0)
		return
	end
	
	if chunk[2] == 1 then
		source_surface.clone_area({
			source_area = source_area,
			destination_area = target_area,
			destination_surface = target_surface,
			--destination_force = …,
			clone_tiles = true,
			clone_entities = false,
			clone_decoratives = false,
			clear_destination_entities = false,
			clear_destination_decoratives = false,
			expand_map = false
		})
		chunk[2] = chunk[2] + 1
		return
	end
	
	if chunk[2] == 2 then
		for _, entity in pairs(source_surface.find_entities_filtered({area = source_area})) do
			process_entity(target_surface, entity, "north")						
		end
		chunk[2] = chunk[2] + 1
		return
	end
	
	local decoratives = {}
	for k, decorative in pairs(source_surface.find_decoratives_filtered{area = source_area}) do 
		decoratives[k] = {name = decorative.decorative.name, position = {decorative.position.x, decorative.position.y}, amount = decorative.amount}
	end
	target_surface.create_decoratives({check_collision = false, decoratives = decoratives})
	
	return true
end

local function mirror_chunk(chunk)
	local target_surface = game.surfaces.biter_battles
	
	local source_surface = game.surfaces.bb_source
	local source_chunk_position = {chunk[1][1] * -1 - 1, chunk[1][2] * -1 - 1}
	local source_left_top = {x = source_chunk_position[1] * 32, y = source_chunk_position[2] * 32}
	local source_area = {{source_left_top.x, source_left_top.y}, {source_left_top.x + 32, source_left_top.y + 32}}
	
	if not source_surface.is_chunk_generated(source_chunk_position) then
		source_surface.request_to_generate_chunks({x = source_left_top.x + 16, y = source_left_top.y + 16}, 0)
		return
	end

	if chunk[2] == 1 then
		local tiles = {}
		for k, tile in pairs(source_surface.find_tiles_filtered({area = source_area})) do
			tiles[k] = {name = tile.name, position = {tile.position.x * -1 - 1 , tile.position.y * -1 - 1}}			
		end
		target_surface.set_tiles(tiles, true)
		chunk[2] = chunk[2] + 1
		return
	end
	
	if chunk[2] == 2 then
		for _, entity in pairs(source_surface.find_entities_filtered({area = source_area})) do
			process_entity(target_surface, entity, "south")
		end
		chunk[2] = chunk[2] + 1
		return
	end
	
	local decoratives = {}
	for k, decorative in pairs(source_surface.find_decoratives_filtered{area = source_area}) do 
		decoratives[k] = {name = decorative.decorative.name, position = {(decorative.position.x * -1) - 1, (decorative.position.y * -1) - 1}, amount = decorative.amount}
	end
	target_surface.create_decoratives({check_collision = false, decoratives = decoratives})
	
	return true
end

local function reveal_chunk(chunk)
	local surface = game.surfaces.biter_battles
	local chunk_position = chunk[1]
	for _, force_name in pairs({"north", "south"}) do
		local force = game.forces[force_name]
		if force.is_chunk_charted(surface, chunk_position) then
			force.chart(surface, {{chunk_position[1] * 32, chunk_position[2] * 32}, {chunk_position[1] * 32 + 31, chunk_position[2] * 32 + 31}})
		end
	end
end

function Public.add_chunk(event)
	local surface = event.surface
	if surface.name ~= "biter_battles" then return end
	local left_top = event.area.left_top	
	local terrain_gen = global.terrain_gen
	
	if left_top.y < 0 then
		terrain_gen.size_of_chunk_copy = terrain_gen.size_of_chunk_copy + 1
		terrain_gen.chunk_copy[terrain_gen.size_of_chunk_copy] = {{left_top.x / 32, left_top.y / 32}, 1}
	else
		terrain_gen.size_of_chunk_mirror = terrain_gen.size_of_chunk_mirror + 1
		terrain_gen.chunk_mirror[terrain_gen.size_of_chunk_mirror] = {{left_top.x / 32, left_top.y / 32}, 1}
	end
end

local function clear_source_surface(terrain_gen)
	if terrain_gen.counter % 1024 == 1023 then
		terrain_gen.counter = terrain_gen.counter + 1
		local surface = game.surfaces.bb_source
		local c = 0
		for chunk in surface.get_chunks() do		
			surface.delete_chunk({chunk.x, chunk.y})
			c = c + 1
		end
		print("Deleted " .. c .. " source surface chunks.")
	end
end

local function north_work()
	local terrain_gen = global.terrain_gen
	for k, chunk in pairs(terrain_gen.chunk_copy) do		
		if copy_chunk(chunk) then
			reveal_chunk(chunk)
			table_remove(terrain_gen.chunk_copy, k)
			terrain_gen.size_of_chunk_copy = terrain_gen.size_of_chunk_copy - 1
			terrain_gen.counter = terrain_gen.counter + 1
		end
		break			
	end
	clear_source_surface(terrain_gen)
end

local function south_work()
	local terrain_gen = global.terrain_gen
	for k, chunk in pairs(terrain_gen.chunk_mirror) do			
		if mirror_chunk(chunk) then
			reveal_chunk(chunk)
			table_remove(terrain_gen.chunk_mirror, k)
			terrain_gen.size_of_chunk_mirror = terrain_gen.size_of_chunk_mirror - 1
			terrain_gen.counter = terrain_gen.counter + 1
		end			
		break
	end
	clear_source_surface(terrain_gen)
end

local works = {
	[1] = north_work,
	[2] = south_work,
}

function Public.ticking_work()
	local tick = game.ticks_played
	if tick < 4 then return end
	local work = works[tick % 2 + 1]	
	if global.server_restart_timer then return end
	work()
end

return Public
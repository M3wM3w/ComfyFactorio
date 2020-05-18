-- placing landfill in another surface will reveal nauvis -- by mewmew

local regenerate_decoratives = true

local event = require 'utils.event'
local math_random = math.random
local table_insert = table.insert
local water_tile_whitelist = {
		["water"] = true,
		["deepwater"] = true,
		["water-green"] = true,
		["deepwater-green"] = true
	}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_chunk_position(position)
	local chunk_position = {}
	position.x = math.floor(position.x)
	position.y = math.floor(position.y)
	for x = 0, 31, 1 do
		if (position.x - x) % 32 == 0 then chunk_position.x = (position.x - x)  / 32 end
	end
	for y = 0, 31, 1 do
		if (position.y - y) % 32 == 0 then chunk_position.y = (position.y - y)  / 32 end
	end	
	return chunk_position
end

local function place_entity(surface, entity)
	if entity.type == "tree" then
		if not surface.can_place_entity({name = entity.name, position = entity.position}) then return end
		entity.clone({position=entity.position, surface=surface, force="neutral"})
		return
	end
	if entity.type == "simple-entity" then
		local new_e = {name = entity.name, position = entity.position, direction = entity.direction}
		if not surface.can_place_entity(new_e) then return end
		local e = surface.create_entity(new_e)
		e.graphics_variation = entity.graphics_variation
		return
	end
	if entity.type == "cliff" then
		local new_e = {name = entity.name, position = entity.position, cliff_orientation = entity.cliff_orientation}
		if not surface.can_place_entity(new_e) then return end
		surface.create_entity(new_e)
		return
	end
	if entity.type == "resource" then
		entity.clone({position=entity.position, surface=surface, force="neutral"})
		return
	end
	if entity.type == "unit-spawner" or entity.type == "unit" or entity.type == "turret" then
		local area = {{entity.position.x - 1, entity.position.y - 1}, {entity.position.x + 1, entity.position.y + 1}}
		if surface.count_entities_filtered({area = area, force = "enemy"}) > 0 then return end
		local new_e = {name = entity.name, position = entity.position, direction = entity.direction}
		surface.create_entity(new_e)
		return
	end
	if entity.name == "character" then
		return
	end
	if entity.name == "fish" then
		local area = {{entity.position.x - 1, entity.position.y - 1}, {entity.position.x + 1, entity.position.y + 1}}
		if surface.count_entities_filtered({area = area, name = "fish"}) > 0 then return end
		surface.create_entity({name = entity.name, position = entity.position, direction = entity.direction})
		return
	end
end

local function generate_chunks(position)
	local nauvis = game.surfaces.nauvis
	local chunk = get_chunk_position(position)
	if nauvis.is_chunk_generated(chunk) then return end
	nauvis.request_to_generate_chunks(position, 1)
	nauvis.force_generate_chunk_requests()
end

local function process_tile(surface, position, old_tile, inventory)	
	local nauvis = game.surfaces.nauvis
	generate_chunks(position)
	local new_tile = nauvis.get_tile(position)	
	surface.set_tiles({new_tile})
	if new_tile.name == old_tile.name then
		surface.set_tiles({{name = "grass-1", position = new_tile.position}}, true)
		--if inventory.valid then inventory.insert({name = "landfill", count = 1}) end
		return
	end
	local area = {{position.x - 0, position.y - 0}, {position.x + 0.999, position.y + 0.999}}
	for _, e in pairs(nauvis.find_entities_filtered({area = area})) do
		place_entity(surface, e)				
	end
	local area = {{position.x - 1, position.y - 1}, {position.x + 0.999, position.y + 0.999}}
	for _, d in pairs(nauvis.find_decoratives_filtered{area = area}) do
		surface.create_decoratives{check_collision = true, decoratives = {{amount = d.amount, position = d.position, name = d.decorative.name}}}
	end
end
	
local function reveal(surface, tiles, inventory)
	for _, placed_tile in pairs(tiles) do
		if water_tile_whitelist[placed_tile.old_tile.name] then
			process_tile(surface, placed_tile.position, placed_tile.old_tile, inventory)			
		end
	end		
end

local function on_player_built_tile(event)
	if event.item.name ~= "landfill" then return end
	reveal(game.surfaces[event.surface_index], event.tiles, game.players[event.player_index].get_main_inventory())
end

local function on_robot_built_tile(event)
	if event.item.name ~= "landfill" then return end
	reveal(event.robot.surface, event.tiles, event.robot.get_inventory(defines.inventory.robot_cargo))
end

event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
event.add(defines.events.on_player_built_tile, on_player_built_tile)
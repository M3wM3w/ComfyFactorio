-- Mirrored Terrain for Biter Battles -- by MewMew and Serennie
local Public = {}

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
	["tree"] = function(surface, entity, mirror_position)
		if not surface.can_place_entity({name = entity.name, position = mirror_position}) then return end
		entity.clone({position = mirror_position, surface = surface, force = "neutral"})
	end,
	["simple-entity"] = function(surface, entity, mirror_position)
		local mirror_entity = {name = entity.name, position = mirror_position, direction = direction_translation[entity.direction]}
		if not surface.can_place_entity(mirror_entity) then return end
		local mirror_entity = surface.create_entity(mirror_entity)
		mirror_entity.graphics_variation = entity.graphics_variation
	end,
	["cliff"] = function(surface, entity, mirror_position)
		local mirror_entity = {name = entity.name, position = mirror_position, cliff_orientation = cliff_orientation_translation[entity.cliff_orientation]}
		if not surface.can_place_entity(mirror_entity) then return end
		surface.create_entity(mirror_entity)
		return
	end,	
	["resource"] = function(surface, entity, mirror_position)
		surface.create_entity({name = entity.name, position = mirror_position, amount = entity.amount})
	end,	
	["corpse"] = function(surface, entity, mirror_position)
		if game.tick > 900 then return end
		surface.create_entity({name = entity.name, position = mirror_position})
	end,	
	["unit-spawner"] = function(surface, entity, mirror_position)
		local mirror_entity = {name = entity.name, position = mirror_position, direction = direction_translation[entity.direction], force = "south_biters"}
		if not surface.can_place_entity(mirror_entity) then return end		
		table.insert(global.unit_spawners.south_biters, surface.create_entity(mirror_entity))
	end,
	["turret"] = function(surface, entity, mirror_position)
		local mirror_entity = {name = entity.name, position = mirror_position, direction = direction_translation[entity.direction], force = "south_biters"}
		if not surface.can_place_entity(mirror_entity) then return end
		surface.create_entity(mirror_entity)
	end,
	["rocket-silo"] = function(surface, entity, mirror_position)
		if game.tick > 900 then return end
		if surface.count_entities_filtered({name = "rocket-silo", area = {{mirror_position.x - 8, mirror_position.y - 8},{mirror_position.x + 8, mirror_position.y + 8}}}) > 0 then return end
		global.rocket_silo["south"] = surface.create_entity({name = entity.name, position = mirror_position, direction = direction_translation[entity.direction], force = "south"})
		global.rocket_silo["south"].minable = false
	end,	
	["ammo-turret"] = function(surface, entity, mirror_position)
		if game.tick > 900 then return end
		if not surface.can_place_entity({name = entity.name, position = mirror_position, force = "south"}) then return end
		entity.clone({position = mirror_position, surface = surface, force="south"})
	end,
	["wall"] = function(surface, entity, mirror_position)
		if game.tick > 900 then return end
		entity.clone({position = mirror_position, surface = surface, force="south"})
	end,
	["container"] = function(surface, entity, mirror_position)
		if game.tick > 900 then return end
		entity.clone({position = mirror_position, surface = surface, force="south"})
	end,
	["fish"] = function(surface, entity, mirror_position)
		local mirror_entity = {name = entity.name, position = mirror_position, direction = direction_translation[entity.direction]}
		if not surface.can_place_entity(mirror_entity) then return end
		local e = surface.create_entity(mirror_entity)
	end,
}

local function process_entity(surface, entity)
	if not entity.valid then return end
	if not entity_copy_functions[entity.type] then return end
	local mirror_position = {x = entity.position.x * -1, y = entity.position.y * -1}
	entity_copy_functions[entity.type](surface, entity, mirror_position)
end


local function mirror_tiles(surface, source_area) 
	mirrored = {}

	local i = 0
	for x = source_area.left_top.x, source_area.left_top.x+31 do
		for y = source_area.left_top.y, source_area.left_top.y+31 do
			local tile = surface.get_tile(x, y)
			mirrored[i] = {name = tile.name, position = {-x, -y - 1}}
			i = i + 1
		end
	end
	
    surface.set_tiles(mirrored, true)
end

local function clear_chunk(surface, area)
	surface.destroy_decoratives{area=area}
	if area.left_top.y > 32 or area.left_top.x > 32 or area.left_top.x < -32 then
		for _, e in pairs(surface.find_entities_filtered({area = area})) do
			if e.valid then
				e.destroy()
			end
		end
	else
		for _, e in pairs(surface.find_entities_filtered({area = area})) do
			if e.valid then
				if e.name ~= "character" then
					e.destroy()
				end
			end
		end
	end
end

local function mirror_chunk(surface, chunk)
	--local x = chunk.x * -32 + 32
	--local y = chunk.y * -32 + 32
	--clear_chunk(surface, {left_top = {x = x, y = y}, right_bottom = {x = x + 32, y = y + 32}})
	local chunk_area = {left_top = {x = chunk.x * 32, y = chunk.y * 32}, right_bottom = {x = chunk.x * 32 + 32, y = chunk.y * 32 + 32}}
	if not surface.is_chunk_generated(chunk) then
		surface.request_to_generate_chunks({x = chunk_area.left_top.x - 16, y = chunk_area.left_top.y - 16}, 1)
		surface.force_generate_chunk_requests()
	end
	for _, tile in pairs(surface.find_tiles_filtered({area = chunk_area})) do
		surface.set_tiles({{name = tile.name, position = {x = tile.position.x * -1, y = (tile.position.y * -1) - 1}}}, true)
	end
	for _, entity in pairs(surface.find_entities_filtered({area = chunk_area})) do
		process_entity(surface, entity)
	end
	for _, decorative in pairs(surface.find_decoratives_filtered{area=chunk_area}) do
		surface.create_decoratives{
			check_collision=false,
			decoratives={{name = decorative.decorative.name, position = {x = decorative.position.x * -1, y = (decorative.position.y * -1) - 1}, amount = decorative.amount}}
		}
	end
end

local function is_chunk_already_mirrored(chunk)	
	local index = chunk[1] .. "_" .. chunk[2]
	if not global.chunks_mirrored[index] then global.chunks_mirrored[index] = true return false end
	return true
end

local function add_work(work)
	if not global.ctp then global.ctp = { continue = 1, last = 0 } end
	local idx = global.ctp.last + 1
	global.ctp[idx] = work 
	global.ctp.last = idx
end

function Public.add_chunks(event)
	local surface = event.surface
	if surface.name ~= "biter_battles" then return end
	
	if event.area.left_top.y < 0 then
		if game.tick == 0 then return end
		local x = event.area.left_top.x / 32
		local y = event.area.left_top.y / 32
		
		if is_chunk_already_mirrored({x, y}) then return end
		add_work({x = x, y = y, state = 1})
		return 
	end
	
	surface.destroy_decoratives{ area = event.area }
	-- Destroy biters here before they get active and attack other biters;
	-- prevents threat decrease
	for _, e in pairs(surface.find_entities_filtered{ area = event.area, force = "enemy" }) do
		if e.valid then e.destroy() end
	end

	local x = (((event.area.left_top.x + 16) * -1) - 16) / 32
	local y = (((event.area.left_top.y + 16) * -1) - 16) / 32
	
	if is_chunk_already_mirrored({x, y}) then return end
	add_work({x = x, y = y, state = 1})
end

function Public.ticking_work()
	if not global.ctp then return end
	local work = global.mws or 512 -- define the number of work per tick here (for copies, creations, deletions)
	-- 136.5333 is the number of work needed to finish 4*(32*32) operations over 30 ticks (spreading a chunk copy over 30 ticks)
	local w = 0
	local i = global.ctp.continue
	local c = global.ctp[i]
	if not c then return end
	local state = c.state
	local d = c.data
	local area = {
		left_top = {x = c.x * 32, y = c.y * 32},
		right_bottom = {x = c.x * 32 + 32, y = c.y * 32 + 32}
	}
	local inverted_area = {
		left_top = { -area.right_bottom.x, -area.right_bottom.y },
		right_bottom = { -area.left_top.x, -area.left_top.y }
	}
	local surface = game.surfaces["biter_battles"]
	if not surface.is_chunk_generated(c) then
		--game.print("Chunk not generated yet, requesting..")
		surface.request_to_generate_chunks({x = area.left_top.x + 16, y = area.left_top.y + 16}, 0)
		-- requeue
		add_work(c)
		global.ctp.continue = i+1
		global.ctp[i] = nil 
		return
	end

	local tasks = {
		[1] = {
			name = "Clearing entities",
			list = function () return surface.find_entities_filtered({area = inverted_area, name = "character", invert = true}) end,
			action = function (e) e.destroy() end
		},
		[2] = {},
		[3] = {
			name = "Entity copy",
			list = function () return surface.find_entities_filtered({area = area}) end,
			action = function (entity) process_entity(surface, entity) end
		},
		[4] = {
			name = "Decorative copy",
			list = function () return surface.find_decoratives_filtered{area = area} end,
			action = function (decorative)
				surface.create_decoratives{
					check_collision = false,
					decoratives = {{
						name = decorative.decorative.name,
						position = {x = decorative.position.x * -1, y = (decorative.position.y * -1) - 1},
						amount = decorative.amount
					}}
				}
			end
		}
	}


    if c.state == 2 then 
        mirror_tiles(surface, area)
        c.state = c.state + 1
        c.data = nil
    else
		local task = tasks[c.state]
		-- game.print(task.name)
		d = d or task.list()
		local last_idx = nil
		for k, v in pairs(d) do
			task.action(v)
			d[k] = nil
			last_idx = k
			w = w + 1
			if w > work then break end
		end
		
		local next_idx, _ = next(d, last_idx)
		if next_idx == nil then
			c.state = c.state + 1
			c.data = nil
		else
			c.data = d
		end
	end

	if c.state == 5 then
		-- game.print("Finished processing chunk "..c.x..","..c.y)
		global.ctp.continue = i+1
		global.ctp[i] = nil
	else
		global.ctp.continue = i
	end
end

return Public
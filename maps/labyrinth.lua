--labyrinth-- mewmew made this --
require "maps.labyrinth_map_intro"
require "modules.teleporters"
require "modules.satellite_score"
--require "modules.landfill_reveals_nauvis"

local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'.d2
local event = require 'utils.event'
local unique_rooms = require "maps.labyrinth_unique_rooms"
local Score = require "comfy_panel.score"

local labyrinth_difficulty_curve = 333  --- How much size the labyrinth needs to have the highest difficulty.

local threat_values = {
	["small-biter"] = 1,
	["medium-biter"] = 3,
	["big-biter"] = 5,
	["behemoth-biter"] = 10,
	["small-spitter"] = 1,
	["medium-spitter"] = 3,
	["big-spitter"] = 5,
	["behemoth-spitter"] = 10
}

local function create_labyrinth_difficulty_gui(player)		
	if player.gui.top["labyrinth_difficulty"] then player.gui.top["labyrinth_difficulty"].destroy() end
	if not global.labyrinth_size then return end
	local str = tostring(math.ceil((global.labyrinth_size / labyrinth_difficulty_curve) * 100, 0)) .. "%"
	local b = player.gui.top.add({ type = "button", name = "labyrinth_difficulty", caption = "Difficulty: " .. str })
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
	b.style.font = "default"
	b.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
end

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_entity_chunk_position(entity_position)
	local chunk_position = {}
	entity_position.x = math.floor(entity_position.x, 0)
	entity_position.y = math.floor(entity_position.y, 0)
	for x = 0, 31, 1 do
		if (entity_position.x - x) % 32 == 0 then chunk_position.x = (entity_position.x - x)  / 32 end
	end
	for y = 0, 31, 1 do
		if (entity_position.y - y) % 32 == 0 then chunk_position.y = (entity_position.y - y)  / 32 end
	end	
	return chunk_position
end

local function is_chunk_allowed_to_grow(chunk_position, surface)
	local pos_x = chunk_position.x * 32
	local pos_y = chunk_position.y * 32
	local area = {
			left_top = {x = pos_x, y = pos_y},
			right_bottom = {x = pos_x + 31, y = pos_y + 31}
			}
	if surface.count_entities_filtered{area = area, name = {"sand-rock-big", "rock-big", "rock-huge"}, limit = 1} == 0 then
		return true
	else
		return false
	end	
end

local function is_canditate_chunk_valid(chunk, surface)
	local modifiers = {{-1,-1},{0,-1},{1,-1},{1,0}, {1,1},{0,1},{-1,1},{-1,0}}
	local invalid_places = 0
	--local invalid_chunk_found = "false"
	for _, m in pairs(modifiers) do
		local testing_chunk = {x = chunk.x + m[1], y = chunk.y + m[2]}
		local left_top_x = testing_chunk.x * 32
		local left_top_y = testing_chunk.y * 32
		local tile = surface.get_tile({left_top_x, left_top_y})		
		if tile.name ~= "out-of-map" then
			invalid_places = invalid_places + 1
		--[[	
			if invalid_chunk_found then				
				if invalid_chunk_found == "true" then					
					invalid_places = invalid_places - 1 ---if chunks are connected, raise the allowance of expansion one time
					invalid_chunk_found = nil
				end
			end
			if invalid_chunk_found then invalid_chunk_found = "true" end			
		else
			if invalid_chunk_found then invalid_chunk_found = "false" end
		]]--
		end
	end
	if math.random(1,50) == 1 and chunk.y < -3 then return true end
	if invalid_places <= 2 then return true end
	if invalid_places > 2 then return false end
end

local worm_raffle = {}
worm_raffle[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"}
worm_raffle[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"}
worm_raffle[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"}
worm_raffle[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"}
worm_raffle[5] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
worm_raffle[6] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
worm_raffle[7] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"}
worm_raffle[8] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"}
worm_raffle[9] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
worm_raffle[10] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
local rock_weights = {{"sand-rock-big", 9}, {"rock-big", 32}, {"rock-huge", 1}}
local rock_raffle = {}
for _, t in pairs (rock_weights) do
	for x = 1, t[2], 1 do
		table.insert(rock_raffle, t[1])
	end			
end
local ore_spawn_raffle = {"iron-ore","iron-ore","iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","stone","uranium-ore","crude-oil"}
local room_layouts = {"quad_rocks", "single_center_rock", "three_horizontal_rocks", "three_vertical_rocks", "tree_and_lake", "forest", "forest_fence"}
local biter_raffle = {
	{"small-biter"},
	{"small-biter","small-biter","small-biter","medium-biter"},
	{"small-biter","small-biter","medium-biter","medium-biter"},
	{"small-biter","medium-biter","medium-biter","medium-biter"},
	{"small-biter","medium-biter","medium-biter","big-biter"},
	{"medium-biter","medium-biter","medium-biter","big-biter"},
	{"medium-biter","medium-biter","big-biter","big-biter"},
	{"medium-biter","big-biter","big-biter","big-biter"},
	{"big-biter","big-biter","big-biter","behemoth-biter"},
	{"big-biter","big-biter","behemoth-biter","behemoth-biter"}	
}
local spitter_raffle = {
	{"small-spitter"},
	{"small-spitter","small-spitter","small-spitter","medium-spitter"},
	{"small-spitter","small-spitter","medium-spitter","medium-spitter"},
	{"small-spitter","medium-spitter","medium-spitter","medium-spitter"},
	{"small-spitter","medium-spitter","medium-spitter","big-spitter"},
	{"medium-spitter","medium-spitter","medium-spitter","big-spitter"},
	{"medium-spitter","medium-spitter","big-spitter","big-spitter"},
	{"medium-spitter","big-spitter","big-spitter","big-spitter"},
	{"big-spitter","big-spitter","big-spitter","behemoth-spitter"},
	{"big-spitter","big-spitter","behemoth-spitter","behemoth-spitter"}	
}
local room_enemies = {}
local room_enemy_weights = {
	{"only_biters", 10},
	{"only_spitters", 10},
	{"biters_and_spitters", 10},
	{"spawners", 7},
	{"only_worms", 5},
	{"worms_and_spawners", 5},
	{"gun_turrets", 3},
	{"allied_entities", 2},
	{"allied_entities_mixed", 2}
}
local unique_room_raffle = {"forgotten_place", "flamethrower_cross", "railway_roundabout", "big_worm_crossing", "deadly_crossing", "mini_labyrinth"}

for _, t in pairs (room_enemy_weights) do
	for x = 1, t[2], 1 do
		table.insert(room_enemies, t[1])
	end			
end

local function grow_cell(chunk_position, surface)
	local math_random = math.random
	local modifier_raffle = {{0,-1},{-1,0},{1,0},{0,1}}
	modifier_raffle = shuffle(modifier_raffle)
	local canditate_chunks = {}
	for _, m in pairs(modifier_raffle) do
		local canditate_chunk = {x = chunk_position.x + m[1], y = chunk_position.y + m[2]}
		local left_top_x = canditate_chunk.x * 32
		local left_top_y = canditate_chunk.y * 32		
		local tile = surface.get_tile({left_top_x, left_top_y})
		if tile.name == "out-of-map" then table.insert(canditate_chunks, canditate_chunk) end
	end
	local valid_chunks = {}
	for _, chunk in pairs(canditate_chunks) do		 
		if is_canditate_chunk_valid(chunk, surface) == true then
			table.insert(valid_chunks, {x = chunk.x, y = chunk.y})
		end
	end	
	
	local tree_raffle = {}
	for _, e in pairs(game.entity_prototypes) do
		if e.type == "tree" then
			table.insert(tree_raffle, e.name)
		end			
	end
	
	local allied_entity_raffle = {}
	local types = {"inserter", "inserter", "transport-belt", "transport-belt", "transport-belt","underground-belt", "electric-pole", "electric-pole", "pipe", "furnace", "assembling-machine", "splitter", "splitter", "straight-rail"}
	for _, e in pairs(game.entity_prototypes) do
		for _, t in pairs(types) do
			if e.type == t then
				table.insert(allied_entity_raffle, e.name)				
			end
		end
	end
	
	if #valid_chunks > 0 then global.labyrinth_size = global.labyrinth_size + 1 end	
	local evolution = global.labyrinth_size / labyrinth_difficulty_curve
	if evolution > 1 then evolution = 1 end
	game.forces.enemy.evolution_factor = evolution
	for _, player in pairs(game.connected_players) do
		create_labyrinth_difficulty_gui(player)
	end
	
	for x = 1, math_random(1,#valid_chunks), 1 do
		local chunk_position = valid_chunks[x]
		local left_top_x = chunk_position.x * 32
		local left_top_y = chunk_position.y * 32
		local tile_to_insert = false
		local tiles = {}
		local entities_to_place = {
		rocks = {},
		worms = {},
		enemy_buildings = {},
		trees = {},
		fish = {},		
		biters = {},
		spitters = {},
		gun_turrets = {},
		misc = {},
		allied_entities = {}
		}
		 
		local tree_name = tree_raffle[math_random(1,#tree_raffle)]
		
		local layout = room_layouts[math_random(1,#room_layouts)]
		local enemies = room_enemies[math_random(1,#room_enemies)]
		
		local unique_room = true
		if global.labyrinth_size > 12 and math_random(1,50) == 1 then
			layout = nil
			enemies = nil
			unique_room = unique_room_raffle[math_random(1,#unique_room_raffle)]
		else
			unique_room = false
		end
		--layout = nil
		--enemies = nil		
		--unique_room = "railway_roundabout"
		
		if layout == "quad_rocks" then
			while not entities_to_place.rocks[1] do
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 8, left_top_y + 8}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 24, left_top_y + 8}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 8, left_top_y + 24}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 24, left_top_y + 24}) end
			end
		end
		
		if layout == "single_center_rock" then
			table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16})	
		end
		
		if layout == "tree_and_lake" then
			table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16})	
		end
		
		if layout == "forest_fence" then
			table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16})
		end

		if layout == "forest" then
			while not entities_to_place.rocks[1] do
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 8}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 8, left_top_y + 24}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 24, left_top_y + 24}) end
			end
		end
		
		if layout == "three_horizontal_rocks" then
			while not entities_to_place.rocks[1] do
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 8, left_top_y + 16}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 24, left_top_y + 16}) end
			end
		end
		
		if layout == "three_vertical_rocks" then
			while not entities_to_place.rocks[1] do
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 8}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 24}) end
			end
		end
		
		if unique_room == "flamethrower_cross" or unique_room == "railway_roundabout" then
			table.insert(entities_to_place.rocks, {left_top_x + 6, left_top_y + 6})
			table.insert(entities_to_place.rocks, {left_top_x + 26, left_top_y + 6})
			table.insert(entities_to_place.rocks, {left_top_x + 6, left_top_y + 26})
			table.insert(entities_to_place.rocks, {left_top_x + 26, left_top_y + 26})
		end
		
		local allied_entity
		if enemies == "allied_entities" then
			allied_entity = allied_entity_raffle[math_random(1,#allied_entity_raffle)]
		end
		
		if global.labyrinth_size < 16 then		
			while enemies == "gun_turrets" or enemies == "only_worms" or enemies == "worms_and_spawners" do
				enemies = room_enemies[math_random(1,#room_enemies)]
			end					
		end						
		
		local placed_enemies = 0
		local enemy_counter = global.labyrinth_size
		if enemy_counter > 2000 then enemy_counter = 2000 end
		local random_max = 400
		if global.labyrinth_size > 50 then random_max = 200 end
		if global.labyrinth_size > 100 then random_max = 100 end
		while placed_enemies < enemy_counter do
			if not enemies then break end
			for x = 0, 31, 1 do
				for y = 0, 31, 1 do
					local pos = {x = left_top_x + x, y = left_top_y + y}					
					if enemies == "spawners" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.biters, pos) end
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.spitters, pos) end
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.enemy_buildings, pos) end				
					end
					if enemies == "worms_and_spawners" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.enemy_buildings, pos) end
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.worms, pos) end					
					end
					if enemies == "only_worms" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.worms, pos) end				
					end
					if enemies == "only_biters" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.biters, pos) end				
					end
					if enemies == "only_spitters" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.spitters, pos) end				
					end
					if enemies == "biters_and_spitters" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.biters, pos) end
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.spitters, pos) end							
					end
					if enemies == "gun_turrets" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.gun_turrets, pos) end				
					end
					if enemies == "allied_entities" then												
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.allied_entities, {allied_entity, pos}) end				
					end
					if enemies == "allied_entities_mixed" then
						if math_random(1,random_max) == 1 then
							allied_entity = allied_entity_raffle[math_random(1,#allied_entity_raffle)]
							table.insert(entities_to_place.allied_entities, {allied_entity, pos})
						end				
					end
					
				end
			end
			placed_enemies = #entities_to_place.biters * 0.35 + #entities_to_place.spitters * 0.35 + #entities_to_place.enemy_buildings * 2 + #entities_to_place.worms * 3 + #entities_to_place.gun_turrets * 3 + #entities_to_place.allied_entities
		end	
		
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do				
				local pos = {x = left_top_x + x, y = left_top_y + y}
				tile_to_insert = "dirt-5"
				
				if layout == "tree_and_lake" then
					if x > 12 and x < 20 and y > 12 and y < 20 then
						tile_to_insert = "water"
					end
					if x > 10 and x < 22 and y > 10 and y < 22 then
						if math_random(1,2) == 1 then table.insert(entities_to_place.trees, pos) end
					end					
				end
				
				if layout == "forest" or unique_room == "railway_roundabout" then					
					if math_random(1,6) == 1 then table.insert(entities_to_place.trees, pos) end
				end
				
				if layout == "forest_fence" then
					if x > 28 or x < 4 or y > 28 or y < 4 then				
						if math_random(1,3) == 1 then table.insert(entities_to_place.trees, pos) end
					end
				end
												
				if unique_room then				
					if unique_room == "mini_labyrinth" then
						if math_random(1,4) == 1 then table.insert(entities_to_place.biters, pos) end
					end
					local room = unique_rooms[unique_room]					
					for _, e in pairs(room.entities) do
						if math.floor(e.position.x, 0) == x and math.floor(e.position.y, 0) == y then
							if e.name == "small-biter" or e.name == "medium-biter" or e.name == "big-biter" or e.name == "behemoth-biter" then
								table.insert(entities_to_place.biters, {left_top_x + e.position.x, left_top_y + e.position.y})
								break
							end
							if e.name == "small-spitter" or e.name == "medium-spitter" or e.name == "big-spitter" or e.name == "behemoth-spitter" then
								table.insert(entities_to_place.spitters, {left_top_x + e.position.x, left_top_y + e.position.y})
								break
							end
							table.insert(entities_to_place.misc,
							{name = e.name, position = {left_top_x + e.position.x, left_top_y + e.position.y}, direction = e.direction, force = e.force})
							break
						end						
					end
					for _, t in pairs(room.tiles) do
						if math.floor(t.position.x, 0) == x and math.floor(t.position.y, 0) == y then
							tile_to_insert = t.name
							break
						end						
					end					
				end				
				table.insert(tiles, {name = tile_to_insert, position = pos}) 								
			end							
		end		
		surface.set_tiles(tiles, true)
		
		local decorative_names = {}
		for k,v in pairs(game.decorative_prototypes) do
			if v.autoplace_specification then
				decorative_names[#decorative_names+1] = k
			end
		end										
		surface.regenerate_decorative(decorative_names, {chunk_position})
		
		if unique_room == "railway_roundabout" then
			local e = surface.create_entity {name="big-ship-wreck-1", position={left_top_x + 16, left_top_y + 22}, force = "player"}
			e.insert({name = 'locomotive', count = 1})
			e.insert({name = 'nuclear-fuel', count = 1})
		end
		
		for _, e in pairs(entities_to_place.misc) do			 			
			local entity = surface.create_entity {name = e.name, position = e.position, force = e.force, direction = e.direction}
			if entity.name == "gun-turret" then
				local ammo = "firearm-magazine"
				if global.labyrinth_size > 100 then ammo = "piercing-rounds-magazine" end
				if global.labyrinth_size > 300 then ammo = "uranium-rounds-magazine" end
				entity.insert({name = ammo, count = math.random(50,150)})
			end
			if entity.name == "storage-tank" then
				entity.fluidbox[1] = {name = "crude-oil", amount = 25000}					
			end							
		end
		
		for _, p in pairs(entities_to_place.enemy_buildings) do						
			if math_random(1,3) == 1 then
				if surface.can_place_entity({name="spitter-spawner", position=p}) then surface.create_entity {name="spitter-spawner", position=p} end	
			else
				if surface.can_place_entity({name="biter-spawner", position=p}) then surface.create_entity {name="biter-spawner", position=p} end	
			end		
		end
		
		for _, p in pairs(entities_to_place.worms) do
			local evolution = math.ceil(game.forces.enemy.evolution_factor * 10, 0)
			local raffle = worm_raffle[evolution]
			local n = raffle[math.random(1,#raffle)]
			if surface.can_place_entity({name = n, position = p}) then surface.create_entity {name = n, position = p} end					
		end
		
		local threat_amount = global.labyrinth_size * 4
		
		for _, p in pairs(entities_to_place.biters) do
			local evolution = math.ceil(game.forces.enemy.evolution_factor * 10, 0)
			local raffle = biter_raffle[evolution]
			local n = raffle[math.random(1,#raffle)]			
			if threat_values[n] then
				threat_amount = threat_amount - threat_values[n]	
				if threat_amount < 0 then break end
			end				
			if surface.can_place_entity({name = n, position = p}) then surface.create_entity {name = n, position = p} end				
		end
		
		for _, p in pairs(entities_to_place.spitters) do
			local evolution = math.ceil(game.forces.enemy.evolution_factor * 10, 0)
			local raffle = spitter_raffle[evolution]
			local n = raffle[math.random(1,#raffle)]			
			if threat_values[n] then
				threat_amount = threat_amount - threat_values[n]	
				if threat_amount < 0 then break end
			end				
			if surface.can_place_entity({name = n, position = p}) then surface.create_entity {name = n, position = p} end				
		end						
		
		for _, p in pairs(entities_to_place.gun_turrets) do			
			local e = surface.create_entity {name = "gun-turret", position = p, force = "enemy"}
			local ammo = "firearm-magazine"
			if global.labyrinth_size > 100 then ammo = "piercing-rounds-magazine" end
			if global.labyrinth_size > 300 then ammo = "uranium-rounds-magazine" end
			e.insert({name = ammo, count = math.random(50,150)})
		end
		
		for _, p in pairs(entities_to_place.rocks) do			
			local e = rock_raffle[math.random(1,#rock_raffle)]
			surface.create_entity {name = e, position = p} 				
		end
				
		for _, p in pairs(entities_to_place.allied_entities) do			
			local directions = {defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west}
			local d = directions[math_random(1,#directions)]
			if surface.can_place_entity({name = p[1], position = p[2], direction = d, force = "player"}) then surface.create_entity {name = p[1], position = p[2], direction = d, force = "player"} end		
		end
		
		for _, p in pairs(entities_to_place.trees) do			 
			if surface.can_place_entity({name = tree_name, position = p}) then surface.create_entity {name = tree_name, position = p} end				
		end
		
	end		
end

local function treasure_chest(position, surface)
	local math_random = math.random
	local chest_raffle = {}
	local chest_loot = {					
		{{name = "submachine-gun", count = math_random(1,3)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "slowdown-capsule", count = math_random(16,32)}, weight = 1, evolution_min = 0.0, evolution_max = 1},
		{{name = "poison-capsule", count = math_random(16,32)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "uranium-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.6, evolution_max = 1},
		{{name = "cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.4, evolution_max = 0.7},
		{{name = "explosive-uranium-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.6, evolution_max = 1},
		{{name = "explosive-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "shotgun", count = 1}, weight = 2, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "shotgun-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "combat-shotgun", count = 1}, weight = 10, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "piercing-shotgun-shell", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 1},
		{{name = "flamethrower", count = 1}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "flamethrower-ammo", count = math_random(16,32)}, weight = 5, evolution_min = 0.3, evolution_max = 1},
		{{name = "rocket-launcher", count = 1}, weight = 5, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "rocket", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 0.7},		
		{{name = "explosive-rocket", count = math_random(16,32)}, weight = 10, evolution_min = 0.3, evolution_max = 1},
		{{name = "land-mine", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "grenade", count = math_random(16,32)}, weight = 10, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "cluster-grenade", count = math_random(16,32)}, weight = 5, evolution_min = 0.4, evolution_max = 1},
		{{name = "firearm-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0, evolution_max = 0.3},
		{{name = "piercing-rounds-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0.1, evolution_max = 0.8},
		{{name = "uranium-rounds-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0.5, evolution_max = 1},
		{{name = "railgun", count = 1}, weight = 1, evolution_min = 0.2, evolution_max = 1},
		{{name = "railgun-dart", count = math_random(16,32)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "defender-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.0, evolution_max = 0.7},
		{{name = "distractor-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.2, evolution_max = 1},
		{{name = "destroyer-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.3, evolution_max = 1},
		{{name = "atomic-bomb", count = math_random(8,16)}, weight = 1, evolution_min = 0.3, evolution_max = 1},		
		{{name = "light-armor", count = 1}, weight = 3, evolution_min = 0, evolution_max = 0.1},		
		{{name = "heavy-armor", count = 1}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "modular-armor", count = 1}, weight = 2, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "power-armor", count = 1}, weight = 2, evolution_min = 0.4, evolution_max = 1},
		{{name = "power-armor-mk2", count = 1}, weight = 1, evolution_min = 0.8, evolution_max = 1},
		{{name = "battery-equipment", count = 1}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "battery-mk2-equipment", count = 1}, weight = 2, evolution_min = 0.6, evolution_max = 1},
		{{name = "belt-immunity-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
		{{name = "solar-panel-equipment", count = math_random(1,4)}, weight = 5, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "discharge-defense-equipment", count = 1}, weight = 1, evolution_min = 0.5, evolution_max = 0.8},
		{{name = "energy-shield-equipment", count = math_random(1,2)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "energy-shield-mk2-equipment", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
		{{name = "fusion-reactor-equipment", count = 1}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "night-vision-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "personal-laser-defense-equipment", count = 1}, weight = 2, evolution_min = 0.4, evolution_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
						
		
		{{name = "iron-gear-wheel", count = math_random(80,100)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "copper-cable", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "electric-engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "battery", count = math_random(100,200)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "advanced-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "electronic-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "processing-unit", count = math_random(100,200)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "explosives", count = math_random(25,50)}, weight = 1, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "lubricant-barrel", count = math_random(4,10)}, weight = 1, evolution_min = 0.3, evolution_max = 0.5},
		{{name = "rocket-fuel", count = math_random(4,10)}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "computer", count = 1}, weight = 1, evolution_min = 0.2, evolution_max = 1},
		{{name = "steel-plate", count = math_random(50,100)}, weight = 2, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "nuclear-fuel", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
				
		{{name = "burner-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "long-handed-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},		
		{{name = "fast-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 1},
		{{name = "filter-inserter", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 1},		
		{{name = "stack-filter-inserter", count = math_random(4,8)}, weight = 1, evolution_min = 0.4, evolution_max = 1},
		{{name = "stack-inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},				
		{{name = "small-electric-pole", count = math_random(16,32)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "medium-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.2, evolution_max = 1},
		{{name = "big-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "substation", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "wooden-chest", count = math_random(25,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "iron-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.1, evolution_max = 0.4},
		{{name = "steel-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "small-lamp", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail", count = math_random(50,75)}, weight = 3, evolution_min = 0.1, evolution_max = 0.6},
		{{name = "assembling-machine-1", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "assembling-machine-2", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "assembling-machine-3", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "accumulator", count = math_random(4,8)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "offshore-pump", count = math_random(1,2)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "beacon", count = math_random(1,2)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "boiler", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "steam-engine", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "steam-turbine", count = math_random(1,2)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		--{{name = "nuclear-reactor", count = 1}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "centrifuge", count = math_random(1,2)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-pipe", count = math_random(8,12)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-exchanger", count = math_random(2,4)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "arithmetic-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "constant-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "decider-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "power-switch", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},		
		{{name = "programmable-speaker", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "green-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "red-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "chemical-plant", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "burner-mining-drill", count = math_random(4,8)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "electric-mining-drill", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.6},		
		{{name = "express-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "express-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		{{name = "express-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.3},
		{{name = "transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0, evolution_max = 0.3},		
		{{name = "oil-refinery", count = math_random(1,2)}, weight = 2, evolution_min = 0.3, evolution_max = 1},
		{{name = "pipe", count = math_random(40,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "pipe-to-ground", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 0.5},
		{{name = "pumpjack", count = math_random(1,2)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "pump", count = math_random(1,4)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "solar-panel", count = math_random(4,8)}, weight = 3, evolution_min = 0.4, evolution_max = 0.9},
		{{name = "electric-furnace", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "steel-furnace", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "stone-furnace", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "radar", count = math_random(1,2)}, weight = 1, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "rail-chain-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},		
		{{name = "stone-wall", count = math_random(25,75)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "gate", count = math_random(4,8)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "storage-tank", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "train-stop", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "express-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "lab", count = math_random(2,4)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},
	
		--{{name = "roboport", count = math_random(2,4)}, weight = 2, evolution_min = 0.6, evolution_max = 1},
		--{{name = "flamethrower-turret", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		--{{name = "laser-turret", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},	
		{{name = "gun-turret", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.9}		
	}		
	for _, t in pairs (chest_loot) do
		for x = 1, t.weight, 1 do
			if t.evolution_min <= game.forces.enemy.evolution_factor and t.evolution_max >= game.forces.enemy.evolution_factor then
				table.insert(chest_raffle, t[1])
			end
		end			
	end
	local chest_type_raffle = {"steel-chest", "iron-chest", "wooden-chest"}
	local e = surface.create_entity {name = chest_type_raffle[math_random(1,#chest_type_raffle)], position = position, force = "player"}
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math_random(3,4), 1 do
		local loot = chest_raffle[math_random(1,#chest_raffle)]
		i.insert(loot)
	end		
end

local function spawn_infinity_chest(pos, surface)
	local math_random = math.random
	local infinity_chests = {		
		--{"raw-wood", math_random(1,3)},
		{"coal", 1},		
		{"stone", math_random(3,5)},
		{"stone", math_random(3,5)},
		{"stone", math_random(3,5)},
		{"stone", math_random(3,5)},
		{"stone", math_random(3,5)},		
		{"iron-ore", 1},		
		{"copper-ore", 1},								
	}
	local x = math_random(1, #infinity_chests)
	local e = surface.create_entity {name = "infinity-chest", position = pos, force = "player"}
	e.set_infinity_container_filter(1, {name = infinity_chests[x][1], count = infinity_chests[x][2]})
	e.minable = false
	e.destructible = false
	e.operable = false
end


local biter_fragmentation = {
	{"medium-biter","small-biter",2,3},
	{"big-biter","medium-biter",2,2},
	{"behemoth-biter","big-biter",2,2}
}

local biter_building_inhabitants = {}
biter_building_inhabitants[1] = {{"small-biter",8,16}}
biter_building_inhabitants[2] = {{"small-biter",12,24}}
biter_building_inhabitants[3] = {{"small-biter",8,16},{"medium-biter",1,2}}
biter_building_inhabitants[4] = {{"small-biter",4,8},{"medium-biter",4,8}}
biter_building_inhabitants[5] = {{"small-biter",3,5},{"medium-biter",8,12}}
biter_building_inhabitants[6] = {{"small-biter",3,5},{"medium-biter",5,7},{"big-biter",1,2}}
biter_building_inhabitants[7] = {{"medium-biter",6,8},{"big-biter",3,5}}
biter_building_inhabitants[8] = {{"medium-biter",2,4},{"big-biter",6,8}}
biter_building_inhabitants[9] = {{"medium-biter",2,3},{"big-biter",7,9}}
biter_building_inhabitants[10] = {{"big-biter",4,8},{"behemoth-biter",3,4}}

local entity_drop_amount = {
    ['small-biter'] = {low = 10, high = 20},
    ['small-spitter'] = {low = 10, high = 20},
    ['medium-spitter'] = {low = 15, high = 30},
    ['big-spitter'] = {low = 20, high = 40},
    ['behemoth-spitter'] = {low = 30, high = 50},
	['biter-spawner'] = {low = 50, high = 100},
	['spitter-spawner'] = {low = 50, high = 100}
}
local ore_spill_raffle = {"iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","coal","coal","stone", "landfill"}
local ore_spawn_raffle = {"iron-ore","iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","uranium-ore","crude-oil"}

local function on_entity_died(event)	
	for _, fragment in pairs(biter_fragmentation) do
		if event.entity.name == fragment[1] then
			for x=1,math.random(fragment[3],fragment[4]),1 do
				local p = event.entity.surface.find_non_colliding_position(fragment[2] , event.entity.position, 2, 1)				
				if p then event.entity.surface.create_entity {name=fragment[2], position=p} end
				p = nil				
			end
			return
		end
	end
	
	if event.entity.name == "biter-spawner" or event.entity.name == "spitter-spawner" then
		local e = math.ceil(game.forces.enemy.evolution_factor*10, 0)		
		for _, t in pairs (biter_building_inhabitants[e]) do		
			for x = 1, math.random(t[2],t[3]), 1 do
				local p = event.entity.surface.find_non_colliding_position(t[1] , event.entity.position, 6, 1)			
				if p then event.entity.surface.create_entity {name=t[1], position=p} end
			end
		end
	end
	
	if entity_drop_amount[event.entity.name] then
		if game.forces.enemy.evolution_factor < 0.5 then
			local evolution_drop_modifier = (0.1 - game.forces.enemy.evolution_factor) * 10
			if evolution_drop_modifier > 0 then
				local amount = math.ceil(math.random(entity_drop_amount[event.entity.name].low, entity_drop_amount[event.entity.name].high) * evolution_drop_modifier)			 
				event.entity.surface.spill_item_stack(event.entity.position,{name = ore_spill_raffle[math.random(1,#ore_spill_raffle)], count = amount},true)
			end
		end
		return
	end

	if event.entity.name == "sand-rock-big" or event.entity.name == "rock-big" or event.entity.name == "rock-huge" then
		local pos = {x = event.entity.position.x, y = event.entity.position.y}
		local surface = event.entity.surface
		if event.entity.name == "rock-huge" then spawn_infinity_chest(pos, surface) end
		if event.entity.name == "rock-big" then treasure_chest(pos, surface) end
		if event.entity.name == "sand-rock-big" then
			local n = ore_spawn_raffle[math.random(1,#ore_spawn_raffle)]
			--local amount_modifier = 1 + ((global.labyrinth_size / labyrinth_difficulty_curve) * 10)
			local amount_modifier = math.ceil(1 + game.forces.enemy.evolution_factor * 5)
			
			if n == "crude-oil" then				
				map_functions.draw_oil_circle(pos, n, surface, 6, 100000 * amount_modifier)
			else				
				map_functions.draw_smoothed_out_ore_circle(pos, n, surface, 9 + amount_modifier, 200 * amount_modifier)
			end
		end
		event.entity.destroy()
		local chunk_position = get_entity_chunk_position(pos)		
		local b = is_chunk_allowed_to_grow(chunk_position, surface)		
		if b == true then
			grow_cell(chunk_position, surface)			
		end		
	end
end

local function on_player_mined_entity(event)
	if event.entity.name == "sand-rock-big" or event.entity.name == "rock-big" or event.entity.name == "rock-huge" then
		event.entity.die()
	end
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	local noise_seed_add = 25000
	if name == "ocean" then		
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		local noise = noise[1]
		return noise
	end
	seed = seed + noise_seed_add
	if name == "island" then		
		noise[1] = simplex_noise(pos.x * 0.002, pos.y * 0.002, seed)
		seed = seed + noise_seed_add
		local noise = noise[1]
		return noise
	end
end

local function on_chunk_generated(event)
	local surface = game.surfaces["labyrinth"] 
	if event.surface.name ~= surface.name then return end
	local math_random = math.random
	local entities_to_place = {
		rocks = {},
		worms = {},
		enemy_buildings = {},
		trees = {},
		fish = {},		
		shipwrecks = {}		
	}	
	local decoratives = {}
	local tiles = {}
	local tile_to_insert = false
	local chunk_position_x = event.area.left_top.x / 32
	local chunk_position_y = event.area.left_top.y / 32
	
		
	--if not global.spawn_ores_generated then
	--	if event.area.left_top.x > 96 then
	--		map_functions.draw_rainbow_patch({x = 16, y = 16}, surface, 9, 1000)				
	--		global.spawn_ores_generated = true
	--	end
	--end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			tile_to_insert = false
			local pos = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}			 
			if chunk_position_y >= 0 then
				tile_to_insert = "water"
				local noise = get_noise("ocean", pos)				
				if math.floor(noise * 10) % 2 == 1 then
					tile_to_insert = "deepwater"
				end					
								
				if pos.y >= 196 + noise * 20 then	
					local noise = get_noise("island", pos)
					if noise > 0.85 then tile_to_insert = "grass-1" end
					if noise > 0.88 then						
						if math_random(1,50) == 1 then
							local a = {
								left_top = {x = pos.x - 100, y = pos.y - 100},
								right_bottom = {x = pos.x + 100, y = pos.y + 100}
							}
							if surface.count_entities_filtered{area = a, name = "infinity-chest", limit = 1} == 0 then
								local e = surface.create_entity {name="infinity-chest", position = pos, force = "player"}
								e.minable = false
								e.destructible = false
								e.operable = false
								e.remove_unfiltered_items = true
							end
						else
							if math_random(1,15) == 1 then surface.create_entity {name="tree-05", position=pos} end
						end
					end
				end
			end
			if chunk_position_x == 0 and chunk_position_y == 0 then
				tile_to_insert = "grass-1"				
			end
			if chunk_position_x == 0 and chunk_position_y == -1 then
				tile_to_insert = "dirt-5"
			end			
			if tile_to_insert == false then
				table.insert(tiles, {name = "out-of-map", position = pos})
			else
				if tile_to_insert == "water" or tile_to_insert == "deepwater" then
					if math_random(1,180) == 1 then table.insert(entities_to_place.fish, pos) end					
				end
				table.insert(tiles, {name = tile_to_insert, position = pos}) 
			end					
		end							
	end		
	surface.set_tiles(tiles,true)										
	for _, p in pairs(entities_to_place.fish) do					
		surface.create_entity {name="fish",position=p}				
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "0.01"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 50, cliff_elevation_0 = 50}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}		
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("labyrinth", map_gen_settings)		
		game.forces["player"].set_spawn_position({16, 0},game.surfaces["labyrinth"])
		local surface = game.surfaces["labyrinth"]
		surface.create_entity {name="rock-big",position={16,-16}}
		
		--game.forces["player"].technologies["gun-turret-damage-1"].enabled = false
		--game.forces["player"].technologies["gun-turret-damage-2"].enabled = false
		--game.forces["player"].technologies["gun-turret-damage-3"].enabled = false
		--game.forces["player"].technologies["gun-turret-damage-4"].enabled = false
		--game.forces["player"].technologies["gun-turret-damage-5"].enabled = false
		--game.forces["player"].technologies["gun-turret-damage-6"].enabled = false
		--game.forces["player"].technologies["gun-turret-damage-7"].enabled = false
		game.forces["player"].technologies["artillery"].enabled = false
		game.forces["player"].technologies["artillery-shell-range-1"].enabled = false		
		game.forces["player"].technologies["artillery-shell-speed-1"].enabled = false						
		game.forces["player"].technologies["atomic-bomb"].enabled = false	
		
		--game.forces["player"].set_ammo_damage_modifier("flamethrower", -0.95)
		--game.forces["player"].set_turret_attack_modifier("flamethrower-turret", -0.95)
		--game.forces["player"].set_turret_attack_modifier("gun-turret", -0.25)
		--game.forces["player"].set_turret_attack_modifier("laser-turret", -0.75)
		
		if not global.labyrinth_size then	global.labyrinth_size = 1 end
		global.map_init_done = true						
	end	
	local surface = game.surfaces["labyrinth"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {16, 0}, 2, 1), "labyrinth")
	else
		if player.online_time < 5 then
			player.teleport({16, 0}, "labyrinth")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}				
		player.insert {name = 'pistol', count = 1}
		player.insert {name = 'firearm-magazine', count = 64}
		--player.insert {name = 'landfill', count = 10240}
	end
	create_labyrinth_difficulty_gui(player)
end

local inserters = {"inserter", "long-handed-inserter", "burner-inserter", "fast-inserter", "filter-inserter", "stack-filter-inserter", "stack-inserter"}
local loaders = {"loader", "fast-loader", "express-loader"}
local function on_built_entity(event)
	local get_score = Score.get_table().score_table
	for _, e in pairs(inserters) do
		if e == event.created_entity.name then			
			local surface = event.created_entity.surface
			local a = {
			left_top = {x = event.created_entity.position.x - 2, y = event.created_entity.position.y - 2},
			right_bottom = {x = event.created_entity.position.x + 2, y = event.created_entity.position.y + 2}
			}
			local chest = surface.find_entities_filtered{area = a, name = "infinity-chest", limit = 1}
			if not chest[1] then return end
			local a = {
			left_top = {x = chest[1].position.x - 2, y = chest[1].position.y - 2},
			right_bottom = {x = chest[1].position.x + 2, y = chest[1].position.y + 2}
			}
			local i = surface.find_entities_filtered{area = a, name = inserters}
			if not i[1] then return end
			if #i > 1 then
				if math.random(1,11) == 1 then
					break
				else
					for _, x in pairs (i) do
						x.die("enemy")
					end
					if event.player_index then
						local player = game.players[event.player_index]
						player.print("The mysterious chest noticed your greed and devoured your devices.", { r=0.75, g=0.0, b=0.0})
					end
				end
			end
			break
		end
	end
	
	for _, e in pairs(loaders) do
		if e == event.created_entity.name then
			local surface = event.created_entity.surface
			local a = {
			left_top = {x = event.created_entity.position.x - 2, y = event.created_entity.position.y - 2},
			right_bottom = {x = event.created_entity.position.x + 2, y = event.created_entity.position.y + 2}
			}
			local found = surface.find_entities_filtered{area = a, name = "infinity-chest"}						
			if found[1] then 
				event.created_entity.die("enemy")
				if event.player_index then
					local player = game.players[event.player_index]
					player.print("The mysterious chest noticed your greed and devoured your device.", { r=0.75, g=0.0, b=0.0})
				end
			end
		end
	end
		
	local name = event.created_entity.name
	if name == "flamethrower-turret" or name == "laser-turret" then
		if event.created_entity.position.y < 0 then 					
			if event.player_index then
				local player = game.players[event.player_index]
				player.insert({name = name, count = 1})
				event.created_entity.destroy()
				if get_score then
					if get_score[player.force.name] then
						if get_score[player.force.name].players[player.name] then
							get_score[player.force.name].players[player.name].built_entities = get_score[player.force.name].players[player.name].built_entities - 1
						end
					end
				end
				player.print("The device seems to be malfunctioning in this strange place.", { r=0.75, g=0.0, b=0.0})
			else
				if event.robot then
					local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
					inventory.insert({name = name, count = 1})
					event.created_entity.destroy()
				end
			end
		end
	end
	
	if name == "gun-turret" then
		local surface = event.created_entity.surface		
		local amount_of_enemy_structures = surface.count_entities_filtered({
			name = {"spitter-spawner", "biter-spawner"},
			area = {{event.created_entity.position.x - 18, event.created_entity.position.y - 18},{event.created_entity.position.x + 18, event.created_entity.position.y + 18}},
			force = "enemy",
			limit = 1			
			})
		
		if event.player_index and amount_of_enemy_structures > 0 then
			local player = game.players[event.player_index]
			player.insert({name = name, count = 1})
			event.created_entity.destroy()
			player.print("Their nests aura seems to deny the placement of any close turrets.", { r=0.75, g=0.0, b=0.0})
			if get_score then
				if get_score[player.force.name] then
					if get_score[player.force.name].players[player.name] then
						get_score[player.force.name].players[player.name].built_entities = get_score[player.force.name].players[player.name].built_entities - 1
					end
				end
			end					
		end
		
		if event.robot and amount_of_enemy_structures > 0 then
			local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
			inventory.insert({name = name, count = 1})
			event.created_entity.destroy()
		end
	end
end

local function on_robot_built_entity(event)
	on_built_entity(event)
end

local function on_entity_damaged(event)
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
		local rock_is_alive = true
		if event.force.name == "enemy" then 
			event.entity.health = event.entity.health + event.final_damage_amount
			if event.entity.health <= event.final_damage_amount then				
				rock_is_alive = false
			end			
		end
	end
end

local attack_messages = {
		"You hear their screeching in the depths. They are trying to reach the entrance!",
		"They are coming for you..",
		"Something stirred them up..",
		"Something must have triggered them..",
		"These noises, this can´t be good.."
	}
	
local function on_tick(event)
	if game.tick % 4600 == 0 then		
		if math.random(1, 6) ~= 1 then return end
		local surface = game.surfaces["labyrinth"]
		local area = {{-10000, -10000}, {10000, 0}}
		local biters = surface.find_entities_filtered({type = "unit", force = "enemy", area = area})
		for _, biter in pairs(biters) do		
			biter.set_command({type=defines.command.attack_area, destination={x = 16, y = 16}, radius=15, distraction=defines.distraction.by_anything})	
		end
		if #biters > 0 then
			game.print(attack_messages[math.random(1, #attack_messages)], {r=0.75, g=0, b=0})
		end
	end
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
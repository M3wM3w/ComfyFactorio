local Public = {}

local BiterRaffle = require "functions.biter_raffle"
local LootRaffle = require "functions.loot_raffle"
local Get_noise = require "utils.get_noise"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor

function Public.get_dungeon_evolution_factor()
	local e = global.dungeons.depth * 0.0005
	return e
end

function Public.roll_spawner_name()
	if math_random(1, 3) == 1 then
		return "spitter-spawner"
	end
	return "biter-spawner"
end

function Public.roll_worm_name()
	return BiterRaffle.roll("worm", Public.get_dungeon_evolution_factor())
end

function Public.get_crude_oil_amount()
	return math_random(200000, 400000) + global.dungeons.depth * 500
end

function Public.get_common_resource_amount()
	return math_random(350, 700) + global.dungeons.depth * 8
end

function Public.common_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 2 + math_random(8, 16), 16)
	local container = surface.create_entity({name = "wooden-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
	container.minable = false
end

function Public.uncommon_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 4 + math_random(32, 64), 16)
	local container = surface.create_entity({name = "iron-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
	container.minable = false
end

function Public.rare_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 8 + math_random(128, 256), 32)
	local container = surface.create_entity({name = "steel-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
	container.minable = false
end

function Public.epic_loot_crate(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 16 + math_random(512, 1024), 48)
	local container = surface.create_entity({name = "steel-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
	container.minable = false
end

function Public.crash_site_chest(surface, position)
	local item_stacks = LootRaffle.roll(global.dungeons.depth * 6 + math_random(160, 320), 48)
	local container = surface.create_entity({name = "crash-site-chest-" .. math_random(1, 2), position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
end

function Public.add_room_loot_crates(surface, room)
	if not room.room_border_tiles[1] then return end
	for key, tile in pairs(room.room_tiles) do
		if math_random(1, 384) == 1 then
			Public.common_loot_crate(surface, tile.position)
		else
			if math_random(1, 1024) == 1 then
				Public.uncommon_loot_crate(surface, tile.position)
			else
				if math_random(1, 4096) == 1 then
					Public.rare_loot_crate(surface, tile.position)
				else
					if math_random(1, 16384) == 1 then
						Public.epic_loot_crate(surface, tile.position)
					end
				end
			end
		end		
	end		
end

function Public.set_spawner_tier(spawner)
	local tier = math_floor(Public.get_dungeon_evolution_factor() * 8 - math_random(0, 8)) + 1
	if tier < 1 then tier = 1 end		
	global.dungeons.spawner_tier[spawner.unit_number] = tier
	--[[
	rendering.draw_text{
		text = "-Tier " .. tier .. "-",
		surface = spawner.surface,
		target = spawner,
		target_offset = {0, -2.65},
		color = {25, 0, 100, 255},
		scale = 1.25,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	]]
end

function Public.spawn_random_biter(surface, position)
	local name = BiterRaffle.roll("mixed", Public.get_dungeon_evolution_factor())
	local non_colliding_position = surface.find_non_colliding_position(name, position, 16, 1)
	local unit
	if non_colliding_position then
		unit = surface.create_entity({name = name, position = non_colliding_position, force = "enemy"})
	else
		unit = surface.create_entity({name = name, position = position, force = "enemy"})
	end	
	unit.ai_settings.allow_try_return_to_spawner = false
	unit.ai_settings.allow_destroy_when_commands_fail = false
end

function Public.place_border_rock(surface, position)
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	table_shuffle_table(vectors)
	local key = false
	for k, v in pairs(vectors) do
		local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
		if tile.name == "out-of-map" then
			key = k
			break
		end
	end		
	local pos = {x = position.x + 0.5, y = position.y + 0.5}
	if key then
		pos = {pos.x + vectors[key][1] * 0.45, pos.y + vectors[key][2] * 0.45}
	end	
	surface.create_entity({name = "rock-big", position = pos})
end

function Public.mining_events(entity)
	if math_random(1, 16) == 1 then Public.spawn_random_biter(entity.surface, entity.position) return end
	if math_random(1, 24) == 1 then Public.common_loot_crate(entity.surface, entity.position) return end
	if math_random(1, 128) == 1 then Public.uncommon_loot_crate(entity.surface, entity.position) return end
	if math_random(1, 512) == 1 then Public.rare_loot_crate(entity.surface, entity.position) return end
	if math_random(1, 1024) == 1 then Public.epic_loot_crate(entity.surface, entity.position) return end
end

function Public.draw_spawn(surface)
	local spawn_size = global.dungeons.spawn_size

	for _, e in pairs(surface.find_entities({{spawn_size * -1, spawn_size * -1}, {spawn_size, spawn_size}})) do
		e.destroy()
	end
	
	local tiles = {}
	local i = 1
	for x = spawn_size * -1, spawn_size, 1 do
		for y = spawn_size * -1, spawn_size, 1 do
			local position = {x = x, y = y}
			if math_abs(position.x) < 2 or math_abs(position.y) < 2 then
				tiles[i] = {name = "dirt-7", position = position}
				i = i + 1
				tiles[i] = {name = "stone-path", position = position}
				i = i + 1
			else	
				tiles[i] = {name = "dirt-7", position = position}
				i = i + 1
			end		
		end
	end
	surface.set_tiles(tiles, true)

	local tiles = {}
	local i = 1
	for x = -2, 2, 1 do
		for y = -2, 2, 1 do
			local position = {x = x, y = y}
			if math_abs(position.x) > 1 or math_abs(position.y) > 1 then
				tiles[i] = {name = "black-refined-concrete", position = position}
				i = i + 1
			else
				tiles[i] = {name = "purple-refined-concrete", position = position}
				i = i + 1
			end		
		end
	end
	surface.set_tiles(tiles, true)
	
	local tiles = {}
	local i = 1
	for x = spawn_size * -1, spawn_size, 1 do
		for y = spawn_size * -1, spawn_size, 1 do
			local position = {x = x, y = y}
			local r = math.sqrt(position.x ^ 2 + position.y ^ 2)	
			if r < 2 then
				tiles[i] = {name = "purple-refined-concrete", position = position}
				i = i + 1
			else
				if r < 2.5 then
					tiles[i] = {name = "black-refined-concrete", position = position}
					i = i + 1
				else
					if r < 4.5 then
						tiles[i] = {name = "dirt-7", position = position}
						i = i + 1
						tiles[i] = {name = "concrete", position = position}
						i = i + 1
					end
				end
			end		
		end
	end
	surface.set_tiles(tiles, true)
	
	local decoratives = {"brown-hairy-grass", "brown-asterisk", "brown-fluff", "brown-fluff-dry", "brown-asterisk", "brown-fluff", "brown-fluff-dry"}
	local a = spawn_size * -1 + 1
	local b = spawn_size - 1
	for _, decorative_name in pairs(decoratives) do
		local seed = game.surfaces[1].map_gen_settings.seed + math_random(1, 1000000)
		for x = a, b, 1 do
			for y = a, b, 1 do
				local position = {x = x + 0.5, y = y + 0.5}
				if surface.get_tile(position).name == "dirt-7" or math_random(1, 5) == 1 then 
					local noise = Get_noise("decoratives", position, seed)
					if math_abs(noise) > 0.37 then
						surface.create_decoratives{check_collision = false, decoratives = {{name = decorative_name, position = position, amount = math.floor(math.abs(noise * 3)) + 1}}}
					end	
				end
			end
		end
	end
	
	local entities = {}
	local i = 1
	for x = spawn_size * -1 - 16, spawn_size + 16, 1 do
		for y = spawn_size * -1 - 16, spawn_size + 16, 1 do
			local position = {x = x, y = y}
			if position.x <= spawn_size and position.y <= spawn_size and position.x >= spawn_size * -1 and position.y >= spawn_size * -1 then
				if position.x == spawn_size then
					entities[i] = {name = "rock-big", position = {position.x + 0.95, position.y}}
					i = i + 1
				end
				if position.y == spawn_size then
					entities[i] = {name = "rock-big", position = {position.x, position.y + 0.95}}
					i = i + 1
				end
				if position.x == spawn_size * -1 or position.y == spawn_size * -1 then
					entities[i] = {name = "rock-big", position = position}
					i = i + 1
				end
			end
		end
	end
	
	for k, e in pairs(entities) do
		if k % 3 > 0 then surface.create_entity(e) end
	end
	
	local trees = { "dead-grey-trunk", "dead-tree-desert", "dry-hairy-tree", "dry-tree", "tree-04"}
	local size_of_trees = #trees
	local r = 4
	for x = spawn_size * -1, spawn_size, 1 do
		for y = spawn_size * -1, spawn_size, 1 do
			local position = {x = x + 0.5, y = y + 0.5}
			if position.x > 5 and position.y > 5 and math_random(1, r) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
			end
			if position.x <= -4 and position.y <= -4 and math_random(1, r) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
			end	
			if position.x > 5 and position.y <= -4 and math_random(1, r) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
			end	
			if position.x <= -4 and position.y > 5 and math_random(1, r) == 1 then
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = position})
			end				
		end
	end
	surface.set_tiles(tiles, true)
end

return Public
local random = math.random
local abs = math.abs
local max = math.max
local min = math.min
local floor = math.floor
local Functions = require "maps.chronosphere.world_functions"
local Raffle = require "maps.chronosphere.raffles"
local Chrono_table = require 'maps.chronosphere.table'

local function process_tile(p, seed, tiles, entities, treasure)
  local objective = Chrono_table.get_table()
  local biters = objective.world.variant.biters
	local noise1 = Functions.get_noise("forest_location", p, seed)
	if noise1 > 0.095 then
		if noise1 > 0.6 then
			if random(1,100) > 42 then entities[#entities + 1] = {name = "tree-08-brown", position = p} end
		else
			if random(1,100) > 42 then entities[#entities + 1] = {name = "tree-01", position = p} end
		end
		return
  else
    if random(1,152 - biters) == 1 and Functions.distance(p.x, p.y) > 200 then entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true} end
  end

	if noise1 < -0.095 then
		if noise1 < -0.6 then
			if random(1,100) > 42 then entities[#entities + 1] = {name = "tree-04", position = p} end
		else
			if random(1,100) > 42 then entities[#entities + 1] = {name = "tree-02-red", position = p} end
		end
		return
  else
    if random(1,152 - biters) == 1 and Functions.distance(p.x, p.y) > 200 then entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true} end
  end
end

local function normal_chunk(surface, left_top)
  local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
  for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_tile(p, seed, tiles, entities, treasure)
		end
	end
  surface.set_tiles(tiles, true)
  Functions.spawn_treasures(surface, treasure)
  Functions.spawn_entities(surface, entities)
end

local function empty_chunk(surface, left_top)
	local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed

	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_tile(p, seed, tiles, entities, treasure)
		end
	end
	surface.set_tiles(tiles, true)
  Functions.replace_water(surface, left_top)
end

local function forest(variant, surface, left_top)
  local id = variant.id

  if abs(left_top.y) <= 31 and abs(left_top.x) <= 31 then empty_chunk(surface, left_top) return end
  if abs(left_top.y) > 31 or abs(left_top.x) > 31 then normal_chunk(surface, left_top) return end
end

return forest

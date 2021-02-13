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
  local richness = random(50 + 20 * objective.chronojumps, 100 + 20 * objective.chronojumps) * objective.world.ores.factor * 0.5
  local iron_size = 0.24
  local copper_size = 0.24
  local stone_size = 0.24
  local coal_size = 0.32
  local noise1 = Functions.get_noise("large_caves", p, seed)
	local noise2 = Functions.get_noise("cave_rivers", p, seed)
  local noise3 = Functions.get_noise("ores", p, seed)
  local noise4 = Functions.get_noise("forest_location", p, seed)

	--Chasms
	local noise5 = Functions.get_noise("cave_ponds", p, seed)
	local noise6 = Functions.get_noise("small_caves", p, seed)
	if noise5 < 0.45 and noise5 > -0.45 then
		if noise6 > 0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if noise6 < -0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if noise1 > -0.05 and noise1 < 0.05 and noise2 < 0.25 then
		tiles[#tiles + 1] = {name = "water-green", position = p}
		if random(1,128) == 1 then entities[#entities + 1] = {name = "fish", position = p} end
		return
  elseif noise1 > -0.20 and noise1 < 0.20 and abs(noise2) < 0.95 then
    if noise3 > -coal_size and noise3 < coal_size then
      entities[#entities + 1] = {name = "coal", position = p, amount = richness}
    end
	end

	if noise2 > -0.70 and noise2 < 0.70 then
		if random(1,48) == 1 then entities[#entities + 1] = {name = Raffle.trees[random(1, #Raffle.trees)], position = p} end
    if noise2 > -0.05 and noise2 < 0.05 then
      if noise3 > -iron_size and noise3 < iron_size then
        entities[#entities + 1] = {name = "iron-ore", position = p, amount = richness}
      end
    elseif noise2 > -0.10 and noise2 < 0.10 then
      if noise3 > -copper_size and noise3 < copper_size then
        entities[#entities + 1] = {name = "copper-ore", position = p, amount = richness}
      end
    end
	else
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
    if noise3 > -stone_size and noise3 < stone_size then
      entities[#entities + 1] = {name = "stone", position = p, amount = richness}
    end
		if random(1,52 - biters) == 1 and Functions.distance(p.x, p.y) > 200 then entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true} end
	end
	if Functions.distance(p.x, p.y) > 175 and noise2 > -0.70 and noise2 < 0.70 then
    if random(1, 2048) == 1 then treasure[#treasure + 1] = p end
  end
  if noise4 > 0.9 then
		if random(1,100) > 42 then entities[#entities + 1] = {name = Raffle.trees[random(1, #Raffle.trees)], position = p} end
		return
  end

	if noise4 < -0.9 then
		if random(1,100) > 42 then entities[#entities + 1] = {name = Raffle.trees[random(1, #Raffle.trees)], position = p} end
		return
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

local function riverlands(variant, surface, left_top)
  local id = variant.id

  if abs(left_top.y) <= 31 and abs(left_top.x) <= 31 then empty_chunk(surface, left_top) return end
  if abs(left_top.y) > 31 or abs(left_top.x) > 31 then normal_chunk(surface, left_top) return end
end

return riverlands

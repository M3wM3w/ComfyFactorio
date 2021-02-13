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
  local noise1 = Functions.get_noise("scrapyard", p, seed)
  local biters = objective.world.variant.biters
  local evo = game.forces["enemy"].evolution_factor
  local handicap = max(0, 120 - objective.chronojumps * 20)

  if noise1 < -0.70 or noise1 > 0.70 then
    tiles[#tiles + 1] = {name = "grass-3", position = p}
    if random(1,40) == 1 then treasure[#treasure + 1] = p end
    return
  end

  if noise1 < -0.65 or noise1 > 0.65 then
    tiles[#tiles + 1] = {name = "water-green", position = p}
    return
  end
  if abs(noise1) > 0.50 and  abs(noise1) < 0.65 then
    if random(1,70) == 1 and Functions.distance(p.x, p.y) > 170 + handicap then
      entities[#entities + 1] = {name = Raffle.worms[random(1 + floor(evo * 8), floor(1 + evo * 16))], position = p, spawn_decorations = true}
    end
    tiles[#tiles + 1] = {name = "water-mud", position = p}
    return
  end
  if abs(noise1) > 0.35 and  abs(noise1) < 0.50 then
    if random(1,140) == 1 and Functions.distance(p.x, p.y) > 180 + handicap then
      entities[#entities + 1] = {name = Raffle.worms[random(1 + floor(evo * 8), floor(1 + evo * 16))], position = p, spawn_decorations = true}
    end
    tiles[#tiles + 1] = {name = "water-shallow", position = p}
    return
  end
  if noise1 > -0.15 and noise1 < 0.15 then
    if random(1,100) > 58 then
      entities[#entities + 1] = {name = Raffle.trees[random(1, #Raffle.trees)], position = p}
    else
      if random(1,8) == 1 then entities[#entities + 1] = {name = Raffle.rocks[random(1, #Raffle.rocks)], position = p} end
    end
    tiles[#tiles + 1] = {name = "grass-1", position = p}
    return
  end
	if random(1, 160) == 1 and Functions.distance(p.x, p.y) > 150 + handicap then
		entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true}
	end
	tiles[#tiles + 1] = {name = "grass-2", position = p}
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

local function swamp(variant, surface, left_top)
  local id = variant.id

  if abs(left_top.y) <= 63 and abs(left_top.x) <= 63 then empty_chunk(surface, left_top) end
  if abs(left_top.y) > 63 or abs(left_top.x) > 63 then normal_chunk(surface, left_top) end
end

return swamp

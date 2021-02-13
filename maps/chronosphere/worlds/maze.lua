local random = math.random
local abs = math.abs
local max = math.max
local min = math.min
local floor = math.floor
local Functions = require "maps.chronosphere.world_functions"
local Raffle = require "maps.chronosphere.raffles"
local Chrono_table = require 'maps.chronosphere.table'
local Ores = require "maps.chronosphere.ores"
local Specials = require "maps.chronosphere.terrain_specials"

local function path_tile(p, tiles, entities, treasure, things)
  local objective = Chrono_table.get_table()
  local biters = objective.world.variant.biters
  if things then
    if things == "lake" and p.x % 32 > 8 and p.x % 32 < 24 and p.y % 32 > 8 and p.y % 32 < 24 then
      tiles[#tiles + 1] = {name = "water", position = p}
      return
    elseif things == "prospect" then
      if random(1,252 - biters) == 1 and Functions.distance(p.x, p.y) > 250 then entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true} end
    elseif things == "camp" then
      if p.x % 32 > 12 and p.x % 32 < 20 and p.y % 32 > 12 and p.y % 32 < 20 then
        if random(1,10) == 1 then treasure[#treasure + 1] = p end
      elseif p.x % 32 == 11 or p.x % 32 == 12 or p.y % 32 == 11 or p.y % 32 == 12 or p.x % 32 == 21 or p.x % 32 == 20 or p.y % 32 == 21 or p.y % 32 == 20 then
        if random(1,14) == 1 then entities[#entities + 1] = {name = "land-mine", position = p, force = "scrapyard"} end
      end
    elseif things == "crashsite" then
      if random(1,2) == 1 then
        entities[#entities + 1] = {name = Raffle.scraps[random(1, #Raffle.scraps)], position = p, force = "neutral"}
      end
    elseif things == "treasure" then
      local roll = random(1,128)
      if roll <= 2 then
        treasure[#treasure + 1] = p
      elseif roll > 2 and roll < 10 then
        entities[#entities + 1] = {name = "land-mine", position = p, force = "scrapyard"}
      end
    end
  else
    if random(1, 150) == 1 and Functions.distance(p.x, p.y) > 200 then
      local evo = game.forces["enemy"].evolution_factor
      entities[#entities + 1] = {name = Raffle.worms[random(1 + floor(evo * 8), floor(1 + evo * 16))], position = p, spawn_decorations = true}
    end
  end
end

local function process_tile(p, seed, tiles, entities, treasure, cell, things)
  local mazenoise = Functions.get_noise("hedgemaze", {x = p.x - p.x % 32, y = p.y - p.y % 32}, seed)
  local lake_noise_value = -0.85

  if mazenoise < lake_noise_value and Functions.distance(p.x - p.x % 32, p.y - p.y % 32) > 65 then
	  tiles[#tiles + 1] = {name = "deepwater", position = p}
    if random(1, 256) == 1 then entities[#entities + 1] = {name = "fish", position = p} end
    return
  elseif mazenoise > 0.7 then
    if cell then --path
      tiles[#tiles + 1] = {name = "dirt-4", position = p}
      path_tile(p, tiles, entities, treasure, things)
    else --wall
      tiles[#tiles + 1] = {name = "dirt-6", position = p}
      if random(1,3) == 1 then
        entities[#entities + 1] = {name = Raffle.dead_trees[random(1, #Raffle.dead_trees)], position = p}
      else
        if random(1,4) == 1 then entities[#entities + 1] = {name = Raffle.rocks[random(1, #Raffle.rocks)], position = p} end
      end
    end
  else
    if cell then --path
      tiles[#tiles + 1] = {name = "grass-1", position = p}
      path_tile(p, tiles, entities, treasure, things)
    else --wall
      tiles[#tiles + 1] = {name = "grass-2", position = p}
      if random(1,3) == 1 then
        entities[#entities + 1] = {name = Raffle.trees[random(1, #Raffle.trees)], position = p}
      else
        if random(1,4) == 1 then entities[#entities + 1] = {name = Raffle.rocks[random(1, #Raffle.rocks)], position = p} end
      end
    end
	end
end

local function normal_chunk(surface, left_top)
  local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
  local cell = false
  local roll = random(1,20)
  local things = nil
  if roll < 3 then
    things = Raffle.maze_things[random(1, #Raffle.maze_things)]
  elseif roll > 2 and roll < 5 then
    things = "lake"
  elseif roll > 10 then
    things = "prospect"
  end
  if Functions.process_labyrinth_cell(left_top, seed) then
    cell = true
    if things == "prospect" then
      Ores.prospect_ores(nil, surface, {x = left_top.x + 16, y = left_top.y + 16})
    elseif things == "camp" or things == "lab" then
      Specials.defended_position(surface, left_top, entities)
      if things == "lab" then
        entities[#entities + 1] = {name = "lab", position = {x = left_top.x + 15, y = left_top.y + 15}, force = "neutral"}
      end
    elseif things == "factory" then
      Specials.production_factory(surface, {x = left_top.x + 15, y = left_top.y + 15})
    end
  end
  for y = 0, 31, 1 do
    for x = 0, 31, 1 do
      local p = {x = left_top.x + x, y = left_top.y + y}
      process_tile(p, seed, tiles, entities, treasure, cell, things)
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
			process_tile(p, seed, tiles, entities, treasure, true, nil)
		end
	end
	surface.set_tiles(tiles, true)
  Functions.replace_water(surface, left_top)
end

local function maze(variant, surface, left_top)
  local id = variant.id

  if abs(left_top.y) <= 31 and abs(left_top.x) <= 31 then empty_chunk(surface, left_top) return end
  if abs(left_top.y) > 31 or abs(left_top.x) > 31 then normal_chunk(surface, left_top) return end
end

return maze

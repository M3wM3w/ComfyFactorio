local random = math.random
local abs = math.abs
local max = math.max
local min = math.min
local floor = math.floor
local Functions = require "maps.chronosphere.world_functions"
local Raffle = require "maps.chronosphere.raffles"
local Chrono_table = require 'maps.chronosphere.table'
local Specials = require "maps.chronosphere.terrain_specials"

local function process_tile(p, seed, tiles, entities, treasure, factories)
  local objective = Chrono_table.get_table()
  local noise1 = Functions.get_noise("scrapyard", p, seed)
  local noise2 = Functions.get_noise("large_caves", p, seed)
  local biters = objective.world.variant.biters
  local ore_factor = objective.world.ores.factor
  local moisture = objective.world.variant.moisture
  local handicap = max(0, 160 - objective.chronojumps * 20)

  if noise1 < -0.75 or noise1 > 0.75 then
    if random(1,52 - biters) == 1 and Functions.distance(p.x, p.y) > 150 + handicap then
      entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true}
    end
  end

  if noise1 > -0.08 - 0.01 * ore_factor and noise1 < 0.08 + 0.01 * ore_factor  then
    if random(1,30) == 1 then
      entities[#entities + 1] = {name = Raffle.rocks[random(1, #Raffle.rocks)], position = p}
    else
      if random(1,5000) <= objective.world.variant.fa then
        factories[#factories + 1] = p
      end
    end
  end

  if noise1 + 0.5 > -0.1  - 0.1 * moisture and noise1 + 0.5 < 0.1 +  0.1 * moisture  then
    if random(1,100) > 42 - handicap / 6 then
      if random(1, 800) == 1 then
        treasure[#treasure + 1] = p
      else
        if objective.world.variant.id == 11 then
          entities[#entities + 1] = {name = Raffle.dead_trees[random(1, #Raffle.dead_trees)] , position = p}
        else
          entities[#entities + 1] = {name = Raffle.trees[random(1, #Raffle.trees)] , position = p}
        end
      end
    end
  end

	if noise1 > -0.10 and noise1 < 0.10 then
		if floor(noise2 * 10) % 4 < 3 then
      local jumps = min(objective.chronojumps * 5, 100)
      local roll = random(1,200 - jumps - biters)
      if Functions.distance(p.x, p.y) > 200 + handicap then
        if roll == 1 then
          entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true}
        elseif roll == 2 then
          local evo = game.forces["enemy"].evolution_factor
          entities[#entities + 1] = {name = Raffle.worms[random(1 + floor(evo * 8), floor(1 + evo * 16))], position = p, spawn_decorations = true}
        elseif roll == 3 then
          if random(1, 50) == 1 then treasure[#treasure + 1] = p end
        end
      end
		end
	end
end

local function normal_chunk(surface, left_top)
  local tiles = {}
	local entities = {}
	local treasure = {}
  local factories = {}
	local seed = surface.map_gen_settings.seed
  for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_tile(p, seed, tiles, entities, treasure, factories)
		end
	end
  surface.set_tiles(tiles, true)
  Functions.spawn_treasures(surface, treasure)
  Functions.spawn_entities(surface, entities)
  for _, pos in pairs(factories) do
    Specials.production_factory(surface, pos)
  end
end

local function empty_chunk(surface, left_top)
	local tiles = {}
	local entities = {}
	local treasure = {}
  local factories = {}
	local seed = surface.map_gen_settings.seed

	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_tile(p, seed, tiles, entities, treasure, factories)
		end
	end
	surface.set_tiles(tiles, true)
  Functions.replace_water(surface, left_top)
end

local function basic(variant, surface, left_top)
  local id = variant.id

  if abs(left_top.y) <= 31 and abs(left_top.x) <= 31 then empty_chunk(surface, left_top) end
  if abs(left_top.y) > 31 or abs(left_top.x) > 31 then normal_chunk(surface, left_top) end
  if id == 11 then Functions.replace_water(surface, left_top) end
end

return basic

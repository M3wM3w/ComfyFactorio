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
  local danger = 0
  if objective.world.variant.id == 2 then danger = 1 end
  local noise1 = Functions.get_noise("scrapyard", p, seed)
  local biters = objective.world.variant.biters
  local moisture = objective.world.variant.moisture
  local handicap = max(0, 160 - objective.chronojumps * 20)
	--Chasms
	local noise2 = Functions.get_noise("cave_ponds", p, seed)
	local noise3 = Functions.get_noise("small_caves", p, seed)
	if noise2 < 0.15 and noise2 > -0.15 then
		if noise3 > 0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if noise3 < -0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if noise1 < -0.25 + danger * 0.05 or noise1 > 0.25 - danger * 0.05 then
		if random(1, 256 - danger * 128) == 1 and Functions.distance(p.x, p.y) > 50 then
			entities[#entities + 1] = {name="gun-turret", position=p, force = "scrapyard"}
		end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if danger == 0 and (noise1 < -0.55 or noise1 > 0.55) then
			if random(1,40) == 1 and Functions.distance(p.x, p.y) > 150 + handicap then entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true} end
			return
		end
    if noise1 + 0.5 > -0.05  - 0.1 * moisture and noise1 + 0.5 < 0.05 +  0.1 * moisture  then
       if random(1,100) > 42 then entities[#entities + 1] = {name = Raffle.dead_trees[random(1, #Raffle.dead_trees)], position = p} end
    end
		if noise1 < -0.28 - danger * 0.1 or noise1 > 0.28 + danger * 0.1 then
			if random(1,48) == 1 then
        entities[#entities + 1] = {name = Raffle.scraps_inv[random(1, #Raffle.scraps_inv)], position = p, force = "neutral"}
      else
        if danger == 0 then
          if random(1,5000) <= objective.world.variant.fa then
            factories[#factories + 1] = p
          else
            if random(1,5) > 1 then entities[#entities + 1] = {name = Raffle.scraps[random(1, #Raffle.scraps)], position = p, force = "neutral"} end
          end
        else
          if random(1,5000) <= objective.world.variant.fa then
            factories[#factories + 1] = p
          else
            if random(1, 3) == 1 then entities[#entities + 1] = {name = Raffle.scraps[random(1, #Raffle.scraps)], position = p, force = "neutral"} end
          end
        end
      end
		end
	end

	if noise2 < -0.6 and noise1 > -0.2 and noise1 < 0.2 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if random(1,128) == 1 then entities[#entities + 1] = {name = "fish", position = p} end
		return
	end

	local noise4 = Functions.get_noise("large_caves", p, seed)
	if noise1 > -0.15 and noise1 < 0.15 then
		if floor(noise4 * 10) % 4 < 3 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
      local jumps = min(objective.chronojumps * 5, 100)
			if random(1,200 - jumps) == 1 and Functions.distance(p.x, p.y) > 150 + handicap and danger == 0 then
        entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true}
      end
			return
		end
	end
	tiles[#tiles + 1] = {name = "dirt-7", position = p}
  tiles[#tiles + 1] = {name = "stone-path", position = p}
end

local function danger_chunk(surface, left_top)
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
  Specials.danger_event(surface, left_top)
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

local function scrapyard(variant, surface, left_top)
  local id = variant.id

  if abs(left_top.y) <= 31 and abs(left_top.x) <= 31 then empty_chunk(surface, left_top) return end
  if id == 2 and abs(left_top.y) == 448 and abs(left_top.x) == 448 then danger_chunk(surface, left_top) return end
  if abs(left_top.y) > 31 or abs(left_top.x) > 31 then normal_chunk(surface, left_top) return end
end

return scrapyard

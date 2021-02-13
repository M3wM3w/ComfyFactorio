local random = math.random
local abs = math.abs
local max = math.max
local min = math.min
local floor = math.floor
local Functions = require "maps.chronosphere.world_functions"
local Raffle = require "maps.chronosphere.raffles"
local Chrono_table = require 'maps.chronosphere.table'

local function process_tile(p, seed, tiles, entities, treasure, decoratives)
  local objective = Chrono_table.get_table()
  local biters = objective.world.variant.biters
  local tunnels = 0
  if objective.world.variant.id == 2 then tunnels = 120 end
  local handicap = max(0, 160 - objective.chronojumps * 20)
  local noise1 = Functions.get_noise("large_caves", p, seed)
	local noise2 = Functions.get_noise("cave_ponds", p, seed)
	local noise3 = Functions.get_noise("small_caves", p, seed)

	if abs(noise1) > 0.7 then
		tiles[#tiles + 1] = {name = "water", position = p}
		if random(1,16) == 1 then entities[#entities + 1] = {name = "fish", position = p} end
		return
	end
	if abs(noise1) > 0.6 then
		if random(1,16) == 1 then entities[#entities + 1] = {name = Raffle.trees[random(11,15)], position = p} end
	end
	if abs(noise1) > 0.5 then
		tiles[#tiles + 1] = {name = "grass-2", position = p}
    if random(1,122 - biters) == 1 and Functions.distance(p.x, p.y) > 150 + handicap then entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true} end
		if random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end
	if abs(noise1) > 0.375 then
		tiles[#tiles + 1] = {name = "dirt-6", position = p}
		if random(1,5) > 1 then entities[#entities + 1] = {name = Raffle.rocks[random(1, #Raffle.rocks)], position = p} end
    decoratives[#decoratives + 1] = {name = Raffle.rock_decoratives[random(1, #Raffle.rock_decoratives)], position = p, amount = 3}
		if random(1, 2 * 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end

	--Chasms
	if noise2 < 0.25 and noise2 > -0.25 then
		if noise3 > 0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if noise3 < -0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if noise3 > -0.25 and noise3 < 0.25 then
		tiles[#tiles + 1] = {name = "dirt-6", position = p}
    local evo = game.forces["enemy"].evolution_factor
    local roll = random(1,1000)
    if roll > 830 + tunnels then
      entities[#entities + 1] = {name = Raffle.rocks[random(1, #Raffle.rocks)], position = p}
      decoratives[#decoratives + 1] = {name = Raffle.rock_decoratives[random(1, #Raffle.rock_decoratives)], position = p, amount = random(2,4)}
    elseif roll > 820 + tunnels and Functions.distance(p.x, p.y) > 150 then
      entities[#entities + 1] = {name = Raffle.worms[random(1 + floor(evo * 8), floor(1 + evo * 16))], position = p, spawn_decorations = true}
    else
      if random(1, 1024) == 1 then treasure[#treasure + 1] = p end
      decoratives[#decoratives + 1] = {name = Raffle.rock_decoratives[random(1, #Raffle.rock_decoratives)], position = p, amount = 1}
    end
		return
	end

	if noise1 > -0.28 and noise1 < 0.28 then

		--Main Rock Terrain
		local noise4 = Functions.get_noise("no_rocks_2", p, seed + 75000)
		if noise4 > 0.80 or noise4 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. floor(noise4 * 8) % 2 + 5, position = p}
			if random(1,512) == 1 then treasure[#treasure + 1] = p end
			return
		end

		if random(1, 2 * 1024) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-6", position = p}
		if random(1,100) > 50 then entities[#entities + 1] = {name = Raffle.rocks[random(1, #Raffle.rocks)], position = p} end
    decoratives[#decoratives + 1] = {name = Raffle.rock_decoratives[random(1, #Raffle.rock_decoratives)], position = p, amount = 4}
		return
	end

	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function normal_chunk(surface, left_top)
  local tiles = {}
	local entities = {}
	local treasure = {}
  local decoratives = {}
	local seed = surface.map_gen_settings.seed
  for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_tile(p, seed, tiles, entities, treasure, decoratives)
		end
	end
  surface.set_tiles(tiles, true)
  Functions.spawn_treasures(surface, treasure)
  Functions.spawn_entities(surface, entities)
  Functions.spawn_decoratives(surface, decoratives)
end

local function empty_chunk(surface, left_top)
	local tiles = {}
	local entities = {}
	local treasure = {}
  local decoratives = {}
	local seed = surface.map_gen_settings.seed

	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_tile(p, seed, tiles, entities, treasure, decoratives)
		end
	end
	surface.set_tiles(tiles, true)
  Functions.replace_water(surface, left_top)
  Functions.spawn_decoratives(surface, decoratives)
end

local function caveworld(variant, surface, left_top)
  local id = variant.id

  if abs(left_top.y) <= 31 and abs(left_top.x) <= 31 then empty_chunk(surface, left_top) return end
  if abs(left_top.y) > 31 or abs(left_top.x) > 31 then normal_chunk(surface, left_top) return end
end

return caveworld

local random = math.random
local abs = math.abs
local max = math.max
local min = math.min
local floor = math.floor
local Balance = require 'maps.chronosphere.balance'
local Functions = require "maps.chronosphere.world_functions"
local Raffle = require "maps.chronosphere.raffles"
local Chrono_table = require 'maps.chronosphere.table'
local Specials = require "maps.chronosphere.terrain_specials"
local simplex_noise = require "utils.simplex_noise".d2
local Difficulty = require 'modules.difficulty_vote'

local function roll_biters(p, biters, entities)
  local roll = random(1, biters)
  if roll < 4 and p.x > -800 then
    entities[#entities + 1] = {name = Raffle.spawners[random(1, #Raffle.spawners)], position = p, spawn_decorations = true}
  elseif roll == 5 and p.x > -800 then
    entities[#entities + 1] = {name = "behemoth-worm-turret", position = p, spawn_decorations = true}
  elseif roll == 6 then
    entities[#entities + 1] = {name = Raffle.trees[random(1, #Raffle.trees)], position = p}
  end
end

local function process_tile(p, seed, tiles, entities)
  local body_radius = 1984 --3072
  local body_square_radius = body_radius ^ 2
  local body_center_position = {x = 0, y = 0}
  local body_spacing = floor(body_radius * 0.82)
  local body_circle_center_1 = {x = body_center_position.x, y = body_center_position.y - body_spacing}
  local body_circle_center_2 = {x = body_center_position.x, y = body_center_position.y + body_spacing}

  local difficulty = Difficulty.get().difficulty_vote_value
  local biters = Balance.fish_market_base_modifier(difficulty)

	--Main Fish Body
	local distance_to_center_1 = ((p.x - body_circle_center_1.x)^2 + (p.y - body_circle_center_1.y)^2)
	local distance_to_center_2 = ((p.x - body_circle_center_2.x)^2 + (p.y - body_circle_center_2.y)^2)
  local eye_center = {x = -500, y = -150}

	if distance_to_center_1 < body_square_radius and distance_to_center_2 < body_square_radius then
    if p.x < -600 and p.x > -1090 and p.y < 64 and p.y > -64 then --mouth
      local noise = simplex_noise(p.x * 0.006, 0, seed) * 20
      if p.y <= 12 + noise and p.y >= -12 + noise then
        tiles[#tiles + 1] = {name = "water", position = p}
      else
        tiles[#tiles + 1] = {name = "grass-1", position = p}
        roll_biters(p, biters, entities)
      end
    else
			local distance = Functions.distance(eye_center.x - p.x, eye_center.y - p.y)
			if distance < 33 and distance >= 15 then --eye
				tiles[#tiles + 1 ] = {name = "water-green", position = p}
			elseif distance < 15 then --eye
				tiles[#tiles + 1] = {name = "out-of-map", position = p}
			else --rest
        tiles[#tiles + 1 ] = {name = "grass-1", position = p}
        roll_biters(p, biters, entities)
      end
    end
  else
    if p.x > 800 and abs(p.y) < p.x - 800 then --tail
      tiles[#tiles + 1 ] = {name = "grass-1", position = p}
      local roll = random(1, biters)
      roll_biters(p, biters, entities)
    else
      tiles[#tiles + 1 ] = {name = "out-of-map", position = p}
    end
  end
end

local function market_chunk(surface, left_top)
  local tiles = {}
	local entities = {}
	local seed = surface.map_gen_settings.seed
  for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_tile(p, seed, tiles, entities)
		end
	end
  surface.set_tiles(tiles, true)
  Specials.fish_market(surface, left_top)
end

local function normal_chunk(surface, left_top, level, planet)
  local tiles = {}
	local entities = {}
  local seed = surface.map_gen_settings.seed
  for y = 0, 31, 1 do
    for x = 0, 31, 1 do
      local p = {x = left_top.x + x, y = left_top.y + y}
      process_tile(p, seed, tiles, entities)
    end
  end
  surface.set_tiles(tiles, true)
  Functions.spawn_entities(surface, entities)
end

local function basic(variant, surface, left_top)
  local id = variant.id

  if abs(left_top.y) <= 31 and abs(left_top.x - 864) <= 31 then market_chunk(surface, left_top) return end
  normal_chunk(surface, left_top)
end

return basic

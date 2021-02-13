local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Raffle = require "maps.chronosphere.raffles"
local Public = {}
local simplex_noise = require 'utils.simplex_noise'.d2
local math_random = math.random
local math_floor = math.floor
local math_ceil = math.ceil

local function draw_noise_ore_patch(position, name, surface, radius, richness, mixed)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
  local noise
	local seed = surface.map_gen_settings.seed
	local richness_part = richness / radius
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x + 0.5, y = y + position.y + 0.5}
			local noise_1 = simplex_noise(pos.x * 0.0125, pos.y * 0.0125, seed)
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed + 25000)
			noise = noise_1 + noise_2 * 0.12
			local distance_to_center = math.sqrt(x^2 + y^2)
			local a = richness - richness_part * distance_to_center
      if distance_to_center < radius - math.abs(noise * radius * 0.85) and a > 1 then

        if mixed then
          noise = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed) + simplex_noise(pos.x * 0.01, pos.y * 0.01, seed) * 0.3 + simplex_noise(pos.x * 0.05, pos.y * 0.05, seed) * 0.2
          local i = (math_floor(noise * 100) % 7) + 1
          name = Raffle.ores[i]
        end
        local entity = {name = name, position = pos, amount = a}

        local preexisting_ores = surface.find_entities_filtered{area = {{pos.x - 0.025, pos.y - 0.025}, {pos.x + 0.025, pos.y + 0.025}}, type= "resource"}

        if #preexisting_ores >= 1 then
          surface.create_entity(entity)
        else
          pos = surface.find_non_colliding_position(name, pos, 64, 1, true)
          if not pos then return end
          if surface.can_place_entity(entity) then
            surface.create_entity(entity)
          end
        end
			end
		end
	end
end

local function get_size_of_ore(ore, world)
  local base_size = math_random(5, 10) + math_floor(world.ores.factor * 4)
  local final_size
  if world.variant.fe > 4 and ore == "iron-ore" then
    final_size = math_floor(base_size * 1.5)
  elseif world.variant.cu > 4 and ore == "copper-ore" then
    final_size = math_floor(base_size * 1.5)
  elseif world.variant.s > 4 and ore == "stone" then
    final_size = math_floor(base_size * 1.5)
  elseif world.variant.c > 4 and ore == "coal" then
    final_size = math_floor(base_size * 1.5)
  elseif world.variant.u > 4 and ore == "uranium-ore" then
    final_size = math_floor(base_size * 1.5)
  elseif world.id == 1 and world.variant.id == 9 then --mixed ores
    final_size = base_size
  else
    final_size = math_floor(base_size / 2)
  end
  return final_size
end

local function get_oil_amount(pos, oil_w, richness)
  local objective = Chrono_table.get_table()
  local hundred_percent = 300000
	return math_ceil((hundred_percent / 50) * (3 + objective.chronojumps) * oil_w * richness)
end

local function spawn_ore_vein(surface, pos, world, extrasize)
  local objective = Chrono_table.get_table()
  local mixed = false
  if world.id == 1 and world.variant.id == 9 then mixed = true end --mixed ores
  local richness = math_random(50 + 10 * objective.chronojumps, 100 + 10 * objective.chronojumps) * world.ores.factor
  if world.id == 16 then richness = richness * 10 end --hedge maze
  local iron = {w = world.variant.fe, t = world.variant.fe}
  local copper = {w = world.variant.cu, t = iron.t + world.variant.cu}
  local stone = {w = world.variant.s, t = copper.t + world.variant.s}
  local coal = {w = world.variant.c, t = stone.t + world.variant.c}
  local uranium = {w = world.variant.u, t = coal.t + world.variant.u}
  local oil = {w = world.variant.o, t = uranium.t + world.variant.o}

  local roll = math_random (0, oil.t)
  if roll == 0 then return end
  local choice = nil
  if roll <= iron.t then
    choice = "iron-ore"
  elseif roll <= copper.t then
    choice = "copper-ore"
  elseif roll <= stone.t then
    choice = "stone"
  elseif roll <= coal.t then
    choice = "coal"
  elseif roll <= uranium.t then
    choice = "uranium-ore"
  elseif roll <= oil.t then
    choice = "crude-oil"
  end

  --if surface.can_place_entity({name = choice, position = pos, amount = 1}) then
    if choice == "crude-oil" then
			local amount = get_oil_amount(pos, oil.w, world.ores.factor)
			if extrasize then amount = amount * 2 end
      surface.create_entity({name = "crude-oil", position = pos, amount = amount})
    else
			local size = get_size_of_ore(choice, world)
			if extrasize then size = size * 2 end
      draw_noise_ore_patch(pos, choice, surface, size, richness * 0.75, mixed)
    end
  --end
end

function Public.prospect_ores(entity, surface, pos)
  local objective = Chrono_table.get_table()
  local world = objective.world
  local chance = 15
	local extrasize = false
  if entity then
    if entity.name == "rock-huge" then chance = 45 end
    if entity.type == "unit-spawner" then chance = 45 end
    if world.id == 1 and (world.variant.id == 10 or world.variant.id == 11) then chance = chance + 30 end
    if math_random(chance + math_floor(20 * world.ores.factor), 100 + chance) >= 100 then
      spawn_ore_vein(surface, pos, world, extrasize)
    end
  else
		extrasize = true
    spawn_ore_vein(surface, pos, world, extrasize)
  end
end

return Public

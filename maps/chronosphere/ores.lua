local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Public_ores = {}
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
  local ore_raffle = {
	"iron-ore", "iron-ore", "iron-ore", "copper-ore", "copper-ore", "coal", "stone"
  }
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
          name = ore_raffle[i]
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

local function get_size_of_ore(ore, planet)
  local base_size = math_random(5, 10) + math_floor(planet[1].ore_richness.factor * 4)
  local final_size
  if planet[1].type.id == 1 and ore == "iron-ore" then --iron planet
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].type.id == 2 and ore == "copper-ore" then --copper planet
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].type.id == 3 and ore == "stone" then --stone planet
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].type.id == 9 and ore == "coal" then --coal planet
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].type.id == 5 and ore == "uranium-ore" then --uranium planet
    final_size = math_floor(base_size * 1.5)
  elseif planet[1].type.id == 6 then --mixed planet
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

local function spawn_ore_vein(surface, pos, planet, extrasize)
  local objective = Chrono_table.get_table()
  local mixed = false
  if planet[1].type.id == 6 then mixed = true end --mixed planet
  local richness = math_random(50 + 10 * objective.chronojumps, 100 + 10 * objective.chronojumps) * planet[1].ore_richness.factor
  if planet[1].type.id == 16 then richness = richness * 10 end --hedge maze
  local iron = {w = planet[1].type.iron, t = planet[1].type.iron}
  local copper = {w = planet[1].type.copper, t = iron.t + planet[1].type.copper}
  local stone = {w = planet[1].type.stone, t = copper.t + planet[1].type.stone}
  local coal = {w = planet[1].type.coal, t = stone.t + planet[1].type.coal}
  local uranium = {w = planet[1].type.uranium, t = coal.t + planet[1].type.uranium}
  local oil = {w = planet[1].type.oil, t = uranium.t + planet[1].type.oil}

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
			local amount = get_oil_amount(pos, oil.w, planet[1].ore_richness.factor)
			if extrasize then amount = amount * 2 end
      surface.create_entity({name = "crude-oil", position = pos, amount = amount})
    else
			local size = get_size_of_ore(choice, planet)
			if extrasize then size = size * 2 end
      draw_noise_ore_patch(pos, choice, surface, size, richness * 0.75, mixed)
    end
  --end
end

function Public_ores.prospect_ores(entity, surface, pos)
  local objective = Chrono_table.get_table()
  local planet = objective.planet
  local chance = 15
	local extrasize = false
  if entity then
    if entity.name == "rock-huge" then chance = 45 end
    if entity.type == "unit-spawner" then chance = 45 end
    if planet[1].type.id == 15 then chance = chance + 30 end
    if math_random(chance + math_floor(20 * planet[1].ore_richness.factor), 100 + chance) >= 100 then
      spawn_ore_vein(surface, pos, planet, extrasize)
    end
  else
		extrasize = true
    spawn_ore_vein(surface, pos, planet, extrasize)
  end
end

return Public_ores

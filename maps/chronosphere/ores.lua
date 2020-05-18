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
  local base_size = math_random(5, 10) + math_floor(planet[1].ore_richness.factor * 3)
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
	return math_ceil((hundred_percent / 100) * (4 + objective.chronojumps) * oil_w * richness / 3)
end

local function spawn_ore_vein(surface, pos, planet)
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
      surface.create_entity({name = "crude-oil", position = pos, amount = get_oil_amount(pos, oil.w, planet[1].ore_richness.factor) })
    else
      draw_noise_ore_patch(pos, choice, surface, get_size_of_ore(choice, planet), richness * 0.75, mixed)
    end
  --end
end

function Public_ores.prospect_ores(entity, surface, pos)
  local objective = Chrono_table.get_table()
  local planet = objective.planet
  local chance = 10
  if entity then
    if entity.name == "rock-huge" then chance = 40 end
    if entity.type == "unit-spawner" then chance = 40 end
    if planet[1].type.id == 15 then chance = chance + 30 end
    if math_random(chance + math_floor(10 * planet[1].ore_richness.factor) ,100 + chance) >= 100 then
      spawn_ore_vein(surface, pos, planet)
    end
  else
    spawn_ore_vein(surface, pos, planet)
  end
end



---- SCRAP ----




local scrap_yield_amounts = {
	["iron-plate"] = 8,
	["iron-gear-wheel"] = 4,
	["iron-stick"] = 8,
	["copper-plate"] = 8,
	["copper-cable"] = 12,
	["electronic-circuit"] = 4,
	["steel-plate"] = 4,
	["pipe"] = 4,
	["solid-fuel"] = 4,
	["empty-barrel"] = 3,
	["crude-oil-barrel"] = 3,
	["lubricant-barrel"] = 3,
	["petroleum-gas-barrel"] = 3,
	["heavy-oil-barrel"] = 3,
	["light-oil-barrel"] = 3,
	["water-barrel"] = 3,
	["grenade"] = 3,
	["battery"] = 3,
	["explosives"] = 3,
	["advanced-circuit"] = 3,
	["nuclear-fuel"] = 0.1,
	["pipe-to-ground"] = 1,
	["plastic-bar"] = 3,
	["processing-unit"] = 1,
	["used-up-uranium-fuel-cell"] = 1,
	["uranium-fuel-cell"] = 0.3,
	["rocket-fuel"] = 0.3,
	["rocket-control-unit"] = 0.3,
	["low-density-structure"] = 0.3,
	["heat-pipe"] = 1,
	["green-wire"] = 8,
	["red-wire"] = 8,
	["engine-unit"] = 2,
	["electric-engine-unit"] = 2,
	["logistic-robot"] = 0.3,
	["construction-robot"] = 0.3,
	["land-mine"] = 1,
	["rocket"] = 2,
	["explosive-rocket"] = 2,
	["cannon-shell"] = 2,
	["explosive-cannon-shell"] = 2,
	["uranium-cannon-shell"] = 2,
	["explosive-uranium-cannon-shell"] = 2,
	["artillery-shell"] = 0.3,
	["cluster-grenade"] = 0.3,
	["defender-capsule"] = 2,
	["destroyer-capsule"] = 0.3,
	["distractor-capsule"] = 0.3
}

local scrap_mining_chance_weights = {
	{name = "iron-plate", chance = 600},
	{name = "iron-gear-wheel", chance = 400},	
	{name = "copper-plate", chance = 400},
	{name = "copper-cable", chance = 200},	
	{name = "electronic-circuit", chance = 150},
	{name = "steel-plate", chance = 100},
	{name = "pipe", chance = 75},
	{name = "iron-stick", chance = 30},
	{name = "solid-fuel", chance = 20},
	{name = "battery", chance = 10},
	{name = "crude-oil-barrel", chance = 10},
	{name = "petroleum-gas-barrel", chance = 7},
	{name = "heavy-oil-barrel", chance = 7},
	{name = "light-oil-barrel", chance = 7},
	{name = "lubricant-barrel", chance = 4},
	{name = "empty-barrel", chance = 4},
	{name = "water-barrel", chance = 4},
	{name = "green-wire", chance = 4},
	{name = "red-wire", chance = 4},
	{name = "grenade", chance = 3},
	{name = "pipe-to-ground", chance = 3},
	{name = "explosives", chance = 3},
	{name = "advanced-circuit", chance = 3},
	{name = "plastic-bar", chance = 3},
	{name = "engine-unit", chance = 2},
	{name = "nuclear-fuel", chance = 1},
	{name = "processing-unit", chance = 1},
	{name = "used-up-uranium-fuel-cell", chance = 1},
	{name = "uranium-fuel-cell", chance = 1},
	{name = "rocket-fuel", chance = 1},
	{name = "rocket-control-unit", chance = 1},	
	{name = "low-density-structure", chance = 1},	
	{name = "heat-pipe", chance = 1},
	{name = "electric-engine-unit", chance = 1},
	{name = "logistic-robot", chance = 1},
	{name = "construction-robot", chance = 1},
	{name = "land-mine", chance = 1},	
	{name = "rocket", chance = 1},
	{name = "explosive-rocket", chance = 1},
	{name = "cannon-shell", chance = 1},
	{name = "explosive-cannon-shell", chance = 1},
	{name = "uranium-cannon-shell", chance = 1},
	{name = "explosive-uranium-cannon-shell", chance = 1},
	{name = "artillery-shell", chance = 1},
	{name = "cluster-grenade", chance = 1},
	{name = "defender-capsule", chance = 1},
	{name = "destroyer-capsule", chance = 1},
	{name = "distractor-capsule", chance = 1}
}




local scrap_raffle = {}				
for _, t in pairs (scrap_mining_chance_weights) do
	for x = 1, t.chance, 1 do
		table.insert(scrap_raffle, t.name)
	end			
end

local size_of_scrap_raffle = #scrap_raffle



local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.name ~= "mineable-wreckage" then return end
			
	event.buffer.clear()
	
	local scrap = scrap_raffle[math.random(1, size_of_scrap_raffle)]
  
  
  local amount_bonus_multiplier = Balance.scrap_quantity_multiplier(game.forces.enemy.evolution_factor)

	local r1 = math.ceil(scrap_yield_amounts[scrap] * 0.3 * amount_bonus_multiplier)
	local r2 = math.ceil(scrap_yield_amounts[scrap] * 1.7 * amount_bonus_multiplier)	
	local amount = math.random(r1, r2)
	
	local player = game.players[event.player_index]	
	local inserted_count = player.insert({name = scrap, count = amount})
	
	if inserted_count ~= amount then
		local amount_to_spill = amount - inserted_count
		entity.surface.spill_item_stack(entity.position,{name = scrap, count = amount_to_spill}, true)
	end
	
	entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "+" .. amount .. " [img=item/" .. scrap .. "]",
		color = {r=0.98, g=0.66, b=0.22}
	})	
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)



return Public_ores

--require "maps.chronosphere.ores"
local Chrono_table = require 'maps.chronosphere.table'
local Ores = require "maps.chronosphere.ores"
local Specials = require "maps.chronosphere.terrain_specials"
local math_random = math.random
local math_floor = math.floor
local math_min = math.min
local math_abs = math.abs
local math_sqrt = math.sqrt
local level_depth = 960
local lake_noise_value = -0.9
local labyrinth_cell_size = 32 --valid values are 2, 4, 8, 16, 32
local Treasure = require 'maps.chronosphere.treasure'
local simplex_noise = require "utils.simplex_noise".d2
local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local size_of_rock_raffle = #rock_raffle
local dead_tree_raffle = {"dead-dry-hairy-tree", "dead-grey-trunk", "dead-tree-desert", "dry-hairy-tree", "dry-tree"}
local tree_raffle = {"tree-01", "tree-02", "tree-02-red", "tree-03", "tree-04", "tree-05", "tree-06", "tree-06-brown", "tree-07",
      "tree-08", "tree-08-brown", "tree-08-red", "tree-09", "tree-09-brown", "tree-09-red"}
local s_tree_raffle = #tree_raffle
local spawner_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}
local worm_raffle = {
  "small-worm-turret", "small-worm-turret", "medium-worm-turret", "small-worm-turret",
  "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "medium-worm-turret",
  "big-worm-turret","big-worm-turret","behemoth-worm-turret", "big-worm-turret",
  "behemoth-worm-turret","behemoth-worm-turret","behemoth-worm-turret","big-worm-turret","behemoth-worm-turret"
}
local scrap_entities = {"crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-lab-broken",
 "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck",
 "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2"}
local scrap_entities_index = #scrap_entities
local maze_things_raffle = {"camp", "lab", "treasure", "crashsite"}
local noises = {
	["no_rocks"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["no_rocks_2"] = {{modifier = 0.013, weight = 1}, {modifier = 0.1, weight = 0.1}},
	["large_caves"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["small_caves"] = {{modifier = 0.008, weight = 1}, {modifier = 0.03, weight = 0.15}, {modifier = 0.25, weight = 0.05}},
	["small_caves_2"] = {{modifier = 0.009, weight = 1}, {modifier = 0.05, weight = 0.25}, {modifier = 0.25, weight = 0.05}},
	["cave_ponds"] = {{modifier = 0.01, weight = 1}, {modifier = 0.1, weight = 0.06}},
	["cave_rivers"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_2"] = {{modifier = 0.003, weight = 1}, {modifier = 0.01, weight = 0.21}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_3"] = {{modifier = 0.002, weight = 1}, {modifier = 0.01, weight = 0.15}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_4"] = {{modifier = 0.001, weight = 1}, {modifier = 0.01, weight = 0.11}, {modifier = 0.05, weight = 0.01}},
	["scrapyard"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.35}, {modifier = 0.05, weight = 0.23}, {modifier = 0.1, weight = 0.11}},
  ["forest_location"] = {{modifier = 0.006, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.15}, {modifier = 0.1, weight = 0.05}},
	["forest_density"] = {{modifier = 0.01, weight = 1}, {modifier = 0.05, weight = 0.5}, {modifier = 0.1, weight = 0.025}},
  ["ores"] = {{modifier = 0.05, weight = 1}, {modifier = 0.02, weight = 0.55}, {modifier = 0.05, weight = 0.05}},
  ["hedgemaze"] = {{modifier = 0.001, weight = 1}}
}

local modifiers = {
  {x = 0, y = -1},{x = -1, y = 0},{x = 1, y = 0},{x = 0, y = 1}
}
local modifiers_diagonal = {
  {diagonal = {x = -1, y = 1}, connection_1 = {x = -1, y = 0}, connection_2 = {x = 0, y = 1}},
  {diagonal = {x = 1, y = -1}, connection_1 = {x = 1, y = 0}, connection_2 = {x = 0, y = -1}},
  {diagonal = {x = 1, y = 1}, connection_1 = {x = 1, y = 0}, connection_2 = {x = 0, y = 1}},
  {diagonal = {x = -1, y = -1}, connection_1 = {x = -1, y = 0}, connection_2 = {x = 0, y = -1}}
}

local function pos_to_key(position)
    return tostring(position.x .. "_" .. position.y)
end

local function get_noise(name, pos, seed)
	local noise = 0
	local d = 0
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		d = d + n.weight
		seed = seed + 10000
	end
	noise = noise / d
	return noise
end

local function get_size_of_ore(ore, planet)
  local base_size = 0.04 + 0.04 * planet[1].ore_richness.factor
  local final_size = 1
  if planet[1].type.id == 1 and ore == "iron-ore" then --iron planet
    final_size = base_size * 5
  elseif planet[1].type.id == 2 and ore == "copper-ore" then --copper planet
    final_size = base_size * 5
  elseif planet[1].type.id == 3 and ore == "stone" then --stone planet
    final_size = base_size * 5
  elseif planet[1].type.id == 9 and ore == "coal" then --coal planet
    final_size = base_size * 5
  elseif planet[1].type.id == 5 and ore == "uranium-ore" then --uranium planet
    final_size = base_size * 5
  elseif planet[1].type.id == 6 then --mixed planet
    final_size = base_size * 2
  else
    final_size = base_size / 2
  end
  return final_size
end

local function get_path_connections_count(cell_pos)
	local objective = Chrono_table.get_table()
	local connections = 0
	for _, m in pairs(modifiers) do
		if objective.lab_cells[tostring(cell_pos.x + m.x) .. "_" .. tostring(cell_pos.y + m.y)] then
			connections = connections + 1
		end
	end
	return connections
end

local function process_labyrinth_cell(pos, seed)
  local objective = Chrono_table.get_table()
  local cell_position = {x = pos.x / labyrinth_cell_size, y = pos.y / labyrinth_cell_size}
  local mazenoise = get_noise("hedgemaze", cell_position, seed)

  if mazenoise < lake_noise_value and math_sqrt((pos.x / 32)^2 + (pos.y / 32)^2) > 65 then return false end

	objective.lab_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] = false

	for _, modifier in pairs(modifiers_diagonal) do
		if objective.lab_cells[tostring(cell_position.x + modifier.diagonal.x) .. "_" .. tostring(cell_position.y + modifier.diagonal.y)] then
			local connection_1 = objective.lab_cells[tostring(cell_position.x + modifier.connection_1.x) .. "_" .. tostring(cell_position.y + modifier.connection_1.y)]
			local connection_2 = objective.lab_cells[tostring(cell_position.x + modifier.connection_2.x) .. "_" .. tostring(cell_position.y + modifier.connection_2.y)]
			if not connection_1 and not connection_2 then
				return false
			end
		end
	end

	for _, m in pairs(modifiers) do
		if get_path_connections_count({x = cell_position.x + m.x, y = cell_position.y + m.y}) >= math_random(2, 3) then return false end
	end

	if get_path_connections_count(cell_position) >= math_random(2, 3) then return false end

	objective.lab_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] = true
	return true
end

local function process_dangerevent_position(p, seed, tiles, entities, treasure, planet)
	local scrapyard = get_noise("scrapyard", p, seed)
	--Chasms
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
	if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
		if small_caves > 0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if scrapyard < -0.20 or scrapyard > 0.20 then
		if math_random(1, 128) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 50 then
			entities[#entities + 1] = {name="gun-turret", position=p, force = "scrapyard"}
		end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if scrapyard < -0.38 or scrapyard > 0.38 then
			if math_random(1,36) == 1 then entities[#entities + 1] = {name = scrap_entities[math_random(1, scrap_entities_index)], position = p, force = "enemy"} end
			if math_random(1,6) == 1 then entities[#entities + 1] = {name="mineable-wreckage", position=p} end
			return
		end
		return
	end

	local cave_ponds = get_noise("cave_ponds", p, seed)
	if cave_ponds < -0.6 and scrapyard > -0.2 and scrapyard < 0.2 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	local large_caves = get_noise("large_caves", p, seed)
	if scrapyard > -0.15 and scrapyard < 0.15 then
		if math_floor(large_caves * 10) % 4 < 3 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
			return
		end
	end
	tiles[#tiles + 1] = {name = "dirt-7", position = p}
  tiles[#tiles + 1] = {name = "stone-path", position = p}
end

local function process_hedgemaze_position(p, seed, tiles, entities, treasure, planet, cell, things)
  --local labyrinth_cell_size = 16 --valid values are 2, 4, 8, 16, 32
  local biters = planet[1].type.biters
  local mazenoise = get_noise("hedgemaze", {x = p.x - p.x % labyrinth_cell_size, y = p.y - p.y % labyrinth_cell_size}, seed)

  if mazenoise < lake_noise_value and math_sqrt((p.x - p.x % labyrinth_cell_size)^2 + (p.y - p.y % labyrinth_cell_size)^2) > 65 then
	  tiles[#tiles + 1] = {name = "deepwater", position = p}
    if math_random(1, 256) == 1 then entities[#entities + 1] = {name = "fish", position = p} end
    return
  elseif mazenoise > 0.7 then
    if cell then --path
      if things then
        if things == "lake" and p.x % 32 > 8 and p.x % 32 < 24 and p.y % 32 > 8 and p.y % 32 < 24 then
          tiles[#tiles + 1] = {name = "water", position = p} return
        elseif things == "prospect" then
          if math_random(1,252 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 300 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
        elseif things == "camp" then
          if p.x % 32 > 12 and p.x % 32 < 20 and p.y % 32 > 12 and p.y % 32 < 20 then
            if math_random(1,16) == 1 then treasure[#treasure + 1] = p end
          elseif p.x % 32 == 11 or p.x % 32 == 12 or p.y % 32 == 11 or p.y % 32 == 12 or p.x % 32 == 21 or p.x % 32 == 20 or p.y % 32 == 21 or p.y % 32 == 20 then
            if math_random(1,28) == 1 then entities[#entities + 1] = {name = "land-mine", position = p, force = "scrapyard"} end
          end
        elseif things == "crashsite" then
          if math_random(1,10) == 1 then
            entities[#entities + 1] = {name="mineable-wreckage", position=p}
          end
        elseif things == "treasure" then
          local roll = math_random(1,512)
          if roll <= 2 then
            treasure[#treasure + 1] = p
          elseif roll == 3 then
            entities[#entities + 1] = {name = "land-mine", position = p, force = "scrapyard"}
          end
        end
      else
        if math_random(1, 150) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 200 then
          entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}
        end
      end
      tiles[#tiles + 1] = {name = "dirt-4", position = p}

    else --wall
      tiles[#tiles + 1] = {name = "dirt-6", position = p}
      if math_random(1,3) == 1 then
        entities[#entities + 1] = {name = "dead-tree-desert", position = p}
      else
        if math_random(1,4) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
      end
    end
  else
    if cell then --path
      if things then
        if things == "lake" and p.x % 32 > 8 and p.x % 32 < 24 and p.y % 32 > 8 and p.y % 32 < 24 then
          tiles[#tiles + 1] = {name = "water", position = p}
          return
        elseif things == "prospect" then
          if math_random(1,252 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 300 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
        elseif things == "camp" then
          if p.x % 32 > 12 and p.x % 32 < 20 and p.y % 32 > 12 and p.y % 32 < 20 and math_random(1,16) == 1 then
            treasure[#treasure + 1] = p
          end
        elseif things == "crashsite" then
          if math_random(1,10) == 1 then
            entities[#entities + 1] = {name="mineable-wreckage", position=p}
          end
        elseif things == "treasure" then
          if math_random(1,256) == 1 then
            treasure[#treasure + 1] = p
          end
        end
      else
        if math_random(1, 2 * 1024) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 125 then
          entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}
        elseif math_random(1, 4 * 1024) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then treasure[#treasure + 1] = p end -- 20/04/04: spread out treasure over map more and increased frequency. maze is a good level to buff since it's fun, so we want players to spend more time on it. nerfed treasure in camps to make it less clear whether to attack
        if math_random(1, 150) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 250 then
          entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}
        end
      end
      tiles[#tiles + 1] = {name = "grass-1", position = p}
    else --wall
      tiles[#tiles + 1] = {name = "grass-2", position = p}
      if math_random(1,3) == 1 then
        entities[#entities + 1] = {name = "tree-04", position = p}
      else
        if math_random(1,4) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
      end
    end
	end

end
local function process_rocky_position(p, seed, tiles, entities, treasure, planet)
  local biters = planet[1].type.biters
  local noise_large_caves = get_noise("large_caves", p, seed)
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)

	if math_abs(noise_large_caves) > 0.7 then
		tiles[#tiles + 1] = {name = "water", position = p}
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end
	if math_abs(noise_large_caves) > 0.6 then
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="tree-02", position=p} end
	end
	if math_abs(noise_large_caves) > 0.5 then
		tiles[#tiles + 1] = {name = "grass-2", position = p}
    if math_random(1,122 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
		if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end
	if math_abs(noise_large_caves) > 0.375 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,5) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		if math_random(1, 2 * 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end

	--Chasms
	if noise_cave_ponds < 0.25 and noise_cave_ponds > -0.25 then
		if small_caves > 0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if small_caves > -0.25 and small_caves < 0.25 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
    local roll = math_random(1,1000)
    if roll > 830 then
      entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
    elseif roll > 820 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then
      entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}
    else
    end
	if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end

	if noise_large_caves > -0.28 and noise_large_caves < 0.28 then

		--Main Rock Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return
		end

		if math_random(1, 2 * 1024) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,100) > 50 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		return
	end

	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function process_forest_position(p, seed, tiles, entities, treasure, planet)
  local biters = planet[1].type.biters
	local noise_forest_location = get_noise("forest_location", p, seed)
	if noise_forest_location > 0.095 then
		if noise_forest_location > 0.6 then
			if math_random(1,100) > 42 then entities[#entities + 1] = {name = "tree-08-brown", position = p} end
		else
			if math_random(1,100) > 42 then entities[#entities + 1] = {name = "tree-01", position = p} end
		end
		return
  else
    if math_random(1,152 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 250 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
  end

	if noise_forest_location < -0.095 then
		if noise_forest_location < -0.6 then
			if math_random(1,100) > 42 then entities[#entities + 1] = {name = "tree-04", position = p} end
		else
			if math_random(1,100) > 42 then entities[#entities + 1] = {name = "tree-02-red", position = p} end
		end
		return
  else
    if math_random(1,152 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 250 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
  end
end

local function process_river_position(p, seed, tiles, entities, treasure, planet)
  local objective = Chrono_table.get_table()
  local biters = planet[1].type.biters
  local richness = math_random(50 + 20 * objective.chronojumps, 100 + 20 * objective.chronojumps) * planet[1].ore_richness.factor * 0.5
  local iron_size = get_size_of_ore("iron-ore", planet) * 3
  local copper_size = get_size_of_ore("copper-ore", planet) * 3
  local stone_size = get_size_of_ore("stone", planet) * 3
  local coal_size = get_size_of_ore("coal", planet) * 4
  if not biters then biters = 4 end
  local large_caves = get_noise("large_caves", p, seed)
	local cave_rivers = get_noise("cave_rivers", p, seed)
  local ores = get_noise("ores", p, seed)
  local noise_forest_location = get_noise("forest_location", p, seed)

	--Chasms
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
	if noise_cave_ponds < 0.45 and noise_cave_ponds > -0.45 then
		if small_caves > 0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if large_caves > -0.05 and large_caves < 0.05 and cave_rivers < 0.25 then
		tiles[#tiles + 1] = {name = "water-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
  elseif large_caves > -0.20 and large_caves < 0.20 and math_abs(cave_rivers) < 0.95 then
    if ores > -coal_size and ores < coal_size then
      entities[#entities + 1] = {name = "coal", position = p, amount = richness}
    end
	end

	if cave_rivers > -0.70 and cave_rivers < 0.70 then
		if math_random(1,48) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
    if cave_rivers > -0.05 and cave_rivers < 0.05 then
      if ores > -iron_size and ores < iron_size then
        entities[#entities + 1] = {name = "iron-ore", position = p, amount = richness}
      end
    elseif cave_rivers > -0.10 and cave_rivers < 0.10 then
      if ores > -copper_size and ores < copper_size then
        entities[#entities + 1] = {name = "copper-ore", position = p, amount = richness}
      end
    end
	else
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
    if ores > -stone_size and ores < stone_size then
      entities[#entities + 1] = {name = "stone", position = p, amount = richness}
    end
		if math_random(1,52 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 200 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
	end
	if math_sqrt(p.x * p.x + p.y * p.y) > 175 and cave_rivers > -0.70 and cave_rivers < 0.70 then
    if math_random(1, 4 * 1024) == 1 then treasure[#treasure + 1] = p end
  end
  if noise_forest_location > 0.9 then
		if math_random(1,100) > 42 then entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p} end
		return
  end

	if noise_forest_location < -0.9 then
		if math_random(1,100) > 42 then entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p} end
		return
  end
end

local function process_biter_position(p, seed, tiles, entities, treasure, planet)
  local objective = Chrono_table.get_table()
  local scrapyard = get_noise("scrapyard", p, seed)
  local large_caves = get_noise("large_caves", p, seed)
  local biters = planet[1].type.biters
  local ore_size = planet[1].ore_richness.factor
  local handicap = 0
  if objective.chronojumps < 3 then handicap = 150 end
  if scrapyard < -0.75 or scrapyard > 0.75 then

    if math_random(1,52 - biters) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 + handicap then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end

  end
  if scrapyard > -0.05 - 0.01 * ore_size and scrapyard < 0.05 + 0.01 * ore_size  then
    if math_random(1,20) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
  end
  if scrapyard + 0.5 > -0.1  - 0.1 * planet[1].type.moisture and scrapyard + 0.5 < 0.1 +  0.1 * planet[1].type.moisture  then
    local treetypes = tree_raffle[math_random(1, s_tree_raffle)]
    if planet[1].type.id == 14 then treetypes = dead_tree_raffle[math_random(1, 5)] end --lava planet
    if math_random(1,100) > 42 - handicap / 6 then
      if math_random(1,800) == 1 then
        treasure[#treasure + 1] = p
      else
        entities[#entities + 1] = {name = treetypes , position = p}
      end
    end
  end

	if scrapyard > -0.10 and scrapyard < 0.10 then
		if math_floor(large_caves * 10) % 4 < 3 then
      local jumps = objective.chronojumps * 5
      if objective.chronojumps > 20 then jumps = 100 end
      local roll = math_random(1,200 - jumps - biters)
      if math_sqrt(p.x * p.x + p.y * p.y) > 200 + handicap then
			if roll == 1 then
          entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p}
        elseif roll == 2 then
          entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}
        elseif roll == 3 then
          --if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
        end
			  return
      end
		end
	end
end

local function process_scrapyard_position(p, seed, tiles, entities, treasure, planet)
  local objective = Chrono_table.get_table()
  local scrapyard = get_noise("scrapyard", p, seed)
  local biters = planet[1].type.biters
	--Chasms
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
	if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
		if small_caves > 0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if scrapyard < -0.25 or scrapyard > 0.25 then
		if math_random(1, 256) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 50 then
			entities[#entities + 1] = {name="gun-turret", position=p, force = "scrapyard"}
		end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		 if scrapyard < -0.55 or scrapyard > 0.55 then
			if math_random(1,40) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
			return
		 end
     if scrapyard + 0.5 > -0.05  - 0.1 * planet[1].type.moisture and scrapyard + 0.5 < 0.05 +  0.1 * planet[1].type.moisture  then
       if math_random(1,100) > 42 then entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p} end
     end
		if scrapyard < -0.28 or scrapyard > 0.28 then
			if math_random(1,48) == 1 then entities[#entities + 1] = {name = scrap_entities[math_random(1, scrap_entities_index)], position = p, force = "enemy"} end
			if math_random(1,3) == 1 then entities[#entities + 1] = {name="mineable-wreckage", position=p} end
			return
		end
		return
	end

	local cave_ponds = get_noise("cave_ponds", p, seed)
	if cave_ponds < -0.6 and scrapyard > -0.2 and scrapyard < 0.2 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	local large_caves = get_noise("large_caves", p, seed)
	if scrapyard > -0.15 and scrapyard < 0.15 then
		if math_floor(large_caves * 10) % 4 < 3 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
      local jumps = objective.chronojumps * 5
      if objective.chronojumps > 20 then jumps = 100 end
			if math_random(1,200 - jumps) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p} end
			return
		end
	end
	tiles[#tiles + 1] = {name = "dirt-7", position = p}
  tiles[#tiles + 1] = {name = "stone-path", position = p}
end

local function process_swamp_position(p, seed, tiles, entities, treasure, planet)
  local scrapyard = get_noise("scrapyard", p, seed)
  local biters = planet[1].type.biters

  if scrapyard < -0.70 or scrapyard > 0.70 then
    tiles[#tiles + 1] = {name = "grass-3", position = p}
    if math_random(1,40) == 1 then treasure[#treasure + 1] = p end
    return
  end

  if scrapyard < -0.65 or scrapyard > 0.65 then
    tiles[#tiles + 1] = {name = "water-green", position = p}
    return
  end
  if math_abs(scrapyard) > 0.50 and  math_abs(scrapyard) < 0.65 then
    if math_random(1,70) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 140 then entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}end
    tiles[#tiles + 1] = {name = "water-mud", position = p}
    return
  end
  if math_abs(scrapyard) > 0.35 and  math_abs(scrapyard) < 0.50 then
    if math_random(1,140) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 140 then entities[#entities + 1] = {name = worm_raffle[math_random(1 + math_floor(game.forces["enemy"].evolution_factor * 8), math_floor(1 + game.forces["enemy"].evolution_factor * 16))], position = p}end
    tiles[#tiles + 1] = {name = "water-shallow", position = p}
    return
  end
  if scrapyard > -0.15 and scrapyard < 0.15 then
    if math_random(1,100) > 58 then
      entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p}
    else
      if math_random(1,8) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
    end
    tiles[#tiles + 1] = {name = "grass-1", position = p}
    return
  end
	if math_random(1, 160) == 1 and math_sqrt(p.x * p.x + p.y * p.y) > 150 then
		entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p}
	end
	tiles[#tiles + 1] = {name = "grass-2", position = p}
end

local function process_fish_position(p, seed, tiles, entities, treasure, planet)
  local body_radius = 1984 --3072
  local body_square_radius = body_radius ^ 2
  local body_center_position = {x = 0, y = 0}
  local body_spacing = math_floor(body_radius * 0.82)
  local body_circle_center_1 = {x = body_center_position.x, y = body_center_position.y - body_spacing}
  local body_circle_center_2 = {x = body_center_position.x, y = body_center_position.y + body_spacing}

  --local fin_radius = 200
  --local square_fin_radius = fin_radius ^ 2
  --local fin_circle_center_1 = {x = -600, y = 0}
  --local fin_circle_center_2 = {x = -600 - 120, y = 0}

	--if math_abs(p.y) > 480 and p.x <= 160 and p.x > body_center_position.x then return true end

	--Main Fish Body
	local distance_to_center_1 = ((p.x - body_circle_center_1.x)^2 + (p.y - body_circle_center_1.y)^2)
	local distance_to_center_2 = ((p.x - body_circle_center_2.x)^2 + (p.y - body_circle_center_2.y)^2)
  --local distance_to_fin_1 = ((p.x - fin_circle_center_1.x)^2 + (p.y - fin_circle_center_1.y)^2)
  --local distance_to_fin_2 = ((p.x - fin_circle_center_2.x)^2 + (p.y - fin_circle_center_2.y)^2)
  local eye_center = {x = -500, y = -150}


	if distance_to_center_1 < body_square_radius and distance_to_center_2 < body_square_radius then
    if p.x < -600 and p.x > -1090 and p.y < 64 and p.y > -64 then --mouth
      local noise = simplex_noise(p.x * 0.006, 0, seed) * 20
      if p.y <= 12 + noise and p.y >= -12 + noise then
        tiles[#tiles + 1] = {name = "water", position = p}
      else
        tiles[#tiles + 1] = {name = "grass-1", position = p}
        local roll = math_random(1,500)
        if roll < 4 and p.x > -800 then
          entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p}
        elseif roll == 5 and p.x > -800 then
          entities[#entities + 1] = {name = "behemoth-worm-turret", position = p}
        elseif roll == 6 then
          entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p}
        end
      end
    else
			local distance = math_sqrt(((eye_center.x - p.x) ^ 2) + ((eye_center.y - p.y) ^ 2))
			if distance < 33 and distance >= 15 then --eye
				tiles[#tiles + 1 ] = {name = "water-green", position = p}
			elseif distance < 15 then --eye
				tiles[#tiles + 1] = {name = "out-of-map", position = p}
			else --rest
        tiles[#tiles + 1 ] = {name = "grass-1", position = p}
        local roll = math_random(1,500)
        if roll < 4 and p.x > -800 then
          entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p}
        elseif roll == 5 and p.x > -800 then
          entities[#entities + 1] = {name = "behemoth-worm-turret", position = p}
        elseif roll == 6 then
          entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p}
        end
      end
    end

  -- elseif distance_to_fin_2 < square_fin_radius and distance_to_fin_1 + math_abs(simplex_noise(0, p.y * 0.075, seed) * 32000) > square_fin_radius then
  --   tiles[#tiles + 1 ] = {name = "dirt-7", position = p}
  else
    if p.x > 800 and math_abs(p.y) < p.x - 800 then --tail
      tiles[#tiles + 1 ] = {name = "grass-1", position = p}
      local roll = math_random(1,500)
      if roll < 4 and p.x > -800 then
        entities[#entities + 1] = {name = spawner_raffle[math_random(1, 4)], position = p}
      elseif roll == 5 and p.x > -800 then
        entities[#entities + 1] = {name = "behemoth-worm-turret", position = p}
      elseif roll == 6 then
        entities[#entities + 1] = {name = tree_raffle[math_random(1, s_tree_raffle)], position = p}
      end
    else
      tiles[#tiles + 1 ] = {name = "out-of-map", position = p}
    end
  end
end

local levels = {
	process_level_1_position,
	process_dangerevent_position,
	process_hedgemaze_position,
	process_rocky_position,
	process_forest_position,
	process_river_position,
	process_biter_position,
	process_scrapyard_position,
	process_swamp_position,
	process_fish_position,
}

local entity_functions = {
	["turret"] = function(surface, entity) surface.create_entity(entity) end,
	["simple-entity"] = function(surface, entity) surface.create_entity(entity) end,
	["ammo-turret"] = function(surface, entity)
    local e = surface.create_entity(entity)
		e.insert({name = "uranium-rounds-magazine", count = math_random(16, 64)})
	end,
	["container"] = function(surface, entity)
		Treasure(surface, entity.position, entity.name)
	end,
  ["lab"] = function(surface, entity)
	local objective = Chrono_table.get_table()
    local e = surface.create_entity(entity)
    local evo = 1 + math_min(math_floor(objective.chronojumps / 4), 4)
    local research = {
      {"automation-science-pack", "logistic-science-pack"},
      {"automation-science-pack", "logistic-science-pack", "military-science-pack"},
      {"automation-science-pack", "logistic-science-pack", "military-science-pack", "chemical-science-pack"},
      {"automation-science-pack", "logistic-science-pack", "military-science-pack", "chemical-science-pack", "production-science-pack"},
      {"automation-science-pack", "logistic-science-pack", "military-science-pack", "chemical-science-pack", "production-science-pack", "utility-science-pack"}
    }
    for _,science in pairs(research[evo]) do
      e.insert({name = science, count = math_random(math_min(32 + objective.chronojumps, 100), math_min(64 + objective.chronojumps, 200))})
    end
  end,
}

local function get_replacement_tile(surface, position)
	local objective = Chrono_table.get_table()
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then return tile.name end
		end
	end
  if objective.planet[1].type.id == 18 then return "grass-2" end
	return "grass-1"
end

local function replace_water(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if surface.get_tile(p).collides_with("resource-layer") then
				surface.set_tiles({{name = get_replacement_tile(surface, p), position = p}}, true)
			end
		end
	end
end

local function forest_chunk(surface, left_top, level, planet)
  local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	local process_level = levels[level]
  for y = 0.5, 31.5, 1 do
		for x = 0.5, 31.5, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet)
		end
	end
  surface.set_tiles(tiles, true)
  for _, entity in pairs(entities) do
		if surface.can_place_entity(entity) then
			local e = surface.create_entity(entity)
      if e.name == "biter-spawner" or e.name == "spitter-spawner" or e.name == "small-worm-turret" or e.name == "medium-worm-turret" or e.name == "big-worm-turret" or e.name == "behemoth-worm-turret" then
        if math_abs(e.position.x) > 420 or math_abs(e.position.y) > 420 then e.destructible = false end
      end
		end
	end
end

local function biter_chunk(surface, left_top, level, planet)
  local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	local process_level = levels[level]
  for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet)
		end
	end
  for _, p in pairs(treasure) do
		local name = "wooden-chest"
		if math_random(1, 6) == 1 then name = "iron-chest" end
		Treasure(surface, p, name)
	end
  surface.set_tiles(tiles, true)
  for _, entity in pairs(entities) do
		if surface.can_place_entity(entity) then
			local e = surface.create_entity(entity)
      if e.name == "biter-spawner" or e.name == "spitter-spawner" or e.name == "small-worm-turret" or e.name == "medium-worm-turret" or e.name == "big-worm-turret" or e.name == "behemoth-worm-turret" then
        if math_abs(e.position.x) > 420 or math_abs(e.position.y) > 420 then e.destructible = false end
      end
		end

	end
end

local function empty_chunk(surface, left_top, level, planet)
	local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	local process_level = levels[level]

	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
      if planet[1].type.id == 16 then
        process_level(p, seed, tiles, entities, treasure, planet, true, nil)
      else
			  process_level(p, seed, tiles, entities, treasure, planet)
      end
		end
	end
	surface.set_tiles(tiles, true)
  replace_water(surface, left_top)
  if planet[1].type.id == 18 and left_top.y > 31 and left_top.x > 31 then
    for x = 1, 5, 1 do
      for y = 1, 5, 1 do
        local pos = {x = left_top.x + x, y = left_top.y + y}
        surface.set_tiles({{name = "deepwater-green", position = pos}})
      end
    end
  end
end

local function danger_chunk(surface, left_top, level, planet)
	local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	local process_level = levels[level]

	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet)
		end
	end
	surface.set_tiles(tiles, true)
  replace_water(surface, left_top)
  Specials.danger_event(surface, left_top)
end

local function fish_market(surface, left_top, level, planet)
  local tiles = {}
	local entities = {}
  local seed = surface.map_gen_settings.seed
  local process_level = levels[level]
  for y = 0, 31, 1 do
    for x = 0, 31, 1 do
      local p = {x = left_top.x + x, y = left_top.y + y}
      process_level(p, seed, tiles, entities, treasure, planet)
    end
  end
  surface.set_tiles(tiles, true)
  Specials.fish_market(surface, left_top)
end

local function fish_chunk(surface, left_top, level, planet)
  local tiles = {}
	local entities = {}
	local treasure = {}
  local seed = surface.map_gen_settings.seed
  local process_level = levels[level]
  for y = 0, 31, 1 do
    for x = 0, 31, 1 do
      local p = {x = left_top.x + x, y = left_top.y + y}
      process_level(p, seed, tiles, entities, treasure, planet)
    end
  end
  surface.set_tiles(tiles, true)
  for _, p in pairs(treasure) do
		local name = "wooden-chest"
		if math_random(1, 6) == 1 then name = "iron-chest" end
		Treasure(surface, p, name)
	end
  for _, entity in pairs(entities) do
		if entity_functions[game.entity_prototypes[entity.name].type] then
			entity_functions[game.entity_prototypes[entity.name].type](surface, entity)
		else
			if surface.can_place_entity(entity) then
				surface.create_entity(entity)
			end
		end
	end
end

local function normal_chunk(surface, left_top, level, planet)
	local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
  local process_level = levels[level]
  if planet[1].type.id == 16 then
    local cell = false
    local roll = math_random(1,20)
    local things = nil
    if roll == 1 then
      things = maze_things_raffle[math_random(1, 4)]
    elseif roll == 2 then
      things = "lake"
    elseif roll > 10 then
      things = "prospect"
    end
		if process_labyrinth_cell(left_top, seed) then
			cell = true
      if things == "prospect" then
        Ores.prospect_ores(nil, surface, {x = left_top.x + 16, y = left_top.y + 16})
      elseif things == "camp" or things == "lab" then
        local positions = {
          {x = left_top.x + 9, y = left_top.y + 9},{x = left_top.x + 9, y = left_top.y + 16},{x = left_top.x + 9, y = left_top.y + 23},
          {x = left_top.x + 16, y = left_top.y + 9},{x = left_top.x + 16, y = left_top.y + 23},
          {x = left_top.x + 23, y = left_top.y + 9},{x = left_top.x + 23, y = left_top.y + 16},{x = left_top.x + 23, y = left_top.y + 23}
        }
        for i = 1, 8, 1 do
          entities[#entities + 1] = {name = "gun-turret", position = positions[i], force = "scrapyard"}
        end
        if things == "lab" then
          entities[#entities + 1] = {name = "lab", position = {x = left_top.x + 15, y = left_top.y + 15}, force = "neutral"}
        end
      end
		end
    for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet, cell, things)
		end
	end
  else
    for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, treasure, planet)
		end
	end
  end
	surface.set_tiles(tiles, true)

	for _, p in pairs(treasure) do
		local name = "wooden-chest"
		if math_random(1, 6) == 1 then name = "iron-chest" end
		Treasure(surface, p, name)
	end

	for _, entity in pairs(entities) do
		if entity_functions[game.entity_prototypes[entity.name].type] then
			entity_functions[game.entity_prototypes[entity.name].type](surface, entity)
		else
			if surface.can_place_entity(entity) then
				local e = surface.create_entity(entity)
        if e.name == "biter-spawner" or e.name == "spitter-spawner" or e.name == "small-worm-turret" or e.name == "medium-worm-turret" or e.name == "big-worm-turret" or e.name == "behemoth-worm-turret" then
          if math_abs(e.position.x) > 420 or math_abs(e.position.y) > 420 then e.destructible = false end
        end
			end
		end
	end
end

local function process_chunk(surface, left_top)
  local objective = Chrono_table.get_table()
  if not surface then return end
  if not surface.valid then return end
  local planet = objective.planet
  if planet[1].type.id == 17 then level_depth = 2176 end
  if left_top.x >= level_depth * 0.5 or left_top.y >= level_depth * 0.5 then return end
  if left_top.x < level_depth * -0.5 or left_top.y < level_depth * -0.5 then return end



	--if left_top.y >= 0 then replace_water(surface, left_top) end
	--if left_top.y > 32 then game.forces.player.chart(surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}}) end
	-- if left_top.y == -128 and left_top.x == -128 then
	-- 	local p = objective.locomotive.position
	-- 	for _, entity in pairs(surface.find_entities_filtered({area = {{p.x - 3, p.y - 4},{p.x + 3, p.y + 10}}, type = "simple-entity"})) do	entity.destroy() end
	-- end

  local id = planet[1].type.id --from chronobubbles
  if id == 10 then --scrapyard
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 8, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then normal_chunk(surface, left_top, 8, planet) return end
  elseif id == 13 then --river planet
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 6, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then normal_chunk(surface, left_top, 6, planet) return end
  elseif id == 12 then --choppy planet
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 5, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then forest_chunk(surface, left_top, 5, planet) return end
  elseif id == 11 then --rocky planet
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 4, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then normal_chunk(surface, left_top, 4, planet) return end
  elseif id == 14 then --lava planet
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 7, planet) end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then biter_chunk(surface, left_top, 7, planet) end
    replace_water(surface, left_top)
    return
  elseif id == 16 then --hedge maze
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 3, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then normal_chunk(surface, left_top, 3, planet) return end
  elseif id == 17 then --fish market
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x - 864) <= 31 then fish_market(surface, left_top, 10, planet) return end
    fish_chunk(surface, left_top, 10, planet)
  elseif id == 18 then --swamp planet
    if math_abs(left_top.y) <= 63 and math_abs(left_top.x) <= 63 then empty_chunk(surface, left_top, 9, planet) return end
    if math_abs(left_top.y) > 63 or math_abs(left_top.x) > 63 then normal_chunk(surface, left_top, 9, planet) return end
  elseif id == 19 then --danger event
    if math_abs(left_top.y) <= 63 and math_abs(left_top.x) <= 63 then empty_chunk(surface, left_top, 2, planet) return end
    if math_abs(left_top.y) == 448 and math_abs(left_top.x) == 448 then danger_chunk(surface, left_top, 2, planet) return end
    if math_abs(left_top.y) > 63 or math_abs(left_top.x) > 63 then normal_chunk(surface, left_top, 2, planet) return end
  else
    if math_abs(left_top.y) <= 31 and math_abs(left_top.x) <= 31 then empty_chunk(surface, left_top, 7, planet) return end
    if math_abs(left_top.y) > 31 or math_abs(left_top.x) > 31 then biter_chunk(surface, left_top, 7, planet) return end
  end
	--if left_top.y > 96 then out_of_map(surface, left_top) return end
	--if left_top.y > 64 then biter_chunk(surface, left_top) return end
	--if left_top.y >= 0 then border_chunk(surface, left_top) return end
  --rock_chunk(surface, left_top)
  --return
end

local function on_chunk_generated(event)
	if string.sub(event.surface.name, 0, 12) ~= "chronosphere" then return end
	process_chunk(event.surface, event.area.left_top)
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)

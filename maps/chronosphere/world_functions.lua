local Treasure = require 'maps.chronosphere.treasure'
local Simplex_noise = require "utils.simplex_noise".d2
local Raffle = require "maps.chronosphere.raffles"
local Chrono_table = require 'maps.chronosphere.table'
local abs = math.abs
local random = math.random
local sqrt = math.sqrt
local min = math.min
local floor = math.floor

local Public = {}

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

local entity_functions = {
	["turret"] = function(surface, entity) surface.create_entity(entity) end,
	["simple-entity"] = function(surface, entity) surface.create_entity(entity) end,
  ["simple-entity-with-owner"] = function(surface, entity) surface.create_entity(entity) end,
	["ammo-turret"] = function(surface, entity)
    local e = surface.create_entity(entity)
		e.insert({name = "uranium-rounds-magazine", count = random(16, 64)})
	end,
	["container"] = function(surface, entity)
		Treasure(surface, entity.position, entity.name)
	end,
  ["lab"] = function(surface, entity)
  	local objective = Chrono_table.get_table()
    local e = surface.create_entity(entity)
    local evo = 1 + min(floor(objective.chronojumps / 5), 4)
    local research = {
      {"automation-science-pack", "logistic-science-pack"},
      {"automation-science-pack", "logistic-science-pack", "military-science-pack"},
      {"automation-science-pack", "logistic-science-pack", "military-science-pack", "chemical-science-pack"},
      {"automation-science-pack", "logistic-science-pack", "military-science-pack", "chemical-science-pack", "production-science-pack"},
      {"automation-science-pack", "logistic-science-pack", "military-science-pack", "chemical-science-pack", "production-science-pack", "utility-science-pack"}
    }
    for _,science in pairs(research[evo]) do
      e.insert({name = science, count = random(min(30 + objective.chronojumps * 5, 100), min(60 + objective.chronojumps * 5, 200))})
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
	return objective.world.default_tile or "grass-1"
end

function Public.get_noise(name, pos, seed)
	local noise = 0
	local d = 0
	for _, n in pairs(noises[name]) do
		noise = noise + Simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		d = d + n.weight
		seed = seed + 10000
	end
	noise = noise / d
	return noise
end

function Public.replace_water(surface, left_top)
  local tiles = {}
  local hidden_tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
      local tile = surface.get_tile(p)
      if tile.hidden_tile then
        surface.set_hidden_tile(p, get_replacement_tile(surface, p).name)
      elseif tile.collides_with("resource-layer") then
        tiles[#tiles+1] = {name = get_replacement_tile(surface, p), position = p}
			end
		end
	end
  surface.set_tiles(tiles, true)
end

function Public.spawn_entities(surface, entities)
	local objective = Chrono_table.get_table()
  for _, entity in pairs(entities) do
    if entity_functions[game.entity_prototypes[entity.name].type] then
			entity_functions[game.entity_prototypes[entity.name].type](surface, entity)
		else
  		if surface.can_place_entity(entity) then
  			local e = surface.create_entity(entity)
        if (e.type == "unit-spawner" or e.type == "turret") and objective.world.id ~= 7 then
          if abs(e.position.x) > 420 or abs(e.position.y) > 420 then e.destructible = false end
        end
  		end
    end
	end
end

function Public.spawn_decoratives(surface, decoratives)
	surface.create_decoratives{check_collision = false, decoratives = decoratives}
end

function Public.spawn_treasures(surface, treasures)
  for _, p in pairs(treasures) do
		local name = "wooden-chest"
		if random(1, 6) == 1 then name = "iron-chest" end
    if surface.can_place_entity({name = name, position = p}) then
      Treasure(surface, p, name)
    end
	end
end

function Public.distance(x, y)
  return sqrt(x*x + y*y)
end

function Public.is_scrap(name)
  for i = 1, #Raffle.scraps, 1 do
    if name == Raffle.scraps[i] then return true end
  end
  for i = 1, #Raffle.scraps_inv, 1 do
    if name == Raffle.scraps_inv[i] then return true end
  end
  return false
end

--LABYRINTH--
local modifiers = {
  {x = 0, y = -1},{x = -1, y = 0},{x = 1, y = 0},{x = 0, y = 1}
}
local modifiers_diagonal = {
  {diagonal = {x = -1, y = 1}, connection_1 = {x = -1, y = 0}, connection_2 = {x = 0, y = 1}},
  {diagonal = {x = 1, y = -1}, connection_1 = {x = 1, y = 0}, connection_2 = {x = 0, y = -1}},
  {diagonal = {x = 1, y = 1}, connection_1 = {x = 1, y = 0}, connection_2 = {x = 0, y = 1}},
  {diagonal = {x = -1, y = -1}, connection_1 = {x = -1, y = 0}, connection_2 = {x = 0, y = -1}}
}

local function get_path_connections_count(cell_pos)
	local scheduletable = Chrono_table.get_schedule_table()
	local connections = 0
	for _, m in pairs(modifiers) do
		if scheduletable.lab_cells[tostring(cell_pos.x + m.x) .. "_" .. tostring(cell_pos.y + m.y)] then
			connections = connections + 1
		end
	end
	return connections
end

function Public.process_labyrinth_cell(pos, seed)
	local scheduletable = Chrono_table.get_schedule_table()
	local lake_noise_value = -0.85
  local cell_position = {x = pos.x / 32, y = pos.y / 32}
  local mazenoise = Public.get_noise("hedgemaze", cell_position, seed)

  if mazenoise < lake_noise_value and Public.distance(pos.x/32, pos.y/32) > 65 then return false end

	scheduletable.lab_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] = false

	for _, modifier in pairs(modifiers_diagonal) do
		if scheduletable.lab_cells[tostring(cell_position.x + modifier.diagonal.x) .. "_" .. tostring(cell_position.y + modifier.diagonal.y)] then
			local connection_1 = scheduletable.lab_cells[tostring(cell_position.x + modifier.connection_1.x) .. "_" .. tostring(cell_position.y + modifier.connection_1.y)]
			local connection_2 = scheduletable.lab_cells[tostring(cell_position.x + modifier.connection_2.x) .. "_" .. tostring(cell_position.y + modifier.connection_2.y)]
			if not connection_1 and not connection_2 then
				return false
			end
		end
	end

	for _, m in pairs(modifiers) do
		if get_path_connections_count({x = cell_position.x + m.x, y = cell_position.y + m.y}) >= random(2, 3) then return false end
	end

	if get_path_connections_count(cell_position) >= random(2, 3) then return false end

	scheduletable.lab_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] = true
	return true
end

return Public

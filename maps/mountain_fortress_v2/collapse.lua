local Public = {}
local simplex_noise = require "utils.simplex_noise".d2
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor
local table_remove = table.remove
local table_insert = table.insert
local table_shuffle_table = table.shuffle_table
local chart_radius = 30
local start_chunk_y = 5
local tile_conversion = {
	["concrete"] = "stone-path",
	["hazard-concrete-left"] = "stone-path",
	["hazard-concrete-right"] = "stone-path",
	["refined-concrete"] = "concrete",
	["refined-hazard-concrete-left"] = "hazard-concrete-left",
	["refined-hazard-concrete-right"] = "hazard-concrete-right",
	["stone-path"] = "landfill",
}

local size_of_vector_list = 64
local function get_collapse_vectors(radius, seed)
	local vectors = {}
	local i = 1
	local m = 1 / (radius * 2)
	for x = radius * -1, radius, 1 do
		for y = radius * -1, radius, 1 do
			local noise = math_abs(simplex_noise(x * m, y * m, seed) * radius * 1.2)
			local d = math_sqrt(x ^ 2 + y ^ 2)
			if d + noise < radius then
				vectors[i] = {x, y}
				i = i + 1
			end
		end
	end

	local sorted_vectors = {}
	for _, vector in pairs(vectors) do
		local index = math_floor(math_sqrt(vector[1] ^ 2 + vector[2] ^ 2)) + 1
		if not sorted_vectors[index] then sorted_vectors[index] = {} end
		sorted_vectors[index][#sorted_vectors[index] + 1] = vector
	end

	local final_list = {}
	for _, row in pairs(sorted_vectors) do
		table_shuffle_table(row)
		for _, tile in pairs(row) do
			table_insert(final_list, tile)
		end
	end

	return final_list
end

local function set_y(surface)
	local level_width = surface.map_gen_settings.width
	local map_collapse = global.map_collapse
	local x_left = surface.map_gen_settings.width * -0.5
	local x_right = surface.map_gen_settings.width * 0.5
	for _ = 1, 16, 1 do
		local area = {{x_left, map_collapse.last_position.y},{x_right, map_collapse.last_position.y + 1}}
		if surface.count_tiles_filtered({name = "out-of-map", area = area}) < level_width then
			return area
		end
		map_collapse.last_position.y = map_collapse.last_position.y - 1
	end
end

local function set_positions(surface)
	local area = set_y(surface)
	if not area then return end

	local map_collapse = global.map_collapse
	map_collapse.positions = {}

	local i = 1
	for _, tile in pairs(surface.find_tiles_filtered({area = area})) do
		if tile.valid then
			if tile.name ~= "out-of-map" then
				map_collapse.positions[i] = tile
				i = i + 1
			end
		end
	end

	if i == 1 then
		map_collapse.positions = nil
		return
	end
	if i > 1 then table_shuffle_table(map_collapse.positions) end
end

local function set_collapse_tiles(surface, position, vectors)
	local map_collapse = global.map_collapse
	map_collapse.processing = {}
	local i = 1
	for _, vector in pairs(vectors) do
		local shifted_position = {x = position[1] + vector[1], y = position[2] + vector[2] - 60}
		local position = {x = position[1] + vector[1], y = position[2] + vector[2]}
		local rocks = surface.find_entities_filtered{position = shifted_position, radius = 2, type = {"simple-entity", "tree"}}
		if #rocks > 0 then
			for i = 1, #rocks, 1 do
				if rocks[i].valid then
					rocks[i].destroy()
				end
			end
		end
		local tile = surface.get_tile(position)
		if tile.valid and tile.name ~= "out-of-map" then
			map_collapse.processing[i] = tile
			i = i + 1
		end
	end
	map_collapse.processing_index = 1
	map_collapse.size_of_processing = #map_collapse.processing
end

local function clean_positions(tbl)
	for k, tile in pairs(tbl) do
		if not tile.valid then
			table_remove(tbl, k)
		else
			if tile.name == "out-of-map" then
				table_remove(tbl, k)
			end
		end
	end
end

local function setup_next_collapse()
	local surface = game.surfaces[global.active_surface_index]
	local map_collapse = global.map_collapse
	if not map_collapse.vector_list then
		map_collapse.vector_list = {}
		for _ = 1, size_of_vector_list, 1 do
			table_insert(global.map_collapse.vector_list, get_collapse_vectors(math_random(24, 48), math_random(1, 9999999)))
		end
	end

	if not map_collapse.positions then
		--if math_random(1, 64) == 1 then map_collapse.last_position = {x = 0, y = 128} end
		set_positions(surface)
		return
	end

	local tile = map_collapse.positions[#map_collapse.positions]
	if not tile then map_collapse.positions = nil return end
	if not tile.valid then clean_positions(map_collapse.positions) return end
	if tile.name == "out-of-map" then clean_positions(map_collapse.positions) return end

	local position = {tile.position.x, tile.position.y}

	local vectors = map_collapse.vector_list[math_random(1, size_of_vector_list)]
	set_collapse_tiles(surface, position, vectors)

	local last_position = global.map_collapse.last_position
	game.forces.player.chart(surface, {{last_position.x - chart_radius, last_position.y - chart_radius},{last_position.x + chart_radius, last_position.y + chart_radius}})
	global.map_collapse.last_position = {x = position[1], y = position[2]}
	game.forces.player.chart(surface, {{position[1] - chart_radius, position[2] - chart_radius},{position[1] + chart_radius, position[2] + chart_radius}})
end

function Public.delete_out_of_map_chunks(surface)
	local count = 0
	for chunk in surface.get_chunks() do
		if surface.count_tiles_filtered({name = "out-of-map", area = chunk.area}) == 1024 then
			surface.delete_chunk({chunk.x, chunk.y})
			count = count + 1
		end
	end
end

local function process_tile(surface, tile, tiles_to_set)
	if not tile then return end
	if not tile.valid then return end

	local conversion_tile = tile_conversion[tile.name]
	if conversion_tile then
		table_insert(tiles_to_set, {name = conversion_tile, position = tile.position})
		surface.create_trivial_smoke({name="train-smoke", position = tile.position})
	else
		table_insert(tiles_to_set, {name = "out-of-map", position = tile.position})
	end

	return true
end

function Public.process()
	local surface = game.surfaces[global.active_surface_index]
	local map_collapse = global.map_collapse

	if map_collapse.processing_index >= map_collapse.size_of_processing then
		setup_next_collapse()
		return
	end

	local count = 0
	local tiles_to_set = {}
	for i = map_collapse.processing_index, map_collapse.size_of_processing, 1 do
		if process_tile(surface, map_collapse.processing[i], tiles_to_set) then
			count = count + 1
			if count >= map_collapse.speed then break end
		end
		map_collapse.processing_index = map_collapse.processing_index + 1
	end

	if count > 1 then surface.set_tiles(tiles_to_set, true) end
end

function Public.init()
	global.map_collapse = {
		["processing_index"] = 0,
		["size_of_processing"] = 0,
		["processing"] = {},
		["last_position"] = {x = 0, y = 128},
		["speed"] = 3,
	}
end

local event = require 'utils.event'
event.on_init(Public.init())

return Public

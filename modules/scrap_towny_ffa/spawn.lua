local Public = {}

local table_size = table.size
local table_insert = table.insert
local math_random = math.random
local math_rad = math.rad
local math_sin = math.sin
local math_cos = math.cos
local math_floor = math.floor

local Table = require 'modules.scrap_towny_ffa.table'
local Enemy = require "modules.scrap_towny_ffa.enemy"
local Building = require "modules.scrap_towny_ffa.building"

-- don't spawn if town is within this range
local spawn_point_town_buffer = 256
-- clear enemies within this distance from spawn
local spawn_point_safety = 16
-- incremental spawn distance from existing town
-- this is how much each attempt is incremented by for checking a pollution free area
local spawn_point_incremental_distance = 16

local function force_load(position, surface, radius)
	--log("is_chunk_generated = " .. tostring(surface.is_chunk_generated(position)))
	surface.request_to_generate_chunks(position, radius)
	--log("force load position = {" .. position.x .. "," .. position.y .. "}")
	surface.force_generate_chunk_requests()
end

-- gets an area (might not be even amount)
local function get_area(position, w, h)
	local x1 = math_floor(w / 2)
	local x2 = w - x1
	local y1 = math_floor(h / 2)
	local y2 = h - y1
	return { { position.x - x1, position.y - y1 }, { position.x + x2, position.y + y2 } }
end

local function clear_spawn(position, surface, w, h)
	--log("clear_spawn {" .. position.x .. "," .. position.y .. "}")
	local area = get_area(position, w, h)
	for _, e in pairs(surface.find_entities_filtered({ area = area })) do
		if e.type ~= "character" then
			e.destroy()
		end
	end
end

-- does the position have any pollution
local function has_pollution(position, surface)
	local result = surface.get_pollution(position) > 0.0
	--log("has_pollution = " .. tostring(result))
	return result
end

-- is the position already used
local function in_use(position)
	local ffatable = Table.get_table()
	local result = false
	for _, v in pairs(ffatable.spawn_point) do
		if v == position then result = true end
	end
	--log("in_use = " .. tostring(result))
	return result
end

-- is the position empty
local function is_empty(position, surface)
	local entity_radius = 1
	local tile_radius = 1
	local entities = surface.count_entities_filtered({ position = position, radius = entity_radius, collision_mask = { "object-layer", "player-layer" } })
	--log("entities = " .. entities)
	if entities > 0 then return false end
	local tiles = surface.count_tiles_filtered({ position = position, radius = tile_radius, collision_mask = "water-tile" })
	--log("water-tiles = " .. tiles)
	if tiles > 0 then return false end
	local result = surface.can_place_entity({ name = "character", position = position })
	--log("is_empty = " .. tostring(result))
	return result
end

-- finds a valid spawn point that is not near a town and not in a polluted area
local function find_valid_spawn_point(surface)
	local ffatable = Table.get_table()
	-- check center of map first if valid
	local position = { x = 0, y = 0 }
	--log("testing {" .. position.x .. "," .. position.y .. "}")
	force_load(position, surface, 1)
	if in_use(position) == false then
		if Building.near_town(position, surface, spawn_point_town_buffer) == false then
			-- force load the position
			if is_empty(position, surface) == true then
				--log("found valid spawn point at {" .. position.x .. "," .. position.y .. "}")
				return position
			end
		end
	end
	-- otherwise find a nearby town
	local keyset = {}
	for town_name, _ in pairs(ffatable.town_centers) do
		table_insert(keyset, town_name)
	end
	local count = table_size(keyset)
	if count > 0 then
		local town_name = keyset[math_random(1, count)]
		local town_center = ffatable.town_centers[town_name]
		if town_center ~= nil then
			position = town_center.market.position
		end
		--log("town center is {" .. position.x .. "," .. position.y .. "}")
	end
	-- and start checking around it for a suitable spawn position
	local tries = 0
	local radius = spawn_point_town_buffer
	local angle
	while (tries < 100) do
		-- 8 attempts each position
		for _ = 1, 8 do
			-- position on the circle radius
			angle = math_random(0, 360)
			local t = math_rad(angle)
			local x = math_floor(position.x + math_cos(t) * radius)
			local y = math_floor(position.y + math_sin(t) * radius)
			local target = { x = x, y = y }
			--log("testing {" .. target.x .. "," .. target.y .. "}")
			force_load(position, surface, 1)
			if in_use(target) == false then
				if has_pollution(target, surface) == false then
					if Building.near_town(target, surface, spawn_point_town_buffer) == false then
						if is_empty(target, surface) == true then
							--log("found valid spawn point at {" .. target.x .. "," .. target.y .. "}")
							position = target
							return position
						end
					end
				end
			end
		end
		-- near a town, increment the radius and select another angle
		radius = radius + math_random(1, spawn_point_incremental_distance)
		angle = math_random(0, 360)
		tries = tries + 1
	end
	return { x = 0, y = 0 }
end

function Public.get_new_spawn_point(player, surface)
	local ffatable = Table.get_table()
	-- get a new spawn point
	local position = find_valid_spawn_point(surface)
	-- should never be invalid or blocked
	ffatable.spawn_point[player.name] = position
	--log("player " .. player.name .. " assigned new spawn point at {" .. position.x .. "," .. position.y .. "}")
	return position
end

-- gets a new or existing spawn point for the player
function Public.get_spawn_point(player, surface)
	local ffatable = Table.get_table()
	if ffatable.spawn_point == nil then ffatable.spawn_point = {} end
	-- test the existing spawn point
	local position = ffatable.spawn_point[player.name]
	if position ~= nil then
		-- check that the spawn point is not blocked
		if surface.can_place_entity({ name = "character", position = position }) then
			--log("player " .. player.name .. "using existing spawn point at {" .. position.x .. "," .. position.y .. "}")
			return position
		else
			position = surface.find_non_colliding_position("character", position, 16, 0.25)
			if (position ~= nil) then return position end
		end
	end
	-- otherwise get a new spawn point
	return Public.get_new_spawn_point(player, surface)
end

function Public.clear_spawn_point(position, surface)
	Enemy.clear_worms(position, surface, spawn_point_safety) -- behemoth worms can attack from a range of 48, clear first time only
	Enemy.clear_enemies(position, surface, spawn_point_safety) -- behemoth worms can attack from a range of 48
	clear_spawn(position, surface, 7, 9)
end

return Public
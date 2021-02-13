--This will add a new game mechanic so that containers with certain fluids explode when they get damaged or are destroyed.
--Made by MewMew
local math_random = math.random
local math_floor = math.floor

local Table = require 'modules.scrap_towny_ffa.table'
local Pollution = require "modules.scrap_towny_ffa.pollution"

local empty_tile_damage_decay = 50
local out_of_map_tile_health = 1500

local container_types = {
	["storage-tank"] = true,
	["pipe"] = true,
	["pipe-to-ground"] = true
}

local fluid_damages = { -- Fluid Whitelist -- add fluid and a damage value to enable
	["lubricant"] = 5,
	["crude-oil"] = 5,
	["gasoline"] = 8,
	["heavy-oil"] = 6,
	["light-oil"] = 7,
	["petroleum-gas"] = 8,
}

local function shuffle(tbl)
	local size = #tbl
	for i = size, 1, -1 do
		local rand = math_random(size)
		tbl[i], tbl[rand] = tbl[rand], tbl[i]
	end
	return tbl
end

local function process_explosion_tile(pos, explosion_index, current_radius)
  local ffatable = Table.get_table()
	local surface = game.surfaces[ffatable.fluid_explosion_schedule[explosion_index].surface]
	local target_entities = surface.find_entities_filtered({ area = { { pos.x - 0.5, pos.y - 0.5 }, { pos.x + 0.499, pos.y + 0.499 } } })
	local explosion_animation = "explosion"

	local tile = surface.get_tile(pos)
	if tile.name == "out-of-map" then
		if ffatable.fluid_explosion_schedule[explosion_index].damage_remaining >= out_of_map_tile_health then
			explosion_animation = "big-explosion"
			surface.set_tiles({ { name = "dirt-5", position = pos } }, true)
		end
		ffatable.fluid_explosion_schedule[explosion_index].damage_remaining = ffatable.fluid_explosion_schedule[explosion_index].damage_remaining - out_of_map_tile_health
	else
		local decay_explosion = true
		for _, entity in pairs(target_entities) do
			if entity.health then
				decay_explosion = false
			end
		end
		if decay_explosion then ffatable.fluid_explosion_schedule[explosion_index].damage_remaining = ffatable.fluid_explosion_schedule[explosion_index].damage_remaining - empty_tile_damage_decay end
	end

	for _, entity in pairs(target_entities) do
		if entity.valid then
			if entity.health then
				if entity.health <= ffatable.fluid_explosion_schedule[explosion_index].damage_remaining then
					explosion_animation = "big-explosion"
					if entity.health > 500 then explosion_animation = "big-artillery-explosion" end
					ffatable.fluid_explosion_schedule[explosion_index].damage_remaining = ffatable.fluid_explosion_schedule[explosion_index].damage_remaining - entity.health
					if entity.name ~= "character" then
						entity.damage(2097152, "player", "explosion")
					else
						entity.die("player")
					end
				else
					entity.damage(ffatable.fluid_explosion_schedule[explosion_index].damage_remaining, "player", "explosion")
					ffatable.fluid_explosion_schedule[explosion_index].damage_remaining = 0
				end
			end
		end
	end

	if ffatable.fluid_explosion_schedule[explosion_index].damage_remaining > 5000 and current_radius < 2 then
		if math_random(1, 2) == 1 then
			explosion_animation = "big-explosion"
		else
			explosion_animation = "big-artillery-explosion"
		end
	end

	surface.create_entity({ name = explosion_animation, position = pos })
	Pollution.explosion(pos, surface, explosion_animation)

	if ffatable.fluid_explosion_schedule[explosion_index].damage_remaining <= 0 then return false end

	return true
end

local function create_explosion_schedule(entity)
  local ffatable = Table.get_table()
	local explosives_amount = math_floor(entity.fluidbox[1].amount)

	if explosives_amount < 1 then return end
	local center_position = entity.position

	if not ffatable.fluid_explosion_schedule then ffatable.fluid_explosion_schedule = {} end
	ffatable.fluid_explosion_schedule[#ffatable.fluid_explosion_schedule + 1] = {}
	ffatable.fluid_explosion_schedule[#ffatable.fluid_explosion_schedule].surface = entity.surface.name

	ffatable.fluid_explosion_schedule[#ffatable.fluid_explosion_schedule].damage_remaining = fluid_damages[entity.fluidbox[1].name] * explosives_amount

	local circle_coordinates = {
		[1] = { { x = 0, y = 0 } },
		[2] = { { x = -1, y = -1 }, { x = 1, y = -1 }, { x = 0, y = -1 }, { x = -1, y = 0 }, { x = -1, y = 1 }, { x = 0, y = 1 }, { x = 1, y = 1 }, { x = 1, y = 0 } },
		[3] = { { x = -2, y = -1 }, { x = -1, y = -2 }, { x = 1, y = -2 }, { x = 0, y = -2 }, { x = 2, y = -1 }, { x = -2, y = 1 }, { x = -2, y = 0 }, { x = 2, y = 1 }, { x = 2, y = 0 }, { x = -1, y = 2 }, { x = 1, y = 2 }, { x = 0, y = 2 } },
		[4] = { { x = -1, y = -3 }, { x = 1, y = -3 }, { x = 0, y = -3 }, { x = -3, y = -1 }, { x = -2, y = -2 }, { x = 3, y = -1 }, { x = 2, y = -2 }, { x = -3, y = 0 }, { x = -3, y = 1 }, { x = 3, y = 1 }, { x = 3, y = 0 }, { x = -2, y = 2 }, { x = -1, y = 3 }, { x = 0, y = 3 }, { x = 1, y = 3 }, { x = 2, y = 2 } },
		[5] = { { x = -3, y = -3 }, { x = -2, y = -3 }, { x = -1, y = -4 }, { x = -2, y = -4 }, { x = 1, y = -4 }, { x = 0, y = -4 }, { x = 2, y = -3 }, { x = 3, y = -3 }, { x = 2, y = -4 }, { x = -3, y = -2 }, { x = -4, y = -1 }, { x = -4, y = -2 }, { x = 3, y = -2 }, { x = 4, y = -1 }, { x = 4, y = -2 }, { x = -4, y = 1 }, { x = -4, y = 0 }, { x = 4, y = 1 }, { x = 4, y = 0 }, { x = -3, y = 3 }, { x = -3, y = 2 }, { x = -4, y = 2 }, { x = -2, y = 3 }, { x = 2, y = 3 }, { x = 3, y = 3 }, { x = 3, y = 2 }, { x = 4, y = 2 }, { x = -2, y = 4 }, { x = -1, y = 4 }, { x = 0, y = 4 }, { x = 1, y = 4 }, { x = 2, y = 4 } },
		[6] = { { x = -1, y = -5 }, { x = -2, y = -5 }, { x = 1, y = -5 }, { x = 0, y = -5 }, { x = 2, y = -5 }, { x = -3, y = -4 }, { x = -4, y = -3 }, { x = 3, y = -4 }, { x = 4, y = -3 }, { x = -5, y = -1 }, { x = -5, y = -2 }, { x = 5, y = -1 }, { x = 5, y = -2 }, { x = -5, y = 1 }, { x = -5, y = 0 }, { x = 5, y = 1 }, { x = 5, y = 0 }, { x = -5, y = 2 }, { x = -4, y = 3 }, { x = 4, y = 3 }, { x = 5, y = 2 }, { x = -3, y = 4 }, { x = -2, y = 5 }, { x = -1, y = 5 }, { x = 0, y = 5 }, { x = 1, y = 5 }, { x = 3, y = 4 }, { x = 2, y = 5 } },
		[7] = { { x = -4, y = -5 }, { x = -3, y = -5 }, { x = -2, y = -6 }, { x = -1, y = -6 }, { x = 0, y = -6 }, { x = 1, y = -6 }, { x = 3, y = -5 }, { x = 2, y = -6 }, { x = 4, y = -5 }, { x = -5, y = -4 }, { x = -5, y = -3 }, { x = -4, y = -4 }, { x = 4, y = -4 }, { x = 5, y = -4 }, { x = 5, y = -3 }, { x = -6, y = -1 }, { x = -6, y = -2 }, { x = 6, y = -1 }, { x = 6, y = -2 }, { x = -6, y = 1 }, { x = -6, y = 0 }, { x = 6, y = 1 }, { x = 6, y = 0 }, { x = -5, y = 3 }, { x = -6, y = 2 }, { x = 5, y = 3 }, { x = 6, y = 2 }, { x = -5, y = 4 }, { x = -4, y = 4 }, { x = -4, y = 5 }, { x = -3, y = 5 }, { x = 3, y = 5 }, { x = 4, y = 4 }, { x = 5, y = 4 }, { x = 4, y = 5 }, { x = -1, y = 6 }, { x = -2, y = 6 }, { x = 1, y = 6 }, { x = 0, y = 6 }, { x = 2, y = 6 } },
		[8] = { { x = -1, y = -7 }, { x = -2, y = -7 }, { x = 1, y = -7 }, { x = 0, y = -7 }, { x = 2, y = -7 }, { x = -5, y = -5 }, { x = -4, y = -6 }, { x = -3, y = -6 }, { x = 3, y = -6 }, { x = 4, y = -6 }, { x = 5, y = -5 }, { x = -6, y = -3 }, { x = -6, y = -4 }, { x = 6, y = -4 }, { x = 6, y = -3 }, { x = -7, y = -1 }, { x = -7, y = -2 }, { x = 7, y = -1 }, { x = 7, y = -2 }, { x = -7, y = 1 }, { x = -7, y = 0 }, { x = 7, y = 1 }, { x = 7, y = 0 }, { x = -7, y = 2 }, { x = -6, y = 3 }, { x = 6, y = 3 }, { x = 7, y = 2 }, { x = -5, y = 5 }, { x = -6, y = 4 }, { x = 5, y = 5 }, { x = 6, y = 4 }, { x = -3, y = 6 }, { x = -4, y = 6 }, { x = -2, y = 7 }, { x = -1, y = 7 }, { x = 0, y = 7 }, { x = 1, y = 7 }, { x = 3, y = 6 }, { x = 2, y = 7 }, { x = 4, y = 6 } },
		[9] = { { x = -4, y = -7 }, { x = -3, y = -7 }, { x = -2, y = -8 }, { x = -1, y = -8 }, { x = 0, y = -8 }, { x = 1, y = -8 }, { x = 3, y = -7 }, { x = 2, y = -8 }, { x = 4, y = -7 }, { x = -5, y = -6 }, { x = -6, y = -6 }, { x = -6, y = -5 }, { x = 5, y = -6 }, { x = 6, y = -5 }, { x = 6, y = -6 }, { x = -7, y = -4 }, { x = -7, y = -3 }, { x = 7, y = -4 }, { x = 7, y = -3 }, { x = -8, y = -2 }, { x = -8, y = -1 }, { x = 8, y = -1 }, { x = 8, y = -2 }, { x = -8, y = 0 }, { x = -8, y = 1 }, { x = 8, y = 1 }, { x = 8, y = 0 }, { x = -7, y = 3 }, { x = -8, y = 2 }, { x = 7, y = 3 }, { x = 8, y = 2 }, { x = -7, y = 4 }, { x = -6, y = 5 }, { x = 6, y = 5 }, { x = 7, y = 4 }, { x = -5, y = 6 }, { x = -6, y = 6 }, { x = -4, y = 7 }, { x = -3, y = 7 }, { x = 3, y = 7 }, { x = 5, y = 6 }, { x = 4, y = 7 }, { x = 6, y = 6 }, { x = -2, y = 8 }, { x = -1, y = 8 }, { x = 0, y = 8 }, { x = 1, y = 8 }, { x = 2, y = 8 } },
		[10] = { { x = -3, y = -9 }, { x = -1, y = -9 }, { x = -2, y = -9 }, { x = 1, y = -9 }, { x = 0, y = -9 }, { x = 3, y = -9 }, { x = 2, y = -9 }, { x = -5, y = -7 }, { x = -6, y = -7 }, { x = -5, y = -8 }, { x = -4, y = -8 }, { x = -3, y = -8 }, { x = 3, y = -8 }, { x = 5, y = -7 }, { x = 5, y = -8 }, { x = 4, y = -8 }, { x = 6, y = -7 }, { x = -7, y = -5 }, { x = -7, y = -6 }, { x = -8, y = -5 }, { x = 7, y = -5 }, { x = 7, y = -6 }, { x = 8, y = -5 }, { x = -9, y = -3 }, { x = -8, y = -4 }, { x = -8, y = -3 }, { x = 8, y = -4 }, { x = 8, y = -3 }, { x = 9, y = -3 }, { x = -9, y = -1 }, { x = -9, y = -2 }, { x = 9, y = -1 }, { x = 9, y = -2 }, { x = -9, y = 1 }, { x = -9, y = 0 }, { x = 9, y = 1 }, { x = 9, y = 0 }, { x = -9, y = 3 }, { x = -9, y = 2 }, { x = -8, y = 3 }, { x = 8, y = 3 }, { x = 9, y = 3 }, { x = 9, y = 2 }, { x = -7, y = 5 }, { x = -8, y = 5 }, { x = -8, y = 4 }, { x = 7, y = 5 }, { x = 8, y = 5 }, { x = 8, y = 4 }, { x = -7, y = 6 }, { x = -6, y = 7 }, { x = -5, y = 7 }, { x = 5, y = 7 }, { x = 7, y = 6 }, { x = 6, y = 7 }, { x = -5, y = 8 }, { x = -4, y = 8 }, { x = -3, y = 8 }, { x = -3, y = 9 }, { x = -2, y = 9 }, { x = -1, y = 9 }, { x = 0, y = 9 }, { x = 1, y = 9 }, { x = 3, y = 8 }, { x = 2, y = 9 }, { x = 3, y = 9 }, { x = 5, y = 8 }, { x = 4, y = 8 } },
		[11] = { { x = -5, y = -9 }, { x = -4, y = -9 }, { x = -3, y = -10 }, { x = -1, y = -10 }, { x = -2, y = -10 }, { x = 1, y = -10 }, { x = 0, y = -10 }, { x = 3, y = -10 }, { x = 2, y = -10 }, { x = 5, y = -9 }, { x = 4, y = -9 }, { x = -7, y = -7 }, { x = -6, y = -8 }, { x = 7, y = -7 }, { x = 6, y = -8 }, { x = -9, y = -5 }, { x = -8, y = -6 }, { x = 9, y = -5 }, { x = 8, y = -6 }, { x = -9, y = -4 }, { x = -10, y = -3 }, { x = 9, y = -4 }, { x = 10, y = -3 }, { x = -10, y = -2 }, { x = -10, y = -1 }, { x = 10, y = -1 }, { x = 10, y = -2 }, { x = -10, y = 0 }, { x = -10, y = 1 }, { x = 10, y = 1 }, { x = 10, y = 0 }, { x = -10, y = 2 }, { x = -10, y = 3 }, { x = 10, y = 3 }, { x = 10, y = 2 }, { x = -9, y = 4 }, { x = -9, y = 5 }, { x = 9, y = 5 }, { x = 9, y = 4 }, { x = -8, y = 6 }, { x = -7, y = 7 }, { x = 7, y = 7 }, { x = 8, y = 6 }, { x = -6, y = 8 }, { x = -5, y = 9 }, { x = -4, y = 9 }, { x = 4, y = 9 }, { x = 5, y = 9 }, { x = 6, y = 8 }, { x = -3, y = 10 }, { x = -2, y = 10 }, { x = -1, y = 10 }, { x = 0, y = 10 }, { x = 1, y = 10 }, { x = 2, y = 10 }, { x = 3, y = 10 } },
		[12] = { { x = -3, y = -11 }, { x = -2, y = -11 }, { x = -1, y = -11 }, { x = 0, y = -11 }, { x = 1, y = -11 }, { x = 2, y = -11 }, { x = 3, y = -11 }, { x = -7, y = -9 }, { x = -6, y = -9 }, { x = -5, y = -10 }, { x = -4, y = -10 }, { x = 5, y = -10 }, { x = 4, y = -10 }, { x = 7, y = -9 }, { x = 6, y = -9 }, { x = -9, y = -7 }, { x = -7, y = -8 }, { x = -8, y = -8 }, { x = -8, y = -7 }, { x = 7, y = -8 }, { x = 8, y = -7 }, { x = 8, y = -8 }, { x = 9, y = -7 }, { x = -9, y = -6 }, { x = -10, y = -5 }, { x = 9, y = -6 }, { x = 10, y = -5 }, { x = -11, y = -3 }, { x = -10, y = -4 }, { x = 10, y = -4 }, { x = 11, y = -3 }, { x = -11, y = -2 }, { x = -11, y = -1 }, { x = 11, y = -1 }, { x = 11, y = -2 }, { x = -11, y = 0 }, { x = -11, y = 1 }, { x = 11, y = 1 }, { x = 11, y = 0 }, { x = -11, y = 2 }, { x = -11, y = 3 }, { x = 11, y = 3 }, { x = 11, y = 2 }, { x = -10, y = 5 }, { x = -10, y = 4 }, { x = 10, y = 5 }, { x = 10, y = 4 }, { x = -9, y = 7 }, { x = -9, y = 6 }, { x = -8, y = 7 }, { x = 8, y = 7 }, { x = 9, y = 7 }, { x = 9, y = 6 }, { x = -8, y = 8 }, { x = -7, y = 8 }, { x = -7, y = 9 }, { x = -6, y = 9 }, { x = 7, y = 8 }, { x = 7, y = 9 }, { x = 6, y = 9 }, { x = 8, y = 8 }, { x = -5, y = 10 }, { x = -4, y = 10 }, { x = -3, y = 11 }, { x = -2, y = 11 }, { x = -1, y = 11 }, { x = 0, y = 11 }, { x = 1, y = 11 }, { x = 2, y = 11 }, { x = 3, y = 11 }, { x = 4, y = 10 }, { x = 5, y = 10 } },
		[13] = { { x = -5, y = -11 }, { x = -4, y = -11 }, { x = -3, y = -12 }, { x = -1, y = -12 }, { x = -2, y = -12 }, { x = 1, y = -12 }, { x = 0, y = -12 }, { x = 3, y = -12 }, { x = 2, y = -12 }, { x = 4, y = -11 }, { x = 5, y = -11 }, { x = -8, y = -9 }, { x = -7, y = -10 }, { x = -6, y = -10 }, { x = 6, y = -10 }, { x = 7, y = -10 }, { x = 8, y = -9 }, { x = -10, y = -7 }, { x = -9, y = -8 }, { x = 9, y = -8 }, { x = 10, y = -7 }, { x = -11, y = -5 }, { x = -10, y = -6 }, { x = 10, y = -6 }, { x = 11, y = -5 }, { x = -11, y = -4 }, { x = -12, y = -3 }, { x = 11, y = -4 }, { x = 12, y = -3 }, { x = -12, y = -1 }, { x = -12, y = -2 }, { x = 12, y = -1 }, { x = 12, y = -2 }, { x = -12, y = 1 }, { x = -12, y = 0 }, { x = 12, y = 1 }, { x = 12, y = 0 }, { x = -12, y = 3 }, { x = -12, y = 2 }, { x = 12, y = 3 }, { x = 12, y = 2 }, { x = -11, y = 5 }, { x = -11, y = 4 }, { x = 11, y = 4 }, { x = 11, y = 5 }, { x = -10, y = 7 }, { x = -10, y = 6 }, { x = 10, y = 6 }, { x = 10, y = 7 }, { x = -9, y = 8 }, { x = -8, y = 9 }, { x = 9, y = 8 }, { x = 8, y = 9 }, { x = -7, y = 10 }, { x = -5, y = 11 }, { x = -6, y = 10 }, { x = -4, y = 11 }, { x = 5, y = 11 }, { x = 4, y = 11 }, { x = 7, y = 10 }, { x = 6, y = 10 }, { x = -3, y = 12 }, { x = -2, y = 12 }, { x = -1, y = 12 }, { x = 0, y = 12 }, { x = 1, y = 12 }, { x = 2, y = 12 }, { x = 3, y = 12 } },
		[14] = { { x = -3, y = -13 }, { x = -1, y = -13 }, { x = -2, y = -13 }, { x = 1, y = -13 }, { x = 0, y = -13 }, { x = 3, y = -13 }, { x = 2, y = -13 }, { x = -7, y = -11 }, { x = -6, y = -11 }, { x = -5, y = -12 }, { x = -6, y = -12 }, { x = -4, y = -12 }, { x = 5, y = -12 }, { x = 4, y = -12 }, { x = 7, y = -11 }, { x = 6, y = -11 }, { x = 6, y = -12 }, { x = -10, y = -9 }, { x = -9, y = -9 }, { x = -9, y = -10 }, { x = -8, y = -10 }, { x = 9, y = -9 }, { x = 9, y = -10 }, { x = 8, y = -10 }, { x = 10, y = -9 }, { x = -11, y = -7 }, { x = -10, y = -8 }, { x = 11, y = -7 }, { x = 10, y = -8 }, { x = -11, y = -6 }, { x = -12, y = -6 }, { x = -12, y = -5 }, { x = 11, y = -6 }, { x = 12, y = -6 }, { x = 12, y = -5 }, { x = -13, y = -3 }, { x = -12, y = -4 }, { x = 12, y = -4 }, { x = 13, y = -3 }, { x = -13, y = -2 }, { x = -13, y = -1 }, { x = 13, y = -1 }, { x = 13, y = -2 }, { x = -13, y = 0 }, { x = -13, y = 1 }, { x = 13, y = 1 }, { x = 13, y = 0 }, { x = -13, y = 2 }, { x = -13, y = 3 }, { x = 13, y = 3 }, { x = 13, y = 2 }, { x = -12, y = 5 }, { x = -12, y = 4 }, { x = 12, y = 5 }, { x = 12, y = 4 }, { x = -11, y = 6 }, { x = -11, y = 7 }, { x = -12, y = 6 }, { x = 11, y = 7 }, { x = 11, y = 6 }, { x = 12, y = 6 }, { x = -10, y = 8 }, { x = -10, y = 9 }, { x = -9, y = 9 }, { x = 9, y = 9 }, { x = 10, y = 9 }, { x = 10, y = 8 }, { x = -9, y = 10 }, { x = -8, y = 10 }, { x = -7, y = 11 }, { x = -6, y = 11 }, { x = 7, y = 11 }, { x = 6, y = 11 }, { x = 8, y = 10 }, { x = 9, y = 10 }, { x = -6, y = 12 }, { x = -5, y = 12 }, { x = -4, y = 12 }, { x = -3, y = 13 }, { x = -2, y = 13 }, { x = -1, y = 13 }, { x = 0, y = 13 }, { x = 1, y = 13 }, { x = 2, y = 13 }, { x = 3, y = 13 }, { x = 5, y = 12 }, { x = 4, y = 12 }, { x = 6, y = 12 } },
		[15] = { { x = -5, y = -13 }, { x = -6, y = -13 }, { x = -4, y = -13 }, { x = -3, y = -14 }, { x = -1, y = -14 }, { x = -2, y = -14 }, { x = 1, y = -14 }, { x = 0, y = -14 }, { x = 3, y = -14 }, { x = 2, y = -14 }, { x = 5, y = -13 }, { x = 4, y = -13 }, { x = 6, y = -13 }, { x = -9, y = -11 }, { x = -8, y = -11 }, { x = -8, y = -12 }, { x = -7, y = -12 }, { x = 7, y = -12 }, { x = 8, y = -12 }, { x = 8, y = -11 }, { x = 9, y = -11 }, { x = -11, y = -9 }, { x = -10, y = -10 }, { x = 10, y = -10 }, { x = 11, y = -9 }, { x = -12, y = -7 }, { x = -11, y = -8 }, { x = -12, y = -8 }, { x = 11, y = -8 }, { x = 12, y = -8 }, { x = 12, y = -7 }, { x = -13, y = -5 }, { x = -13, y = -6 }, { x = 13, y = -5 }, { x = 13, y = -6 }, { x = -13, y = -4 }, { x = -14, y = -3 }, { x = 13, y = -4 }, { x = 14, y = -3 }, { x = -14, y = -2 }, { x = -14, y = -1 }, { x = 14, y = -1 }, { x = 14, y = -2 }, { x = -14, y = 0 }, { x = -14, y = 1 }, { x = 14, y = 1 }, { x = 14, y = 0 }, { x = -14, y = 2 }, { x = -14, y = 3 }, { x = 14, y = 3 }, { x = 14, y = 2 }, { x = -13, y = 4 }, { x = -13, y = 5 }, { x = 13, y = 5 }, { x = 13, y = 4 }, { x = -13, y = 6 }, { x = -12, y = 7 }, { x = 12, y = 7 }, { x = 13, y = 6 }, { x = -11, y = 9 }, { x = -11, y = 8 }, { x = -12, y = 8 }, { x = 11, y = 8 }, { x = 11, y = 9 }, { x = 12, y = 8 }, { x = -9, y = 11 }, { x = -10, y = 10 }, { x = -8, y = 11 }, { x = 9, y = 11 }, { x = 8, y = 11 }, { x = 10, y = 10 }, { x = -7, y = 12 }, { x = -8, y = 12 }, { x = -6, y = 13 }, { x = -5, y = 13 }, { x = -4, y = 13 }, { x = 5, y = 13 }, { x = 4, y = 13 }, { x = 7, y = 12 }, { x = 6, y = 13 }, { x = 8, y = 12 }, { x = -3, y = 14 }, { x = -2, y = 14 }, { x = -1, y = 14 }, { x = 0, y = 14 }, { x = 1, y = 14 }, { x = 2, y = 14 }, { x = 3, y = 14 } },
		[16] = { { x = -3, y = -15 }, { x = -1, y = -15 }, { x = -2, y = -15 }, { x = 1, y = -15 }, { x = 0, y = -15 }, { x = 3, y = -15 }, { x = 2, y = -15 }, { x = -7, y = -13 }, { x = -8, y = -13 }, { x = -5, y = -14 }, { x = -6, y = -14 }, { x = -4, y = -14 }, { x = 5, y = -14 }, { x = 4, y = -14 }, { x = 7, y = -13 }, { x = 6, y = -14 }, { x = 8, y = -13 }, { x = -9, y = -12 }, { x = -10, y = -11 }, { x = 9, y = -12 }, { x = 10, y = -11 }, { x = -11, y = -10 }, { x = -12, y = -9 }, { x = 11, y = -10 }, { x = 12, y = -9 }, { x = -13, y = -7 }, { x = -13, y = -8 }, { x = 13, y = -7 }, { x = 13, y = -8 }, { x = -14, y = -6 }, { x = -14, y = -5 }, { x = 14, y = -5 }, { x = 14, y = -6 }, { x = -15, y = -3 }, { x = -14, y = -4 }, { x = 15, y = -3 }, { x = 14, y = -4 }, { x = -15, y = -2 }, { x = -15, y = -1 }, { x = 15, y = -1 }, { x = 15, y = -2 }, { x = -15, y = 0 }, { x = -15, y = 1 }, { x = 15, y = 1 }, { x = 15, y = 0 }, { x = -15, y = 2 }, { x = -15, y = 3 }, { x = 15, y = 3 }, { x = 15, y = 2 }, { x = -14, y = 5 }, { x = -14, y = 4 }, { x = 14, y = 5 }, { x = 14, y = 4 }, { x = -13, y = 7 }, { x = -14, y = 6 }, { x = 13, y = 7 }, { x = 14, y = 6 }, { x = -13, y = 8 }, { x = -12, y = 9 }, { x = 12, y = 9 }, { x = 13, y = 8 }, { x = -11, y = 10 }, { x = -10, y = 11 }, { x = 10, y = 11 }, { x = 11, y = 10 }, { x = -9, y = 12 }, { x = -8, y = 13 }, { x = -7, y = 13 }, { x = 7, y = 13 }, { x = 8, y = 13 }, { x = 9, y = 12 }, { x = -6, y = 14 }, { x = -5, y = 14 }, { x = -4, y = 14 }, { x = -3, y = 15 }, { x = -2, y = 15 }, { x = -1, y = 15 }, { x = 0, y = 15 }, { x = 1, y = 15 }, { x = 2, y = 15 }, { x = 3, y = 15 }, { x = 4, y = 14 }, { x = 5, y = 14 }, { x = 6, y = 14 } }
	}

	for current_radius = 1, 16, 1 do

		ffatable.fluid_explosion_schedule[#ffatable.fluid_explosion_schedule][current_radius] = {}
		ffatable.fluid_explosion_schedule[#ffatable.fluid_explosion_schedule][current_radius].trigger_tick = game.tick + (current_radius * 8)

		local circle_coords = circle_coordinates[current_radius]
		circle_coords = shuffle(circle_coords)

		for index, tile_position in pairs(circle_coords) do
			local pos = { x = center_position.x + tile_position.x, y = center_position.y + tile_position.y }
			ffatable.fluid_explosion_schedule[#ffatable.fluid_explosion_schedule][current_radius][index] = { x = pos.x, y = pos.y }
		end

	end
	entity.die("player")
end

local function on_entity_damaged(event)
	local entity = event.entity
	if not entity.valid then return end
	if not entity.health then return end
	if not container_types[entity.type] then return end
	if not entity.fluidbox[1] then return end
	if not fluid_damages[entity.fluidbox[1].name] then return end
	if entity.health > entity.prototype.max_health * 0.75 then return end

	if math.random(1, 3) == 1 or entity.health <= 0 then
		create_explosion_schedule(entity)
		return
	end
end

local function on_tick(event)
	local ffatable = Table.get_table()
	local tick = event.tick
	if ffatable.fluid_explosion_schedule then
		local explosion_schedule_is_alive = false
		for explosion_index = 1, #ffatable.fluid_explosion_schedule, 1 do
			if #ffatable.fluid_explosion_schedule[explosion_index] > 0 then
				explosion_schedule_is_alive = true
				for radius = 1, #ffatable.fluid_explosion_schedule[explosion_index], 1 do
					if ffatable.fluid_explosion_schedule[explosion_index][radius].trigger_tick == tick then
						for tile_index = 1, #ffatable.fluid_explosion_schedule[explosion_index][radius], 1 do
							local continue_explosion = process_explosion_tile(ffatable.fluid_explosion_schedule[explosion_index][radius][tile_index], explosion_index, radius)
							if not continue_explosion then
								ffatable.fluid_explosion_schedule[explosion_index] = {}
								break
							end
						end
						if radius == #ffatable.fluid_explosion_schedule[explosion_index] then ffatable.fluid_explosion_schedule[explosion_index] = {} end
						break
					end
				end
			end
		end
		if not explosion_schedule_is_alive then ffatable.fluid_explosion_schedule = nil end
	end
end

local on_init = function ()
	local ffatable = Table.get_table()
	ffatable.fluid_explosion_schedule = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_tick, on_tick)

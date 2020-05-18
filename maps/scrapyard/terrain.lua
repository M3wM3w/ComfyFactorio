local Biters = require 'modules.wave_defense.biter_rolls'
local WD = require "modules.wave_defense.table"
local Event = require 'utils.event'
local Market = require 'functions.basic_markets'
local create_entity_chain = require "functions.create_entity_chain"
local create_tile_chain = require "functions.create_tile_chain"
local noise_v1 = require 'utils.simplex_noise'.d2
local map_functions = require "tools.map_functions"
local Scrap_table = require "maps.scrapyard.table"
local shapes = require "tools.shapes"
local Loot = require 'maps.scrapyard.loot'

local Public = {}

local insert = table.insert
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local uncover_radius = 10
Public.level_depth = 960
local worm_level_modifier = 0.18

local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local scrap_buildings = {"nuclear-reactor", "centrifuge", "beacon", "chemical-plant", "assembling-machine-1", "assembling-machine-2", "assembling-machine-3",  "oil-refinery", "arithmetic-combinator", "constant-combinator", "decider-combinator", "programmable-speaker", "steam-turbine", "steam-engine", "chemical-plant", "assembling-machine-1", "assembling-machine-2", "assembling-machine-3",  "oil-refinery", "arithmetic-combinator", "constant-combinator", "decider-combinator", "programmable-speaker", "steam-turbine", "steam-engine"}
local spawner_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}
local trees = {"dead-grey-trunk", "dead-grey-trunk", "dry-tree"}
local colors = {"black", "orange", "red", "yellow"}
local more_colors = {"black-refined-concrete", "brown-refined-concrete", "red-refined-concrete", "blue-refined-concrete"}

local noises = {
	["no_rocks"] = {{modifier = 0.0044, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["no_rocks_2"] = {{modifier = 0.013, weight = 1}, {modifier = 0.1, weight = 0.1}},
	["large_caves"] = {{modifier = 0.0044, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["small_caves"] = {{modifier = 0.008, weight = 1}, {modifier = 0.03, weight = 0.15}, {modifier = 0.25, weight = 0.05}},
	["small_caves_2"] = {{modifier = 0.009, weight = 1}, {modifier = 0.05, weight = 0.25}, {modifier = 0.25, weight = 0.05}},
	["cave_worms"] = {{modifier = 0.001, weight = 1}, {modifier = 0.1, weight = 0.06}},
	["cave_ponds"] = {{modifier = 0.01, weight = 1}, {modifier = 0.1, weight = 0.06}},
	["cave_rivers"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_2"] = {{modifier = 0.003, weight = 1}, {modifier = 0.01, weight = 0.21}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_3"] = {{modifier = 0.002, weight = 1}, {modifier = 0.01, weight = 0.15}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_4"] = {{modifier = 0.001, weight = 1}, {modifier = 0.01, weight = 0.11}, {modifier = 0.05, weight = 0.01}},
	["scrapyard"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.35}, {modifier = 0.05, weight = 0.23}, {modifier = 0.1, weight = 0.11}},
}



local function get_noise(name, pos, seed)
	local noise = 0
	local d = 0
	for _, n in pairs(noises[name]) do
		noise = noise + noise_v1(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		d = d + n.weight
		seed = seed + 10000
	end
	noise = noise / d
	return noise
end

local function place_random_scrap_entity(surface, position)
	local r = math_random(1, 100)
	if r < 15 then
		local e = surface.create_entity({name = scrap_buildings[math_random(1, #scrap_buildings)], position = position, force = "scrap"})
		if e.name == "nuclear-reactor" then
			create_entity_chain(surface, {name = "heat-pipe", position = position, force = "player"}, math_random(16,32), 25)
		end
		if e.name == "chemical-plant" or e.name == "steam-turbine" or e.name == "steam-engine" or e.name == "oil-refinery" then
			create_entity_chain(surface, {name = "pipe", position = position, force = "player"}, math_random(8,16), 25)
		end
		e.active = false
		return
	end
	if r < 75 then
		local e = surface.create_entity({name = "gun-turret", position = position, force = "scrap_defense"})
		if math_abs(position.y) < Public.level_depth * 2.5 then
			e.insert({name = "piercing-rounds-magazine", count = math_random(64, 128)})
		else
			e.insert({name = "uranium-rounds-magazine", count = math_random(64, 128)})
		end
		return
	end

	local e = surface.create_entity({name = "storage-tank", position = position, force = "scrap", direction = math_random(0, 3)})
	local fluids = {"crude-oil", "lubricant", "heavy-oil", "light-oil", "petroleum-gas", "sulfuric-acid", "water"}
	e.fluidbox[1] = {name = fluids[math_random(1, #fluids)], amount = math_random(15000, 25000)}
	create_entity_chain(surface, {name = "pipe", position = position, force = "player"}, math_random(6,8), 1)
	create_entity_chain(surface, {name = "pipe", position = position, force = "player"}, math_random(6,8), 1)
	create_entity_chain(surface, {name = "pipe", position = position, force = "player"}, math_random(15,30), 80)
end

local function create_inner_content(surface, pos, noise)
	if math_random(1, 90000) == 1 then
		if noise < 0.3 or noise > -0.3 then
			map_functions.draw_noise_entity_ring(surface, pos, "laser-turret", "scrap_defense", 0, 2)
			map_functions.draw_noise_entity_ring(surface, pos, "accumulator", "scrap_defense", 2, 3)
			map_functions.draw_noise_entity_ring(surface, pos, "substation", "scrap_defense", 3, 4)
			map_functions.draw_noise_entity_ring(surface, pos, "solar-panel", "scrap_defense", 4, 6)
			map_functions.draw_noise_entity_ring(surface, pos, "stone-wall", "scrap_defense", 6, 7)

			create_tile_chain(surface, {name = "concrete", position = pos}, math_random(16, 32), 50)
			create_tile_chain(surface, {name = "concrete", position = pos}, math_random(16, 32), 50)
			create_tile_chain(surface, {name = "stone-path", position = pos}, math_random(16, 32), 50)
			create_tile_chain(surface, {name = "stone-path", position = pos}, math_random(16, 32), 50)
		end
		return
	end
end

local function get_oil_amount(p)
	return (math_abs(p.y) * 200 + 10000) * math_random(75, 125) * 0.01
end

local function wall(surface, left_top, seed)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			local small_caves = get_noise("small_caves", p, seed)
			local cave_ponds = get_noise("cave_rivers", p, seed + 100000)
			if y > 9 + cave_ponds * 6 and y < 23 + small_caves * 6 then
				if small_caves > 0.05 or cave_ponds > 0.05 then
					surface.set_tiles({{name = "deepwater-green", position = p}})
					if math_random(1,48) == 1 then surface.create_entity({name = "fish", position = p}) end
				else
					surface.set_tiles({{name = "dirt-7", position = p}})
					if math_random(1, 5) ~= 1 then
						surface.create_entity({name = "mineable-wreckage", position = p})
					end
				end
			else
				surface.set_tiles({{name = "dirt-7", position = p}})

				if surface.can_place_entity({name = "stone-wall", position = p, force = "enemy"}) then
					if math_random(1,512) == 1 and y > 3 and y < 28 then
						if math_random(1, 2) == 1 then
							Loot.add(surface, p, "wooden-chest")
						else
							Loot.add(surface, p, "steel-chest")
						end
					else

						if y < 5 or y > 26 then
							if y <= 15 then
								if math_random(1, y + 1) == 1 then
									local e = surface.create_entity({name = "stone-wall", position = p, force = "enemy"})
									e.minable = false
								end
							else
								if math_random(1, 32 - y)  == 1 then
									local e = surface.create_entity({name = "stone-wall", position = p, force = "enemy"})
									e.minable = false
								end
							end
						end

					end
				end

				if math_random(1,512) == 1 then
					place_random_scrap_entity(surface, p)
				end

				if math_random(1, 16) == 1 then
					if surface.can_place_entity({name = "small-worm-turret", position = p, force = "enemy"}) then
						Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
						surface.create_entity({name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"})
					end
				end

				if math_random(1, 32) == 1 then
					if surface.can_place_entity({name = "gun-turret", position = p, force = "enemy"}) then
						local e = surface.create_entity({name = "gun-turret", position = p, force = "enemy"})
						if math_abs(p.y) < Public.level_depth * 2.5 then
							e.insert({name = "piercing-rounds-magazine", count = math_random(64, 128)})
						else
							e.insert({name = "uranium-rounds-magazine", count = math_random(64, 128)})
						end
					end
				end
			end
		end
	end
end

local function process_level_6_position(surface, p, seed, tiles, entities, fishes, r_area, markets, treasure)
	local large_caves = get_noise("large_caves", p, seed)
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)

	if large_caves > -0.14 and large_caves < 0.14 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
		if math_random(1,768) == 1 then treasure[#treasure + 1] = p end
		if math_random(1,3) > 1 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
		return
	end

	if large_caves < -0.47 or large_caves > 0.47 then
		insert(r_area, {x = p.x, y = p.y})
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		if math_random(1,128) == 1 then
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			create_inner_content(surface, p, noise_cave_ponds)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
		return
	end

	if large_caves > -0.30 and large_caves < 0.30 then
		if noise_cave_ponds > 0.35 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_random(1, 4), position = p}
			--tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
			if math_random(1,256) == 1 then treasure[#treasure + 1] = p end
			if math_random(1,256) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
			return
		end
		if noise_cave_ponds > 0.25 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
			--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			if math_random(1,2) > 1 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
			return
		end
	end
end

local function process_level_5_position(surface, p, seed, tiles, entities, fishes, r_area, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed)
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)

	if small_caves > -0.14 and small_caves < 0.14 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
		if math_random(1,768) == 1 then treasure[#treasure + 1] = p end
		if math_random(1,3) > 1 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
		return
	end

	if small_caves < -0.50 or small_caves > 0.50 then
		insert(r_area, {x = p.x, y = p.y})
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		if math_random(1,128) == 1 then
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			create_inner_content(surface, p, noise_cave_ponds)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
		return
	end

	if small_caves > -0.30 and small_caves < 0.30 then
		if noise_cave_ponds > 0.35 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_random(1, 4), position = p}
			--tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
			if math_random(1,256) == 1 then treasure[#treasure + 1] = p end
			if math_random(1,256) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
			return
		end
		if noise_cave_ponds > 0.25 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
			--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			if math_random(1,2) > 1 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
			return
		end
	end
end

local function process_level_4_position(surface, p, seed, tiles, entities, fishes, r_area, markets, treasure)
	local noise_large_caves = get_noise("large_caves", p, seed)
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)

	if math_abs(noise_large_caves) > 0.7 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end
	if math_abs(noise_large_caves) > 0.6 then
		insert(r_area, {x = p.x, y = p.y})
		if math_random(1,16) == 1 then entities[#entities + 1] = {name=trees[math_random(1, #trees)], position=p} end
		if math_random(1,32) == 1 then markets[#markets + 1] = p end
	end
	if math_abs(noise_large_caves) > 0.5 then
		insert(r_area, {x = p.x, y = p.y})
		tiles[#tiles + 1] = {name = "grass-2", position = p}
		if math_random(1,620) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
		if math_random(1,384) == 1 then
			create_inner_content(surface, p, noise_cave_ponds)
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
		if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end
	if math_abs(noise_large_caves) > 0.475 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
		if math_random(1,3) > 1 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		return
	end

	--Chasms
	if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
		if small_caves > 0.45 then
			tiles[#tiles + 1] = {name = "water-shallow", position = p}
			return
		end
		if small_caves < -0.45 then
			tiles[#tiles + 1] = {name = "water-shallow", position = p}
			return
		end
	end

	if small_caves > -0.15 and small_caves < 0.15 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		--tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
		if math_random(1,5) > 1 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
		if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end

	if noise_large_caves > -0.1 and noise_large_caves < 0.1 then

		--Main Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
			tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return
		end

		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
		if math_random(1,100) > 30 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
		return
	end
end

local function process_level_3_position(surface, p, seed, tiles, entities, fishes, r_area, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed + 50000)
	local small_caves_2 = get_noise("small_caves_2", p, seed + 70000)
	local noise_large_caves = get_noise("large_caves", p, seed + 60000)
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)

	--Market Spots
	if noise_cave_ponds < -0.77 then
		if noise_cave_ponds > -0.79 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
			--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
			entities[#entities + 1] = {name = "mineable-wreckage", position = p}
		else
			tiles[#tiles + 1] = {name = "grass-" .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
			if math_random(1,32) == 1 then markets[#markets + 1] = p end
			if math_random(1,16) == 1 then entities[#entities + 1] = {name = trees[math_random(1, #trees)], position=p} end
		end
		return
	end

	if noise_large_caves > -0.2 and noise_large_caves < 0.2 or small_caves_2 > 0 then
		--Green Water Ponds
		if noise_cave_ponds > 0.80 then
			tiles[#tiles + 1] = {name = "deepwater-green", position = p}
			if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
			return
		end

		--Chasms
		if noise_cave_ponds < 0.12 and noise_cave_ponds > -0.12 then
			if small_caves > 0.55 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				return
			end
			if small_caves < -0.55 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				return
			end
		end

		--Rivers
		local cave_rivers = get_noise("cave_rivers", p, seed + 100000)
		if cave_rivers < 0.014 and cave_rivers > -0.014 then
			if noise_cave_ponds > 0.2 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
				return
			end
		end
		local cave_rivers_2 = get_noise("cave_rivers_2", p, seed)
		if cave_rivers_2 < 0.024 and cave_rivers_2 > -0.024 then
			if noise_cave_ponds < 0.5 then
				tiles[#tiles + 1] = {name = "deepwater-green", position = p}
				if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
				return
			end
		end

		if noise_cave_ponds > 0.775 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_random(4, 6), position = p}
			--tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
			return
		end

		local no_rocks = get_noise("no_rocks", p, seed + 25000)
		--Worm oil Zones
		if no_rocks < 0.15 and no_rocks > -0.15 then
			if small_caves > 0.35 then
				insert(r_area, {x = p.x, y = p.y})
				--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
				tiles[#tiles + 1] = {name = "dirt-" .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
				if math_random(1,320) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
				if math_random(1,50) == 1 then
					Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
					create_inner_content(surface, p, noise_cave_ponds)
					entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
				end
				if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
				if math_random(1,64) == 1 then entities[#entities + 1] = {name = trees[math_random(1, #trees)], position=p} end
				return
			end
		end

		--Main Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
			--tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return 
		end

		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
		if math_random(1,2048) == 1 then place_random_scrap_entity(surface, p) end
		if math_random(1,100) > 30 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
		return
	end

end

local function process_level_2_position(surface, p, seed, tiles, entities, fishes, r_area, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed)
	local noise_large_caves = get_noise("large_caves", p, seed)

	if noise_large_caves > -0.75 and noise_large_caves < 0.75 then

		local noise_cave_ponds = get_noise("cave_ponds", p, seed)

		--Chasms
		if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
			if small_caves > 0.32 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				return
			end
			if small_caves < -0.32 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				return
			end
		end

		--Green Water Ponds
		if noise_cave_ponds > 0.80 then
			tiles[#tiles + 1] = {name = "deepwater-green", position = p}
			if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
			return
		end

		--Rivers
		local cave_rivers = get_noise("cave_rivers", p, seed + 100000)
		if cave_rivers < 0.027 and cave_rivers > -0.027 then
			if noise_cave_ponds < 0.1 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
				return
			end
		end

		if noise_cave_ponds > 0.76 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_random(4, 6), position = p}
			--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
			return
		end

		--Market Spots
		if noise_cave_ponds < -0.80 then
			insert(r_area, {x = p.x, y = p.y})
			create_inner_content(surface, p, noise_cave_ponds)
			tiles[#tiles + 1] = {name = "grass-" .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
			if math_random(1,32) == 1 then markets[#markets + 1] = p end
			if math_random(1,16) == 1 then entities[#entities + 1] = {name = trees[math_random(1, #trees)], position=p} end
			return
		end

		local no_rocks = get_noise("no_rocks", p, seed + 25000)
		--Worm oil Zones
		if no_rocks < 0.15 and no_rocks > -0.15 then
			if small_caves > 0.35 then
				insert(r_area, {x = p.x, y = p.y})
				tiles[#tiles + 1] = {name = "dirt-" .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
				--tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
				if math_random(1,450) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
				if math_random(1,64) == 1 then
					Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
					entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
				end
				if math_random(1,64) == 1 then entities[#entities + 1] = {name = trees[math_random(1, #trees)], position=p} end
				return
			end
		end


		--Main Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
			--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return
		end

		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
	if math_random(1,2048) == 1 then place_random_scrap_entity(surface, p) end
		if math_random(1,100) > 30 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
		return
	end

end

local function process_level_1_position(surface, p, seed, tiles, entities, fishes, r_area, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed)

	local noise_cave_ponds = get_noise("cave_ponds", p, seed)

	local cave_worms = get_noise("cave_worms", p, seed)

	if cave_worms < 0.12 and cave_worms > -0.12 then
		if small_caves > 0.55 then
			tiles[#tiles + 1] = {name = "water-shallow", position = p}
			return
		end
		if small_caves < -0.55 then
			tiles[#tiles + 1] = {name = "water-shallow", position = p}
			return
		end
	end
	--Green Water Ponds
	if noise_cave_ponds > 0.80 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end
	--Rivers
	local cave_rivers = get_noise("cave_rivers", p, seed + 100000)
	if cave_rivers < 0.024 and cave_rivers > -0.024 then
		if noise_cave_ponds > 0 then
			tiles[#tiles + 1] = {name = "water-shallow", position = p}
			if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
			return
		end
	end

	if noise_cave_ponds > 0.76 then
		--tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
		tiles[#tiles + 1] = {name = "dirt-" .. math_random(4, 6), position = p}
		return
	end

	--Market Spots
	if noise_cave_ponds < -0.75 then
		insert(r_area, {x = p.x, y = p.y})
		tiles[#tiles + 1] = {name = "grass-" .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
		if math_random(1,32) == 1 then markets[#markets + 1] = p end
		if math_random(1,32) == 1 then entities[#entities + 1] = {name = trees[math_random(1, #trees)], position=p} end
		create_inner_content(surface, p, noise_cave_ponds)
		return
	end

	local no_rocks = get_noise("no_rocks", p, seed + 25000)
	--Worm oil Zones
	if p.y < -64 + noise_cave_ponds * 10 then
		if no_rocks < 0.08 and no_rocks > -0.08 then
			if small_caves > 0.35 then
				insert(r_area, {x = p.x, y = p.y})
				--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
				tiles[#tiles + 1] = {name = "dirt-" .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
				if math_random(1,450) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
				if math_random(1,96) == 1 then
					Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
					entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
				end
				if math_random(1,1024) == 1 then treasure[#treasure + 1] = p end
				if math_random(1,64) == 1 then entities[#entities + 1] = {name = trees[math_random(1, #trees)], position=p} end
				return
			end
		end
	end

	--Main Terrain
	local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
	if no_rocks_2 > 0.70 or no_rocks_2 < -0.70 then
		--tiles[#tiles + 1] = {name = more_colors[math_random(1, #more_colors)].. "-refined-concrete", position = p}
		tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
		if math_random(1,32) == 1 then entities[#entities + 1] = {name = trees[math_random(1, #trees)], position=p} end
		if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
		return
	end

	if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
	--tiles[#tiles + 1] = {name = colors[math_random(1, #colors)].. "-refined-concrete", position = p}
	tiles[#tiles + 1] = {name = "dirt-7", position = p}
	if math_random(1,4028) == 1 then place_random_scrap_entity(surface, p) end
	if math_random(1,100) > 30 then entities[#entities + 1] = {name = "mineable-wreckage", position = p} end
end

Public.levels = {
	process_level_1_position,
	process_level_2_position,
	process_level_3_position,
	process_level_4_position,
	process_level_5_position,
	--process_level_6_position,
	--process_level_7_position,
	--process_level_8_position,
	--process_level_9_position,
	--process_level_10_position,
}

function Public.reveal_area(x, y, surface, max_radius)
	local this = Scrap_table.get_table()
	local wave_defense_table = WD.get_table()
	local seed = game.surfaces[this.active_surface_index].map_gen_settings.seed
	local circles = shapes.circles
	local r_area = {}
	local tiles = {}
	local fishes = {}
	local entities = {}
	local markets = {}
	local treasure = {}
	local process_level = Public.levels[math_floor(math_abs(y) / Public.level_depth) + 1]
	if not process_level then process_level = Public.levels[#Public.levels] end
	for r = 1, max_radius, 1 do
		for _, v in pairs(circles[r]) do
			local pos = {x = x + v.x, y = y + v.y}
			if not surface.get_tile(pos) then return end
			local t_name = surface.get_tile(pos).name == "out-of-map"
			if t_name then
				process_level(surface, pos, seed, tiles, entities, fishes, r_area, markets, treasure)
			end
		end
	end
	if #tiles > 0 then
		surface.set_tiles(tiles, true)
	end
	for _, entity in pairs(entities) do
		if surface.can_place_entity(entity) and entity == "biter-spawner" or entity == "spitter-spawner" then
			surface.create_entity(entity)
		else
			surface.create_entity(entity)
		end
	end
	if #markets > 0 then
		local pos = markets[math_random(1, #markets)]
		if surface.count_entities_filtered{area = {{pos.x - 96, pos.y - 96}, {pos.x + 96, pos.y + 96}}, name = "market", limit = 1} == 0 then
			local market = Market.mountain_market(surface, pos, math_abs(pos.y) * 0.004)
			market.destructible = false
		end
	end
	for _, p in pairs(treasure) do
		local name = "steel-chest"
		Loot.add(surface, p, name)
		if math_random(1,wave_defense_table.math) == 1 then
			local distance_to_center = math.sqrt(p.x^2 + p.y^2)
			local size = 7 + math.floor(distance_to_center * 0.0075)
			if size > 20 then size = 20 end
			local amount = 500 + distance_to_center * 2
			map_functions.draw_rainbow_patch_v2(p, surface, size, amount)
		end
	end
	for _, fish in pairs(fishes) do
		surface.create_entity({name = "fish", position = fish})
	end
end


function Public.reveal(player)
	local this = Scrap_table.get_table()
	local seed = game.surfaces[this.active_surface_index].map_gen_settings.seed
	local position = player.position
	local surface = player.surface
	local circles = shapes.circles
	local r_area = {}
	local tiles = {}
	local fishes = {}
	local entities = {}
	local markets = {}
	local treasure = {}
	local process_level = Public.levels[math_floor(math_abs(position.y) / Public.level_depth) + 1]
	if not process_level then process_level = Public.levels[#Public.levels] end
	for r = 1, uncover_radius, 1 do
		for _, v in pairs(circles[r]) do
			local pos = {x = position.x + v.x, y = position.y + v.y}
			local t_name = surface.get_tile(pos).name == "out-of-map"
			if t_name then
				process_level(surface, pos, seed, tiles, entities, fishes, r_area, markets, treasure)
			end
		end
	end
	if #tiles > 0 then
		surface.set_tiles(tiles, true)
	end
	for _, entity in pairs(entities) do
		if surface.can_place_entity(entity) and entity == "biter-spawner" or entity == "spitter-spawner" then
			surface.create_entity(entity)
		else
			surface.create_entity(entity)
		end
	end
	for _, pos in pairs(r_area) do
		local x = pos.x
		local y = pos.y
		Public.reveal_area(x, y, surface, 12)
	end
	if #markets > 0 then
		local pos = markets[math_random(1, #markets)]
		if surface.count_entities_filtered{area = {{pos.x - 96, pos.y - 96}, {pos.x + 96, pos.y + 96}}, name = "market", limit = 1} == 0 then
			local market = Market.mountain_market(surface, pos, math_abs(pos.y) * 0.004)
			market.destructible = false
		end
	end
	for _, p in pairs(treasure) do
		local name = "steel-chest"
		Loot.add(surface, p, name)
	end
	for _, fish in pairs(fishes) do
		surface.create_entity({name = "fish", position = fish})
	end
end

local function generate_spawn_area(surface, position_left_top)
	if position_left_top.y < -0 then return end
	if position_left_top.y > 10 then return end
	local tiles = {}
	local circles = shapes.circles

	for r = 1, 12 do
		for k, v in pairs(circles[r]) do
			local pos = {x = position_left_top.x + v.x, y = position_left_top.y+20 + v.y}
			if pos.x > -15 and pos.x < 15 and pos.y < 40 then
				insert(tiles, {name = more_colors[math_random(1, #more_colors)], position = pos})
			end
			if pos.x > -30 and pos.x < 30 and pos.y < 40 then
				insert(tiles, {name = more_colors[math_random(1, #more_colors)], position = pos})
			end
			if pos.x > -60 and pos.x < 60 and pos.y < 40 then
				insert(tiles, {name = more_colors[math_random(1, #more_colors)], position = pos})
			end
			if pos.x > -90 and pos.x < 90 and pos.y < 40 then
				insert(tiles, {name = more_colors[math_random(1, #more_colors)], position = pos})
			end
			if pos.x > -120 and pos.x < 120 and pos.y < 40 then
				insert(tiles, {name = more_colors[math_random(1, #more_colors)], position = pos})
			end
			if pos.x > -150 and pos.x < 150 and pos.y < 40 then
				insert(tiles, {name = more_colors[math_random(1, #more_colors)], position = pos})
			end
			if pos.x > -180 and pos.x < 180 and pos.y < 40 then
				insert(tiles, {name = more_colors[math_random(1, #more_colors)], position = pos})
			end
			--if t_insert then
			--	insert(tiles, {name = t_insert, position = pos})
			--end
		end
	end
	surface.set_tiles(tiles, true)
end

local function is_out_of_map(p)
	if p.x < 196 and p.x >= -196 then return end
	if p.y * 0.5 >= math_abs(p.x) then return end
	if p.y * -0.5 > math_abs(p.x) then return end
	return true
end

local function border_chunk(surface, left_top)
	for x = 0, 31, 1 do
		for y = 5, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1, math.ceil(pos.y + pos.y) + 64) == 1 then
				surface.create_entity({name = trees[math_random(1, #trees)], position = pos})
			end
		end
	end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if not is_out_of_map(pos) then
				if math_random(1, pos.y + 23) == 1 then
					surface.create_entity{
					name = "gun-turret-remnants", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))
					}
				end
				if math_random(1, pos.y + 2) == 1 then
					surface.create_decoratives{
					check_collision=false,
					decoratives={
							{name = "rock-small", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
						}
					}
				end
				if math_random(1, pos.y + 2) == 1 then
					surface.create_decoratives{
					check_collision=false,
					decoratives={
							{name = "rock-tiny", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
						}
					}
				end
				if math_random(1, pos.y + 22) == 1 then
					surface.create_entity{
					name = "wall-remnants", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))
					}
				end
				if math_random(1, math.ceil(pos.y + pos.y) + 32) == 1 then
					surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})
				end
			end
		end
	end

	for _, e in pairs(surface.find_entities_filtered({area = {{left_top.x, left_top.y},{left_top.x + 32, left_top.y + 32}}, type = "cliff"})) do	e.destroy() end
end

local function replace_water(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if surface.get_tile(p).collides_with("resource-layer") then
				surface.set_tiles({{name = "dirt-" .. math_random(1,5), position = p}}, true)
			end
		end
	end
end

local function process(surface, left_top)
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = "out-of-map"
			local pos = {x = left_top.x + x, y = left_top.y + y}
				insert(tiles, {name = tile_to_insert, position = pos})
		end
	end
	surface.set_tiles(tiles, true)
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	surface.regenerate_decorative(decorative_names, {left_top})
end

local function out_of_map_area(event)
	local surface = event.surface
	local left_top = event.area.left_top
	for x = -1, 32, 1 do
		for y = -1, 32, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if is_out_of_map(p) then
				surface.set_tiles({{name = "out-of-map", position = p}}, true)
			end
		end
	end
end

local function biter_chunk(surface, left_top)
	local tile_positions = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			tile_positions[#tile_positions + 1] = p
		end
	end

	for i = 1, 1, 1 do
		local position = surface.find_non_colliding_position("biter-spawner", tile_positions[math_random(1, #tile_positions)], 16, 2)
		if position then
			local e = surface.create_entity({name = spawner_raffle[math_random(1, #spawner_raffle)], position = position, force = "enemy"})
			e.destructible = false
			e.active = false
		end
	end

	for i = 1, 3, 1 do
		local position = surface.find_non_colliding_position("big-worm-turret", tile_positions[math_random(1, #tile_positions)], 16, 2)
		if position then
			local e = surface.create_entity({name = "big-worm-turret", position = position, force = "enemy"})
			e.destructible = false
		end
	end
end

local function out_of_map(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x = left_top.x + x, y = left_top.y + y}}})
		end
	end
end

local function on_chunk_generated(event)
	local this = Scrap_table.get_table()
	if string.sub(event.surface.name, 0, 9) ~= "scrapyard" then return end
	local surface = event.surface
	local left_top = event.area.left_top
	if left_top.x >= Public.level_depth * 0.5 then out_of_map(surface, left_top) return end
	if left_top.x < Public.level_depth * -0.5 then out_of_map(surface, left_top) return end
	if surface.name ~= event.surface.name then return end

	if this.revealed_spawn > game.tick then
		for i = 80, -80, -10 do
			Public.reveal_area(0, i, surface, 4)
			Public.reveal_area(0, i, surface, 4)
			Public.reveal_area(0, i, surface, 4)
			Public.reveal_area(0, i, surface, 4)
		end

		for v = 80, -80, -10 do
			Public.reveal_area(v, 0, surface, 4)
			Public.reveal_area(v, 0, surface, 4)
			Public.reveal_area(v, 0, surface, 4)
			Public.reveal_area(v, 0, surface, 4)
		end
	end

	if left_top.y % Public.level_depth == 0 and left_top.y < 0 and left_top.y > Public.level_depth * -10 then
		this.left_top = event.area.left_top
		wall(surface, left_top, surface.map_gen_settings.seed)
		return
	end

	if left_top.y > 268 then out_of_map(surface, left_top) return end
	if left_top.y >= 0 then replace_water(surface, left_top) end
	if left_top.y > 210 then biter_chunk(surface, left_top) end
	if left_top.y >= 10 then border_chunk(surface, left_top) end
	if left_top.y < 0 then process(surface, left_top) end
	out_of_map_area(event)
	generate_spawn_area(surface, left_top)
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public
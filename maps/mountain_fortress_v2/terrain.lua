local Biters = require 'modules.wave_defense.biter_rolls'
local Treasure = require 'maps.mountain_fortress_v2.treasure'
local Market = require 'functions.basic_markets'
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local simplex_noise = require "utils.simplex_noise".d2
local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local size_of_rock_raffle = #rock_raffle
local spawner_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}
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
}
local level_depth = 704
local worm_level_modifier = 0.18

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

local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then return tile.name end
		end
	end
	return "grass-1"
end

local function get_oil_amount(p)
	return (math_abs(p.y) * 200 + 10000) * math_random(75, 125) * 0.01
end

local function process_level_11_position(p, seed, tiles, entities, markets, treasure)
	local noise_1 = get_noise("small_caves", p, seed)
	local noise_2 = get_noise("no_rocks_2", p, seed + 10000)

	if noise_1 > 0.7 then
		tiles[#tiles + 1] = {name = "water", position = p}
		if math_random(1,48) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	if noise_1 < -0.72 then
		tiles[#tiles + 1] = {name = "lab-dark-1", position = p}
		entities[#entities + 1] = {name = "uranium-ore", position = p, amount = math_abs(p.y) + 1 * 3}
		return
	end

	if noise_1 > -0.30 and noise_1 < 0.30 then
		if noise_1 > -0.14 and noise_1 < 0.14 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
			if math_random(1,2) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
			if math_random(1,256) == 1 then treasure[#treasure + 1] = p end
		else
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
		end
		return
	end

	if math_random(1,64) == 1 and noise_2 > 0.65 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
	if math_random(1,8192) == 1 then markets[#markets + 1] = p end
	if math_random(1,1024) == 1 then entities[#entities + 1] = {name = "crash-site-chest-" .. math_random(1,2), position = p, force = "neutral"} end

	tiles[#tiles + 1] = {name = "tutorial-grid", position = p}
end

local function process_level_10_position(p, seed, tiles, entities, markets, treasure)
	local scrapyard = get_noise("scrapyard", p, seed)

  if scrapyard < -0.70 or scrapyard > 0.70 then
    tiles[#tiles + 1] = {name = "grass-3", position = p}
    if math_random(1,40) == 1 then treasure[#treasure + 1] = p end
    return
  end

  if scrapyard < -0.65 or scrapyard > 0.65 then
    tiles[#tiles + 1] = {name = "water-green", position = p}
    return
  end
  if math_abs(scrapyard) > 0.40 and  math_abs(scrapyard) < 0.65 then
		if math_random(1,64) == 1 then
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
    tiles[#tiles + 1] = {name = "water-mud", position = p}
    return
  end
  if math_abs(scrapyard) > 0.25 and  math_abs(scrapyard) < 0.40 then
		if math_random(1,128) == 1 then
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
    tiles[#tiles + 1] = {name = "water-shallow", position = p}
    return
  end
  if scrapyard > -0.15 and scrapyard < 0.15 then
    if math_random(1,100) > 88 then
      entities[#entities + 1] = {name = "tree-0" .. math_random(1,9), position = p}
    else
      if math_random(1,2) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
    end
    tiles[#tiles + 1] = {name = "dirt-6", position = p}
    return
  end
	tiles[#tiles + 1] = {name = "grass-2", position = p}
end

local function process_level_9_position(p, seed, tiles, entities, markets, treasure)
	local maze_p = {x = math_floor(p.x - p.x % 10), y = math_floor(p.y - p.y % 10)}
	local maze_noise = get_noise("no_rocks_2", maze_p, seed)

	if maze_noise > -0.35 and maze_noise < 0.35 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		local no_rocks_2 = get_noise("no_rocks_2", p, seed)
		if math_random(1,2) == 1 and no_rocks_2 > -0.5 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		if math_random(1,1024) == 1 then treasure[#treasure + 1] = p end
		if math_random(1,256) == 1 then
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
		return
	end

	if maze_noise > 0 and maze_noise < 0.45 then
		if math_random(1,512) == 1 then markets[#markets + 1] = p end
		if math_random(1,256) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
		if math_random(1,32) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
		return
	end

	if maze_noise < -0.5 or maze_noise > 0.5 then
		tiles[#tiles + 1] = {name = "deepwater", position = p}
		if math_random(1,96) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	tiles[#tiles + 1] = {name = "water", position = p}
	if math_random(1,96) == 1 then entities[#entities + 1] = {name="fish", position=p} end
end

local scrap_entities = {"crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-lab-broken",
 "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck",
 "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2"}
local scrap_entities_index = #scrap_entities

--SCRAPYARD
local function process_level_8_position(p, seed, tiles, entities, markets, treasure)
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

	if scrapyard < -0.25 or scrapyard > 0.25 then
		if math_random(1, 256) == 1 then
			entities[#entities + 1] = {name="gun-turret", position=p, force = "enemy"}
		end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if scrapyard < -0.55 or scrapyard > 0.55 then
			if math_random(1,2) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
			return
		end
		if scrapyard < -0.28 or scrapyard > 0.28 then
			if math_random(1,128) == 1 then
				Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
				entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
			end
			if math_random(1,96) == 1 then entities[#entities + 1] = {name = scrap_entities[math_random(1, scrap_entities_index)], position = p, force = "enemy"} end
			if math_random(1,5) > 1 then entities[#entities + 1] = {name="mineable-wreckage", position=p} end
			if math_random(1,256) == 1 then entities[#entities + 1] = {name ="land-mine", position = p, force = "enemy"} end
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
			if math_random(1,2) == 1 then entities[#entities +  1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
			return
		end
	end

	if math_random(1,64) == 1 and cave_ponds > 0.6 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end

	tiles[#tiles + 1] = {name = "stone-path", position = p}
	if math_random(1,256) == 1 then entities[#entities +1] = {name ="land-mine", position = p, force = "enemy"} end
end

local function process_level_7_position(p, seed, tiles, entities, markets, treasure)
	local cave_rivers_3 = get_noise("cave_rivers_3", p, seed)
	local cave_rivers_4 = get_noise("cave_rivers_4", p, seed + 50000)
	local no_rocks_2 = get_noise("no_rocks_2", p, seed)

	if cave_rivers_3 > -0.025 and cave_rivers_3 < 0.025 and no_rocks_2 > -0.6 then
		tiles[#tiles + 1] = {name = "water", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	if cave_rivers_4 > -0.025 and cave_rivers_4 < 0.025 and no_rocks_2 > -0.6 then
		tiles[#tiles + 1] = {name = "water", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	local noise_ores = get_noise("no_rocks_2", p, seed + 25000)

	if cave_rivers_3 > -0.20 and cave_rivers_3 < 0.20 then
		tiles[#tiles + 1] = {name = "grass-" .. math_floor(cave_rivers_3 * 32) % 3 + 1, position = p}
		if cave_rivers_3 > -0.10 and cave_rivers_3 < 0.10 then
			if math_random(1,8) == 1 and no_rocks_2 > -0.25 then entities[#entities + 1] = {name = "tree-01", position=p} end
			if math_random(1,2048) == 1 then markets[#markets + 1] = p end
			if noise_ores < -0.5 and no_rocks_2 > -0.6 then
				if cave_rivers_3 > 0 and cave_rivers_3 < 0.07 then
					entities[#entities + 1] = {name = "iron-ore", position=p, amount = math_abs(p.y) + 1}
				end
			end
		end
		if math_random(1,64) == 1 and no_rocks_2 > 0.7 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		return
	end

	if cave_rivers_4 > -0.20 and cave_rivers_4 < 0.20 then
		tiles[#tiles + 1] = {name = "grass-" .. math_floor(cave_rivers_4 * 32) % 3 + 1, position = p}
		if cave_rivers_4 > -0.10 and cave_rivers_4 < 0.10 then
			if math_random(1,8) == 1 and no_rocks_2 > -0.25 then entities[#entities + 1] = {name = "tree-02", position=p} end
			if math_random(1,2048) == 1 then markets[#markets + 1] = p end
			if noise_ores < -0.5 and no_rocks_2 > -0.6 then
				if cave_rivers_4 > 0 and cave_rivers_4 < 0.07 then
					entities[#entities + 1] = {name = "copper-ore", position=p, amount = math_abs(p.y) + 1}
				end
			end
		end
		if math_random(1,64) == 1 and no_rocks_2 > 0.7 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		return
	end

	--Chasms
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
	if noise_cave_ponds < 0.25 and noise_cave_ponds > -0.25 then
		if small_caves > 0.55 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.55 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	tiles[#tiles + 1] = {name = "dirt-7", position = p}
	if math_random(1,100) > 15 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
	if math_random(1,256) == 1 then treasure[#treasure + 1] = p end
end

local function process_level_6_position(p, seed, tiles, entities, markets, treasure)
	local large_caves = get_noise("large_caves", p, seed)
	local cave_rivers = get_noise("cave_rivers", p, seed)

	--Chasms
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
	if noise_cave_ponds < 0.45 and noise_cave_ponds > -0.45 then
		if small_caves > 0.45 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.45 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if large_caves > -0.03 and large_caves < 0.03 and cave_rivers < 0.25 then
		tiles[#tiles + 1] = {name = "water-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end

	if cave_rivers > -0.1 and cave_rivers < 0.1 then
		if math_random(1,36) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
		if math_random(1,128) == 1 then
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
	else
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,100) > 15 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
		if math_random(1,4096) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
		if math_random(1,8096) == 1 then markets[#markets + 1] = p end
	end
end

local function process_level_5_position(p, seed, tiles, entities, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed)
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)

	if small_caves > -0.24 and small_caves < 0.24 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,768) == 1 then treasure[#treasure + 1] = p end
		if math_random(1,2) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		return
	end

	if small_caves < -0.50 or small_caves > 0.50 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		if math_random(1,128) == 1 then
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
		return
	end

	if small_caves > -0.40 and small_caves < 0.40 then
		if noise_cave_ponds > 0.35 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_random(1, 4), position = p}
			if math_random(1,256) == 1 then treasure[#treasure + 1] = p end
			if math_random(1,256) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
			return
		end
		if noise_cave_ponds > 0.25 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			if math_random(1,2) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
			return
		end
	end

	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function process_level_4_position(p, seed, tiles, entities, markets, treasure)
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
		if math_random(1,32) == 1 then markets[#markets + 1] = p end
	end
	if math_abs(noise_large_caves) > 0.5 then
		tiles[#tiles + 1] = {name = "grass-2", position = p}
		if math_random(1,620) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
		if math_random(1,384) == 1 then
			Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
			entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
		end
		if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end
	if math_abs(noise_large_caves) > 0.475 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,2) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		return
	end

	--Chasms
	if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
		if small_caves > 0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.75 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end

	if small_caves > -0.15 and small_caves < 0.15 then
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,2) == 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		if math_random(1, 1024) == 1 then treasure[#treasure + 1] = p end
		return
	end

	if noise_large_caves > -0.2 and noise_large_caves < 0.2 then

		--Main Rock Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return
		end

		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,100) > 30 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		return
	end

	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function process_level_3_position(p, seed, tiles, entities, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed + 50000)
	local small_caves_2 = get_noise("small_caves_2", p, seed + 70000)
	local noise_large_caves = get_noise("large_caves", p, seed + 60000)
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)

	--Market Spots
	if noise_cave_ponds < -0.77 then
		if noise_cave_ponds > -0.79 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
			entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p}
		else
			tiles[#tiles + 1] = {name = "grass-" .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
			if math_random(1,32) == 1 then markets[#markets + 1] = p end
			if math_random(1,16) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
		end
		return
	end

	if noise_large_caves > -0.15 and noise_large_caves < 0.15 or small_caves_2 > 0 then
		--Green Water Ponds
		if noise_cave_ponds > 0.80 then
			tiles[#tiles + 1] = {name = "deepwater-green", position = p}
			if math_random(1,16) == 1 then entities[#entities + 1] = {name="fish", position=p} end
			return
		end

		--Chasms
		if noise_cave_ponds < 0.12 and noise_cave_ponds > -0.12 then
			if small_caves > 0.85 then
				tiles[#tiles + 1] = {name = "out-of-map", position = p}
				return
			end
			if small_caves < -0.85 then
				tiles[#tiles + 1] = {name = "out-of-map", position = p}
				return
			end
		end

		--Rivers
		local cave_rivers = get_noise("cave_rivers", p, seed + 100000)
		if cave_rivers < 0.024 and cave_rivers > -0.024 then
			if noise_cave_ponds > 0.2 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
				return
			end
		end
		local cave_rivers_2 = get_noise("cave_rivers_2", p, seed)
		if cave_rivers_2 < 0.024 and cave_rivers_2 > -0.024 then
			if noise_cave_ponds < 0.4 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
				return
			end
		end

		if noise_cave_ponds > 0.725 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_random(4, 6), position = p}
			return
		end

		local no_rocks = get_noise("no_rocks", p, seed + 25000)
		--Worm oil Zones
		if no_rocks < 0.20 and no_rocks > -0.20 then
			if small_caves > 0.35 then
				tiles[#tiles + 1] = {name = "dirt-" .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
				if math_random(1,320) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
				if math_random(1,50) == 1 then
					Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
					entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
				end
				if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
				if math_random(1,64) == 1 then entities[#entities + 1] = {name = "dead-tree-desert", position=p} end
				return
			end
		end

		--Main Rock Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return
		end

		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,100) > 30 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		return
	end

	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function process_level_2_position(p, seed, tiles, entities, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed)
	local noise_large_caves = get_noise("large_caves", p, seed)

	if noise_large_caves > -0.75 and noise_large_caves < 0.75 then

		local noise_cave_ponds = get_noise("cave_ponds", p, seed)

		--Chasms
		if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
			if small_caves > 0.32 then
				tiles[#tiles + 1] = {name = "out-of-map", position = p}
				return
			end
			if small_caves < -0.32 then
				tiles[#tiles + 1] = {name = "out-of-map", position = p}
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
		if cave_rivers < 0.037 and cave_rivers > -0.037 then
			if noise_cave_ponds < 0.1 then
				tiles[#tiles + 1] = {name = "water-shallow", position = p}
				if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
				return
			end
		end

		if noise_cave_ponds > 0.66 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_random(4, 6), position = p}
			return
		end

		--Market Spots
		if noise_cave_ponds < -0.80 then
			tiles[#tiles + 1] = {name = "grass-" .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
			if math_random(1,32) == 1 then markets[#markets + 1] = p end
			if math_random(1,16) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
			return
		end

		local no_rocks = get_noise("no_rocks", p, seed + 25000)
		--Worm oil Zones
		if no_rocks < 0.20 and no_rocks > -0.20 then
			if small_caves > 0.30 then
				tiles[#tiles + 1] = {name = "dirt-" .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
				if math_random(1,450) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
				if math_random(1,64) == 1 then
					Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
					entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
				end
				if math_random(1,1024) == 1 then treasure[#treasure + 1] = p end
				if math_random(1,64) == 1 then entities[#entities + 1] = {name = "dead-tree-desert", position=p} end
				return
			end
		end


		--Main Rock Terrain
		local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
		if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
			tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
			if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
			return
		end

		if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if math_random(1,100) > 25 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
		return
	end

	tiles[#tiles + 1] = {name = "out-of-map", position = p}
end

local function process_level_1_position(p, seed, tiles, entities, markets, treasure)
	local small_caves = get_noise("small_caves", p, seed)
	local noise_large_caves = get_noise("large_caves", p, seed)

	local noise_cave_ponds = get_noise("cave_ponds", p, seed)

	--Chasms
	if noise_cave_ponds < 0.12 and noise_cave_ponds > -0.12 then
		if small_caves > 0.55 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.55 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
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
	if cave_rivers < 0.044 and cave_rivers > -0.044 then
		if noise_cave_ponds > 0 then
			tiles[#tiles + 1] = {name = "water-shallow", position = p}
			if math_random(1,64) == 1 then entities[#entities + 1] = {name="fish", position=p} end
			return
		end
	end

	if noise_cave_ponds > 0.76 then
		tiles[#tiles + 1] = {name = "dirt-" .. math_random(4, 6), position = p}
		return
	end

	--Market Spots
	if noise_cave_ponds < -0.75 then
		tiles[#tiles + 1] = {name = "grass-" .. math_floor(noise_cave_ponds * 32) % 3 + 1, position = p}
		if math_random(1,32) == 1 then markets[#markets + 1] = p end
		if math_random(1,32) == 1 then entities[#entities + 1] = {name = "tree-0" .. math_random(1, 9), position=p} end
		return
	end

	local no_rocks = get_noise("no_rocks", p, seed + 25000)
	--Worm oil Zones
	if p.y < -64 + noise_cave_ponds * 10 then
		if no_rocks < 0.12 and no_rocks > -0.12 then
			if small_caves > 0.30 then
				tiles[#tiles + 1] = {name = "dirt-" .. math_floor(noise_cave_ponds * 32) % 7 + 1, position = p}
				if math_random(1,450) == 1 then entities[#entities + 1] = {name = "crude-oil", position = p, amount = get_oil_amount(p)} end
				if math_random(1,96) == 1 then
					Biters.wave_defense_set_worm_raffle(math_abs(p.y) * worm_level_modifier)
					entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = "enemy"}
				end
				if math_random(1,1024) == 1 then treasure[#treasure + 1] = p end
				if math_random(1,64) == 1 then entities[#entities + 1] = {name = "dead-tree-desert", position=p} end
				return
			end
		end
	end

	--Main Rock Terrain
	local no_rocks_2 = get_noise("no_rocks_2", p, seed + 75000)
	if no_rocks_2 > 0.65 or no_rocks_2 < -0.65 then
		tiles[#tiles + 1] = {name = "dirt-" .. math_floor(no_rocks_2 * 8) % 2 + 5, position = p}
		if math_random(1,32) == 1 then entities[#entities + 1] = {name = "dead-tree-desert", position=p} end
		if math_random(1,512) == 1 then treasure[#treasure + 1] = p end
		return
	end

	if math_random(1,2048) == 1 then treasure[#treasure + 1] = p end
	tiles[#tiles + 1] = {name = "dirt-7", position = p}
	if math_random(1,100) > 25 then entities[#entities + 1] = {name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p} end
end

local levels = {
	process_level_1_position,
	process_level_2_position,
	process_level_3_position,
	process_level_4_position,
	process_level_5_position,
	process_level_6_position,
	process_level_7_position,
	process_level_8_position,
	process_level_9_position,
	process_level_10_position,
	process_level_11_position,
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
}

local function rock_chunk(surface, left_top)
	local tiles = {}
	local entities = {}
	local markets = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed

	local level_index = math_floor((math_abs(left_top.y / level_depth)) % 11) + 1
	local process_level = levels[level_index]

	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_level(p, seed, tiles, entities, markets, treasure)
		end
	end
	surface.set_tiles(tiles, true)

	if #markets > 0 then
		local position = markets[math_random(1, #markets)]
		if surface.count_entities_filtered{area = {{position.x - 96, position.y - 96}, {position.x + 96, position.y + 96}}, name = "market", limit = 1} == 0 then
			local market = Market.mountain_market(surface, position, math_abs(position.y) * 0.004)
			market.destructible = false
		end
	end

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

local function border_chunk(surface, left_top)
	local trees = {"dead-grey-trunk", "dead-grey-trunk", "dry-tree"}
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
			if math_random(1, pos.y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-medium", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
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
			if math_random(1, math.ceil(pos.y + pos.y) + 2) == 1 then
				surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = pos})
			end
		end
	end

	for _, e in pairs(surface.find_entities_filtered({area = {{left_top.x, left_top.y},{left_top.x + 32, left_top.y + 32}}, type = "cliff"})) do	e.destroy() end
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
	--for _, e in pairs(surface.find_entities_filtered({area = {{left_top.x, left_top.y},{left_top.x + 32, left_top.y + 32}}, type = "cliff"})) do	e.destroy() end
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

local function out_of_map(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x = left_top.x + x, y = left_top.y + y}}})
		end
	end
end

local function wall(surface, left_top, seed)
	local entities = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			local small_caves = get_noise("small_caves", p, seed)
			local cave_ponds = get_noise("cave_rivers", p, seed + 100000)
			if y > 9 + cave_ponds * 6 and y < 23 + small_caves * 6 then
				if small_caves > 0.15 or cave_ponds > 0.15 then
					--surface.set_tiles({{name = "water-shallow", position = p}})
					surface.set_tiles({{name = "deepwater", position = p}})
					if math_random(1,48) == 1 then surface.create_entity({name = "fish", position = p}) end
				else
					surface.set_tiles({{name = "dirt-7", position = p}})
					if math_random(1, 2) == 1 then
						surface.create_entity({name = rock_raffle[math_random(1, size_of_rock_raffle)], position = p})
					end
				end
			else
				surface.set_tiles({{name = "dirt-7", position = p}})

				if surface.can_place_entity({name = "stone-wall", position = p, force = "enemy"}) then
					if math_random(1,512) == 1 and y > 3 and y < 28 then
						if math_random(1, 2) == 1 then
							Treasure(surface, p, "wooden-chest")
						else
							Treasure(surface, p, "iron-chest")
						end
					else

						if y < 5 or y > 26 then
							if y <= 15 then
								if math_random(1, y + 1) == 1 then
									local e = surface.create_entity({name = "stone-wall", position = p, force = "player"})
									e.minable = false
								end
							else
								if math_random(1, 32 - y)  == 1 then
									local e = surface.create_entity({name = "stone-wall", position = p, force = "player"})
									e.minable = false
								end
							end
						end

					end
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
						if math_abs(p.y) < level_depth * 2.5 then
							e.insert({name = "firearm-magazine", count = math_random(64, 128)})
						elseif math_abs(p.y) < level_depth * 4.5 then
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

local function process_chunk(surface, left_top)
	if not surface then return end
	if not surface.valid then return end
	if left_top.x >= level_depth * 0.5 then return end
	if left_top.x < level_depth * -0.5 then return end

	if left_top.y % level_depth == 0 and left_top.y < 0 then wall(surface, left_top, surface.map_gen_settings.seed) return end

	if left_top.y >= 0 then replace_water(surface, left_top) end
	if left_top.y > 32 then game.forces.player.chart(surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}}) end
	if left_top.y == -128 and left_top.x == -128 then
		local p = global.locomotive.position
		for _, entity in pairs(surface.find_entities_filtered({area = {{p.x - 3, p.y - 4},{p.x + 3, p.y + 10}}, type = "simple-entity"})) do	entity.destroy() end
	end
	if left_top.y < 0 then rock_chunk(surface, left_top) return end
	if left_top.y > 96 then out_of_map(surface, left_top) return end
	if left_top.y > 64 then biter_chunk(surface, left_top) return end
	if left_top.y >= 0 then border_chunk(surface, left_top) return end
end

local function on_chunk_generated(event)
	if string.sub(event.surface.name, 0, 8) ~= "mountain" then return end
	process_chunk(event.surface, event.area.left_top)
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)

return level_depth

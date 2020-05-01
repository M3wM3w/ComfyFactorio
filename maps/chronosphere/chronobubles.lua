local Chrono_table = require 'maps.chronosphere.table'

local Public = {}
local math_random = math.random
--biters: used in spawner generation within math_random(1, 52 - biters), so higher number gives better chance. not to be greater than 50.

local biomes = {
  [1] = {{id = 1, name = {"chronosphere.map_1"}, dname = "Terra Ferrata", iron = 6, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = -0.2}, weight = 1},
  [2] = {{id = 2, name = {"chronosphere.map_2"}, dname = "Malachite Hills", iron = 1, copper = 6, coal = 1, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0.2}, weight = 1},
  [3] = {{id = 3, name = {"chronosphere.map_3"}, dname = "Granite Plains", iron = 1, copper = 1, coal = 1, stone = 6, uranium = 0, oil = 1, biters = 16, moisture = -0.2}, weight = 1},
  [4] = {{id = 4, name = {"chronosphere.map_4"}, dname = "Petroleum Basin", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 6, biters = 16, moisture = 0.1}, weight = 1},
  [5] = {{id = 5, name = {"chronosphere.map_5"}, dname = "Pitchblende Mountain", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 6, oil = 1, biters = 16, moisture = -0.2}, weight = 1},
  [6] = {{id = 6, name = {"chronosphere.map_6"}, dname = "Mixed Deposits", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 0, oil = 2, biters = 10, moisture = 0}, weight = 3},
  [7] = {{id = 7, name = {"chronosphere.map_7"}, dname = "Biter Homelands", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 4, oil = 3, biters = 40, moisture = 0.2}, weight = 4},
  [8] = {{id = 8, name = {"chronosphere.map_8"}, dname = "Gangue Dumps", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 0, biters = 16, moisture = 0.1}, weight = 1},
  [9] = {{id = 9, name = {"chronosphere.map_9"}, dname = "Antracite Valley", iron = 1, copper = 1, coal = 6, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0}, weight = 1},
  [10] = {{id = 10, name = {"chronosphere.map_10"}, dname = "Ancient Battlefield", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 0, moisture = -0.2}, weight = 3},
  [11] = {{id = 11, name = {"chronosphere.map_11"}, dname = "Cave Systems", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 6, moisture = -0.2}, weight = 2},
  [12] = {{id = 12, name = {"chronosphere.map_12"}, dname = "Strange Forest", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 1, biters = 6, moisture = 0.4}, weight = 2},
  [13] = {{id = 13, name = {"chronosphere.map_13"}, dname = "Riverlands", iron = 1, copper = 1, coal = 3, stone = 1, uranium = 0, oil = 0, biters = 8, moisture = 0.5}, weight = 2},
  [14] = {{id = 14, name = {"chronosphere.map_14"}, dname = "Burning Hell", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 0, oil = 0, biters = 6, moisture = -0.5}, weight = 1},
  [15] = {{id = 15, name = {"chronosphere.map_15"}, dname = "Starting Area", iron = 5, copper = 3, coal = 5, stone = 2, uranium = 0, oil = 0, biters = 1, moisture = -0.3}, weight = 0},
  [16] = {{id = 16, name = {"chronosphere.map_16"}, dname = "Hedge Maze", iron = 3, copper = 3, coal = 3, stone = 3, uranium = 1, oil = 2, biters = 16, moisture = -0.1}, weight = 2},
  [17] = {{id = 17, name = {"chronosphere.map_17"}, dname = "Fish Market", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 100, moisture = 0}, weight = 0},
  [18] = {{id = 18, name = {"chronosphere.map_18"}, dname = "Methane Swamps", iron = 2, copper = 0, coal = 3, stone = 0, uranium = 0, oil = 2, biters = 16, moisture = 0.5}, weight = 2},
  [19] = {{id = 19, name = {"chronosphere.map_19"}, dname = "ERROR DESTINATION NOT FOUND", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 0, moisture = 0}, weight = 0}
}

local time_speed_variants = {
  [1] = {name = {"chronosphere.daynight_static"}, dname = "static", timer = 0},
  [2] = {name = {"chronosphere.daynight_normal"}, dname = "normal", timer = 100},
  [3] = {name = {"chronosphere.daynight_slow"}, dname = "slow", timer = 200},
  [4] = {name = {"chronosphere.daynight_superslow"}, dname = "superslow", timer = 400},
  [5] = {name = {"chronosphere.daynight_fast"}, dname = "fast", timer = 50},
  [6] = {name = {"chronosphere.daynight_superfast"}, dname = "superfast", timer = 25}
}

local richness = {
  [1] = {name = {"chronosphere.ore_richness_very_rich"}, dname = "very rich", factor = 3},
  [2] = {name = {"chronosphere.ore_richness_rich"}, dname = "rich", factor = 2},
  [3] = {name = {"chronosphere.ore_richness_normal"}, dname = "normal", factor = 1},
  [4] = {name = {"chronosphere.ore_richness_poor"}, dname = "poor", factor = 0.6},
  [5] = {name = {"chronosphere.ore_richness_very_poor"}, dname = "very poor", factor = 0.3},
  [6] = {name = {"chronosphere.ore_richness_none"}, dname = "none", factor = 0}
}
local function biome_roll()
  local biomes_raffle = {}
	for t = 1, #biomes, 1 do
    if biomes[t].weight > 0 then
      for _ = 1, biomes[t].weight, 1 do
          table.insert(biomes_raffle, biomes[t][1])
      end
    end
  end
  
  local planet = biomes_raffle[math_random(1,#biomes_raffle)]
  return planet
end

function Public.determine_planet(choice)
  local objective = Chrono_table.get_table()
  if not global.difficulty_vote_value then global.difficulty_vote_value = 1 end
  local difficulty = global.difficulty_vote_value

  local ores_weights = {4,8,12,8,4,0}
  if difficulty <= 0.25
  then ores_weights = {9,10,9,4,2,0}
  elseif difficulty <= 0.5
  then ores_weights = {5,11,12,6,2,0}
  elseif difficulty <= 0.75
  then ores_weights = {5,9,12,7,3,0}
  elseif difficulty <= 1
  then ores_weights = {4,8,12,8,4,0}
  elseif difficulty <= 1.5
  then ores_weights = {2,7,12,10,5,0}
  elseif difficulty <= 3
  then ores_weights = {1,6,12,11,6,0}
  elseif difficulty >= 5
  then ores_weights = {1,2,12,15,6,0}
  end
  local ores_raffle = {}
	for t = 1, 6, 1 do
    if ores_weights[t] > 0 then
      for _ = 1, ores_weights[t], 1 do
          table.insert(ores_raffle, t)
      end
    end
  end
  local ores = ores_raffle[math_random(1,#ores_raffle)]

  local dayspeed = time_speed_variants[math_random(1, #time_speed_variants)]
  local daytime = math_random(1,100) / 100
  local planet_choice
  if objective.game_lost then
    choice = 15
    ores = 2
  end
  if objective.upgrades[16] == 1 then
    choice = 17
    ores = 6
  end
  if objective.config.jumpfailure == true and objective.game_lost == false then
    if objective.chronojumps == 21 or objective.chronojumps == 29 or objective.chronojumps == 36 or objective.chronojumps == 42 then
      choice = 19
      ores = 6
      dayspeed = time_speed_variants[1]
      daytime = 0.15
    end
  end
  if not choice then
    planet_choice = biome_roll()
  else
    if biomes[choice][1] then
      planet_choice = biomes[choice][1]
    else
      planet_choice = biome_roll()
    end
  end
  if planet_choice.id == 10 then ores = 6 end
  if objective.upgrades[13] == 1 and ores == 5 then ores = 4 end
  if objective.upgrades[14] == 1 and ores > 3 and ores < 6 then ores = 3 end

  local planet = {
    [1] = {
      name = planet_choice,
      day_speed = dayspeed,
      time = daytime,
      ore_richness = richness[ores]
    }
  }
  
  objective.planet = planet
end
return Public

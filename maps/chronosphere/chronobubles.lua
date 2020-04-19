local Public = {}
local math_random = math.random
--cumul_chance must be sum of this and all previous chances, add new planets at the end only, or recalculate
--biters: used in spawner generation within math_random(1, 52 - biters), so higher number gives better chance. not to be greater than 50.
local variants = {
  [1] = {id = 1, name = {"chronosphere.map_1"}, dname = "Terra Ferrata", iron = 6, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = -0.2, chance = 1, cumul_chance = 1},
  [2] = {id = 2, name = {"chronosphere.map_2"}, dname = "Malachite Hills", iron = 1, copper = 6, coal = 1, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0.2, chance = 1, cumul_chance = 2},
  [3] = {id = 3, name = {"chronosphere.map_3"}, dname = "Granite Plains", iron = 1, copper = 1, coal = 1, stone = 6, uranium = 0, oil = 1, biters = 16, moisture = -0.2, chance = 1, cumul_chance = 3},
  [4] = {id = 4, name = {"chronosphere.map_4"}, dname = "Petroleum Basin", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 6, biters = 16, moisture = 0.1, chance = 1, cumul_chance = 4},
  [5] = {id = 5, name = {"chronosphere.map_5"}, dname = "Pitchblende Mountain", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 6, oil = 1, biters = 16, moisture = -0.2, chance = 1, cumul_chance = 5},
  [6] = {id = 6, name = {"chronosphere.map_6"}, dname = "Mixed Deposits", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 0, oil = 2, biters = 10, moisture = 0, chance = 3, cumul_chance = 8},
  [7] = {id = 7, name = {"chronosphere.map_7"}, dname = "Biter Homelands", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 4, oil = 3, biters = 40, moisture = 0.2, chance = 4, cumul_chance = 12},
  [8] = {id = 8, name = {"chronosphere.map_8"}, dname = "Gangue Dumps", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 0, biters = 16, moisture = 0.1, chance = 1, cumul_chance = 13},
  [9] = {id = 9, name = {"chronosphere.map_9"}, dname = "Antracite Valley", iron = 1, copper = 1, coal = 6, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0, chance = 1, cumul_chance = 14},
  [10] = {id = 10, name = {"chronosphere.map_10"}, dname = "Ancient Battlefield", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 0, moisture = -0.2, chance = 3, cumul_chance = 17},
  [11] = {id = 11, name = {"chronosphere.map_11"}, dname = "Cave Systems", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 6, moisture = -0.2, chance = 2, cumul_chance = 19},
  [12] = {id = 12, name = {"chronosphere.map_12"}, dname = "Strange Forest", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 1, biters = 6, moisture = 0.4, chance = 2, cumul_chance = 21},
  [13] = {id = 13, name = {"chronosphere.map_13"}, dname = "Riverlands", iron = 1, copper = 1, coal = 3, stone = 1, uranium = 0, oil = 0, biters = 8, moisture = 0.5, chance = 2, cumul_chance = 23},
  [14] = {id = 14, name = {"chronosphere.map_14"}, dname = "Burning Hell", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 0, oil = 0, biters = 6, moisture = -0.5, chance = 1, cumul_chance = 24},
  [15] = {id = 15, name = {"chronosphere.map_15"}, dname = "Starting Area", iron = 5, copper = 3, coal = 5, stone = 2, uranium = 0, oil = 0, biters = 1, moisture = -0.3, chance = 0, cumul_chance = 24},
  [16] = {id = 16, name = {"chronosphere.map_16"}, dname = "Hedge Maze", iron = 3, copper = 3, coal = 3, stone = 3, uranium = 1, oil = 2, biters = 16, moisture = -0.1, chance = 2, cumul_chance = 26},
  [17] = {id = 17, name = {"chronosphere.map_17"}, dname = "Fish Market", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 100, moisture = 0, chance = 0, cumul_chance = 26},
  [18] = {id = 18, name = {"chronosphere.map_18"}, dname = "Methane Swamps", iron = 2, copper = 0, coal = 3, stone = 0, uranium = 0, oil = 2, biters = 16, moisture = 0.5, chance = 2, cumul_chance = 28},
  [19] = {id = 19, name = {"chronosphere.map_19"}, dname = "ERROR DESTINATION NOT FOUND", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 0, moisture = 0, chance = 0, cumul_chance = 28}
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
  [3] = {name = {"chronosphere.ore_richness_rich"}, dname = "rich", factor = 2},
  [4] = {name = {"chronosphere.ore_richness_normal"}, dname = "normal", factor = 1},
  [5] = {name = {"chronosphere.ore_richness_normal"}, dname = "normal", factor = 1},
  [6] = {name = {"chronosphere.ore_richness_normal"}, dname = "normal", factor = 1},
  [7] = {name = {"chronosphere.ore_richness_poor"}, dname = "poor", factor = 0.6},
  [8] = {name = {"chronosphere.ore_richness_poor"}, dname = "poor", factor = 0.6},
  [9] = {name = {"chronosphere.ore_richness_very_poor"}, dname = "very poor", factor = 0.3},
  [10] = {name = {"chronosphere.ore_richness_none"}, dname = "none", factor = 0}
}
local function roll(weight)
  for i = 1, 100, 1 do
    local planet = variants[math_random(1, #variants)]
    local planet_weight = planet.chance
    local planet_cumul = planet.cumul_chance
    local rolling = math_random(1, weight)
    if ((planet_cumul - planet_weight < rolling) and (rolling  <= planet_cumul)) then
      return planet
    end
  end
  --default planet if 100 rolls fail
  return variants[6]
end

function Public.determine_planet(choice)
  local objective = global.objective
  local weight = variants[#variants].cumul_chance
  local planet_choice = nil
  local ores = math_random(1, 9)
  local dayspeed = time_speed_variants[math_random(1, #time_speed_variants)]
  local daytime = math_random(1,100) / 100
  if objective.game_lost then
    choice = 15
    ores = 2
  end
  if objective.upgrades[16] == 1 then
    choice = 17
    ores = 10
  end
  if objective.config.jumpfailure == true and objective.game_lost == false then
    if objective.chronojumps == 21 or objective.chronojumps == 29 or chronojumps == 36 or chronojumps == 42 then
      choice = 19
      ores = 10
      dayspeed = time_speed_variants[1]
      daytime = 0.15
    end
  end
  if not choice then
    planet_choice = roll(weight)
  else
    if variants[choice] then
      planet_choice = variants[choice]
    else
      planet_choice = roll(weight)
    end
  end
  if planet_choice.id == 10 then ores = 10 end
  if objective.upgrades[13] == 1 and ores == 9 then ores = 8 end
  if objective.upgrades[14] == 1 and ores > 6 and ores ~= 10 then ores = 6 end
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

local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Rand = require 'maps.chronosphere.random'

local Public = {}
local math_random = math.random
--biters: used in spawner generation within math_random(1, 52 - biters), so higher number gives better chance. not to be greater than 50.

local biome_types = {
  ironwrld = {id = 1, name = {"chronosphere.map_1"}, dname = "Terra Ferrata", iron = 6, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = -0.2},

  copperwrld = {id = 2, name = {"chronosphere.map_2"}, dname = "Malachite Hills", iron = 1, copper = 6, coal = 1, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0.2},

  stonewrld = {id = 3, name = {"chronosphere.map_3"}, dname = "Granite Plains", iron = 1, copper = 1, coal = 1, stone = 6, uranium = 0, oil = 1, biters = 16, moisture = -0.2},

  oilwrld = {id = 4, name = {"chronosphere.map_4"}, dname = "Petroleum Basin", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 6, biters = 16, moisture = 0.1},

  uraniumwrld = {id = 5, name = {"chronosphere.map_5"}, dname = "Pitchblende Mountain", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 6, oil = 1, biters = 16, moisture = -0.2},

  mixedwrld = {id = 6, name = {"chronosphere.map_6"}, dname = "Mixed Deposits", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 0, oil = 2, biters = 10, moisture = 0},

  biterwrld = {id = 7, name = {"chronosphere.map_7"}, dname = "Biter Homelands", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 4, oil = 3, biters = 40, moisture = 0.2},

  dumpwrld = {id = 8, name = {"chronosphere.map_8"}, dname = "Gangue Dumps", iron = 1, copper = 1, coal = 1, stone = 1, uranium = 0, oil = 0, biters = 16, moisture = 0.1},

  coalwrld = {id = 9, name = {"chronosphere.map_9"}, dname = "Antracite Valley", iron = 1, copper = 1, coal = 6, stone = 1, uranium = 0, oil = 1, biters = 16, moisture = 0},

  scrapwrld = {id = 10, name = {"chronosphere.map_10"}, dname = "Ancient Battlefield", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 0, moisture = -0.2},

  cavewrld = {id = 11, name = {"chronosphere.map_11"}, dname = "Cave Systems", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 6, moisture = -0.2},

  forestwrld = {id = 12, name = {"chronosphere.map_12"}, dname = "Strange Forest", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 1, biters = 6, moisture = 0.4},

  riverwrld = {id = 13, name = {"chronosphere.map_13"}, dname = "Riverlands", iron = 1, copper = 1, coal = 3, stone = 1, uranium = 0, oil = 0, biters = 8, moisture = 0.5},

  hellwrld = {id = 14, name = {"chronosphere.map_14"}, dname = "Burning Hell", iron = 2, copper = 2, coal = 2, stone = 2, uranium = 0, oil = 0, biters = 6, moisture = -0.5},

  startwrld = {id = 15, name = {"chronosphere.map_15"}, dname = "Starting Area", iron = 5, copper = 3, coal = 5, stone = 2, uranium = 0, oil = 0, biters = 1, moisture = -0.3},

  mazewrld = {id = 16, name = {"chronosphere.map_16"}, dname = "Hedge Maze", iron = 3, copper = 3, coal = 3, stone = 3, uranium = 1, oil = 2, biters = 16, moisture = -0.1},

  endwrld = {id = 17, name = {"chronosphere.map_17"}, dname = "Fish Market", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 100, moisture = 0},

  swampwrld = {id = 18, name = {"chronosphere.map_18"}, dname = "Methane Swamps", iron = 2, copper = 0, coal = 3, stone = 0, uranium = 0, oil = 2, biters = 16, moisture = 0.5},

  nukewrld = {id = 19, name = {"chronosphere.map_19"}, dname = "ERROR DESTINATION NOT FOUND", iron = 0, copper = 0, coal = 0, stone = 0, uranium = 0, oil = 0, biters = 0, moisture = 0}
  }

local time_speed_variants = {
  static = {name = {"chronosphere.daynight_static"}, dname = "static", timer = 0},
  normal = {name = {"chronosphere.daynight_normal"}, dname = "normal", timer = 150},
  slow = {name = {"chronosphere.daynight_slow"}, dname = "slow", timer = 300},
  superslow = {name = {"chronosphere.daynight_superslow"}, dname = "superslow", timer = 600},
  fast = {name = {"chronosphere.daynight_fast"}, dname = "fast", timer = 80},
  superfast = {name = {"chronosphere.daynight_superfast"}, dname = "superfast", timer = 40}
}

local ore_richness_variants = { -- 20/04/04: less variance in the factors here is really important I think because this variance can kill runs
  vrich = {name = {"chronosphere.ore_richness_very_rich"}, dname = "very rich", factor = 2.5},
  rich = {name = {"chronosphere.ore_richness_rich"}, dname = "rich", factor = 1.5},
  normal = {name = {"chronosphere.ore_richness_normal"}, dname = "normal", factor = 1},
  poor = {name = {"chronosphere.ore_richness_poor"}, dname = "poor", factor = 0.75},
  vpoor = {name = {"chronosphere.ore_richness_very_poor"}, dname = "very poor", factor = 0.5},
  none = {name = {"chronosphere.ore_richness_none"}, dname = "none", factor = 0}
}


function Public.determine_planet(choice)
  local objective = Chrono_table.get_table()
  local difficulty = Difficulty.get().difficulty_vote_value

  local ores = Rand.raffle(ore_richness_variants, Balance.ore_richness_weights(difficulty))
  local dayspeed = Rand.raffle(time_speed_variants, Balance.dayspeed_weights)
  local daytime = math_random(1,100) / 100

  local planet_choice
  if objective.game_lost then
    choice = "startwrld"
    ores = ore_richness_variants["rich"]
    dayspeed = time_speed_variants["normal"]
    daytime = 0
  end
  if objective.upgrades[16] == 1 then
    choice = "endwrld"
    ores = ore_richness_variants["none"]
  end
  if objective.config.jumpfailure == true and objective.game_lost == false then
    if objective.chronojumps == 19 or objective.chronojumps == 26 or objective.chronojumps == 33 or objective.chronojumps == 41 then
      choice = "nukewrld"
      ores = ore_richness_variants["none"]
      dayspeed = time_speed_variants["static"]
      daytime = 0.15
    end
  end

  if not choice then
    planet_choice = Rand.raffle(biome_types,Balance.biome_weights)
  else
    if biome_types[choice] then
      planet_choice = biome_types[choice]
    else
      planet_choice = Rand.raffle(biome_types,Balance.biome_weights)
    end
  end
  if planet_choice.id == 10 then ores = ore_richness_variants["none"] end
  if objective.upgrades[13] == 1 and ores == ore_richness_variants["vpoor"] then ores = ore_richness_variants["poor"] end
  if objective.upgrades[14] == 1 and (ore_richness_variants["vpoor"] or ore_richness_variants["poor"]) then ores = ore_richness_variants["normal"] end

  local planet = {
    [1] = {
      type = planet_choice,
      day_speed = dayspeed,
      time = daytime,
      ore_richness = ores
    }
  }

  
  objective.planet = planet
end
return Public

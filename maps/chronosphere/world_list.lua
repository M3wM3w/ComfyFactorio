local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Rand = require 'maps.chronosphere.random'
local random = math.random
local Public = {}
local Worlds = {}

Worlds[1] = {
  world_id = 1,
  map = require "maps.chronosphere.worlds.basic",
  variants = {
    [1] = {id = 1, min = 1, weight = 1, name = {"chronosphere.map_1_1"}, fe = 6, cu = 1, c = 1, s = 1, u = 0, o = 1, biters = 16, moisture = -0.2, fa = 1},
    [2] = {id = 2, min = 1, weight = 1, name = {"chronosphere.map_1_2"}, fe = 1, cu = 6, c = 1, s = 1, u = 0, o = 1, biters = 16, moisture = 0.2, fa = 1},
    [3] = {id = 3, min = 2, weight = 1, name = {"chronosphere.map_1_3"}, fe = 1, cu = 1, c = 1, s = 6, u = 0, o = 1, biters = 16, moisture = -0.2, fa = 1},
    [4] = {id = 4, min = 4, weight = 1, name = {"chronosphere.map_1_4"}, fe = 1, cu = 1, c = 1, s = 1, u = 0, o = 6, biters = 16, moisture = 0.1, fa = 1},
    [5] = {id = 5, min = 6, weight = 1, name = {"chronosphere.map_1_5"}, fe = 1, cu = 1, c = 1, s = 1, u = 6, o = 1, biters = 16, moisture = -0.2, fa = 1},
    [6] = {id = 6, min = 2, weight = 1, name = {"chronosphere.map_1_6"}, fe = 1, cu = 1, c = 6, s = 1, u = 0, o = 1, biters = 16, moisture = 0, fa = 1},
    [7] = {id = 7, min = 4, weight = 1, name = {"chronosphere.map_1_7"}, fe = 2, cu = 2, c = 2, s = 2, u = 4, o = 3, biters = 40, moisture = 0.2, fa = 0},
    [8] = {id = 8, min = 2, weight = 1, name = {"chronosphere.map_1_8"}, fe = 1, cu = 1, c = 1, s = 1, u = 0, o = 0, biters = 16, moisture = 0.1, fa = 4},
    [9] = {id = 9, min = 1, weight = 1, name = {"chronosphere.map_1_9"}, fe = 2, cu = 2, c = 2, s = 2, u = 0, o = 2, biters = 10, moisture = 0, fa = 1},
    [10] = {id = 10, min = 0, weight = 0, name = {"chronosphere.map_1_10"}, fe = 4, cu = 3, c = 4, s = 2, u = 0, o = 0, biters = 1, moisture = -0.3, fa = 0},
    [11] = {id = 11, min = 6, weight = 1, name = {"chronosphere.map_1_11"}, fe = 3, cu = 3, c = 2, s = 3, u = 0, o = 0, biters = 6, moisture = -0.5, fa = 4},
  },
  modifiers = {

  },
  default_tile = "grass-1"
}
Worlds[2] = {
  world_id = 2,
  map = require "maps.chronosphere.worlds.scrapyard",
  variants = {
    [1] = {id = 1, min = 1, weight = 1, name = {"chronosphere.map_2_1"}, fe = 0, cu = 0, c = 0, s = 0, u = 0, o = 0, biters = 0, moisture = -0.2, fa = 4},
    [2] = {id = 2, min = 15, weight = 0, name = {"chronosphere.map_2_2"}, fe = 0, cu = 0, c = 0, s = 0, u = 0, o = 0, biters = 0, moisture = -0.2, fa = 1},
    [3] = {id = 3, min = 4, weight = 1, name = {"chronosphere.map_2_3"}, fe = 0, cu = 0, c = 0, s = 0, u = 0, o = 0, biters = 0, moisture = -0.2, fa = 10},
  },
  modifiers = {
    ores = "none"
  },
  default_tile = "dirt-1"
}
Worlds[3] = {
  world_id = 3,
  map = require "maps.chronosphere.worlds.caveworld",
  variants = {
    [1] = {id = 1, min = 2, weight = 1, name = {"chronosphere.map_3_1"}, fe = 0, cu = 0, c = 0, s = 0, u = 0, o = 0, biters = 6, moisture = -0.2, fa = 0},
    [2] = {id = 2, min = 4, weight = 1, name = {"chronosphere.map_3_2"}, fe = 0, cu = 0, c = 0, s = 0, u = 0, o = 0, biters = 18, moisture = -0.4, fa = 0},
  },
  modifiers = {
    daytime = 0.35,
    dayspeed = "static"
  },
  default_tile = "dirt-6"
}
Worlds[4] = {
  world_id = 4,
  map = require "maps.chronosphere.worlds.forest",
  variants = {
    [1] = {id = 1, min = 1, weight = 1, name = {"chronosphere.map_4_1"}, fe = 0, cu = 0, c = 0, s = 0, u = 0, o = 0, biters = 6, moisture = 0.4, fa = 0},
  },
  modifiers = {
  },
  default_tile = "grass-1"
}
Worlds[5] = {
  world_id = 5,
  map = require "maps.chronosphere.worlds.maze",
  variants = {
    [1] = {id = 1, min = 2, weight = 1, name = {"chronosphere.map_5_1"}, fe = 3, cu = 3, c = 3, s = 3, u = 1, o = 2, biters = 16, moisture = -0.1, fa = 2},
  },
  modifiers = {
  },
  default_tile = "grass-1"
}
Worlds[6] = {
  world_id = 6,
  map = require "maps.chronosphere.worlds.riverlands",
  variants = {
    [1] = {id = 1, min = 2, weight = 1, name = {"chronosphere.map_6_1"}, fe = 2, cu = 2, c = 3, s = 1, u = 0, o = 0, biters = 16, moisture = 0.5, fa = 0},
  },
  modifiers = {
  },
  default_tile = "grass-1"
}
Worlds[7] = {
  world_id = 7,
  map = require "maps.chronosphere.worlds.fishmarket",
  variants = {
    [1] = {id = 1, min = 20, weight = 0, name = {"chronosphere.map_7_1"}, fe = 0, cu = 0, c = 0, s = 0, u = 0, o = 0, biters = 100, moisture = 0.0, fa = 0},
  },
  modifiers = {
    ores = "none",
    dayspeed = "static",
    daytime = 0
  },
  default_tile = "grass-1"
}
Worlds[8] = {
  world_id = 8,
  map = require "maps.chronosphere.worlds.swamp",
  variants = {
    [1] = {id = 1, min = 6, weight = 1, name = {"chronosphere.map_8_1"}, fe = 2, cu = 0, c = 3, s = 0, u = 0, o = 2, biters = 16, moisture = 0.5, fa = 0},
  },
  modifiers = {
  },
  default_tile = "grass-1"
}

local time_speed_variants = {
  static = {name = {"chronosphere.daynight_static"}, timer = 0},
  normal = {name = {"chronosphere.daynight_normal"}, timer = 150},
  slow = {name = {"chronosphere.daynight_slow"}, timer = 300},
  superslow = {name = {"chronosphere.daynight_superslow"}, timer = 600},
  fast = {name = {"chronosphere.daynight_fast"}, timer = 80},
  superfast = {name = {"chronosphere.daynight_superfast"}, timer = 40}
}

local time_speed_weights = { static = 1, normal = 4, slow = 3, superslow = 2, fast = 3, superfast = 2}

local ore_richness_variants = {
  vrich = {name = {"chronosphere.ore_richness_very_rich"}, factor = 2.5},
  rich = {name = {"chronosphere.ore_richness_rich"}, factor = 1.5},
  normal = {name = {"chronosphere.ore_richness_normal"}, factor = 1},
  poor = {name = {"chronosphere.ore_richness_poor"}, factor = 0.75},
  vpoor = {name = {"chronosphere.ore_richness_very_poor"}, factor = 0.5},
  none = {name = {"chronosphere.ore_richness_none"}, factor = 0}
}

local function special_world()
  local objective = Chrono_table.get_table()
  local special =  {yes = false, chosen_id = nil, chosen_variant_id = nil, ores = nil, dayspeed = nil, daytime = nil}
  if objective.game_lost then --start map
    special.yes = true
    special.chosen_id = 1
    special.chosen_variant_id = 10
    special.ores = ore_richness_variants["rich"]
    special.dayspeed = time_speed_variants["normal"]
    special.daytime = 0
    return special
  end
  if objective.config.jumpfailure == true then -- danger event
    if objective.chronojumps == 19 or objective.chronojumps == 26 or objective.chronojumps == 33 or objective.chronojumps == 41 then
      special.yes = true
      special.chosen_id = 2
      special.chosen_variant_id = 2
      special.ores = ore_richness_variants["none"]
      special.dayspeed = time_speed_variants["static"]
      special.daytime = 0.15
      return special
    end
  end
  if objective.upgrades[16] == 1 then -- fish market
    special.yes = true
    special.chosen_id = 7
    special.chosen_variant_id = 1
    special.ores = ore_richness_variants["none"]
    special.dayspeed = time_speed_variants["static"]
    special.daytime = 0.05
    return special
  end
  return special
end

local function modifiers(world_id)
  local modifier = {ores = nil, dayspeed = nil, daytime = nil}
  if Worlds[world_id].modifiers.ores then modifier.ores = ore_richness_variants[Worlds[world_id].modifiers.ores] end
  if Worlds[world_id].modifiers.dayspeed then modifier.dayspeed = time_speed_variants[Worlds[world_id].modifiers.dayspeed] end
  if Worlds[world_id].modifiers.daytime then modifier.daytime = Worlds[world_id].modifiers.daytime end
  return modifier
end

function Public.determine_world(optional_choice)
  local objective = Chrono_table.get_table()
  local difficulty = Difficulty.get().difficulty_vote_value
  local chosen_id
  local chosen_variant_id
  local ores = Rand.raffle(ore_richness_variants, Balance.ore_richness_weights(difficulty))
  local dayspeed = Rand.raffle(time_speed_variants, time_speed_weights)
  local daytime = random(0,100) / 100
  local special = special_world()
  if special.yes then
    chosen_id = special.chosen_id
    chosen_variant_id = special.chosen_variant_id
    if special.ores then ores = special.ores end
    if special.dayspeed then dayspeed = special.dayspeed end
    if special.daytime then daytime = special.daytime end
    objective.world = {
      id = chosen_id,
      variant = Worlds[chosen_id].variants[chosen_variant_id],
      default_tile = Worlds[chosen_id].default_tile or "grass-1",
      ores = ores,
      dayspeed = dayspeed,
      daytime = daytime
    }
    return
  end

  local choices = {types = {}, weights = {}}
  for _, world in pairs(Worlds) do
    table.insert(choices.types, world.world_id)
    local weight = 0
    for _,variant in pairs(world.variants) do
      if objective.chronojumps >= variant.min then
        weight = weight + variant.weight
      end
    end
    table.insert(choices.weights, weight)
  end
  if Worlds[optional_choice] then
    chosen_id = optional_choice
  else
    chosen_id = Rand.raffle(choices.types, choices.weights)
  end
  local variant_choices = {types = {}, weights = {}}
  for _,variant in pairs(Worlds[chosen_id].variants) do
    if objective.chronojumps >= variant.min then
      table.insert(variant_choices.types, variant.id)
      table.insert(variant_choices.weights, variant.weight)
    end
  end
  chosen_variant_id = Rand.raffle(variant_choices.types, variant_choices.weights)
  local modifiers = modifiers(chosen_id)
  if modifiers.ores then ores = modifiers.ores end
  if modifiers.dayspeed then dayspeed = modifiers.dayspeed end
  if modifiers.daytime then daytime = modifiers.daytime end
  if objective.upgrades[13] == 1 and ores == ore_richness_variants["vpoor"] then ores = ore_richness_variants["poor"] end
  if objective.upgrades[14] == 1 and (ore_richness_variants["vpoor"] or ore_richness_variants["poor"]) then ores = ore_richness_variants["normal"] end
  objective.world = {
    id = chosen_id,
    variant = Worlds[chosen_id].variants[chosen_variant_id],
    default_tile = Worlds[chosen_id].default_tile,
    ores = ores,
    dayspeed = dayspeed,
    daytime = daytime
  }
end

local function process_chunk(surface, left_top)
  local objective = Chrono_table.get_table()
  if not surface then return end
  if not surface.valid then return end
  local world = objective.world
  local level_depth = 960
  if world.id == 7 then level_depth = 2176 end
  if left_top.x >= level_depth * 0.5 or left_top.y >= level_depth * 0.5 then return end
  if left_top.x < level_depth * -0.5 or left_top.y < level_depth * -0.5 then return end
  Worlds[world.id].map(world.variant, surface, left_top)
  return
end

local function on_chunk_generated(event)
	if string.sub(event.surface.name, 0, 12) ~= "chronosphere" then return end
	process_chunk(event.surface, event.area.left_top)
end

local Event = require 'utils.event'
Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public

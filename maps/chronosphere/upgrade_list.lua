local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Public = {}

local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_ceil = math.ceil

function Public.upgrades()
  local objective = Chrono_table.get_table()
  local difficulty = Difficulty.get().difficulty_vote_value
  if not objective.upgrades then
    objective.upgrades = {}
    for i = 1, 16, 1 do
      objective.upgrades[i] = 0
    end
  end

  --Each upgrade is automatically added into gui.
  --name : visible name in gui (best if localized)
  --sprite: visible icon
  --cost/item/tt = the first part of localized string, for example coin is in item-name.coin. Can be even scenario's key.
  --Second part of localized string is taken from item's name.
  --First additional parameter for tooltip should match the max_level
  --still need to map upgrade effects in upgrades.lua / process_upgrade() if it should do more than increase level of upgrade
  local upgrades = {
    [1] = {
      name = {"chronosphere.upgrade_train_armor"},
      sprite = "recipe/locomotive",
      max_level = 36,
      message = {"chronosphere.upgrade_train_armor_message"},
      tooltip = {"chronosphere.upgrade_train_armor_tooltip", 36, objective.max_health},
      jump_limit = objective.upgrades[1],
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 500 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty) * (1 + 2 * objective.upgrades[1])},
        item2 = {name = "copper-plate", tt = "item-name", sprite = "item/copper-plate", count = 1500},
      }
    },
    [2] = {
      name = {"chronosphere.upgrade_filter"},
      sprite = "recipe/effectivity-module",
      max_level = 9,
      message = {"chronosphere.upgrade_filter_message"},
      tooltip = {"chronosphere.upgrade_filter_tooltip", math_floor(100 * Balance.machine_pollution_transfer_from_inside_factor(Difficulty.get().difficulty_vote_value, objective.upgrades[2]))},
      jump_limit = (1 + objective.upgrades[2]) * 3 or 0,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 5000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty)},
        item2 = {name = "electronic-circuit", tt = "item-name", sprite = "item/electronic-circuit", count = math_min(1 + objective.upgrades[2], 3) * 500 + 500},
        item3 = {name = "advanced-circuit", tt = "item-name", sprite = "item/advanced-circuit", count = math_max(math_min(1 + objective.upgrades[2], 6) - 3, 0) * 500},
        item4 = {name = "processing-unit", tt = "item-name", sprite = "item/processing-unit", count = math_max(math_min(1 + objective.upgrades[2], 9) - 6, 0) * 500}
      }
    },
    [3] = {
      name = {"chronosphere.upgrade_accumulators"},
      sprite = "recipe/accumulator",
      max_level = 24,
      message = {"chronosphere.upgrade_accumulators_message"},
      tooltip = {"chronosphere.upgrade_accumulators_tooltip"},
      jump_limit = objective.upgrades[3],
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 3000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty) * (1 + objective.upgrades[3] / 4)},
        item2 = {name = "battery", tt = "item-name", sprite = "item/battery", count = 100 * (1 + objective.upgrades[3])}
      }
    },
    [4] = {
      name = {"chronosphere.upgrade_loot_pickup"},
      sprite = "recipe/long-handed-inserter",
      max_level = 4,
      message = {"chronosphere.upgrade_loot_pickup_message"},
      tooltip = {"chronosphere.upgrade_loot_pickup_tooltip", objective.upgrades[4]},
      jump_limit = 0,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 1000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty) * (1 + objective.upgrades[4])},
        item2 = {name = "long-handed-inserter", tt = "entity-name", sprite = "recipe/long-handed-inserter", count = 400}
      }
    },
    [5] = {
      name = {"chronosphere.upgrade_inventory_size"},
      sprite = "entity/character",
      max_level = 4,
      message = {"chronosphere.upgrade_inventory_size_message"},
      tooltip = {"chronosphere.upgrade_inventory_size_tooltip"},
      jump_limit = (1 + objective.upgrades[5]) * 5,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 2500 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty) * (1 + objective.upgrades[5])},
        item2 = {name = "wooden-chest", tt = "entity-name", sprite = "item/wooden-chest", count = math_max(0, 250 - math_abs(objective.upgrades[5]) * 250)},
        item3 = {name = "iron-chest", tt = "entity-name", sprite = "item/iron-chest", count = math_max(0, 250 - math_abs(objective.upgrades[5] - 1) * 250)},
        item4 = {name = "steel-chest", tt = "entity-name", sprite = "item/steel-chest", count = math_max(0, 250 - math_abs(objective.upgrades[5] - 2) * 250)},
        item5 = {name = "logistic-chest-storage", tt = "entity-name", sprite = "item/logistic-chest-storage", count = math_max(0, 250 - math_abs(objective.upgrades[5] - 3) * 250)}
      }
    },
    [6] = {
      name = {"chronosphere.upgrade_repair"},
      sprite = "recipe/repair-pack",
      max_level = 4,
      message = {"chronosphere.upgrade_repair_message"},
      tooltip = {"chronosphere.upgrade_repair_tooltip", objective.upgrades[6]},
      jump_limit = 0,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 1000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty) * (1 + objective.upgrades[6])},
        item2 = {name = "repair-pack", tt = "item-name", sprite = "recipe/repair-pack", count = 200 * (1 + objective.upgrades[6])}
      }
    },
    [7] = {
      name = {"chronosphere.upgrade_water"},
      sprite = "fluid/water",
      max_level = 1,
      message = {"chronosphere.upgrade_water_message"},
      tooltip = {"chronosphere.upgrade_water_tooltip"},
      jump_limit = 0,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 2000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty)},
        item2 = {name = "pipe", tt = "entity-name", sprite = "item/pipe", count = 500},
        item3 = {name = "pump", tt = "entity-name", sprite = "item/pump", count = 10}
      }
    },
    [8] = {
      name = {"chronosphere.upgrade_output"},
      sprite = "recipe/cargo-wagon",
      max_level = 1,
      message = {"chronosphere.upgrade_output_message"},
      tooltip = {"chronosphere.upgrade_output_tooltip"},
      jump_limit = 0,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 2000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty)},
        item2 = {name = "fast-inserter", tt = "entity-name", sprite = "recipe/fast-inserter", count = 200}
      }
    },
    [9] = {
      name = {"chronosphere.upgrade_storage"},
      sprite = "item/logistic-chest-storage",
      max_level = 4,
      message = {"chronosphere.upgrade_storage_message"},
      tooltip = {"chronosphere.upgrade_storage_tooltip"},
      jump_limit = (1 + objective.upgrades[9]) * 5,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 3000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty) * (1 + objective.upgrades[9])},
        item2 = {name = "wooden-chest", tt = "entity-name", sprite = "item/wooden-chest", count = math_max(0, 250 - math_abs(objective.upgrades[9]) * 250)},
        item3 = {name = "iron-chest", tt = "entity-name", sprite = "item/iron-chest", count = math_max(0, 250 - math_abs(objective.upgrades[9] - 1) * 250)},
        item4 = {name = "steel-chest", tt = "entity-name", sprite = "item/steel-chest", count = math_max(0, 250 - math_abs(objective.upgrades[9] - 2) * 250)},
        item5 = {name = "logistic-chest-storage", tt = "entity-name", sprite = "item/logistic-chest-storage", count = math_max(0, 250 - math_abs(objective.upgrades[9] - 3) * 250)}
      }
    },
    [10] = {
      name = {"chronosphere.upgrade_poison"},
      sprite = "recipe/poison-capsule",
      max_level = 4,
      message = {"chronosphere.upgrade_poison_message"},
      tooltip = {"chronosphere.upgrade_poison_tooltip", math_ceil(objective.poisontimeout/6)},
      jump_limit = 0,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 1000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty)},
        item2 = {name = "poison-capsule", tt = "item-name", sprite = "recipe/poison-capsule", count = 50}
      }
    },
    [11] = {
      name = {"chronosphere.upgrade_fusion"},
      sprite = "recipe/fusion-reactor-equipment",
      max_level = 999,
      message = {"chronosphere.upgrade_fusion_message"},
      tooltip = {"chronosphere.upgrade_fusion_tooltip"},
      jump_limit = 24,
      cost = {
        item1 = {name = "low-density-structure", tt = "item-name", sprite = "item/low-density-structure", count = 100},
        item2 = {name = "railgun-dart", tt = "item-name", sprite = "item/railgun-dart", count = 200},
        item3 = {name = "solar-panel-equipment", tt = "equipment-name", sprite = "item/solar-panel-equipment", count = 16}
      }
    },
    [12] = {
      name = {"chronosphere.upgrade_mk2"},
      sprite = "recipe/power-armor-mk2",
      max_level = 999,
      message = {"chronosphere.upgrade_mk2_message"},
      tooltip = {"chronosphere.upgrade_mk2_tooltip"},
      jump_limit = 24,
      cost = {
        item1 = {name = "low-density-structure", tt = "item-name", sprite = "item/low-density-structure", count = 100},
        item2 = {name = "railgun-dart", tt = "item-name", sprite = "item/railgun-dart", count = 300},
        item3 = {name = "power-armor", tt = "item-name", sprite = "item/power-armor", count = 1}
      }
    },
    [13] = {
      name = {"chronosphere.upgrade_computer1"},
      sprite = "item/advanced-circuit",
      max_level = 1,
      message = {"chronosphere.upgrade_computer1_message"},
      tooltip = {"chronosphere.upgrade_computer1_tooltip"},
      jump_limit = 15,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 5000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty)},
        item2 = {name = "advanced-circuit", tt = "item-name", sprite = "item/advanced-circuit", count = 800},
        item3 = {name = "copper-plate", tt = "item-name", sprite = "item/copper-plate", count = 2000}
      }
    },
    [14] = {
      name = {"chronosphere.upgrade_computer2"},
      sprite = "item/processing-unit",
      max_level = 1,
      message = {"chronosphere.upgrade_computer2_message"},
      tooltip = {"chronosphere.upgrade_computer2_tooltip"},
      jump_limit = 20,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 10000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty)},
        item2 = {name = "processing-unit", tt = "item-name", sprite = "item/processing-unit", count = 800},
        item3 = {name = "nuclear-reactor", tt = "entity-name", sprite = "item/nuclear-reactor", count = 1}
      }
    },
    [15] = {
      name = {"chronosphere.upgrade_computer3"},
      sprite = "item/rocket-control-unit",
      max_level = 10,
      message = {"chronosphere.upgrade_computer3_message", objective.upgrades[15] + 1},
      tooltip = {"chronosphere.upgrade_computer3_tooltip"},
      jump_limit = 25,
      cost = {
        item1 = {name = "coin", tt = "item-name", sprite = "item/coin", count = 2000 * Balance.upgrades_coin_cost_difficulty_scaling(difficulty)},
        item2 = {name = "low-density-structure", tt = "item-name", sprite = "item/low-density-structure", count = 40},
        item3 = {name = "rocket-control-unit", tt = "item-name", sprite = "item/rocket-control-unit", count = 40},
        item4 = {name = "uranium-fuel-cell", tt = "item-name", sprite = "item/uranium-fuel-cell", count = 20}
      }
    },
    [16] = {
      name = {"chronosphere.upgrade_computer4"},
      sprite = "item/satellite",
      max_level = 1,
      message = {"chronosphere.upgrade_computer4_message"},
      tooltip = {"chronosphere.upgrade_computer4_tooltip"},
      jump_limit = 25,
      cost = {
        item1 = {name = "rocket-silo", tt = "entity-name", sprite = "item/rocket-silo", count = 1},
        item2 = {name = "satellite", tt = "item-name", sprite = "item/satellite", count = 1}
      }
    }

  }
  return upgrades
end

return Public

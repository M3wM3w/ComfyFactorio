local Chrono_table = require 'maps.chronosphere.table'
local Rand = require 'maps.chronosphere.random'

local Public = {}
local List = require 'maps.chronosphere.production_list'

local function roll_assembler()
  local objective = Chrono_table.get_table()
  local choices = {types = {}, weights = {}}
  for _, item in pairs(List) do
    if objective.chronojumps >= item.jump_min then
      table.insert(choices.types, item.id)
      table.insert(choices.weights, item.weight)
    end
  end
  return Rand.raffle(choices.types, choices.weights)
end

local function total_avg_level()
  local production = Chrono_table.get_production_table()
  local levels = 0
  local count = 0
  for _, assembler in pairs(production.train_assemblers) do
    levels = levels + assembler.tier
    count = count + 1
  end
  return math.floor(levels / count)
end

local function produce(factory, train)
  if factory.active then
    if not factory.entity.valid then
      factory.active = false
      return
    end
    local id = factory.id
    factory.progress = factory.progress + 60 * (1 + (factory.tier - 1) / 4)
    local progress_excess = factory.progress - List[id].base_time * 60
    local pollution_coef = 0.1 + factory.tier / 40
    if progress_excess >= 0 then
      local multi = math.floor(progress_excess / (List[id].base_time * 60))
      factory.progress = factory.progress - (1 + multi) * List[id].base_time * 60
      local inserted = factory.entity.get_output_inventory().insert{name = List[id].name, count = 1 + multi}
      factory.produced = factory.produced + inserted
      factory.entity.surface.pollute(factory.entity.position, inserted * pollution_coef)
      if train then
        game.pollution_statistics.on_flow("cargo-wagon", inserted * pollution_coef)
        game.forces.player.item_production_statistics.on_flow(List[id].name, inserted)
        factory.entity.products_finished = factory.entity.products_finished + inserted
      else
        game.pollution_statistics.on_flow("item-on-ground", inserted * pollution_coef)
      end
    end
  end
end

function Public.register_train_assembler(entity, id)
  local production = Chrono_table.get_production_table()
  production.train_assemblers[id] = {
    entity = entity,
    id = id,
    progress = 0,
    produced = 0,
    tier = 0,
    active = true
  }
end

local function levelup_train_factory(id)
  local production = Chrono_table.get_production_table()
  local xp = production.experience[id]
  local level = math.floor((xp / 1000)^(1 / 2))
  production.train_assemblers[id].tier = level
end

local function flying_text(surface, position, text, color)
	surface.create_entity({
		name = "flying-text",
		position = {position.x, position.y - 0.5},
		text = text,
		color = color
	})
end

function Public.produce_assemblers()
  local production = Chrono_table.get_production_table()
  for _, factory in pairs(production.assemblers) do
    produce(factory, false)
  end
  for key, factory in pairs(production.train_assemblers) do
    if factory.tier > 0 then
      produce(factory, true)
    end
  end
end

function Public.roll_random_assembler()
  local entity_to_spawn = "electric-furnace"
  local id = roll_assembler()
  if List[id].kind == "assembler" then
    entity_to_spawn = "assembling-machine-1"
  end
  if List[id].kind == "fluid-assembler" then
    entity_to_spawn = "assembling-machine-2"
  end

  local tier = 1 + math.min(4, total_avg_level())
  tier = math.random(1, tier)
  if tier > 2 and entity_to_spawn == "assembling-machine-1" then entity_to_spawn = "assembling-machine-2" end
  if tier > 4 and entity_to_spawn == "assembling-machine-2" then entity_to_spawn = "assembling-machine-3" end
  return {entity = entity_to_spawn, id = id, tier = tier}
end

function Public.register_random_assembler(entity, id, tier)
  local production = Chrono_table.get_production_table()
  local objective = Chrono_table.get_table()
  if not entity or not entity.valid then return end
  if List[id].kind == "assembler" or List[id].kind == "fluid-assembler" then
    entity.set_recipe(List[id].recipe_override or List[id].name)
    entity.recipe_locked = true
  end
  production.assemblers[#production.assemblers + 1] = {
    entity = entity,
    id = id,
    progress = 0,
    produced = 0,
    tier = tier,
    active = false
  }
end

function Public.check_activity()
  local production = Chrono_table.get_production_table()
  for key, factory in pairs(production.assemblers) do
    local entity = factory.entity
    if not entity.valid then
      factory.active = false
      goto continue
    end
    local surface = entity.surface
    local count = surface.count_entities_filtered{position = entity.position, radius = 10, force = "player"}
    if count > 10 then
      factory.active = true
      flying_text(surface, entity.position, "Active", {r = 0, g = 0.98, b = 0})
    else
      factory.active = false
      flying_text(surface, entity.position, "Not Active", {r = 0.98, g = 0, b = 0})
    end
    ::continue::
  end
end

function Public.jump_procedure()
  local production = Chrono_table.get_production_table()
  for _, factory in pairs(production.assemblers) do
    if not production.experience[factory.id] then production.experience[factory.id] = 0 end
    production.experience[factory.id] = production.experience[factory.id] + factory.produced
    levelup_train_factory(factory.id)
  end
  production.assemblers = {}
  for _, factory in pairs(production.train_assemblers) do
    if not production.experience[factory.id] then production.experience[factory.id] = 0 end
    production.experience[factory.id] = production.experience[factory.id] + (factory.produced / 2)
    production.train_assemblers[factory.id].produced = 0
    levelup_train_factory(factory.id)
  end
end

return Public

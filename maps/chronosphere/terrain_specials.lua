local Chrono_table = require 'maps.chronosphere.table'

local Public_terrain = {}

function Public_terrain.danger_event(surface, left_top)
  local objective = Chrono_table.get_table()
  local silo = surface.create_entity({name = "rocket-silo", force = "enemy", position = {x = left_top.x + 16, y = left_top.y + 16}})
  local pole = surface.create_entity({name = "medium-electric-pole", position = {x = left_top.x + 12, y = left_top.y + 11}, force = "scrapyard", create_build_effect_smoke = false})
  local silo_text = rendering.draw_text{
    text = "Nuclear silo",
    surface = surface,
    target = pole,
    target_offset = {5, -2.5},
    color = {r = 0.98, g = 0, b = 0},
    scale = 1.00,
    font = "default-game",
    alignment = "center",
    scale_with_zoom = false
  }

  local countdown_text = rendering.draw_text{
    text = " ",
    surface = surface,
    target = pole,
    target_offset = {5, -1.5},
    color = {r = 0.98, g = 0, b = 0},
    scale = 1.00,
    font = "default-game",
    alignment = "center",
    scale_with_zoom = false
  }
  silo.get_module_inventory().insert("effectivity-module-3")
  silo.rocket_parts = 100
  --silo.get_module_inventory().insert("effectivity-module-3")
  local combinator = surface.create_entity({name = "constant-combinator", position = {x = left_top.x + 11, y = left_top.y + 10}, force = "player", create_build_effect_smoke = false})
  local speaker = surface.create_entity({name = "programmable-speaker", position = {x = left_top.x + 11, y = left_top.y + 11}, force = "player", create_build_effect_smoke = false,
    parameters = {playback_volume = 0.6, playback_globally = true, allow_polyphony = false},
    alert_parameters = {show_alert = true, show_on_map = true, icon_signal_id = {type = "item", name = "atomic-bomb"}, alert_message = "Nuclear missile silo detected!" }})
  combinator.connect_neighbour({wire = defines.wire_type.green, target_entity = speaker})
  local rules = combinator.get_or_create_control_behavior()
  local rules2 = speaker.get_or_create_control_behavior()
  rules.set_signal(1, {signal = {type = "virtual", name = "signal-A"}, count = 1})
  rules2.circuit_condition = {condition = {first_signal = {type = "virtual", name = "signal-A"}, second_constant = 0, comparator = ">"}}
  rules2.circuit_parameters = {signal_value_is_pitch = false, instrument_id = 0, note_id = 6}
  local solar = surface.create_entity({name = "solar-panel", position = {x = left_top.x + 14, y = left_top.y + 10}, force = "scrapyard", create_build_effect_smoke = false})
  local acu = surface.create_entity({name = "accumulator", position = {x = left_top.x + 14, y = left_top.y + 8}, force = "scrapyard", create_build_effect_smoke = false})
  acu.energy = 5000000
  speaker.minable = false
  speaker.destructible = false
  speaker.operable = false
  combinator.minable = false
  combinator.destructible = false
  combinator.operable = false
  solar.destructible = false
  pole.destructible = false
  acu.destructible = false

  objective.dangers[#objective.dangers + 1] = {silo = silo, speaker = speaker, combinator = combinator, solar = solar,acu = acu, pole = pole, destroyed = false, text = silo_text, timer = countdown_text}
end

function Public_terrain.fish_market(surface, left_top)
  local objective = Chrono_table.get_table()
  local market = surface.create_entity({name = "market", force = "player", position = {x = left_top.x + 16, y = left_top.y + 16}})
  market.destructible = false
  market.operable = false
  market.minable = false
  rendering.draw_text{
    text = "Fish Market",
    surface = surface,
    target = market,
    target_offset = {0, -2.5},
    color = objective.locomotive.color,
    scale = 1.00,
    font = "default-game",
    alignment = "center",
    scale_with_zoom = false
  }
  local fishchest = surface.create_entity({name = "steel-chest", force = "player", position = {x = left_top.x + 11, y = left_top.y + 16}})
  fishchest.destructible = false
  fishchest.minable = false
  fishchest.operable = false
  objective.fishchest = fishchest
  rendering.draw_text{
    text = "Deposit fish here",
    surface = surface,
    target = fishchest,
    target_offset = {0, -2.5},
    color = objective.locomotive.color,
    scale = 0.75,
    font = "default-game",
    alignment = "center",
    scale_with_zoom = false
  }
  local inserter = surface.create_entity({name = "fast-inserter", force = "player", position = {x = left_top.x + 10, y = left_top.y + 16}, direction = defines.direction.west})
  inserter.destructible = false
  inserter.minable = false
  inserter.operable = false
  inserter.rotatable = false
  local track = surface.create_entity({name = "straight-rail", force = "player", position = {x = left_top.x + 8, y = left_top.y + 16}})
  track.destructible = false
  track.minable = false
end



return Public_terrain

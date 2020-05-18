local public = {}

public.player_ship_loot = {
   {
      name = "piercing-rounds-magazine",
      count = 35,
   },
   {
      name = "grenade",
      count = 2,
   },
   {
      name = "submachine-gun",
      count = 1,
   },
   {
      name = "light-armor",
      count = 1,
   },
   {
      name = "iron-plate",
      count = 30,
   },
   {
      name = "copper-plate",
      count = 10,
   },
   {
      name = "raw-fish",
      count = 2,
   },
   {
      name = "small-lamp",
      count = 1
   }
}

public.permission_orbit = {
   defines.input_action.activate_copy,
   defines.input_action.activate_cut,
   defines.input_action.activate_paste,
   defines.input_action.add_permission_group,
   defines.input_action.add_train_station,
   defines.input_action.admin_action,
   defines.input_action.alt_select_area,
   defines.input_action.alt_select_blueprint_entities,
   defines.input_action.alternative_copy,
   defines.input_action.begin_mining,
   defines.input_action.begin_mining_terrain,
   defines.input_action.build_item,
   defines.input_action.build_rail,
   defines.input_action.build_terrain,
   defines.input_action.cancel_craft,
   defines.input_action.cancel_deconstruct,
   defines.input_action.cancel_new_blueprint,
   defines.input_action.cancel_research,
   defines.input_action.cancel_upgrade,
   defines.input_action.change_active_item_group_for_crafting,
   defines.input_action.change_active_item_group_for_filters,
   defines.input_action.change_active_quick_bar,
   defines.input_action.change_arithmetic_combinator_parameters,
   defines.input_action.change_blueprint_book_record_label,
   defines.input_action.change_decider_combinator_parameters,
   defines.input_action.change_item_label,
   defines.input_action.change_multiplayer_config,
   defines.input_action.change_picking_state,
   defines.input_action.change_programmable_speaker_alert_parameters,
   defines.input_action.change_programmable_speaker_circuit_parameters,
   defines.input_action.change_programmable_speaker_parameters,
   defines.input_action.change_riding_state,
   defines.input_action.change_shooting_state,
   defines.input_action.change_single_blueprint_record_label,
   defines.input_action.change_train_stop_station,
   defines.input_action.change_train_wait_condition,
   defines.input_action.change_train_wait_condition_data,
   defines.input_action.clean_cursor_stack,
   defines.input_action.clear_selected_blueprint,
   defines.input_action.clear_selected_deconstruction_item,
   defines.input_action.clear_selected_upgrade_item,
   defines.input_action.connect_rolling_stock,
   defines.input_action.copy_entity_settings,
   defines.input_action.craft,
   defines.input_action.create_blueprint_like,
   defines.input_action.cursor_split,
   defines.input_action.cursor_transfer,
   defines.input_action.custom_input,
   defines.input_action.cycle_blueprint_book_backwards,
   defines.input_action.cycle_blueprint_book_forwards,
   defines.input_action.deconstruct,
   defines.input_action.delete_blueprint_library,
   defines.input_action.delete_blueprint_record,
   defines.input_action.delete_custom_tag,
   defines.input_action.delete_permission_group,
   defines.input_action.destroy_opened_item,
   defines.input_action.disconnect_rolling_stock,
   defines.input_action.drag_train_schedule,
   defines.input_action.drag_train_wait_condition,
   defines.input_action.drop_blueprint_record,
   defines.input_action.drop_item,
   defines.input_action.drop_to_blueprint_book,
   defines.input_action.edit_custom_tag,
   defines.input_action.edit_permission_group,
   defines.input_action.export_blueprint,
   defines.input_action.fast_entity_split,
   defines.input_action.fast_entity_transfer,
   defines.input_action.go_to_train_station,
   defines.input_action.grab_blueprint_record,
   defines.input_action.import_blueprint,
   defines.input_action.import_blueprint_string,
   defines.input_action.import_permissions_string,
   defines.input_action.inventory_split,
   defines.input_action.inventory_transfer,
   defines.input_action.launch_rocket,
   defines.input_action.lua_shortcut,
   defines.input_action.map_editor_action,
   defines.input_action.market_offer,
   defines.input_action.mod_settings_changed,
   defines.input_action.open_achievements_gui,
   defines.input_action.open_blueprint_library_gui,
   defines.input_action.open_blueprint_record,
   defines.input_action.open_bonus_gui,
   defines.input_action.open_character_gui,
   defines.input_action.open_equipment,
   defines.input_action.open_gui,
   defines.input_action.open_item,
   defines.input_action.open_kills_gui,
   defines.input_action.open_logistic_gui,
   defines.input_action.open_mod_item,
   defines.input_action.open_production_gui,
   defines.input_action.open_technology_gui,
   defines.input_action.open_train_gui,
   defines.input_action.open_train_station_gui,
   defines.input_action.open_trains_gui,
   defines.input_action.open_tutorials_gui,
   defines.input_action.paste_entity_settings,
   defines.input_action.place_equipment,
   defines.input_action.quick_bar_pick_slot,
   defines.input_action.quick_bar_set_selected_page,
   defines.input_action.quick_bar_set_slot,
   defines.input_action.remove_cables,
   defines.input_action.remove_train_station,
   defines.input_action.reset_assembling_machine,
   defines.input_action.rotate_entity,
   defines.input_action.select_area,
   defines.input_action.select_blueprint_entities,
   defines.input_action.select_entity_slot,
   defines.input_action.select_item,
   defines.input_action.select_mapper_slot,
   defines.input_action.select_next_valid_gun,
   defines.input_action.select_tile_slot,
   defines.input_action.set_auto_launch_rocket,
   defines.input_action.set_autosort_inventory,
   defines.input_action.set_behavior_mode,
   defines.input_action.set_car_weapons_control,
   defines.input_action.set_circuit_condition,
   defines.input_action.set_circuit_mode_of_operation,
   defines.input_action.set_deconstruction_item_tile_selection_mode,
   defines.input_action.set_deconstruction_item_trees_and_rocks_only,
   defines.input_action.set_entity_color,
   defines.input_action.set_entity_energy_property,
   defines.input_action.set_filter,
   defines.input_action.set_heat_interface_mode,
   defines.input_action.set_heat_interface_temperature,
   defines.input_action.set_infinity_container_filter_item,
   defines.input_action.set_infinity_container_remove_unfiltered_items,
   defines.input_action.set_infinity_pipe_filter,
   defines.input_action.set_inserter_max_stack_size,
   defines.input_action.set_inventory_bar,
   defines.input_action.set_logistic_filter_item,
   defines.input_action.set_logistic_filter_signal,
   defines.input_action.set_logistic_trash_filter_item,
   defines.input_action.set_request_from_buffers,
   defines.input_action.set_research_finished_stops_game,
   defines.input_action.set_signal,
   defines.input_action.set_single_blueprint_record_icon,
   defines.input_action.set_splitter_priority,
   defines.input_action.set_train_stopped,
   defines.input_action.setup_assembling_machine,
   defines.input_action.setup_blueprint,
   defines.input_action.setup_single_blueprint_record,
   defines.input_action.smart_pipette,
   defines.input_action.stack_split,
   defines.input_action.stack_transfer,
   defines.input_action.start_repair,
   defines.input_action.start_research,
   defines.input_action.stop_building_by_moving,
   defines.input_action.switch_connect_to_logistic_network,
   defines.input_action.switch_constant_combinator_state,
   defines.input_action.switch_inserter_filter_mode_state,
   defines.input_action.switch_power_switch_state,
   defines.input_action.switch_to_rename_stop_gui,
   defines.input_action.take_equipment,
   defines.input_action.toggle_deconstruction_item_entity_filter_mode,
   defines.input_action.toggle_deconstruction_item_tile_filter_mode,
   defines.input_action.toggle_driving,
   defines.input_action.toggle_enable_vehicle_logistics_while_moving,
   defines.input_action.toggle_equipment_movement_bonus,
   defines.input_action.toggle_map_editor,
   defines.input_action.toggle_personal_roboport,
   defines.input_action.toggle_show_entity_info,
   defines.input_action.translate_string,
   defines.input_action.undo,
   defines.input_action.upgrade,
   defines.input_action.upgrade_opened_blueprint,
   defines.input_action.use_artillery_remote,
   defines.input_action.use_item,
   defines.input_action.wire_dragging,
}

public.self_explode = 60 * 60 * 10
public.claim_markers = {
   "gun-turret",
   "laser-turret",
   "stone-wall",
}
public.claim_max_distance = 15
public.base_costs = {
   ["gun-turret"] = 1,
   ["laser-turret"] = 5,
   ["stone-wall"] = 0.1,
}
public.raid_costs = {
   {
      cost = 1,
      chance = 300,
      gear = {
         {
            weap = "shotgun",
            ammo = "shotgun-shell",
            armor = "light-armor"
         },
         {
            weap = "pistol",
            ammo = "firearm-magazine",
            armor = "light-armor"
         }
      }
   },
   {
      cost = 15,
      chance = 150,
      gear = {
         {
            weap = "shotgun",
            ammo = "shotgun-shell",
            armor = "light-armor"
         },
         {
            weap = "pistol",
            ammo = "firearm-magazine",
            armor = "light-armor"
         }
      }
   },
   {
      cost = 30,
      chance = 100,
      gear = {
         {
            weap = "shotgun",
            ammo = "shotgun-shell",
            armor = "light-armor"
         },
         {
            weap = "pistol",
            ammo = "firearm-magazine",
            armor = "light-armor"
         }
      }
   },
   {
      cost = 40,
      chance = 100,
      gear = {
         {
            weap = "shotgun",
            ammo = "shotgun-shell",
            armor = "heavy-armor"
         },
         {
            weap = "pistol",
            ammo = "firearm-magazine",
            armor = "heavy-armor"
         }
      }
   },
   {
      cost = 70,
      chance = 100,
      gear = {
         {
            weap = "shotgun",
            ammo = "piercing-shotgun-shell",
            armor = "heavy-armor"
         },
         {
            weap = "pistol",
            ammo = "piercing-rounds-magazine",
            armor = "heavy-armor"
         }
      }
   },
}

public.wreck_loot = {
   ["iron-plate"] = {
      rare = 0.1,
      count = { 20, 40 },
   },
   ["copper-plate"] = {
      rare = 0.1,
      count = { 10, 30 },
   },
   ["empty-barrel"] = {
      rare = 0.4,
      count = { 1, 1},
   },
   ["copper-cable"] = {
      rare = 0.5,
      count = { 5, 20 },
   },
   ["electronic-circuit"] = {
      rare = 0.6,
      count = { 5, 20 },
   },
   ["firearm-magazine"] = {
      rare = 0.4,
      count = { 1, 2 },
   },
   ["steel-plate"] = {
      rare = 0.8,
      count = { 1, 5 },
   },
   ["explosives"] = {
      rare = 0.85,
      count = { 1, 5 },
   },
   ["advanced-circuit"] = {
      rare = 0.9,
      count = { 1, 5 },
   },
   ["processing-unit"] = {
      rare = 0.95,
      count = { 1, 2 },
   },
   ["electric-engine-unit"] = {
      rare = 0.95,
      count = { 1, 1 },
   },
   ["battery"] = {
      rare = 0.95,
      count = { 1, 2 },
   },
   ["piercing-rounds-magazine"] = {
      rare = 0.99,
      count = { 1, 2 },
   },
}

public.technologies = {
   ["military"] = true,
   ["artillery"] = false,
   ["artillery-shell-range-1"] = false,
   ["artillery-shell-speed-1"] = false,
   ["automation-3"] = false,
   ["battery-equipment"] = false,
   ["battery-mk2-equipment"] = false,
   ["belt-immunity-equipment"] = false,
   ["combat-robotics-2"] = false,
   ["combat-robotics-3"] = false,
   ["discharge-defense-equipment"] = false,
   ["energy-shield-equipment"] = false,
   ["energy-shield-mk2-equipment"] = false,
   ["exoskeleton-equipment"] = false,
   ["explosive-rocketry"] = false,
   ["flamethrower"] = false,
   ["fusion-reactor-equipment"] = false,
   ["kovarex-enrichment-process"] = false,
   ["land-mine"] = false,
   ["logistics-3"] = false,
   ["military-4"] = false,
   ["modular-armor"] = false,
   ["night-vision-equipment"] = false,
   ["nuclear-fuel-reprocessing"] = false,
   ["nuclear-power"] = false,
   ["personal-laser-defense-equipment"] = false,
   ["personal-roboport-equipment"] = false,
   ["personal-roboport-mk2-equipment"] = false,
   ["power-armor"] = false,
   ["power-armor-mk2"] = false,
   ["refined-flammables-1"] = false,
   ["refined-flammables-2"] = false,
   ["refined-flammables-3"] = false,
   ["refined-flammables-4"] = false,
   ["refined-flammables-5"] = false,
   ["refined-flammables-6"] = false,
   ["refined-flammables-7"] = false,
   ["rocketry"] = false,
   ["solar-panel-equipment"] = false,
   ["stack-inserter"] = false,
   ["stronger-explosives-2"] = false,
   ["stronger-explosives-3"] = false,
   ["stronger-explosives-4"] = false,
   ["stronger-explosives-5"] = false,
   ["stronger-explosives-6"] = false,
   ["stronger-explosives-7"] = false,
   ["physical-projectile-damage-4"] = false,
   ["physical-projectile-damage-5"] = false,
   ["physical-projectile-damage-6"] = false,
   ["physical-projectile-damage-7"] = false,
   ["weapon-shooting-speed-4"] = false,
   ["weapon-shooting-speed-5"] = false,
   ["weapon-shooting-speed-6"] = false,
   ["energy-weapons-damage-1"] = false,
   ["energy-weapons-damage-2"] = false,
   ["energy-weapons-damage-3"] = false,
   ["energy-weapons-damage-4"] = false,
   ["energy-weapons-damage-5"] = false,
   ["energy-weapons-damage-6"] = false,
   ["energy-weapons-damage-7"] = false,
   ["laser-turret-speed-2"] = false,
   ["laser-turret-speed-3"] = false,
   ["laser-turret-speed-4"] = false,
   ["laser-turret-speed-5"] = false,
   ["laser-turret-speed-6"] = false,
   ["laser-turret-speed-7"] = false,
   ["follower-robot-count-2"] = false,
   ["follower-robot-count-3"] = false,
   ["follower-robot-count-4"] = false,
   ["follower-robot-count-5"] = false,
   ["follower-robot-count-6"] = false,
   ["follower-robot-count-7"] = false,
   ["tanks"] = false,
   ["uranium-ammo"] = false,
   ["uranium-processing"] = false,
   ["atomic-bomb"] = false,
}

public.merchant_offer = {
   {
      price = {
         {
            type = "item",
            name = "iron-plate",
            amount = 10
         },
         {
            type = "item",
            name = "advanced-circuit",
            amount = 2
         },
         {
            type = "item",
            name = "battery",
            amount = 2
         },
         {
            type = "item",
            name = "small-lamp",
            amount = 2
         },
         {
            type = "item",
            name = "copper-cable",
            amount = 5
         },
         {
            type = "item",
            name = "steel-plate",
            amount = 1
         },
      },
      offer = {
         type = "nothing",
         effect_description = "Construct a GPS receiver"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 100
         }
      },
      offer = {
         type = "give-item",
         item = "heavy-armor"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 500
         }
      },
      offer = {
         type = "give-item",
         item = "modular-armor"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 12000
         }
      },
      offer = {
         type = "give-item",
         item = "power-armor"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 100
         }
      },
      offer = {
         type = "give-item",
         item = "night-vision-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 70
         }
      },
      offer = {
         type = "give-item",
         item = "battery-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 700
         }
      },
      offer = {
         type = "give-item",
         item = "battery-mk2-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 1200
         }
      },
      offer = {
         type = "give-item",
         item = "exoskeleton-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 2500
         }
      },
      offer = {
         type = "give-item",
         item = "fusion-reactor-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 200
         }
      },
      offer = {
         type = "give-item",
         item = "personal-roboport-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 400
         }
      },
      offer = {
         type = "give-item",
         item = "personal-roboport-mk2-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 90
         }
      },
      offer = {
         type = "give-item",
         item = "solar-panel-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 300
         }
      },
      offer = {
         type = "give-item",
         item = "energy-shield-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 2000
         }
      },
      offer = {
         type = "give-item",
         item = "energy-shield-mk2-equipment"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 50
         }
      },
      offer = {
         type = "give-item",
         item = "flamethrower-ammo"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 1
         }
      },
      offer = {
         type = "give-item",
         item = "firearm-magazine"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 5
         }
      },
      offer = {
         type = "give-item",
         item = "piercing-rounds-magazine"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 1000
         }
      },
      offer = {
         type = "unlock-recipe",
         recipe = "flamethrower"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 50
         }
      },
      offer = {
         type = "give-item",
         item = "defender-capsule"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 200
         }
      },
      offer = {
         type = "give-item",
         item = "distractor-capsule"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 250
         }
      },
      offer = {
         type = "give-item",
         item = "destroyer-capsule"
      }
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 70
         }
      },
      offer = {
         type = "unlock-recipe",
         recipe = "filter-inserter"
      },
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 100
         }
      },
      offer = {
         type = "unlock-recipe",
         recipe = "stack-inserter"
      },
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 170
         }
      },
      offer = {
         type = "unlock-recipe",
         recipe = "stack-filter-inserter"
      },
   },
   {
      price = {
         {
            type = "item",
            name = "coin",
            amount = 65000
         }
      },
      offer = {
         type = "give-item",
         item = "computer"
      }
   },
}

public.manual = [[
[font=heading-1]Planet Prison (1.1.0) - Manual[/font]
[font=default-bold]You did naughty things and was sent to this planet with a one way ticket. Once an industrial site, turned into non-hospitable planet due to pollution and war. Among other inmates, there are still bandits scavenging through the junk looking for rare items.

This is an ultimate survival scenario with very hostile environment.
- You die, you lose everything.
- You leave, you lose everything.
- Technology cost is 10x lower.
- The merchant is a gateway to PvP.
- Flee by a rocket is a win. (Put a car into a rocket and enter the rocket).
- The light is your best friend.
[/font]
[font=heading-1]NAP contractors (A non-aggression pact)[/font]
[font=default-bold]Grab a raw fish [img=item/raw-fish] and drop it on someone with [virtual-signal=signal-Z] button (in default setting). This way you request an inmate to get in NAP with you.[/font]
[font=default-bold]Grab a coal piece [img=item/coal] and drop it on someone with [virtual-signal=signal-Z] button (in default setting). This way you discard NAP with an inname.[/font]

[font=heading-1]Coins[/font]
[font=default-bold]Coins [img=item/coin] are the main medium that you use in the market. You obtain them by researching stuff and pvp activites.[/font]

[font=heading-1]Other[/font]
[font=default-bold]This scenario was made by cogito123. If you find any bugs/balancing issues, report it to getcomfy.eu/discord. Thanks for playing this map.[/font]
]]

return public

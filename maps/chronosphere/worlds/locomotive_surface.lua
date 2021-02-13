local Balance = require 'maps.chronosphere.balance'
local Chrono_table = require 'maps.chronosphere.table'
local Factories = require 'maps.chronosphere.production'
local Upgrades = require "maps.chronosphere.upgrade_list"
local List = require 'maps.chronosphere.production_list'
local math_floor = math.floor
local math_random = math.random

local Public = {}

local function protect(entity, operable)
  entity.minable = false
  entity.destructible = false
  entity.operable = operable
end

function Public.create_wagon_room()
	local objective = Chrono_table.get_table()
	local width = 64
	local height = 384
	objective.comfychests2 = {}
	objective.accumulators = {}
	local map_gen_settings = {
		["width"] = width,
		["height"] = height + 128,
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = true,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = true},
			["decorative"] = {treat_missing_as_default = false},
		},
	}
	if not game.surfaces["cargo_wagon"] then game.create_surface("cargo_wagon", map_gen_settings) end
	local surface = game.surfaces["cargo_wagon"]
	surface.freeze_daytime = true
	surface.daytime = 0.1
	surface.request_to_generate_chunks({0,0}, 12)
	surface.force_generate_chunk_requests()
  local tiles = {}
	local carfpos = {
		[1]={x=-33,y=-127},[2]={x=-33,y=-128},[3]={x=-33,y=-129},[4]={x=-33,y=-130},[5]={x=32,y=-127},[6]={x=32,y=-128},[7]={x=32,y=-129},[8]={x=32,y=-130},
		[9]={x=-33,y=-2},[10]={x=-33,y=-1},[11]={x=-33,y=0},[12]={x=-33,y=1},[13]={x=32,y=-2},[14]={x=32,y=-1},[15]={x=32,y=0},[16]={x=32,y=1},
		[17]={x=-33,y=126},[18]={x=-33,y=127},[19]={x=-33,y=128},[20]={x=-33,y=129},[21]={x=32,y=126},[22]={x=32,y=127},[23]={x=32,y=128},[24]={x=32,y=129}
	}
	for i = 1, 24, 1 do
		tiles[#tiles + 1] = {name = "tutorial-grid", position = {carfpos[i].x,carfpos[i].y}}
	end

	for x = width * -0.5, width * 0.5 - 1, 1 do
		for y = height * 0.5, height * 0.7, 1 do
			tiles[#tiles + 1] = {name = "out-of-map", position = {x,y}}
		end
		for y = height * -0.7, height * -0.5, 1 do
			tiles[#tiles + 1] = {name = "out-of-map", position = {x,y}}
		end
		for y = height * -0.5 + 3, height * 0.5 - 4, 1 do
			tiles[#tiles + 1] = {name = "tutorial-grid", position = {x,y}}
		end
		for y = height * -0.16 - 5, height * -0.16 + 0, 1 do
			tiles[#tiles + 1] = {name = "out-of-map", position = {x,y}}
		end
		for y = height * 0.16 - 0, height * 0.16 + 5, 1 do
			tiles[#tiles + 1] = {name = "out-of-map", position = {x,y}}
		end
		for y = height * -0.5, height * -0.5 + 2, 1 do
			tiles[#tiles + 1] = {name = "out-of-map", position = {x,y}}
		end
		for y = height * 0.5 - 3, height * 0.5, 1 do
			tiles[#tiles + 1] = {name = "out-of-map", position = {x,y}}
		end
	end
	for x = width * -0.2 + 1, width * 0.2 - 1, 1 do
		for y = height * -0.16 - 5, height * -0.16 + 0, 1 do
			tiles[#tiles + 1] = {name = "tutorial-grid", position = {x,y}}
		end
		for y = height * 0.16 -0, height * 0.16 + 5, 1 do
			tiles[#tiles + 1] = {name = "tutorial-grid", position = {x,y}}
		end
		--for y = height * -0.5 -5, height * -0.5 + 3, 1 do
		--	tiles[#tiles + 1] = {name = "tutorial-grid", position = {x,y}}
		--end
	end

	for x = width * -0.5 + 5, width * 0.5 - 6, 1 do
		for y = height * -0.7 + 18, height * -0.5 - 5, 1 do
			tiles[#tiles + 1] = {name = "tutorial-grid", position = {x,y}}
		end
	end

	for x = width * -0.5 - 6, width * -0.5 + 3, 1 do -- combinators
		for y = -251, -241, 1 do
			tiles[#tiles + 1] = {name = "tutorial-grid", position = {x,y}}
		end
	end
  surface.set_tiles(tiles)
  local water_tiles = {}

	for x = width * -0.4 + 6, width * 0.4 - 6, 1 do
		for y = height * -0.5 + 7, height * -0.5 + 10, 1 do
			water_tiles[#water_tiles + 1] = {name = "water", position = {x,y}}
			--surface.set_tiles({{name = "water", position = p}})
			if math_random(1, 3) == 1 and (x ~= width * -0.4 + 6) and (y ~= height * -0.5 + 7) then surface.create_entity({name = "fish", position = {x,y}}) end
		end
	end
  surface.set_tiles(water_tiles)

	local combinators = {}
	for x = width * -0.5 - 6, width * -0.5 + 3, 1 do
		for y = -250, -244, 2 do
			combinators[#combinators + 1] = {name = "arithmetic-combinator", position = {x, y}, force = "player", create_build_effect_smoke = false}
		end
	end
	local combimade = {}
	for i = 1, #combinators, 1 do
		combimade[i] = surface.create_entity(combinators[i])
    protect(combimade[i], false)

		if i > 1 then
			combimade[i].connect_neighbour({wire = defines.wire_type.green, target_entity = combimade[i - 1], source_circuit_id =  2, target_circuit_id = 1})
			local rule = combimade[i].get_or_create_control_behavior()
			rule.parameters = {first_signal = {type = "virtual", name = "signal-A"}, second_constant = 0, operation = "+", output_signal = {type = "virtual", name = "signal-A"}}
		else
			local rule2 = combimade[i].get_or_create_control_behavior()
			rule2.parameters =  {first_signal = {type = "virtual", name = "signal-A"}, second_constant = 0, operation = "+", output_signal = {type = "virtual", name = "signal-B"}}
		end
	end
	local checker = surface.create_entity({name = "decider-combinator", position = {x = width * -0.5 - 6, y = -242}, force = "player", create_build_effect_smoke = false })
	local rules3 = checker.get_or_create_control_behavior()
	rules3.parameters = {first_signal = {type = "virtual", name = "signal-A"}, second_signal = {type = "virtual", name = "signal-B"}, comparator = ">",
		output_signal = {type = "virtual", name = "signal-C"}, copy_count_from_input = false }
	local combipower = surface.create_entity({name = "substation", position = {x = width * -0.5 - 4, y = -242}, force="player", create_build_effect_smoke = false})
	combipower.connect_neighbour({wire = defines.wire_type.green, target_entity = checker, target_circuit_id = 1})
	combipower.connect_neighbour({wire = defines.wire_type.green, target_entity = combimade[#combimade], target_circuit_id = 1})
	combimade[1].connect_neighbour({wire = defines.wire_type.green, target_entity = checker, source_circuit_id =  2, target_circuit_id = 1})
	local speaker = surface.create_entity({name = "programmable-speaker", position = {x = width * -0.5 - 6, y = -241}, force = "player", create_build_effect_smoke = false,
		parameters = {playback_volume = 0.6, playback_globally = true, allow_polyphony = false},
		alert_parameters = {show_alert = true, show_on_map = true, icon_signal_id = {type = "item", name = "accumulator"}, alert_message = "Train Is Charging!" }})
	speaker.connect_neighbour({wire = defines.wire_type.green, target_entity = checker, target_circuit_id = 2})
	local rules4 = speaker.get_or_create_control_behavior()
	rules4.circuit_condition = {condition = {first_signal = {type = "virtual", name = "signal-C"}, second_constant = 0, comparator = ">"}}
	rules4.circuit_parameters = {signal_value_is_pitch = false, instrument_id = 8, note_id = 5}
	local solar1 = surface.create_entity({name = "solar-panel", position = {x = width * -0.5 - 2, y = -242}, force="player", create_build_effect_smoke = false})
	local solar2 = surface.create_entity({name = "solar-panel", position = {x = width * -0.5 + 1, y = -242}, force="player", create_build_effect_smoke = false})
  protect(solar1, true)
  protect(solar2, true)
  protect(combipower, false)
  protect(speaker, false)
  protect(checker, false)

	for k, x in pairs({-1, 0}) do
		for i = 1, 12, 1 do
			local step = math_floor((i-1)/4)
			local y = -131 + i + step * 128 - step * 4
			local e = surface.create_entity({name = "red-chest", position = {x,y}, force = "player", create_build_effect_smoke = false})
      protect(e, true)
      --e.link_id = 1000 + i + 12 * (k - 1)
			table.insert(objective.comfychests2, e)
		end
	end

	for i = 1, 9, 1 do
		local y = -0.7 * height + 18 + 9 + 18 * ( math_floor((i - 1) / 3))
		local x = -0.5 * width + 5 + 9 + 18 * ( i%3 )
		local substation = surface.create_entity({name = "substation", position = {x,y}, force="player", create_build_effect_smoke = false})
		if i == 3 then
			substation.disconnect_neighbour(combipower)
			substation.connect_neighbour({wire = defines.wire_type.green, target_entity = combipower})
		end
    protect(substation, true)
		for j = 1, 4, 1 do
			local xx = x - 2 * j
			local acumulator = surface.create_entity({name = "accumulator", position = {xx,y}, force="player", create_build_effect_smoke = false})
			if i == 3 and j == 1 then
				acumulator.connect_neighbour({wire = defines.wire_type.green, target_entity = substation})
			end
      protect(acumulator, true)
			table.insert(objective.accumulators, acumulator)
		end
		for k = 1, 4, 1 do
			local xx = x + 2 * k
			local acumulator = surface.create_entity({name = "accumulator", position = {xx,y}, force="player", create_build_effect_smoke = false})
			protect(acumulator, true)
			table.insert(objective.accumulators, acumulator)
		end
	end

	local powerpole = surface.create_entity({name = "big-electric-pole", position = {0, height * -0.5 }, force="player", create_build_effect_smoke = false})
  protect(powerpole, false)
  local laser_battery = surface.create_entity({name = "accumulator", position = {-31, height * -0.5 + 4}, force="player", create_build_effect_smoke = false})
  protect(laser_battery, true)
  objective.laser_battery = laser_battery
  rendering.draw_text{
    text = {"chronosphere.train_laser_battery"},
    surface = surface,
    target = laser_battery,
    target_offset = {0, -2.5},
    color = objective.locomotive.color,
    scale = 1.00,
    font = "default-game",
    alignment = "center",
    scale_with_zoom = false
  }

	local market = surface.create_entity({name = "market", position = {-28, height * -0.5 + 4}, force="neutral", create_build_effect_smoke = false})
  protect(market, true)
  local repairchest = surface.create_entity({name = "blue-chest", position = {-24, height * -0.5 + 3}, force = "player"})
  protect(repairchest, true)
  objective.upgradechest[0] = repairchest
  rendering.draw_text{
    text = {"chronosphere.train_repair_chest"},
    surface = surface,
    target = repairchest,
    target_offset = {0, -2.5},
    color = objective.locomotive.color,
    scale = 1.00,
    font = "default-game",
    alignment = "center",
    scale_with_zoom = false
  }
  local upgrades = Upgrades.upgrades()
  for i = 1, #upgrades, 1 do
    local e = surface.create_entity({name = "blue-chest", position = {-21 + i, height * -0.5 + 3}, force = "player"})
    protect(e, true)
    objective.upgradechest[i] = e
    rendering.draw_sprite{
      sprite = upgrades[i].sprite,
      surface = surface,
      target = e,
      target_offset = {0, -1.3},
      font = "default-game",
      visible = true
    }
  end

	local market1_text = rendering.draw_text{
		text = {"chronosphere.train_market"},
		surface = surface,
		target = market,
		target_offset = {0, -3.5},
		color = objective.locomotive.color,
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	local upgrade_text = rendering.draw_text{
		text = {"chronosphere.train_upgrades"},
		surface = surface,
		target = objective.upgradechest[8],
		target_offset = {0, -3.5},
		color = objective.locomotive.color,
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	local upgrade_sub_text = rendering.draw_text{
		text = {"chronosphere.train_upgrades_sub"},
		surface = surface,
		target = objective.upgradechest[8],
		target_offset = {0, -2.5},
		color = objective.locomotive.color,
		scale = 0.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}


	for _, offer in pairs(Balance.market_offers()) do market.add_market_item(offer) end

	--generate cars--
	local car_pos = {
		{x = width * -0.5 - 1.4, y = -128},
		{x = width * -0.5 - 1.4, y = 0},
		{x = width * -0.5 - 1.4, y = 128},
		{x = width * 0.5 + 1.4, y = -128},
		{x = width * 0.5 + 1.4, y = 0},
		{x = width * 0.5 + 1.4, y = 128}
	}
	objective.car_exits = {}
	for i = 1, 6, 1 do
		local e = surface.create_entity({name = "car", position = car_pos[i], force = "player", create_build_effect_smoke = false})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 16})
    protect(e, false)
		objective.car_exits[i] = e
	end

	--generate chests inside south wagon--
	local positions = {}
	for x = width * -0.5 + 2, width * 0.5 - 1, 1 do
		if x == -1 then x = x - 1 end
		if x == 0 then x = x + 1 end
		for y = 68, height * 0.5 - 7, 1 do
			positions[#positions + 1] = {x = x, y = y}
		end
	end
	table.shuffle_table(positions)

	local cargo_boxes = Balance.initial_cargo_boxes()

	local i = 1
	for _ = 1, 16, 1 do
		if not positions[i] then break end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		local inventory = e.get_inventory(defines.inventory.chest)
		inventory.insert({name = "raw-fish", count = math_random(2, 5)})
		i = i + 1
	end

	for _ = 1, 24, 1 do
		if not positions[i] then break end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		i = i + 1
	end

	for loot_i = 1, #cargo_boxes, 1 do
		if not positions[i] then
			log("ran out of cargo box positions")
			break
		end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		local inventory = e.get_inventory(defines.inventory.chest)
		inventory.insert(cargo_boxes[loot_i])
		i = i + 1
	end
  local factory = "assembling-machine-2"
  for key = 1, 20, 1 do
    if List[key].kind == "furnace" then factory = "electric-furnace" else factory = "assembling-machine-2" end
    local position = {x = -32 + key * 3, y = height * 0.5 - 5}
    local e = surface.create_entity({name = factory, force = "player", position = position})
    e.active = false
    protect(e, false)
    e.rotatable = false
    Factories.register_train_assembler(e, key)
    if List[key].kind == "assembler" or List[key].kind == "fluid-assembler" then
      e.set_recipe(List[key].recipe_override or List[key].name)
      e.recipe_locked = true
      e.direction = defines.direction.south
    end
  end
end

return Public

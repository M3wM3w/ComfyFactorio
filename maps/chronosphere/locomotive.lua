local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Public = {}
local Upgrades = require "maps.chronosphere.upgrade_list"
local math_floor = math.floor
local math_random = math.random
local function math_sgn(x)
  return (x<0 and -1) or 1
end

function Public.locomotive_spawn(surface, position, wagons)
	surface.request_to_generate_chunks(position, 0.5)
	surface.force_generate_chunk_requests()
	local objective = Chrono_table.get_table()
	if objective.planet[1].type.id == 17 then --fish market
		position.x = position.x - 960
		position.y = position.y - 64
	end
	for y = -10, 18, 2 do
		local rail = {name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0}
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	objective.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -6}, force = "player"})
	objective.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})
	for i = 1, 3, 1 do
		objective.locomotive_cargo[i] = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + math_floor((i - 1) * 6.5)}, force = "player"})
		local inv = objective.locomotive_cargo[i].get_inventory(defines.inventory.cargo_wagon)
		if wagons[i].bar > 0 then inv.set_bar(wagons[i].bar) end
		for ii = 1, 40, 1 do
			inv.set_filter(ii, wagons[i].filters[ii])
      if wagons[i].inventory[ii] then
        inv.insert(wagons[i].inventory[ii])
      end
		end
		objective.locomotive_cargo[i].minable = false
	end
	objective.locomotive_cargo[1].operable = false
	objective.locomotive.color = {0, 255, 0}
	objective.locomotive.minable = false

	--if not objective.comfychests then objective.comfychests = {} end
	--if not objective.accumulators then objective.accumulators = {} end
	for i = 1, 24, 1 do
		local yi = 0
		local xi = 5
		if i > 20 then
		 	yi = 6 - 12
			xi = 5
		elseif i > 16 then
		 	yi = 6 - 15
			xi = 5
		elseif i > 12 then
		 	xi = 5
		  yi = 6 - 18
		elseif i > 8 then
		 	yi = 6
		 	xi = 0
		elseif i > 4 then
		 	yi = 3
		 	xi = 0
		else
		 	yi = 0
		 	xi = 0
		end

		local comfychest = surface.create_entity({name = "steel-chest", position = {position.x - 2 + xi, position.y - 2 + yi + i}, force = "player"})
		comfychest.minable = false
		--comfychest.destructible = false
		if not objective.comfychests[i] then
			table.insert(objective.comfychests, comfychest)
		else
			objective.comfychests[i] = comfychest
		end
	end
	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = objective.locomotive,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = objective.locomotive_cargo[3],
		surface = surface, visible = true, only_in_alt_mode = false,
	})


end


function Public.fish_tag()
	local objective = Chrono_table.get_table()
	if not objective.locomotive_cargo[1] then return end
	local cargo = objective.locomotive_cargo[1]
	if not cargo.valid then return end
	if not cargo.surface then return end
	if not cargo.surface.valid then return end
	if objective.locomotive_tag then
		if objective.locomotive_tag.valid then
			if objective.locomotive_tag.position.x == cargo.position.x and objective.locomotive_tag.position.y == cargo.position.y then return end
			objective.locomotive_tag.destroy()
		end
	end
	objective.locomotive_tag = cargo.force.add_chart_tag(
		cargo.surface,
		{icon = {type = 'item', name = 'raw-fish'},
		position = cargo.position,
		text = " "
	})
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
	local carfpos = {
		[1]={x=-33,y=-127},[2]={x=-33,y=-128},[3]={x=-33,y=-129},[4]={x=-33,y=-130},[5]={x=32,y=-127},[6]={x=32,y=-128},[7]={x=32,y=-129},[8]={x=32,y=-130},
		[9]={x=-33,y=-2},[10]={x=-33,y=-1},[11]={x=-33,y=0},[12]={x=-33,y=1},[13]={x=32,y=-2},[14]={x=32,y=-1},[15]={x=32,y=0},[16]={x=32,y=1},
		[17]={x=-33,y=126},[18]={x=-33,y=127},[19]={x=-33,y=128},[20]={x=-33,y=129},[21]={x=32,y=126},[22]={x=32,y=127},[23]={x=32,y=128},[24]={x=32,y=129}
	}
	for i = 1, 24, 1 do
		surface.set_tiles({{name = "tutorial-grid", position = {carfpos[i].x,carfpos[i].y}}})
	end

	for x = width * -0.5, width * 0.5 - 1, 1 do
		for y = height * 0.5, height * 0.7, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * -0.7, height * -0.5, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * -0.5 + 3, height * 0.5 - 4, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
		for y = height * -0.16 - 5, height * -0.16 + 0, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * 0.16 - 0, height * 0.16 + 5, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * -0.5, height * -0.5 + 2, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
		for y = height * 0.5 - 3, height * 0.5, 1 do
			surface.set_tiles({{name = "out-of-map", position = {x,y}}})
		end
	end
	for x = width * -0.2 + 1, width * 0.2 - 1, 1 do
		for y = height * -0.16 - 5, height * -0.16 + 0, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
		for y = height * 0.16 -0, height * 0.16 + 5, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
		--for y = height * -0.5 -5, height * -0.5 + 3, 1 do
		--	surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		--end
	end

	for x = width * -0.5 + 5, width * 0.5 - 6, 1 do
		for y = height * -0.7 + 18, height * -0.5 - 5, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
	end

	for x = width * -0.5 - 6, width * -0.5 + 3, 1 do -- combinators
		for y = -251, -241, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
		end
	end

	for x = width * -0.4 + 6, width * 0.4 - 6, 1 do
		for y = height * -0.5 + 7, height * -0.5 + 10, 1 do
			local p = {x,y}
			surface.set_tiles({{name = "water", position = p}})
			if math_random(1, 3) == 1 and (x ~= width * -0.4 + 6) and (y ~= height * -0.5 + 7) then surface.create_entity({name = "fish", position = p}) end
		end
	end

	local combinators = {}
	for x = width * -0.5 - 6, width * -0.5 + 3, 1 do
		for y = -250, -244, 2 do
			combinators[#combinators + 1] = {name = "arithmetic-combinator", position = {x, y}, force = "player", create_build_effect_smoke = false}
		end
	end
	local combimade = {}
	for i = 1, #combinators, 1 do
		combimade[i] = surface.create_entity(combinators[i])
		combimade[i].minable = false
		combimade[i].destructible = false
		combimade[i].operable = false

		if i > 1 then
			combimade[i].connect_neighbour({wire = defines.wire_type.green, target_entity = combimade[i - 1], source_circuit_id =  2, target_circuit_id = 1})
			local rule = combimade[i].get_or_create_control_behavior()
			rule.parameters = {parameters = {first_signal = {type = "virtual", name = "signal-A"}, second_constant = 0, operation = "+", output_signal = {type = "virtual", name = "signal-A"}}}
		else
			local rule2 = combimade[i].get_or_create_control_behavior()
			rule2.parameters =  {parameters = {first_signal = {type = "virtual", name = "signal-A"}, second_constant = 0, operation = "+", output_signal = {type = "virtual", name = "signal-B"}}}
		end
	end
	local checker = surface.create_entity({name = "decider-combinator", position = {x = width * -0.5 - 6, y = -242}, force = "player", create_build_effect_smoke = false })
		local rules3 = checker.get_or_create_control_behavior()
		rules3.parameters = {parameters = {first_signal = {type = "virtual", name = "signal-A"}, second_signal = {type = "virtual", name = "signal-B"}, comparator = ">",
		output_signal = {type = "virtual", name = "signal-C"}, copy_count_from_input = false }}
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
	solar1.destructible = false
	solar1.minable = false
	solar2.destructible = false
	solar2.minable = false
	combipower.destructible = false
	combipower.minable = false
	combipower.operable = false
	speaker.destructible = false
	speaker.minable = false
	speaker.operable = false
	checker.destructible = false
	checker.minable = false
	checker.operable = false



	for _, x in pairs({-1, 0}) do
		for i = 1, 12, 1 do
			local step = math_floor((i-1)/4)
			local y = -131 + i + step * 128 - step * 4
			local e = surface.create_entity({name = "steel-chest", position = {x,y}, force = "player", create_build_effect_smoke = false})
			e.destructible = false
			e.minable = false
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
		substation.minable = false
		substation.destructible = false
		for j = 1, 4, 1 do
			local xx = x - 2 * j
			local acumulator = surface.create_entity({name = "accumulator", position = {xx,y}, force="player", create_build_effect_smoke = false})
			if i == 3 and j == 1 then
				acumulator.connect_neighbour({wire = defines.wire_type.green, target_entity = substation})
			end
			acumulator.minable = false
			acumulator.destructible = false
			table.insert(objective.accumulators, acumulator)
		end
		for k = 1, 4, 1 do
			local xx = x + 2 * k
			local acumulator = surface.create_entity({name = "accumulator", position = {xx,y}, force="player", create_build_effect_smoke = false})
			acumulator.minable = false
			acumulator.destructible = false
			table.insert(objective.accumulators, acumulator)
		end

	end

	local powerpole = surface.create_entity({name = "big-electric-pole", position = {0, height * -0.5 }, force="player", create_build_effect_smoke = false})
	powerpole.minable = false
	powerpole.destructible = false

	local market = surface.create_entity({name = "market", position = {-29, height * -0.5 + 4}, force="neutral", create_build_effect_smoke = false})
	market.minable = false
	market.destructible = false
  local repairchest = surface.create_entity({name = "steel-chest", position = {-24, height * -0.5 + 3}, force = "player"})
  repairchest.minable = false
  repairchest.destructible = false
  objective.upgradechest[0] = repairchest
  rendering.draw_text{
    text = "Repair Chest",
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
    local e = surface.create_entity({name = "steel-chest", position = {-21 + i, height * -0.5 + 3}, force = "player"})
    e.minable = false
    e.destructible = false
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
		text = "Market",
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
		text = "Upgrades",
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
		text = "Click [Upgrades] at top of screen",
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
		e.destructible = false
		e.minable = false
		e.operable = false
		objective.car_exits[i] = e
	end

	--generate chests inside south wagon--
	local positions = {}
	for x = width * -0.5 + 2, width * 0.5 - 1, 1 do
		if x == -1 then x = x - 1 end
		if x == 0 then x = x + 1 end
		for y = 68, height * 0.5 - 4, 1 do
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
end

function Public.set_player_spawn_and_refill_fish()
	local objective = Chrono_table.get_table()
	if not objective.locomotive_cargo[1] then return end
	local cargo = objective.locomotive_cargo[1]
	if not cargo.valid then return end
	cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 1})
	local position = cargo.surface.find_non_colliding_position("stone-furnace", cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, cargo.surface)
end

function Public.award_coins(_count)
	if not (_count >= 1) then return end
	local objective = Chrono_table.get_table()
	if not objective.locomotive_cargo[1] then return end
	local cargo = objective.locomotive_cargo[1]
	if not cargo.valid then return end
	cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "coin", count = math_floor(_count)})
end

function Public.enter_cargo_wagon(player, vehicle)
	local objective = Chrono_table.get_table()
	if not vehicle then log("no vehicle") return end
	if not vehicle.valid then log("vehicle invalid") return end
	if not game.surfaces["cargo_wagon"] then Public.create_wagon_room() end
	local wagon_surface = game.surfaces["cargo_wagon"]
	for i = 1, 3, 1 do
		if not objective.locomotive_cargo[i] then log("no cargo") return end
		if not objective.locomotive_cargo[i].valid then log("cargo invalid") return end
		if vehicle == objective.locomotive_cargo[i] then
			local x_vector = vehicle.position.x - player.position.x
			local position
			if x_vector > 0 then
				position = {wagon_surface.map_gen_settings.width * -0.5, -128 + 128 * (i - 1)}
			else
				position = {wagon_surface.map_gen_settings.width * 0.5, -128 + 128 * (i - 1)}
			end
			player.teleport(wagon_surface.find_non_colliding_position("character", position, 128, 0.5), wagon_surface)
			break
		end
	end
	if player.surface.name == "cargo_wagon" and vehicle.type == "car" then
		if objective.flame_boots then
			objective.flame_boots[player.index] = {fuel = 1, steps = {}}
		end
		local used_exit = 0
		for i = 1, 6, 1 do
			if vehicle == objective.car_exits[i] then
				used_exit = i
				break
			end
		end
		local surface = objective.locomotive_cargo[1].surface
		local position = {x = objective.locomotive_cargo[((used_exit - 1) % 3) + 1].position.x + math_sgn(used_exit - 3.5) * 2, y = objective.locomotive_cargo[((used_exit - 1) % 3) + 1].position.y}
 		local position2 = surface.find_non_colliding_position("character", position, 128, 0.5)
		if not position2 then return end
		player.teleport(position2, surface)
	end
end

return Public

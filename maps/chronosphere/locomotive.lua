local Chrono_table = require 'maps.chronosphere.table'
local Locomotive_surface = require "maps.chronosphere.worlds.locomotive_surface"

local Public = {}
local math_floor = math.floor
local function math_sgn(x)
  return (x<0 and -1) or 1
end

local function draw_light(entity)
  rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = entity,
		surface = entity.surface, visible = true, only_in_alt_mode = false,
	})
end

function Public.locomotive_spawn(surface, position, wagons)
	surface.request_to_generate_chunks(position, 0.5)
	surface.force_generate_chunk_requests()
	local objective = Chrono_table.get_table()
	if objective.world.id == 7 then --fish market
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
  local chest_positions = {
    {x = -2, y = -1}, {x = -2, y = 0}, {x = -2, y = 1}, {x = -2, y = 2}, {x = -2, y = 6}, {x = -2, y = 7},
    {x = -2, y = 8}, {x = -2, y = 9}, {x = -2, y = 13}, {x = -2, y = 14}, {x = -2, y = 15}, {x = -2, y = 16},
    {x = 3, y = -1}, {x = 3, y = 0}, {x = 3, y = 1}, {x = 3, y = 2}, {x = 3, y = 6}, {x = 3, y = 7},
    {x = 3, y = 8}, {x = 3, y = 9}, {x = 3, y = 13}, {x = 3, y = 14}, {x = 3, y = 15}, {x = 3, y = 16}
  }
	for i = 1, 24, 1 do
    local comfychest = surface.create_entity({name = "blue-chest", position = {position.x + chest_positions[i].x, position.y + chest_positions[i].y}, force = "player"})
    --comfychest.link_id = 1000 + i
		comfychest.minable = false
		if not objective.comfychests[i] then
			table.insert(objective.comfychests, comfychest)
		else
			objective.comfychests[i] = comfychest
		end
	end
  draw_light(objective.locomotive)
  draw_light(objective.locomotive_cargo[3])
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
	Locomotive_surface.create_wagon_room()
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
  local playertable = Chrono_table.get_player_table()
	if not vehicle then log("no vehicle") return end
	if not vehicle.valid then log("vehicle invalid") return end
  if not objective.locomotive then log("locomotive missing") return end
  if not objective.locomotive.valid then log("locomotive invalid") return end
	if not game.surfaces["cargo_wagon"] then Locomotive_surface.create_wagon_room() end
	local wagon_surface = game.surfaces["cargo_wagon"]
  if vehicle.type == "cargo-wagon" then
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
  end
	if player.surface.name == "cargo_wagon" and vehicle.type == "car" then
		if playertable.flame_boots then
			playertable.flame_boots[player.index] = {fuel = 1, steps = {}}
		end
		local used_exit = 0
		for i = 1, 6, 1 do
			if vehicle == objective.car_exits[i] then
				used_exit = i
				break
			end
		end
		local surface = objective.locomotive.surface
    local position
    if used_exit == 0 or objective.game_lost then
      position = game.forces.player.get_spawn_position(surface)
    else
      position = {x = objective.locomotive_cargo[((used_exit - 1) % 3) + 1].position.x + math_sgn(used_exit - 3.5) * 2, y = objective.locomotive_cargo[((used_exit - 1) % 3) + 1].position.y}
    end
 		local position2 = surface.find_non_colliding_position("character", position, 128, 0.5)
		if not position2 then return end
		player.teleport(position2, surface)
	end
end

return Public

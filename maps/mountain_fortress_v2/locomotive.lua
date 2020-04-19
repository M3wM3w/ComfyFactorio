local Public = {}

function Public.locomotive_spawn(surface, position)
	for y = -6, 6, 2 do
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	global.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -3}, force = "player"})
	global.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})

	global.locomotive_cargo = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 3}, force = "player"})
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 1})

	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = global.locomotive,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = global.locomotive_cargo,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	global.locomotive.color = {0, 255, 0}
	global.locomotive.minable = false
	global.locomotive_cargo.minable = false
	global.locomotive_cargo.operable = false
end


function Public.fish_tag()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	if not global.locomotive_cargo.surface then return end
	if not global.locomotive_cargo.surface.valid then return end
	if global.locomotive_tag then
		if global.locomotive_tag.valid then
			if global.locomotive_tag.position.x == global.locomotive_cargo.position.x and global.locomotive_tag.position.y == global.locomotive_cargo.position.y then return end
			global.locomotive_tag.destroy()
		end
	end
	global.locomotive_tag = global.locomotive_cargo.force.add_chart_tag(
		global.locomotive_cargo.surface,
		{icon = {type = 'item', name = 'raw-fish'},
		position = global.locomotive_cargo.position,
		text = " "
	})
end
--[[
local function accelerate()
	if not global.locomotive then return end
	if not global.locomotive.valid then return end
	if global.locomotive.get_driver() then return end
	global.locomotive_driver = global.locomotive.surface.create_entity({name = "character", position = global.locomotive.position, force = "player"})
	global.locomotive_driver.driving = true
	global.locomotive_driver.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight}
end

local function remove_acceleration()
	if not global.locomotive then return end
	if not global.locomotive.valid then return end
	if global.locomotive_driver then global.locomotive_driver.destroy() end
	global.locomotive_driver = nil
end
]]

local market_offers = {
	{price = {{'coin', 25}}, offer = {type = 'give-item', item = "raw-fish"}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'wood', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'stone', count = 50}},
	{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'coal', count = 50}},
	{price = {{"coin", 80}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
	{price = {{"coin", 25}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
}

local function create_wagon_room()
	local width = 32
	local height = 64
	local map_gen_settings = {
		["width"] = width,
		["height"] = height,
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
	local surface = 	game.create_surface("cargo_wagon", map_gen_settings)
	surface.freeze_daytime = true
	surface.daytime = 0.1
	surface.request_to_generate_chunks({0,0}, 1)
	surface.force_generate_chunk_requests()

	for x = width * -0.5, width * 0.5 - 1, 1 do
		for y = height * -0.5, height * 0.5 - 1, 1 do
			surface.set_tiles({{name = "tutorial-grid", position = {x,y}}})
			if math.random(1, 5) == 1 and y > 2 then
				surface.spill_item_stack({x + math.random(0, 9) * 0.1,y + math.random(0, 9) * 0.1},{name = "raw-fish", count = 1}, false)
			end
		end
	end

	for x = width * -0.5 + 4, width * 0.5 - 5, 1 do
		for y = height * -0.5 + 4, height * -0.5 + 6, 1 do
			local p = {x,y}
			surface.set_tiles({{name = "water", position = p}})
			if math.random(1, 2) == 1 then surface.create_entity({name = "fish", position = p}) end
		end
	end

	local market = surface.create_entity({name = "market", position = {0, height * -0.5 + 9}, force="neutral", create_build_effect_smoke = false})
	market.minable = false
	market.destructible = false
	for _, offer in pairs(market_offers) do market.add_market_item(offer) end

	for _, x in pairs({width * -0.5 -0.5, width * 0.5 + 0.5}) do
		local e = surface.create_entity({name = "car", position = {x, 0}, force = "player", create_build_effect_smoke = false})
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 16})
		e.destructible = false
		e.minable = false
		e.operable = false
	end

	local e = surface.create_entity({name = "big-biter", position = {width * -0.5 + 2, height * -0.5 + 2}, force = "player", create_build_effect_smoke = false})
	e.ai_settings.allow_destroy_when_commands_fail = false
	e.ai_settings.allow_try_return_to_spawner = false

	local positions = {}
	for x = width * -0.5 + 2, width * 0.5 - 2, 1 do
		for y = 4, height * 0.5 - 1, 1 do
			positions[#positions + 1] = {x = x, y = y}
		end
	end
	table.shuffle_table(positions)

	local cargo_boxes = {
		{name = "grenade", count = math.random(2, 3)},
		{name = "submachine-gun", count = 1},
		{name = "land-mine", count = math.random(8, 12)},
		{name = "explosives", count = math.random(57, 73)},
		{name = "explosives", count = math.random(57, 73)},
		{name = "iron-gear-wheel", count = math.random(7, 15)},
		{name = "iron-plate", count = math.random(15, 23)},
		{name = "copper-plate", count = math.random(15, 23)},
		{name = "shotgun", count = 1},
		{name = "shotgun-shell", count = math.random(5, 7)},
		{name = "firearm-magazine", count = math.random(7, 15)},
		{name = "rail", count = math.random(16, 24)},
		{name = "rail", count = math.random(16, 24)},
		{name = "rail", count = math.random(16, 24)},
	}

	local i = 1
	for _ = 1, 10, 1 do
		if not positions[i] then break end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		local inventory = e.get_inventory(defines.inventory.chest)
		inventory.insert({name = "raw-fish", count = math.random(2, 5)})
		i = i + 1
	end

	for _ = 1, 24, 1 do
		if not positions[i] then break end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		i = i + 1
	end

	for loot_i = 1, #cargo_boxes, 1 do
		if not positions[i] then break end
		local e = surface.create_entity({name = "wooden-chest", position = positions[i], force="player", create_build_effect_smoke = false})
		local inventory = e.get_inventory(defines.inventory.chest)
		inventory.insert(cargo_boxes[loot_i])
		i = i + 1
	end
end

function Public.set_player_spawn_and_refill_fish()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	global.locomotive_cargo.health = global.locomotive_cargo.health + 6
	global.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = math.random(1, 2)})
	local position = global.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", global.locomotive_cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, global.locomotive_cargo.surface)
end

function Public.enter_cargo_wagon(player, vehicle)
	if not vehicle then return end
	if not vehicle.valid then return end
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	if vehicle == global.locomotive_cargo then
		if not game.surfaces["cargo_wagon"] then create_wagon_room() end
		local surface = game.surfaces["cargo_wagon"]
		local x_vector = vehicle.position.x - player.position.x
		local position
		if x_vector > 0 then
			position = {surface.map_gen_settings.width * -0.5, 0}
		else
			position = {surface.map_gen_settings.width * 0.5, 0}
		end
		player.teleport(surface.find_non_colliding_position("character", position, 128, 0.5), surface)
	end
	if player.surface.name == "cargo_wagon" and vehicle.type == "car" then
		local surface = global.locomotive_cargo.surface
		local x_vector = (vehicle.position.x / math.abs(vehicle.position.x)) * 2
		local position = {global.locomotive_cargo.position.x + x_vector, global.locomotive_cargo.position.y}
		local position = surface.find_non_colliding_position("character", position, 128, 0.5)
		if not position then return end
		player.teleport(position, surface)
	end
end

return Public

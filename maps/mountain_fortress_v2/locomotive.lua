local Immersive_cargo_wagons = require "modules.immersive_cargo_wagons.main"
local Public = {}

local market_offers = {
	{price = {{'coin', 4}}, offer = {type = 'give-item', item = "raw-fish"}},
	{price = {{"coin", 16}}, offer = {type = 'give-item', item = 'wood', count = 50}},
	{price = {{"coin", 16}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
	{price = {{"coin", 16}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
	{price = {{"coin", 16}}, offer = {type = 'give-item', item = 'stone', count = 50}},
	{price = {{"coin", 16}}, offer = {type = 'give-item', item = 'coal', count = 50}},
	{price = {{"coin", 24}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},	
	{price = {{"coin", 8}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
}

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
	global.locomotive_cargo.minable = false
	
	for y = -1, 0, 0.05 do
		local scale = math.random(50, 100) * 0.01
		rendering.draw_sprite({sprite = "item/raw-fish", orientation = math.random(0, 100) * 0.01, x_scale = scale, y_scale = scale, tint = {math.random(75, 255), math.random(75, 255), math.random(75, 255)}, render_layer = "selection-box", target = global.locomotive_cargo, target_offset = {-0.7 + math.random(0, 140) * 0.01, y}, surface = surface})
	end
	
	Immersive_cargo_wagons.register_wagon(global.locomotive)
	local wagon = Immersive_cargo_wagons.register_wagon(global.locomotive_cargo)	
	wagon.entity_count = 999
	
	local surface = wagon.surface
	local center_position = {x = wagon.area.left_top.x + (wagon.area.right_bottom.x - wagon.area.left_top.x) * 0.5, y = wagon.area.left_top.y + (wagon.area.right_bottom.y - wagon.area.left_top.y) * 0.5}
	
	local position = surface.find_non_colliding_position("market", center_position, 128, 0.5)
	local market = surface.create_entity({name = "market", position = position, force = "neutral", create_build_effect_smoke = false})
	market.minable = false
	market.destructible = false
	for _, offer in pairs(market_offers) do market.add_market_item(offer) end
	
	local position = surface.find_non_colliding_position("market", center_position, 128, 0.5)
	local e = surface.create_entity({name = "big-biter", position = position, force = "player", create_build_effect_smoke = false})
	e.ai_settings.allow_destroy_when_commands_fail = false
	e.ai_settings.allow_try_return_to_spawner = false
	
	for x = center_position.x - 5, center_position.x + 5, 1 do
		for y = center_position.y - 5, center_position.y + 5, 1 do
			if math.random(1, 2) == 1 then
				surface.spill_item_stack({x + math.random(0, 9) * 0.1, y + math.random(0, 9) * 0.1},{name = "raw-fish", count = 1}, false)
			end
		end
	end
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

function Public.set_player_spawn_and_refill_fish()
	if not global.locomotive_cargo then return end
	if not global.locomotive_cargo.valid then return end
	local position = global.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", global.locomotive_cargo.position, 16, 2)
	if position then game.forces.player.set_spawn_position({x = position.x, y = position.y}, global.locomotive_cargo.surface) end
	return true
end

return Public

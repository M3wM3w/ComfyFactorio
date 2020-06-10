local Town_center = require "modules.scrap_towny_ffa.town_center"

local upgrade_functions = {
	--Upgrade Town Center Health
	[1] = function(town_center, player)
		local market = town_center.market
		local surface = market.surface
		if town_center.max_health > 500000 then return end
		town_center.health = town_center.health + town_center.max_health
		town_center.max_health = town_center.max_health * 2
		Town_center.set_market_health(market, 0)
		surface.play_sound({path="utility/achievement_unlocked", position=player.position, volume_modifier=1})
	end,
	--Upgrade Backpack
	[2] = function(town_center, player)
		local market = town_center.market
		local force = market.force
		local surface = market.surface
		if force.character_inventory_slots_bonus > 100 then return end
		force.character_inventory_slots_bonus = force.character_inventory_slots_bonus + 5
		surface.play_sound({path="utility/achievement_unlocked", position=player.position, volume_modifier=1})
	end,
	--Upgrade Backpack
	[3] = function(town_center, player)
		local market = town_center.market
		local force = market.force
		local surface = market.surface
		if town_center.upgrades.mining_prod >= 10 then return end
		town_center.upgrades.mining_prod = town_center.upgrades.mining_prod + 1
		force.mining_drill_productivity_bonus = force.mining_drill_productivity_bonus + 0.1
		surface.play_sound({path="utility/achievement_unlocked", position=player.position, volume_modifier=1})
	end,
	--Laser Turret
	[4] = function(town_center, player)
		local market = town_center.market
		local surface = market.surface
		town_center.upgrades.laser_turret.slots = town_center.upgrades.laser_turret.slots + 1
		surface.play_sound({path="utility/new_objective", position=player.position, volume_modifier=1})
	end,
	--Spawn Point
	[5] = function(town_center, player)
		local market = town_center.market
		local force = market.force
		local surface = market.surface
		local spawn_point = force.get_spawn_position(surface)
		global.towny.spawn_point[player.name] = spawn_point
		surface.play_sound({path="utility/scenario_message", position=player.position, volume_modifier=1})
	end,
}

local function clear_offers(market)
	for _ = 1, 256, 1 do
		local a = market.remove_market_item(1)
		if a == false then return end
	end
end

local function set_offers(town_center)
	local market = town_center.market
	local force = market.force
	
	local special_offers = {}	
	if town_center.max_health < 500000 then 
		special_offers[1] = {{{"coin", town_center.max_health  * 0.1}}, "Upgrade Town Center Health"}
	else
		special_offers[1] = {{{"computer", 1}}, "Maximum Health upgrades reached!"}
	end
	if force.character_inventory_slots_bonus <= 100 then 
		special_offers[2] = {{{"coin", (force.character_inventory_slots_bonus / 5 + 1) * 50}}, "Upgrade Backpack +5 Slot"}
	else
		special_offers[2] = {{{"computer", 1}}, "Maximum Backpack upgrades reached!"}
	end
	if town_center.upgrades.mining_prod < 10 then
		special_offers[3] = {{{"coin", (town_center.upgrades.mining_prod + 1) * 400}}, "Upgrade Mining Productivity +10%"}
	else
		special_offers[3] = {{{"computer", 1}}, "Maximum Mining upgrades reached!"}
	end
	local laser_turret = "Laser Turret Slot [#" .. tostring(town_center.upgrades.laser_turret.slots + 1) .. "]"
	special_offers[4] = {{{"coin", 1000 + (town_center.upgrades.laser_turret.slots * 50)}}, laser_turret}
	local spawn_point = "Set Spawn Point [Free!]"
	special_offers[5] = {nil, spawn_point}

	local market_items = {}	
	for _, v in pairs(special_offers) do
		table.insert(market_items, {price = v[1], offer = {type = 'nothing', effect_description = v[2]}})
	end

	table.insert(market_items, {price = {{"coin", 1}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}})
	table.insert(market_items, {price = {{"coin", 8}}, offer = {type = 'give-item', item = 'wood', count = 50}})
	table.insert(market_items, {price = {{"coin", 8}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}})
	table.insert(market_items, {price = {{"coin", 8}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}})
	table.insert(market_items, {price = {{"coin", 8}}, offer = {type = 'give-item', item = 'stone', count = 50}})
	table.insert(market_items, {price = {{"coin", 8}}, offer = {type = 'give-item', item = 'coal', count = 50}})
	table.insert(market_items, {price = {{"coin", 12}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}})
	table.insert(market_items, {price = {{'wood', 7}}, offer = {type = 'give-item', item = "coin"}})
	table.insert(market_items, {price = {{'iron-ore', 7}}, offer = {type = 'give-item', item = "coin"}})
	table.insert(market_items, {price = {{'copper-ore', 7}}, offer = {type = 'give-item', item = "coin"}})
	table.insert(market_items, {price = {{'stone', 7}}, offer = {type = 'give-item', item = "coin"}})
	table.insert(market_items, {price = {{'coal', 7}}, offer = {type = 'give-item', item = "coin"}})
	table.insert(market_items, {price = {{'uranium-ore', 5}}, offer = {type = 'give-item', item = "coin"}})
	table.insert(market_items, {price = {{'copper-cable', 8}}, offer = {type = 'give-item', item = "copper-plate"}})
	table.insert(market_items, {price = {{'iron-gear-wheel', 4}}, offer = {type = 'give-item', item = "iron-plate"}})
	table.insert(market_items, {price = {{'iron-stick', 2}}, offer = {type = 'give-item', item = "iron-plate"}})
	table.insert(market_items, {price = {{'empty-barrel', 4}}, offer = {type = 'give-item', item = "steel-plate"}})

	table.insert(market_items, {price = {{"coin", 300}}, offer = {type = 'give-item', item = 'loader', count = 1}})
	table.insert(market_items, {price = {{"coin", 600}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}})
	table.insert(market_items, {price = {{"coin", 900}}, offer = {type = 'give-item', item = 'express-loader', count = 1}})
	
	for _, item in pairs(market_items) do
		market.add_market_item(item)
	end
end

local function refresh_offers(event)
	local market = event.entity or event.market
	if not market then return end
	if not market.valid then return end
	if market.name ~= "market" then return end
	local town_center = global.towny.town_centers[market.force.name]
	if not town_center then return end
	clear_offers(market)
	set_offers(town_center)
end

local function offer_purchased(event)
	local player = game.players[event.player_index]
	local market = event.market
	local offer_index = event.offer_index
	local count = event.count
	if not upgrade_functions[offer_index] then return end

	local town_center = global.towny.town_centers[market.force.name]
	if not town_center then return end

	upgrade_functions[offer_index](town_center, player)

	if count > 1 then
		local offers = market.get_market_items()
		local price = offers[offer_index].price[1].amount
		player.insert({name = "coin", count = price * (count - 1)})
	end
end

local function on_gui_opened(event)
	local gui_type = event.gui_type
	if gui_type ~= defines.gui_type.entity then return end
	local entity = event.entity
	if entity == nil or not entity.valid then return end
	if entity.type == "market" then refresh_offers(event) end
end

local function on_market_item_purchased(event)
	offer_purchased(event)
	refresh_offers(event)
end

local Event = require 'utils.event'
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)


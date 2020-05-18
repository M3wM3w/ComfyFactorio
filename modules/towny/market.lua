local Town_center = require "modules.towny.town_center"
local Public = {}

local upgrade_functions = {
	--Upgrade Town Center Health
	[1] = function(town_center)
		if town_center.max_health > 500000 then return end
		town_center.health = town_center.health + town_center.max_health
		town_center.max_health = town_center.max_health * 2
		Town_center.set_market_health(town_center.market, 0)
	end,
	--Upgrade Backpack
	[2] = function(town_center)
		local force = town_center.market.force
		if force.character_inventory_slots_bonus > 100 then return end
		force.character_inventory_slots_bonus = force.character_inventory_slots_bonus + 5
	end,
	--Upgrade Backpack
	[3] = function(town_center)
		local force = town_center.market.force		
		if town_center.upgrades.mining_prod >= 10 then return end
		town_center.upgrades.mining_prod = town_center.upgrades.mining_prod + 1
		force.mining_drill_productivity_bonus = force.mining_drill_productivity_bonus + 0.1
	end,
}

local function clear_offers(market)
	for i = 1, 256, 1 do
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
		special_offers[3] = {{{"computer", 1}}, "Maximum Backpack upgrades reached!"}
	end
	
	
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
	
	table.insert(market_items, {price = {{"coin", 300}}, offer = {type = 'give-item', item = 'loader', count = 1}})
	table.insert(market_items, {price = {{"coin", 600}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}})
	table.insert(market_items, {price = {{"coin", 900}}, offer = {type = 'give-item', item = 'express-loader', count = 1}})
	
	for _, item in pairs(market_items) do
		market.add_market_item(item)
	end
end

function Public.refresh_offers(event)
	local market = event.entity or event.market
	if not market then return end
	if not market.valid then return end
	if market.name ~= "market" then return end
	local town_center = global.towny.town_centers[market.force.name]
	if not town_center then return end
	clear_offers(market)
	set_offers(town_center)
end

function Public.offer_purchased(event)
	local offer_index = event.offer_index
	if not upgrade_functions[offer_index] then return end
	
	local market = event.market

	local town_center = global.towny.town_centers[market.force.name]
	if not town_center then return end
	
	upgrade_functions[offer_index](town_center)
	
	count = event.count
	if count > 1 then
		local offers = market.get_market_items()
		local price = offers[offer_index].price[1].amount
		game.players[event.player_index].insert({name = "coin", count = price * (count - 1)})
	end
end

return Public


local Public = {}

local market = {}

market.weapons = {
	["pistol"] = {value = 10, rarity = 1},
	["submachine-gun"] = {value = 50, rarity = 2},
	["shotgun"] = {value = 40, rarity = 2},
	["combat-shotgun"] = {value = 400, rarity = 5},
	["rocket-launcher"] = {value = 250, rarity = 4},
	["flamethrower"] = {value = 750, rarity = 6},
	["land-mine"] = {value = 3, rarity = 5},
}

market.ammo = {
	["firearm-magazine"] = {value = 3, rarity = 1},
	["piercing-rounds-magazine"] = {value = 6, rarity = 4},
	["uranium-rounds-magazine"] = {value = 20, rarity = 8},
	["shotgun-shell"] = {value = 3, rarity = 1},
	["piercing-shotgun-shell"] = {value = 8, rarity = 5},
	["cannon-shell"] = {value = 8, rarity = 4},
	["explosive-cannon-shell"] = {value = 12, rarity = 5},
	["uranium-cannon-shell"] = {value = 16, rarity = 7},
	["explosive-uranium-cannon-shell"] = {value = 20, rarity = 8},
	["artillery-shell"] = {value = 64, rarity = 7},
	["rocket"] = {value = 4, rarity = 3},
	["explosive-rocket"] = {value = 12, rarity = 5},
	["atomic-bomb"] = {value = 9000, rarity = 10},
	["flamethrower-ammo"] = {value = 20, rarity = 6},
	["explosives"] = {value = 3, rarity = 1},
}

market.caspules = {
	["grenade"] = {value = 16, rarity = 2},
	["cluster-grenade"] = {value = 32, rarity = 5},
	["poison-capsule"] = {value = 32, rarity = 6},
	["slowdown-capsule"] = {value = 8, rarity = 1},
	["defender-capsule"] = {value = 8, rarity = 1},
	["distractor-capsule"] = {value = 20, rarity = 5},
	["destroyer-capsule"] = {value = 32, rarity = 7},
	["discharge-defense-remote"] = {value = 64, rarity = 6},
	["artillery-targeting-remote"] = {value = 32, rarity = 7},
	["raw-fish"] = {value = 6, rarity = 1},
}

market.armor = {
	["light-armor"] = {value = 25, rarity = 1},
	["heavy-armor"] = {value = 250, rarity = 4},
	["modular-armor"] = {value = 750, rarity = 5},
	["power-armor"] = {value = 2500, rarity = 6},
	["power-armor-mk2"] = {value = 20000, rarity = 10},
}

market.equipment = {
	["solar-panel-equipment"] = {value = 240, rarity = 3},
	["fusion-reactor-equipment"] = {value = 9000, rarity = 7},
	["energy-shield-equipment"] = {value = 400, rarity = 6},
	["energy-shield-mk2-equipment"] = {value = 4000, rarity = 8},
	["battery-equipment"] = {value = 160, rarity = 2},
	["battery-mk2-equipment"] = {value = 2000, rarity = 8},
	["personal-laser-defense-equipment"] = {value = 2500, rarity = 7},
	["discharge-defense-equipment"] = {value = 2000, rarity = 5},
	["belt-immunity-equipment"] = {value = 200, rarity = 1},
	["exoskeleton-equipment"] = {value = 800, rarity = 3},
	["personal-roboport-equipment"] = {value = 500, rarity = 3},
	["personal-roboport-mk2-equipment"] = {value = 5000, rarity = 8},
	["night-vision-equipment"] = {value = 250, rarity = 1},
}

market.defense = {	
	["stone-wall"] = {value = 4, rarity = 1},
	["gate"] = {value = 8, rarity = 1},
	["repair-pack"] = {value = 8, rarity = 1},
	["gun-turret"] = {value = 64, rarity = 1},
	["laser-turret"] = {value = 1024, rarity = 6},
	["flamethrower-turret"] = {value = 2048, rarity = 6},
	["flamethrower-turret"] = {value = 2048, rarity = 6},
	["artillery-turret"] = {value = 8192, rarity = 8},
	["rocket-silo"] = {value = 64000, rarity = 10},
}

market.logistic = {
	["wooden-chest"] = {value = 3, rarity = 1},
	["iron-chest"] = {value = 10, rarity = 2},
	["steel-chest"] = {value = 24, rarity = 3},
	["storage-tank"] = {value = 32, rarity = 4},
	["transport-belt"] = {value = 4, rarity = 1},
	["fast-transport-belt"] = {value = 8, rarity = 4},
	["express-transport-belt"] = {value = 24, rarity = 7},
	["underground-belt"] = {value = 8, rarity = 1},
	["fast-underground-belt"] = {value = 32, rarity = 4},
	["express-underground-belt"] = {value = 64, rarity = 7},
	["splitter"] = {value = 16, rarity = 1},
	["fast-splitter"] = {value = 48, rarity = 4},
	["express-splitter"] = {value = 128, rarity = 7},
	["loader"] = {value = 256, rarity = 2},
	["fast-loader"] = {value = 512, rarity = 5},
	["express-loader"] = {value = 768, rarity = 8},
	["burner-inserter"] = {value = 4, rarity = 1},
	["inserter"] = {value = 8, rarity = 1},
	["long-handed-inserter"] = {value = 12, rarity = 2},
	["fast-inserter"] = {value = 16, rarity = 4},
	["filter-inserter"] = {value = 24, rarity = 5},
	["stack-inserter"] = {value = 96, rarity = 6},
	["stack-filter-inserter"] = {value = 128, rarity = 7},
	["small-electric-pole"] = {value = 2, rarity = 1},
	["medium-electric-pole"] = {value = 12, rarity = 4},
	["big-electric-pole"] = {value = 24, rarity = 5},
	["substation"] = {value = 96, rarity = 8},
	["pipe"] = {value = 2, rarity = 1},
	["pipe-to-ground"] = {value = 8, rarity = 1},
	["pump"] = {value = 16, rarity = 4},
	["logistic-robot"] = {value = 28, rarity = 5},
	["construction-robot"] = {value = 28, rarity = 3},
	["logistic-chest-active-provider"] = {value = 128, rarity = 7},
	["logistic-chest-passive-provider"] = {value = 128, rarity = 6},
	["logistic-chest-storage"] = {value = 128, rarity = 6},
	["logistic-chest-buffer"] = {value = 128, rarity = 7},
	["logistic-chest-requester"] = {value = 128, rarity = 7},
	["roboport"] = {value = 4096, rarity = 8},
}

market.vehicles = {
	["rail"] = {value = 4, rarity = 1},
	["train-stop"] = {value = 32, rarity = 3},
	["rail-signal"] = {value = 8, rarity = 5},
	["rail-chain-signal"] = {value = 8, rarity = 5},
	["locomotive"] = {value = 400, rarity = 4},
	["cargo-wagon"] = {value = 200, rarity = 4},
	["fluid-wagon"] = {value = 300, rarity = 5},
	["artillery-wagon"] = {value = 8192, rarity = 8},
	["car"] = {value = 80, rarity = 1},
	["tank"] = {value = 1800, rarity = 5},
}

market.wire = {
	["small-lamp"] = {value = 4, rarity = 1},
	["red-wire"] = {value = 4, rarity = 1},
	["green-wire"] = {value = 4, rarity = 1},
	["arithmetic-combinator"] = {value = 16, rarity = 1},
	["decider-combinator"] = {value = 16, rarity = 1},
	["constant-combinator"] = {value = 16, rarity = 1},
	["power-switch"] = {value = 16, rarity = 1},
	["programmable-speaker"] = {value = 24, rarity = 1},
}

local function get_types()
	local types = {}
	for k, v in pairs(market) do
		types[#types + 1] = k
	end
	return types
end

local function get_resource_market_sells()
	local sells = {
		{price = {{"coin", math.random(5,10)}}, offer = {type = 'give-item', item = 'wood', count = 50}},
		{price = {{"coin", math.random(5,10)}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
		{price = {{"coin", math.random(5,10)}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
		{price = {{"coin", math.random(5,10)}}, offer = {type = 'give-item', item = 'stone', count = 50}},
		{price = {{"coin", math.random(5,10)}}, offer = {type = 'give-item', item = 'coal', count = 50}},
		{price = {{"coin", math.random(8,16)}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},	
		{price = {{"coin", math.random(2,4)}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},				
	}
	table.shuffle_table(sells)
	return sells
end

local function get_resource_market_buys()
	local buys = {
		{price = {{'wood', math.random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'iron-ore', math.random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'copper-ore', math.random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'stone', math.random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'coal', math.random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'uranium-ore', math.random(8,10)}}, offer = {type = 'give-item', item = "coin"}},
		{price = {{'water-barrel', 1}}, offer = {type = 'give-item', item = "coin", count = math.random(1,2)}},
		{price = {{'lubricant-barrel', 1}}, offer = {type = 'give-item', item = "coin", count = math.random(3,6)}},
		{price = {{'sulfuric-acid-barrel', 1}}, offer = {type = 'give-item', item = "coin", count = math.random(4,8)}},
		{price = {{'light-oil-barrel', 1}}, offer = {type = 'give-item', item = "coin", count = math.random(2,4)}},
		{price = {{'heavy-oil-barrel', 1}}, offer = {type = 'give-item', item = "coin", count = math.random(2,4)}},
		{price = {{'petroleum-gas-barrel', 1}}, offer = {type = 'give-item', item = "coin", count = math.random(3,5)}},
	}
	table.shuffle_table(buys)	
	return buys
end

local function get_market_item_list(market_types, rarity)
	if rarity < 1 then rarity = 1 end
	if rarity > 10 then rarity = 10 end
	local list = {}
	for _, market_type in pairs(market_types) do
		for k, item in pairs(market[market_type]) do
			--if item.rarity <= rarity and item.rarity + 7 >= rarity then
			if item.rarity <= rarity then
				local price = math.random(math.floor(item.value * 0.75), math.floor(item.value * 1.25))
				if price < 1 then price = 1 end
				if price > 64000 then price = 64000 end
				list[#list + 1] = {price = {{"coin", price}}, offer = {type = 'give-item', item = k}}
			end
		end
	end
	if #list == 0 then return false end
	return list
end

local function get_random_market_item_list(rarity)
	local types = get_types()
	table.shuffle_table(types)
	for i = 1, #types, 1 do
		local items = get_market_item_list({types[i]}, rarity)
		if items then return items end
	end
	return false
end

function Public.mountain_market(surface, position, rarity)
	local types = get_types()
	table.shuffle_table(types)
	local items = get_market_item_list({types[1], types[2], types[3]}, rarity)
	if not items then return end
	if #items > 0 then table.shuffle_table(items) end
	local market = surface.create_entity({name = "market", position = position, force="neutral"})
	
	local blacklist = {
		["cargo-wagon"] = true,
		["locomotive"] = true,
		["artillery-wagon"] = true,
		["fluid-wagon"] = true,
		["land-mine"] = true,
	}
	
	for i = 1, math.random(5, 10), 1 do
		local item = items[i]
		if not item then break end
		if not blacklist[item.offer.item] then market.add_market_item(items[i]) end
	end
	
	local sells = get_resource_market_sells()
	for i = 1, math.random(1, 3), 1 do
		market.add_market_item(sells[i])
	end
	
	local buys = get_resource_market_buys()
	for i = 1, math.random(1, 3), 1 do
		market.add_market_item(buys[i])
	end
	
	return market
end

function Public.super_market(surface, position, rarity)
	local items = get_market_item_list(get_types(), rarity)
	if not items then return end
	if #items > 0 then table.shuffle_table(items) end
	local market = surface.create_entity({name = "market", position = position, force="neutral"})
	market.minable = false
	market.destructible = false
	
	for i = 1, math.random(6, 12), 1 do
		if not items[i] then break end
		market.add_market_item(items[i])
	end
	
	local sells = get_resource_market_sells()
	for i = 1, math.random(1, 3), 1 do
		market.add_market_item(sells[i])
	end
	
	local buys = get_resource_market_buys()
	for i = 1, math.random(1, 3), 1 do
		market.add_market_item(buys[i])
	end
	
	return market
end

return Public
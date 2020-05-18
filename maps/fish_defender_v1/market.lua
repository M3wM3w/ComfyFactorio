require 'maps.fish_defender_v1.flame_boots'
require 'maps.fish_defender_v1.trapped_capsules'
require 'maps.fish_defender_v1.ultra_mines'
require 'maps.fish_defender_v1.crumbly_walls'
require 'maps.fish_defender_v1.vehicle_nanobots'
require 'maps.fish_defender_v1.laser_pointer'

local event = require 'utils.event'
local Server = require 'utils.server'

local slot_upgrade_offers = {
		[1] = {"gun-turret", "gun turret"},
		[2] = {"laser-turret", "laser turret"},
		[3] = {"artillery-turret", "artillery turret"},
		[4] = {"flamethrower-turret", "flamethrower turret"},
		[5] = {"land-mine", "land mine"}
	}

local special_descriptions = {
	["flame-boots"] = "Flame Boots - Get yourself some hot boots.",
	["explosive-bullets"] = "Unlock Explosive Bullets - Submachine-Gun and Pistol gains a chance to deal splash damage.",
	["bouncy-shells"] = "Unlock Bouncy Shells - Shotgun projectiles may bounce to multiple targets.",
	["trapped-capsules"] = "Unlock Trapped Capsules - Combat robots will send a last deadly projectile to a nearby enemy when killed.",
	["ultra-mines"] = "Unlock Ultra Mines - Careful with these...",
	["railgun-enhancer"] = "Unlock Railgun Enhancer - Turns the railgun into a powerful forking gun.",
	["crumbly-walls"] = "Unlock Crumbly Walls - Fortifications which crumble, may turn into rocks.",
	["vehicle-nanobots"] = "Unlock Vehicle Nanobots - Vehicles repair rapidly while driving.",
	["laser-pointer"] = "Unlock Laser Pointer - The biters are on a quest to slay the red (artillery) dot."
}

function place_fish_market(surface, position)
	local market = surface.create_entity({name = "market", position = position, force = "player"})
	market.minable = false
	return market
end

local function refresh_market_offers()
	if not global.market then return end
	for i = 1, 100, 1 do
		local a = global.market.remove_market_item(1)
		if a == false then break end
	end
	
	local str1 = "Gun Turret Slot for " .. tostring(global.entity_limits["gun-turret"].limit * global.entity_limits["gun-turret"].slot_price)
	str1 = str1 .. " Coins."
	
	local str2 = "Laser Turret Slot for " .. tostring(global.entity_limits["laser-turret"].limit * global.entity_limits["laser-turret"].slot_price)
	str2 = str2 .. " Coins."
	
	local str3 = "Artillery Slot for " .. tostring(global.entity_limits["artillery-turret"].limit * global.entity_limits["artillery-turret"].slot_price)
	str3 = str3 .. " Coins."
	
	local current_limit = 1
	if global.entity_limits["flamethrower-turret"].limit ~= 0 then current_limit = current_limit + global.entity_limits["flamethrower-turret"].limit end
	local str4 = "Flamethrower Turret Slot for " .. tostring(current_limit * global.entity_limits["flamethrower-turret"].slot_price)
	str4 = str4 .. " Coins."
	
	local str5 = "Landmine Slot for " .. tostring(math.ceil((global.entity_limits["land-mine"].limit / 3) * global.entity_limits["land-mine"].slot_price))
	str5 = str5 .. " Coins."
	
	local market_items = {
		{price = {}, offer = {type = 'nothing', effect_description = str1}},
		{price = {}, offer = {type = 'nothing', effect_description = str2}},
		{price = {}, offer = {type = 'nothing', effect_description = str3}},
		{price = {}, offer = {type = 'nothing', effect_description = str4}},
		{price = {}, offer = {type = 'nothing', effect_description = str5}},
		{price = {{"coin", 5}}, offer = {type = 'give-item', item = "raw-fish", count = 1}},
		{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'wood', count = 8}},		
		{price = {{"coin", 8}}, offer = {type = 'give-item', item = 'grenade', count = 1}},
		{price = {{"coin", 32}}, offer = {type = 'give-item', item = 'cluster-grenade', count = 1}},
		{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'land-mine', count = 1}},
		{price = {{"coin", 80}}, offer = {type = 'give-item', item = 'car', count = 1}},
		{price = {{"coin", 1200}}, offer = {type = 'give-item', item = 'tank', count = 1}},
		{price = {{"coin", 3}}, offer = {type = 'give-item', item = 'cannon-shell', count = 1}},
		{price = {{"coin", 7}}, offer = {type = 'give-item', item = 'explosive-cannon-shell', count = 1}},
		{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'gun-turret', count = 1}},
		{price = {{"coin", 300}}, offer = {type = 'give-item', item = 'laser-turret', count = 1}},
		{price = {{"coin", 450}}, offer = {type = 'give-item', item = 'artillery-turret', count = 1}},
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'artillery-shell', count = 1}},
		{price = {{"coin", 25}}, offer = {type = 'give-item', item = 'artillery-targeting-remote', count = 1}},
		{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'firearm-magazine', count = 1}},
		{price = {{"coin", 4}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine', count = 1}},				
		{price = {{"coin", 2}}, offer = {type = 'give-item', item = 'shotgun-shell', count = 1}},	
		{price = {{"coin", 6}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell', count = 1}},
		{price = {{"coin", 30}}, offer = {type = 'give-item', item = "submachine-gun", count = 1}},
		{price = {{"coin", 250}}, offer = {type = 'give-item', item = 'combat-shotgun', count = 1}},	
		{price = {{"coin", 450}}, offer = {type = 'give-item', item = 'flamethrower', count = 1}},	
		{price = {{"coin", 25}}, offer = {type = 'give-item', item = 'flamethrower-ammo', count = 1}},	
		{price = {{"coin", 125}}, offer = {type = 'give-item', item = 'rocket-launcher', count = 1}},
		{price = {{"coin", 2}}, offer = {type = 'give-item', item = 'rocket', count = 1}},	
		{price = {{"coin", 7}}, offer = {type = 'give-item', item = 'explosive-rocket', count = 1}},
		{price = {{"coin", 7500}}, offer = {type = 'give-item', item = 'atomic-bomb', count = 1}},		
		{price = {{"coin", 325}}, offer = {type = 'give-item', item = 'railgun', count = 1}},
		{price = {{"coin", 8}}, offer = {type = 'give-item', item = 'railgun-dart', count = 1}},	
		{price = {{"coin", 40}}, offer = {type = 'give-item', item = 'poison-capsule', count = 1}},
		{price = {{"coin", 4}}, offer = {type = 'give-item', item = 'defender-capsule', count = 1}},	
		{price = {{"coin", 10}}, offer = {type = 'give-item', item = 'light-armor', count = 1}},		
		{price = {{"coin", 125}}, offer = {type = 'give-item', item = 'heavy-armor', count = 1}},	
		{price = {{"coin", 350}}, offer = {type = 'give-item', item = 'modular-armor', count = 1}},	
		{price = {{"coin", 1500}}, offer = {type = 'give-item', item = 'power-armor', count = 1}},
		{price = {{"coin", 12000}}, offer = {type = 'give-item', item = 'power-armor-mk2', count = 1}},
		{price = {{"coin", 50}}, offer = {type = 'give-item', item = 'solar-panel-equipment', count = 1}},
		{price = {{"coin", 2250}}, offer = {type = 'give-item', item = 'fusion-reactor-equipment', count = 1}},
		{price = {{"coin", 100}}, offer = {type = 'give-item', item = 'battery-equipment', count = 1}},				
		{price = {{"coin", 200}}, offer = {type = 'give-item', item = 'energy-shield-equipment', count = 1}},
		{price = {{"coin", 850}}, offer = {type = 'give-item', item = 'personal-laser-defense-equipment', count = 1}},	
		{price = {{"coin", 175}}, offer = {type = 'give-item', item = 'exoskeleton-equipment', count = 1}},		
		{price = {{"coin", 125}}, offer = {type = 'give-item', item = 'night-vision-equipment', count = 1}},
		{price = {{"coin", 200}}, offer = {type = 'give-item', item = 'belt-immunity-equipment', count = 1}},	
		{price = {{"coin", 250}}, offer = {type = 'give-item', item = 'personal-roboport-equipment', count = 1}},
		{price = {{"coin", 35}}, offer = {type = 'give-item', item = 'construction-robot', count = 1}},
		{price = {{"coin", 25}}, offer = {type = 'give-item', item = 'cliff-explosives', count = 1}},
		{price = {{"coin", 80}}, offer = {type = 'nothing', effect_description = special_descriptions["flame-boots"]}}
	}
	
	for _, item in pairs(market_items) do
		global.market.add_market_item(item)
	end
	
	if not global.railgun_enhancer_unlocked then 
		global.market.add_market_item({price = {{"coin", 1500}}, offer = {type = 'nothing', effect_description = special_descriptions["railgun-enhancer"]}})
	end		
	if not global.trapped_capsules_unlocked then 
		global.market.add_market_item({price = {{"coin", 3500}}, offer = {type = 'nothing', effect_description = special_descriptions["trapped-capsules"]}})
	end	
	if not global.explosive_bullets_unlocked then 
		global.market.add_market_item({price = {{"coin", 4500}}, offer = {type = 'nothing', effect_description = special_descriptions["explosive-bullets"]}})
	end
	if not global.bouncy_shells_unlocked then 
		global.market.add_market_item({price = {{"coin", 10000}}, offer = {type = 'nothing', effect_description = special_descriptions["bouncy-shells"]}})
	end	
	if not global.vehicle_nanobots_unlocked then 
		global.market.add_market_item({price = {{"coin", 15000}}, offer = {type = 'nothing', effect_description = special_descriptions["vehicle-nanobots"]}})
	end
	if not global.crumbly_walls_unlocked then 
		global.market.add_market_item({price = {{"coin", 35000}}, offer = {type = 'nothing', effect_description = special_descriptions["crumbly-walls"]}})
	end
	if not global.ultra_mines_unlocked then 
		global.market.add_market_item({price = {{"coin", 45000}}, offer = {type = 'nothing', effect_description = special_descriptions["ultra-mines"]}})
	end
	if not global.laser_pointer_unlocked then 
		global.market.add_market_item({price = {{"coin", 65000}}, offer = {type = 'nothing', effect_description = special_descriptions["laser-pointer"]}})
	end
end

local function slot_upgrade(player, offer_index)
	local price = global.entity_limits[slot_upgrade_offers[offer_index][1]].limit * global.entity_limits[slot_upgrade_offers[offer_index][1]].slot_price
		
	local gain = 1
	if offer_index == 5 then
		price = math.ceil((global.entity_limits[slot_upgrade_offers[offer_index][1]].limit  / 3) * global.entity_limits[slot_upgrade_offers[offer_index][1]].slot_price)
		gain = 3
	end
	
	if slot_upgrade_offers[offer_index][1] == "flamethrower-turret" then
		price = (global.entity_limits[slot_upgrade_offers[offer_index][1]].limit + 1) * global.entity_limits[slot_upgrade_offers[offer_index][1]].slot_price
	end			
	
	local coins_removed = player.remove_item({name = "coin", count = price})		
	if coins_removed ~= price then
		if coins_removed > 0 then
			player.insert({name = "coin", count = coins_removed})
		end
		player.print("Not enough coins.", {r = 0.22, g = 0.77, b = 0.44})
		return false
	end
				 
	global.entity_limits[slot_upgrade_offers[offer_index][1]].limit = global.entity_limits[slot_upgrade_offers[offer_index][1]].limit + gain
	game.print(player.name .. " has bought a " .. slot_upgrade_offers[offer_index][2] .. " slot for " .. price .. " coins!", {r = 0.22, g = 0.77, b = 0.44})
	Server.to_discord_bold(table.concat{player.name .. " has bought a " .. slot_upgrade_offers[offer_index][2] .. " slot for " .. price .. " coins!"})
	refresh_market_offers()
end

local function on_market_item_purchased(event)
	local player = game.players[event.player_index]	
	local market = event.market
	local offer_index = event.offer_index	
	local offers = market.get_market_items()	
	local bought_offer = offers[offer_index].offer	
	if bought_offer.type ~= "nothing" then return end
		
	if slot_upgrade_offers[offer_index] then
		if slot_upgrade(player, offer_index) then return end
	end
		
	if offer_index < 50 then return end
	
	if bought_offer.effect_description == special_descriptions["flame-boots"] then
		game.print(player.name .. " has bought themselves some flame boots.", {r = 0.22, g = 0.77, b = 0.44})
		if not global.flame_boots[player.index].fuel then
			global.flame_boots[player.index].fuel = math.random(1500, 3000)
		else
			global.flame_boots[player.index].fuel = global.flame_boots[player.index].fuel + math.random(1500, 3000)
		end
		
		player.print("Fuel remaining: " .. global.flame_boots[player.index].fuel, {r = 0.22, g = 0.77, b = 0.44})
		refresh_market_offers()
		return
	end
	
	if bought_offer.effect_description == special_descriptions["explosive-bullets"] then
		game.print(player.name .. " has unlocked explosive bullets.", {r = 0.22, g = 0.77, b = 0.44})
		global.explosive_bullets_unlocked = true
		refresh_market_offers()
		return
	end
	
	if bought_offer.effect_description == special_descriptions["bouncy-shells"] then
		game.print(player.name .. " has unlocked bouncy shells.", {r = 0.22, g = 0.77, b = 0.44})
		global.bouncy_shells_unlocked = true
		refresh_market_offers()
		return
	end
			
	if bought_offer.effect_description == special_descriptions["trapped-capsules"] then
		game.print(player.name .. " has unlocked trapped capsules!", {r = 0.22, g = 0.77, b = 0.44})
		global.trapped_capsules_unlocked = true
		refresh_market_offers()
		return
	end
	
	if bought_offer.effect_description == special_descriptions["ultra-mines"] then
		game.print(player.name .. " has unlocked ultra mines!", {r = 0.22, g = 0.77, b = 0.44})
		global.ultra_mines_unlocked = true
		refresh_market_offers()
		return
	end
	
	if bought_offer.effect_description == special_descriptions["laser-pointer"] then
		game.print(player.name .. " has unleashed the quest to slay the red dot!", {r = 0.22, g = 0.77, b = 0.44})
		global.laser_pointer_unlocked = true
		refresh_market_offers()
		return
	end
	
	if bought_offer.effect_description == special_descriptions["railgun-enhancer"] then
		game.print(player.name .. " has unlocked the enhanced railgun!", {r = 0.22, g = 0.77, b = 0.44})
		global.railgun_enhancer_unlocked = true
		refresh_market_offers()
		return
	end
	
	if bought_offer.effect_description == special_descriptions["crumbly-walls"] then
		game.print(player.name .. " has unlocked crumbly walls!", {r = 0.22, g = 0.77, b = 0.44})
		global.crumbly_walls_unlocked = true
		refresh_market_offers()
		return
	end
	
	if bought_offer.effect_description == special_descriptions["vehicle-nanobots"] then
		game.print(player.name .. " has unlocked vehicle nanobots!", {r = 0.22, g = 0.77, b = 0.44})
		global.vehicle_nanobots_unlocked = true
		refresh_market_offers()
		return
	end
end

local function on_gui_opened(event)
	if not event.entity then return end
	if not event.entity.valid then return end
	if event.entity.name == "market" then refresh_market_offers() return end
end

event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
event.add(defines.events.on_gui_opened, on_gui_opened)
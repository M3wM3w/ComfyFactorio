local table_insert = table.insert

local Table = require 'modules.scrap_towny_ffa.table'
local Town_center = require 'modules.scrap_towny_ffa.town_center'

local upgrade_functions = {
	-- Upgrade Town Center Health
	[1] = function(town_center, player)
		local market = town_center.market
		local surface = market.surface
		if town_center.max_health > 500000 then return end
		town_center.health = town_center.health + town_center.max_health
		town_center.max_health = town_center.max_health * 2
		Town_center.set_market_health(market, 0)
		surface.play_sound({ path = "utility/achievement_unlocked", position = player.position, volume_modifier = 1 })
	end,
	-- Upgrade Backpack
	[2] = function(town_center, player)
		local market = town_center.market
		local force = market.force
		local surface = market.surface
		if force.character_inventory_slots_bonus > 100 then return end
		force.character_inventory_slots_bonus = force.character_inventory_slots_bonus + 5
		surface.play_sound({ path = "utility/achievement_unlocked", position = player.position, volume_modifier = 1 })
	end,
	-- Upgrade Mining Productivity
	[3] = function(town_center, player)
		local market = town_center.market
		local force = market.force
		local surface = market.surface
		if town_center.upgrades.mining_prod >= 10 then return end
		town_center.upgrades.mining_prod = town_center.upgrades.mining_prod + 1
		force.mining_drill_productivity_bonus = force.mining_drill_productivity_bonus + 0.1
		surface.play_sound({ path = "utility/achievement_unlocked", position = player.position, volume_modifier = 1 })
	end,
	-- Laser Turret Slot
	[4] = function(town_center, player)
		local market = town_center.market
		local surface = market.surface
		town_center.upgrades.laser_turret.slots = town_center.upgrades.laser_turret.slots + 1
		surface.play_sound({ path = "utility/new_objective", position = player.position, volume_modifier = 1 })
	end,
	-- Set Spawn Point
	[5] = function(town_center, player)
		local ffatable = Table.get_table()
		local market = town_center.market
		local force = market.force
		local surface = market.surface
		local spawn_point = force.get_spawn_position(surface)
		ffatable.spawn_point[player.name] = spawn_point
		surface.play_sound({ path = "utility/scenario_message", position = player.position, volume_modifier = 1 })
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
		special_offers[1] = { { { "coin", town_center.max_health * 0.1 } }, "Upgrade Town Center Health" }
	else
		special_offers[1] = { { { "coin", 1 } }, "Maximum Health upgrades reached!" }
	end
	if force.character_inventory_slots_bonus <= 100 then
		special_offers[2] = { { { "coin", (force.character_inventory_slots_bonus / 5 + 1) * 50 } }, "Upgrade Backpack +5 Slot" }
	else
		special_offers[2] = { { { "coin", 1 } }, "Maximum Backpack upgrades reached!" }
	end
	if town_center.upgrades.mining_prod < 10 then
		special_offers[3] = { { { "coin", (town_center.upgrades.mining_prod + 1) * 400 } }, "Upgrade Mining Productivity +10%" }
	else
		special_offers[3] = { { { "coin", 1 } }, "Maximum Mining upgrades reached!" }
	end
	local laser_turret = "Laser Turret Slot [#" .. tostring(town_center.upgrades.laser_turret.slots + 1) .. "]"
	special_offers[4] = { { { "coin", 1000 + (town_center.upgrades.laser_turret.slots * 50) } }, laser_turret }
	local spawn_point = "Set Spawn Point"
	special_offers[5] = { { { "coin", 1 } }, spawn_point }

	local market_items = {}

	for _, v in pairs(special_offers) do
		table_insert(market_items, { price = v[1], offer = { type = 'nothing', effect_description = v[2] } })
	end

	-- coin purchases
	table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'raw-fish', count = 1 } })
	table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'wood', count = 6 } })
	table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'iron-ore', count = 6 } })
	table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'copper-ore', count = 6 } })
	table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'stone', count = 6 } })
	table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'coal', count = 6 } })
	table_insert(market_items, { price = { { 'coin', 1 } }, offer = { type = 'give-item', item = 'uranium-ore', count = 4 } })
	table_insert(market_items, { price = { { 'coin', 300 } }, offer = { type = 'give-item', item = 'loader', count = 1 } })
	table_insert(market_items, { price = { { 'coin', 600 } }, offer = { type = 'give-item', item = 'fast-loader', count = 1 } })
	table_insert(market_items, { price = { { 'coin', 900 } }, offer = { type = 'give-item', item = 'express-loader', count = 1 } })
	-- scrap selling
	table_insert(market_items, { price = { { 'wood', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'iron-ore', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'copper-ore', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'stone', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'coal', 7 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'uranium-ore', 5 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'copper-cable', 12 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'iron-gear-wheel', 3 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'iron-stick', 12 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })
	table_insert(market_items, { price = { { 'empty-barrel', 1 } }, offer = { type = 'give-item', item = 'coin', count = 1 } })

	for _, item in pairs(market_items) do
		market.add_market_item(item)
	end
end

local function refresh_offers(event)
	local ffatable = Table.get_table()
	local market = event.entity or event.market
	if not market then return end
	if not market.valid then return end
	if market.name ~= "market" then return end
	local town_center = ffatable.town_centers[market.force.name]
	if not town_center then return end
	clear_offers(market)
	set_offers(town_center)
end

local function offer_purchased(event)
	local ffatable = Table.get_table()
	local player = game.players[event.player_index]
	local market = event.market
	local offer_index = event.offer_index
	local count = event.count
	if not upgrade_functions[offer_index] then return end

	local town_center = ffatable.town_centers[market.force.name]
	if not town_center then return end

	upgrade_functions[offer_index](town_center, player)

	if count > 1 then
		local offers = market.get_market_items()
		local price = offers[offer_index].price[1].amount
		player.insert({ name = "coin", count = price * (count - 1) })
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

local function inside(pos, area)
	return pos.x >= area.left_top.x and pos.x <= area.right_bottom.x and pos.y >= area.left_top.y and pos.y <= area.right_bottom.y
end

local function on_tick(_)
	local ffatable = Table.get_table()
	if not ffatable.town_centers then return end
	local items = { "burner-inserter", "inserter", "long-handed-inserter", "fast-inserter",
					"filter-inserter", "stack-inserter", "stack-filter-inserter",
					"loader", "fast-loader", "express-loader" }
	for _, town_center in pairs(ffatable.town_centers) do
		local market = town_center.market
		local offers = market.get_market_items()
		if offers == nil then set_offers(town_center) end
		local s = market.surface
		local force = market.force
		-- get the bounding box for the market
		local bb = market.bounding_box
		local area = { left_top = { bb.left_top.x - 2, bb.left_top.y - 2 }, right_bottom = { bb.right_bottom.x + 2, bb.right_bottom.y + 2 } }
		local entities = s.find_entities_filtered({ area = area, name = items })
		for _, e in pairs(entities) do
			if e.name ~= "loader" and e.name ~= "fast-loader" and e.name ~= "express-loader" then
				local ppos = e.pickup_position
				local dpos = e.drop_position
				-- pulling an item from the market
				if inside(ppos, bb) and e.drop_target then
					local stack = e.held_stack
					local spos = e.held_stack_position
					if inside(spos, bb) then
						local filter
						local filter_mode = e.inserter_filter_mode
						if filter_mode ~= nil then
							for i = 1, e.filter_slot_count do
								if e.get_filter(i) ~= nil then
									filter = e.get_filter(i)
									break
								end
							end
						end
						if (filter_mode == "whitelist" and filter == "coin") or (filter_mode == "blacklist" and filter == nil) or (filter_mode == nil) then
							if stack.valid and town_center.coin_balance > 0 then
								-- pull coins
								stack.set_stack({ name = "coin", count = 1 })
								town_center.coin_balance = town_center.coin_balance - 1
								Town_center.update_coin_balance(force)
							end
						else
							if filter_mode == "whitelist" and filter ~= nil and stack.valid then
								-- purchased and pull items if output buffer is empty
								-- buffer the output in a item buffer since the stack might be too small
								-- output items are shared among the output
								for _, trade in ipairs(offers) do
									local type = trade.offer.type
									local item = trade.offer.item
									local count = trade.offer.count or 1
									local cost = trade.price[1].amount
									if type == "give-item" and item == filter then
										if town_center.output_buffer[item] == nil then town_center.output_buffer[item] = 0 end
										if town_center.output_buffer[item] == 0 then
											-- fill buffer
											if town_center.coin_balance >= cost then
												town_center.coin_balance = town_center.coin_balance - cost
												Town_center.update_coin_balance(force)
												town_center.output_buffer[item] = town_center.output_buffer[item] + count
												--log("output_buffer[" .. item .. "] = " .. town_center.output_buffer[item])
											end
										end
										if town_center.output_buffer[item] > 0 and not stack.valid_for_read then
											-- output the item
											local amount = 1
											if stack.can_set_stack({ name = item, count = amount }) then
												town_center.output_buffer[item] = town_center.output_buffer[item] - amount
												stack.set_stack({ name = item, count = amount })
												--log("output_buffer[" .. item .. "] = " .. town_center.output_buffer[item])
											end
										end
										break
									end
								end
							end
						end
					end
				end
				-- pushing an item to the market (coins or scrap)
				if e.pickup_target and inside(dpos, bb) then
					local stack = e.held_stack
					local spos = e.held_stack_position
					if stack.valid_for_read and inside(spos, bb) then
						local name = stack.name
						local amount = stack.count
						if name == "coin" then
							-- push coins
							e.remove_item(stack)
							town_center.coin_balance = town_center.coin_balance + amount
							Town_center.update_coin_balance(force)
						else
							-- push items to turn into coin
							for _, trade in ipairs(offers) do
								local type = trade.offer.type
								local item = trade.price[1].name
								local count = trade.price[1].amount
								local cost = trade.offer.count
								if type == "give-item" and name == item and item ~= "coin" then
									e.remove_item(stack)
									-- buffer the input in an item buffer that can be sold
									if town_center.input_buffer[item] == nil then town_center.input_buffer[item] = 0 end
									town_center.input_buffer[item] = town_center.input_buffer[item] + amount
									--log("input_buffer[" .. item .. "] = " .. town_center.input_buffer[item])
									if town_center.input_buffer[item] >= count then
										town_center.input_buffer[item] = town_center.input_buffer[item] - count
										town_center.coin_balance = town_center.coin_balance + cost
										Town_center.update_coin_balance(force)
										--log("input_buffer[" .. item .. "] = " .. town_center.input_buffer[item])
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)


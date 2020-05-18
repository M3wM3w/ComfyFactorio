local Public = {}

local connection_radius = 7

local entity_type_whitelist = {
	["accumulator"] = true,
	["ammo-turret"] = true,
	["arithmetic-combinator"] = true,
	["artillery-turret"] = true,
	["assembling-machine"] = true,
	["boiler"] = true,
	["constant-combinator"] = true,
	["container"] = true,
	["curved-rail"] = true,
	["decider-combinator"] = true,
	["electric-pole"] = true,
	["electric-turret"] = true,
	["fluid-turret"] = true,
	["furnace"] = true,
	["gate"] = true,
	["generator"] = true,
	["heat-interface"] = true,
	["heat-pipe"] = true,
	["infinity-container"] = true,
	["infinity-pipe"] = true,
	["inserter"] = true,
	["lamp"] = true,
	["land-mine"] = true,
	["loader"] = true,
	["logistic-container"] = true,
	["market"] = true,
	["mining-drill"] = true,
	["offshore-pump"] = true,
	["pipe"] = true,
	["pipe-to-ground"] = true,
	["programmable-speaker"] = true,
	["pump"] = true,
	["radar"] = true,
	["rail-chain-signal"] = true,
	["rail-signal"] = true,
	["reactor"] = true,
	["roboport"] = true,
	["rocket-silo"] = true,
	["solar-panel"] = true,
	["splitter"] = true,
	["storage-tank"] = true,
	["straight-rail"] = true,
	["train-stop"] = true,
	["transport-belt"] = true,
	["underground-belt"] = true,
	["wall"] = true,
}

local function is_position_isolated(surface, force, position)
	local position_x = position.x
	local position_y = position.y
	local area = {{position_x - connection_radius, position_y - connection_radius}, {position_x + connection_radius, position_y + connection_radius}}
	local count = 0
	
	for _, e in pairs(surface.find_entities_filtered({area = area, force = force.name})) do
		if entity_type_whitelist[e.type] then
			count = count + 1
			if count > 1 then return end
		end
	end
	
	return true
end

local function refund_item(event, item_name)
	if event.player_index then 
		game.players[event.player_index].insert({name = item_name, count = 1})
		return 
	end	
	
	if event.robot then
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = item_name, count = 1})
		return
	end
end

local function error_floaty(surface, position, msg)
	surface.create_entity({
		name = "flying-text",
		position = position,
		text = msg,
		color = {r=0.77, g=0.0, b=0.0}
	})
end

local function is_town_market_nearby(entity)
	local area = {{entity.position.x - 48, entity.position.y - 48}, {entity.position.x + 48, entity.position.y + 48}}
	local markets = entity.surface.find_entities_filtered({name = "market", area = area})
	if not markets[1] then return false end
	for _, market in pairs(markets) do
		if market.force.index > 3 then return true end
	end
	return false
end

function Public.prevent_isolation(event)
	local entity = event.created_entity
	if not entity.valid then return end
	if entity.force.index == 1 then return end
	if not entity_type_whitelist[entity.type] then return end
	local surface = event.created_entity.surface
	
	if is_position_isolated(surface, entity.force, entity.position) then
		error_floaty(surface, entity.position, "Building is not connected to town!")
		refund_item(event, event.stack.name)	
		entity.destroy()
		return true
	end	
end

function Public.prevent_isolation_landfill(event)
	if event.item.name ~= "landfill" then return end
	local surface = game.surfaces[event.surface_index]
	local tiles = event.tiles
	
	local force
	if event.player_index then
		force = game.players[event.player_index].force
	else
		force = event.robot.force
	end
	
	for _, placed_tile in pairs(tiles) do
		local position = placed_tile.position
		if is_position_isolated(surface, force, position) then
			error_floaty(surface, position, "Tile is not connected to town!")
			surface.set_tiles({{name = "water", position = position}}, true)			
			refund_item(event, "landfill")		
		end
	end	
end

local square_min_distance_to_spawn = 80 ^ 2

function Public.restrictions(event)
	local entity = event.created_entity
	if not entity.valid then return end
	
	if entity.force.index == 1 then
		if is_town_market_nearby(entity) then
			refund_item(event, event.stack.name)
			error_floaty(entity.surface, entity.position, "Building too close to a town center!")
			entity.destroy()
		end	
		return 
	end
	
	if not entity_type_whitelist[entity.type] then return end
	if entity.position.x ^ 2 + entity.position.y ^ 2 > square_min_distance_to_spawn then return end
	refund_item(event, event.stack.name)
	error_floaty(entity.surface, entity.position, "Building too close to spawn!")
	entity.destroy()
end

return Public
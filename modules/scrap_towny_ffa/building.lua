local Public = {}

local connection_radius = 7

local neutral_whitelist = {
	["wooden-chest"] = true,
	["iron-chest"] = true,
	["steel-chest"] = true,
	["raw-fish"] = true,
}

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
	["lab"] = true,
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
	if item_name == "blueprint" then return end
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

local function in_range(pos1, pos2, radius)
	if pos1 == nil then return false end
	if pos2 == nil then return false end
	if radius < 1 then return true end
	local dx = pos1.x - pos2.x
	local dy = pos1.y - pos2.y
	if dx ^ 2 + dy ^ 2 < radius ^ 2 then
		return true
	end
	return false
end

-- is the position near a town?
function Public.near_town(position, surface, radius)
	for _, town_center in pairs(global.towny.town_centers) do
		if town_center ~= nil then
			local market = town_center.market
			if in_range(position, market.position, radius) and market.surface == surface then
				--log("near town")
				return true
			end
		end
	end
	--log("not near town")
	return false
end

local function prevent_isolation(event)
	local entity = event.created_entity
	if not entity.valid then return end
	local itemstack = event.stack
	local force = entity.force
	if force == game.forces["player"] then return end
	if force == game.forces["rogue"] then return end
	--if not entity_type_whitelist[entity.type] then return end
	local surface = event.created_entity.surface
	
	if is_position_isolated(surface, force, entity.position) then
		error_floaty(surface, entity.position, "Building is not connected to town!")
		if itemstack.valid then
			refund_item(event, itemstack.name)
		end
		entity.destroy()
		return true
	end	
end

local function prevent_isolation_landfill(event)
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

local function restrictions(event)
	local entity = event.created_entity
	if not entity.valid then return end
	
	if entity.force == game.forces["player"] or entity.force == game.forces["rogue"] then
		if Public.near_town(position, surface, 32) then
			refund_item(event, event.stack.name)
			error_floaty(entity.surface, entity.position, "Building too close to a town center!")
			entity.destroy()
		else
			entity.force = game.forces["neutral"]
		end	
		return 
	end

	if not neutral_whitelist[entity.type] then return end
	entity.force = game.forces["neutral"]

end

local function on_built_entity(event)
	if prevent_isolation(event) then return end
	restrictions(event)
end

local function on_player_built_tile(event)
	prevent_isolation_landfill(event)
end

local function on_robot_built_entity(event)
	if prevent_isolation(event) then return end
	restrictions(event)
end

local function on_robot_built_tile(event)
	prevent_isolation_landfill(event)
end

local Event = require 'utils.event'
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)

return Public
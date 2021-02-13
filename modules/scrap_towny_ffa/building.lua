local Public = {}

local Table = require 'modules.scrap_towny_ffa.table'

local town_radius = 27
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
	["lab"] = true,
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

local function isolated(surface, force, position)
	local position_x = position.x
	local position_y = position.y
	local area = { { position_x - connection_radius, position_y - connection_radius }, { position_x + connection_radius, position_y + connection_radius } }
	local count = 0

	for _, e in pairs(surface.find_entities_filtered({ area = area, force = force.name })) do
		if entity_type_whitelist[e.type] then
			count = count + 1
			if count > 1 then return false end		-- are there more than one team entities in the area?
		end
	end

	return true
end

local function refund_item(event, item_name)
	if item_name == "blueprint" then return end
	if event.player_index then
		game.players[event.player_index].insert({ name = item_name, count = 1 })
		return
	end

	if event.robot then
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({ name = item_name, count = 1 })
		return
	end
end

local function error_floaty(surface, position, msg)
	surface.create_entity({
		name = "flying-text",
		position = position,
		text = msg,
		color = { r = 0.77, g = 0.0, b = 0.0 }
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
	local ffatable = Table.get_table()
	for _, town_center in pairs(ffatable.town_centers) do
		if town_center ~= nil then
			local market = town_center.market
			if in_range(position, market.position, radius) and market.surface == surface then
				return true
			end
		end
	end
	return false
end

local function in_town(force, position)
	local ffatable = Table.get_table()
	local town_center = ffatable.town_centers[force.name]
	if town_center ~= nil then
		local center = town_center.market.position
		if position.x >= center.x - town_radius and position.x <= center.x + town_radius then
			if position.y >= center.y - town_radius and position.y <= center.y + town_radius then
				return true
			end
		end
	end
	return false
end

local function prevent_isolation_entity(event, player)
	local p = player or nil
	local entity = event.created_entity
	local position = entity.position
	if not entity.valid then return end
	local entity_name = entity.name
	local item = event.item
	if item == nil then return end
	local item_name = item.name
	local force = entity.force
	if force == game.forces.player then return end
	if force == game.forces["rogue"] then return end
	local surface = entity.surface
	local error = false
	if not in_town(force, position) and isolated(surface, force, position) then
		error = true
		entity.destroy()
		if entity_name ~= "entity-ghost" and entity_name ~= "tile-ghost" then
			refund_item(event, item_name)
		end
		--return true
	end
	if error == true then
		if p ~= nil then
			p.play_sound({ path = "utility/cannot_build", position = p.position, volume_modifier = 0.75 })
		end
		error_floaty(surface, position, "Building is not connected to town!")
	end
end

local function prevent_isolation_tile(event, player)
	local p = player or nil
	local tile = event.tile
	if not tile.valid then return end
	local tile_name = tile.name
	local surface = game.surfaces[event.surface_index]
	local tiles = event.tiles
	local force
	if event.player_index then
		force = game.players[event.player_index].force
	else
		force = event.robot.force
	end
	local error = false
	local position
	for _, t in pairs(tiles) do
		local old_tile = t.old_tile
		position = t.position
		if not in_town(force, position) and isolated(surface, force, position) then
			error = true
			surface.set_tiles({ { name = old_tile.name, position = position } }, true)
			if tile_name ~= "tile-ghost" then
				if tile_name == "stone-path" then tile_name = "stone-brick" end
				refund_item(event, tile_name)
			end
		end
	end
	if error == true then
		if p ~= nil then
			p.play_sound({ path = "utility/cannot_build", position = p.position, volume_modifier = 0.75 })
		end
		error_floaty(surface, position, "Tile is not connected to town!")
	end
end

local function restrictions(event, player)
	local p = player or nil
	local entity = event.created_entity
	if not entity.valid then return end
	local entity_name = entity.name
	local surface = entity.surface
	local position = entity.position
	local error = false
	if entity.force == game.forces["player"] or entity.force == game.forces["rogue"] then
		if Public.near_town(position, surface, 32) then
			error = true
			entity.destroy()
			if entity_name ~= "entity-ghost" then
				refund_item(event, event.stack.name)
			end
		else
			entity.force = game.forces["neutral"]
		end
		return
	end
	if error == true then
		if p ~= nil then
			p.play_sound({ path = "utility/cannot_build", position = p.position, volume_modifier = 0.75 })
		end
		error_floaty(surface, position, "Can't build near town!")
	end

	if not neutral_whitelist[entity.type] then return end
	entity.force = game.forces["neutral"]

end

-- called when a player places an item, or a ghost
local function on_built_entity(event)
	local player = game.players[event.player_index]
	if prevent_isolation_entity(event, player) then return end
	restrictions(event, player)
end

local function on_robot_built_entity(event)
	if prevent_isolation_entity(event) then return end
	restrictions(event)
end

-- called when a player places landfill
local function on_player_built_tile(event)
	local player = game.players[event.player_index]
	prevent_isolation_tile(event, player)
end

local function on_robot_built_tile(event)
	prevent_isolation_tile(event)
end

local Event = require 'utils.event'
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)

return Public
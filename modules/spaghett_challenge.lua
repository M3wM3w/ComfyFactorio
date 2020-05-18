-- too many same entities close together will explode 

local event = require 'utils.event'
local math_random = math.random
require 'utils.table'

local search_radius = 6
local explosions = {"explosion", "explosion", "explosion", "explosion", "explosion", "explosion", "medium-explosion", "uranium-cannon-explosion", "uranium-cannon-explosion"}

local default_limit = 2
local entity_limits = {
	["transport-belt"] = search_radius * 2 + 1,
	["pipe"] = search_radius * 2 + 2,
	["pipe-to-ground"] = 2,
	["heat-pipe"] = search_radius * 2,
	["inserter"] = 3,
	["underground-belt"] = 3,
	["electric-pole"] = 3,
	["generator"] = 1,
	["assembling-machine"] = 4,
	["accumulator"] = 4,
	["container"] = search_radius * 2,
	["furnace"] = 4,
	["mining-drill"] = 1
}

local ignore_list = {
	["curved-rail"] = true,
	["straight-rail"] = true,
	["rail-signal"] = true,
	["rail-chain-signal"] = true,
	["car"] = true,
	["cargo-wagon"] = true,
	["locomotive"] = true,
	["land-mine"] = true,
	["entity-ghost"] = true,
	["character"] = true,
	["gate"] = true,
	["wall"] = true
}

local function error_message()
	local errors = {"spaghett", "not found", "cat", "error", "not enough", "pylons", "out of", "limit reached", "void",
	"balance", "operation", "alert", "not responding", "angry", "sad", "not working", "can not compute", "unstable location", "invalid",
	"gearwheel", "malfunctioning", "unknown", "can not", "wrong", "dog", "ocelot", "failure", "division by", "zero", "bathwater", "faulty", "conveyor", "too many",
	"ravioli", "pasta", "overflow", "major"
	}
	table.shuffle_table(errors)
	local message = table.concat({errors[1], " ", errors[2], " ", errors[3], "!"})
	return message
end

local function count_same_entities(entity)
	local same_entity_count = 0
	for _, e in pairs(entity.surface.find_entities_filtered({type = entity.type, area = {{entity.position.x - search_radius, entity.position.y - search_radius},{entity.position.x + search_radius, entity.position.y + search_radius}}})) do
		if entity.type == e.type and entity.direction == e.direction then
			same_entity_count = same_entity_count + 1
		end
	end
	return same_entity_count
end

local function spaghett(surface, entity, inventory, player)
	if ignore_list[entity.type] then return end
	local limit = entity_limits[entity.type]
	if not limit then limit = 2 end	
	if count_same_entities(entity) > limit then
		inventory.insert({name = entity.name, count = 1})
		surface.create_entity({name = explosions[math_random(1, #explosions)], position = entity.position})
		if player then
			if not global.last_spaghett_error then global.last_spaghett_error = {} end
			if not global.last_spaghett_error[player.index] then global.last_spaghett_error[player.index] = 0 end
			if game.tick - global.last_spaghett_error[player.index] > 30 then
				local gb = math.random(0, 150)
				surface.create_entity({
					name = "flying-text",
					position = entity.position,
					text = error_message(),
					color = {r = math.random(200, 255), g = math.random(0, 125), b = math.random(0, 125)}
				})
				global.last_spaghett_error[player.index] = game.tick
			end
		end
		entity.die("player")
	end
end

local function on_built_entity(event)
	spaghett(event.created_entity.surface, event.created_entity, game.players[event.player_index].get_main_inventory(), game.players[event.player_index])
end

local function on_player_rotated_entity(event)
	spaghett(event.entity.surface, event.entity, game.players[event.player_index].get_main_inventory(), game.players[event.player_index])
end

local function on_robot_built_entity(event)
	spaghett(event.robot.surface, event.created_entity, event.robot.get_inventory(defines.inventory.robot_cargo))
end

function on_player_created(event)
	local force = game.players[event.player_index].force
	force.technologies["logistic-system"].enabled = false
	force.technologies["construction-robotics"].enabled = false
	force.technologies["logistic-robotics"].enabled = false
	force.technologies["robotics"].enabled = false
	force.technologies["personal-roboport-equipment"].enabled = false
	force.technologies["personal-roboport-mk2-equipment"].enabled = false	
	force.technologies["character-logistic-trash-slots-1"].enabled = false
	force.technologies["character-logistic-trash-slots-2"].enabled = false
	force.technologies["auto-character-logistic-trash-slots"].enabled = false
	force.technologies["worker-robots-storage-1"].enabled = false
	force.technologies["worker-robots-storage-2"].enabled = false
	force.technologies["worker-robots-storage-3"].enabled = false	
	force.technologies["character-logistic-slots-1"].enabled = false
	force.technologies["character-logistic-slots-2"].enabled = false
	force.technologies["character-logistic-slots-3"].enabled = false
	force.technologies["character-logistic-slots-4"].enabled = false
	force.technologies["character-logistic-slots-5"].enabled = false
	force.technologies["character-logistic-slots-6"].enabled = false
	force.technologies["worker-robots-speed-1"].enabled = false
	force.technologies["worker-robots-speed-2"].enabled = false
	force.technologies["worker-robots-speed-3"].enabled = false
	force.technologies["worker-robots-speed-4"].enabled = false
	force.technologies["worker-robots-speed-5"].enabled = false
	force.technologies["worker-robots-speed-6"].enabled = false
end

event.add(defines.events.on_player_created, on_player_created)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
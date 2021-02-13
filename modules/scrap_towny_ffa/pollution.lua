local Public = {}
local math_random = math.random

local Table = require 'modules.scrap_towny_ffa.table'
local Scrap = require 'modules.scrap_towny_ffa.scrap'

local pollution_index = {
	["small-biter"] = { min = 0.1, max = 0.1 },
	["medium-biter"] = { min = 0.1, max = 0.2 },
	["big-biter"] = { min = 0.1, max = 0.3 },
	["behemoth-biter"] = { min = 0.1, max = 0.4 },
	["small-spitter"] = { min = 0.1, max = 0.1 },
	["medium-spitter"] = { min = 0.1, max = 0.2 },
	["big-spitter"] = { min = 0.1, max = 0.3 },
	["behemoth-spitter"] = { min = 0.2, max = 0.4 },
	["small-worm-turret"] = { min = 0.1, max = 0.1 },
	["medium-worm-turret"] = { min = 0.1, max = 0.2 },
	["big-worm-turret"] = { min = 0.1, max = 0.3 },
	["behemoth-worm-turret"] = { min = 0.2, max = 0.4 },
	["biter-spawner"] = { min = 0.5, max = 2.5 },
	["spitter-spawner"] = { min = 0.5, max = 2.5 },
	["mineable-wreckage"] = { min = 0.1, max = 0.1 },
	["small-ship-wreck"] = { min = 0.1, max = 0.1 },
	["medium-ship-wreck"] = { min = 0.1, max = 0.1 },
	["crash-site-spaceship-wreck-small-1"] = { min = 0.1, max = 0.1 },
	["crash-site-spaceship-wreck-small-2"] = { min = 0.1, max = 0.1 },
	["crash-site-spaceship-wreck-small-3"] = { min = 0.1, max = 0.1 },
	["crash-site-spaceship-wreck-small-4"] = { min = 0.1, max = 0.1 },
	["crash-site-spaceship-wreck-small-5"] = { min = 0.1, max = 0.1 },
	["crash-site-spaceship-wreck-small-6"] = { min = 0.1, max = 0.1 },
	["big-ship-wreck-1"] = { min = 0.2, max = 0.4 },
	["big-ship-wreck-2"] = { min = 0.2, max = 0.4 },
	["big-ship-wreck-3"] = { min = 0.2, max = 0.4 },
	["crash-site-chest-1"] = { min = 0.1, max = 0.2 },
	["crash-site-chest-2"] = { min = 0.1, max = 0.2 },
	["crash-site-spaceship-wreck-medium-1"] = { min = 0.1, max = 0.2 },
	["crash-site-spaceship-wreck-medium-2"] = { min = 0.1, max = 0.2 },
	["crash-site-spaceship-wreck-medium-3"] = { min = 0.1, max = 0.2 },
	["crash-site-spaceship-wreck-big-1"] = { min = 0.2, max = 0.4 },
	["crash-site-spaceship-wreck-big-2"] = { min = 0.2, max = 0.4 },
	["crash-site-spaceship"] = { min = 0.5, max = 2.5 },
	["explosion"] = { min = 0.1, max = 0.1 },
	["big-explosion"] = { min = 0.2, max = 0.2 },
	["big-artillery-explosion"] = { min = 0.5, max = 0.5 },
	["market"] = { min = 10, max = 50 },
}

function Public.market_scent()
	local ffatable = Table.get_table()
	local town_centers = ffatable.town_centers
	if town_centers == nil then return end
	for _, town_center in pairs(town_centers) do
		local market = town_center.market
		local pollution = pollution_index["market"]
		local amount = math_random(pollution.min, pollution.max)
		market.surface.pollute(market.position, amount)
	end
end

function Public.explosion(position, surface, animation)
	local pollution = pollution_index[animation]
	if pollution == nil then return end
	local amount = math_random(pollution.min, pollution.max)
	surface.pollute(position, amount)
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if Scrap.is_scrap(entity) == true then
		local pollution = pollution_index[entity.name]
		local amount = math_random(pollution.min, pollution.max)
		entity.surface.pollute(entity.position, amount)
	end
end

local function on_entity_damaged(event)
	local entity = event.entity
	if not entity.valid then return end
	local pollution = pollution_index[entity.name]
	if pollution == nil then return end
	local amount = math_random(pollution.min, pollution.max)
	entity.surface.pollute(entity.position, amount)
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	local pollution = pollution_index[entity.name]
	if pollution == nil then return end
	local amount = math_random(pollution.min, pollution.max) * 10
	entity.surface.pollute(entity.position, amount)
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)

return Public
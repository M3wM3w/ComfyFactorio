local math_random = math.random
local Evolution = require "modules.scrap_towny_ffa.evolution"
local Building = require "modules.scrap_towny_ffa.building"
local Scrap = require "modules.scrap_towny_ffa.scrap"
local unearthing_worm = require "modules.scrap_towny_ffa.unearthing_worm"
local unearthing_biters = require "modules.scrap_towny_ffa.unearthing_biters"
local tick_tack_trap = require "modules.scrap_towny_ffa.tick_tack_trap"

local function trap(entity)
	-- check if within 32 blocks of market
	if entity.type == "tree" or Scrap.is_scrap(entity) then
		if math_random(1, 1024) == 1 then
			if not Building.near_town(entity.position, entity.surface, 32) then
				tick_tack_trap(entity.surface, entity.position)
				return
			end
		end
		if math_random(1, 256) == 1 then
			if not Building.near_town(entity.position, entity.surface, 32) then
				unearthing_worm(entity.surface, entity.position, Evolution.get_worm_evolution(entity))
			end
		end
		if math_random(1, 128) == 1 then
			if not Building.near_town(entity.position, entity.surface, 32) then
				unearthing_biters(entity.surface, entity.position, math_random(4, 8), Evolution.get_biter_evolution(entity))
			end
		end
	end
end

local function on_player_mined_entity(event)
	local entity = event.entity
	trap(entity)
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
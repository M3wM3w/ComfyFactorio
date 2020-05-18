require "modules.biter_reanimator"

local Blood_moon = require "maps.pitch_black.blood_moon"
local Gui = require "maps.pitch_black.gui"
local Difficulty = require "maps.pitch_black.difficulty"

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	local cause = event.cause	
	Difficulty.fleeing_biteys(entity, cause)
	Difficulty.add_score(entity)
end

local function on_tick()
	local tick = game.tick
	if tick % 2 ~= 0 then return end
	
	local surface = game.surfaces[1]
	
	Blood_moon.set_daytime(surface, tick)
	
	if tick % 30 ~= 0 then return end
	Difficulty.set_daytime_difficulty(surface, tick)
	Difficulty.set_biter_difficulty()
	
	Gui.update()
end

local function on_init()
	local surface = game.surfaces[1]
	
	surface.freeze_daytime = true
	surface.min_brightness = 0
	
	global.daytime = 0
	global.map_score = 0
end

local Event = require 'utils.event'
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_tick, on_tick)
Event.on_init(on_init)
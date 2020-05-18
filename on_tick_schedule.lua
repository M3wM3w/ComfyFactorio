local function on_tick()	
	if not global.on_tick_schedule[game.tick] then return end	
	for _, schedule in pairs(global.on_tick_schedule[game.tick]) do
		schedule.func(unpack(schedule.args))		
	end		
	global.on_tick_schedule[game.tick] = nil
end

local function on_init(event)
	if not global.on_tick_schedule then global.on_tick_schedule = {} end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
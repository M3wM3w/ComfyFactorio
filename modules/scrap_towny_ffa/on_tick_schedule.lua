local Table = require 'modules.scrap_towny_ffa.table'

local function on_tick()
  local ffatable = Table.get_table()
	if not ffatable.on_tick_schedule[game.tick] then return end
	for _, schedule in pairs(ffatable.on_tick_schedule[game.tick]) do
		schedule.func(unpack(schedule.args))
	end
	ffatable.on_tick_schedule[game.tick] = nil
end

local on_init = function ()
  local ffatable = Table.get_table()
  ffatable.on_tick_schedule = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
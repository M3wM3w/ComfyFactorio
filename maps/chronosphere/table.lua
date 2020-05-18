-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local chronosphere = {}
local Public = {}

Global.register(
    chronosphere,
    function(tbl)
        chronosphere = tbl
    end
)

function Public.reset_table()
    for k, _ in pairs(chronosphere) do
      chronosphere[k] = nil
    end
	chronosphere.computermessage = 0
	chronosphere.config = {}
	chronosphere.lab_cells = {}
	chronosphere.flame_boots = {}
	chronosphere.chronojumps = 0
	chronosphere.game_lost = true
	chronosphere.game_won = false
	chronosphere.max_health = 0
	chronosphere.health = 0
	chronosphere.poisontimeout = 0
	chronosphere.chronocharges = 0
	chronosphere.passive_chronocharge_rate = 0
	chronosphere.accumulator_energy_history = {}
	chronosphere.passivetimer = 0
	chronosphere.overstaycount = 0
	chronosphere.chronochargesneeded = 0
	chronosphere.jump_countdown_start_time = 0
	chronosphere.jump_countdown_length = 0
	chronosphere.mainscore = 0
	chronosphere.active_biters = {}
	chronosphere.unit_groups = {}
	chronosphere.biter_raffle = {}
	chronosphere.dangertimer = 0
	chronosphere.dangers = {}
	chronosphere.looted_nukes = 0
	chronosphere.offline_players = {}
	chronosphere.nextsurface = nil
	chronosphere.upgrades = {}
	chronosphere.outchests = {}
	chronosphere.upgradechest = {}
	chronosphere.fishchest = {}
	chronosphere.comfylatron = {}
	chronosphere.accumulators = {}
	chronosphere.comfychests = {}
	chronosphere.comfychests2 = {}
	chronosphere.locomotive_cargo = {}
	chronosphere.planet = {}
end

function Public.get_table()
    return chronosphere
end

local on_init = function ()
    Public.reset_table()
end

Event.on_init(on_init)

return Public

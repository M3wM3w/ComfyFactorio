-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local chronosphere = {}
local bitersphere = {}
local schedulesphere = {}
local playersphere = {}
local productionsphere = {}
local Public = {}

Global.register(
    chronosphere,
    function(tbl)
        chronosphere = tbl
    end
)
Global.register(
    bitersphere,
    function(tbl)
        bitersphere = tbl
    end
)
Global.register(
    schedulesphere,
    function(tbl)
        schedulesphere = tbl
    end
)
Global.register(
    playersphere,
    function(tbl)
        playersphere = tbl
    end
)
Global.register(
    productionsphere,
    function(tbl)
        productionsphere = tbl
    end
)

function Public.reset_production_table()
  for k, _ in pairs(productionsphere) do
    productionsphere[k] = nil
  end
  productionsphere.experience = {}
  productionsphere.assemblers = {}
  productionsphere.train_assemblers = {}
end

function Public.reset_player_table()
  for k, _ in pairs(playersphere) do
    playersphere[k] = nil
  end
  playersphere.icw = {}
  playersphere.icw.players = {}
  playersphere.flame_boots = {}
  playersphere.offline_players = {}
  playersphere.active_upgrades_gui = {}
end

function Public.reset_schedule_table()
  for k, _ in pairs(schedulesphere) do
    schedulesphere[k] = nil
  end
  schedulesphere.schedule_step = 0
  schedulesphere.schedule_max_step = 0
  schedulesphere.schedule = {}
  schedulesphere.lab_cells = {}
end

function Public.reset_biter_table()
  for k, _ in pairs(bitersphere) do
    bitersphere[k] = nil
  end
  bitersphere.active_biters = {}
  bitersphere.unit_groups = {}
  bitersphere.biter_raffle = {}
  bitersphere.free_biters = 0
end

function Public.reset_table()
    for k, _ in pairs(chronosphere) do
      chronosphere[k] = nil
    end
	chronosphere.computermessage = 0
	chronosphere.config = {}
  chronosphere.chronojumps = 0
	chronosphere.game_lost = true
	chronosphere.game_won = false
	chronosphere.max_health = 0
	chronosphere.health = 0
	chronosphere.poisontimeout = 0
	chronosphere.chronocharges = 0
	chronosphere.passive_chronocharge_rate = 0
	chronosphere.passivetimer = 0
	chronosphere.overstaycount = 0
	chronosphere.chronochargesneeded = 0
	chronosphere.jump_countdown_start_time = 0
	chronosphere.jump_countdown_length = 0
	chronosphere.mainscore = 0
  chronosphere.dangertimer = 0
	chronosphere.dangers = {}
	chronosphere.looted_nukes = 0
	chronosphere.nextsurface = nil
	chronosphere.upgrades = {}
	chronosphere.outchests = {}
  chronosphere.outcombinators = {}
	chronosphere.upgradechest = {}
	chronosphere.fishchest = {}
	chronosphere.comfylatron = {}
	chronosphere.accumulators = {}
	chronosphere.comfychests = {}
	chronosphere.comfychests2 = {}
	chronosphere.locomotive_cargo = {}
	chronosphere.world = {}
  chronosphere.research_tokens = {}
  chronosphere.research_tokens.biters = 0
	chronosphere.research_tokens.ammo = 0
	chronosphere.research_tokens.tech = 0
	chronosphere.research_tokens.ecology = 0
	chronosphere.research_tokens.weapons = 0
  chronosphere.laser_battery = 0
  chronosphere.last_artillery_event = 0
  chronosphere.poison_mastery_unlocked = 0
end

function Public.get_table()
    return chronosphere
end

function Public.get_player_table()
    return playersphere
end

function Public.get_schedule_table()
    return schedulesphere
end

function Public.get_biter_table()
    return bitersphere
end

function Public.get_production_table()
    return productionsphere
end

local on_init = function ()
    Public.reset_table()
    Public.reset_biter_table()
    Public.reset_player_table()
    Public.reset_schedule_table()
    Public.reset_production_table()
end

Event.on_init(on_init)

return Public

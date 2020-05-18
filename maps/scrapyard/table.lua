-- on table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    players = {},
    game_lost = false,
    game_won = false,
    energy = {},
    wave_counter = 0,
    locomotive_health = 10000,
    locomotive_max_health = 10000,
    cargo_health = 10000,
    cargo_max_health = 10000,
    revealed_spawn = 0,
    scrap_enabled = true,
    rocks_yield_ore_maximum_amount = 500,
    rocks_yield_ore_base_amount = 50,
    rocks_yield_ore_distance_modifier = 0.020,
    left_top = {
        x = 0,
        y = 0
    },
    o_left_top = {
        x = 0,
        y = 0
    }
}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.reset_table()
    --for k, _ in pairs(this) do
    --  this[k] = nil
    --end
    this.lo_energy = nil
    this.ow_energy = nil
	this.game_lost = false
	this.game_won = false
    this.energy = {}
    this.wave_counter = 0
	this.locomotive_health = 10000
	this.locomotive_max_health = 10000
    this.cargo_health = 10000
    this.cargo_max_health = 10000
	this.revealed_spawn = 0
    this.scrap_enabled = true
    this.left_top = {
        x = 0,
        y = 0
    }
    this.o_left_top = {
        x = 0,
        y = 0
    }
end

function Public.get_table()
    return this
end

local on_init = function ()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
